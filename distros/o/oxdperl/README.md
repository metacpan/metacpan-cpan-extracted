# oxd-perl

The README is used to introduce the module and provide instructions on
how to install the module, any machine dependencies it may have (for
example C compilers and installed libraries) and any other information
that should be provided before the module is installed.

A README file is required for CPAN modules since CPAN extracts the README
file from a module distribution so that people browsing the archive
can use it to get an idea of the module's uses. It is usually a good idea
to provide version information here so that people can decide whether
fixes for the module are worth downloading.


# INSTALLATION

To install this module, run the following commands on following path:
    
    Path : /var/www/html/oxd-perl/oxdPerl/
    
	perl Build.PL
	./Build
	./Build test
	./Build install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc oxdPerl

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=oxdPerl

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/oxdPerl

    CPAN Ratings
        http://cpanratings.perl.org/d/oxdPerl

    Search CPAN
        http://search.cpan.org/dist/oxdPerl/


LICENSE AND COPYRIGHT

Copyright (C) 2016 Gaurav Chhabra

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Configuration For Example Setup

# OXD Perl Demo site

This is a demo site for oxd-perl written using Perl (CGI) to demonstrate how to use oxd-perl to perform authorization with an OpenID Provider and fetch information.

## Deployment

### Prerequisites

Ubuntu 14.04 with some basic utilities listed below

```bash
$ sudo apt-get update
$ sudo apt-get install apache2
$ a2enmod ssl
```

