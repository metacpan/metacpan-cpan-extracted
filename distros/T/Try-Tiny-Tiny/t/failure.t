use strict; use warnings;
use Test::More;

#
use Try::Tiny 'try';

plan skip_all => 'Sub::{Name,Util} un{available,supported}'
	unless eval { Try::Tiny->VERSION('0.23') and defined &Sub::Util::set_subname }
	or     eval { Try::Tiny->VERSION('0.15') and defined &Sub::Name::subname };

plan tests => 4;

my $cb = sub { (caller 0)[3] };
my $name = &$cb;

isnt &try($cb), $name, 'Try::Tiny alone names its callback';

my $w;
my $r = eval { local $SIG{'__WARN__'} = sub { $w = join '', @_ }; require Try::Tiny::Tiny };
my $e = $@ || 'error lost';

is $r, undef, 'Try::Tiny::Tiny fails to load after Try::Tiny';
like $e, qr!\ATry/Tiny/Tiny.pm did not return a true value !, '... with the expected error';
is $w, "Try::Tiny::Tiny is ineffective (probably loaded too late)\n", '... and warning';
