#!/usr/bin/perl -w
###########################################################################
### 01___ldap_filter.t
###
### Basic tests of Trinket::Dictionary::FilterParser
###
### $Id: 50___ldap_filter.t,v 1.1.1.1 2001/02/15 18:47:50 deus_x Exp $
###
### TODO:
###
###########################################################################

no warnings qw( uninitialized );
use strict;
use Test;

BEGIN
  {
    plan tests => 1;

    unless(grep /blib/, @INC)
      {
        chdir 't' if -d 't';
        unshift @INC, '../lib' if -d '../lib';
        unshift @INC, './lib' if -d './lib';
      }
  }

use Trinket::Object;
use Trinket::Directory::FilterParser::LDAP;
use Data::Dumper;
use Carp qw( croak cluck );

my ($obj, $parser);

### Creation
ok $parser = new Trinket::Directory::FilterParser::LDAP();

#my $parsed = $parser->parse_filter('(&(parent=1)(objectclass=Iaido::Object::Folder))');

# $parsed = $parser->parse_filter
#    (qq^
#        (&
#          (path~=/hivemind/*)
#          (objectclass=Iaido::Object::Hivemind::Task)
#          (| (parent=2378)(parent=2124)(parent=2308)(parent=3217) )
#          (| (author=1949)(author=4158) )
#          (& (created>=883976400)(created<=947307600) )
#          (closed=0)
#         )
#      ^);

exit(0);

