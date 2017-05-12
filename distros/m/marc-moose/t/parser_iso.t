#!perl

use strict;
use warnings;

use Test::More tests=>3;

use MARC::Moose::Parser::Iso2709;

# The problem is only visible if the data consists of characters, not bytes/octets
# Since it is recommended practice to decode any input it is always possible to
# see data in this form. In my case it was by reading over HTTP with LWP. Since 
# there was a UTF-8 header it was automatically read as characters. The same
# could happen when reading a record from a database with UTF-8 encoding. It can
# always happen that the UTF-8 flag is (correctly) set, so I think it is a good
# idea to be able to cope with it.
#
# Another unrelated problem I found is that MARC::Moose::Record was not 'used'
# in MARC::Moose::Parser::Iso2709, giving an error if not used elsewhere.

open(my $fh, "<:encoding(UTF-8)", "t/parser_iso.mrc"); # make sure we get characters

my $parser  = MARC::Moose::Parser::Iso2709->new();
my $rec_txt = <$fh>;
my $record  = $parser->parse($rec_txt);

is($record->field('260')->subfield('a'), 'Dortmund', 'damaged field');
ok($record->field('935'), 'missing field');
is($record->field('935')->subfield('b'), 'druck', 'missing field - value');

# To see the effect:
# use MARC::Moose::Formater::Text;
# my $formater = MARC::Moose::Formater::Text->new();
# print MARC::Moose::Formater::Text->new()->format($record);

