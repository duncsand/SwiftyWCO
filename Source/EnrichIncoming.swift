//
//  EnrichIncoming.swift
//
//  Created by Duncan Anderson on 13/11/2016.
//
//

import Foundation
import SwiftyJSON
import KituraRequest
import HeliumLogger
import LoggerAPI

class EnrichIncoming {
    
    // Find postcodes and names in incoming msg text and add to the message object
    func enrichIncoming(context:JSON, incomingMessageBody:JSON, completionHandler: @escaping (_ context:JSON, _ msgBody:JSON)->Void) {
        var enrichedMsgBody = incomingMessageBody
        var enrichedContext = context
        var enrichedMsg = incomingMessageBody["message"]["text"].string ?? ""
        
        // Add you enrichment logic here
        
        
        // Call completionHandler and complete message processing
        completionHandler(enrichedContext, enrichedMsgBody)
    }
    
}
