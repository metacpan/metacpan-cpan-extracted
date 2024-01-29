package WWW::Suffit::API;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

WWW::Suffit::API - The Suffit API

=head1 VERSION

API Version 1.01

=head1 DESCRIPTION

This library provides server API methods and describe it

=head2 MEDIA TYPES

The API currently supports only JSON as an exchange format. Be sure to set both the C<Content-Type>
and C<Accept> headers for every request as C<application/json>.

All Date objects are returned in L<ISO 8601|https://tools.ietf.org/html/rfc3339> format: C<YYYY-MM-DDTHH:mm:ss.SSSZ>
or in unixtime format (epoch), eg.: C<1682759233>

=head2 CHARACTER SET

API supports a subset of the UTF-8 specification. Specifically, any character that can be encoded in
three bytes or less is supported. BMP characters and supplementary characters that must be encoded
using four bytes aren't supported at this time.

=head2 HTTP METHODS

Where possible, the we strives to use appropriate HTTP methods for each action.

=head3 GET

Used for retrieving objects

=head3 POST

Used for creating objects or performing custom actions (such as user lifecycle operations).
For POST requests with no C<body> param, set the C<Content-Length> header to zero.

=head3 PUT

Used for replacing objects or collections. For PUT requests with no C<body> param, set the C<Content-Length> header to zero.

=head3 PATCH

Used for partially updating objects

=head3 DELETE

Used for deleting objects

=head2 IP ADDRESS

The public IP address of your application is automatically used as the client IP address for your request.
The API supports the standard C<X-Forwarded-For> HTTP header to forward the originating client's IP address
if your application is behind a proxy server or acting as a sign-in portal or gateway.

B<Note:> The public IP address of your trusted web application must be a part of the allowlist in your
org's network security settings as a trusted proxy to forward the user agent's original IP address
with the C<X-Forwarded-For> HTTP header.

=head2 ERRORS

All successful requests return a 200 status if there is content to return or a 204 status
if there is no content to return.

All requests that result in an error return the appropriate 4xx or 5xx error code with a custom JSON
error object:

    {
      "code": "E0001",
      "error": "API validation failed",
      "status": false
    }

or

    {
      "code": "E0001",
      "message": "API validation failed",
      "status": false
    }

=over 8

=item code

A code that is associated with this error type

=item error

A natural language explanation of the error

=item message

A natural language explanation of the error (=error)

=item status

Any errors always return the status false

=back

List of codes see L<WWW::Suffit::API/"ERROR CODES">

=head2 AUTHENTICATION

Suffit APIs support two authentication options: session and tokens.

The Suffit API requires the custom HTTP authentication scheme Token or Bearer for API token authentication.
Requests must have a valid API token specified in the HTTP Authorization header with the Token/Bearer
scheme or HTTP X-Token header.

For example:

    X-Token: 00QCjAl4MlV-WPXM...0HmjFx-vbGua
    Authorization: Token 00QCjAl4MlV-WPXM...0HmjFx-vbGua
    Authorization: Bearer 00QCjAl4MlV-WPXM...0HmjFx-vbGua

=head1 API METHODS

List of API methods

=head2 GET /api

Gets general API information

    # curl -v https://localhost:8695/api

    > GET /api HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 1507
    < Server: WWW::Suffit/1.00
    < Date: Sat, 29 Apr 2023 09:42:46 GMT
    <
    {
      "algorithms": [ ... ],
      "base_url": "https://localhost:8695",
      "code": "E0000",
      "csrf": "cf1b5f99a1c8480fb38a0f1e575d901d31dc0c90",
      "entities": { ... },
      "files": {},
      "generated": 1682761547,
      "message": "Session not exists! Please sign in or provide the token",
      "methods": [ ... ],
      "operators": [ ... ],
      "providers": [ ... ],
      "public_key": " ... ",
      "remote_addr": "127.0.0.1",
      "requestid": "7113e2fe",
      "route": "api",
      "status": true,
      "token": "",
      "user": {},
      "version": "1.00",
      "year": "2023"
    }

