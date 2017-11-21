package Test::MasterData::Declare::CompareRow;
use 5.010001;
use strict;
use warnings;
use utf8;

use parent "Test2::Compare::Hash";
use Test2::Util::HashBase qw/json_checks/;

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
    return 1;
}

sub add_json_field {
    my $self = shift;
    my ($name, @path) = @_;
    my $check = pop @path;

    croak "column name is required"
        unless defined $name;

    $self->{+JSON_CHECKS} ||= [];
    push @{$self->{+JSON_CHECKS}} => [$name, \@path, $check];
}

sub _wrap_check {
    my ($class, $got, $check) = @_;

    my $ccheck = $check->clone;
    $ccheck->set_file($got->file);
    $ccheck->set_lines([$got->lineno]);

    return $ccheck;
}

sub deltas {
    my $self = shift;

    my %params = @_;
    my ($got, $convert, $seen) = @params{qw/got convert seen/};
    my $row = $got->row;
    $params{got} = $row;
    my $wrap_convert = sub {
        my $check = $convert->(@_);
        return $self->_wrap_check($got, $check);
    };
    $params{convert} = $wrap_convert;

    my @deltas = $self->SUPER::deltas(%params);

    my $json_checks = $self->{+JSON_CHECKS};
    for my $json_check (@$json_checks) {
        my ($json_column, $path, $check) = @$json_check;
        my $converted_check = $wrap_convert->($check);

        my $out = $got->json($json_column, @$path);
        push @deltas => $converted_check->run(
            id      => ["" => join ".", $json_column, @$path],
            convert => $wrap_convert,
            seen    => $seen,
            got     => $out,
            exists  => defined $out ? 1 : 0,
        );
    }

    return @deltas;
}

sub run {
    my $self = shift;
    my %params = @_;
    my $got = $params{got};

    my $delta = $self->SUPER::run(@_);
    return unless $delta;

    if ($got && blessed $got && $got->isa("Test::MasterData::Declare::Row")) {
        $delta->set_id(["HASH" => $got->source]);
    }
    return $delta;
}

1;
