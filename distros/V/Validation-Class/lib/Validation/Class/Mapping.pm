# ABSTRACT: Generic Container Class for a Hash Reference

package Validation::Class::Mapping;

use strict;
use warnings;

use Validation::Class::Util '!has', '!hold';
use Hash::Merge ();

our $VERSION = '7.900057'; # VERSION



sub new {

    my $class = shift;

    $class = ref $class if ref $class;

    my $arguments = $class->build_args(@_);

    my $self = bless {}, $class;

    $self->add($arguments);

    return $self;

}


sub add {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    while (my ($key, $value) = each %{$arguments}) {

        $self->{$key} = $value;

    }

    return $self;

}


sub clear {

    my ($self) = @_;

    $self->delete($_) for keys %{$self};

    return $self;

}


sub count {

    my ($self) = @_;

    return scalar($self->keys);

}


sub delete {

    my ($self, $name) = @_;

    return delete $self->{$name};

}


sub defined {

    my ($self, $index) = @_;

    return defined $self->{$index};

}


sub each {

    my ($self, $code) = @_;

    $code ||= sub {};

    while (my @args = each(%{$self})) {

        $code->(@args);

    }

    return $self;

}


sub exists {

    my ($self, $name) = @_;

    return exists $self->{$name} ? 1 : 0;

}


sub get {

    my ($self, $name) = @_;

    return $self->{$name};

}


sub grep {

    my ($self, $pattern) = @_;

    $pattern = qr/$pattern/ unless "REGEXP" eq uc ref $pattern;

    return $self->new(map {$_=>$self->get($_)}grep{$_=~$pattern}($self->keys));

}


sub has {

    my ($self, $name) = @_;

    return ($self->defined($name) || $self->exists($name)) ? 1 : 0;

}


sub hash {

    my ($self) = @_;

    return {$self->list};

}


sub iterator {

    my ($self, $function, @arguments) = @_;

    $function = 'keys'
        unless grep { $function eq $_ } ('sort', 'rsort', 'nsort', 'rnsort');

    my @keys = ($self->$function(@arguments));

    my $i = 0;

    return sub {

        return unless defined $keys[$i];

        return $self->get($keys[$i++]);

    }

}


sub keys {

    my ($self) = @_;

    return (keys(%{$self->hash}));

}


sub list {

    my ($self) = @_;

    return (%{$self});

}


sub merge {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    my $merger = Hash::Merge->new('LEFT_PRECEDENT');

    # eval bug in Hash::Merge (v0.12 line 100) will likely never be fixed
    # https://rt.cpan.org/Public/Bug/Display.html?id=55978
    # something is hijacking $SIG{__DIE__}
    eval { $self->add($merger->merge($arguments, $self->hash)) };

    return $self;

}


sub nsort {

    my ($self) = @_;

    my $code = sub { $_[0] <=> $_[1] };

    return $self->sort($code);

}


sub pairs {

    my ($self, $function, @arguments) = @_;

    $function ||= 'keys';

    my @keys = ($self->$function(@arguments));

    my @pairs = map {{ key => $_, value => $self->get($_) }} (@keys);

    return (@pairs);

}


sub rmerge {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    my $merger = Hash::Merge->new('RIGHT_PRECEDENT');

    # eval bug in Hash::Merge (v0.12 line 100) will likely never be fixed
    # https://rt.cpan.org/Public/Bug/Display.html?id=55978
    # something is hijacking $SIG{__DIE__}
    eval { $self->add($merger->merge($arguments, $self->hash)) };

    return $self;

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
        sort { $a->$code($b) } ($self->keys) : sort { $a cmp $b } ($self->keys);

}


sub values {

    my ($self) = @_;

    return (values(%{$self->hash}));

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Mapping - Generic Container Class for a Hash Reference

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Mapping;

    my $foos = Validation::Class::Mapping->new;

    $foos->add(foo => 'one foo');
    $foos->add(bar => 'one bar');

    print $foos->count; # 2 objects

=head1 DESCRIPTION

Validation::Class::Mapping is a container class that provides general-purpose
functionality for hashref objects.

=head1 METHODS

=head2 new

    my $self = Validation::Class::Mapping->new;

=head2 add

    $self = $self->add(foo => 1, bar => 2);

=head2 clear

    $self = $self->clear;

=head2 count

    my $count = $self->count;

=head2 delete

    $value = $self->delete($name);

=head2 defined

    $true if $self->defined($name) # defined

=head2 each

    $self = $self->each(sub{

        my ($key, $value) = @_;

    });

=head2 exists

    $true if $self->exists($name) # exists

=head2 get

    my $value = $self->get($name); # i.e. $self->{$name}

=head2 grep

    $new_list = $self->grep(qr/update_/);

=head2 has

    $true if $self->has($name) # defined or exists

=head2 hash

    my $hash = $self->hash;

=head2 iterator

    my $next = $self->iterator();

    # defaults to iterating by keys but accepts: sort, rsort, nsort, or rnsort
    # e.g. $self->iterator('sort', sub{ (shift) cmp (shift) });

    while (my $item = $next->()) {
        # do something with $item (value)
    }

=head2 keys

    my @keys = $self->keys;

=head2 list

    my %hash = $self->list;

=head2 merge

    $self->merge($hashref);

=head2 nsort

    my @keys = $self->nsort;

=head2 pairs

    my @pairs = $self->pairs;
    # or filter using $self->pairs('grep', $regexp);

    foreach my $pair (@pairs) {
        # $pair->{key} is $pair->{value};
    }

=head2 rmerge

    $self->rmerge($hashref);

=head2 rnsort

    my @keys = $self->rnsort;

=head2 rsort

    my @keys = $self->rsort;

=head2 sort

    my @keys = $self->sort(sub{...});

=head2 values

    my @values = $self->values;

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
