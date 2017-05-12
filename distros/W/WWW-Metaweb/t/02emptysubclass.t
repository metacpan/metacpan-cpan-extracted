#!/usr/bin/perl

package Local::WWW::Metaweb;

# One of the strictures in perlmodlib is that an empty package that includes a
# module as a subclass should be able to act as that module - here we test that,
# in a very simple fashion.

use WWW::Metaweb;

our @ISA = qw(WWW::Metaweb);

package main;

use strict;
use Test::More tests => 1;

my $mh = Local::WWW::Metaweb->connect( server => 'www.freebase.com',
				       read_uri => '/api/service/mqlread',
                              );
ok(defined $mh, 'Empty package can subclass WWW::Metaweb');

exit;
