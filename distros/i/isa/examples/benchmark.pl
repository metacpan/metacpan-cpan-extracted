use v5.32;
use strict;
use warnings;
use feature 'isa';
no warnings 'experimental::isa';
use Benchmark 'cmpthese';

package Thingy {
	use Class::Tiny;
}

use isa 'Thingy';

our $obj = Thingy->new;

die unless $obj isa Thingy;
die unless isa_Thingy $obj;

# prepend to BOTH versions, even though isa.pm doesn't need it
my $common = 'use feature "isa"; no warnings "experimental::isa";';

cmpthese -3, {
	native => $common . '$::obj isa Thingy',
	isa_pm => $common . '::isa_Thingy $::obj',
};

__END__
             Rate native isa_pm
native  6619309/s     --   -53%
isa_pm 14206513/s   115%     --
