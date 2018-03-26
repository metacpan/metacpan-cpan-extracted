# Zcash::RPC::Client -  Zcash Payment API client as a Perl module

[![Build Status](https://travis-ci.org/Cyclenerd/Zcash-RPC-Client.svg?branch=master)](https://travis-ci.org/Cyclenerd/Zcash-RPC-Client)

This module is a pure Perl implementation of the methods that are currently part of the Zcash Payment API client calls (`zcash-cli`).
The method names and parameters are identical between the Zcash Payment API reference and this module.
This is done for consistency so that a developer only has to reference one manual:
https://github.com/zcash/zcash/blob/master/doc/payment-api.md

Currently tested against Zcash v1.0.14 but should work with earlier versions.

## SYNOPSIS

```
#!/usr/bin/perl
use Zcash::RPC::Client;

# Create Zcash::RPC::Client object
$zec = Zcash::RPC::Client->new(
	user     => "username",
	password => "p4ssword",
);

# Zcash supports all commands in the Bitcoin Core API
$getinfo = $zec->getinfo;
$blocks = $getinfo->{blocks};

# Return the total value of funds stored in the node’s wallet
$z_gettotalbalance = $zec->z_gettotalbalance;
# Output:
# {
#   "transparent" : 1.23,
#   "private" : 4.56,
#   "total" : 5.79
# }
print $z_gettotalbalance->{total};
# 5.79

# See ex/example.pl for more in depth JSON handling:
#     https://github.com/Cyclenerd/Zcash-RPC-Client/tree/master/ex
```

## CONSTRUCTOR

```
$zec = Zcash::RPC::Client->new( %options );
```

This method creates a new `Zcash::RPC::Client` and returns it.

| Key             | Default          |
|-----------------|------------------|
| host            | 127.0.0.1        |
| user            | undef (Required) |
| password        | undef (Required) |
| cookie          | undef            |
| port            | 8232             |
| wallet          | undef            |
| timeout         | 20               |
| ssl             | 0                |
| verify_hostname | 1                |
| debug           | 0                |

**host** - Address listens for JSON-RPC connections

**user** and **password** - User and Password for JSON-RPC api commands

**cookie** - Absolute path to your RPC cookie file (.cookie). When cookie is defined user and password will be ignored and the contents of cookie will be used instead.

**port** - TCP port for JSON-RPC connections

**wallet** - Work against specific wallet.dat file when Multi-wallet support is
enabled

**timeout** - Set the timeout in seconds for individual RPC requests. Increase this for slow zcashd instances.

**ssl** - OpenSSL support has been removed from the Bitcoin Core and Zcash project. 
However `Zcash::RPC::Client` will work over SSL with earlier versions or with a reverse web proxy such as nginx.

**verify_hostname** - Disable SSL certificate verification. Needed when bitcoind is fronted by a proxy or when using a self-signed certificate.

**debug** - Turns on raw HTTP request/response output from LWP::UserAgent.

## INSTALL

### Source

```
perl Makefile.PL
make
make test
make install
```

### cpanm

```
cpanm Zcash::RPC::Client
```

### CPAN shell

```
perl -MCPAN -e shell
install Zcash::RPC::Client
```

## DEPENDENCIES

* `Moo`
* `JSON::RPC::Legacy::Client`

## CAVEATS

* Boolean parameters must be passed as `JSON::Boolean` objects E.g. `JSON::true`

## AUTHORS

Zcash is based on Bitcoin. Zcash supports all commands in the Bitcoin Core API (as of version 0.11.2). This module is a fork of the [Bitcoin JSON-RPC client](https://github.com/whindsx/Bitcoin-RPC-Client).

`Bitcoin::RPC::Client` is developed by Wesley Hinds. This Zcash fork is mantained by Nils Knieling.