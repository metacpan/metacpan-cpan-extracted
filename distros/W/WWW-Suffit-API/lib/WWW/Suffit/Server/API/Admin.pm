package WWW::Suffit::Server::API::Admin;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::API::Admin - The Suffit API controller for admin management

=head1 SYNOPSIS

    use WWW::Suffit::Server::API::Admin;

=head1 DESCRIPTION

The Suffit API controller for admin management

This module uses the following configuration directives:

=over 8

=item JWS_Algorithm

Allowed JWS signing algorithms: B<HS256>, B<HS384>, B<HS512>, B<RS256>, B<RS384>, B<RS512>

    HS256   HMAC+SHA256 integrity
    HS384   HMAC+SHA384 integrity
    HS512   HMAC+SHA512 integrity
    RS256   RSA+PKCS1-V1_5 + SHA256 signature
    RS384   RSA+PKCS1-V1_5 + SHA384 signature
    RS512   RSA+PKCS1-V1_5 + SHA512 signature

Default: B<HS256>

=item SessionExpires

    SessionExpires +1h
    SessionExpires 3600

This directive defines time of session expiration in formatted time units

Default: 3600 (1 hour)

=item TokenExpires

    TokenExpires  +1d
    TokenExpires  86400
    TokenExpires  20h
    TokenExpires  1M

This directive defines expiration period of the issued JWT tokens

Default: 86400 (1 day)

=back

=head1 METHODS

List of internal methods

=head2 group_enroll

See L</"POST /api/admin/group/GROUPNAME/enroll">

=head2 group_del

See L</"DELETE /api/admin/group/GROUPNAME">

=head2 group_members

See L</"GET /api/admin/group/GROUPNAME/members">

=head2 group_get

See L</"GET /api/admin/group">
and L</"GET /api/admin/group/GROUPNAME">

=head2 group_set

See L</"POST /api/admin/group">
and L</"PUT /api/admin/group/GROUPNAME">

=head2 settings

See L</"GET /api/admin/settings">

=head2 realm_del

See L</"DELETE /api/admin/realm/REALMNAME">

=head2 realm_get

See L</"GET /api/admin/realm">
and L</"GET /api/admin/realm/REALMNAME">

=head2 realm_set

See L</"POST /api/admin/realm">
and L</"PUT /api/admin/realm/REALMNAME">

=head2 requirement_get

See L</"GET /api/admin/requirement">

=head2 route_del

See L</"DELETE /api/admin/route/ROUTENAME">

=head2 route_get

See L</"GET /api/admin/route">
and L</"GET /api/admin/route/ROUTENAME">

=head2 route_set

See L</"POST /api/admin/route">
and L</"PUT /api/admin/route/ROUTENAME">

=head2 route_search

See L</"GET /api/admin/search/route">

=head2 route_sysadd

See L</"POST /api/admin/sysroute">

=head2 route_sysget

See L</"GET /api/admin/sysroute">

=head2 user_del

See L</"DELETE /api/admin/user/USERNAME">

=head2 user_get

See L</"GET /api/admin/user">
and L</"GET /api/admin/user/USERNAME">

=head2 user_groups

See L</"GET /api/admin/user/USERNAME/groups">

=head2 user_passwd

See L</"PUT /api/admin/user/USERNAME/passwd">

=head2 user_search

See L</"GET /api/admin/search/user">

=head2 user_set

See L</"POST /api/admin/user">
and L</"PUT /api/admin/user/USERNAME">

=head1 API METHODS

List of API methods

=head2 GET /api/admin/group

Gets list of all existing groups

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/group

    > GET /api/admin/group HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Date: Mon, 15 May 2023 14:48:22 GMT
    < Content-Length: 292
    < Content-Type: application/json;charset=UTF-8
    <
    [
      {
        "description": "OWL Administrators",
        "groupname": "admin",
        "id": 3
      }
    ]

=head2 POST /api/admin/group

Adds new group

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      -X POST -d '{
        "groupname": "FooBar",
        "description": "Test group",
        "members": ["alice", "test"]
      }' \
      https://owl.localhost:8695/api/admin/group

    > POST /api/admin/group HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    > Content-Length: 112
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Date: Mon, 15 May 2023 15:00:57 GMT
    < Content-Length: 70
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    <
    {
      "description": "Test group",
      "groupname": "FooBar",
      "id": 9,
      "status": true
    }

=head2 GET /api/admin/group/GROUPNAME

Gets group's data by groupname

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/group/admin

    > GET /api/admin/group/admin HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Content-Length: 77
    < Content-Type: application/json;charset=UTF-8
    < Date: Mon, 15 May 2023 14:50:45 GMT
    < Server: OWL/1.00
    <
    {
      "description": "OWL Administrators",
      "groupname": "admin",
      "id": 3,
      "status": true
    }

=head2 PUT /api/admin/group/GROUPNAME

Edit the group

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      -X PUT -d '{
        "id": 9,
        "description": "Test group",
        "members": ["test"]
      }' \
      https://owl.localhost:8695/api/admin/group/FooBar

    > PUT /api/admin/group/FooBar HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    > Content-Length: 91
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Content-Type: application/json;charset=UTF-8
    < Date: Mon, 15 May 2023 15:06:28 GMT
    < Content-Length: 70
    < Server: OWL/1.00
    <
    {
      "description": "Test group",
      "groupname": "FooBar",
      "id": 9,
      "status": true
    }

=head2 DELETE /api/admin/group/GROUPNAME

Delete group by groupname

    # curl -v -X DELETE -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/group/FooBar

    > DELETE /api/admin/group/FooBar HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Date: Mon, 15 May 2023 15:13:31 GMT
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 30
    <
    {
      "code": "E0000",
      "status":true
    }

