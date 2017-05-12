# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Markdown-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test::More qw(no_plan);
BEGIN { use_ok('Text::Markdown::Discount') };

#########################

use FindBin qw($Bin);
use Text::Diff;

opendir(DIR, "$Bin/../xt/MarkdownTest_1.0.3/Tests");

foreach my $testfile (grep { /\.text$/ } readdir(DIR)) {
    my $testname = $testfile;
    $testname =~ s{(.+)\.text$}{$1}i; 
    open (EXPECTED, "$Bin/../xt/MarkdownTest_1.0.3/Tests/$testname" . '.html') or die "NO html file for $testname";
    my $expected = do {undef $/; <EXPECTED>};
    my $actual = `$Bin/../xt/MarkdownXS.pl '$Bin/../xt/MarkdownTest_1.0.3/Tests/$testfile'` or die "failed run MarkdownXS.pl $testfile"; 

    $expected =~ s{'}{'\\''}g; # escape ' chars for shell
    $actual =~ s{'}{'\\''}g;
    $expected = `echo '$expected' | tidy --show-body-only 1 --quiet 1 --show-warnings 0`;
    $actual   = `echo '$actual' | tidy --show-body-only 1 --quiet 1 --show-warnings 0`;

    if ($actual eq $expected) {
        pass($testname);
    } else {
        fail($testname);
        diag diff \$expected, \$actual;
    }
}
