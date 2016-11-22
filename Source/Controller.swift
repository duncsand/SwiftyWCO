//
//  Controller.swift
//
//  Created by Duncan Anderson on 13/11/2016.
//
//

import Kitura
import SwiftyJSON
import LoggerAPI
import CloudFoundryEnv
import CouchDB
import Foundation
import KituraRequest
import Credentials
import CredentialsHTTP
import HeliumLogger
import LoggerAPI

let jsonContentType = "application/json; charset=utf-8"
let couchDBClient = CouchDBClient(connectionProperties: connProperties)


public class Controller {
    let couchDBClient = CouchDBClient(connectionProperties: connProperties)
    let router: Router
    let appEnv: AppEnv
    let jsonContentType = "application/json; charset=utf-8"
    
    // Configs
    //let path = Bundle.main.path(forResource: "Config", ofType: "plist")
    //var config = NSDictionary()
    
    var port: Int {
        get { return appEnv.port }
    }
    
    var url: String {
        get { return appEnv.url }
    }
    init() throws {
        Log.logger = HeliumLogger()
        appEnv = try CloudFoundryEnv.getAppEnv()
        // Get configs
        //config = NSDictionary(contentsOfFile: path!)!
        //config = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Config", ofType: "plist")!)!
        
        // All web apps need a Router instance to define routes
        router = Router()
        
        // Credentials
        let credentials = Credentials()
        let users = ["botDunc" : "watsoniscool"]
        let basicCredentials = CredentialsHTTPBasic(userProfileLoader: { userId, callback in
            if let storedPassword = users["botDunc"] {
                callback(UserProfile(id: userId, displayName: userId, provider: "HTTPBasic"), storedPassword)
            }
            else {
                callback(nil, nil)
            }
        })
        
        // Setup basic auth credentials
        credentials.register(plugin: basicCredentials)
        
        // Serve static content from "public"
        router.all("/*", middleware: credentials)
        router.all("/", middleware: StaticFileServer())
        router.all("/newMessage", middleware: BodyParser())
        router.post("/newMessage", handler: newMessage )
    }
    
    
    // MARK:- HTTP processing
    // Process incoming new message
    public func newMessage(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.debug("GET - /newMessage route handler...")
        
        guard let parsedBody = request.body else {
            next()
            return
        }
        
        switch(parsedBody) {
        case .json(let incomingMessageBody):
            let conversationID = incomingMessageBody["sender"]["id"].string ?? ""
            let origin = incomingMessageBody["origin"].string ?? ""
            let msg = incomingMessageBody["message"]["text"].string ?? ""
            
            //Find stored context
            self.findStoredContext(id: conversationID) {(document: JSON?) -> () in
                var conversationContext = JSON([])
                if ( document?["rows"].count == 0) { // Create a new context
                    conversationContext = JSON(["conversationID": conversationID, "origin": origin]) }
                else { // Reuse found context
                    conversationContext = (document?["rows"][0]["doc"])!
                }
                let enrich = EnrichIncoming()
                enrich.enrichIncoming(msg: msg, context: conversationContext, incomingMessageBody: incomingMessageBody, completionHandler: {(msg: String, context: JSON, msgBody:JSON)-> Void in
                    self.processEnrichedMsg(msg: msg, context: context, incomingMessageBody: msgBody, response: response)
                })
            }
        default:
            break
        }
    }
    
    
    // Now process the message
    func processEnrichedMsg (msg:String, context:JSON, incomingMessageBody:JSON, response:RouterResponse) {
        
        // Send request to Watson Conversation
        self.sendConversationRequest(msg: msg, context: context, completionHandler: {(responseJSON: JSON)->Void in
            
            // Process Response
            let post = PostProcessOutgoing()
            post.processConversationResponse(conversationJSON: responseJSON, completionHandler: {(responseJSON: JSON)->Void in
                self.createResponse(conversationJSON: responseJSON, response: response)
            })
            
            // Update stored context
            self.storeContext(context: responseJSON["context"])
        })
    }
    
    
    // MARK:- Conext Storage
    // Find stored context if one exists in Cloudant
    func findStoredContext (id: String, completionHandler: @escaping (JSON?) -> ()) {
        let database = couchDBClient.database("context")
        let key = id as Database.KeyType
        let qp = Database.QueryParameters.limit(10)
        let qp2 = Database.QueryParameters.includeDocs(true)
        let qp3 = Database.QueryParameters.keys([key])
        database.queryByView("conversationID", ofDesign: "conversationID", usingParameters: [qp, qp2, qp3]) {(document: JSON?, error: NSError?) in
            completionHandler(document)
        }
    }
    
