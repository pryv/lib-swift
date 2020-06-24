//
//  MockedData.swift
//  PryvApiSwiftKitTests
//
//  Created by Sara Alemanno on 04.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import UIKit

public final class MockedData {
    public static let eventId = "eventId"
    
    public static let serviceInfoResponse: Data = """
        {
          "register": "https://reg.pryv.me/",
          "access": "https://access.pryv.me/access",
          "api": "https://{username}.pryv.me/",
          "name": "Pryv Test Lab",
          "home": "https://www.pryv.com",
          "support": "https://pryv.com/helpdesk",
          "terms": "https://pryv.com/pryv-lab-terms-of-use/",
          "eventTypes": "https://api.pryv.com/event-types/flat.json"
        }
    """.data(using: .utf8)!
    
    public static let authResponse: Data = """
        {
            "status": "NEED_SIGNIN",
            "code": 201,
            "key": "6CInm4R2TLaoqtl4",
            "requestingAppId": "test-app-id",
            "requestedPermissions": [
                {
                    "streamId": "diary",
                    "level": "read",
                    "defaultName": "Journal"
                },
                {
                    "streamId": "position",
                    "level": "contribute",
                    "defaultName": "Position"
                }
            ],
            "url": "https://sw.pryv.me/access/access.html?lang=fr&key=6CInm4R2TLaoqtl4&requestingAppId=test-app-id&domain=pryv.me&registerURL=https%3A%2F%2Freg.pryv.me&poll=https%3A%2F%2Freg.pryv.me%2Faccess%2F6CInm4R2TLaoqtl4",
            "authUrl": "https://sw.pryv.me/access/access.html?poll=https://reg.pryv.me/access/6CInm4R2TLaoqtl4",
            "poll": "https://reg.pryv.me/access/6CInm4R2TLaoqtl4",
            "oauthState": null,
            "poll_rate_ms": 1000.0,
            "lang": "fr",
            "serviceInfo": {
                  "register": "https://reg.pryv.me",
                  "access": "https://access.pryv.me/access",
                  "api": "https://{username}.pryv.me/",
                  "name": "Pryv Lab",
                  "home": "https://www.pryv.com",
                  "support": "https://pryv.com/helpdesk",
                  "terms": "https://pryv.com/pryv-lab-terms-of-use/",
                  "eventTypes": "https://api.pryv.com/event-types/flat.json"
            }
        }
    """.data(using: .utf8)!
    
    public static let loginResponse = """
        {
          "token": "ckay3nllh0002lkpv36t1pkyk",
          "preferredLanguage": "zh"
        }
    """.data(using: .utf8)!
    
    public static let basicEvent = """
        {
          "event": {
          "id": "\(eventId)",
            "time": 1591274234.916,
            "streamIds": [
              "weight"
            ],
            "streamId": "weight",
            "tags": [],
            "type": "mass/kg",
            "content": 90,
            "created": 1591274234.916,
            "createdBy": "ckb0rldr90001q6pv8zymgvpr",
            "modified": 1591274234.916,
            "modifiedBy": "ckb0rldr90001q6pv8zymgvpr"
          }
        }
    """
    
    public static let callBatchResponse = """
        {
          "results": [
            \(basicEvent),
            {
              "event": {
                "id": "ckb0rldt0000uq6pv9lvaluav",
                "time": 1385046854.282,
                "streamIds": [
                  "systolic"
                ],
                "streamId": "systolic",
                "tags": [],
                "type": "pressure/mmhg",
                "content": 120,
                "created": 1591274234.916,
                "createdBy": "ckb0rldr90001q6pv8zymgvpr",
                "modified": 1591274234.916,
                "modifiedBy": "ckb0rldr90001q6pv8zymgvpr"
              }
            }
          ]
        }
    """.data(using: .utf8)!
    
    public static let getEventsResponse = """
        {
            "results": [
                {
                  "events": [
                    {
                      "id": "ckbs1xuph000wuq0sn9clev8t",
                      "time": 1592924199.605,
                      "streamIds": [
                        "weight"
                      ],
                      "streamId": "weight",
                      "tags": [],
                      "type": "mass/kg",
                      "content": 90,
                      "created": 1592924199.605,
                      "createdBy": "ckbs1xumw0001uq0sj26o31t8",
                      "modified": 1592924199.605,
                      "modifiedBy": "ckbs1xumw0001uq0sj26o31t8"
                    }
                  ],
                  "eventDeletions": [
                    {
                      "id": "ckbs1xupw001cuq0s5smh0d4p",
                      "deleted": 1592920599.62
                    },
                    {
                      "id": "ckbs1xupw001duq0s8va1rc4j",
                      "deleted": 1592888199.62
                    },
                    {
                      "id": "ckbs1xupw001euq0sm3ibrpkp",
                      "deleted": 1592852199.62
                    }
                  ]
                }
            ]
        }
    """.data(using: .utf8)!
    
    public static let okResponse = """
        {
          "status": "ok"
        }
    """.data(using: .utf8)!
    
    public static let createEventResponse = basicEvent.data(using: .utf8)!
    
    public static let addAttachmentResponse = """
        {
          "event": {
            "id": "\(eventId)",
            "time": 1591274234.916,
            "streamIds": [
              "weight"
            ],
            "streamId": "weight",
            "tags": [],
            "type": "mass/kg",
            "content": 90,
            "attachments": [
              {
                "id": "ckb6fn2p9000r4y0s51ve4cx8",
                "fileName": "sample.pdf",
                "type": "application/pdf",
                "size": 111,
                "readToken": "ckb6fn2p9000s4y0slij89se5-JGZ6xx1vFDvSFsCxdoO4ptM7gc8"
              }
            ],
            "created": 1591274234.916,
            "createdBy": "ckb0rldr90001q6pv8zymgvpr",
            "modified": 1591274234.916,
            "modifiedBy": "ckb0rldr90001q6pv8zymgvpr"
          }
        }
    """.data(using: .utf8)!
    
    public static let imagePreview = Bundle(for: MockedData.self).url(forResource: "corona", withExtension: "jpg")!.dataRepresentation
}
