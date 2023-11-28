#! perl -I. -w
use t::Test::abeltje;

# These gave problems in 0.17, so keep them around
# No::Package is to test a Not Installed thing
my @test_cases = qw<
    CPAN::Reporter
    DBI
    Parse::RecDescent
    SOAP::Lite
    Sub::Exporter
    Sub::Quote
    XML::DOM
    XML::LibXML
    XML::Twig
    No::Package
>;
my %multi_version = (
    'SOAP::Lite' => [qw< SOAP::Lite SOAP::Client >],
);

for my $test (@test_cases) {
    my $stdout = qx{"$^X" "-Ilib", "-MV=$test"};
    SKIP: {
        skip("Package not installed: $test", 1)
            if $stdout =~ m{^\tNot found}m;
        if (exists($multi_version{$test})) {
            my $pkgs = join("\n", map { "\t    $_: .+" } @{$multi_version{$test}});
            like(
                $stdout,
                qr{^$test\n\t.+:\n$pkgs},
                "found version for $test"
            );
        }
        else {
            like(
                $stdout,
                qr{^$test\n\s+.+: .+},
                "found version for $test"
            );
        }
    }
}

abeltje_done_testing();
