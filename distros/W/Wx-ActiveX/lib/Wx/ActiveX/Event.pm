#############################################################################
## Name:        lib/Wx/ActiveX/Event.pm
## Purpose:     Wx::ActiveX events.
## Author:      Graciliano M. P.
## Created:     01/09/2003
## SVN-ID:      $Id: Event.pm 2846 2010-03-16 09:15:49Z mdootson $
## Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::ActiveX::Event;
use strict;
use Wx::ActiveX::IE;
use base qw( Exporter );
our( @EXPORT_OK, %EXPORT_TAGS );

$EXPORT_TAGS{'everything'} = \@EXPORT_OK;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;
$EXPORT_TAGS{'activex'} = \@EXPORT_OK;

# this module file retained only to support VERSION < 0.06 code.
# new code should use Wx::ActiveX constants & EVT subs

our $VERSION = '0.15'; # Wx::ActiveX Version

sub EVT_ACTIVEX ($$$$) { &Wx::ActiveX::EVT_ACTIVEX( @_ ) }

push(@EXPORT_OK, 'EVT_ACTIVEX');

my $exporttag = 'iexplorer';
my $eventname = 'IE';

# we don't inherit from Wx::ActiveX so call as function
&Wx::ActiveX::activex_load_activex_event_types(__PACKAGE__,
                                               __PACKAGE__,
                                               $eventname,
                                               $exporttag,
                                               \@Wx::ActiveX::IE::activexevents );

1;

__END__

