package Test::MasterData::Declare::Reader;
use 5.010001;
use strict;
use warnings;
use utf8;

use Text::CSV_PP;
use Carp qw/croak/;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/_rows table_name/],
);

use Test::MasterData::Declare::Row;

sub read_csv_from {
    my ($class, %args) = @_;
    my $filepath      = $args{filepath};
    my $table_name    = $args{table_name};
    my $identifier_key = $args{identifier_key};

    open my $fh, "<:encoding(utf8)", $filepath or croak "cannot open $filepath";
    my $csv = Text::CSV_PP->new({
        binary             => 1,
        blank_is_undef     => 1,
        eol                => "\n",
    }) or croak Text::CSV_PP->error_diag();

    $csv->header($fh);
    my @rows;
    while (my $row = $csv->getline_hr($fh)) {
        my $lineno = $csv->record_number;
        push @rows, Test::MasterData::Declare::Row->new(
            table_name     => $table_name,
            _row           => $row,
            identifier_key => $identifier_key,
            lineno         => $lineno,
            file           => $filepath,
        );
    }

    return $class->new(
        _rows      => \@rows,
        table_name => $table_name,
    );
}

sub rows {
    my $self = shift;

    return $self->_rows;
}

1;
