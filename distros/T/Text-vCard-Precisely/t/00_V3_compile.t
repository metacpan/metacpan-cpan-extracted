use strict;
use warnings;
use Test::More tests => 3;

use_ok('Text::vCard::Precisely::V3');    # 1

my $vc = new_ok( 'Text::vCard::Precisely::V3', [] );     # 2
$vc = new_ok( 'Text::vCard::Precisely::V3', [ {} ] );    # 3

done_testing();
