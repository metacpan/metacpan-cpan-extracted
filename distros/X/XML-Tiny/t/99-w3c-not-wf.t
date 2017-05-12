use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";

$^W = 1;

$SIG{__WARN__} = sub {
    die(
        "Caught a warning, making it fatal:\n\n$_[0]\n"
	# eval 'use Devel::StackTrace;Devel::StackTrace->new()->as_string()'
    );
};

my @testfiles = ();
foreach my $testdir (map { "t/w3c/not-wf/$_" } qw(ext-sa not-sa sa)) {
    opendir(T, $testdir);
    push @testfiles, map { "$testdir/$_" } grep { /\.xml$/ } readdir(T);
    closedir(T);
}
print "1..".@testfiles."\n";

foreach my $testfile (@testfiles) {
    eval "parsefile('$testfile', fatal_declarations => 1, strict_entity_parsing => 1)";
    ok($@, "w3c test $testfile");
}
