# perl-sdk / WebService::Hexonet::Connector

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![build](https://travis-ci.com/hexonet/perl-sdk.svg?branch=master)](https://travis-ci.com/hexonet/perl-sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/hexonet/perl-sdk/blob/master/CONTRIBUTING.md)

This module is a connector library for the insanely fast HEXONET Backend API. For further informations visit our [homepage](http://hexonet.net) and do not hesitate to [contact us](https://www.hexonet.net/contact).

## Resources

* [Usage Guide](https://github.com/hexonet/perl-sdk/blob/master/README.md#how-to-use-this-module-in-your-project)
* [SDK Documenation](https://rawgit.com/hexonet/perl-sdk/master/docs/hexonet.html)
* [HEXONET Backend API Documentation](https://github.com/hexonet/hexonet-api-documentation/tree/master/API)
* [Release Notes](https://github.com/hexonet/perl-sdk/releases)
* [Development Guide](https://github.com/hexonet/perl-sdk/wiki/Development-Guide)

## Features

* Automatic IDN Domain name conversion to punycode (our API accepts only punycode format in commands)
* Allows nested associative arrays in API commands to improve for bulk parameters
* Connecting and communication with our API
* Several ways to access and deal with response data
* Getting the command again returned together with the response
* Sessionless communication
* Session based communication
* Possibility to save API session identifier in session
* Configure a Proxy for API communication
* Configure a Referer for API communication
* High Performance Proxy Setupn

## How to use this module in your project

We have also a demo app available showing how to integrate and use our SDK. See [here](https://github.com/hexonet/perl-sdk-demo).

### Requirements

* Installed most current version of perl 5
* Installed cpanm (App::cpanminus) as suggested alternative for cpan command

### Install from CPAN

```bash
# by Module ID (suggested!)
cpanm WebService::Hexonet::Connector~2.0000

# or by filename
cpanm HEXONET/WebSservice-Hexonet-Connector-v2.0.0.tar.gz
```

NOTE: I got this only working by sudo'ing these commands.
In case you install by filename, please check the [release overview](https://github.com/hexonet/perl-sdk/releases) for the most current release and use that version instead.

### High Performance Proxy Setup

Long distances to our main data center in Germany may result in high network latencies. If you encounter such problems, we highly recommend to use this setup, as it uses persistent connections to our API server and the overhead for connection establishments is omitted.

#### Step 1: Required Apache2 packages / modules

*At least Apache version 2.2.9* is required.

The following Apache2 modules must be installed and activated:

```bash
proxy.conf
proxy.load
proxy_http.load
ssl.conf # for HTTPs connection to our API server
ssl.load # for HTTPs connection to our API server
```

#### Step 2: Apache configuration

An example Apache configuration with binding to localhost:

```bash
<VirtualHost 127.0.0.1:80>
    ServerAdmin webmaster@localhost
    ServerSignature Off
    SSLProxyEngine on
    ProxyPass /api/call.cgi https://api.ispapi.net/api/call.cgi min=1 max=2
    <Proxy *>
        Order Deny,Allow
        Deny from none
        Allow from all
    </Proxy>
</VirtualHost>
```

After saving your configuration changes please restart the Apache webserver.

#### Step 3: Using this setup

```perl
use 5.026_000;
use strict;
use warnings;
use WebService::Hexonet::Connector;

my $cl = WebService::Hexonet::Connector::APIClient->new();
$cl->useOTESystem();# LIVE System would be used otherwise by default
$cl->useHighPerformanceConnectionSetup();# Default Connection Setup would be used otherwise by default
$cl->setCredentials('test.user', 'test.passw0rd');
my $response = $cl->request({ COMMAND => "StatusAccount" });
```

So, what happens in code behind the scenes? We communicate with localhost (so our proxy setup) that passes the requests to the HEXONET API.
Of course we can't activate this setup by default as it is based on Steps 1 and 2. Otherwise connecting to our API wouldn't work.

Just in case the above port or ip address can't be used, use function setURL instead to set a different URL / Port.
`http://127.0.0.1/api/call.cgi` is the default URL for the High Performance Proxy Setup.
e.g. `$cl->setURL('http://127.0.0.1:8765/api/call.cgi');` would change the port. Configure that port also in the Apache Configuration (-> Step 2)!

Don't use `https` for that setup as it leads to slowing things down as of the https `overhead` of securing the connection. In this setup we just connect to localhost, so no direct outgoing network traffic using `http`. The apache configuration finally takes care passing it to `https` for the final communication to the HEXONET API.

### Usage Examples

Please have an eye on our [HEXONET Backend API documentation](https://github.com/hexonet/hexonet-api-documentation/tree/master/API). Here you can find information on available Commands and their response data.

#### Session based API Communication

```perl
use 5.026_000;
use strict;
use warnings;
use WebService::Hexonet::Connector;

my $cl = WebService::Hexonet::Connector::APIClient->new();
$cl->useOTESystem();
$cl->setCredentials('test.user', 'test.passw0rd');
$cl->setRemoteIPAddress('1.2.3.4');

my $response = $cl->login();
# in case of 2FA use:
# my $response = $cl->login("12345678");

if ($response->isSuccess()) {
    # now the session will be used for communication in background
    # instead of the provided credentials
    # if you need something to rebuild connection on next page visit,
    # so in a frontend-session based environment, please consider
    # saveSession and reuseSession methods

    # Call a command
    my $response = $cl->request(
        {
            COMMAND => 'QueryDomainList',
            LIMIT => 5
        }
    );

    # get the result in the format you want
    my $res;
    $res = $response->getListHash();
    $res = $response->getHash();
    $res = $response->getPlain();

    # get the response code and the response description
    my $code = $response->getCode();
    my $description = $response->getDescription();

    print "$code $description";

    # close Backend API Session
    # you may verify the result of the logout procedure
    # like for the login procedure above
    $cl->logout();
}
```

#### Sessionless API Communication

```perl
use 5.026_000;
use strict;
use warnings;
use WebService::Hexonet::Connector;

my $cl = WebService::Hexonet::Connector::APIClient->new();
$cl->useOTESystem();
$cl->setCredentials('test.user', 'test.passw0rd');
$cl->setRemoteIPAddress('1.2.3.4');
# in case of 2FA use:
# $cl->setOTP("12345678")

# Call a command
my $response = $cl->request(
    {
        COMMAND => 'QueryDomainList',
        LIMIT => 5
    }
);

# get the result in the format you want
my $res;
$res = $response->getListHash();
$res = $response->getHash();
$res = $response->getPlain();

# get the response code and the response description
my $code = $response->getCode();
my $description = $response->getDescription();

print "$code $description";
```

#### Using bulk parameters [SINCE 2.3.0]

Using the below is supported to improve using commands. It will automatically be converted to parameters `DOMAIN0` and `DOMAIN1` accordingly.
This of course works for all commands and all such parameters.

```perl
use 5.026_000;
use strict;
use warnings;
use WebService::Hexonet::Connector;

my $cl = WebService::Hexonet::Connector::APIClient->new();
$cl->useOTESystem();
$cl->setCredentials('test.user', 'test.passw0rd');
$cl->setRemoteIPAddress('1.2.3.4');
# in case of 2FA use:
# $cl->setOTP("12345678")

# Call a command
my $response = $cl->request(
    {
        COMMAND => 'QueryDomainOptions',
        DOMAIN => ['example1.com', 'example2.com']
    }
);

# get the response code and the response description
my $code = $response->getCode();
my $description = $response->getDescription();

print "$code $description";
```

## Contributing

Please read [our development guide](https://github.com/hexonet/perl-sdk/wiki/Development-Guide) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Anthony Schneider** - *development* - [AnthonySchn](https://github.com/anthonyschn)
* **Kai Schwarz** - *development* - [PapaKai](https://github.com/papakai)

See also the list of [contributors](https://github.com/hexonet/perl-sdk/graphs/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
