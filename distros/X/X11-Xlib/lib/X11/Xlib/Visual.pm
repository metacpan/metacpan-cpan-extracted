package X11::Xlib::Visual;
require X11::Xlib::Opaque;
# parent class "Opaque" and XS handle all methods.
# No need to load this package.

__END__

=head1 NAME

X11::Xlib::Visual - Wrapper for Visual* pointers

=head1 DESCRIPTION

This is an opaque structure describing an available visual configuration
of a screen.  The only thing you can do with this object is pass it to
X11 functions, or get its L</id> to look up the L<X11::Xlib::XVisualInfo>.

=head1 ATTRIBUTES

=head2 id

Return the numeric ID of this visual.

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017-2020 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
