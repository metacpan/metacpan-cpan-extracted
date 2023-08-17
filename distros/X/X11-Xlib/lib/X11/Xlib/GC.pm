package X11::Xlib::GC;
require X11::Xlib::Opaque;
# parent class "Opaque" and XS handle all methods.
# No need to load this package.

__END__

=head1 NAME

X11::Xlib::GC - Wrapper for GC* pointers

=head1 DESCRIPTION

This is an opaque structure describing a X11 Graphic Context.
None of the GC API has been implemented yet, so this just allows you to
pass around references to a GC such as the DefaultGC of a Screen.

=head1 ATTRIBUTES

=head2 display

See L<X1::Xlib::Opaque/display>

=head2 pointer_bytes

See L<X1::Xlib::Opaque/pointer_bytes>

=head2 pointer_int

See L<X1::Xlib::Opaque/pointer_int>

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017-2023 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
