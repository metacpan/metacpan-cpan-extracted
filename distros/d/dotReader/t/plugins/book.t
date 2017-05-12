#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

eval { use dtRdr::Book };

ok((not $@), 'require ok');

# run the import
{
package SomeBook;
use base 'dtRdr::Book';
# only part that flexes the plugin system:
use dtRdr::Book (register => {type => 'somebook'});

# define methods

# we'll take anything
sub identify_uri {1}
sub load_uri {1}

}

my $bp = 'SomeBook';
{ # check inheritance
# interesting:  isa_ok doesn't work on classes!
ok($bp->isa('dtRdr::Book'), 'class isa');

}

{ # type registration
  my $class = dtRdr::Plugins::Book->class_for_type('somebook');
  is($class, 'SomeBook');
  $class = dtRdr::Plugins::Book->class_for_type('somewonkynameforatypeofbook');
  is($class, undef);
}

{ # try to instantiate
my $book = dtRdr::Book->new_from_uri('somebook://foo.bar');
ok($book, 'got book');
isa_ok($book, 'dtRdr::Book');
isa_ok($book, 'SomeBook');
}

=note TODO

  identify_by_uri
  identify_by_type

=cut

# vi:syntax=perl:ts=2:sw=2:et:sta
