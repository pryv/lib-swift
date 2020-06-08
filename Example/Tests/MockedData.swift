//
//  MockedData.swift
//  PryvApiSwiftKitTests
//
//  Created by Sara Alemanno on 04.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

public final class MockedData {
    public static let serviceInfoResponse: Data = """
        {
          "register": "https://reg.pryv.me/",
          "access": "https://access.pryv.me/access",
          "api": "https://{username}.pryv.me/",
          "name": "Pryv Lab",
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
    
    public static let callBatchResponse = """
        {
          "results": [
            {
              "event": {
                "id": "ckb0rldt0000tq6pvrahee7gj",
                "time": 1385046854.282,
                "streamIds": [
                  "heart"
                ],
                "streamId": "heart",
                "tags": [],
                "type": "frequency/bpm",
                "content": 90,
                "created": 1591274234.916,
                "createdBy": "ckb0rldr90001q6pv8zymgvpr",
                "modified": 1591274234.916,
                "modifiedBy": "ckb0rldr90001q6pv8zymgvpr"
              }
            },
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
    
    public static let okResponse = """
        {
          "status": "ok"
        }
    """.data(using: .utf8)!
    
    public static let createEventResponse = """
        {
          "event": {
            "id": "ckb0rldt0000wq6pv1g9qxozc",
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
    """.data(using: .utf8)!
}
