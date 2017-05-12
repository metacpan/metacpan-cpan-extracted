This is the README file for Zabbix-API-Simple,
a simple abstraction of the Zabbix::API.

## Description

Zabbix-API-Simple provides
a simple abstraction of the Zabbix::API.

This module is kind of a workaround for the
official Zabbix API. The Zabbix JSON-RPC API
is quite powerful and has a nice CPAN Client
but is very hard to implement against. Much
to difficult to be useful in simple automation
scripts.

This module provides a gateway between the
powerful but complex JSON-RPC API and
lightweight scripts by providing a simple
and limited HTTP API. It's very eays to script
against and perform bulk operations.

As an added benefit is can act as a gatekeeper
which further controls the access to the Zabbix
API.

It is made to be very simple to extend.

Please have a close look at the Plugins in the
namespace Zabbix::API::Simple::Web::Plugin and
the coresponding documentation in conf/zsapi.conf.dist.
Please not how the Plugin names are mapped to the
appropriate configuration keys.

## Limitations

This module does not intend to support the full
range of features the official JSON-RPC API provides.

At the moment only a subset of operations on hosts is
supported. It may be extended to support other common
bulk operations as well but it wont ever try to
support every aspect of the official API.

## Installation

This package uses Dist::Zilla.

Use

dzil build

to create a release tarball which can be
unpacked and installed like any other EUMM
distribution.

perl Makefile.PL

make

make test

make install

## Documentation

Please see perldoc Zabbix::API::Simple.

