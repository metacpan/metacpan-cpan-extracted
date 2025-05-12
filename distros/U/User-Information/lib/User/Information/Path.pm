# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Path;

use v5.20;
use strict;
use warnings;

use parent 'Data::Identifier::Interface::Userdata';

use Data::Identifier;
use Data::Identifier::Generate;
use User::Information;

use Carp;

our $VERSION = v0.01;

my %_registered;


sub new {
    my ($pkg, @args) = @_;
    my @elements;
    my $self = bless {elements => \@elements}, $pkg;
    my $root;
    my $sub;
    my $hashkey;

    if (!(scalar(@args) & 1)) {
        $root = shift(@args);
    }
    $sub = shift(@args);

    if (ref $sub) {
        @elements = @{$sub};
    } elsif (defined $sub) {
        @elements = ($sub);
    }

    croak 'No elements given' unless scalar @elements;

    if (defined $root) {
        unshift(@elements, $root->_elements);
    }

    foreach my $el (@elements) {
        $el = _mk_element($el);
    }

    croak 'Stray options passed' if scalar @args;

    $hashkey = join('/', map {$_->ise} @elements); # no need to escape as we do not accept chars that need to be escaped to begin with

    if (defined $_registered{$hashkey}) {
        return $_registered{$hashkey};
    }

    $_registered{$hashkey} = $self;
    $self->{hashkey} = $hashkey;

    return $self;
}


sub displayname {
    my ($self, %opts) = @_;

    delete $opts{default};
    delete $opts{no_defaults};

    croak 'Stray options passed' if scalar keys %opts;
    return $self->{displayname} = join('/', map {$_->displayname} $self->_elements);
}

# ---- Private helpers ----
sub _elements {
    my ($self) = @_;
    return @{$self->{elements}};
}

sub _last_element_id {
    my ($self) = @_;
    return $self->{elements}[-1]->id;
}

sub _hashkey {
    my ($self) = @_;
    return $self->{hashkey};
}

sub _mk_element {
    my ($val) = @_;
    my $ret;

    return $val->Data::Identifier::as('Data::Identifier') if ref $val;

    $ret = Data::Identifier->new(User::Information->PATH_ELEMENT_TYPE => $val);
    $ret->{id_cache}{Data::Identifier->WK_UUID()} = Data::Identifier::Generate->_uuid_v5(User::Information->PATH_ELEMENT_NS, $val);

    $ret->register;

    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Path - generic module for extracting information from user accounts

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use User::Information::Path;

    my User::Information::Path $path = User::Information::Path->new([qw(root key subkey)]);

This module is used to build paths (used to get values from a L<User::Information::Base>).

This package inherits from L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head2 new

    my User::Information::Path $path = User::Information::Path->new([qw(root key subkey)]);
    # or:
    my User::Information::Path $path = User::Information::Path->new($root => [qw(sub path)]);

Creates a new path instance using the given keys.

This module may cache the resulting objects.

This package inherits from L<Data::Identifier::Interface::Userdata>.

=head2 displayname

    my $displayname = $path->displayname;

Returns a human readable version of the path.

This method does not take any options. However C<default> and C<no_defaults> are ignored.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
