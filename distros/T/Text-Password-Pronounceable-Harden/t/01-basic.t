use Test::More tests => 4;
use Text::Password::Pronounceable::Harden;

ok(
    my $pwgen =
      Text::Password::Pronounceable::Harden->new( min => 8, max => 12 ),
    'create password generator'
);
ok( $pwgen->add_filter('Uppercase'), 'add filter' );
is( $pwgen->count,1,'count filters');

unlike( $pwgen->generate(), qr/a-z/, 'no lower case characters' );
