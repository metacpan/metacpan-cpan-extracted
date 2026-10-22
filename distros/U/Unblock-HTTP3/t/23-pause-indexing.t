use strict;
use warnings;

use ExtUtils::MakeMaker ();
use File::Find ();
use JSON::PP ();
use Test2::V0;

# PAUSE reads VERSION without executing modules. A runtime-assigned VERSION
# can therefore appear as zero despite a correct runtime value.
my $version = MM->parse_version('lib/Unblock/HTTP3.pm');
is($version, '0.13', 'main package has the expected release version');

my @modules;
File::Find::find(
    {
        no_chdir => 1,
        wanted => sub {
            my $file = $File::Find::name;
            push @modules, $file if -f $file && $file =~ /\.pm\z/;
        },
    },
    'lib',
);
is(scalar @modules, 15, 'all distribution Perl modules are included');

for my $file (sort @modules) {
    is(
        MM->parse_version($file),
        $version,
        "$file has a statically parseable distribution version",
    );
}

my @indexed = qw(
    Unblock::HTTP3
    Unblock::HTTP3::Body::Reader
    Unblock::HTTP3::Body::Stream
    Unblock::HTTP3::Capsule
    Unblock::HTTP3::Capsule::Parser
    Unblock::HTTP3::Capsule::Stream
    Unblock::HTTP3::Client
    Unblock::HTTP3::Extension::Stream
    Unblock::HTTP3::Integration
    Unblock::HTTP3::NativeABI
    Unblock::HTTP3::Server
    Unblock::HTTP3::Transaction
);

# META.json is generated for the CPAN tarball. Source-tree tests may run
# before it exists; disttest runs this check inside the packaged release.
if (-f 'META.json') {
    open my $fh, '<', 'META.json' or die "open META.json: $!";
    local $/;
    my $meta = JSON::PP::decode_json(<$fh>);
    close $fh or die "close META.json: $!";

    is($meta->{version}, $version, 'distribution metadata version matches');

    for my $package (@indexed) {
        ok(exists $meta->{provides}{$package}, "$package is in provides");
        is(
            $meta->{provides}{$package}{version},
            $version,
            "$package has the correct META.json indexed version",
        );
    }

    for my $internal (qw(
        Unblock::HTTP3::Connection
        Unblock::HTTP3::_Bytes
        Unblock::HTTP3::_Native
    )) {
        ok(!exists $meta->{provides}{$internal}, "$internal is not indexed");
    }
}
else {
    note('META.json not generated yet; make disttest checks packaged metadata');
}

done_testing;

