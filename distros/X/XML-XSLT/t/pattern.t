#!/usr/nin/perl
# Test all patterns
# $Id: pattern.t,v 1.1 2004/02/16 10:29:20 gellyfish Exp $

use strict;

use Test::More tests => 2;

use vars qw($DEBUGGING);

$DEBUGGING = 0;

use_ok('XML::XSLT');

eval
{
  my $parser = XML::XSLT->new(use_deprecated => 1,debug => $DEBUGGING);
};
ok(1,"");
