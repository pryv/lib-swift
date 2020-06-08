//
//  Event.swift
//  PryvApiSwiftKit
//
//  Created by Sara Alemanno on 08.06.20.
//

import Foundation

public struct Event {
    var id: String
    var streamIds: [String]
    var streamId: String
    var time: Double
    var duration: Double?
    var type: String
    var content: Any?
    var tags: [String]?
    var description: String?
    var attachments: [Attachment]?
    var clientData: Any?
    var trashed: Bool?
    var created: Double
    var createdBy: String
    var modified: Double
    var modifiedBy: String
}

public struct Attachment {
    var id: String
    var fileName: String
    var type: String
    var size: Int
    var readToken: String
}
