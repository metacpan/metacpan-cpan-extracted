use Test;
use XML::Generator::PerlData;
BEGIN { plan tests => 8 }


my $pd = XML::Generator::PerlData->new();

####################################################
# attr tests
###################################################
{
my %map = ( a => 'one', b => 'two', c => 'three' );
ok( scalar keys %{$pd->attrmap()} == 0 );

$pd->attrmap( %map );
ok ( scalar keys %{$pd->attrmap()} == 3 );

$pd->add_attrmap( d => 'four' );
ok( scalar keys %{$pd->attrmap()} == 4 );
}

{
my %map = $pd->attrmap();
ok( defined($map{a}) and defined( $map{b} ) and defined( $map{c} ) and defined( $map{d} ) );

ok( ($map{a}->[0] eq 'one') && 
    ($map{b}->[0] eq 'two') && 
    ($map{c}->[0] eq 'three') && 
    ($map{d}->[0] eq 'four') );
}

{
$pd->delete_attrmap( 'd' );
ok( scalar keys %{$pd->attrmap()} == 3 );
}

{
my %map = $pd->attrmap();
ok( defined($map{a}) and defined( $map{b} ) and defined( $map{c} ) );

ok( ($map{a}->[0] eq 'one') && 
    ($map{b}->[0] eq 'two') && 
    ($map{c}->[0] eq 'three') );
}
####################################################