=head2 GET /api/check

Checks the ready state of API server

    # curl -v -H "Authorization: Bearer eyJh...s5aM" \
      https://localhost:8695/api/check

    > GET /api/check HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...s5aM
    >
    < HTTP/1.1 200 OK
    < Server: WWW::Suffit/1.00
    < Date: Sat, 29 Apr 2023 10:41:10 GMT
    < Content-Length: 104
    < Content-Type: application/json;charset=UTF-8
    <
    {
      "base_url": "https://localhost:8695",
      "time": 1682764944,
      "remote_addr": "127.0.0.1",
      "requestid": "3a8cbe4f",
      "status": true,
      "version": "1.00"
    }

=head2 GET /api/file

Gets file list (manifest)

    # curl -v -H "Authorization: Bearer eyJh...s5aM" \
      https://localhost:8695/api/file

    > GET /api/file HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...s5aM
    >
    < HTTP/1.1 200 OK
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 1947
    < Date: Sat, 29 Apr 2023 10:55:35 GMT
    < Server: WWW::Suffit/1.00
    <
    {
      "documentroot": "/home/test/public",
      "manifest": [
        {
          "absf": "/test/README.md",
          "directory": "test",
          "filename": "README.md",
          "id": 9962792,
          "pid": 9962787,
          "mdate": 1666333440,
          "path": "test/README.md",
          "perms": 436,
          "size": 333,
          "type": "file"
        }
      ],
      "status": true
    }

=head2 GET /api/file/FILEPATH

Download file from server

    # curl -v -H "Authorization: Bearer eyJh...GBew" \
      https://localhost:8695/foo/bar/test.txt

    > GET /foo/bar/test.txt HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...GBew
    >
    < HTTP/1.1 200 OK
    < Content-Type: text/plain;charset=UTF-8
    < Server: WWW::Suffit/1.00
    < Last-Modified: Fri, 19 May 2023 09:22:10 GMT
    < ETag: "df6c2ef1b599717f3f419da4b0ea0dbd"
    < Content-Length: 1234
    < Accept-Ranges: bytes
    < Date: Fri, 19 May 2023 09:24:58 GMT
    <
    ...content of the file...

=head2 PUT /api/file/FILEPATH

Upload file to server

    # curl -v -H "Authorization: Bearer eyJh...GBew" \
      -X PUT -F size=1234 \
      -F md5=ef20b7ac555ab6e04b71c13018602f70 -F fileraw=@test.txt.tmp \
      https://localhost:8695/api/file/foo/bar/test.txt

    > PUT /api/file/foo/bar/test.txt HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...GBew
    > Content-Length: 1662
    > Content-Type: multipart/form-data; boundary=------99d4d614cf7b933a
    > Expect: 100-continue
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 19 May 2023 09:36:41 GMT
    < Content-Length: 180
    < Server: WWW::Suffit/1.00
    < Content-Type: application/json;charset=UTF-8
    <
    {
      "code": "E0000",
      "file": "\/home\/foo\/tmp\/public\/foo\/bar\/test.txt",
      "md5":  "ef20b7ac555ab6e04b71c13018602f70",
      "size": "1234",
      "status": true,
      "uploaded": "2023-05-19T09:36:41Z"
    }

=head2 DELETE /api/file/FILEPATH

Remove file from server

    # curl -v -X DELETE -H "Authorization: Bearer eyJh...GBew" \
      https://localhost:8695/api/file/foo/bar/test.txt

    > DELETE /api/file/foo/bar/test.txt HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...GBew
    >
    < HTTP/1.1 200 OK
    < Server: WWW::Suffit/1.00
    < Content-Type: application/json;charset=UTF-8
    < Date: Fri, 19 May 2023 10:12:05 GMT
    < Content-Length: 30
    <
    {
      "code": "E0000",
      "status": true
    }

=head2 GET /api/status

