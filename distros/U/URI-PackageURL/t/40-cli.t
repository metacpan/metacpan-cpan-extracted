#!perl -T

use strict;
use warnings;

use Test::More;
use JSON;

use URI::PackageURL::CLI;

sub cmd {

    my (@arguments) = @_;

    my $output;

    open(my $output_handle, '>', \$output) or die "Can't open handle file: $!";
    my $original_handle = select $output_handle;

    URI::PackageURL::CLI->run(@arguments);
    chomp $output;

    select $original_handle;

    return $output;

}

my $t1 = 'pkg:cpan/GDT/URI-PackageURL@2.00';

subtest "CLI '$t1' (JSON output)" => sub {

    my $test_1 = cmd($t1, '--json');

    ok($test_1, 'Parse PackageURL string to JSON');

    my $test_2 = eval { decode_json($test_1) };

    ok($test_2, 'Valid JSON output');

    is($test_2->{type},      'cpan',           'JSON output: Type');
    is($test_2->{namespace}, 'GDT',            'JSON output: Namespace');
    is($test_2->{name},      'URI-PackageURL', 'JSON output: Name');
    is($test_2->{version},   '2.00',           'JSON output: Version');

};

done_testing();

#diag($test_1);
