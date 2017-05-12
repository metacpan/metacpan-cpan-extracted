package Test::MobileAgent::Airh;

use strict;
use warnings;
use base 'Test::MobileAgent::Base';

# this list is borrowed from HTTP::MobileAgent's t/07_airh.t
# last updated: Fri Jan 14 14:56:46 2011
sub _list {q{
Mozilla/3.0(DDIPOCKET;JRC/AH-J3001V,AH-J3002V/1.0/0100/c50)CNF/2.0
Mozilla/3.0(DDIPOCKET;KYOCERA/AH-K3001V/1.4.1.67.000000/0.1/C100) Opera 7.0
Mozilla/3.0(WILLCOM;KYOCERA/WX300K/1;1.0.2.8.000000/0.1/C100) Opera/7.0
Mozilla/3.0(WILLCOM;SANYO/WX310SA/2;1/1/C128) NetFront/3.3
Mozilla/3.0(WILLCOM;KES/WS009KEplus/2;0001;1/1/C128) NetFront/3.3
Mozilla/3.0(WILLCOM;KES/WS009KE/2;3/1/C128) NetFront/3.3
Mozilla/3.0(WILLCOM;KES/WS009KE/2;1/1/C128) NetFront/3.3
Mozilla/3.0(WILLCOM;KES/WS009KEplus/2;0001;1/1/C128) NetFront/3.3
Mozilla/3.0(WILLCOM;KYOCERA/WX310K/2;1.2.14.17.000000/0.1/C100) Opera 7.0
Mozilla/3.0(WILLCOM;KYOCERA/WX310K/2;1.2.3.16.000000/0.1/C100) Opera 7.0
}}

1;

__END__

=head1 NAME

Test::MobileAgent::Airh

=head1 SEE ALSO

See L<HTTP::MobileAgent>'s t/07_airh.t, from which the data is borrowed.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