Returns status information of the Suffit API server

    # curl -v -H "Authorization: Bearer eyJh...s5aM" \
      https://localhost:8695/api/status

    > GET /api/status HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...s5aM
    >
    < HTTP/1.1 200 OK
    < Server: WWW::Suffit/1.00
    < Date: Sat, 29 Apr 2023 10:49:14 GMT
    < Content-Length: 394
    < Content-Type: application/json;charset=UTF-8
    <
    {
      "base_url": "https://localhost:8695",
      "dsn": "*see monm config file*",
      "elapsed": 0.000275,
      "mbutiny_collectors": [],
      "mbutiny_error": "App::MBUtiny not installed",
      "mbutiny_loaded": 0,
      "mbutiny_status": "UNKNOWN",
      "monm_dsn": "dbi:SQLite:dbname=/var/lib/monm/monm.db",
      "monm_error": "Can't connect to database: unable to open database file",
      "monm_loaded": 1,
      "monm_status": "FAILED",
      "status": true,
      "time": 1682765546
    }

=head2 POST /api/v1/authn

Authentication user

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      -X POST -d '{
        "username": "bob",
        "password": "123",
        "encrypted": false
      }' \
      https://localhost:8695/api/v1/authn

    > POST /api/v1/authn HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    > Content-Length: 90
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 401 Unauthorized
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 70
    < Date: Tue, 16 May 2023 15:17:23 GMT
    < Server: WWW::Suffit/1.00
    <
    {
      "code": "E1311",
      "message": "Wrong username or password",
      "status": false
    }

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      -X POST -d '{
        "username": "bob",
        "password": "bob",
        "encrypted": false
      }' \
      https://localhost:8695/api/v1/authn

    > POST /api/v1/authn HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    > Content-Length: 90
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Server: WWW::Suffit/1.00
    < Date: Tue, 16 May 2023 15:18:54 GMT
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 30
    <
    {
      "code": "E0000",
      "status": true
    }

=head2 POST /api/v1/authz

Authorization and check access grants

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      -X POST -d '{
        "username": "bob",
        "method": "HEAD",
        "url": "https://metacpan.org/release/SRI/Mojolicious-9.32/source/lib/Mojo/URL.pm",
        "headers": {
            "Accept": "text/html,text/plain",
            "Connection": "keep-alive",
            "Host": "localhost:8695"
        }
      }' \
      https://localhost:8695/api/v1/authz

    > POST /api/v1/authz HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    > Content-Length: 311
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Date: Tue, 16 May 2023 16:54:55 GMT
    < Content-Type: application/json;charset=UTF-8
    < Server: WWW::Suffit/1.00
    < Content-Length: 30
    <
    {
      "code": "E0000",
      "status": true
    }

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      -X POST -d '{
        "username": "bob",
        "method": "GET",
        "url": "https://localhost:8695/api/check"
      }' \
      https://localhost:8695/api/v1/authz

    > POST /api/v1/authz HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    > Content-Length: 115
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 403 Forbidden
    < Server: WWW::Suffit/1.00
    < Content-Length: 79
    < Content-Type: application/json;charset=UTF-8
    < Date: Tue, 16 May 2023 17:33:23 GMT
    <
    {
      "code": "E1205",
      "message": "Access denied by realm restrictions",
      "status": false
    }

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      -X POST -d '{
        "username": "bob",
        "method": "HEAD",
        "url": "https://metacpan.org/release/SRI/Mojolicious-9.32/source/lib/Mojo/URL.pm",
        "headers": {
            "Accept": "text/html,text/plain",
            "Connection": "keep-alive",
            "Host": "localhost:8695"
        },
        "verbose": true
      }' \
      https://localhost:8695/api/v1/authz

    > POST /api/v1/authz HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    > Content-Length: 336
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Date: Tue, 16 May 2023 18:05:52 GMT
    < Content-Type: application/json;charset=UTF-8
    < Server: WWW::Suffit/1.00
    < Content-Length: 198
    <
    {
      "code": "E0000",
      "email": "bob@example.com",
      "email_md5": "4b9bb80620f03eb3719e0a061c14283d",
      "expires": 1684260497,
      "groups": [],
      "name": "Bob Bob",
      "role": "Test user",
      "status": true,
      "uid": 13,
      "username": "bob"
    }

