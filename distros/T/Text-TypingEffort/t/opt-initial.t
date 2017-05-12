# Is the 'initial' option handled correctly?

use Test::More tests => 4;
use Text::TypingEffort qw( effort );

my $text_1 = "   \tThe quick brown fox jumps over the lazy dog\n";
$text_1   .= "\t  The quick brown fox jumps over the lazy dog\n";

my $text_2 = "The lazy dog chased after the so-called quick föx.";

my $ok_1 = {
    characters => 88,
    presses    => 90,
    distance   => 2040,
    energy     => 4.76178104431768,
};

my $ok_2 = {
    characters => 49,
    presses    => 50,
    distance   => 890,
    energy     => 2.08710545560919,
    unknowns   => {
        presses => {
            'ö' => 1,
        },
        distance => {
            'ö' => 1,
        },
    },
};

my $effort;

# try text_1 then text_2
$effort = effort(text=>$text_1);
$effort = effort(text=>$text_2, unknowns=>1, initial=>$effort);
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply(
    $effort,
    add_hashes($ok_1, $ok_2),
    'text_1 then text_2'
);

# try text_2 then text_1
$effort = effort(text=>$text_2, unknowns=>1);
$effort = effort(text=>$text_1, initial=>$effort);
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply(
    $effort,
    add_hashes($ok_1, $ok_2),
    'text_2 then text_1'
);

#### try some wierd conditions

# try initial with an undefined 'characters' value
$effort = effort( text=>$text_1, initial=>{characters=>undef} );
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply(
    $effort,
    add_hashes($ok_1, {}),
    'initial characters undefined',
);

# try initial with a non-reference as the value
$effort = effort( text=>$text_1, initial=>'please RTFM' );
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply(
    $effort,
    add_hashes($ok_1, {}),
    'initial not a ref',
);


####################### helper subs ########################

sub add_hashes {
    no warnings 'uninitialized';

    my %a = %{ $_[0] };
    my %b = %{ $_[1] };

    my %result;
    for (qw/characters presses distance energy/) {
        $result{$_} = $a{$_} + $b{$_};
    }
    if( $a{unknowns} or $b{unknowns} ) {
        for my $m (qw/presses distance/) {
            my @keys;
            push @keys, keys %{$a{unknowns}{$m}};
            push @keys, keys %{$b{unknowns}{$m}};
            for( @keys ) {
                $result{unknowns}{$m}{$_} =
                    $a{unknowns}{$m}{$_} +
                    $b{unknowns}{$m}{$_};
            }
        }
    }
    $result{energy} = sprintf("%.4f", $result{energy});
    return \%result;
}
