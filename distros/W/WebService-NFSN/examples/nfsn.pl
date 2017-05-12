#! /usr/bin/perl
#---------------------------------------------------------------------
# nfsn.pl
# Copyright 2010 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Simple client script for using the NFSN API
#---------------------------------------------------------------------

use strict;
use warnings;
# RECOMMEND PREREQ: Data::Dumper
use Data::Dumper;
use Try::Tiny;
use WebService::NFSN;

my ($type, $id, $command, @parameters) = @ARGV;

die <<"" unless defined $command;
Usage: $0 TYPE ID COMMAND [PARAMETERS...]\n
Reads credentials from .nfsn-api\n
Examples:
  $0 account A1B2-C3D4E5F6 balance
  $0 account A1B2-C3D4E5F6 friendlyName NewName
  $0 dns example.com listRRs name www
  $0 dns example.com addRR name bob type A data 10.0.0.5
  $0 email example.com forward name dest_email 'to\@example.net'
  $0 member USER accounts
  $0 site SHORT_NAME addAlias alias www.example.com

my $nfsn = WebService::NFSN->new; # Load credentials from ~/.nfsn-api

die "Unknown type $type\n" unless $nfsn->can($type);
my $obj = $nfsn->$type($id);

die "Unknown command $command\n" unless $obj->can($command);
my $result = try {
  $obj->$command(@parameters);
} catch {
  my $res = $nfsn->last_response;
  print STDERR $res->as_string . "\n" if $res;
  die $_;
};

$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse    = 1;
print Dumper($result);