=head2 POST /api/admin/group/GROUPNAME/enroll

Add user to group members

    # curl -v -H "Authorization: OWL eyJh...j1rM" \
      -X POST -d '{
        "groupname": "wheel",
        "username": "bob"
      }' \
      https://owl.localhost:8695/api/admin/group/wheel/enroll

    > POST /api/admin/group/wheel/enroll HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...j1rM
    > Content-Length: 65
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Content-Length: 52
    < Date: Fri, 12 May 2023 13:18:34 GMT
    < Content-Type: application/json;charset=UTF-8
    < Server: OWL/1.00
    <
    {
      "groupname": "wheel",
      "status": true,
      "username": "bob"
    }

=head2 GET /api/admin/group/GROUPNAME/members

Gets user list of group by groupname

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/group/admin/members

    > GET /api/admin/group/admin/members HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Date: Mon, 15 May 2023 15:19:23 GMT
    < Content-Length: 161
    < Content-Type: application/json;charset=UTF-8
    <
    [
      {
        "id": 2,
        "name": "Administrator",
        "role": "Project's Administrator",
        "username": "admin"
      }
    ]

=head2 GET /api/admin/realm

Gets list of all existing realms

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/realm

    > GET /api/admin/realm HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Content-Type: application/json;charset=UTF-8
    < Server: OWL/1.00
    < Content-Length: 281
    < Date: Mon, 15 May 2023 15:40:09 GMT
    <
    [
      {
        "description": "This is restricted zone for test only",
        "id": 13,
        "realm": "Restricted zone",
        "realmname": "MagicalForest",
        "satisfy": "Any"
      }
    ]

=head2 POST /api/admin/realm

Adds new realm

    # curl -v -H "Authorization: OWL eyJh...ISuA" \
      -X POST -d '{
        "realmname": "MagicalForest",
        "realm": "Restricted zone",
        "satisfy": "Any",
        "description": "This is restricted zone for test only",
        "requirements": [1],
        "provider1": "User/Group",
        "entity1": "Group",
        "op1": "eq",
        "value1": "user",
        "routes": [
          "Stump"
        ]
      }' \
      https://owl.localhost:8695/api/admin/realm

    > POST /api/admin/realm HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...ISuA
    > Content-Length: 360
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Content-Length: 147
    < Content-Type: application/json;charset=UTF-8
    < Date: Mon, 15 May 2023 09:17:39 GMT
    < Server: OWL/1.00
    <
    {
      "description": "This is restricted zone for test only",
      "id": 13,
      "realm": "Restricted zone",
      "realmname": "MagicalForest",
      "satisfy": "Any",
      "status": true
    }

=head2 GET /api/admin/realm/REALMNAME

Gets realm's data by realmname

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/realm/MagicalForest

    > GET /api/admin/realm/MagicalForest HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    < Date: Mon, 15 May 2023 15:42:05 GMT
    < Content-Length: 149
    <
    {
      "description": "This is restricted zone for test only",
      "id": 13,
      "realm": "Restricted zone",
      "realmname": "MagicalForest",
      "satisfy": "Any",
      "status":true
    }

=head2 PUT /api/admin/realm/REALMNAME

Sets realm's data

    curl -v -H "Authorization: OWL eyJh...Bh7g" \
      -X PUT -d '{
        "id": 13,
        "realmname": "MagicalForest",
        "realm": "Restricted zone",
        "satisfy": "Any",
        "description": "This is restricted zone for test only 2",
        "requirements": [1],
        "provider1": "User/Group",
        "entity1": "Group",
        "op1": "eq",
        "value1": "user",
        "routes": [
          "Stump"
        ]
      }' \
      https://owl.localhost:8695/api/admin/realm/MagicalForest

    > PUT /api/admin/realm/MagicalForest HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...ISuA
    > Content-Length: 380
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Date: Mon, 15 May 2023 09:23:12 GMT
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 149
    < Server: OWL/1.00
    <
    {
      "description": "This is restricted zone for test only 2",
      "id": 13,
      "realm": "Restricted zone",
      "realmname": "MagicalForest",
      "satisfy": "Any",
      "status": true
    }

=head2 DELETE /api/admin/realm/REALMNAME

Delete realm by realmname

    # curl -v -X DELETE -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/realm/MagicalForest

    > DELETE /api/admin/realm/MagicalForest HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Date: Mon, 15 May 2023 15:51:02 GMT
    < Content-Length: 30
    < Content-Type: application/json;charset=UTF-8
    <
    {
      "code": "E0000",
      "status": true
    }

=head2 GET /api/admin/requirement

    GET /api/admin/requirement?realmname=<REALMNAME>

Get list of realm's requirement

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/requirement?realmname=Default

    > GET /api/admin/requirement?realmname=Default HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 302
    < Date: Mon, 15 May 2023 15:58:04 GMT
    <
    [
      {
        "entity": "Group",
        "id": 113,
        "op": "eq",
        "provider": "User\/Group",
        "realmname": "Default",
        "value": "admin"
      }
    ]

=head2 GET /api/admin/route

Get list of all existing routes

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/route

    > GET /api/admin/route HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Date: Mon, 15 May 2023 16:07:18 GMT
    < Content-Length: 783
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    <
    [
      {
        "base": "https://owl.localhost:8695",
        "id": 14,
        "is_sysroute": 0,
        "method": "ANY",
        "path": "/api/admin/*",
        "realmname": "Default",
        "routename": "AdminAPI",
        "url": "https://owl.localhost:8695/api/admin/*"
      }
    ]

=head2 POST /api/admin/route

