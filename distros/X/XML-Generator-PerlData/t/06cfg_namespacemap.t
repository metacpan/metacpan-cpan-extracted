use Test;
use XML::Generator::PerlData;
BEGIN { plan tests => 10 }


my $pd = XML::Generator::PerlData->new();

####################################################
# attr tests
###################################################
{
my %map = ( 'http://ubu1' => 'one', 'http://ubu2' => 'two', 'http://ubu3' => 'three' );

#1
ok( scalar keys %{$pd->namespacemap()} == 0 );

$pd->namespacemap( %map );
#2
ok ( scalar keys %{$pd->namespacemap()} == 3 );

$pd->add_namespacemap( 'http://ubu4' => 'four' );

#3
ok( scalar keys %{$pd->namespacemap()} == 4 );

$pd->add_namespacemap( 'http://ubu4' => 'foura' );

#4
ok( scalar keys %{$pd->namespacemap()} == 4 );
}


{
my %map = $pd->namespacemap();
#5
ok( defined($map{'http://ubu1'}) and 
    defined( $map{'http://ubu2'} ) and 
    defined( $map{'http://ubu3'} ) 
    and defined( $map{'http://ubu4'} ) );

#6
ok( ($map{'http://ubu1'}->[0] eq 'one') && 
    ($map{'http://ubu2'}->[0] eq 'two') && 
    ($map{'http://ubu3'}->[0] eq 'three') && 
    ($map{'http://ubu4'}->[0] eq 'four') &&
    ($map{'http://ubu4'}->[1] eq 'foura')
  );
}

{
$pd->delete_namespacemap( 'four' );
#7
ok( scalar keys %{$pd->namespacemap()} == 4 );
}

{
$pd->delete_namespacemap( 'foura' );
#8
ok( scalar keys %{$pd->namespacemap()} == 3 );
}

{
my %map = $pd->namespacemap();

#9
ok( defined($map{'http://ubu1'}) and
    defined( $map{'http://ubu2'} ) and
    defined( $map{'http://ubu3'} )
  );

#10
ok( ($map{'http://ubu1'}->[0] eq 'one') && 
    ($map{'http://ubu2'}->[0] eq 'two') && 
    ($map{'http://ubu3'}->[0] eq 'three')
  ); 
}


####################################################




