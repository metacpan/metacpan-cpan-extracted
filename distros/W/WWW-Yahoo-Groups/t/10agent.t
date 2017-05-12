use Test::More tests => 7;
use vars qw( $class );

BEGIN {
    $class = 'WWW::Yahoo::Groups';
    use_ok $class;
}

my $x = $class->new();

isa_ok( $x => $class );

my $w = $x->agent();

isa_ok( $w => 'WWW::Mechanize' );

my $custom = "Fnar";
my $y = bless {}, $custom;

my $z = $x->agent($y);

is( $z => $x => "Same object as before" );
isa_ok( $z => $class );

my $t = $x->agent();

is( $t => $y => "Same object as before" );
isa_ok( $t => $custom );

