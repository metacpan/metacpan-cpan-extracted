#!/usr/bin/perl 
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

BEGIN { use_ok( 'WWW::Gazetteer' ); }

throws_ok { WWW::Gazetteer->new("not_a_plugin") } qr/No WWW::Gazetteer plugin/,
  "Can not load unknown plugin";

# there isn't much we can test until we have installed
# any subclasses :-(

