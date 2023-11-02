#! perl -w
use strict;

use Test::More 'no_plan';

use Cwd;
use Test::Smoke::Util::Execute;

local $Test::Smoke::LogMixin::USE_TIMESTAMP = 0;
{
    my $cmd = 'C:\Program Files\Git\bin\git.exe';
    my $prg = Test::Smoke::Util::Execute->new(command => qq/"$cmd"/);
    isa_ok($prg, 'Test::Smoke::Util::Execute');
    is($prg->full_command(), qq/"$cmd"/, "full_command()");
    is($prg->full_command('-q'), qq/"$cmd" -q/, "full_command(-q)");
    is($prg->full_command('-q', 'blah blah'), qq/"$cmd" -q "blah blah"/, "full_command");

    my $prg2 = Test::Smoke::Util::Execute->new(command => qq/$cmd/);
    isa_ok($prg2, 'Test::Smoke::Util::Execute');
    is($prg2->full_command(), qq/"$cmd"/, "full_command() no extra quotes");
    is(
        $prg2->full_command(commit => blah => -m => "'Inner apostrophe gone'"),
        qq{"$cmd" commit blah -m "Inner apostrophe gone"},
        "full_command() changes ' into \" around arguments"
    );
}
{
    my @numbers = map "$_\n", 1..3;
    my $lines = join("", @numbers);

    my $prog = "print qq/$lines/";
    my $ex = Test::Smoke::Util::Execute->new(
        command => "$^X"
    );
    isa_ok($ex, 'Test::Smoke::Util::Execute');
    is($ex->verbose, 0, "  Default verbose 0");

    my @output = $ex->run('-e', $prog);
    is_deeply(\@output, \@numbers, "  Got the lines as array");

    my $output = $ex->run('-e', $prog);
    is($output, $lines, "  Got the lines as scalar");
}
{
    my $hw = "Hello, World!";
    my $prog = "print qq/$hw/; exit 42";
    my $command = qq/$^X/;
    my $ex = Test::Smoke::Util::Execute->new(
        verbose => 1,
        command => $command,
    );
    isa_ok($ex, 'Test::Smoke::Util::Execute');
    is($ex->verbose, 1, "  verbose 1");

    is($ex->verbose(2), 2, "  set verbose 2");
    my ($output, $stdout);
    {
        local *STDOUT;
        open STDOUT, '>', \$stdout;
        $output = $ex->run('-e', $prog);
    }
    is_deeply($output, $hw, "  Got the output");
    is(
        $stdout,
        "In pwd(@{[cwd()]}) running:\nqx[$command -e \"$prog\"]\n",
        "  Caught the verbose [$command -e \"$prog\"]"
    );
    is($ex->exitcode, 42, "  Caught the exitcode");
}
{
    my $ex = Test::Smoke::Util::Execute->new(command => $^X);
    isa_ok($ex, 'Test::Smoke::Util::Execute');

    my $out1 = $ex->run('-e', "print 42;");
    is($out1, 42, " Running with variable arguments");
    is($ex->exitcode, 0, "  And exitcode");

    my $out2 = $ex->run('-e', "print qq/666\n/; exit 42");
    is($out2, "666\n", " Running with other arguments");
    is($ex->exitcode, 42, "  And exitcode");
}
