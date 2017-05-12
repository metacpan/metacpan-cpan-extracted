# Tie-Filehandle-Preempt-Stdin
# t/01_load.t - check module loading

use Test::More 
# qw(no_plan);
tests => 6;

BEGIN { use_ok( 'Tie::Filehandle::Preempt::Stdin' ); }

my (@prompts, $object, @entered);
@prompts = qw| alpha beta gamma |;
$object = tie *STDIN, 'Tie::Filehandle::Preempt::Stdin', @prompts;
can_ok('Tie::Filehandle::Preempt::Stdin', ('READLINE'));
isa_ok($object, 'Tie::Filehandle::Preempt::Stdin');

# Best case:  Items supplied as prompts exactly equal to prompts
# requested. 
is_deeply(\@prompts, simulate_prompt(3), 
    "STDIN was correctly preempted.");
$object = undef;
untie *STDIN;

# Not so bad case:  More items supplied as prompts than prompts
# requested.
@prompts = qw| alpha beta gamma |;
$object = tie *STDIN, 'Tie::Filehandle::Preempt::Stdin', @prompts;
is_deeply([@prompts[0..1]], simulate_prompt(2), 
    "STDIN was correctly preempted.");
$object = undef;
untie *STDIN;

# Bad case:  Fewer items supplied as prompts than prompts requested.
@prompts = qw| alpha beta gamma |;
$object = tie *STDIN, 'Tie::Filehandle::Preempt::Stdin', @prompts;
{
    local $SIG{__WARN__} = \&_capture;
    eval { simulate_prompt(4); };
    print "\n";
}
like($@, qr/^List of prompt responses has been exhausted/, 
   "Prompt responses correctly found to have been exhausted")
   || print STDERR "$@\n";
$object = undef;
untie *STDIN;


##### UTILITY SUBROUTINES #####

sub simulate_prompt {
    my $count = shift;
    my ($entry, @entered);
    for (my $i = 1; $i <= $count; $i++) {
        print "Enter item $i:  ";
        chomp($entry = <STDIN>);
        push @entered, $entry;
    }
    print "\n";
    return \@entered;
}

sub _capture { my $str = $_[0]; }

