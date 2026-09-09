use strict;
use warnings;

use re '/aa';

use 5.014;

use Test::More;

use Perl::Critic;
use Perl::Critic::Policy::ProhibitPrintSTDERR;

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for
# a .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets -- which then fail for want of POD rather than for printing.
# Note the hyphen in -single-policy: -single_policy is accepted and silently
# ignored, leaving all 200-odd policies switched on.
my $critic = Perl::Critic->new( -profile => q{}, '-single-policy' => 'ProhibitPrintSTDERR', -severity => 1 );

sub violations {
    my ($source) = @_;
    return scalar $critic->critique( \"use strict;\nuse warnings;\n$source\n" );
}

my %prohibited = (
    'bareword handle'    => q{print STDERR "oh no\n";},
    'printf'             => q{printf STDERR "%s\n", $why;},
    'say'                => q{say STDERR 'oh no';},
    'glob in a block'    => q{print {*STDERR} "oh no\n";},
    'globref in a block' => q{print {\*STDERR} "oh no\n";},
    'spaced block'       => q{print { *STDERR } "oh no\n";},
    'bare glob'          => q{print *STDERR "oh no\n";},
    'parenthesised'      => q{print(STDERR "oh no\n");},
    'IO::Handle method'  => q{STDERR->print("oh no\n");},
    'no argument'        => q{print STDERR;},
    'heredoc'            => qq{print STDERR <<'EOF';\nbody\nEOF\n},
);

foreach my $case ( sort keys %prohibited ) {
    is( violations( $prohibited{$case} ), 1, "$case is a violation" );
}

my %allowed = (
    'plain print'             => q{print "ordinary\n";},
    'explicit stdout'         => q{print STDOUT "ordinary\n";},
    'stdout in a block'       => q{print {*STDOUT} "ordinary\n";},
    'a lexical handle'        => q{print $fh "into a file\n";},
    'a handle in a block'     => q{print {$fh} "into a file\n";},
    'warn'                    => q{warn "the thing this policy wants";},
    'parenthesised plain'     => q{print("ordinary\n");},
    'parenthesised variable'  => q{print($x);},
    'print on another object' => q{$obj->print("not ours");},
    'a sub of our own'        => q{sub print_stderr { return }},
    'STDERR as a bare word'   => q{my $x = fileno(STDERR);},
    'STDERR after an op'      => q{my $x = $a * STDERR;},
    'close'                   => q{close(STDERR);},
);

foreach my $case ( sort keys %allowed ) {
    is( violations( $allowed{$case} ), 0, "$case is not a violation" );
}

is( violations(q{print STDERR "x\n";  ## no critic (ProhibitPrintSTDERR)}), 0, 'an explicit no-critic is what signs it off' );

is(
    violations( join "\n", '## no critic (ProhibitPrintSTDERR)', q{print STDERR "usage: $0\n";}, q{print STDERR "  --verbose\n";}, '## use critic' ),
    0,
    'and a region of them signs off usage text in one place'
);

is( violations( join "\n", q{print STDERR "a\n";}, q{print STDERR "b\n";} ), 2, 'each one is counted' );

done_testing();
