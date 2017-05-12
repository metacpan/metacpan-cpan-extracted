HOST: http://example
FORMAT: 1A

# SAMPLE API

This is a test document.

## POST /api/sample

+ Request

    + Headers

            Cookie: sid=71de3e2e5c1e7f15fecef9b25f74087d6bc41b01

    + Parameters
        + id (number) ... ID
        + title (string) ... Title
        + body (string) ... Body
        + gender (string) ... Gender(male|female)

+ Response 200 (application/json)

    + Headers

            X-Framework: Ark
            Cache-Control: max-age=100

    + Body

            {
                "status" : 200,
                "result": {
                    "ok": 1,
                }
            }


## GET /api/sample

+ Request

    + Headers

            Cookie: sid=71de3e2e5c1e7f15fecef9b25f74087d6bc41b01

+ Response 405 (application/json)

    + Body

            {
                "status" : 405,
                "error" : "コメントは1000文字以内です",
                "result": {
                    "ng": 1
                }
            }

## GET /api/sample/{id}

+ Request

    + Headers

            Cookie: sid=71de3e2e5c1e7f15fecef9b25f74087d6bc41b01

+ Response 200 (application/json)

    + Body

            {
                "status" : 200,
                "result": {
                    "id": 1,
                    "title": "こんにちは",
                    "body": "お世話になっております。"
                }
            }


## GET /api/xyz

hoge hoge ....

+ Response 200 (application/json)

    + Body

            {
                "status" : 200,
                "result": {
                    "ok": 1
                }
            }


## GET /api/abc/{id}

hoge hoge ....

+ Response 200 (application/json)

    + Body

            {
                "status" : 200,
                "result": {
                    "ok": 1
                }
            }


## OPTIONS /api/account

hoge hoge ....

+ Response 200 (application/json)

    + Body

            {
                "status" : 200,
                "error" : "コメントは1000文字以内です",
                "result": {
                    "ng": 1
                }
            }