Adds route's data

    # curl -v -H "Authorization: OWL eyJh...ISuA" \
      -X POST -d '{
        "realmname": "Default",
        "routename": "AdminAPI",
        "method": "ANY",
        "url": "https://owl.localhost:8695/api/admin/*"
      }' \
      https://owl.localhost:8695/api/admin/route

    > POST /api/admin/route HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...ISuA
    > Content-Length: 156
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Content-Length: 199
    < Content-Type: application/json;charset=UTF-8
    < Date: Sun, 07 May 2023 13:14:59 GMT
    < Server: OWL/1.00
    <
    {
      base": "https://owl.localhost:8695",
      "id":20,
      "method":"ANY",
      "path":"/api/admin/*",
      "realmname":"Default",
      "routename":"AdminAPI",
      "status":true,
      "url":"https://owl.localhost:8695/api/admin/*"
    }

=head2 GET /api/admin/route/ROUTENAME

Get route's data by routename

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/route/AdminAPI

    > GET /api/admin/route/AdminAPI HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Content-Length: 214
    < Date: Mon, 15 May 2023 16:09:28 GMT
    < Content-Type: application/json;charset=UTF-8
    < Server: OWL/1.00
    <
    {
      "base": "https://owl.localhost:8695",
      "id": 14,
      "is_sysroute": 0,
      "method": "ANY",
      "path": "/api/admin/*",
      "realmname": "Default",
      "routename": "AdminAPI",
      "status": true,
      "url": "https://owl.localhost:8695/api/admin/*"
    }

=head2 PUT /api/admin/route/ROUTENAME

Sets route's data

    # curl -v -H "Authorization: OWL eyJh...ISuA" \
      -X PUT -d '{
        "id": 20,
        "realmname": "Default",
        "method": "ANY",
        "url": "https://localhost:8695/api/admin/*"
      }' \
      https://owl.localhost:8695/api/admin/route/AdminAPI

    > PUT /api/admin/route/AdminAPI HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...ISuA
    > Content-Length: 136
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 191
    < Server: OWL/1.00
    < Date: Sun, 07 May 2023 13:22:01 GMT
    <
    {
      "base":"https://localhost:8695",
      "id":20,
      "method":"ANY",
      "path":"/api/admin/*",
      "realmname":"Default",
      "routename":"AdminAPI",
      "status":true,
      "url":"https://localhost:8695/api/admin/*"
    }

=head2 DELETE /api/admin/route/ROUTENAME

Delete route by routename

    # curl -v -X DELETE -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/route/api-backups

    > DELETE /api/admin/route/api-backups HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 30
    < Date: Mon, 15 May 2023 16:55:39 GMT
    <
    {
      "code": "E0000",
      "status": true
    }

=head2 GET /api/admin/search/route

    GET /api/admin/search/route?text=<FRAGMENT>

Performs search route by fragment

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/search/route?text=a

    > GET /api/admin/search/route?text=a HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Content-Length: 592
    < Content-Type: application/json;charset=UTF-8
    < Date: Mon, 15 May 2023 16:17:50 GMT
    <
    [
      {
        "base": "https://owl.localhost:8695",
        "id": 14,
        "is_sysroute": 0,
        "method": "ANY",
        "path": "/api/admin/*",
        "realmname": "Default",
        "routename": "AdminAPI",
        "url": "https://owl.localhost:8695/api/admin/*"
      }
    ]

=head2 GET /api/admin/search/user

    GET /api/admin/search/user?text=<FRAGMENT>

Performs search user by fragment

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/search/user?text=te

    > GET /api/admin/search/user?text=te HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Content-Length: 66
    < Date: Mon, 15 May 2023 12:21:29 GMT
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    <
    [
      {
        "id": 3,
        "name": "Test User",
        "role": "Test user",
        "username": "test"
      }
    ]

=head2 GET /api/admin/settings

Gets settings

    # curl -v -H "Authorization: OWL eyJh...r3bo" \
      https://owl.localhost:8695/api/admin/settings

    > GET /api/admin/settings HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...r3bo
    >
    < HTTP/1.1 200 OK
    < Content-Type: application/json;charset=UTF-8
    < Date: Sat, 29 Apr 2023 04:56:56 GMT
    < Content-Length: 30
    < Server: OWL/1.00
    <
    {
      "message": "Ok",
      "status": true
    }

=head2 GET /api/admin/sysroute

Returns list of all existing system routes

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/sysroute

    > GET /api/admin/sysroute HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Content-Type: application/json;charset=UTF-8
    < Date: Mon, 15 May 2023 16:24:11 GMT
    < Content-Length: 7860
    < Server: OWL/1.00
    <
    [
      {
        "method": "GET",
        "route": "/api",
        "routename": "api",
        "url": "https://owl.localhost:8695/api"
      }
    ]

=head2 POST /api/admin/sysroute

Adds system route to route list

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      -X POST -d '{
        "routes": ["api-checkits", "api-backups"]
      }' \
      https://owl.localhost:8695/api/admin/sysroute

    > POST /api/admin/sysroute HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    > Content-Length: 59
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Date: Mon, 15 May 2023 16:43:20 GMT
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 30
    <
    {
      "code": "E0000",
      "status": true
    }

=head2 GET /api/admin/user

Gets list of all existing users

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/user

    > GET /api/admin/user HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Date: Mon, 15 May 2023 11:53:55 GMT
    < Content-Length: 10517
    < Content-Type: application/json;charset=UTF-8
    <
    [
      {
        "algorithm": "SHA256",
        "attributes": "",
        "comment": "Test user for internal testing only",
        "created": 1678741533,
        "email": "test@owl.localhost",
        "flags": 0,
        "id": 3,
        "name": "Test User",
        "not_after": null,
        "not_before": 1678741533,
        "password": "9f86...0a08",
        "private_key": "",
        "public_key": "",
        "role": "Test user",
        "username": "test"
      }
    ]

