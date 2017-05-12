use Test;
use XML::Generator::PerlData;
BEGIN { plan tests => 2 }


my $pd = XML::Generator::PerlData->new();


####################################################
# defaultname tests
###################################################

ok ( $pd->defaultname() eq 'default' );

$pd->defaultname( 'defaultubu' );
ok( $pd->defaultname() eq 'defaultubu' );

###################################################





