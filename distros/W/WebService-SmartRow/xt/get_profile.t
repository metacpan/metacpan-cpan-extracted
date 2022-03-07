use Test2::V0;

use WebService::SmartRow;

die 'You need to set SMARTROW_USERNAME' unless $ENV{SMARTROW_USERNAME};
die 'You need to set SMARTROW_PASSWORD' unless $ENV{SMARTROW_PASSWORD};

my $sr = WebService::SmartRow->new;

my $profile = $sr->get_profile;

is $profile,
    {
    'activation_key'     => E,
    'active'             => E,
    'age'                => E,
    'avatar'             => E,
    'clearance'          => E,
    'country'            => E,
    'country_flag'       => E,
    'country_name'       => E,
    'created'            => E,
    'data_permission'    => E,
    'dob'                => E,
    'email'              => E,
    'first_name'         => E,
    'force_curve_max'    => E,
    'gender'             => E,
    'height'             => E,
    'id'                 => E,
    'is_public'          => E,
    'language'           => E,
    'last_login'         => E,
    'last_name'          => E,
    'max_hr'             => E,
    'metric_measurement' => E,
    'mod'                => E,
    'public_id'          => E,
    'reset_key'          => E,
    'strava_connection'  => E,
    'weight'             => E,
    };

done_testing;
