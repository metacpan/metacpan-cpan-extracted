
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Text::Parser';
}

lives_ok {
    my $parser = Text::Parser->new();
    $parser->add_rule(
        if => '$1 eq "NAME:"',
        do => 'return { name => ${2+} }'
    );
    $parser->add_rule(
        if => '$1 eq "EMAIL:"',
        do => 'my $rec = $this->pop_record; $rec->{email} = $2; return $rec'
    );
    $parser->add_rule(
        if => '$1 eq "ADDRESS:"',
        do =>
            'my $rec = $this->pop_record; $rec->{address} = ${2+}; return $rec'
    );
    $parser->read('t/example-compare_native_perl-1.txt');
    my (@data) = $parser->get_records;
    is( scalar(@data), 4, 'Got 4 records' );
    is_deeply(
        $data[0],
        {   name    => 'Brian',
            email   => 'brian@webhost.net',
            address => '401 Burnswick Ave, Cool City, UT 12345'
        },
        'Brian data matched'
    );
    is_deeply(
        $data[1],
        {   name    => 'Darin Cruz',
            email   => 'darin123@yahoo.co.uk',
            address => '209 Random St, Forest City, CA 92710'
        },
        'Darin data matched'
    );
    is_deeply(
        $data[2],
        {   name    => 'Elizabeth Andrews',
            address => '0 Muutama Lane, Inaccessible Forest area, AK 88170',
        },
        'Elizabeth data matched'
    );
    is_deeply(
        $data[3],
        {   name    => 'Audrey C. Miller',
            email   => 'aud@audrey.io',
            address => '9 New St, Smart City, PA 12933',
        },
        'Audrey data matched'
    );
}
'Works fine!';

done_testing;