=head2 POST /api/admin/user

Adds user's data

    # curl -v -H "Authorization: OWL eyJh...j1rM" \
      -X POST -d '{
        "username": "bob",
        "name": "Bob",
        "email": "bob@example.com",
        "password": "bob",
        "algorithm": "SHA256",
        "role": "Test user",
        "flags": 0,
        "not_after": null,
        "public_key": null,
        "private_key": null,
        "attributes": null,
        "comment": "Test user for unit testing only"
      }' \
      https://owl.localhost:8695/api/admin/user

    > POST /api/admin/user HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...j1rM
    > Content-Length: 367
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 12 May 2023 12:15:50 GMT
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 1530
    < Server: OWL/1.00
    <
    {
      "algorithm": "SHA256",
      "attributes": "",
      "comment": "Test user for unit testing only",
      "created": 1683893750,
      "email": "bob@example.com",
      "flags": 0,
      "id": 13,
      "name": "Bob",
      "not_after": 0,
      "not_before": 1683893750,
      "password": "81b6...8ce9",
      "private_key": "-----BEGIN RSA PRIVATE KEY-----...",
      "public_key": "-----BEGIN RSA PUBLIC KEY-----...",
      "role": "Test user",
      "status": true,
      "username": "bob"
    }

=head2 GET /api/admin/user/USERNAME

    GET /api/admin/user/<USERNAME>
    GET /api/admin/user/?username=<USERNAME>

Gets user's data by username

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/user/test

    > GET /api/admin/user/test HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Content-Length: 1544
    < Content-Type: application/json;charset=UTF-8
    < Date: Mon, 15 May 2023 12:03:36 GMT
    <
    {
      "algorithm": "SHA256",
      "attributes": "",
      "comment": "Test user for internal testing only",
      "created": 1678741533,
      "email": "test@owl.localhost",
      "flags": 0,
      "id": 3,
      "name": "Test User",
      "not_after": null,
      "not_before": 1678741533,
      "password": "9f86...0a08",
      "private_key": "",
      "public_key": "",
      "role": "Test user",
      "status": true,
      "username": "test"
    }

=head2 PUT /api/admin/user/USERNAME

Sets user's data

    # curl -v -H "Authorization: OWL eyJh...j1rM" \
      -X PUT -d '{
        "id": 13,
        "username": "bob",
        "name": "Bob Bob",
        "email": "bob@example.com",
        "password": "bob",
        "algorithm": "SHA256",
        "role": "Test user",
        "flags": 0,
        "not_after": null,
        "public_key": null,
        "private_key": null,
        "attributes": null,
        "comment": "Test user for unit testing only"
      }' \
      https://owl.localhost:8695/api/admin/user/bob

    > PUT /api/admin/user/bob HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...j1rM
    > Content-Length: 389
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 12 May 2023 12:21:07 GMT
    < Content-Type: application/json;charset=UTF-8
    < Server: OWL/1.00
    < Content-Length: 1536
    <
    {
      "algorithm": "SHA256",
      "attributes": "",
      "comment": "Test user for unit testing only",
      "created": 1683893750,
      "email": "bob@example.com",
      "flags": 0,
      "id": 13,
      "name": "Bob Bob",
      "not_after": 0,
      "not_before": 1683894066,
      "password": "81b6...8ce9",
      "private_key": "-----BEGIN RSA PRIVATE KEY-----...",
      "public_key": "-----BEGIN RSA PUBLIC KEY-----...",
      "role": "Test user",
      "status": true,
      "username": "bob"
    }

=head2 DELETE /api/admin/user/USERNAME

Delete user by username

    # curl -v -X DELETE -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/user/bob.bob

    > DELETE /api/admin/user/bob.bob HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Content-Length: 30
    < Date: Mon, 15 May 2023 12:11:42 GMT
    < Content-Type: application/json;charset=UTF-8
    < Server: OWL/1.00
    <
    {
      "code": "E0000",
      "status": true
    }

=head2 GET /api/admin/user/USERNAME/groups

Returns list user's groups

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      https://owl.localhost:8695/api/admin/user/test/groups

    > GET /api/admin/user/test/groups HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    >
    < HTTP/1.1 200 OK
    < Date: Mon, 15 May 2023 12:27:43 GMT
    < Server: OWL/1.00
    < Content-Length: 64
    < Content-Type: application/json;charset=UTF-8
    <
    [
      {
        "description": "Unprivileged users",
        "groupname": "user",
        "id": 2
      }
    ]

=head2 PUT /api/admin/user/USERNAME/passwd

Set password for user

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      -X PUT -d '{"password": "test"}' \
      https://owl.localhost:8695/api/admin/user/test/passwd

    > PUT /api/admin/user/test/passwd HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...Bh7g
    > Content-Length: 20
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Content-Length: 30
    < Date: Mon, 15 May 2023 12:34:18 GMT
    < Content-Type: application/json;charset=UTF-8
    < Server: OWL/1.00
    <
    {
      "code": "E0000",
      "status": true
    }

=head1 ERROR CODES