### Installing and configuring the oxd-server
You can download the oxd-server and follow the installation instructions from [here](https://www.gluu.org/docs-oxd)

## Demosite deployment

OpenID Connect works only with HTTPS connections. So let us get the ssl certs ready.
```bash
$ mkdir /etc/certs
$ cd /etc/certs
$ openssl genrsa -des3 -out demosite.key 2048
$ openssl rsa -in demosite.key -out demosite.key.insecure
$ mv demosite.key.insecure demosite.key
$ openssl req -new -key demosite.key -out demosite.csr
$ openssl x509 -req -days 365 -in demosite.csr -signkey demosite.key -out demosite.crt
```

### Install Perl on ubuntu

```bash
$ sudo apt-get install perl
$ sudo apt-get install libapache2-mod-perl2 

```
Then create virtual host of oxd-perl ""odx-perl.conf" under /etc/apache2/sites-available/  file and add these lines :

```bash
$ cd /etc/apache2/sites-available
$ vim client.example.conf

```
add below mention lines on  virtual host file

```
<IfModule mod_ssl.c>
    <VirtualHost _default_:443>

        DocumentRoot /var/www/html/oxd-perl/example/
        ServerName www.client.example.com
        ServerAlias client.example.com

        <Directory /var/www/html/oxd-perl/example/>
                        AllowOverride All
        </Directory>

        ErrorLog /var/www/html/oxd-perl/example/logs/error.log
        CustomLog /var/www/html/oxd-perl/example/logs/access.log combined

        AddType application/x-httpd-php .php
           <Files 'xmlrpc.php'>
                   Order Allow,Deny
                   deny from all
           </Files>

        SSLEngine on
        SSLCertificateFile  /etc/certs/demosite.crt
        SSLCertificateKeyFile /etc/certs/demosite.key

                <FilesMatch "\.(cgi|shtml|phtml|php)$">
                        SSLOptions +StdEnvVars
                </FilesMatch>

                # processes .cgi and .pl as CGI scripts

                ScriptAlias /cgi-bin/ /var/www/html/oxd-perl/
                <Directory "/var/www/html/oxd-perl">
                        Options +ExecCGI
                        SSLOptions +StdEnvVars
                        AddHandler cgi-script .cgi .pl
                </Directory>

                BrowserMatch "MSIE [2-6]" \
            nokeepalive ssl-unclean-shutdown \
            downgrade-1.0 force-response-1.0
                BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

        </VirtualHost>
</IfModule>
```

Then enable `client.example.conf` virtual host by running:

```bash

$ sudo a2ensite client.example.conf 

```

After that add domain name in virtual host file.
In console:

```bash

$ sudo nano /etc/hosts

```

Add these lines in virtual host file:
```
127.0.0.1 www.client.example.com
127.0.0.1  client.example.com

```

Reload the apache server

```bash
$ sudo service apache2 restart

```
### Setting up and running demo app

Navigate to perl app root:

```bash

Copy example folder from oxdPerl directory and placed on root folder

cd /var/www/html/oxd-perl/example



```

## Deployment (Windows)

OpenID Connect works only with HTTPS connections.


- Install Perl ([Strawberry Perl](http://strawberryperl.com/))

- Add Perl executable path to the system environment variable.

- Install Apache.

- Add the following lines on virtual host file of Apache (Virtual host file is in the Path C:/apache/conf/extra/httpd-vhosts.conf):

```
<VirtualHost *>
    ServerName client.example.com
    ServerAlias client.example.com
    DocumentRoot "C:/xampp/htdocs"
</VirtualHost>

<VirtualHost *:443>
    DocumentRoot "C:/xampp/htdocs"
    ServerName client.example.com
    SSLEngine on
    SSLCertificateFile "conf/ssl.crt/server.crt"
    SSLCertificateKeyFile "conf/ssl.key/server.key"
    <Directory "C:/xampp/htdocs">
        AllowOverride All
        Order allow,deny
        Allow from all
    </Directory>
</VirtualHost>
```

- Then open Notepad as Administrator and open hosts file present in C:\Windows\System32\drivers\etc. Add domain name in hosts file:

```
127.0.0.1       client.example.com
::1             client.example.com
```


- Configure Apache to treat the code directory as your script directory, search for the following line in your `httpd.conf` file which is in the location `C:\Program Files\Apache Group\Apache\conf\httpd.conf`

```
ScriptAlias /cgi-bin/ "<path to your CGI files>"
```

- To run CGI scripts anywhere in your domain, add the following line to your `httpd.conf` file.

```
AddHandler cgi-script .cgi
```

- In the `Directory` section of `httpd.conf` file. Add your CGI path

```code
<Directory "<path to your CGI files>">
    AllowOverride All
    Options None
    Require all granted
</Directory>
```

- The initial line of perl script contains `#!/usr/bin/perl` , change it with the path of perl.exe `#!C:/program files/perl/bin/perl.exe` 

- Copy the perl modules of your lib folder to lib folder of perl.


- Restart the apache server.

## Configuration 

The oxd-perl configuration file is located in 'oxd-settings.json'. The values here are used during registration. For a full list of supported oxd configuration parameters, see the oxd documentation Below is a typical configuration data set for registration:
``` {.code }
{
  "op_host": "https://ce-dev3.gluu.org",
  "oxd_host_port":8099,
  "authorization_redirect_uri" : "https://client.example.com/index.cgi",
  "post_logout_redirect_uri" : "https://client.example.com/index.cgi",
  "client_frontchannel_logout_uris" : "https://client.example.com/logout.cgi",
  "scope" : [ "openid", "profile", "email", "uma_authorization", "uma_protection" ],
  "application_type" : "web",
  "response_types" : ["code"],
  "grant_types":["authorization_code", "client_credentials", "uma_ticket"],
  "acr_values" : [ "basic" ],
  "oxd_id": "<oxd_id>",
  "client_id": "<client_id>",
  "client_secret": "<client_secret>",
  "client_name": "<client_name>",
  "connection_type": "web",
  "rest_service_url": "https://127.0.0.1:8443",
  "dynamic_registration": "true"
}
```        
-    oxd_host_port - oxd port or socket

### Sample code

### index.cgi

    Configuration Values from oxd-settings.json

**Example**
``` {.code}
OxdConfig:
	$object = new OxdConfig();
    my $opHost = $object->getOpHost();
    my $oxdHostPort = $object->getOxdHostPort();
    my $authorizationRedirectUrl = $object->getAuthorizationRedirectUrl();
    my $postLogoutRedirectUrl = $object->getPostLogoutRedirectUrl();
    my $clientFrontChannelLogoutUrl = $object->getClientFrontChannelLogoutUris();
    my $scope = $object->getScope();
    my $applicationType = $object->getApplicationType();
    my $responseType = $object->getResponseType();
    my $grantType = $object->getGrantTypes();
    my $acrValues = $object->getAcrValues();
    my $restServiceUrl = $object->getRestServiceUrl();
    my $connectionType = $object->getConnectionType();
    my $oxd_id = $object->getOxdId();
    my $client_name = $object->getClientName();
    my $client_id = $object->getClientId();
    my $client_secret = $object->getClientSecret();
```

### OxdSetupClient.pm

- [Setup client protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#setup-client).

**Example**

``` {.code}
OxdSetupClient:

my $setup_client = new OxdSetupClient( );	
$setup_client->setRequestOpHost($opHost);
$setup_client->setRequestAcrValues($acrValues);
$setup_client->setRequestAuthorizationRedirectUri($authorizationRedirectUrl);
$setup_client->setRequestPostLogoutRedirectUri($postLogoutRedirectUrl);
$setup_client->setRequestClientLogoutUris([$clientFrontChannelLogoutUrl]);
$setup_client->setRequestGrantTypes($grantType);
$setup_client->setRequestResponseTypes($responseType);
$setup_client->setRequestScope($scope);
$setup_client->setRequestApplicationType($applicationType);
$setup_client->setRequestClientName($client_name);
$setup_client->request();

my $oxd_id = $setup_client->getResponseOxdId();
my $client_id = $setup_client->getResponseClientId();
my $client_secret = $setup_client->getResponseClientSecret();
print Dumper($setup_client->getResponseObject());
```

### GetClientToken.pm

- [Get client token protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#get-client-token).

**Example**

``` {.code}
GetClientToken:

my $get_client_token = new GetClientToken( );
$get_client_token->setRequestClientId($client_id);
$get_client_token->setRequestClientSecret($client_secret);
$get_client_token->setRequestOpHost($opHost);
$get_client_token->request();

my $protection_access_token = $get_client_token->getResponseAccessToken();
print Dumper($get_client_token->getResponseObject());
```

### OxdRegister.pm

- [Register_site protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#register-site).

**Example**

``` {.code}
OxdRegister:

my $register_site = new OxdRegister( );
$register_site->setRequestOpHost($opHost);
$register_site->setRequestAcrValues($acrValues);
$register_site->setRequestAuthorizationRedirectUri($authorizationRedirectUrl);
$register_site->setRequestPostLogoutRedirectUri($postLogoutRedirectUrl);
$register_site->setRequestScope($scope);
$register_site->setRequestProtectionAccessToken($protection_access_token);
$register_site->request();

my $oxd_id = $register_site->getResponseOxdId();
print Dumper($register_site->getResponseObject());
```

### UpdateRegistration.pm

- [Update_site_registration protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#update-site-registration).

**Example**

``` {.code}
UpdateRegistration:

my $update_site_registration = new UpdateRegistration();
$update_site_registration->setRequestOxdId($oxd_id);
$update_site_registration->setRequestAuthorizationRedirectUri($authorizationRedirectUrl);
$update_site_registration->setRequestPostLogoutRedirectUri($postLogoutRedirectUrl);
$update_site_registration->setRequestContacts([$email]);
$update_site_registration->setRequestGrantTypes($grantType);
$update_site_registration->setRequestProtectionAccessToken($protection_access_token);
$update_site_registration->request();

my $oxd_id = $update_site_registration->getResponseOxdId();
print Dumper($update_site_registration->getResponseObject());
```

### GetAuthorizationUrl.pm

- [Get_authorization_url protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#get-authorization-url).

**Example**

``` {.code}
GetAuthorizationUrl:

my $get_authorization_url = new GetAuthorizationUrl( );
$get_authorization_url->setRequestOxdId($oxd_id);
$get_authorization_url->setRequestScope($scope);
$get_authorization_url->setRequestAcrValues($acrValues);
$get_authorization_url->setRequestCustomParam($customParam);
$get_authorization_url->setRequestProtectionAccessToken($protection_access_token);
$get_authorization_url->request();

my $oxdurl = $get_authorization_url->getResponseAuthorizationUrl();
print Dumper($get_authorization_url->getResponseObject());
```

###  GetTokenByCode.pm

- [Get_tokens_by_code protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#get-tokens-id-access-by-code).

**Example**

``` {.code}
GetTokenByCode:

my $code = $cgi->escapeHTML($cgi->param("code"));
my $state = $cgi->escapeHTML($cgi->param("state"));
my $session_state = $cgi->escapeHTML($cgi->param("session_state"));

my $get_tokens_by_code = new GetTokenByCode();
$get_tokens_by_code->setRequestOxdId($oxd_id);
$get_tokens_by_code->setRequestCode($code);
$get_tokens_by_code->setRequestState($state);
$get_tokens_by_code->setRequestProtectionAccessToken($protection_access_token);
$get_tokens_by_code->request();

my $user_oxd_id_token = $get_tokens_by_code->getResponseIdToken();
my $accessToken = $get_tokens_by_code->getResponseAccessToken();
my $refreshToken = $get_tokens_by_code->getResponseRefreshToken();
print Dumper($get_tokens_by_code->getResponseObject());
```


### GetAccessTokenByRefreshToken.pm

- [Get_access token_by_refresh token protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#get-access-token-by-refresh-token).

**Example**

``` {.code}
GetAccessTokenByRefreshToken:

$get_access_token_by_refresh_token = new GetAccessTokenByRefreshToken();
$get_access_token_by_refresh_token->setRequestOxdId($oxd_id);
$get_access_token_by_refresh_token->setRequestRefreshToken($refresh_token);
$get_access_token_by_refresh_token->setRequestProtectionAccessToken($protection_access_token);
$get_access_token_by_refresh_token->request();

$new_access_token = $get_access_token_by_refresh_token->getResponseAccessToken();
$new_refresh_token = $get_access_token_by_refresh_token->getResponseRefreshToken();
print Dumper($get_access_token_by_refresh_token->getResponseObject());
```


### GetUserInfo.pm

- [Get_user_info protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#get-user-info).

**Example**

``` {.code}
GetUserInfo:

my $get_user_info = new GetUserInfo();
$get_user_info->setRequestOxdId($oxd_id);
$get_user_info->setRequestAccessToken($accessToken);
$get_user_info->setRequestProtectionAccessToken($protection_access_token);
$get_user_info->request();

my $username = $get_user_info->getResponseObject()->{data}->{claims}->{name}[0];
my $useremail = $get_user_info->getResponseObject()->{data}->{claims}->{email}[0];
print Dumper($get_user_info->getResponseObject());   
```


### OxdLogout.pm

- [Get_logout_uri protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#log-out-uri).

**Example**

``` {.code}
OxdLogout:

my $logout = new OxdLogout();
$logout->setRequestOxdId($oxd_id);
$logout->setRequestPostLogoutRedirectUri($postLogoutRedirectUrl);
$logout->setRequestIdToken($user_oxd_id_token);
$logout->setRequestSessionState($session_state);
$logout->setRequestState($state);
$logout->setRequestProtectionAccessToken($protection_access_token);
$logout->request();

$session->delete();
$logoutUrl = $logout->getResponseObject()->{data}->{uri};
print Dumper($logout->getResponseObject());
```

### For UMA authentications open this url in browser

- [https://client.example.com/uma.cgi](https://client.example.com/uma.cgi).

### UmaRsProtect.pm

- [Uma_rs_protect protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#uma-rs-protect-resources).

**Example**

``` {.code}
UmaRsProtect:

$uma_rs_protect = new UmaRsProtect();
$uma_rs_protect->setRequestOxdId($oxd_id);

$uma_rs_protect->addConditionForPath(["GET"],["https://photoz.example.com/dev/actions/view"], ["https://photoz.example.com/dev/actions/view"]);
$uma_rs_protect->addConditionForPath(["POST"],[ "https://photoz.example.com/dev/actions/add"],[ "https://photoz.example.com/dev/actions/add"]);
$uma_rs_protect->addConditionForPath(["DELETE"],["https://photoz.example.com/dev/actions/remove"], ["https://photoz.example.com/dev/actions/remove"]);
$uma_rs_protect->addResource('/photo');
$uma_rs_protect->setRequestProtectionAccessToken($protection_access_token);
$uma_rs_protect->request();

print Dumper( $uma_rs_protect->getResponseObject() );
```

### UmaRsCheckAccess.pm

- [Uma_rs_check_access protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#uma-rs-check-access).

**Example**

``` {.code}
UmaRsCheckAccess:

$uma_rs_check_access = new UmaRsCheckAccess();
$uma_rs_check_access->setRequestOxdId($oxd_id);
$uma_rs_check_access->setRequestRpt($uma_rpt);
$uma_rs_check_access->setRequestPath("/photo");
$uma_rs_check_access->setRequestHttpMethod("GET");
$uma_rs_check_access->setRequestProtectionAccessToken($protection_access_token);
$uma_rs_check_access->request();

my $uma_ticket= $uma_rs_check_access->getResponseTicket();
print Dumper($uma_rs_check_access->getResponseObject());

```

### UmaRpGetRpt.pm

- [Uma_rp_get_rpt protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#uma-rp-get-rpt).

**Example**

``` {.code}
UmaRpGetRpt:

$uma_rp_get_rpt = new UmaRpGetRpt();
$uma_rp_get_rpt->setRequestOxdId($oxd_id);
$uma_rp_get_rpt->setRequestTicket($uma_ticket);
$uma_rp_get_rpt->setRequestProtectionAccessToken($protection_access_token);
$uma_rp_get_rpt->request();

my $uma_rpt= $uma_rp_get_rpt->getResponseRpt();
print Dumper($uma_rp_get_rpt->getResponseObject());

```

### UmaRpGetClaimsGatheringUrl.pm

- [Uma_rp_get_claims_gathering_url protocol description](https://gluu.org/docs/oxd/3.1.0/protocol/#uma-rp-get-claims-gathering-url).

**Example**

``` {.code}
UmaRpGetClaimsGatheringUrl:

$uma_rp_get_claims_gathering_url = new UmaRpGetClaimsGatheringUrl();
$uma_rp_get_claims_gathering_url->setRequestOxdId($oxd_id);
$uma_rp_get_claims_gathering_url->setRequestTicket($uma_ticket);
$uma_rp_get_claims_gathering_url->setRequestClaimsRedirectUri($claims_redirect_Uri);
$uma_rp_get_claims_gathering_url->setRequestProtectionAccessToken($protection_access_token);
$uma_rp_get_claims_gathering_url->request();

print Dumper($uma_rp_get_claims_gathering_url->getResponseObject());
```


Now your perl app should work from https://client.example.com/

##Enjoy!
