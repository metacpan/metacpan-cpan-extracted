use strict;
use warnings;

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which literal regexes the policy reports, and which it leaves to the
call they are the pattern of

=head1 DESCRIPTION

A table of snippets that must be reported and a table that must not, under the
default configuration and under one naming functions of its own.  The first
tables are the original policy's behaviour, which this fork must not have
changed; the rest are what it adds.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;
use Perl::Critic::Policy::ProhibitRegexForSimpleSubstring;

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for
# a .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern,
# and a bare 'ProhibitRegexForSimpleSubstring' also matches the original.
my $POLICY = '^Perl::Critic::Policy::ProhibitRegexForSimpleSubstring$';

sub critic_with {
    my ($profile) = @_;
    return Perl::Critic->new( -profile => $profile, '-single-policy' => $POLICY, -severity => 1 );
}

sub violations {
    my ( $critic, $source ) = @_;
    return scalar $critic->critique( \$source );
}

sub check_table {
    my ( $critic, $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( violations( $critic, $source ), $expected, "$label: $case: $source" );
    }
    return;
}

my $default = critic_with(q{});

# --- The original's behaviour, unchanged ---------------------------------------

check_table(
    $default, 'reported, as the original did',
    'the POD example, m//'            => [ 1, q{if ( $str =~ m/foo/ ) { 1 }} ],
    'the POD example, an escaped dot' => [ 1, q{if ( $str =~ /bar\.baz/ ) { 1 }} ],
    'a match against $_'              => [ 1, q{print if m/foo/;} ],
    'a match in a grep block'         => [ 1, q{grep { m/foo/ } @lines;} ],
    'an /aa, which exempts nothing'   => [ 1, q{$str =~ m/foo/aa;} ],
    'an unconfigured function'        => [ 1, q{grep_lines( m/foo/, @lines );} ],
    'an unconfigured method'          => [ 1, q{$obj->grep_lines( m/foo/ );} ],
    'an unconfigured list operator'   => [ 1, q{foo m/foo/, $s;} ],
    'a hash key named split'          => [ 1, q{my %h = ( split => m/foo/ );} ],
);

check_table(
    $default, 'not reported, as the original did not',
    'the POD example, index' => [ 0, q{if ( index( $str, 'foo' ) != -1 ) { 1 }} ],
    '/i'                     => [ 0, q{$str =~ m/foo/i;} ],
    'a character class'      => [ 0, q{$str =~ m/[ab]c/;} ],
    'a quantifier'           => [ 0, q{$str =~ m/fo+/;} ],
    'an anchor'              => [ 0, q{$str =~ m/^foo/;} ],
    'a capturing group'      => [ 0, q{$str =~ m/(foo)/;} ],
    'a non-capturing group'  => [ 0, q{$str =~ m/(?:foo)/;} ],
    'interpolation'          => [ 0, q{$str =~ m/$foo/;} ],
    'alternation'            => [ 0, q{$str =~ m/foo|bar/;} ],
    'a substitution'         => [ 0, q{$str =~ s/foo/bar/;} ],
    'a compiled regex'       => [ 0, q{my $rx = qr/foo/;} ],
    'split on a pattern'     => [ 0, q{split m/\s+/, $s;} ],
);

# --- What this fork changes: modifiers ------------------------------------------

