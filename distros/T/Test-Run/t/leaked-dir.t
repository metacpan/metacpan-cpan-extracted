use strict;
use warnings;

use Test::More tests => 2;

use File::Path;

use Test::Run::Trap::Obj;

use vars qw(@leaked_file_rets);

package MyTestRun::LeakedCheck;

use Moose;
extends("Test::Run::Obj");

sub _report_leaked_files
{
    my ($self, $args) = @_;

    push @main::leaked_file_rets, [sort { $a cmp $b } @{$args->{leaked_files}}];
}

package main;

my $sample_tests_dir = File::Spec->catdir("t", "sample-tests");
my $leaked_files_dir = File::Spec->catdir($sample_tests_dir, "leaked-files-dir");
my $leaked_file = File::Spec->catfile($leaked_files_dir, "hello.txt");

my $leak_test_file = File::Spec->catfile($sample_tests_dir, "leak-file.t");

mkdir($leaked_files_dir, 0777);
{
    {
        local (*O);
        open O, ">", $leaked_file;
        print O "This is the file hello.txt";
        close(O);
    }

    @leaked_file_rets = ();

    my $got = Test::Run::Trap::Obj->trap_run({
            class => "MyTestRun::LeakedCheck",
            args =>
            [
                test_files => [$leak_test_file],
                Leaked_Dir => $leaked_files_dir,
            ]
        });

    # TEST
    is_deeply(
        \@leaked_file_rets,
        [["new-file.txt"]],
        "Leaked files reported correctly",
    );

    # TEST
    $got->field_is("die", undef(), "Leaked files' run did not die from an exception");

    # Cleanup afterwards.
    rmtree([$leaked_files_dir], 0, 0);
}

