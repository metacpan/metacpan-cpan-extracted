package Foo;
use strict;
use warnings;

use Mojo::Base -base;
use Mojo::Util qw/dumper/;
use List::Util;
use Class::Method::Modifiers;
use Scalar::Util qw(looks_like_number);
use overload
    '""' =>  \&to_sprintf,
    '&{}' => \&to_sub;

has type      => "string";

has length    => 0;
has precision => 0;

has max       => 0;
has format    => "";
has integers  => 0;
has percentages  => 0;

around "new" => sub {
    my $orig = shift;
    my $ret;

    if ((ref $_[1] eq "HASH") || (scalar @_ == 1)) {
	$ret = $orig->(@_);
    } else {
	my $class = shift;
	$ret->{type}      = _type(@_);
	$ret->{precision} = _precision(@_);
	$ret->{length}    = _length(@_);
	$ret->{integers}  = _integers(@_);
	$ret->{percentages}  = _percentages(@_);
	return $orig->($class, $ret)
    }
};

around "precision" => sub {
    my $orig = shift;
    if (defined $_[1]) {

    }
    return $orig->(@_);
};

sub _type {
    my @vals = @_;
    @vals = map { s/^\+//; s/^-//; s/%$//; $_ } @vals;
    return "int" if List::Util::all { looks_like_number($_) && $_ == int($_) } @vals;
    return "float" if List::Util::all { looks_like_number($_) } @vals;
    return "string"
}

sub _precision {
    my @vals = @_;
    @vals = map { s/^\+//; s/^-//; s/%$//; $_ } @vals;
    return List::Util::max map { /^\d*\.\d*$/ ? length($_=~ s/\d*\.//r) : 0 } @vals;
}

sub _integers {
    return List::Util::max map { /([\+\-]*\d+)\.*\d*/ ? length($1) : 0 } @_;
}

sub _length {
    return List::Util::max map { length($_) } @_;
}

sub _percentages {
    return List::Util::all { /%$/ } @_;
}

sub to_sub {
    my $self = shift;
    my $format = $self->to_string;
    no warnings;
    return sub { return sprintf $format, shift() }
}



sub to_string {
    my $self = shift;
    my $format = $self->format;

    if ($format) {
	return $format;
    } else {
	if ($self->type eq "int") {
	    $format = "%" . $self->length . "i";
	}
	elsif ($self->type eq "float") {
	    $format = '%' . (1 + $self->integers + $self->precision) . "." . $self->precision . "f";
	    $format .= "%%" if $self->percentages;
	}
	else {
	    $format = "%-" . $self->length . "s";
	}
	return $format;
    }
}

sub sql {
    my $self = shift;
    if ($self->type eq "int") {
	return "integer"
    }
    elsif ($self->type eq "float") {
	return "float"
    }
    elsif ($self->type eq "string" && $self->length <= 512) {
	return sprintf "varchar(%i)", $self->length;
    }
    else {
	return "text"
    }
}

1

