use Test::More tests => 3;
use Text::Password::Pronounceable::Harden;

my $pg = Text::Password::Pronounceable::Harden->new();

is($pg->min,8,'checking min default');
is($pg->max,8,'checking max default');

like( $pg->generate(), qr/^[a-z]{8}$/, 'just using defaults' );
