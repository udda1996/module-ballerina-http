// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import snowpeak.representations as rep;

public isolated function getLocations() returns rep:Locations|error {
    return { 
        locations: [
            {
                name: "Alps",
                id: "l1000",
                address: "NC 29384, some place, switzerland"
            },
            {
                name: "Pilatus",
                id: "l2000",
                address: "NC 29444, some place, switzerland"
            }
        ]
    };
}

public isolated function getRooms(string startDate, string endDate) returns rep:Rooms|error {
    return {
        rooms: [
            {
                id: "r1000",
                category: rep:DELUXE,
                capacity: 5,
                wifi: true,
                status: rep:AVAILABLE,
                currency: "USD",
                price: 200.00,
                count: 3
            }
        ]
    };
}

public isolated function createReservation(rep:Reservation reservation) returns rep:ReservationCreated|error {
    return {
        headers: {
            location: "/snowpeak/reservations/re1000"
        },
        body: {
            id: "re1000",
            expiryDate: "2021-07-01",
            lastUpdated: "2021-06-29T13:01:30Z",
            currency: "USD",
            total: 400.00,
            state: rep:VALID,
            reservation: {
                reserveRooms: [
                    {
                        id: "r1000",
                        count: 2
                    }
                ],
                startDate: "2021-08-01",
                endDate: "2021-08-03"
            }
        }
    };
}

public isolated function updateReservation(string id, rep:Reservation reservation) returns rep:ReservationUpdated|error {
    return {
        headers: {
            location: "/snowpeak/reservations/" + id
        },
        body: {
            id: id,
            expiryDate: "2021-07-01",
            lastUpdated: "2021-06-29T13:01:30Z",
            currency: "USD",
            total: 600.00,
            state: rep:VALID,
            reservation: {
                reserveRooms: [
                    {
                        id: reservation.reserveRooms[0].id,
                        count: 3
                    }
                ],
                startDate: reservation.startDate,
                endDate: reservation.endDate
            }
        }
    };
}

public isolated function cancelReservation(string id) returns rep:ReservationCanceled|error {
    return {
        body: {
            id: "re1000",
            expiryDate: "2021-07-01",
            lastUpdated: "2021-06-29T13:01:30Z",
            currency: "USD",
            total: 400.00,
            state: rep:CANCELED,
            reservation: {
                reserveRooms: [
                    {
                        id: "r1000",
                        count: 2
                    }
                ],
                startDate: "2021-08-01",
                endDate: "2021-08-03"
            }
        }
    };
}

public isolated function createPayment(string id, rep:Payment payment) returns rep:PaymentCreated|error {
    return {
        headers: {
            location: "/snowpeak/reservations/p1000"
        },
        body: {
            id: "p1000",
            currency: "USD",
            total: 400.00,
            lastUpdated: "2021-06-29T13:01:30Z",
            rooms: [
                    {
                    id: "r1000",
                    category: rep:DELUXE,
                    capacity: 5,
                    wifi: true,
                    status: rep:RESERVED,
                    currency: "USD",
                    price: 200.00,
                    count: 1
                }
            ]
        }
    };
}

