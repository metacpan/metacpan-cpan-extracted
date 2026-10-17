#!perl -T

use strict;
use warnings;

use Test::More;

use URI::VersionRange;

our $INJECTED = 0;

subtest "VERS: scheme is never evaluated as code" => sub {

    my $payload = q{x if 0; $main::INJECTED = 1};

    is(URI::VersionRange::Version->load($payload), 'URI::VersionRange::Version', 'load: invalid scheme uses fallback');

    eval { URI::VersionRange->new(scheme => $payload, constraints => ['1.0']) };
    like($@, qr/invalid scheme/, 'new: invalid scheme');

    eval { URI::VersionRange->from_native(scheme => $payload, range => '1.0') };
    like($@, qr/invalid scheme/, 'from_native: invalid scheme');

    is($INJECTED, 0, 'scheme is not evaluated as code');

};

subtest "VERS: scheme comparator classes" => sub {

    #<<<
    my %modules = (
        'URI/VersionRange/Scheme/foo_bar.pm'        => "package URI::VersionRange::Scheme::foo_bar;\nuse parent 'URI::VersionRange::Version';\n1;\n",
        'URI/VersionRange/Scheme/broken.pm'         => "package URI::VersionRange::Scheme::broken;\nsub {\n1;\n",
        'URI/VersionRange/Scheme/missing_module.pm' => "package URI::VersionRange::Scheme::missing_module;\nuse Not::Installed::Module;\n1;\n",
    );
    #>>>

    # Load the modules from memory (based on App-FatPacker and Perlbrew)
    local @INC = (
        sub {
            my (undef, $file) = @_;
            return unless exists $modules{$file};
            open my $fh, '<', \$modules{$file} or die "Can't open '$file': $!";
            return $fh;
        },
        @INC
    );

    #<<<
    my %classes = (
        cpan          => 'URI::VersionRange::Scheme::cpan',
        semver        => 'URI::VersionRange::Scheme::semver',
        npm           => 'URI::VersionRange::Scheme::npm',
        pypi          => 'URI::VersionRange::Version',
        datetime      => 'URI::VersionRange::Scheme::datetime',
        intdot        => 'URI::VersionRange::Scheme::intdot',
        lexicographic => 'URI::VersionRange::Scheme::lexicographic',
        unknown       => 'URI::VersionRange::Version',
    );
    #>>>

    foreach my $scheme (sort keys %classes) {
        is(URI::VersionRange::Version->load($scheme), $classes{$scheme}, "load: '$scheme' scheme");
    }

    foreach my $scheme (qw[broken missing_module]) {
        eval { URI::VersionRange::Version->load($scheme) };
        like(
            $@,
            qr/Failed to load 'URI::VersionRange::Scheme::$scheme' comparator class/,
            "load: '$scheme' scheme croaks"
        );
    }

};

done_testing();
