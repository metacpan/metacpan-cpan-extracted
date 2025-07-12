#!perl -T

use strict;
use warnings;

use Test::More;

use URI::PackageURL;

my $t1 = 'pkg:cpan/GDT/URI-PackageURL@2.23';
my $t2 = 'pkg:deb/debian/curl@7.50.3-1?arch=i386&distro=jessie';
my $t3 = 'pkg:golang/google.golang.org/genproto@abcdedf#googleapis/api/annotations';
my $t4 = 'pkg:docker/customer/dockerimage@sha256:244fd47e07d1004f0aed9c?repository_url=gcr.io';
my $t5 = 'pkg:generic/ns/n@m#?@version?qualifier=#v@lue#subp@th?';
my $t6 = 'pkg:/generic/test?checksum=sha1:ad9503c3e994a4f,sha256:41bf9088b3a1e6c1ef1d';
my $t7 = 'pkg:pypi/django?vers=vers:pypi%2F%3E%3D1.11.0%7C%21%3D1.11.1%7C%3C2.0.0';

subtest "Decode '$t1'" => sub {

    my $purl = decode_purl($t1);

    is($purl->type,      'cpan',           'Type');
    is($purl->namespace, 'GDT',            'Namespace');
    is($purl->name,      'URI-PackageURL', 'Name');
    is($purl->version,   '2.23',           'Version');

    is($purl->to_string, $t1, 'PackageURL');

};

subtest "Decode '$t2'" => sub {

    my $purl = decode_purl($t2);

    is($purl->type,                 'deb',      'Type');
    is($purl->namespace,            'debian',   'Namespace');
    is($purl->name,                 'curl',     'Name');
    is($purl->version,              '7.50.3-1', 'Version');
    is($purl->qualifiers->{arch},   'i386',     'Qualifier "arch"');
    is($purl->qualifiers->{distro}, 'jessie',   'Qualifier "distro"');

    is($purl->to_string, $t2, 'PackageURL');


};

subtest "Decode '$t3'" => sub {

    my $purl = decode_purl($t3);

    is($purl->type,      'golang',                     'Type');
    is($purl->namespace, 'google.golang.org',          'Namespace');
    is($purl->name,      'genproto',                   'Name');
    is($purl->version,   'abcdedf',                    'Version');
    is($purl->subpath,   'googleapis/api/annotations', 'Subpath');

    is($purl->to_string, $t3, 'PackageURL');

};

subtest "Decode '$t4'" => sub {

    my $purl = decode_purl($t4);

    is($purl->type,                         'docker',                        'Type');
    is($purl->namespace,                    'customer',                      'Namespace');
    is($purl->name,                         'dockerimage',                   'Name');
    is($purl->version,                      'sha256:244fd47e07d1004f0aed9c', 'Version');
    is($purl->qualifiers->{repository_url}, 'gcr.io',                        'Qualifier "repository_url"');

    is($purl->to_string, $t4, 'PackageURL');

};

subtest "Decode '$t5'" => sub {

    my $purl = decode_purl($t5);

    is($purl->type,                    'generic',  'Type');
    is($purl->namespace,               'ns',       'Namespace');
    is($purl->name,                    'n@m#?',    'Name');
    is($purl->version,                 'version',  'Version');
    is($purl->qualifiers->{qualifier}, '#v@lue',   'Qualifier "qualifier"');
    is($purl->subpath,                 'subp@th?', 'Subpath');

};

subtest "Decode '$t6'" => sub {

    my $purl = decode_purl($t6);

    is($purl->type, 'generic', 'Type');
    is($purl->name, 'test',    'Name');
    isa_ok($purl->qualifiers->{checksum}, 'ARRAY', 'Qualifier "checksum" as ARRAY');

};

done_testing();
