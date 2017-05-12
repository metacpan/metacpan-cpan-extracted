# -*- Perl -*-

package Unix::Sysexits;

use 5.006000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	EX_CANTCREAT
	EX_CONFIG
	EX_DATAERR
	EX_IOERR
	EX_NOHOST
	EX_NOINPUT
	EX_NOPERM
	EX_NOUSER
	EX_OK
	EX_OSERR
	EX_OSFILE
	EX_PROTOCOL
	EX_SOFTWARE
	EX_TEMPFAIL
	EX_UNAVAILABLE
	EX_USAGE
	EX__BASE
	EX__MAX
);

our $VERSION = '0.06';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Unix::Sysexits::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Unix::Sysexits', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Unix::Sysexits - Perl extension for sysexits.h

=head1 SYNOPSIS

Consult L<sysexits(3)> for details on the constants.

  use Unix::Sysexits;
  exit EX_USAGE;

=head1 DESCRIPTION

No really, just a thin wrapper around L<sysexits(3)> for those
constants. See L<POSIX> for the EXIT_FAILURE and EXIT_SUCCESS stdlib
constants.

=head2 EXPORT

  EX_CANTCREAT
  EX_CONFIG
  EX_DATAERR
  EX_IOERR
  EX_NOHOST
  EX_NOINPUT
  EX_NOPERM
  EX_NOUSER
  EX_OK
  EX_OSERR
  EX_OSFILE
  EX_PROTOCOL
  EX_SOFTWARE
  EX_TEMPFAIL
  EX_UNAVAILABLE
  EX_USAGE
  EX__BASE
  EX__MAX

=head1 SEE ALSO

L<sysexits(3)>, L<POSIX>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011,2013-2015 Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
