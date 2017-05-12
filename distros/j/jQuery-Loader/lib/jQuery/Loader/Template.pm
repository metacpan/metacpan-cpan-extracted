package jQuery::Loader::Template;

use strict;
use warnings;

use Moose;

has version => qw/is rw/;
has filter => qw/is rw/;

sub process {
    my $self = shift;
    my $template = shift;
    my %override = @_;

    my $result = $template;

    $result =~ s/\%j/jquery%-v%.f.js/g;

    my $version = $self->version;
    $version = $override{version} if exists $override{version};
    $version ||= "";

    $result =~ s/\%v/$version/g;
    $result =~ s/\%\.v/$version ? "\.$version" : ""/ge;
    $result =~ s/\%\-v/$version ? "\-$version" : ""/ge;
    $result =~ s/\%\/v/$version ? "\/$version" : ""/ge;

    my $filter = $self->filter;
    $filter = $override{filter} if exists $override{filter};
    $filter ||= "";

    $result =~ s/\%f/$filter/g;
    $result =~ s/\%\.f/$filter ? "\.$filter" : ""/ge;
    $result =~ s/\%\-f/$filter ? "\-$filter" : ""/ge;
    $result =~ s/\%\/f/$filter ? "\/$filter" : ""/ge;

    $result =~ s/\%\%/\%/g;

    return $result;
}

1;

__END__

sub process {
    my $self = shift;
    if (@_) {
        my $pattern = shift;

        my $result = $self->_calculate($pattern, @_);
        my $value = $self->value;
        $result =~ s/\%jq/$value/g;

        return $result;
    }

    if ($self->{from_pattern}) {

        my $result = $self->_calculate($self->pattern);

        return $self->{value} = $result;
    }

    return $self->{value};
}

around value => sub {
    my $inner = shift;
    my $self = shift;
    return $self->$inner() unless @_;
    $self->$inner(@_);
    $self->from_pattern(0);
    return $self->{value};
};

around $_ => sub {
    my $inner = shift;
    my $self = shift;
    return $self->$inner() unless @_;
    $self->$inner(@_);
    return $self->{value};
}
for qw/version filter pattern/;

after from_pattern => sub {
    my $self = shift;
    $self->calculate;
};

__END__

has value => qw/is rw/;
has pattern => qw/is rw required 1/, default => "jquery%-v%.f.js";
has version => qw/is rw/;
has filter => qw/is rw/;
has from_pattern => qw/is rw required 1 default 1/;

sub BUILD {
    my $self = shift;
    my $given = shift;

    $self->from_pattern($given->{value} ? 0 : 1); # Will do the calculation as well
}

sub _calculate {
    my $self = shift;
    my $pattern = shift;
    my %override = @_;

    my $result = $pattern;

    my $version = $self->version;
    $version = $override{version} if exists $override{version};
    $version ||= "";

    $result =~ s/\%v/$version/g;
    $result =~ s/\%\.v/$version ? "\.$version" : ""/ge;
    $result =~ s/\%\-v/$version ? "\-$version" : ""/ge;
    $result =~ s/\%\/v/$version ? "\/$version" : ""/ge;

    my $filter = $self->filter;
    $filter = $override{filter} if exists $override{filter};
    $filter ||= "";

    $result =~ s/\%f/$filter/g;
    $result =~ s/\%\.f/$filter ? "\.$filter" : ""/ge;
    $result =~ s/\%\-f/$filter ? "\-$filter" : ""/ge;
    $result =~ s/\%\/f/$filter ? "\/$filter" : ""/ge;

    $result =~ s/\%\%/\%/g;

    return $result;
}

sub calculate {
    my $self = shift;
    if (@_) {
        my $pattern = shift;

        my $result = $self->_calculate($pattern, @_);
        my $value = $self->value;
        $result =~ s/\%jq/$value/g;

        return $result;
    }

    if ($self->{from_pattern}) {

        my $result = $self->_calculate($self->pattern);

        return $self->{value} = $result;
    }

    return $self->{value};
}

around value => sub {
    my $inner = shift;
    my $self = shift;
    return $self->$inner() unless @_;
    $self->$inner(@_);
    $self->from_pattern(0);
    return $self->{value};
};

around $_ => sub {
    my $inner = shift;
    my $self = shift;
    return $self->$inner() unless @_;
    $self->$inner(@_);
    $self->from_pattern(1);
    return $self->{value};
}
for qw/version filter pattern/;

after from_pattern => sub {
    my $self = shift;
    $self->calculate;
};

1;
