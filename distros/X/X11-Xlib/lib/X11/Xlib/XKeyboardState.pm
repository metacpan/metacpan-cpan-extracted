package X11::Xlib::XKeyboardState;
require X11::Xlib::Struct;
__END__

=head1 NAME

X11::Xlib::XKeyboardState - Struct for various keyboard attributes

=head1 ATTRIBUTES

=head2 key_click_percent

int

=head2 bell_percent

int

=head2 bell_pitch

unsigned int

=head2 bell_duration

unsigned int

=head2 led_mask

long

=head2 global_auto_repeat

int

=head2 auto_repeats

char[32]

This is a bit vector for each of 0..255 indicating whether that key scan code has
auto-repeat enabled.

=head1 METHODS

See parent class L<X11::Xlib::Struct>

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
