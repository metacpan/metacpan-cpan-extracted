# $Id: Senna.pm 2 2005-11-15 15:43:07Z daisuke $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Tie::Senna;
use strict;
use base qw(Tie::Hash);
use Senna;
our $VERSION = '0.02';

sub TIEHASH
{
    my $class = shift;
    my %args  = @_;
    my $index = $args{index};
    my $storage = $args{storage};

    # If not storage given, use a plain hash (all in memory)
    if (!$storage) {
        warn "no storage given, using in-memory hash (all data will be lost when program exits)";
        $storage = {};
    }

    if (ref($storage) ne 'HASH') {
        Carp::croak("storage must be a hash!");
    }

    bless {
        index => $index,
        storage => $storage,
    }, $class;
}

sub index { shift->{index} }
sub storage { shift->{storage} }

sub search
{
    my $self = shift;
    my $query = shift;

    my $c = $self->{index}->search($query);
    return wantarray ? $c->as_list : $c;
}

sub STORE
{
    my $self = shift;
    my $key  = shift;
    my $val  = shift;

    if ($self->EXISTS($key)) {
        $self->{index}->replace($key,
            delete $self->{storage}->{$key},
            $val);
    } else {
        $self->{index}->put($key, $val);
    }
    $self->{storage}->{$key} = $val;
}

sub DELETE
{
    my $self = shift;
    my $key  = shift;
    $self->{index}->del($key, $self->{storage}->{$key});
    delete $self->{storage}->{$key};
}

sub EXISTS
{
    my $self = shift;
    my $key  = shift;
    return exists $self->{storage}->{$key};
}

sub FIRSTKEY
{
    my $self = shift;
    my $storage = $self->{storage};
    if (my $tied = tied(%$storage)) {
        return $tied->FIRSTKEY(@_);
    } else {
        my $a = scalar keys %{$storage};
        return each %{$_[0]};
    }
}

sub NEXTKEY
{
    my $self = shift;
    my $storage = $self->{storage};
    if (my $tied = tied(%$storage)) {
        return $tied->NEXTKEY(@_);
    } else {
        my $a = scalar keys %{$storage};
        return each %{$_[0]};
    }
}

sub CLEAR
{
    my $self = shift;

    my @args = (
        $self->{index}->filename,
        $self->{index}->key_size,
        $self->{index}->flags,
        $self->{index}->initial_n_segments,
        $self->{index}->encoding,
    );
    $self->{index}->remove;
    $self->{index}->create(@args);

    if (my $tied = tied(%{$self->{storage}})) {
        $tied->CLEAR(@_);
    } else {
        %{$self->{storage}} = ();
    }
}

1;

__END__

=head1 NAME

Tie::Senna - Tie Senna With Hashes

=head1 SYNOPSIS

  use Tie::Senna;
  my $senna = Senna::Index->create(...);

  tie %hash, 'Tie::Senna', index => $index;
  # tie %hash, 'Tie::Senna', index => $index, storage => \%storage;
  $hash{$key} = $value;

  foreach my $r ( tied(%hash)->search($query) ) {
    print "matched ", $r->key, " -> score: ", $hash{$r->key}\n";
  }

=head1 DESCRIPTION

Tie::Senna ties an existing hash with a senna index.

=head1 METHODS

=head2 tie(%hash, 'Tie::Senna', %args)

Tie a Senna with a hash. After tieing, subsequent calls to modify %hash will
trigger necessary changes to the underlying senna index, so you can perform
searches on it.

%args must contain the 'index' parameter. This must point to a Senna::Index
object.

You may optionally specify a reference to hash as the C<storage> parameter.
It is recommended that you specify this, as otherwise Tie::Senna will use
a plain old in-memory hash, and all data will be lost when the object is
garbage collected. You can specify other tied hashes, too:

   use Tie::Senna;
   use DB_File;

   my %storage;
   tie %storage, 'DB_File', ...;

   my $index = Senna::Index->create(...);
   my %senna;
   tie %senna, 'Tie::Senna', index => $index, storage => \%storage;

=head2 search($query)

Perform a full text search on the index and returns a Senna::Cursor object, 
or a list of Senna::Result objects in list context. You need to access the 
tied() object from the tied hash to call this method.

=head2 storage()

Return a reference to the underlying hash that is used as the data storage

=head2 index()

Return the underlying Senna::Index object being used.

=head1 AUTHOR

(c) Copyright 2005 - Daisuke Maki E<lt>dmaki@cpan.orgE<gt>.

Development funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=head1 SEE ALSO

L<Senna|Senna>, L<Tie::Hash>, L<Class::DBI::Plugin::Senna>

=cut
