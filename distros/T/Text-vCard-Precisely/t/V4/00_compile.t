use strict;
use warnings;

use Test::More tests => 3;
use lib qw(./lib);

BEGIN { use_ok ('Text::vCard::Precisely::V4') };        # 1

my $vc = new_ok('Text::vCard::Precisely::V4');          # 2
$vc = new_ok( 'Text::vCard::Precisely::V4', [{}] );     # 3

done_testing();
