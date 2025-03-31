package Type::Guess;

# ABSTRACT: Guess data types

use strict;
use warnings;

use Mojo::Base -base;
use Mojo::Util qw/dumper/;
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

# these two are set initially based
has length_ro  => 0;
has integer_chars_ro  => 0;
has precision_ro  => 0;

has percentages  => 0;
has signed  => 0;


around "new" => sub {
    my $orig = shift;
    my $ret;

    if ((ref $_[1] eq "HASH") || (scalar @_ == 1)) {
	$ret = $orig->(@_);
    } else {
	my $class = ref $_[0] ? ref shift : shift;
	local @_ = $class->skip_empty ? @_ : grep { /^.$/ } @_;
	return $orig->($class, $class->analyse(@_)->as_hash)
    }
};

sub analyse {
    my $class = ref $_[0] ? ref shift : shift;
    my $ret;

    $ret->{type}      = $class->_type(@_);

    $ret->{precision} = $class->_precision(@_);
    $ret->{precision_ro} = $ret->{precision};

    $ret->{length}    = $class->_length(@_);
    $ret->{length_ro} = $ret->{length};

    $ret->{integer_chars}  = $class->_integer_chars(@_);
    $ret->{integer_chars_ro} = $ret->{integer_chars};

    $ret->{percentages}  = $class->_percentages(@_);
    $ret->{signed}  = $class->_signed(@_);

    return $class->new($ret);
}

sub as_hash {
    my $self = shift;
    my $ret = {};
    $\ = "\n";
    for (keys $self->%*) {
	$ret->{$_} = $self->$_
    }
    return $ret;
}

around "length_ro"        => sub { warn "length_ro is read-only" if defined $_[2]; return $_[0]->($_[1]) };
around "precision_ro"     => sub { warn "precision_ro is read-only" if defined $_[2]; return $_[0]->($_[1]) };
around "integer_chars_ro" => sub { warn "integer_chars_ro is read-only" if defined $_[2]; return $_[0]->($_[1]) };

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

around "type" => sub {
    my $orig = shift;
    my $self = shift;
    if (defined $_[0] && $_[0] eq "Str") {
	my $ret = $orig->($self, @_);
	$self->length($self->length_ro);
	return $ret;
    }
    return $orig->($self, @_);
};

around "length" => sub {
    my $orig = shift;
    my $self = shift;
    $\ = "\n";
    return $orig->($self, @_) unless $self->type =~ /^(Int|Num)$/;
    if ($self->type eq "Num") {
	if (defined $_[0]) {
	    my $int_chars = $_[0] - ($self->precision + ($self->percentages ? 1 : 0) + 1);
	    if ($int_chars > $self->integer_chars_ro) { $self->integer_chars($int_chars) } else { warn "Length value is too low - cannot chop" }
	}
	return $self->integer_chars + $self->precision + ($self->percentages ? 1 : 0) + 1
    }
    elsif ($self->type eq "Int") {
	if (defined $_[0]) {
	    my $int_chars = $_[0] - ($self->precision + ($self->percentages ? 1 : 0));
	    if ($int_chars > $self->integer_chars_ro) { $self->integer_chars($int_chars) } else { warn "Length value is too low - cannot chop" }
	}
	return $self->integer_chars + $self->precision + ($self->percentages ? 1 : 0)
    }
    else {
	print $self->type;
	print "here";
	print scalar @_;
	print join " ", map { qq("$_") } @_;
	if (!@_) {
	    print "nothing";
	    return $orig->($self)
	} elsif (defined $_[0]) {
	    print "defined";
	    return $orig->($self, @_);
	} else {
	    print "undef";
	    $orig->($self, $self->length_ro)
	}
    }
};


our $opts = { tolerance => 0, skip_empty => 1, encoding => "" };
our $skip_empty = 1;

sub class_opts {
    my ($class, $opt, $val) = @_;
    die sprintf "Invalid option %s\n" unless exists $opts->{$opt};
    $opts->{$opt} = $val if defined $val;
    return $opts->{$opt}
}

sub tolerance  { return shift()->class_opts("tolerance", shift()) }
sub skip_empty { return shift()->class_opts("skip_empty", shift()) }

sub _enough($&@) {
    my $class = shift;
    my $sub = shift;
    my @input = @_;
    my $tolerance = $class->tolerance;
    my $enough = scalar @input * (1 - $tolerance);
    return (scalar grep { $sub->($_) } @input) >= $enough
}

sub _type {
    no warnings;
    my $class = shift();
    my @vals = @_;
    @vals = map { s/^\+//; s/^-//; s/%$//; $_ } @vals;
    return "Int" if $class->_enough(sub { looks_like_number($_) && $_ == int($_) }, @vals);
    return "Num" if $class->_enough(sub{ looks_like_number($_) }, @vals);
    return "Str"
}

sub _precision {
    no warnings;
    my $class = shift();
    return List::Util::max map { /^\d*\.\d*$/ ? length($_=~ s/\d*\.//r) : 0 } map { local $_ = $_ ; s/^\+//; s/^-//; s/%$//; $_ } @_;
}

sub _integer_chars {
    no warnings;
    my $class = shift();
    return List::Util::max map { /([\+\-]*\d+)\.*\d*/ ? length($1) : 0 } @_;
}

sub _signed {
    my $class = shift();
    no warnings;
    return "+-" if (List::Util::any { /^([\-])/ } @_) && (List::Util::any { /^([\+])/ } @_);
    return "-" if (List::Util::any { /^([\-])/ } @_);
    return undef;
}


sub _length {
    my $class = shift();
    no warnings;
    return List::Util::max map { length($_) } @_;
}

sub _percentages {
    no warnings;
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

1


#     -sub sql {
# -    my $self = shift;
# -    if ($self->type eq "Int") {
# -       return "integer"
# -    }
# -    elsif ($self->type eq "Num") {
# -       return "float"
# -    }
# -    elsif ($self->type eq "Str" && $self->length <= 512) {
# -       return sprintf "varchar(%i)", $self->length;
# -    }
# -    else {
# -       return "text"
# -    }
# -}
# -