=head2 GET /api/v1/publicKey

Get RSA public key of user (the token issuer)

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      https://localhost:8695/api/v1/publicKey

    > GET /api/v1/publicKey HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 01 Sep 2023 16:59:51 GMT
    < Server: WWW::Suffit/1.03
    < Content-Length: 303
    < Content-Type: application/json;charset=UTF-8
    <
    {
      "code": "E0000",
      "public_key": "-----BEGIN RSA PUBLIC KEY----- ...",
      "status": true
    }

=head2 POST /authorize

This method performs authentication and authorization on the Suffit API server,
then returns the access token

    # curl -v -X POST \
      -H "Accept: application/json" \
      -d '{
        "username": "test",
        "password": "test",
        "encrypted": false
      }' \
      https://localhost:8695/authorize

    # curl -v -X POST \
      -H "Accept: application/json" \
      -F username=test -F password=test \
      https://localhost:8695/authorize

    > POST /authorize HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: application/json
    > Content-Length: 248
    > Content-Type: multipart/form-data; boundary=-----6a21ca7cea8dc981
    >
    < HTTP/1.1 200 OK
    < Date: Thu, 11 May 2023 14:30:34 GMT
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 635
    < Server: WWW::Suffit/1.00
    <
    {
      "clientid": "f459f12619c961122450ae5883e44a60",
      "code": "E0000",
      "datetime": "2023-12-17T07:47:56Z",
      "elapsed": 0.313583,
      "encrypted": false,
      "expires": "2023-12-18T07:47:56Z",
      "jti": "kB...hO",
      "message": "The user is successfully authorized",
      "referer": "",
      "status": true,
      "token": "ey...1o",
      "type": "access",
      "user": {
        "algorithm": "SHA256",
        "attributes": "",
        "comment": "Test user for internal testing only",
        "created": 1678741533,
        "email": "test@localhost",
        "email_md5": "163e50783979333ebae6fd63b2d96d16",
        "expires": 1702799576,
        "flags": 31,
        "groups": [
          "user"
        ],
        "name": "Test User",
        "not_after": 0,
        "not_before": 1695334721,
        "public_key": "-----BEGIN RSA PUBLIC KEY-----...",
        "role": "Test user",
        "uid": 3,
        "username": "test"
      }
    }

=head2 ERROR CODES

=over 8

=item B<E0xxx> -- General errors

E01xx, E02xx, E03xx, E04xx and E05xx are reserved as HTTP errors

    E0000   Ok (general)
    E0100   Continue
    E0200   OK (HTTP)
    E0300   Multiple Choices
    E0400   Bad Request
    E0500   Internal Server Error

=item B<E1xxx> -- API errors

B<Auth: E10xx>

    E1000   [Auth::is_authorized_api] Access denied. No token/session exists
    E1001   [Auth::is_authorized_api] Access denied. JWT error
    E1002   [Auth::is_authorized_api] Access denied. The token has been revoked
    E1003   [Auth::is_authorized_api] Access denied. Session is not authorized
    E1004   [Auth::is_authorized_api] Access denied by realm restrictions
    E1005   [Auth::is_authorized_api] The database is not initialized
    E1010   [Auth::_authen]         No username specified
    E1011   [Auth::_authen]         No password specified
    E1012   [Auth::_authen]         Wrong username or password
    E1020   [Auth::_authz]          No username
    E1021   [Auth::_authz]          Access denied (authz)
    E1022   [Auth::_authz]          Access denied (access)
    E1030   [Login::logged_in]      User is not authenticated
    E1031   [Login::logged_in]      Access denied
    E1032   [Login::logged_in]      The database is not initialized
    E1040   [Login::login]          Access denied
    E1041   [Login::login]          Can't JWT generate
    E1042   [Login::login]          Wrong username or password, please try again
    E1043   [Login::login]          Can't token store to database
    E1050   [Login::token]          Token for user is frozen
    E1060   [Auth::authorize]       Incorrect username or password
    E1061   [Auth::authorize]       Access denied
    E1062   [Auth::authorize]       Can't JWT generate
    E1063   [Auth::authorize]       Can't token store to database
    E1064   [Auth::authorize]       RSA decode error

