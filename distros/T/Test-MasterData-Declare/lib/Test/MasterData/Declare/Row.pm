package Test::MasterData::Declare::Row;
use 5.010001;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw/_cached_compare_row/],
    ro  => [qw/table_name _row identifier_key lineno file/],
);

use Test2::Compare::Number qw/number/;
use Test2::Compare::String;
use Carp qw/croak/;
use JSON;

my $json = JSON->new->utf8;

sub row {
    my $self = shift;

    my $cached_compare_row = $self->_cached_compare_row;
    return $cached_compare_row if $cached_compare_row;

    my %compare_row;
    for my $key (keys %{$self->_row}) {
        $compare_row{$key} = $self->_row->{$key};
    }

    $self->_cached_compare_row(\%compare_row);
    return \%compare_row;
}

sub source {
    my ($self, $column) = @_;

    return sprintf(
        "%s#%s=%s",
        $self->file,
        $self->identifier_key, $self->row->{$self->identifier_key},
    );
}

sub json {
    my ($self, $column, @keys) = @_;
    my $json_data = $self->row->{$column};
    my $data = $json->decode($json_data);

    my $out = $data;
    for my $key (@keys) {
        if (ref $out eq "HASH") {
            $out = $out->{$key};
        }
        elsif (ref $out eq "ARRAY" && number($key)) {
            $out = $out->[$key];
        }
        else {
            return undef;
        }
    }

    return $out;
}

1;
