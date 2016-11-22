//
//  main.swift
//
//  Created by Duncan Anderson on 13/11/2016.
//
//

// Kitura-Starter contains examples for creating custom routes.
import Foundation
import Kitura
import LoggerAPI
import HeliumLogger
import CloudFoundryEnv
import CloudFoundryDeploymentTracker
import CouchDB

do {
    // HeliumLogger disables all buffering on stdout
    HeliumLogger.use(LoggerMessageType.info)
    let controller = try Controller()
    Log.info("Server will be started on '\(controller.url)'.")
    Kitura.addHTTPServer(onPort: controller.port, with: controller.router)
    
    // Start Kitura-Starter server
    Kitura.run()
} catch let error {
    Log.error(error.localizedDescription)
    Log.error("Oops... something went wrong. Server did not start!")
}
