# NAME

WebService::Tuya::IoT::API - Perl library to access the Tuya IoT API

# SYNOPSIS

    use WebService::Tuya::IoT::API;
    my $ws             = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret);
    my $access_token   = $ws->access_token;
    my $device_status  = $ws->device_status($deviceid);
    my $response       = $ws->device_commands($deviceid, {code=>'switch_1', value=>$boolean ? \1 : \0});

# DESCRIPTION

Perl library to access the Tuya IoT API to control and read the state of Tuya compatible smart devices.

Tuya compatible smart devices include outlets, switches, lights, window covers, etc.

## SETUP

Other projects have documented device setup, so I will not go into details here.  The [TinyTuya](https://github.com/jasonacox/tinytuya#setup-wizard---getting-local-keys) setup documentation is the best that I have found. Please note some setup instructions step through the process of creating an app inside the Tuya IoT project, but I was able to use the Smart Life app for device discovery and pair the app with the API by scanning the QR code.

- You must configure your devices with the Smart Life ([iOS](https://apps.apple.com/us/app/smart-life-smart-living/id1115101477)) app.
- You must create an account and project on the [Tuya IoT Platform](https://iot.tuya.com/).
- You must link the Smart Life app to the project with the QR code. 
- You must configure the correct project data center to see your devices in the project (Note: My devices call the Western America Data Center even though I'm located in Eastern America).
- You must use the host associated to your data center. The default host is the Americas which is set as openapi.tuyaus.com.

# CONSTRUCTORS

## new

     my $ws = WebService::Tuya::IoT::API->new;
    

# PROPERTIES

## http\_hostname

Sets and returns the host name for the API service endpoint.

    $ws->http_hostname("openapi.tuyaus.com"); #Americas
    $ws->http_hostname("openapi.tuyacn.com"); #China
    $ws->http_hostname("openapi.tuyaeu.com"); #Europe
    $ws->http_hostname("openapi.tuyain.com"); #India

default: openapi.tuyaus.com

## client\_id

Sets and returns the Client ID found on https://iot.tuya.com/ project overview page.

## client\_secret

Sets and returns the Client Secret found on https://iot.tuya.com/ project overview page.

## api\_version

Sets and returns the API version string used in the URL on API web service calls.

    my $api_version = $ws->api_version;

default: v1.0

# METHODS

## api

Calls the Tuya IoT API and returns the parsed JSON data structure.  This method automatically handles access token and web request signatures.

    my $response = $ws->api(GET  => 'token?grant_type=1');                                                             #get access token
    my $response = $ws->api(GET  => "iot-03/devices/$deviceid/status");                                                #get status of $deviceid
    my $response = $ws->api(POST => "iot-03/devices/$deviceid/commands", {commands=>[{code=>'switch_1', value=>\0}]}); #set switch_1 off on $deviceid

References:

- https://developer.tuya.com/en/docs/iot/new-singnature?id=Kbw0q34cs2e5g
- https://github.com/jasonacox/tinytuya/blob/ffcec471a9c4bba38d5bf224608e20bc148f1b86/tinytuya/Cloud.py#L130
- https://bestlab-platform.readthedocs.io/en/latest/bestlab\_platform.tuya.html

## api\_get, api\_post, api\_put, api\_delete

Wrappers around the `api` method with hard coded HTTP methods.

## access\_token

Wrapper around `api` method which calls and caches the token web service for a temporary access token to be used for subsequent web service calls.

## device\_status

Wrapper around `api` method and the device status API destination.

    my $device_status = $ws->device_status($deviceid);

## device\_commands

Wrapper around `api` method and the device commands API destination.

    my $switch   = 'switch_1';
    my $value    = $boolean ? \1 : \0;
    my $response = $ws->device_commands($deviceid, {code=>$switch, value=>$value});

## device\_command\_code\_value

Wrapper around `device_commands` for one command with code and value keys;

    my $response = $ws->device_command_code_value($deviceid, $code, $value);

# ACCESSORS

## ua

Returns an [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny) web client user agent

# SEE ALSO

https://iot.tuya.com/, https://github.com/jasonacox/tinytuya, https://apps.apple.com/us/app/smart-life-smart-living/id1115101477, 

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2023 Michael R. Davis
