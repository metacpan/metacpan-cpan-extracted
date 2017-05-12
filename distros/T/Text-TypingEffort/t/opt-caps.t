# Is the 'caps' option handled correctly?

use Test::More tests => 8;
use Text::TypingEffort qw( effort );

my $text = "   \tTHE QUICK BROWN FOX JUMPS OVER THE LAZY DOG\n";
$text   .= "\t  THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG\n";

# the standard test text
my %ok = (
    characters => 88,
    presses    => 92,
    distance   => 2040,
    energy     => 4.7636,
);
$effort = effort( text => $text );
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply( $effort, \%ok, 'single caps chunk' );

$effort = effort( text => $text, caps => undef );
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply( $effort, \%ok, 'caps=undef' );

# don't use the caps option
%ok = (
    characters => 88,
    presses    => 158,
    distance   => 5160,
    energy     => 11.9818,
);
$effort = effort(
    text => $text,
    caps => 0,
);
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply( $effort, \%ok, 'no caps handling' );

# set the caps option to something ridiculous
$effort = effort(
    text => $text,
    caps => 1000,
);
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply( $effort, \%ok, 'gianormous caps handling' );

# intermixing caps and non-caps
$text = 'This is a SHORT test of CAPITALIZED letters';
$effort = effort(
    text => $text,
    caps => 0,
);
%ok = (
    characters => 43,
    presses    => 60,
    distance   => 1560,
    energy     => 3.6334,
);
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply( $effort, \%ok, 'mixed:no caps' );

$effort = effort($text);
%ok = (
    characters => 43,
    presses    => 48,
    distance   => 900,
    energy     => 2.1083,
);
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply( $effort, \%ok, 'mixed:standard caps' );

$effort = effort(text=>$text,caps=>6);
%ok = (
    characters => 43,
    presses    => 51,
    distance   => 1080,
    energy     => '2.5240',
);
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply( $effort, \%ok, 'mixed:6 caps' );

# try an invalid value for B<caps>
$text = 'This string has Some places with ONE capital';
my $a = effort(text=>$text, caps=>2);
my $b = effort(text=>$text, caps=>1);
is_deeply($b, $a, 'caps=1');

