use strict;
use warnings;

use Test::More tests => 6;

use lib qw(./lib);

BEGIN { use_ok ('Text::vCard::Precisely') };                            #1

my $vc = Text::vCard::Precisely->new();
is '3.0', $vc->version, "new()";                                        #2

$vc = Text::vCard::Precisely->new( version => '3.0' );
is '3.0', $vc->version, "new( version => '3.0' )";                      #3

$vc = Text::vCard::Precisely->new( version => '4.0' );
is '4.0', $vc->version, "new( version => '4.0' )";                      #4

my $fail = eval{ $vc->version('3.0') };
is undef, $fail, "fail to change the version";                          #5

$fail = eval { $vc = Text::vCard::Precisely->new( version => '2.1' ) };
is undef, $fail, "fail to declare an invalid version";                  #6

done_testing;
