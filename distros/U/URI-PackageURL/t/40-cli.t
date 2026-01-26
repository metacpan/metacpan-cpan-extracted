#!perl -T

use strict;
use warnings;

use Test::More;
use JSON::PP qw(decode_json);

use URI::PackageURL::App;
use URI::VersionRange::App;

sub cmd {

    my ($class, @arguments) = @_;

    my $output;

    open(my $output_handle, '>', \$output) or die "Can't open handle file: $!";
    my $original_handle = select $output_handle;

    $class->run(@arguments);
    chomp $output;

    select $original_handle;

    return $output;

}

my $t1 = 'pkg:cpan/GDT/URI-PackageURL@2.23';
my $t2 = 'vers:cpan/1.00|>=2.00|<5.00';

subtest "URI::PackageURL::App - '$t1' (JSON output)" => sub {

    my $test_1 = cmd('URI::PackageURL::App', $t1, '--json');
    ok($test_1, 'Parse PURL string to JSON');

    my $test_2 = eval { decode_json($test_1) };

    ok($test_2, 'Valid JSON output');
    is($test_2->{type},      'cpan',           'JSON output: Type');
    is($test_2->{namespace}, 'GDT',            'JSON output: Namespace');
    is($test_2->{name},      'URI-PackageURL', 'JSON output: Name');
    is($test_2->{version},   '2.23',           'JSON output: Version');

};

subtest "URI::VersionRange::App - '$t2' (JSON output)" => sub {

    my $test_1 = cmd('URI::VersionRange::App', $t2, '--json');
    ok($test_1, 'Parse Version Range string to JSON');

    my $test_2 = eval { decode_json($test_1) };

    ok($test_2, 'Valid JSON output');
    is($test_2->{scheme}, 'cpan', 'JSON output: Scheme');

};


#<<<
my @valid = (
    'pkg:cpan/GDT/URI-PackageURL@2.23',
    'pkg:deb/debian/curl@7.50.3-1?arch=i386&distro=jessie',
    'pkg:golang/google.golang.org/genproto@abcdedf#googleapis/api/annotations',
    'pkg:docker/customer/dockerimage@sha256:244fd47e07d1004f0aed9c?repository_url=gcr.io',
    'pkg:generic/ns/n@m#?@version?qualifier=#v@lue#subp@th?',
    'pkg:/generic/test?checksum=sha1:ad9503c3e994a4f,sha256:41bf9088b3a1e6c1ef1d',
    'pkg:pypi/django?vers=vers:pypi%2F%3E%3D1.11.0%7C%21%3D1.11.1%7C%3C2.0.0',
);

my @invalid = (
    'EnterpriseLibrary.Common@6.0.1304',
    'pkg:EnterpriseLibrary.Common@6.0.1304',
    'pkg:n&g?inx/nginx@0.8.9',
    'pkg:maven/@1.3.4',
    'pkg:npm/myartifact@1.0.0?in%20production=true',
    'pkg:hackage',
    'pkg%3Amaven/org.apache.commons/io',
);
#>>>

foreach (@valid) {
    my $res = URI::PackageURL::App->run($_, '--validate', '--quiet');
    ok(!$res, "Valid PURL: purl-tool --validate -q $_");
}

foreach (@invalid) {
    my $res = URI::PackageURL::App->run($_, '--validate', '--quiet');
    ok($res, "Invalid PURL: purl-tool --validate -q $_");
}

{
    my @args = ('--type', 'cpan', '--namespace', 'GDT', '--name', 'URI-PackageURL', '--version', '2.23');
    my $res  = cmd('URI::PackageURL::App', @args);
    is $res, $t1, 'Build PURL string: purl-tool ' . join(' ', @args);
}

done_testing();
