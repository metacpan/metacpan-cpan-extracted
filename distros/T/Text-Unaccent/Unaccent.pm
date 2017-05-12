#
# Copyright (C) 2000, 2001, 2002, 2004 Loic Dachary <loic@senga.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
package Text::Unaccent;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(
unac_string unac_string_utf16 unac_version unac_debug
);
$VERSION = '1.08';

bootstrap Text::Unaccent $VERSION;

1;
__END__

=head1 NAME

Text::Unaccent - Remove accents from a string

=head1 SYNOPSIS

  use Text::Unaccent;

  $unaccented = unac_string($charset, $string);
  $unaccented = unac_string_utf16($string);
  $version = unac_version();
  unac_debug($level);

=head1 DESCRIPTION

Text::Unaccent is a module that remove accents from a string.
C<unac_string> converts the input string from the
specified  charset to UTF-16 and call 
C<unac_string_utf16> to
return the unaccented equivalent. The conversion from  and
to  UTF-16  is  done  with iconv(1).

=head1 METHODS

=over 4

=item $unaccented = unac_string($charset, $string)

Return the unaccented equivalent of the  string
C<$string>. The character set of 
C<$string> is specified by the 
C<$charset> argument. The returned string is coded using
the same character set. Valid values for the 
C<$charset> argument are character sets known by 
iconv(1). Under GNU/Linux try C<iconv -l> for 
a complete list.

=item $unaccented = unac_string_utf16($string)

Return the unaccented equivalent of the  string
C<$string>. The character set of 
C<$string> must be UTF-16.

=item $version = unac_version()

Return the version of the unac library used by this
perl module.

=item unac_debug($level)

Set the debug level. Messages are printed on stderr.
Possible debug levels are:

=over 4
=item $Text::Unaccent::DEBUG_NONE
Silent.
=item $Text::Unaccent::DEBUG_LOW
Human readable messsages.
=item $Text::Unaccent::DEBUG_HIGH
Detailed and very verbose information.
=back 

=back 

=head1 AUTHOR

Loic Dachary (loic@senga.org)
http://www.senga.org/unac/

=head1 SEE ALSO

iconv(1), unac(3).

=cut
