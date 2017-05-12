#!/usr/bin/env perl
# Check processing of KeyInfo structures.
use warnings;
use strict;

use lib '../XMLWSS/lib', 'lib';

use Log::Report;
use Test::More  tests => 2;

use File::Slurp                   qw/write_file/;
use XML::Compile::Cache           ();
use XML::Compile::WSS             ();
use XML::Compile::WSS::Signature  ();

my $schema    = XML::Compile::Cache->new;
ok(defined $schema);

my $wss       = XML::Compile::WSS::Signature->new
  ( version => '1.1'
  , schema  => $schema
  , prepare => 'NONE'
  , token   => 'dummy'
  );

### save template

write_file 'dump/keyinfo/KeyInfo.templ'
  , $wss->schema->template(PERL => 'ds:KeyInfo');

write_file 'dump/keyinfo/KeyIdentifier.templ'
  , $wss->schema->template(PERL => 'wsse:KeyIdentifier');

write_file 'dump/keyinfo/SecurityTokenReference.templ'
  , $wss->schema->template(PERL => 'wsse:SecurityTokenReference');

write_file 'dump/keyinfo/Reference.templ'
  , $wss->schema->template(PERL => 'wsse:Reference');

write_file 'dump/keyinfo/BinarySecurityToken.templ'
  , $wss->schema->template(PERL => 'wsse:BinarySecurityToken');

write_file 'dump/security.templ'
  , $wss->schema->template(PERL => 'wsse:Security');

write_file 'dump/signature.templ'
  , $wss->schema->template(PERL => 'ds:Signature');

ok(1, 'templates in ./dump');
