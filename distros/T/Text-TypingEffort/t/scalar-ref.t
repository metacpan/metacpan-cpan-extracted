# does effort() work with a single scalarref parameter?

use Test::More tests => 1;
use Text::TypingEffort qw( effort );

my $text = "   \tThe quick brown fox jumps over the lazy dog\n";
$text   .= "\t  The quick brown fox jumps over the lazy dog\n";

my %ok = (
    characters => 88,
    presses    => 90,
    distance   => 2040,
    energy     => 4.7618,
);

my $effort = effort( \$text );
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply( $effort, \%ok, 'leading whitespace ignored' );

