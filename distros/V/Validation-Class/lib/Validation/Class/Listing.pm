# ABSTRACT: Generic Container Class for an Array Reference

package Validation::Class::Listing;

use strict;
use warnings;

use Validation::Class::Util '!has', '!hold';
use List::MoreUtils 'uniq';

our $VERSION = '7.900057'; # VERSION



sub new {

    my $class = shift;

    $class = ref $class if ref $class;

    my $arguments = isa_arrayref($_[0]) ? $_[0] : [@_];

    my $self = bless [], $class;

    $self->add($arguments);

    return $self;

}


sub add {

    my $self = shift;

    my $arguments = isa_arrayref($_[0]) ? $_[0] : [@_];

    push @{$self}, @{$arguments};

    return $self;

}


sub clear {

    my ($self) = @_;

    foreach my $pair ($self->pairs) {
        $self->delete($pair->{index});
    }

    return $self->new;

}


sub count {

    my ($self) = @_;

    return scalar($self->list);

}


sub delete {

    my ($self, $index) = @_;

    return delete $self->[$index];

}


sub defined {

    my ($self, $index) = @_;

    return defined $self->[$index];

}


sub each {

    my ($self, $code) = @_;

    $code ||= sub {};

    my $i=0;

    foreach my $value ($self->list) {

        $code->($i, $value); $i++;

    }

    return $self;

}


sub first {

    my ($self) = @_;

    return $self->[0];

}


sub get {

    my ($self, $index) = @_;

    return $self->[$index];

}


sub grep {

    my ($self, $pattern) = @_;

    $pattern = qr/$pattern/ unless "REGEXP" eq uc ref $pattern;

    return $self->new(grep { $_ =~ $pattern } ($self->list));

}


sub has {

    my ($self, $index) = @_;

    return $self->defined($index) ? 1 : 0;

}


sub iterator {

    my ($self, $function, @arguments) = @_;

    $function = 'list'
        unless grep { $function eq $_ } ('sort', 'rsort', 'nsort', 'rnsort');

    my @keys = ($self->$function(@arguments));

    @keys = $keys[0]->list if $keys[0] eq ref $self;

    my $i = 0;

    return sub {

        return unless defined $keys[$i];

        return $keys[$i++];

    }

}


sub join {

    my ($self, $delimiter) = @_;

    return join($delimiter, ($self->list));

}


sub last {

    my ($self) = @_;

    return $self->[-1];

}


sub list {

    my ($self) = @_;

    return (@{$self});

}


sub nsort {

    my ($self) = @_;

    my $code = sub { $_[0] <=> $_[1] };

    return $self->sort($code);

}


sub pairs {

    my ($self, $function, @arguments) = @_;

    $function ||= 'list';

    my @values = ($self->$function(@arguments));

    return () unless @values;

    @values = $values[0]->list if ref $values[0] && ref $values[0] eq ref $self;

    my $i=0;

    my @pairs = map {{ index => $i++, value => $_ }} (@values);

    return (@pairs);

}


sub rnsort {

    my ($self) = @_;

    my $code = sub { $_[1] <=> $_[0] };

    return $self->sort($code);

}


sub rsort {

    my ($self) = @_;

    my $code = sub { $_[1] cmp $_[0] };

    return $self->sort($code);

}


sub sort {

    my ($self, $code) = @_;

    return "CODE" eq ref $code ?
        sort { $a->$code($b) } ($self->keys) : sort { $a cmp $b } ($self->list);

}


sub unique {

    my ($self) = @_;

    return uniq ($self->list);

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Listing - Generic Container Class for an Array Reference

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Listing;

    my $foos = Validation::Class::Listing->new;

    $foos->add('foo');
    $foos->add('bar', 'baz');

    print $foos->count; # 3 objects

=head1 DESCRIPTION

Validation::Class::Listing is a container class that provides general-purpose
functionality for arrayref objects.

=head1 METHODS

=head2 new

    my $self = Validation::Class::Listing->new;

=head2 add

    $self = $self->add('foo', 'bar');

=head2 clear

    $self = $self->clear;

=head2 count

    my $count = $self->count;

=head2 delete

    $value = $self->delete($index);

=head2 defined

    $true if $self->defined($name) # defined

=head2 each

    $self = $self->each(sub{

        my ($index, $value) = @_;

    });

=head2 first

    my $value = $self->first;

=head2 get

    my $value = $self->get($index); # i.e. $self->[$index]

=head2 grep

    $new_list = $self->grep(qr/update_/);

=head2 has

    $true if $self->has($name) # defined

=head2 iterator

    my $next = $self->iterator();

    # defaults to iterating by keys but accepts sort, rsort, nsort, or rnsort
    # e.g. $self->iterator('sort', sub{ (shift) cmp (shift) });

    while (my $item = $next->()) {
        # do something with $item
    }

=head2 join

    my $string = $self->join($delimiter);

=head2 last

    my $value = $self->last;

=head2 list

    my @list = $self->list;

=head2 nsort

    my @list = $self->nsort;

=head2 pairs

    my @pairs = $self->pairs;
    # or filter using $self->pairs('grep', $regexp);

    foreach my $pair (@pairs) {
        # $pair->{index} is $pair->{value};
    }

=head2 rnsort

    my @list = $self->rnsort;

=head2 rsort

    my @list = $self->rsort;

=head2 sort

    my @list = $self->sort(sub{...});

=head2 unique

    my @list = $self->unique();

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
