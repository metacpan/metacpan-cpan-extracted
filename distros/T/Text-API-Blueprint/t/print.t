#!perl

use t::tests;
use Text::API::Blueprint ();

#plan tests => 11;

################################################################################

is( Text::API::Blueprint::_autoprint( 1, 'foobar' ),
    'foobar', '_autoprint returns string' );

################################################################################

local $Text::API::Blueprint::Autoprint = 0;
is( Text::API::Blueprint::_autoprint( undef, 'foobar' ),
    'foobar', '_autoprint returns string' );

################################################################################

my $str = 'x';
local $Text::API::Blueprint::Autoprint = \$str;
isnt( Text::API::Blueprint::_autoprint( undef, 'foobar' ),
    'foobar', '_autoprint returns no string' );
is( $str => 'xfoobar', 'output appended' );

################################################################################

pipe( my $R, my $W ) or die "cannot pipe: $!";
local $Text::API::Blueprint::Autoprint = $W;
isnt( Text::API::Blueprint::_autoprint( undef, 'foobar' ),
    'foobar', '_autoprint returns no string' );
close $W;
is( <$R> => 'foobar', 'output in pipe' );
close $R;

################################################################################

done_testing;
