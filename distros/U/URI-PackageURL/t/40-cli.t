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

my $t1 = 'pkg:cpan/GDT/URI-PackageURL@2.20';
my $t2 = 'vers:cpan/1.00|>=2.00|<5.00';

subtest "URI::PackageURL::App - '$t1' (JSON output)" => sub {

    my $test_1 = cmd('URI::PackageURL::App', $t1, '--json');
    ok($test_1, 'Parse PackageURL string to JSON');

    my $test_2 = eval { decode_json($test_1) };

    ok($test_2, 'Valid JSON output');
    is($test_2->{type},      'cpan',           'JSON output: Type');
    is($test_2->{namespace}, 'GDT',            'JSON output: Namespace');
    is($test_2->{name},      'URI-PackageURL', 'JSON output: Name');
    is($test_2->{version},   '2.20',           'JSON output: Version');

};

subtest "URI::VersionRange::App - '$t2' (JSON output)" => sub {

    my $test_1 = cmd('URI::VersionRange::App', $t2, '--json');
    ok($test_1, 'Parse Version Range string to JSON');

    my $test_2 = eval { decode_json($test_1) };

    ok($test_2, 'Valid JSON output');
    is($test_2->{scheme}, 'cpan', 'JSON output: Scheme');

};

done_testing();
