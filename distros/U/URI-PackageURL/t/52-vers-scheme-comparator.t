#!perl -T

use strict;
use warnings;

use Test::More;

use URI::VersionRange;
use URI::VersionRange::Util qw(version_compare generic_version_compare);

package    # hide from pause
    URI::VersionRange::Scheme::reverse {
    use parent -norequire, 'URI::VersionRange::Version';
    use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

    sub compare {
        my ($left, $right) = @_;
        return $right->[0] <=> $left->[0];
    }

    sub from_native {
        my ($class, $range, $scheme) = @_;
        return join '/', "vers:$scheme", join('|', reverse split /,/, $range);
    }
}

subtest "VERS: constraints sorted using the scheme comparator" => sub {

    #<<<
    my @tests = (
        {scheme => 'cpan',    constraints => ['<1.9', '>1.10'],          expected => 'vers:cpan/>1.10|<1.9'},
        {scheme => 'semver',  constraints => ['<1.0.0', '>=1.0.0-rc.1'], expected => 'vers:semver/>=1.0.0-rc.1|<1.0.0'},
        {scheme => 'npm',     constraints => ['<1.0.0', '>=1.0.0-beta'], expected => 'vers:npm/>=1.0.0-beta|<1.0.0'},
        {scheme => 'reverse', constraints => ['<1', '>2'],               expected => 'vers:reverse/>2|<1'},
    );
    #>>>

    foreach my $test (@tests) {
        my $vers = URI::VersionRange->new(scheme => $test->{scheme}, constraints => $test->{constraints});
        is("$vers", $test->{expected}, "to_string: $test->{expected}");
    }

};


subtest "VERS: bundled SemVer comparator" => sub {

    #<<<
    my @tests = (
        {vers => 'vers:npm/<1.0.0',    version => '1.0.0-beta', expected => 1},
        {vers => 'vers:semver/<1.0.0', version => '1.0.0-rc.1', expected => 1},
        {vers => 'vers:semver/<1.0.0', version => '1.0.0',      expected => 0},
    );
    #>>>

    foreach my $test (@tests) {
        my $vers = URI::VersionRange->from_string($test->{vers});
        is(!!$vers->contains($test->{version}), !!$test->{expected}, "contains: $test->{version} in $test->{vers}");
    }

};

subtest "VERS: version_compare utility" => sub {

    is(version_compare('cpan',    '1.10',       '1.9'),   -1, 'version_compare: cpan');
    is(version_compare('npm',     '1.0.0-beta', '1.0.0'), -1, 'version_compare: npm');
    is(version_compare('reverse', '1',          '2'),      1, 'version_compare: user-supplied comparator');

    is(
        version_compare('pypi', '1.10', '1.9'),
        generic_version_compare('1.10', '1.9'),
        'version_compare: generic fallback'
    );

};

subtest "VERS: from_native using the scheme class" => sub {

    #<<<
    my @tests = (
        {scheme => 'reverse', range => '<1,>2',       expected => 'vers:reverse/>2|<1'},      # Scheme class "from_native"
        {scheme => 'pypi',    range => '>=1.0, <2.0', expected => 'vers:pypi/>=1.0|<2.0'},    # Fallback ("native_range_to_vers")
    );
    #>>>

    foreach my $test (@tests) {
        my $vers = URI::VersionRange->from_native(scheme => $test->{scheme}, range => $test->{range});
        isa_ok($vers, 'URI::VersionRange');
        is("$vers", $test->{expected}, "from_native: $test->{range} --> $test->{expected}");
    }

};

done_testing();
