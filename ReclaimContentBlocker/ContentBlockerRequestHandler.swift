//
//  ContentBlockerRequestHandler.swift
//  ContentBlocker
//
//  Safari Content Blocker extension request handler
//

import Foundation
import SafariServices

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        // Load the blocklist JSON from the shared app group
        let appGroupIdentifier = "group.reclaim-app.Reclaim"

        guard let sharedContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            NSLog("❌ Failed to access shared container")
            context.cancelRequest(withError: NSError(
                domain: "ContentBlocker",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to access shared container"]
            ))
            return
        }

        let blocklistURL = sharedContainer.appendingPathComponent("blockerList.json")

        NSLog("📂 Loading blocklist from: \(blocklistURL.path)")

        // Check if blocklist exists, create empty one if it doesn't
        if !FileManager.default.fileExists(atPath: blocklistURL.path) {
            NSLog("⚠️ Blocklist file doesn't exist, creating empty blocklist")

            // Create empty blocklist
            let emptyBlocklist = "[]"
            try? emptyBlocklist.write(to: blocklistURL, atomically: true, encoding: .utf8)
        }

        // Attach the blocklist JSON
        guard let attachment = NSItemProvider(contentsOf: blocklistURL) else {
            NSLog("❌ Failed to create item provider")
            context.cancelRequest(withError: NSError(
                domain: "ContentBlocker",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load blocklist"]
            ))
            return
        }

        let item = NSExtensionItem()
        item.attachments = [attachment]

        context.completeRequest(returningItems: [item], completionHandler: nil)

        NSLog("✅ Content blocker loaded successfully")
    }
}
