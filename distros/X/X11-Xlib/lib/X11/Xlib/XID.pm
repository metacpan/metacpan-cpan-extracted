package X11::Xlib::XID;
use strict;
use warnings;
use Carp;
use X11::Xlib;

sub new {
    my $class= shift;
    my %args= (@_ == 1 && ref $_[0] eq 'HASH')? %{$_[0]} : @_;
    defined $args{display} or croak "'display' is required";
    defined $args{xid}     or croak "'xid' is required";
    bless \%args, $class;
}

sub display { croak "read-only" if @_ > 1; $_[0]{display} }
sub xid     { croak "read-only" if @_ > 1; $_[0]{xid} }
*id= *xid;
*dpy= *display;
sub autofree { my $self= shift; $self->{autofree}= shift if @_; $self->{autofree} }

1;

__END__

=head1 NAME

X11::Xlib::XID - Base class for objects wrapping an XID

=head1 ATTRIBUTES

=head2 display

Required.  The L<X11::Xlib::Display> where the resource is located.

=head2 xid

Required.  The X11 numeric ID for this resource.

=head2 autofree

Whether this object should control the lifespan of the remote resource,
by calling an Xlib Free/Destroy function if it goes out of scope.
The default is False, since this base class has no idea how to release
any resources.

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
