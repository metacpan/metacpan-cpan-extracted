#!/usr/bin/perl -w

use strict;
use FileHandle;
use Test::More 0.88;
use Test::Reporter;
use Data::Dumper;

$Test::Reporter::VERSION ||= 999; # dzil will set it for us on release

plan tests => 14;

my $CR   = "\015";
my $LF   = "\012";

my $distro = "Foo-Bar-1.23";
my $distfile = "AUTHOR/" . $distro . ".tar.gz";

my $reporter = Test::Reporter->new
(
    grade => 'pass',
    distribution => $distro,
    distfile => $distfile,
    from => 'johndoe@example.net',
);
isa_ok($reporter, 'Test::Reporter');
my $file = $reporter->write();
like($file, "/$distro/");
ok(-e $file);
my $orig_subject = $reporter->subject;
my $orig_from = $reporter->from;
my $orig_report = $reporter->report;

undef $reporter;

# convert line endings
open my $in_fh, "<", $file;
my $slurp = do { local $/; <$in_fh> };
close $in_fh;

$slurp =~ s{$CR?$LF}{$CR$LF}g;

open my $out_fh, ">", $file;
binmode $out_fh;
print {$out_fh} $slurp;
close $out_fh;


# read in

$reporter = Test::Reporter->new
(
)->read($file);
isa_ok($reporter, 'Test::Reporter');
like($reporter->subject,"/^PASS $distro\\s/");
like($reporter->report, '/This distribution has been tested/');
like($reporter->report,'/Summary of my/');
is($reporter->grade, 'pass');
is($reporter->distribution, $distro);
is($reporter->distfile, $distfile);
like($reporter->perl_version->{_myconfig}, '/Summary of my/', "Regenerated _myconfig");

# confirm roundtrip -- particularly newlines
is($reporter->subject, $orig_subject);
is($reporter->from, $orig_from);
is($reporter->report, $orig_report);

unlink $file;

done_testing;
