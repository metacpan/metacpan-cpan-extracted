use Test;
use XML::Generator::PerlData;
BEGIN { plan tests => 8 }


my $pd = XML::Generator::PerlData->new();

####################################################
# keymap tests
###################################################
{
my %map = ( a => 'one', b => 'two', c => 'three' );
ok( scalar keys %{$pd->keymap()} == 0 );

$pd->keymap( %map );
ok ( scalar keys %{$pd->keymap()} == 3 );

$pd->add_keymap( d => 'four' );
ok( scalar keys %{$pd->keymap()} == 4 );
}

{
my %map = $pd->keymap();
ok( defined($map{a}) and defined( $map{b} ) and defined( $map{c} ) and defined( $map{d} ) );

ok( ($map{a} eq 'one') && ($map{b} eq 'two') && ($map{c} eq 'three') && ($map{d} eq 'four') );
}

{
$pd->delete_keymap( 'd' );
ok( scalar keys %{$pd->keymap()} == 3 );
}

{
my %map = $pd->keymap();
ok( defined($map{a}) and defined( $map{b} ) and defined( $map{c} ) );

ok( ($map{a} eq 'one') && ($map{b} eq 'two') && ($map{c} eq 'three') );
}
####################################################




