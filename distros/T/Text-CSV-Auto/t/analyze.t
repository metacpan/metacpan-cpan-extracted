use strict;
use warnings;

use Test::More;
use Text::CSV::Auto;

my $expected = [
          {
            integer => 1,
            min => 479,
            max => 2749,
            integer_length => 4,
            header => 'feature_id',
            data_type => 'integer',
          },
          {
            string_length => 18,
            string => 1,
            header => 'feature_name',
            data_type => 'string',
          },
          {
            string_length => 15,
            string => 1,
            header => 'feature_class',
            data_type => 'string',
          },
          {
            integer => 1,
            min => 170,
            max => 12070,
            integer_length => 5,
            header => 'census_code',
            data_type => 'integer',
          },
          {
            string_length => 2,
            string => 1,
            header => 'census_class_code',
            data_type => 'string',
          },
          {
            integer => 1,
            min => 5,
            empty => 1,
            max => 80,
            integer_length => 2,
            header => 'gsa_code',
            data_type => 'integer',
          },
          {
            integer => 1,
            min => 40005013,
            empty => 1,
            max => 40080013,
            integer_length => 8,
            header => 'opm_code',
            data_type => 'integer',
          },
          {
            integer => 1,
            min => 4,
            max => 4,
            integer_length => 1,
            header => 'state_numeric',
            data_type => 'integer',
          },
          {
            string_length => 2,
            string => 1,
            header => 'state_alpha',
            data_type => 'string',
          },
          {
            integer => 1,
            min => 1,
            max => 1,
            integer_length => 1,
            header => 'county_sequence',
            data_type => 'integer',
          },
          {
            integer => 1,
            min => 1,
            max => 25,
            integer_length => 2,
            header => 'county_numeric',
            data_type => 'integer',
          },
          {
            string_length => 8,
            string => 1,
            header => 'county_name',
            data_type => 'string',
          },
          {
            fractional_length => 7,
            min => '31.3514908',
            max => '36.6016535',
            decimal => 1,
            integer_length => 2,
            header => 'primary_latitude',
            data_type => 'decimal',
          },
          {
            fractional_length => 7,
            min => '-114.5682983',
            max => '-109.4870088',
            decimal => 1,
            signed => 1,
            integer_length => 3,
            header => 'primary_longitude',
            data_type => 'decimal',
          },
          {
            mdy_date => 1,
            header => 'date_created',
            data_type => 'mdy_date',
          },
          {
            mdy_date => 1,
            empty => 1,
            header => 'date_edited',
            data_type => 'mdy_date',
          }
        ];

my $auto = Text::CSV::Auto->new( 't/features.csv' );

my $info = $auto->analyze();

is_deeply(
    $info,
    $expected,
    'analyze returned the expected results',
);

done_testing;
