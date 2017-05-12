#!/perl -I..

use strict;
use warnings;
# no warnings 'uninitialized';
print "1..6\n";

my $tn=0;
sub is
{
    my $ok = $_[0] eq $_[1]? "ok " : "not ok ";
    print $ok, ++$tn;
    if ($ok eq "not ok ")
    {
        print "\t$_[2]: expected '$_[1]', got '$_[0]'"
    }
    print "\n";
}

use Tie::Plural;

# Were all variables imported? (1)
is ref tied %pl, 'Tie::Plural' => '%pl imported';

my $num;

$num=0;
is "I have $num dog$pl{$num}.", "I have 0 dogs.", 'no dogs';
$num=1;
is "I have $num dog$pl{$num}.", "I have 1 dog.",  'one dog';
$num=2;
is "I have $num dog$pl{$num}.", "I have 2 dogs.", 'two dogs';
$num=3;
is "I have $num dog$pl{$num}.", "I have 3 dogs.", 'three dogs';

$num = 700;
is "My wife owns $pl{$num,'many','one','no'} dress$pl{$num,'es'}.", "My wife owns many dresses.", 'Lots of dresses';
