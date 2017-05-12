# BW::Constants.pm
# Commonly used constants for BW::* modules
# 
# by Bill Weinman - http://bw.org/
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#
# See POD for History

package BW::Constants;

use strict;
use warnings;
use 5.008;
use Exporter 'import';

use constant {
    TRUE    => 1,
    SUCCESS => 1,
    FALSE   => '',
    FAILURE => '',
    EMPTY   => '',
    CR      => "\x0d",
    LF      => "\x0a",
    CRLF    => "\x0d\x0a",
    VOID    => undef
};

our @EXPORT  = qw ( TRUE SUCCESS FALSE FAILURE EMPTY CR LF CRLF VOID );
our $VERSION = "1.2";

1;

__END__

=head1 NAME

BW::Constants - Commonly used constants

=head1 SYNOPSIS

  use BW::Constants;

  sub x { blah blah; return SUCCESS }
  sub y { blah blah; return FAILURE }

=head1 CONSTANTS

=over 4

=item B<TRUE>

The value 1 for use in logical tests and conditionals. 

=item B<SUCCESS>

The value 1 for use as a return value to indicate success. 

=item B<FALSE>

The value '' for use in logical tests and conditionals. Note: This is what
perl uses internally for false as it avoids ambiguity with numeric 0. 

=item B<FAILURE>

The value '' for use as a return value to indicate failure. 

=item B<CR>

ASCII Carriage Return.

=item B<LF>

ASCII Line Feed. 

=item B<CRLF>

CR + LF ... suitable for MIME line endings and other things. 

=item B<EMPTY>

The value '' for use as an empty string. 

=item B<VOID>

The value undef for use as a non-value return. 

=back

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

    2010-02-02 bw 1.2   -- first CPAN release
    2007-10-20 bw       -- added CR, LF, and CRLF
    2007-10-18 bw       -- initial release.

=cut

