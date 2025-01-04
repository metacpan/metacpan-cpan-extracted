#!/usr/bin/perl -I.

use strict;
use warnings;

use t::Test::abeltje;
use Capture::Tiny  qw( capture );

# These gave problems in 0.17, so keep them around
# No::Package is to test a Not Installed thing
my @test_cases = qw(
    CPAN::Reporter
    DBI
    Devel::PPPort
    No::Package
    Parse::RecDescent
    SOAP::Lite
    Sub::Exporter
    Sub::Quote
    XML::DOM
    XML::LibXML
    XML::Twig
    );
my %multi_version = (
    "SOAP::Lite" => [qw( SOAP::Lite SOAP::Client )],
    );

for my $test (@test_cases) {
    my ($out, $err, $ext) = capture { system $^X, "-Mblib", "-Ilib", "-MV=$test" };
    if ($out =~ m{^$test\n\tNot found}) {
	ok (1, "Package $test is not installed");
	next;
	}
    if (exists ($multi_version{$test})) {
	my $pkgs = join "\n" => map { "\t    $_: .+" } @{$multi_version{$test}};
	like ($out, qr{^$test\n\t.+:\n$pkgs}, "found version for $test");
	next;
	}

    (my $rpt = $out) =~ s{[\s\r\n]+}{ }g;
    $rpt =~ s{\s+$}{};
    like ($out, qr{^$test\s+.+: (?!\?)}, "found version for $test ($rpt)");
    }

abeltje_done_testing ();