B<API: E11xx>

    E1100   [API::api]              The stored token not found. Please logout and login again
    E1110   [API::file_*]           No file path specified
    E1111   [API::file_*]           Incorrect file path
    E1112   [API::file_*]           File not found
    E1113   [API::file_*]           Can't upload file
    E1114   [API::file_*]           Can't upload file: file is lost
    E1115   [API::file_*]           File size mismatch
    E1116   [API::file_*]           File md5 checksum mismatch

B<API::V1: E12xx>

    E1200   [V1::authn]             No RSA public key found
    E1201   [V1::authn]             No RSA private key found
    E1202   [V1::authn]             RSA decrypt error
    E1203   [V1::authn]             Incorrect username or password
    E1204   [V1::authn]             Access denied (authz)
    E1205   [V1::authn]             Access denied by realm restrictions (access)

B<AuthDB: E13xx>

    E1300   [AuthDB::load]          Can't load file. File not found
    E1301   [AuthDB::load]          Can't load data from file
    E1302   [AuthDB::load]          File did not return a JSON object
    E1303   [AuthDB::save]          Can't serialize data to JSON
    E1304   [AuthDB::save]          Can't save data to file
    E1305   [AuthDB::authen]        No username specified
    E1306   [AuthDB::authen]        The username is too long (1-256 chars required)
    E1307   [AuthDB::authen]        No password specified
    E1308   [AuthDB::authen]        The password is too long (1-256 chars required)
    E1309   [AuthDB::authen]        Account is hold on 5 min
    E1310   [AuthDB::authen]        Incorrect digest algorithm
    E1311   [AuthDB::authen]        Wrong username or password
    E1312   [AuthDB::authz]         No username specified
    E1313   [AuthDB::authz]         The username is too long (1-256 chars required)
    E1314   [AuthDB::authz]         User is disabled
    E1315   [AuthDB::user_set]      Incorrect digest algorithm
    E1316   [AuthDB::user_set]      User already exists
    E1317   [AuthDB::user_passwd]   No user found
    E1318   [AuthDB::user_passwd]   Incorrect digest algorithm
    E1319   [AuthDB::user_passwd]   No password specified
    E1320   [AuthDB::user_edit]     No user found
    E1321   [AuthDB::user_genkeys]  No user found
    E1322   [AuthDB::group_set]     Group already exists
    E1323   [AuthDB::realm_set]     Realm already exists
    E1324   [AuthDB::route_set]     Route already exists
    E1325   [AuthDB::meta]          No key specified
    E1330   [User::is_valid]        User not found
    E1331   [User::is_valid]        Incorrect username stored
    E1332   [User::is_valid]        Incorrect password stored
    E1333   [User::is_valid]        The user data is expired
    E1334   [Group::is_valid]       The user data is expired
    E1335   [Group::is_valid]       Incorrect groupname stored
    E1336   [Group::is_valid]       The group data is expired
    E1337   [Realm::is_valid]       Incorrect realmname
    E1338   [Realm::is_valid]       The realm data is expired
    E1339   [AuthDB::authz]         External requests is blocked
    E1340   [AuthDB::authz]         Internal requests is blocked

B<API::Profile: E14xx>

    E1400   [Profile::token_get]    Incorrect username
    E1401   [Profile::token_set]    Incorrect username
    E1402   [Profile::token_set]    Can't JWT generate
    E1403   [Profile::token_set]    Can't set token
    E1404   [Profile::token_set]    Can't get token
    E1405   [Profile::token_del]    Incorrect jti
    E1406   [Profile::token_del]    Incorrect username
    E1407   [Profile::token_del]    Can't delete token
    E1408   [Profile::genkeys]      Incorrect username
    E1409   [Profile::genkeys]      Can't generate RSA keys
    E1410   [Profile::genkeys]      Can't set RSA keys
    E1411   [Profile::passwd]       Incorrect username
    E1412   [Profile::passwd]       Incorrect current password
    E1413   [Profile::passwd]       Incorrect new password
    E1414   [Profile::passwd]       Incorrect current password
    E1415   [Profile::passwd]       Can't set password
    E1416   [Profile::user_set]     Incorrect username
    E1417   [Profile::user_set]     Can't set user (edit)

