//
//  PostProcessOutgoing.swift
//
//  Created by Duncan Anderson on 13/11/2016.
//
//

import Foundation
import SwiftyJSON
import KituraRequest
import HeliumLogger
import LoggerAPI
import CouchDB

class PostProcessOutgoing {

    // Gets called to post-process output of Conversation
    func processConversationResponse (conversationJSON: JSON, completionHandler: @escaping (_ response:JSON)->Void)  {
        // Process Conversation response
        let responseJSON = conversationJSON
        var responseContext = conversationJSON["context"]
        let topIntent = conversationJSON["intents"][0]["intent"]
        
        // Decision logic
        let specialAction = responseContext["special_action"].stringValue
        if (specialAction != "") {
            Log.verbose("Special-Action: \(specialAction)")
        }

        switch responseContext["special_action"] {
        case "restaurantBookingAPI":
            // Add your post-processing logic here
            
            completionHandler(responseJSON)
            break
            
        default:
            completionHandler(responseJSON)
        }
    }
    
}
