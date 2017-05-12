use Test;
use XML::Generator::PerlData;
BEGIN { plan tests => 2 }


my $pd = XML::Generator::PerlData->new();


####################################################
# rootname tests
###################################################

ok ( $pd->rootname() eq 'document' );

$pd->rootname( 'uburoot' );
ok( $pd->rootname() eq 'uburoot' );

####################################################