B<API::Admin: E15xx>

    E1500   [Admin::user_del]       Incorrect username
    E1501   [Admin::user_del]       Can't get user data
    E1502   [Admin::user_del]       User not found
    E1503   [Admin::user_del]       Can't user delete
    E1504   [Admin::user_get]       Incorrect username
    E1505   [Admin::user_get]       Can't get user data
    E1506   [Admin::user_get]       No user found
    E1507   [Admin::user_get]       Can't get user list
    E1508   [Admin::user_set]       Incorrect username
    E1509   [Admin::user_set]       Incorrect email
    E1510   [Admin::user_set]       Incorrect full name
    E1511   [Admin::user_set]       Incorrect password
    E1512   [Admin::user_set]       Incorrect algorithm
    E1513   [Admin::user_set]       Incorrect role
    E1514   [Admin::user_set]       Incorrect flags
    E1515   [Admin::user_set]       Can't generate RSA keys
    E1516   [Admin::user_set]       Can't set user data
    E1517   [Admin::user_set]       Can't get user data
    E1518   [Admin::user_set]       Can't get data from AuthDB by username
    E1519   [Admin::user_groups]    Incorrect username
    E1520   [Admin::user_groups]    Can't get groups list
    E1521   [Admin::user_passwd]    Incorrect username
    E1522   [Admin::user_passwd]    Incorrect password
    E1523   [Admin::user_passwd]    Can't set password
    E1524   [Admin::user_search]    Incorrect search text
    E1525   [Admin::user_search]    Can't find users
    E1526   [Admin::group_enroll]   Incorrect groupname
    E1527   [Admin::group_enroll]   Incorrect username
    E1528   [Admin::group_enroll]   Can't group enroll
    E1529   [Admin::group_del]      Incorrect groupname
    E1530   [Admin::group_del]      Can't get group data
    E1531   [Admin::group_del]      Group not found
    E1532   [Admin::group_del]      Can't group delete
    E1533   [Admin::group_get]      Incorrect groupname
    E1534   [Admin::group_get]      Can't get group data
    E1535   [Admin::group_get]      Group not found
    E1536   [Admin::group_get]      Can't get group list
    E1537   [Admin::group_set]      Incorrect groupname
    E1538   [Admin::group_set]      Can't set group data
    E1539   [Admin::group_set]      Can't get group data
    E1540   [Admin::group_set]      Can't get data from AuthDB by groupname
    E1541   [Admin::group_members]  Incorrect groupname
    E1542   [Admin::group_members]  Can't get group members
    E1543   [Admin::realm_del]      Incorrect realmname
    E1544   [Admin::realm_del]      Can't get realm data
    E1545   [Admin::realm_del]      Realm not found
    E1546   [Admin::realm_del]      Can't realm delete
    E1547   [Admin::realm_get]      Incorrect realmname
    E1548   [Admin::realm_get]      Can't get realm data
    E1549   [Admin::realm_get]      No realm found
    E1550   [Admin::realm_get]      Can't get realm list
    E1551   [Admin::realm_set]      Incorrect realmname
    E1552   [Admin::realm_set]      Incorrect type of requirements list. Array expected
    E1553   [Admin::realm_set]      Incorrect type of routes list. Array expected
    E1554   [Admin::realm_set]      Can't set realm data
    E1555   [Admin::realm_set]      Can't get realm data
    E1556   [Admin::realm_set]      Can't get data from AuthDB by realmname
    E1557   [Admin::requirement_get] Incorrect realmname
    E1558   [Admin::requirement_get] Can't get requirements
    E1559   [Admin::route_get]      Incorrect routename
    E1560   [Admin::route_get]      Can't get route data
    E1561   [Admin::route_get]      No route found
    E1562   [Admin::route_get]      Can't get route list
    E1563   [Admin::route_set]      Incorrect routename
    E1564   [Admin::route_set]      Incorrect URL
    E1565   [Admin::route_set]      Incorrect realmname
    E1566   [Admin::route_set]      Can't set route data
    E1567   [Admin::route_set]      Can't get route data
    E1568   [Admin::route_set]      Can't get data from AuthDB by routename
    E1569   [Admin::route_search]   Incorrect search text
    E1570   [Admin::route_search]   No routee found
    E1571   [Admin::route_sysadd]   Can't route set
    E1572   [Admin::route_del]      Incorrect routename
    E1573   [Admin::route_del]      Can't get route data
    E1574   [Admin::route_del]      Route not found
    E1575   [Admin::route_del]      Can't route delete
    E1576   [Admin::settings]       Incorrect input parameter
    E1577   [Admin::settings]       Can't save settings parameter

