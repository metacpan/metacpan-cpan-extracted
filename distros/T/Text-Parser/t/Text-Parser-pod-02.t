use strict;
use warnings;

package Text::Parser::CSV;
use parent 'Text::Parser';

sub save_record {
    my ( $self, $line ) = @_;
    chomp $line;
    my (@fields) = split /,/, $line;
    $self->SUPER::save_record( \@fields );
}

package main;
use Test::More;
use Test::Output;
use Test::Exception;

my $csvp = Text::Parser::CSV->new();
lives_ok {
    $csvp->read('t/dummy-data.csv');
    is_deeply(
        [ $csvp->get_records() ],
        [   [qw(NAME DAY_OF_BIRTH MONTH_OF_BIRTH YEAR_OF_BIRTH)],
            [qw(Balaji 5 9 1981)],
            [qw(Elizabeth 16 2 1984)],
            [qw(Narayanan 19 5 1986)],
            [qw(Hemalatha 2 5 1956)],
            [qw(Ramasubramanian 5 2 1951)],
        ],
        'Got the records as expected'
    );
}
'No issues in reading the CSV file';

done_testing();
