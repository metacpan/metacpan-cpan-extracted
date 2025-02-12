package Type::Guess;

# ABSTRACT: Guess data types

use strict;
use warnings;

use Mojo::Base -base;
use List::Util;

use Class::Method::Modifiers;
use Scalar::Util qw(looks_like_number);

use overload
    '""' =>  \&to_string,
    '&{}' => \&to_sub;

has type      => "Str";

has length    => 0;
has precision => 0;

has max       => 0;
has format    => "";
has integer_chars  => 0;
has percentages  => 0;
has signed  => 0;

around "new" => sub {
    my $orig = shift;
    my $ret;

    if ((ref $_[1] eq "HASH") || (scalar @_ == 1)) {
	$ret = $orig->(@_);
    } else {
	my $class = shift;
	local @_ = $class->strictness ? @_ : grep { /^.$/ } @_;

	$ret->{type}      = $class->_type(@_);
	$ret->{precision} = $class->_precision(@_);
	$ret->{length}    = $class->_length(@_);
	$ret->{integer_chars}  = $class->_integer_chars(@_);
	$ret->{percentages}  = $class->_percentages(@_);
	$ret->{signed}  = $class->_signed(@_);
	return $orig->($class, $ret)
    }
};

around "precision" => sub {
    my $orig = shift;
    my $self = shift;
    return 0 unless $self->type =~ /^(Num)$/;
    return $orig->($self, @_);
};

around "signed" => sub {
    my $orig = shift;
    my $self = shift;
    return 0 unless $self->type =~ /^(Int|Num)$/;
    return $orig->($self, @_);
};

around "length" => sub {
    my $orig = shift;
    my $self = shift;
    return $orig->($self, @_) unless $self->type =~ /^(Int|Num)$/;
    if ($self->type eq "Num") {
	return $self->integer_chars + $self->precision + ($self->percentages ? 1 : 0) + 1
    }
    elsif ($self->type eq "Int") {
	return $self->integer_chars + $self->precision + ($self->percentages ? 1 : 0)
    }
};


our $opts = { tolerance => 0, strictness => 1, encoding => "" };
our $strictness = 1;

sub class_opts {
    my ($class, $opt, $val) = @_;
    die sprintf "Invalid option %s\n" unless exists $opts->{$opt};
    $opts->{$opt} = $val if defined $val;
    return $opts->{$opt}
}

sub tolerance  { return shift()->class_opts("tolerance", shift()) }
sub strictness { return shift()->class_opts("strictness", shift()) }

sub _enough($&@) {
    my $class = shift;
    my $sub = shift;
    my @input = @_;
    my $tolerance = $class->tolerance;
    my $enough = scalar @input * (1 - $tolerance);
    return (scalar grep { $sub->($_) } @input) >= $enough
}

sub _type {
    my $class = shift();
    my @vals = @_;
    @vals = map { s/^\+//; s/^-//; s/%$//; $_ } @vals;
    return "Int" if $class->_enough(sub { looks_like_number($_) && $_ == int($_) }, @vals);
    return "Num" if $class->_enough(sub{ looks_like_number($_) }, @vals);
    return "Str"
}

sub _precision {
    my $class = shift();
    return List::Util::max map { /^\d*\.\d*$/ ? length($_=~ s/\d*\.//r) : 0 } map { local $_ = $_ ; s/^\+//; s/^-//; s/%$//; $_ } @_;
}

sub _integer_chars {
    my $class = shift();
    return List::Util::max map { /([\+\-]*\d+)\.*\d*/ ? length($1) : 0 } @_;
}

sub _signed {
    my $class = shift();
    return "+-" if (List::Util::any { /^([\-])/ } @_) && (List::Util::any { /^([\+])/ } @_);
    return "-" if (List::Util::any { /^([\-])/ } @_);
    return undef;
}


sub _length {
    my $class = shift();
    return List::Util::max map { length($_) } @_;
}

sub _percentages {
    my $class = shift();
    return $class->_enough(sub { /%$/ }, @_);
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
	if ($self->type eq "Int") {
	    $format = "%" . $self->length . "i";
	}
	elsif ($self->type eq "Num") {
	    $format = '%' . (1 + $self->integer_chars + $self->precision) . "." . $self->precision . "f";
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
    if ($self->type eq "Int") {
	return "integer"
    }
    elsif ($self->type eq "Num") {
	return "float"
    }
    elsif ($self->type eq "Str" && $self->length <= 512) {
	return sprintf "varchar(%i)", $self->length;
    }
    else {
	return "text"
    }
}

1

