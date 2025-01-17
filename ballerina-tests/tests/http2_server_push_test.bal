// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/lang.'string as strings;
import ballerina/test;
import ballerina/http;

listener http:Listener serverPushFrontendEP = new(serverPushTestPort1);
listener http:Listener serverPushBackendEP = new(serverPushTestPort2, { httpVersion: "2.0" });

final http:Client serverPushClient = check new("http://localhost:" + serverPushTestPort1.toString());
final http:Client backendClientEP = check new("http://localhost:" + serverPushTestPort2.toString(), { httpVersion: "2.0" });

service /frontendHttpService on serverPushFrontendEP {

    resource function get .(http:Caller caller, http:Request clientRequest) returns error? {

        http:Request serviceReq = new;
        http:HttpFuture httpFuture = new;
        // Submit a request
        var submissionResult = backendClientEP->submit("GET", "/backendHttp2Service/main", serviceReq);
        if submissionResult is http:HttpFuture {
            httpFuture = submissionResult;
        } else {
            io:println("Error occurred while submitting a request");
            json errMsg = { "error": "error occurred while submitting a request" };
            check caller->respond(errMsg);
            return;
        }

        // Check whether promises exists
        http:PushPromise?[] promises = [];
        int promiseCount = 0;
        boolean hasPromise = backendClientEP->hasPromise(httpFuture);
        while (hasPromise) {
            http:PushPromise pushPromise = new;
            // Get the next promise
            var nextPromiseResult = backendClientEP->getNextPromise(httpFuture);
            if nextPromiseResult is http:PushPromise {
                pushPromise = nextPromiseResult;
            } else {
                io:println("Error occurred while fetching a push promise");
                json errMsg = { "error": "error occurred while fetching a push promise" };
                check caller->respond(errMsg);
            }

            io:println("Received a promise for " + pushPromise.path);
            // Store required promises
            promises[promiseCount] = pushPromise;
            promiseCount = promiseCount + 1;
            hasPromise = backendClientEP->hasPromise(httpFuture);
        }
        // By this time 3 promises should be received, if not send an error response
        if promiseCount != 3 {
            json errMsg = { "error": "expected number of promises not received" };
            check caller->respond(errMsg);
        }
        io:println("Number of promises received : " + promiseCount.toString());

        // Get the requested resource
        http:Response response = new;
        var result = backendClientEP->getResponse(httpFuture);
        if result is http:Response {
            response = result;
        } else {
            io:println("Error occurred while fetching response");
            json errMsg = { "error": "error occurred while fetching response" };
            check caller->respond(errMsg);
        }

        var responsePayload = response.getJsonPayload();
        json responseJsonPayload = {};
        if responsePayload is json {
            responseJsonPayload = responsePayload;
        } else {
            json errMsg = { "error": "expected response message not received" };
            check caller->respond(errMsg);
        }
        // Check whether correct response received
        string responseStringPayload = responseJsonPayload.toString();
        if !(strings:includes(responseStringPayload, "main")) {
            json errMsg = { "error": "expected response message not received" };
            check caller->respond(errMsg);
        }
        io:println("Response : " + responseStringPayload);

        // Fetch required promised responses
        foreach var p in promises {
            http:PushPromise promise = <http:PushPromise>p;
            http:Response promisedResponse = new;
            var promisedResponseResult = backendClientEP->getPromisedResponse(promise);
            if promisedResponseResult is http:Response {
                promisedResponse = promisedResponseResult;
            } else {
                io:println("Error occurred while fetching promised response");
                json errMsg = { "error": "error occurred while fetching promised response" };
                check caller->respond(errMsg);
            }

            json promisedJsonPayload = {};
            var promisedPayload = promisedResponse.getJsonPayload();
            if promisedPayload is json {
                promisedJsonPayload = promisedPayload;
            } else {
                json errMsg = { "error": "expected promised response not received" };
                check caller->respond(errMsg);
            }

            // check whether expected
            string expectedVal = promise.path.substring(1, 10);
            string promisedStringPayload = promisedJsonPayload.toString();
            if !(strings:includes(promisedStringPayload, expectedVal)) {
                json errMsg = { "error": "expected promised response not received" };
                check caller->respond(errMsg);
            }
            io:println("Promised resource : " + promisedStringPayload);
        }

        // By this time everything has went well, hence send a success response
        json successMsg = { "status": "successful" };
        check caller->respond(successMsg);
    }
}

service /backendHttp2Service on serverPushBackendEP {

    resource function get main(http:Caller caller, http:Request req) returns error? {

        io:println("Request received");

        // Send a Push Promise
        http:PushPromise promise1 = new("/resource1", "POST");
        check caller->promise(promise1);

        // Send another Push Promise
        http:PushPromise promise2 = new("/resource2", "POST");
        check caller->promise(promise2);

        // Send one more Push Promise
        http:PushPromise promise3 = new;
        // create with default params
        promise3.path = "/resource3";
        // set parameters
        promise3.method = "POST";
        check caller->promise(promise3);

        // Construct requested resource
        json msg = { "response": { "name": "main resource" } };

        // Send the requested resource
        check caller->respond(msg);

        // Construct promised resource1
        http:Response push1 = new;
        msg = { "push": { "name": "resource1" } };
        push1.setJsonPayload(msg);

        // Push promised resource1
        check caller->pushPromisedResponse(promise1, push1);

        http:Response push2 = new;
        msg = { "push": { "name": "resource2" } };
        push2.setJsonPayload(msg);

        // Push promised resource2
        check caller->pushPromisedResponse(promise2, push2);

        http:Response push3 = new;
        msg = { "push": { "name": "resource3" } };
        push3.setJsonPayload(msg);

        // Push promised resource3
        check caller->pushPromisedResponse(promise3, push3);
    }
}

//Test HTTP/2.0 Server Push scenario
@test:Config {
    groups: ["http2ServerPush"]
}
function testPushPromise() returns error? {
    http:Response|error response = serverPushClient->get("/frontendHttpService");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {status:"successful"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
