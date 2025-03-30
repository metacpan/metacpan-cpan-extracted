package autobox::Lookup;

# ABSTRACT: easy data lookup
{ our $VERSION = '0.002'; }

use base qw(autobox);

sub import {
    my $class = shift;

    $autobox::Lookup::Subs::sep = shift() || '.';

    $class->SUPER::import(
			  HASH => 'autobox::Lookup::Subs',
			  ARRAY => 'autobox::Lookup::Subs',
			  SCALAR => 'autobox::Lookup::Subs',
			 );
}

package autobox::Lookup::Subs;

use List::Util qw/reduce/;
use strict;

*_lookup = *_recursive_lookup;

BEGIN {
    eval { require Mojo::Collection };
    if (!$@) {
	Mojo::Collection->import();
	*collection = sub {
	    my $data = shift;
	    if (ref($data) eq 'ARRAY') {
		Mojo::Collection->new($data->@*)
	    }
	    elsif (ref($data) eq 'HASH') {
		Mojo::Collection->new(values $data->%*)
	    }
	};
    } else {
	*collection = sub { die "collection is not implemented unless Mojo::Collection is installed\n" }
    }
}

sub _recursive_lookup {
    my ($data, $key) = @_;

    return \undef unless defined $data && ref($data);
    return \$data unless defined $key;

    my ($first, @rest) = split /\./, $key;

    if ($key =~ /\,/) {
        return do { my $r = [ map { ${_lookup($data, $_)} } split /\,/, $key ]; \$r }
    }
    elsif (ref($data) eq 'ARRAY' && $first =~ /^\d+$/) {
        return @rest ? _lookup($data->[$first], join('.', @rest)) : \($data->[$first]);
    }
    elsif (ref($data) eq 'ARRAY' && $first eq '[]') {
        return @rest ? do { my $t = [ map { ${_lookup($_, join('.', @rest))} } @$data ]; \$t } : \$data;
    }
    elsif (ref($data) eq 'HASH' && $first eq '[]') {
	return @rest  ?
	    do { my $t = [ map { ${_lookup($data->{$_}, join('.', @rest))} } sort keys %$data ]; \$t } :
	    do { my $t = [ map { $data->{$_} } sort keys %$data ]; \$t; };
    }
    elsif (ref($data) eq 'HASH' && exists $data->{$first}) {
        return @rest ? _lookup($data->{$first}, join('.', @rest)) : \($data->{$first});
    }
    return \undef;
}

sub lookup { shift()->get(@_) }

sub get {
    my $h = shift;
    my $k = shift;

    my $l = _lookup($h, $k);

    return $$l
}

sub set {
    my ($h, $k, $v) = @_;

    my $l = _lookup($h, $k);
    $$l = $v;
    return $h
}

sub values {
    if (ref $_[0] eq "HASH") {
	return [ values $_[0]->%* ]
    } 
    elsif (ref $_[0] eq "ARRAY") {
	return $_[0]
    }
}

sub keys {
    if (ref $_[0] eq "HASH") {
	return [ keys $_[0]->%* ]
    } 
    elsif (ref $_[0] eq "ARRAY") {
	return [ 0..$#{$_[0]} ]
    }
}

1;