The list of Admin Suffit API error codes

    API   | HTTP  | DESCRIPTION
   -------+-------+-------------------------------------------------
    E1200   [400]   Incorrect username
    E1201   [404]   User not found
    E1202   [400]   Incorrect password
    E1203   [400]   Incorrect search text
    E1204   [400]   Incorrect groupname
    E1205   [400]   Incorrect email address
    E1206   [400]   Incorrect full name
    E1207   [400]   Incorrect digest algorithm
    E1208   [400]   Incorrect role
    E1209   [400]   Incorrect flags
    E1210   [404]   Group not found
    E1211   [400]   Incorrect realmname
    E1212   [400]   Incorrect type of requirements list. Array expected
    E1213   [400]   Incorrect type of routes list. Array expected
    E1214   [404]   Realm not found
    E1215   [500]   Can't generate RSA keys (user_set)
    E1216   [500]   Can't set user data to database (user_set)
    E1217   [500]   Can't get data from database by username (user_set)
    E1218   [500]   Can't get data from database by groupname (group_set)
    E1219   [500]   Can't set realm data
    E1220   [500]   Can't group delete (group_del)
    E1221   [500]   Can't set group data (group_set)
    E1222   [500]   Can't user delete (user_del)
    E1223   [500]   Can't set password (user_passwd)
    E1224   [500]   Can't group enroll (group_enroll)
    E1225   [500]   Can't get data from database by realmname (realm_set)
    E1226   [500]   Can't realm delete (realm_del)
    E1227   [400]   Incorrect routename
    E1228   [404]   Route not found
    E1229   [400]   Incorrect URL
    E1230   [500]   Can't set route data (route_set)
    E1231   [500]   Can't get data from database by routename (route_set)
    E1232   [500]   Can't route delete (route_del)
    E1233   [500]   Can't route set (route_sysadd)
    E1234   [400]   Incorrect JWS algorithm (settings)
    E1235   [400]   Incorrect session expires value in seconds (settings)
    E1236   [400]   Incorrect token expires value in seconds (settings)
    E1237   [500]   Can't save meta parameter

B<*> -- this code will be defined later on the interface side

See also list of common Suffit API error codes in L<WWW::Suffit::API/"ERROR CODES">

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit>, L<WWW::Suffit::Server>, L<WWW::Suffit::API>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw/ true false /;
use Mojo::Util qw/ trim /;
use Mojo::URL;

use Acrux::Util qw/ parse_time_offset /;
use Acrux::RefUtil qw/ is_array_ref is_integer is_hash_ref /;

use WWW::Suffit::Const qw/ :security :session :misc /;

