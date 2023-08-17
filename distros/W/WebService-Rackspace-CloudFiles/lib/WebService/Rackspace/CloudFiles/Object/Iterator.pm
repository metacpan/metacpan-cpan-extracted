package WebService::Rackspace::CloudFiles::Object::Iterator;
use Moo;
use Types::Standard qw(Bool CodeRef);

has 'callback', is => 'ro', isa => CodeRef;
has 'is_done', is => 'rwp', isa => Bool;

sub next {
    my $self = shift;
    return if $self->is_done;

    my $cb = $self->callback;
    my $next = $self->$cb;
    return $next if $next;

    $self->_set_is_done(1);
    return;
}

sub items {
    my $self = shift;
    if (my $a = $self->next) {
        return @$a;
    }
    return ();
}

sub all {
    my $self = shift;
    my @all = ();
    while (my $next = $self->next) {
        push @all, @$next;
    }
    return @all;
}

sub cat      { $_[0]->upgrade_to_data_stream_bulk; shift->cat(@_);       }
sub list_cat { $_[0]->upgrade_to_data_stream_bulk; shift->list_calt(@_); }
sub filter   { $_[0]->upgrade_to_data_stream_bulk; shift->filter(@_);    }
sub chunk    { $_[0]->upgrade_to_data_stream_bulk; shift->chunk(@_);     }
sub upgrade_to_data_stream_bulk {
  require Data::Stream::Bulk::Callback;
  $_[0] = Data::Stream::Bulk::Callback->new(callback => $_[0]->callback);
}

1;

__END__

=head1 NAME
 
WebService::Rackspace::CloudFiles::Object::Iterator - A simple iterator
for CloudFiles file objects.
 
=head1 SYNOPSIS

  # $container is an instance of WebService::Rackspace::CloudFiles::Container
  my @objects = $container->objects->all;

  # or
  my $next = $container->objects->next;
 
=head1 DESCRIPTION

Since Rackspace CloudFiles can only return 10,000 files at a time, an iterator
is needed. WebService::RackSpace::CloudFiles used to use 
Data::Bulk::Streamer but this relied upon Moose. It was replaced with this 
module in order to allow use of Moo instead.

This class supports the methods next, items, all, and is_done. For backward
compatibility with previous versions of WebService::Rackspace::CloudFiles, if
you call one of unsupported Data::Stream::Bulk's methods on an instance of this
class, it will be converted to a Data::Stream::Bulk::Callback object. 
 
=head1 METHODS
 
=head2 next

Retrieves the next block of items, if any, as an arrayref.

=head2 items

Retrieves the next block of items and dereferences the result.
 
=head2 all

Retrieves all items.

=head2 callback

=head2 cat

=head2 chunk

=head2 filter

=head2 list_cat

=head2 upgrade_to_data_stream_bulk
  
=head2 is_done

Returns true if there are no more items. Note that a false value means
that there MAY or MAY NOT be additional items.
 
=head1 SEE ALSO
 
L<WebService::Rackspace::CloudFiles>,
L<WebService::Rackspace::CloudFiles::Container>,
L<WebService::Rackspace::CloudFiles::Object>.
 
=head1 AUTHOR
 
Dondi Michael Stroma <dstroma@gmail.com>.
 
=head1 COPYRIGHT
 
Copyright (C) 2017, Dondi Michael Stroma
 
=head1 LICENSE
 
This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