=item B<E2xxx> -- Database errors

    E2000   [Model::new]            The database is not initialized
    E2001   [Model::init]           Can't connect to database
    E2002   [Model::init]           Can't init database. Ping failed
    E2003   [Model::reconnect]      Can't reconnect to database
    E2004   [Model::reconnect]      Can't reinit database. Ping failed
    E2010   [Model::user_add]       Can't insert new record (DML_USER_ADD)
    E2011   [Model::user_get]       No username specified
    E2012   [Model::user_get]       Can't get record (DML_USER_GET)
    E2013   [Model::user_set]       No username specified
    E2014   [Model::user_set]       Can't update record (DML_USER_SET)
    E2015   [Model::user_passwd]    No username specified
    E2016   [Model::user_passwd]    Can't update record (DML_PASSWD)
    E2017   [Model::user_del]       No username specified
    E2018   [Model::user_del]       Can't delete record (DML_USER_DEL)
    E2019   [Model::user_getall]    Can't get records (DML_USER_GETALL)
    E2020   [Model::user_search]    Can't get records (DML_USER_SEARCH)
    E2021   [Model::user_groups]    No username specified
    E2022   [Model::user_groups]    Can't get records (DML_USER_GROUPS)
    E2023   [Model::user_edit]      No id of user specified
    E2024   [Model::user_edit]      Can't update record (DML_USER_EDIT)
    E2025   [Model::user_setkeys]   No id of user specified
    E2026   [Model::user_setkeys]   Can't update record (DML_USER_SETKEYS)
    E2027   [Model::user_tokens]    No username specified
    E2028   [Model::user_tokens]    Can't get records (DML_TOKEN_GET_BY_USERNAME)
    E2030   [Model::group_add]      Can't insert new record (DML_GROUP_ADD)
    E2031   [Model::group_get]      No groupname specified
    E2032   [Model::group_get]      Can't get record (DML_GROUP_GET)
    E2033   [Model::group_set]      No groupname specified
    E2034   [Model::group_set]      Can't update record (DML_GROUP_SET)
    E2035   [Model::group_del]      No groupname specified
    E2036   [Model::group_del]      Can't delete record (DML_GROUP_DEL)
    E2037   [Model::group_getall]   Can't get records (DML_GROUP_GETALL)
    E2038   [Model::group_members]  No groupname specified
    E2039   [Model::group_members]  Can't get records (DML_GROUP_MEMBERS)
    E2040   [Model::realm_add]      Can't insert new record (DML_REALM_ADD)
    E2041   [Model::realm_get]      No realmname specified
    E2042   [Model::realm_get]      Can't get record (DML_REALM_GET)
    E2043   [Model::realm_set]      No realmname specified
    E2044   [Model::realm_set]      Can't update record (DML_REALM_SET)
    E2045   [Model::realm_del]      No realmname specified
    E2046   [Model::realm_del]      Can't delete record (DML_REALM_DEL)
    E2047   [Model::realm_getall]   Can't get records (DML_REALM_GETALL)
    E2048   [Model::realm_requirements] No realmname specified
    E2049   [Model::realm_requirements] Can't get record(s) (DML_REQUIREMENT_GET_BY_REALM)
    E2050   [Model::realm_requirement_del] No realmname specified
    E2051   [Model::realm_requirement_del] Can't delete record (DML_REQUIREMENT_DEL_BY_REALM)
    E2052   [Model::requirement_add] Can't insert new record (DML_REQUIREMENT_ADD)
    E2053   [Model::realm_routes]   No realmname specified
    E2054   [Model::realm_routes]   Can't get record(s) (DML_ROUTE_GET_BY_REALM)
    E2060   [Model::route_add]      Can't insert new record (DML_ROUTE_ADD)
    E2061   [Model::route_get]      No routename specified
    E2062   [Model::route_get]      Can't get record(s) (DML_ROUTE_GET_BY_ROUTE)
    E2063   [Model::route_set]      No id specified
    E2064   [Model::route_set]      Can't update record (DML_ROUTE_SET)
    E2065   [Model::route_del]      No routename specified
    E2066   [Model::route_del]      Can't delete record (DML_ROUTE_DEL_BY_ROUTE)
    E2067   [Model::route_getall]   Can't get records (DML_ROUTE_GET*)
    E2068   [Model::route_search]   Can't get records (DML_ROUTE_SEARCH)
    E2069   [Model::route_release]  No realmname specified
    E2070   [Model::route_release]  Can't update record (DML_ROUTE_RELEASE_BY_REALM)
    E2071   [Model::route_assign]   No realmname specified
    E2072   [Model::route_assign]   No routename specified
    E2073   [Model::route_assign]   Can't update record (DML_ROUTE_ASSIGN_BY_ROUTE)
    E2080   [Model::grpusr_add]     Can't insert new record (DML_GRPUSR_ADD)
    E2081   [Model::grpusr_get]     No any conditions specified
    E2082   [Model::grpusr_get]     Can't get record(s) (DML_GRPUSR_GET_BY_*)
    E2083   [Model::grpusr_del]     No any conditions specified
    E2084   [Model::grpusr_del]     Can't delete record (DML_GRPUSR_DEL_BY_*)
    E2090   [Model::meta_set]       No key specified
    E2091   [Model::meta_set]       Can't insert or update record (DML_META_*)
    E2092   [Model::meta_get]       Can't get record (DML_META_GET)
    E2093   [Model::meta_get]       Can't get table (DML_META_GETALL)
    E2094   [Model::meta_del]       No key specified
    E2095   [Model::meta_del]       Can't delete record (DML_META_DEL)
    E2100   [Model::token_get]      No token's id specified
    E2101   [Model::token_get]      Can't get record (DML_TOKEN_GET)
    E2102   [Model::token_get_cond] No any conditions specified
    E2103   [Model::token_get_cond] Can't get record (DML_TOKEN_GET_BY_USERNAME_AND_*)
    E2104   [Model::token_getall]   Can't get records (DML_TOKEN_GET_*)
    E2105   [Model::token_add]      Can't insert new record (DML_TOKEN_ADD)
    E2106   [Model::token_set]      No token's id specified
    E2107   [Model::token_set]      Can't update record (DML_TOKEN_SET)
    E2108   [Model::token_del]      Can't delete expired tokens (DML_TOKEN_DEL_EXPIRED)
    E2109   [Model::token_del]      Can't delete record (DML_TOKEN_DEL)
    E2110   [Model::stat_get]       No address specified
    E2111   [Model::stat_get]       No username specified
    E2112   [Model::stat_get]       Can't get record (DML_STAT_GET)
    E2113   [Model::stat_set]       No address specified
    E2114   [Model::stat_set]       No username specified
    E2115   [Model::stat_set]       Can't insert or update record (DML_STAT_*)

=item B<E7xxx> -- Application errors

B<Auth: E70xx>

Errors that reserved for user applications

=back

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.01';

1;

__END__
