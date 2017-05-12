#!/usr/bin/perl -w

# Copyright 2010, 2013 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Email::Address;

{
  my $str = 'foo@example.com';
   $str = '  ';
  if ($str =~ $Email::Address::mailbox) {
    print "match\n";
  } else {
    print "no match\n";
  }
  exit 0;
}

{
  my ($e) = Email::Address->parse('"foo \\(Foo\\)" <y>')
    or die;
  print "name: ",$e->name//'undef',"\n";
  print "phrase: ",$e->phrase//'undef',"\n";
  print "comment: ",$e->comment,"\n";
  print "address: ",$e->address,"\n";
  print $e;
  exit 0;
}
{
print Email::Address->new('foo (bar)', undef, 'comm');
exit 0;
}
#print Email::Address->new('foo (bar)', undef);

#print Email::Address->new('foo bar');
#print Email::Address->new('foo@bar');
print Email::Address->parse('foo@bar');
