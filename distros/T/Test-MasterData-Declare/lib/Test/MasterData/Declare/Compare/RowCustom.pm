package Test::MasterData::Declare::Compare::RowCustrom;
use 5.010001;
use strict;
use warnings;
use utf8;

use parent "Test2::Compare::Custom";

use Carp qw/croak/;
use Scalar::Util qw/blessed/;

sub object_base { "Test::MasterData::Declare::Row" }

sub verify {
    my $self = shift;
    my %params = @_;
    my ($got, $exists) = @params{qw/got exists/};

    return 0 unless $exists;
    return 0 unless $got;
    return 0 unless ref($got);
    return 0 unless blessed($got);
    return 0 unless $got->isa($self->object_base);

    $params{got} = $got->row;
    return $self->SUPER::verify(%params);
}


sub run {
    my $self = shift;
    my %params = @_;
    my $got = $params{got};

    $params{got} = $got->row;

    my $delta = $self->SUPER::run(@_);
    return unless $delta;

    my $ccheck = $self->clone;
    $ccheck->set_file($got->file);
    $ccheck->set_lines([$got->lineno]);
    $delta->set_check($ccheck);
    $delta->set_id(["HASH" => $got->source]);
    $delta->set_got($got->row);
    return $delta;
}

1;
