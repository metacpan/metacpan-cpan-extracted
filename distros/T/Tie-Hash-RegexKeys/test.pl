# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 1 };
use Tie::Hash::RegexKeys;
ok( 1 );    # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;


$nbr =1; 

tie %h, 'Tie::Hash::RegexKeys';

my $a = '.1.2.3.4.5.6.2';
my $b = '.1.2.3.4.5.7';
my $c = '.1.2.3.4.5.6.1';
my $d = '.1.2.3.4.5.6.1.6';

$h{$a}="key1";
$h{$b}="key2";
$h{$c}="subkey1";
$h{$d}="subkey2";

my $pat = '^\.1\.2\.3\.4\.5\.6.*';
my @res = tied(%h)->FETCH_KEYS(qr/$pat/);

@ret = ( '.1.2.3.4.5.6.1' , '.1.2.3.4.5.6.1.6', '.1.2.3.4.5.6.2' );


foreach $result ( @res )
{
$nbr++;
    print "*******result=$result\tret=".$ret[$nbr-2]."\n";

    if ( $ret[$nbr -2] eq $result )
    {
        state( 0,$nbr );
    }
    else
    {
        state( 1,$nbr );
    }

}

sub state
{
    my ( $stat, $ws ) = @_;

    wait();

    print( $stat ? "not ok $ws\n" : "ok $ws\n" );
}
