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
    func enrichIncoming(msg:String, context:JSON, incomingMessageBody:JSON, completionHandler: @escaping (_ msg:String, _ context:JSON, _ msgBody:JSON)->Void) {
        var enrichedMsgBody = incomingMessageBody
        var enrichedContext = context
        var enrichedMsg = msg
        
        // Add you enrichment logic here
        
        
        // Call completionHandler and complete message processing
        completionHandler(enrichedMsg, enrichedContext, enrichedMsgBody)
    }
    
}
