#	Win32API::Const -- Basic API Constants
#	Copyright (C) 1998 Brian Dellert: <aspider@pobox.com>, 206/689-6828,
#	<http://www.applespider.com>

#	Constants parsed from the egcs 1.1 header files Defines.h, Messages.h,
#	Errors.h, Base.h, & Sockets.h

#	This program is free software; you can redistribute it and/or modify it
#	under the terms of the GNU General Public License as published by the
#	Free Software Foundation; either version 2 of the License, or (at your
#	option) any later version.
#
#	This program is distributed in the hope that it will be useful, but
#	WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#	or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#	for more details.
#
#	You should have received a copy of the GNU General Public License along
#	with this program (gpl.license.txt); if not, write to the Free Software
#	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

package Win32API::Const;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require DynaLoader;
require AutoLoader;

@ISA = qw(DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
$VERSION = '0.011';

no strict 'refs';
sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;

	if (@_) {
		croak "Usage: Win32API::Const::$constname()";
	}

    croak "& not defined" if $constname eq 'constant';

	my ($val, $error);
	for my $const ($constname, "${constname}A") {
		if (defined &$const) {
			*$AUTOLOAD = \&{$const};
			goto &$AUTOLOAD;
		}
		$val = constant($const);
		$error = $!;
		last unless $error;

		if ($! =~ /Invalid/) {
			$AutoLoader::AUTOLOAD = $AUTOLOAD;
			goto &AutoLoader::AUTOLOAD;
		}
	}
	if ($error) {
		croak "Your vendor has not defined Win32API::Const macro $constname";
	}

	*$constname = sub {$val};
    *$AUTOLOAD = \&{$constname};
    goto &$AUTOLOAD;
}
use strict;

bootstrap Win32API::Const $VERSION;

no strict 'refs';
sub export {
	my ($pkg, $callpkg, $imports) = @_;
	return unless @$imports;

    for my $sym (@$imports) {
		if ($sym !~ s/^://) {
			if (not defined &{"${pkg}::$sym"}) {
				my $val = constant($sym);
				if ($! != 0) {
					if ($! =~ /Invalid/) {
						$AutoLoader::AUTOLOAD = $AUTOLOAD;
						goto &AutoLoader::AUTOLOAD;
					}
					else {
						croak "Your vendor has not defined Win32API::Const macro $sym";
					}
				}
				*{"${pkg}::$sym"} = sub { $val };
			}

			*{"${callpkg}::$sym"} = \&{"${pkg}::$sym"};
		}
		else {
			my $all = $sym !~ /./;
			for my $data_type (1..4) {
				my ($start, $end) = $all ? constant_full_range($data_type) : constant_match_range($data_type, $sym);
				next unless $start <= $end and $start >= 0;
				for (my $i=$start; $i<=$end; ++$i) {
					my ($name, $val) = constant_get($data_type, $i);
					*{"${pkg}::$name"} = sub { $val } unless defined \&{"${pkg}::$name"};
					*{"${callpkg}::$name"} = \&{"${pkg}::$name"};
				}
			}
		}
    }
}

sub import {
    export (shift, scalar (caller), \@_);
}
use strict;


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Win32API::Const - Access Win32 constants such as WM_CLOSE, HELP_CONTENTS, etc.

=head1 SYNOPSIS

  #
  # Access value of WM_CLOSE without importing it
  #
  use Win32API::Const;
  print "WM_CLOSE         = ", Win32API::Const::WM_CLOSE(), "\n";


  #
  # Import and access values of WM_CLOSE and HELP_CONTENTS
  #
  use Win32API::Const qw(WM_CLOSE HELP_CONTENTS);
  print "WM_CLOSE         = ", WM_CLOSE(),      "\n";
  print "HELP_CONTENTS    = ", HELP_CONTENTS(), "\n";


  #
  # Import WM_CLOSE, along with all constants whose names start with WS_ or SE_
  #
  use Win32API::Const qw(:WS_ WM_CLOSE :SE_);
  print "WM_CLOSE         = ", WM_CLOSE(),         "\n";
  print "WS_MAXIMIZE      = ", WS_MAXIMIZE(),      "\n";
  print "WS_MINIMIZE      = ", WS_MINIMIZE(),      "\n";
  print "WS_OVERLAPPED    = ", WS_OVERLAPPED(),    "\n";
  print "SE_SHUTDOWN_NAME = ", SE_SHUTDOWN_NAME(), "\n";

=head1 DESCRIPTION

The Win32API::Const
module allows you to access the values of Win32 constants by name. Almost 6,000 constants are included --
these were parsed from the egcs 1.1 header files: Defines.h, Messages.h, Errors.h, Base.h, and Sockets.h.

Constant names and values were parsed from the egcs 1.1 Win32 header files (egcs is the free GNU
C/C++ compiler). You can download the Win32 version of egcs from
<ftp://ftp.xraylith.wisc.edu/pub/khan/gnu-win32/>.

A full list of Win32 constants and their meanings can be found in the documentation for your Win32
C/C++ compiler or in the Microsoft Developer Network (MSDN).

=head2 IMPORT A CONSTANT

To import a constant, specify its name on the C<use> line. For example, to import the constants
C<WM_CLOSE> and C<SE_SHUTDOWN_NAME>, do this:

  use Win32API::Const qw(WM_CLOSE SE_SHUTDOWN_NAME);

Then, you can get the value of the constant by calling it like a subroutine.

  my $value = WM_CLOSE();
  print "The value of WM_CLOSE is: $value\n";

=head2 IMPORT A RANGE OF CONSTANTS

If you want to import all Win32 constants that start with, let's say, "WM_", then place
":WM_" in the import list. For example:

  use Win32API::Const qw(:WM_);
  print "The value of WM_CLOSE is: ", WM_CLOSE(), "\n";
  print "The value of WM_HELP is:  ", WM_HELP(),  "\n";

You can import an individual constant and a range of constants on the same line. For example,
let's say you wan to import all the constants that start with C<WM_> and C<HELP_>, along with the
constant named C<SE_SHUTDOWN_NAME>.

  use Win32API::Const qw(:WM_ SE_SHUTDOWN_NAME :HELP_);

The order you list stuff in the import list does not matter.

Note that importing C<:WM> is different than importing C<:WM_> (note the trailing underscore).
The former imports constants such as C<WMSZ_BOTTOM>, whereas the latter does not. It's up to you what you want to do.

=head2 USE A CONSTANT WITHOUT IMPORTING IT

You can still use a constant, even if you do not import it into your namespace -- heck, even
if you do not import I<any> constants into your namespace. Just call it like you would any
subroutine, and specify the full Win32API::Const package name.

  use Win32API::Const;

  print "WM_CLOSE = ", Win32API::Const::WM_CLOSE(), "\n";

=head1 COPYRIGHT

Win32API::Const -- Basic API Constants
Copyright (C) 1998 Brian Dellert: <aspider@pobox.com>, 206/689-6828,
<http://www.applespider.com>

Constants parsed from the egcs 1.1 header files Defines.h, Messages.h,
Errors.h, Base.h, & Sockets.h

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program (gpl.license.txt); if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=head1 SEE ALSO



=cut
