#!perl -T

use strict;
use warnings;

use Test::More;
use URI::VersionRange;

my @in_range     = ('v2.11', 'v2.99', 'v3.00');
my @not_in_range = ('v0.01', 'v0.99', 'v2.10');

subtest "VERS: encode/decode" => sub {

    my $vers = 'vers:cpan/>v1.00|!=v2.10|<=v3.00';

    my $v1 = URI::VersionRange->from_string($vers);

    my $v2 = URI::VersionRange->new(
        scheme      => 'cpan',
        constraints => [
            URI::VersionRange::Constraint->new(comparator => '>',  version => 'v1.00'),
            URI::VersionRange::Constraint->new(comparator => '!=', version => 'v2.10'),
            URI::VersionRange::Constraint->new(comparator => '<=', version => 'v3.00')
        ]
    );

    my $v3 = URI::VersionRange->new(scheme => 'cpan', constraints => ['>v1.00', '!=v2.10', '<=v3.00']);

    my $v4 = decode_vers($vers);

    my $v5 = decode_vers(encode_vers(scheme => 'cpan', constraints => ['>v1.00', '!=v2.10', '<=v3.00']));

    my %tests = (
        'from_string'               => $v1,
        'object-oriented #1'        => $v2,
        'object-oriented #2'        => $v3,
        'decode_vers'               => $v4,
        'encode_vers + decode_vers' => $v5,
    );

    foreach (sort keys %tests) {
        is $v1, $tests{$_}, "Version range ($_)";
    }

    eval { decode_vers('foo:bar<baz') };
    like "$@", qr/Malformed/, 'foo:bar<baz: invalid VERS';

};

subtest "VERS: contains" => sub {

    my $vers = 'vers:cpan/>v1.00|!=v2.10|<=v3.00';
    my $v    = URI::VersionRange->from_string($vers);

    is $v->contains($_), !!1, "$_ version in range ($v)"     for (sort @in_range);
    is $v->contains($_), !!0, "$_ version not in range ($v)" for (sort @not_in_range);

    is decode_vers('vers:cpan/<v13.37')->contains($_), !!1, "$_ version in range" for (sort @in_range);

};

subtest "VERS: Generic schemes" => sub {

    #<<<
    my @valid = (
        'vers:all/*',
        'vers:generic/*',
        'vers:intdot/*',
        'vers:semver/*',
        'vers:lexicographic/*',
        'vers:datetime/*'
    );
    #>>>

    my @invalid = ('vers:none/1.00', 'vers:all/1.00');

    for my $vers (@valid) {
        is decode_vers($vers)->contains($_), !!1, "$vers: $_ version in range" for (sort @in_range);
    }

    is decode_vers('vers:none/*')->contains($_), !!0, "vers:none/*: $_ version not in range" for (sort @in_range);

    for my $vers (@invalid) {
        eval { decode_vers($vers) };
        like "$@", qr/Malformed/, "$vers: invalid VERS";
    }

};

subtest "VERS: is_vers" => sub {

    my @tests = (
        {vers => 'vers:cpan/1.0',    expected => 1},
        {vers => 'vers:foo-bar/1.0', expected => 1},
        {vers => 'vers:foo.bar/1.0', expected => 1},
        {vers => 'vers:a\\b/1.0',    expected => 0},
        {vers => 'vers:a+b/1.0',     expected => 0},
        {vers => 'vers:-a/1.0',      expected => 0},
    );

    foreach my $test (@tests) {
        is(!!URI::VersionRange::is_vers($test->{vers}), !!$test->{expected}, "is_vers: $test->{vers}");
    }

};

subtest "VERS: version \"0\" and empty version" => sub {

    is(decode_vers('vers:generic/>=0|<1'), 'vers:generic/>=0|<1', 'version "0" (with comparator)');
    is(decode_vers('vers:generic/0'),      'vers:generic/0',      'version "0"');

    eval { decode_vers('vers:npm/>=') };
    like("$@", qr/empty version/, 'empty version');

};

subtest "VERS: tainted input" => sub {

    # %ENV is tainted under -T
    my $tainted = substr($ENV{PATH} // '', 0, 0) . 'cpan';
    my $vers    = eval { decode_vers("vers:$tainted/>1.0|<2.0") };

    is($@, '', "from_string: tainted input ($tainted)");
    ok($vers && $vers->contains('1.5'), "contains: tainted input ($tainted)");

};

done_testing();
