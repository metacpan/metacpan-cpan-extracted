use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Text::Parser';
}

lives_ok {
    my $table_parser = Text::Parser->new( FS => qr/\s*[|]\s*/ );
    isa_ok( $table_parser, 'Text::Parser' );
    $table_parser->add_rule(
        if          => '$this->NF == 0',
        dont_record => 1
    );
    $table_parser->add_rule(
        if => '$this->lines_parsed == 1',
        do => '~columns = [$this->fields()];'
    );
    $table_parser->add_rule(
        if => '$this->lines_parsed > 1',
        do => 'my %rec = ();
               foreach my $i (0..$#{~columns}) {
               my $k = ~columns->[$i];
               $rec{$k} = $this->field($i);
               }
               return \%rec;',
    );
    $table_parser->read('t/table.txt');
    is_deeply(
        [ $table_parser->get_records() ],
        [   [ 'rec', 'First Name', 'Last Name', 'Phone number' ],
            {   'First Name'   => 'Chidi',
                'Last Name'    => 'Anagonye',
                rec            => 1,
                'Phone number' => '012-345-6789'
            },
            {   'First Name'   => 'Eleanor',
                'Last Name'    => 'Shellstrop',
                rec            => 2,
                'Phone number' => '019-138-2801'
            },
            {   'First Name'   => 'Tahani',
                'Last Name'    => 'Al-Jamil',
                rec            => 3,
                'Phone number' => undef
            },
            {   'First Name'   => 'Jason',
                'Last Name'    => 'Mendoza',
                rec            => 4,
                'Phone number' => '820-891-2930'
            },
        ],
        'All records match'
    );

}
'All of this works fine';

done_testing;
