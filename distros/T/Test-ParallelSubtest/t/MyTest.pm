package t::MyTest;
use strict;
use warnings;

use Carp;
sub _warning_handler {
    my $warning = shift;

    # annoying Test::Cmd warning under Perl 5.6
    return if $warning =~ /^No such signal: .*\bCmd\.pm/;

    confess "warning during testing: $warning";
}
BEGIN { $SIG{__WARN__} = \&_warning_handler }

use Config;
use Test::Builder;
use Test::Cmd;
use Test::Differences;
use Test::More;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(same_as_subtest ext_perl_run error_prone_strings);


sub same_as_subtest ($$) {
    my ($testname, $source) = @_;

    $source = "use strict; use warnings; $source";

    local $Test::Builder::Level = $Test::Builder::Level + 2;

    # Convert to the equivalent test script without Test::ParallelSubtest
    my $ref_source = $source;
    $ref_source =~ s{\buse\s+Test::ParallelSubtest.*\n}{\n};
    $ref_source =~ s/\bbg_subtest\b/subtest/g;
    $ref_source = "sub bg_subtest_wait {}; $ref_source";

    my $without_bg = ext_perl_run($ref_source);

    my $with_bg = ext_perl_run($source);

    # Try it with fork() not available, results should be the same.
    my $nofork_source =
                 'BEGIN { *CORE::GLOBAL::fork = sub {undef}; } ' . $source;
    my $nofork = ext_perl_run($nofork_source);

    _remove_allowable_differences($without_bg, $with_bg, $nofork);

    is $nofork->{Status}, $without_bg->{Status}, "$testname -f status";
    eq_or_diff $nofork->{Stdout}, $without_bg->{Stdout}, "$testname -f OUT";
    eq_or_diff $nofork->{Stderr}, $without_bg->{Stderr}, "$testname -f ERR";

    is $with_bg->{Status}, $without_bg->{Status}, "$testname status";
    eq_or_diff $with_bg->{Stdout}, $without_bg->{Stdout}, "$testname OUT";
    eq_or_diff $with_bg->{Stderr}, $without_bg->{Stderr}, "$testname ERR";
}

sub ext_perl_run ($) {
    my $source = shift;

    $source .= ' ; print "tweet tweet\n"';

    local $!;
    local $?;

    my $perl = Test::Cmd->new(
        prog    => join(' ', $Config{perlpath}, (map { ("-I", $_) } @INC), '-'),
        workdir => '',
    );

    my $status = $perl->run(stdin => $source);
    my $result = {
        Status => ($status ? 1 : 0),
        Stdout => scalar $perl->stdout,
        Stderr => scalar $perl->stderr,
    };

    unless ($result->{Stdout} =~ s/tweet tweet\n//) {
        confess "Canary text not found in subprocess output, ".
                "stderr was [$result->{Stderr}]";
    }

    return $result;
}

sub _remove_allowable_differences {
    foreach my $result (@_) {
        # TAP::Parser doesn't preserve leading or trailing spaces on skip
        # reasons.
        $result->{Stdout} =~ s/( # skip \S+) \n/$1\n/g;
        $result->{Stdout} =~ s/( # skip ) /$1/g;

        # TAP::Parser doesn't preserve trailing spaces on test names.
        $result->{Stdout} =~ s/  # TODO / # TODO /g;
        $result->{Stdout} =~ s/^(([^#\n]|\\#)+) +\n/$1\n/mg;
    }
}

sub error_prone_strings {
    [empty  => ''],
    [zero   => 0],
    [spacex => ' x'],
    [hash   => '#'],
    [hash2  => '##'],
    [sphash => ' #'],
    [hashsp => '# '],
    [bshash => '\\\\#'],
}

1;

