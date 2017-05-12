#!perl
use FindBin qw($Bin); use lib $Bin;
use warnings::method; # installs the check routine
use warnings;         # enables  the check routine
use Foo;

my $foo = Foo->new();                      # OK
$foo->bar('Called as methods');            # OK

$foo = Foo::new('Foo');                    # WARN
Foo::bar($foo, 'Called as functions');     # WARN
{
    no warnings 'syntax';
    $foo = Foo::new('Foo');                # OK
    Foo::bar($foo, 'Called as functions'); # OK
}

open my($in), '<', __FILE__; # print this file with line number
my $i = 0; 
while(<$in>){
	last if /__FILE__/;
	printf '%02d:%s', ++$i, $_;
}