sub settings {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # POST (Save)
    if ($self->req->method eq 'POST') {
        # Get jwt_jws_algorithm
        my $algorithm = trim($self->req->json('/jwt_jws_algorithm') // '');
        return $self->reply->json_error(400 => "E1234" => "Incorrect JWS algorithm")
            unless length($algorithm) && scalar(grep {$algorithm eq $_} qw/HS256 HS384 HS512 RS256 RS384 RS512/);

        # Get session_expires
        my $session_expires = trim($self->req->json('/session_expires') || 0);
        return $self->reply->json_error(400 => "E1235" => "Incorrect session expires value in seconds")
            unless is_integer($session_expires) && $session_expires >= 0;

        # Get token_expires
        my $token_expires = trim($self->req->json('/token_expires') || 0);
        return $self->reply->json_error(400 => "E1236" => "Incorrect token expires value in seconds")
            unless is_integer($token_expires) && $token_expires >= 0;

        # Save settings
        $authdb->meta(jws_algorithm => $algorithm)
            or return $self->reply->json_error($authdb->code, $authdb->error || "E1237: Can't save meta parameter");
        $authdb->meta(sessionexpires => $session_expires)
            or return $self->reply->json_error($authdb->code, $authdb->error || "E1237: Can't save meta parameter");
        $authdb->meta(tokenexpires => $token_expires)
            or return $self->reply->json_error($authdb->code, $authdb->error || "E1237: Can't save meta parameter");
    }

    # Render ok
    my $jws_algorithm = $authdb->meta('jws_algorithm') || $self->conf->latest("/jws_algorithm");
        return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
    my $sessionexpires = $authdb->meta('sessionexpires') || parse_time_offset($self->conf->latest("/sessionexpires") || SESSION_EXPIRATION);
        return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
    my $tokenexpires = $authdb->meta('tokenexpires') || parse_time_offset($self->conf->latest("/tokenexpires") || TOKEN_EXPIRATION);
        return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render ok
    return $self->reply->json_ok({
        'time' => time,
        jwt_jws_algorithms => [
            {name => 'HS256', title => 'HMAC+SHA256 integrity', is_default => true},
            {name => 'HS384', title => 'HMAC+SHA384 integrity'},
            {name => 'HS512', title => 'HMAC+SHA512 integrity'},
            {name => 'RS256', title => 'RSA+PKCS1-V1_5 + SHA256 signature'},
            {name => 'RS384', title => 'RSA+PKCS1-V1_5 + SHA384 signature'},
            {name => 'RS512', title => 'RSA+PKCS1-V1_5 + SHA512 signature'},
        ],
        jwt_jws_algorithm   => $jws_algorithm,
        session_expires     => $sessionexpires,
        token_expires       => $tokenexpires,
        public_key          => $self->app->public_key,
    });
}
sub user_del {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get username from path
    my $username = trim($self->param('username') // '');
    return $self->reply->json_error(400 => "E1200" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;

    # Get pure data from AuthDB
    my %data = $authdb->user_get($username);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
    return $self->reply->json_error(404 => "E1201" => "User not found") unless $data{id};

    # Delete from database
    $authdb->user_del($username)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1222: Can't user delete");

    # Render ok
    return $self->reply->json_ok;
}
sub user_get {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get username from query or path
    my $username = trim($self->param('username') // '');
    if (length($username)) {
        return $self->reply->json_error(400 => "E1200" => "Incorrect username")
            unless (length($username) <= 64) && $username =~ USERNAME_REGEXP;

        # Get user data from AuthDB
        my %data = $authdb->user_get($username);
        return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
        return $self->reply->json_error(404 => "E1201" => "User not found") unless $data{id};

        # Render ok
        return $self->reply->json_ok({%data});
    }

    # Get user list
    my @users = $authdb->user_get;
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render collection
    return $self->render(json => [@users]);
}
sub user_set {
    my $self = shift;
    my %data = ();
    my $authdb = $self->authdb->clean;

    # Get data from request
    my $id = $self->req->json('/id') || 0;
    $data{id} = $id;

    # Get username
    my $username = trim($self->param('username') // $self->req->json('/username') // '');
    return $self->reply->json_error(400 => "E1200" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;
    $data{username} = $username;

    # Get email
    my $email = trim($self->req->json('/email') // '');
    return $self->reply->json_error(400 => "E1205" => "Incorrect email address")
        unless length($email) && (length($email) <= 255) && $email =~ EMAIL_REGEXP;
    $data{email} = $email;

    # Get name
    my $name = trim($self->req->json('/name') // '');
    return $self->reply->json_error(400 => "E1206" => "Incorrect full name")
        unless length($name) && (length($name) <= 255);
    $data{name} = $name;

    # Get password
    my $password = trim($self->req->json('/password') // '');
    unless ($id) { # If add user - check password!
        return $self->reply->json_error(400 => "E1202" => "Incorrect password")
            unless length($password) && (length($password) <= 255);
    }
    $data{password} = $password;

    # Get algorithm
    my $algorithm = uc(trim($self->req->json('/algorithm') // ''));
    return $self->reply->json_error(400 => "E1207" => "Incorrect digest algorithm")
        unless length($algorithm) && grep {$_ eq $algorithm} @{(DIGEST_ALGORITHMS())};
    $data{algorithm} = $algorithm;

    # Get role
    my $role = trim($self->req->json('/role') // '');
    return $self->reply->json_error(400 => "E1208" => "Incorrect role")
        unless length($role) && (length($role) <= 255);
    $data{role} = $role;

    # Get flags
    my $flags = trim($self->req->json('/flags') || 0);
    return $self->reply->json_error(400 => "E1209" => "Incorrect flags")
        unless is_integer($flags);
    $data{flags} = $flags;

    # Get not_after
    my $is_disabled = $self->req->json('/disabled') || 0;
    $data{not_after} = $is_disabled ? time() : undef;

    # Text fields
    foreach my $k (qw/public_key private_key attributes comment/) {
        my $v = $self->req->json("/$k") // '';
        $data{$k} = $v;
    }

    # Gen RSA keys
    unless (length($data{public_key}) || length($data{private_key})) {
        my %ks = $self->gen_rsakeys();
        return $self->reply->json_error(500 => "E1215" => $ks{error}) if $ks{error};
        $data{$_} = $ks{$_} for qw/public_key private_key/;
    }

    # Set user data
    $authdb->user_set(%data)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1216: Can't set user data to authorization database");

    # Get pure data from AuthDB
    my %user_data = $authdb->user_get($username);
        return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Check id
    return $self->reply->json_error(500 => "E1217" => "Can't get data from authorization database by username")
        unless $user_data{id};

    # Render ok
    return $self->reply->json_ok({%user_data});
}
sub user_groups {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get username from path
    my $username = trim($self->param('username') // '');
    return $self->reply->json_error(400 => "E1200" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;

    # Groups list
    my @groups = $authdb->user_groups($username);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render collection
    return $self->render(json => [@groups]);
}
sub user_passwd {
    my $self = shift;
    my %data = ();
    my $authdb = $self->authdb->clean;

    # Get username
    my $username = trim($self->param('username') // $self->req->json('/username') // '');
    return $self->reply->json_error(400 => "E1200" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;
    $data{username} = $username;

    # Get password
    my $password = trim($self->req->json('/password') // '');
    return $self->reply->json_error(400 => "E1202" => "Incorrect password")
        unless length($password) && (length($password) <= 255);
    $data{password} = $password;

    # Store data
    $authdb->user_passwd(%data)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1223: Can't set password");

    # Render ok
    return $self->reply->json_ok;
}
sub user_search {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get searchstring from query
    my $text = trim($self->param('text') // '');
    return $self->reply->json_error(400 => "E1203" => "Incorrect search text")
        unless length($text) <= 64;

    # User search
    my @users = $authdb->user_search($text);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render collection
    return $self->render(json => [@users]);
}
sub group_enroll {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get username
    my $username = $self->req->json('/username') // '';
    return $self->reply->json_error(400 => "E1200" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;

    # Get groupname
    my $groupname = trim($self->param('groupname')) // $self->req->json('/groupname') // '';
    return $self->reply->json_error(400 => "E1204" => "Incorrect groupname")
        unless length($groupname) && (length($groupname) <= 64) && $groupname =~ USERNAME_REGEXP;

    # Set data
    $authdb->group_enroll(
        username => $username,
        groupname => $groupname,
    ) or return $self->reply->json_error($authdb->code, $authdb->error || "E1224: Can't group enroll");

    # Render ok
    return $self->reply->json_ok({groupname => $groupname, username => $username});
}
sub group_del {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get groupname from path
    my $groupname = trim($self->param('groupname') // '');
    return $self->reply->json_error(400 => "E1204" => "Incorrect groupname")
        unless length($groupname) && (length($groupname) <= 64) && $groupname =~ USERNAME_REGEXP;

    # Get pure data from AuthDB
    my %data = $authdb->group_get($groupname);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
    return $self->reply->json_error(404 => "E1210" => "Group not found") unless $data{id};

    # Delete from database
    $authdb->group_del($groupname)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1220: Can't group delete");

    # Render ok
    return $self->reply->json_ok;
}
sub group_get {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get groupname from query or path
    my $groupname = trim($self->param('groupname') // '');
    if (length($groupname)) {
        return $self->reply->json_error(400 => "E1204" => "Incorrect groupname")
            unless (length($groupname) <= 64) && $groupname =~ USERNAME_REGEXP;

        # Get pure data from AuthDB
        my %data = $authdb->group_get($groupname);
        return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
        return $self->reply->json_error(404 => "E1210" => "Group not found") unless $data{id};

        # Render ok
        return $self->reply->json_ok({%data});
    }

    # Groups list
    my @groups = $authdb->group_get;
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render collection
    return $self->render(json => [@groups]);
}
sub group_set {
    my $self = shift;
    my %data = ();
    my $authdb = $self->authdb->clean;

    # Get data from request
    my $id = $self->req->json('/id') || 0;
    $data{id} = $id;

    # Get groupname
    my $groupname = trim($self->param('groupname') // $self->req->json('/groupname') // '');
    return $self->reply->json_error(400 => "E1204" => "Incorrect groupname")
        unless length($groupname) && (length($groupname) <= 64) && $groupname =~ USERNAME_REGEXP;
    $data{groupname} = $groupname;

    # Description
    $data{description} = $self->req->json("/description") // '';

    # Members
    $data{users} = $self->req->json("/members") || [];

    # Set group data
    $authdb->group_set(%data)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1221: Can't set group data");

    # Get pure data from AuthDB
    my %group_data = $authdb->group_get($groupname);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Check id
    return $self->reply->json_error(500 => "E1218" => "Can't get data from authorization database by groupname")
        unless $group_data{id};

    # Render ok
    return $self->reply->json_ok({%group_data});
}
sub group_members {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get groupname from query
    my $groupname = trim($self->param('groupname') // '');
    return $self->reply->json_error(400 => "E1204" => "Incorrect groupname")
        unless length($groupname) && (length($groupname) <= 64) && $groupname =~ USERNAME_REGEXP;

    # Members list
    my @members = $authdb->group_members($groupname);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render collection
    return $self->render(json => [@members]);
}
sub realm_del {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get realmname from path
    my $realmname = trim($self->param('realmname') // '');
    return $self->reply->json_error(400 => "E1211" => "Incorrect realmname")
        unless length($realmname) && (length($realmname) <= 64) && $realmname =~ USERNAME_REGEXP;

    # Get pure data from AuthDB
    my %data = $authdb->realm_get($realmname);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
    return $self->reply->json_error(404 => "E1214" => "Realm not found") unless $data{id};

    # Delete from database
    $authdb->realm_del($realmname)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1226: Can't realm delete");

    # Render ok
    return $self->reply->json_ok;
}
sub realm_get {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get realmname from query or path
    my $realmname = trim($self->param('realmname') // '');
    if (length($realmname)) {
        return $self->reply->json_error(400 => "E1211" => "Incorrect realmname")
            unless (length($realmname) <= 64) && $realmname =~ USERNAME_REGEXP;

        # Get pure data from AuthDB
        my %data = $authdb->realm_get($realmname);
        return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
        return $self->reply->json_error(404 => "E1214" => "Realm not found") unless $data{id};

        # Render ok
        return $self->reply->json_ok({%data});
    }

    # Realms list
    my @realms = $authdb->realm_get;
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render collection
    return $self->render(json => [@realms]);
}
sub realm_set {
    my $self = shift;
    my $authdb = $self->authdb->clean;
    my %data = ();

    # Get data from request
    my $id = $self->req->json('/id') || 0;
    $data{id} = $id;

    # Get realmname
    my $realmname = trim($self->param('realmname') // $self->req->json('/realmname') // '');
    return $self->reply->json_error(400 => "E1211" => "Incorrect realmname")
        unless length($realmname) && (length($realmname) <= 64) && $realmname =~ USERNAME_REGEXP;
    $data{realmname} = $realmname;

    # Realm
    $data{realm} = $self->req->json("/realm") // '';

    # Satisfy
    $data{satisfy} = $self->req->json("/satisfy") // '';

    # Description
    $data{description} = $self->req->json("/description") // '';

    # Requirements
    my @requirements = ();
    my $reqs = $self->req->json("/requirements") || [];
    return $self->reply->json_error(400 => "E1212" => "Incorrect type of requirements list. Array expected")
        unless is_array_ref($reqs);
    foreach my $cid (@$reqs) {
        next unless $cid;
        push @requirements, {
            provider    => $self->req->json("/provider$cid") || '',
            entity      => $self->req->json("/entity$cid") || '',
            op          => $self->req->json("/op$cid") || '',
            value       => $self->req->json("/value$cid") || '',
        };
    }
    $data{requirements} = [@requirements];
    #$self->log->warn($self->dumper( $data{requirements} ));

    # Requirements
    $data{routes} = $self->req->json("/routes") || [];
    return $self->reply->json_error(400 => "E1213" => "Incorrect type of routes list. Array expected")
        unless is_array_ref($data{routes});

    # Set data
    $authdb->realm_set(%data)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1219: Can't set realm data");

    # Get pure data from AuthDB
    my %ret = $authdb->realm_get($realmname);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Check id
    return $self->reply->json_error(500 => "E1225" => "Can't get data from database by realmname ($realmname)")
         unless $ret{id};

    # Render ok
    return $self->reply->json_ok({%ret});
}
sub requirement_get {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Requirements list
    my $realmname = trim($self->param('realmname') // '');
    return $self->reply->json_error(400 => "E1211" => "Incorrect realmname")
        unless length($realmname) && (length($realmname) <= 64) && $realmname =~ USERNAME_REGEXP;

    # Requirements list
    my @requirements = $authdb->realm_requirements($realmname);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render collection
    return $self->render(json => [@requirements]);
}
sub route_get {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Sysroute names
    my %sysroutes;
    $sysroutes{$_->{routename}} = 1 for $self->_get_sysroutes();

    # Get routename from query or path
    my $routename = trim($self->param('routename') // '');
    if (length($routename)) {
        return $self->reply->json_error(400 => "E1227" => "Incorrect routename")
            unless (length($routename) <= 64) && $routename =~ USERNAME_REGEXP;

        # Get pure data from AuthDB
        my %data = $authdb->route_get($routename);
        return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
        return $self->reply->json_error(404 => "E1228" => "Route not found") unless $data{id};

        # Render ok
        $data{is_sysroute} = $sysroutes{$routename} ? 1 : 0;
        return $self->reply->json_ok({%data});
    }

    # Routes list
    my $realmname = trim($self->param('realmname') // '');
    my @routes = $realmname ? $authdb->realm_routes($realmname) : $authdb->route_get();
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render collection
    return $self->render(json => [map {$_->{is_sysroute} = $sysroutes{$_->{routename}} ? 1 : 0; $_} @routes]);
}
sub route_set {
    my $self = shift;
    my %data = ();
    my $authdb = $self->authdb->clean;

    # Get data from request
    my $id = $self->req->json('/id') || 0;
    $data{id} = $id;

    # Get routename
    my $routename = trim($self->param('routename') // $self->req->json('/routename') // '');
    return $self->reply->json_error(400 => "E1227" => "Incorrect routename")
        unless length($routename) && (length($routename) <= 64) && $routename =~ USERNAME_REGEXP;
    $data{routename} = $routename;

    # Method
    $data{method} = $self->req->json("/method") // '';

    # URL
    $data{url} = $self->req->json("/url") // '';
    return $self->reply->json_error(400 => "E1229" => "Incorrect URL")
        unless length($data{url});
    my $url = Mojo::URL->new( $data{url} );
    $data{path} = $url->path->to_string // '/';
    $data{path} = '/' unless length($data{path});
    $data{base} = $url->path_query('/')->to_string // '';
    $data{base} =~ s/\/+$//;
    #$self->log->warn("Path = " . $data{path});

    # Realmname
    my $realmname = trim($self->req->json('/realmname') // '');
    if (length($realmname)) {
        return $self->reply->json_error(400 => "E1211" => "Incorrect realmname")
            unless (length($realmname) <= 64) && $realmname =~ USERNAME_REGEXP;
    }
    $data{realmname} = $realmname;

    # Set data
    #return $self->reply->json_error(500 => "E1566" => $authdb->error) unless ;
    $authdb->route_set(%data)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1230: Can't set route data");

    # Get pure data from AuthDB
    my %ret = $authdb->route_get($routename);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Check id
    return $self->reply->json_error(500 => "E1231" => "Can't get data from database by routename ($routename)")
        unless $ret{id};

    # Render ok
    return $self->reply->json_ok({%ret});
}
sub route_search {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Sysroute names
    my %sysroutes;
    $sysroutes{$_->{routename}} = 1 for $self->_get_sysroutes();

    # Get searchstring from query
    my $text = trim($self->param('text') // '');
    return $self->reply->json_error(400 => "E1203" => "Incorrect search text")
        unless length($text) <= 64;

    # Groups list
    my @routes = $authdb->route_search($text);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render collection
    return $self->render(json => [map {$_->{is_sysroute} = $sysroutes{$_->{routename}} ? 1 : 0; $_} @routes]);
}
sub route_sysadd {
    my $self = shift;
    my $authdb = $self->authdb->clean;
    my %routes = ();
    foreach my $r ($self->_get_sysroutes()) {
        $routes{$r->{routename}} = $r
    }

    # Get form routes
    my $frmroutes = $self->req->json("/routes") || [];
    foreach my $r (@$frmroutes) {
        my $data = $routes{$r};
        next unless $data && is_hash_ref($data);
        $authdb->route_set(%$data)
            or return $self->reply->json_error($authdb->code, $authdb->error || "E1233: Can't route set");
    }

    # Render ok
    return $self->reply->json_ok;
}
sub route_sysget {
    my $self = shift;
    my @routes = $self->_get_sysroutes();

    # Render collection
    return $self->render(json => [@routes]);
}
sub route_del {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get routename from path
    my $routename = trim($self->param('routename') // '');
    return $self->reply->json_error(400 => "E1227" => "Incorrect routename")
        unless length($routename) && (length($routename) <= 64) && $routename =~ USERNAME_REGEXP;

    # Get pure data from AuthDB
    my %data = $authdb->route_get($routename);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
    return $self->reply->json_error(404 => "E1228" => "Route not found") unless $data{id};

    # Delete from database
    $authdb->route_del($routename)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1232: Can't route delete");

    # Render ok
    return $self->reply->json_ok;
}

sub _get_sysroutes {
    my $self = shift;
    my @routes = ();
    my $children = $self->app->routes->children;
    my $url = $self->req->url->base->clone;
    my $walk = sub {
        my $this = shift;
        my $child = shift || [];
        foreach my $route (@$child) {
            if ($route->is_endpoint && !$route->partial) {
                my $methods = $route->can("methods") ? $route->methods : $route->via; # Fix for old Mojo
                push @routes, {
                    routename   => $route->name,
                    route       => $route->to_string || '/',
                    method      => uc(join ',', @{$methods // []}) || '*',
                    url         => $url->path($route->to_string)->to_string,
                };
            }
            $this->($this, $route->children);
        }
    };
    $walk->($walk, $children);
    return sort {$a->{routename} cmp $b->{routename}} @routes;
}

1;

__END__
