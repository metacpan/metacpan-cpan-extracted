package Text::Levenshtein::TestUtils;

use strict;
use warnings;

# This line is needed before we use Test::More, to suppress warnings
# about "Wide character in print" from Test::Builder
use open ':std', ':encoding(utf8)';

use Test::More 0.88;
use Text::Levenshtein qw/ distance fastdistance /;
use parent 'Exporter';
use Carp;

our @EXPORT_OK = qw/ run_data_tests /;

sub run_data_tests
{
    my $opt = {};
    my $package = (caller(0))[0];
    my $distance;
    my $fh;
    my @extra;

    @extra = @_;

    $fh = do {
        no strict 'refs';
        \*{"${package}::DATA"};
    };

    my @tests = parse_tests($fh);

    plan tests => 4 * @tests;

    foreach my $test (@tests) {
        $distance = distance($test->{word1}, $test->{word2}, @extra);
        ok($distance == $test->{distance},
           "$test->{title} (distance)");

        $distance = distance($test->{word2}, $test->{word1}, @extra);
        ok($distance == $test->{distance},
           "$test->{title} (reverse distance)");

        $distance = fastdistance($test->{word1}, $test->{word2}, @extra);
        ok($distance == $test->{distance},
           "$test->{title} (fastdistance)");

        $distance = fastdistance($test->{word2}, $test->{word1}, @extra);
        ok($distance == $test->{distance},
           "$test->{title} (reverse fastdistance)");
    }

}

sub parse_tests
{
    my $fh = shift;
    my @tests;
    my @fields;
    local $_;

    while (<$fh>) {
        next if /^--/;  # test case divider
        next if /^#/;   # comment
        chomp;
        push(@fields, $_);
        if (@fields == 3) {
            my ($word1, $word2, $expected_distance) = @fields;
            push(@tests, { title    => "$word1 vs $word2",
                           word1    => $word1,
                           word2    => $word2,
                           distance => $expected_distance,
                         });
            @fields = ();
        }
    }
    return @tests;
}

1;
