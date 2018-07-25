# perl-sdk / WebService::Hexonet::Connector

This module is a connector library for the insanely fast HEXONET Backend API. For further informations visit our [homepage](http://hexonet.net) and do not hesitate to [contact us](https://www.hexonet.net/contact).

## Resources

* [Usage Guide](https://github.com/hexonet/perl-sdk/blob/master/README.md#how-to-use-this-module-in-your-project)
* [SDK Documenation](https://rawgit.com/hexonet/perl-sdk/master/docs/hexonet.html)
* [HEXONET Backend API Documentation](https://github.com/hexonet/hexonet-api-documentation/tree/master/API)
* [Release Notes](https://github.com/hexonet/perl-sdk/releases)
* [Development Guide](https://github.com/hexonet/perl-sdk/wiki/Development-Guide)

## How to use this module in your project

We have also a demo app available showing how to integrate and use our SDK. See [here](https://github.com/hexonet/perl-sdk-demo).

### Requirements

* Installed most current version of perl 5
* Installed cpanm (App::cpanminus) as suggested alternative for cpan command

### Install from CPAN

```bash
# by Module ID (suggested!)
cpanm WebService::Hexonet::Connector

# or by filename
cpanm HEXONET/WebSservice-Hexonet-Connector-1.03.tar.gz
```

NOTE: I got this only working by sudo'ing these commands.
In case you install by filename, please check the [release overview](https://github.com/hexonet/perl-sdk/releases) for the most current release and use that version instead.

### Usage Examples

Please have an eye on our [HEXONET Backend API documentation](https://github.com/hexonet/hexonet-api-documentation/tree/master/API). Here you can find information on available Commands and their response data.

#### Session based API Communication

Not yet available, this needs a review of the SDK.

#### Sessionless API Communication

```perl
use strict;
use warnings;
use WebService::Hexonet::Connector;

my $api = WebService::Hexonet::Connector::connect(
	{
		url => "https://coreapi.1api.net/api/call.cgi",
		entity => "1234",
		login => "test.user",
		password => "test.passw0rd"
	}
);

# Call a command
my $response = $api->call(
	{
		command => "QueryDomainList",
		limit => 5
	}
);

# get the result in the format you want
my $res = $response->as_list();
$res = $response->as_list_hash();
$res = $response->as_hash();

# get the response code and the response description
my $code = $response->code();
my $description = $response->description();

print "$code $description";
```

## Contributing

Please read [our development guide](https://github.com/hexonet/perl-sdk/wiki/Development-Guide) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Anthony Schneider** - *development* - [ISharky](https://github.com/isharky)
* **Kai Schwarz** - *development* - [PapaKai](https://github.com/papakai)

See also the list of [contributors](https://github.com/hexonet/perl-sdk/graphs/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
