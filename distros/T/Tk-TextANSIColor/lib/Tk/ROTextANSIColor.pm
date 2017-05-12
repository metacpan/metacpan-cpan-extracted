package Tk::ROTextANSIColor;

use strict;

require Tk;
require Tk::TextANSIColor;
require Tk::ROText;

use vars qw/ $VERSION /;
$VERSION = '0.01';

# Inherit from Tk::TextANSIColor
# Can not inherit from Tk::ROText as well since Tk::TextANSIColor
# already inherits from Tk::Text and those methods will supercede
# RO::Text methods.
use base qw(Tk::TextANSIColor);

# Construct the new widget
Construct Tk::Widget 'ROTextANSIColor';

# Inheritance problems mean we have to provide some methods
# that call into Tk::ROText directly. If Tk::ROText is changed
# this may well have to change as well. The neater OO approach would
# be to have a dummy class containing the ANSIColor methods that 
# both Tk::TextANSIColor and Tk::ROTextANSIColor can inherit from
# Tk::TextANSIColor would inherit from that base class and Tk::Text
# and Tk::ROTextANSIColor would inheirt from that base and Tk::ROText.
# For now, just jump the tree.

sub ClassInit {
  Tk::ROText::ClassInit(@_);
}

sub clipEvents {
  Tk::ROText::clipEvents(@_);
}

1;

__END__


=head1 NAME

Tk::ROTextANSIColor - Read-only Tk::TextANSIColor

=for pm Tk/ROTextANSIColor.pm

=for category Derived Widgets

=head1 SYNOPSIS

  use Tk::ROTextANSIColor;

  $wid = $mw->ROTextANSIColor(?options,...?);

  $wid->insert($pos, $string, ?taglist, ?string, ?taglist);

  use Term::ANSIColor; 
  $red = color('red');  # Retrieve color codes
  $bold = color('bold');
  $wid->insert('end', "$red red text $bold with bold\n");

=head1 DESCRIPTION

This is a read-only version of C<Tk::TextANSIColor>.

=head1 SEE ALSO

L<Tk::ROText>, L<Tk::TextANSIColor>

=head1 AUTHOR

Tim Jenness (E<lt>tjenness@cpan.orgE<gt>)

=head1 COPYRIGHT

Copyright (c) 1999-2000 Tim Jenness. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