# Only /i stops index() doing the job.  /m changes ^ and $, /s changes ., and /x
# makes whitespace and comments insignificant -- none of which a pattern of
# nothing but literals has -- and a use re in scope counts the same as a flag
# written on the match.
check_table(
    $default, 'a modifier that does not change literal text is still reported',
    '/m'                              => [ 1, q{$str =~ m/foo/m;} ],
    '/s'                              => [ 1, q{$str =~ m/foo/s;} ],
    '/x'                              => [ 1, q{$str =~ m/foo/x;} ],
    '/msx together'                   => [ 1, q{$str =~ m/foo/msx;} ],
    '/n'                              => [ 1, q{$str =~ m/foo/n;} ],
    '/x over a space, still foobar'   => [ 1, q{$str =~ m/foo bar/x;} ],
    '/x over a comment, still foobar' => [ 1, qq{\$str =~ m/foo # the first half\nbar/x;} ],
    "use re '/aasx'"                  => [ 1, q{use re '/aasx'; $str =~ m/foo/;} ],
    "use re '/aasx', then no re"      => [ 1, q{use re '/aasx'; { no re '/sx'; $str =~ m/foo/ }} ],
);

check_table(
    $default, 'what does change the answer is still not reported',
    "use re '/i'"                  => [ 0, q{use re '/i'; $str =~ m/foo/;} ],
    "use re '/aasxi'"              => [ 0, q{use re '/aasxi'; $str =~ m/foo/;} ],
    'a space spelled as a class'   => [ 0, q{use re '/aasx'; $str =~ m/foo[ ]bar/;} ],
    "split's pattern under use re" => [ 0, q{use re '/aasx'; split m/,/, $s;} ],
);

# --- What this fork adds: split's pattern --------------------------------------

check_table(
    $default, 'split takes a literal pattern',
    'm//, without parentheses'      => [ 0, q{split m/x/, $s;} ],
    '//, without parentheses'       => [ 0, q{split /x/, $s;} ],
    'm//, with parentheses'         => [ 0, q{split( m/x/, $s );} ],
    '//, with parentheses'          => [ 0, q{split(/x/, $s);} ],
    'assigned'                      => [ 0, q{my @lines = split m/\n/, $text;} ],
    'as a loop list'                => [ 0, q{foreach my $line ( split m/\n/, File::Slurper::read_text($tt) ) { 1 }} ],
    'with no string, splitting $_'  => [ 0, q{split m/x/;} ],
    'CORE::split'                   => [ 0, q{CORE::split( m/x/, $s );} ],
    'as a method'                   => [ 0, q{$obj->split( m/x/, $s );} ],
    'inside another call'           => [ 0, q{foo( split m/x/, $s );} ],
    'then or die'                   => [ 0, q{split m/x/, $s or die;} ],
    'the last statement of a block' => [ 0, q{sub { split m/,/, $_[0] }} ],
    'in parentheses of its own'     => [ 0, q{split( ( m/x/ ), $s );} ],
);

check_table(
    $default, 'split does not exempt what is not its pattern',
    'a match as the string'                   => [ 1, q{split $sep, $str =~ m/x/;} ],
    'a bare match as the second argument'     => [ 1, q{split m/,/, m/x/;} ],
    'a ternary choosing the pattern'          => [ 2, q{split( $tab ? m/a/ : m/b/, $s );} ],
    'a hash subscript inside the arguments'   => [ 1, q{split( $h{ m/x/ }, $s );} ],
    'an anonymous array inside the arguments' => [ 1, q{split( [ m/x/ ], $s );} ],
    'joined onto something'                   => [ 1, q{split m/x/ . $more, $s;} ],
);

is( violations( $default, q{$str =~ m/foo/;  ## no critic (ProhibitRegexForSimpleSubstring)} ), 0, 'an explicit no-critic is what signs it off' );

# --- allow ----------------------------------------------------------------------
{
    my $configured = critic_with( \"[ProhibitRegexForSimpleSubstring]\nallow = grep_lines My::Util::match_all\n" );

    check_table(
        $configured, 'configured, not reported',
        'an unqualified entry, called bare'    => [ 0, q{grep_lines( m/foo/, @lines );} ],
        'an unqualified entry, parenless'      => [ 0, q{grep_lines m/foo/, @lines;} ],
        'an unqualified entry, qualified'      => [ 0, q{Other::grep_lines( m/foo/, @lines );} ],
        'an unqualified entry, as a method'    => [ 0, q{$obj->grep_lines( m/foo/ );} ],
        'a qualified entry, called qualified'  => [ 0, q{My::Util::match_all( m/foo/, $s );} ],
        'a qualified entry, as a class method' => [ 0, q{My::Util->match_all( m/foo/, $s );} ],
        'the default survives'                 => [ 0, q{split m/\n/, $text;} ],
    );

    check_table(
        $configured, 'configured, still reported',
        'a qualified entry does not match bare'      => [ 1, q{match_all( m/foo/, $s );} ],
        'a qualified entry does not match a package' => [ 1, q{Other::match_all( m/foo/, $s );} ],
        'a qualified entry does not match an object' => [ 1, q{$obj->match_all( m/foo/, $s );} ],
        'not the first argument'                     => [ 1, q{grep_lines( $s, m/foo/ );} ],
        'a function nobody allowed'                  => [ 1, q{foo( m/foo/ );} ],
        'nothing else got exempted'                  => [ 1, q{$str =~ m/foo/;} ],
    );
}

# Places a match can sit with nothing around it to climb into.
foreach my $source ( q{m/foo/;}, q{sub { m/foo/ }}, q{split m/x/} ) {
    my @warned = warnings { violations( $default, $source ) };
    is_deeply( \@warned, [], "no warning from critiquing it: $source" );
}

done_testing();
