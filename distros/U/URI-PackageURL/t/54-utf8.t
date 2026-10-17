#!perl -T

use strict;
use warnings;
use utf8;

use Test::More;

use URI::PackageURL;
use URI::VersionRange;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);


# PURL

#<<<
my @purl_tests = (
    {purl => 'pkg:generic/caf%C3%A9@1.0',              name => 'café',      expected => 'pkg:generic/caf%C3%A9@1.0'},
    {purl => 'pkg:generic/café@1.0',                   name => 'café',      expected => 'pkg:generic/caf%C3%A9@1.0'},
    {purl => 'pkg:generic/%F0%9F%98%80',               name => "\x{1F600}", expected => 'pkg:generic/%F0%9F%98%80'},
    {purl => 'pkg:generic/ns%C3%BC/foo#d%C3%ADr/file', name => 'foo',       expected => 'pkg:generic/ns%C3%BC/foo#d%C3%ADr/file'},
);
#>>>

foreach my $test (@purl_tests) {

    my $purl = URI::PackageURL->from_string($test->{purl});

    is($purl->name, $test->{name},     "$test->{purl} - name");
    is("$purl",     $test->{expected}, "$test->{purl} - to_string");

}

my $purl = URI::PackageURL->from_string('pkg:generic/ns%C3%BC/foo?note=%E2%82%AC%20price#d%C3%ADr/file');

is($purl->namespace,          'nsü',      'PURL namespace');
is($purl->qualifiers->{note}, '€ price',  'PURL qualifier');
is($purl->subpath,            'dír/file', 'PURL subpath');

is(URI::PackageURL->new(type => 'generic', name => 'café'), 'pkg:generic/caf%C3%A9', 'PURL encode (Latin-1 range)');
is(
    URI::PackageURL->new(type => 'generic', name => "\x{1F600}"),
    'pkg:generic/%F0%9F%98%80',
    'PURL encode (wide character)'
);

eval { URI::PackageURL->from_string('pkg:generic/caf%E9') };
like($@, qr/invalid UTF-8 encoding/, 'PURL invalid UTF-8');


# VERS

my $vers = URI::VersionRange->new(scheme => 'lexicographic', constraints => ['é', "\x{1F600}"]);

is("$vers", 'vers:lexicographic/%C3%A9|%F0%9F%98%80', 'VERS encode');

is_deeply(
    [map { $_->version } @{URI::VersionRange->from_string("$vers")->constraints}],
    ['é', "\x{1F600}"],
    'VERS decode'
);

eval { URI::VersionRange->from_string('vers:lexicographic/%E9') };
like($@, qr/Invalid UTF-8 encoding/, 'VERS invalid UTF-8');

done_testing();
