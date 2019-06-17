use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Text::Parser';
}

lives_ok {
    my $parser = Text::Parser->new( auto_split => 1, FS => qr/[:,]\s+/ );
    $parser->add_rule( if => '$1 eq "State"', do => 'return {state => $2}' );
    $parser->add_rule(
        if => '$1 eq "County"',
        do => 'my $data = $this->pop_record;
        $data->{$2} = { area => $3, county_seat => $4, date_inc => $5, };
        return $data;'
    );
    $parser->read('t/example-compare_native_perl-2.txt');
    is_deeply(
        [ $parser->get_records ],
        [   {   state         => 'California',
                'Santa Clara' => {
                    area        => 1304,
                    county_seat => 'San Jose',
                    date_inc    => '2/18/1850'
                },
                'Alameda' => {
                    area        => 821,
                    county_seat => 'Oakland',
                    date_inc    => '3/25/1853'
                },
                'San Mateo' => {
                    area        => 774,
                    county_seat => 'Redwood City',
                    date_inc    => '4/19/1856'
                },
            },
            { state => 'Arkansas', }
        ],
        'Everything worked'
    );
}
'This example code worked';

done_testing;
