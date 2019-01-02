use strict;
use warnings;

package Text::Parser::CSV;
use parent 'Text::Parser';
use Exception::Class ( 'Text::Parser::CSV::Error',
    'Text::Parser::CSV::TooManyFields' =>
        { isa => 'Text::Parser::CSV::Error', }, );

sub save_record {
    my ( $self, $line ) = @_;
    chomp $line;
    my (@fields) = split /,/, $line;
    $self->{__csv_header} = \@fields if not scalar( $self->get_records );
    Text::Parser::CSV::TooManyFields->throw(
        error => "Too many fields on line #" . $self->lines_parsed )
        if scalar(@fields) > scalar( @{ $self->{__csv_header} } );
    $self->SUPER::save_record( \@fields );
}

package main;
use Test::More;
use Test::Output;
use Test::Exception;
use Try::Tiny;

sub test_read_dirty_csv {
    my $csvp = shift;
    try {
        $csvp->read('t/dirty-data.csv');
    } catch {
        isa_ok( $_, 'Text::Parser::CSV::TooManyFields',
            'Correct error type' );
        $_->rethrow() if not $_->isa('Text::Parser::CSV::TooManyFields');
        print STDERR $_->error, "\n";
    };
}

my $csvp = Text::Parser::CSV->new();
lives_ok {
    stderr_is {
        test_read_dirty_csv($csvp);
    }
    "Too many fields on line #4\n", 'Displays correct error message';
}
'Exception caught properly ; no other exceptions';

done_testing();