    // Update/Store Context in Cloudant
    func storeContext(context:JSON) {
        var updatedContext = context
        let database = couchDBClient.database("context")
        if updatedContext["_rev"].exists() {
            // Update existing ontext
            let id = updatedContext["_id"].string
            let rev = updatedContext["_rev"].string
            updatedContext["special_action"] = ""
            updatedContext["account"] = ""
            database.update(id!, rev: rev!, document: updatedContext)  { (id, revision, error) in
                if (error != nil) {
                    Log.error("Error: \(error?.localizedDescription)")
                }
                else {
                    Log.verbose("Context updated.")
                }
            }
        }
        else {
            // Create new context
            database.create(updatedContext) { (id, revision, doc, error) in
                if (error != nil) {
                    Log.error ("Error: \(error?.localizedDescription)")
                }
                else {
                    Log.verbose("New Context stored.")
                }
            }
        }
    }
    
    
    // Send msg & context object to Watson Conversation
    func sendConversationRequest(msg: String, context:JSON, completionHandler: @escaping ((_ response: JSON) -> Void) ) {
        
        // Create the URL
        var url = URL(string: conversationServiceURL)
        let URLParams = [ "version": conversationVersion]
        url = url?.URLByAppendingQueryParameters(parametersDictionary: URLParams)
        
        // Headers
        let headers = ["Content-Type": jsonContentType,
                       "Authorization": conversationServiceAuth]
        // JSON Body
        let bodyObject = ["input": ["text": msg], "context": context.object]
        
        // Make request
        KituraRequest.request(Request.Method(rawValue: "POST")!, (url?.absoluteString)!, parameters: bodyObject, encoding: JSONEncoding.default, headers: headers).response {request, response, data, error in
            if (error == nil) {
                // Success
                let json = JSON(data: data!)
                completionHandler(json)
            }
            else {
                // Failure
                Log.error("URL Session Task Failed: \(error?.localizedDescription)")
            }
        }
    }
    
    
    func createResponse (conversationJSON: JSON, response: RouterResponse) {
        // Get response text
        var jsonResponse = JSON([:])
        if (conversationJSON["attachments"].exists()) {
            jsonResponse["attachments"] = conversationJSON["attachments"]
        }
        else
        {
            var outputText: String = ""
            let outputArray = conversationJSON["output"]["text"].array ?? []
            for response: JSON in outputArray {
                outputText = outputText + response.stringValue
            }
            jsonResponse["response"].stringValue = outputText
        }
        
        // Create response
        response.headers["Content-Type"] = self.jsonContentType
        do {
            try response.status(.OK).send(json: jsonResponse).end()}
        catch let error as NSError {
            Log.error("ERROR: \(error.localizedDescription)")
        }
    }
}



// MARK:- URL processing helpers

protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

extension Dictionary : URLQueryParameterStringConvertible {
    /**
     This computed property returns a query parameters string from the given NSDictionary. For
     example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
     string will be @"day=Tuesday&month=January".
     @return The computed parameters string.
     */
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(describing: key).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! + "=" + String(describing: value).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            parts.append(part)
        }
        return parts.joined(separator: "&")
    }
    
}

extension URL {
    /**
     Creates a new URL by adding the given query parameters.
     @param parametersDictionary The query parameter dictionary to add.
     @return A new URL.
     */
    func URLByAppendingQueryParameters(parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString = self.absoluteString + "?" + parametersDictionary.queryParameters
        return URL(string: URLString)!
    }
}
