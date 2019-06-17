
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Text::Parser';
}

lives_ok {
    my $parser = Text::Parser->new( FS => qr/\s+\=\s+|,\s+/ );
    $parser->add_rule(
        if => '$1 eq "School"',
        do => '~school = $2; return {$2 => {}};'
    );
    $parser->add_rule(
        if => '$1 eq "Grade"',
        do => 'my $p = $this->pop_record;
        $p->{~school}{$2} = {};
        ~grade = $2;
        return $p;'
    );
    $parser->add_rule(
        if          => '$1 eq "Student number"',
        do          => '~info = $2;',
        dont_record => 1
    );
    $parser->add_rule(
        do => 'my $p = $this->pop_record;
        $p->{~school}{~grade}{$1}{~info} = $2;
        return $p;'
    );
    $parser->read('t/example-compare_native_perl-3.txt');
    is( scalar( $parser->get_records ), 2, 'Two records' );
    is_deeply(
        [ $parser->get_records ],
        [   {   "Riverdale High" => {
                    "1" => {
                        0 => { Name => "Phoebe", Score => 3 },
                        1 => { Name => "Rachel", Score => 7 }
                    },
                    "2" => {
                        0 => { Name => "Angela",  Score => 6 },
                        1 => { Name => "Tristan", Score => 3 },
                        2 => { Name => "Aurora",  Score => 9 },
                    },
                },
            },
            {   "Hogwarts" => {
                    "1" => {
                        0 => { Name => "Ginny", Score => 8 },
                        1 => { Name => "Luna",  Score => 7 },
                    },
                    "2" => {
                        0 => { Name => "Harry",    Score => 5 },
                        1 => { Name => "Hermione", Score => 10 },
                    },
                    "3" => {
                        0 => { Name => "Fred",   Score => 0 },
                        1 => { Name => "George", Score => 0 },
                    },
                },
            },
        ],
        'This is all matching'
    );
}
'No compilation error';

done_testing;
