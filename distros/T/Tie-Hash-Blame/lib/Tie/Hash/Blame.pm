## no critic (RequireUseStrict)
package Tie::Hash::Blame;
{
  $Tie::Hash::Blame::VERSION = '0.01';
}

## use critic (RequireUseStrict)
use strict;
use warnings;
require Tie::Hash;
use parent '-norequire', 'Tie::ExtraHash';

sub TIEHASH {
    my ( $class ) = @_;

    return bless [
        {}, # key/value storage
        {}, # history storage
    ], $class;
}

sub _storage {
    my ( $self ) = @_;

    return $self->[0];
}

sub _history {
    my ( $self ) = @_;

    return $self->[1];
}

sub STORE {
    my ( $self, $key, $value ) = @_;

    my $storage = $self->_storage;
    my $history = $self->_history;

    $storage->{$key} = $value;

    my ( undef, $filename, $line_no ) = caller;
    $history->{$key} = {
        filename => $filename,
        line_no  => $line_no,
    };

    return $value;
}

sub DELETE {
    my ( $self, $key ) = @_;

    my $storage = $self->_storage;
    my $history = $self->_history;

    delete $history->{$key};
    return delete $storage->{$key};
}

sub CLEAR {
    my ( $self ) = @_;

    my $storage = $self->_storage;
    my $history = $self->_history;

    %$storage = ();
    %$history = ();

    return;
}

sub blame {
    my ( $self ) = @_;

    my $history = $self->_history;
    my %copy;

    foreach my $k (keys %$history) {
        my $v = $history->{$k};

        $copy{$k} = { %$v };
    }

    return \%copy;
}

1;



=pod

=head1 NAME

Tie::Hash::Blame - A hash that remembers where its keys were set

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Tie::Hash::Blame;

  my %hash;
  tie %hash, 'Tie::Hash::Blame';

=head1 DESCRIPTION

Have you ever tried to track changes to a hash throughout a large program?
It's hard, isn't it?  This module makes things a little easier.  Its intended
use is for debugging, because ties are magic, and magic is evil.

=head1 METHODS

=head2 tied(%hash)->blame

Returns a hash reference containing the location of the last assignment to
each hash key.  The keys in the returned hash reference are the same as in the
underlying hash; the values, however, are all hash references with two keys:
'filename' and 'line_no'.

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hoelzro/tie-hash-blame/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut


__END__

# ABSTRACT: A hash that remembers where its keys were set

