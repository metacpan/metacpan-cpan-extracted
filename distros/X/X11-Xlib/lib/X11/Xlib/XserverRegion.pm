package X11::Xlib::XserverRegion;
use strict;
use warnings;
use Carp;
use parent 'X11::Xlib::XID';

# All modules in dist share a version
BEGIN { our $VERSION= $X11::Xlib::VERSION; }

sub DESTROY {
    my $self= shift;
    $self->display->XFixesDestroyRegion($self->xid)
        if $self->autofree && $self->xid;
}

1;

__END__

=head1 NAME

X11::Xlib::XserverRegion - XID wrapper for XserverRegion

=head1 DESCRIPTION

Object representing a clip region, as used by the Xfixes extension.

Not much of that API is exposed by this module, yet.

=head1 ATTRIBUTES

See L<X11::Xlib::XID> for base-class attributes.

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
