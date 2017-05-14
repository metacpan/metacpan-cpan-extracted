############################################################################
#
# Win32::ASP::Error - an abstract parent class for supporting exceptions
#                     in the Win32-ASP-DB system
#
# Author: Toby Everett
# Revision: 0.02
# Last Change:
############################################################################
# Copyright 1999, 2000 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
############################################################################

use Error::Unhandled;
use Class::SelfMethods;

use strict;

=head1 NAME

Win32::ASP::Error - an abstract parent class for implementing exceptions in Win32::ASP::DB

=head1 SYNOPSIS

  use Win32::ASP::Error;

  package Win32::ASP::Error::DBRecord;
  @Win32::ASP::Error::DBRecord::ISA = qw/Win32::ASP::Error/;

  package Win32::ASP::Error::DBRecord::no_permission;
  @Win32::ASP::Error::DBRecord::no_permission::ISA = qw/Win32::ASP::Error::DBRecord/;

  #Parameters:  action, identifier

  sub _as_html {
    my $self = shift;

    my $action = $self->action;
    my $identifier = $self->identifier;
    return <<ENDHTML;
  You are not allowed to $action $identifier.<P>
  ENDHTML
  }

  throw Win32::ASP::Error::DBRecord::no_permission (action => 'view', identifier => $identifier);

=head1 DESCRIPTION

=head2 Overview

C<Win32::ASP::Error> is the abstract parent class used for implementing exceptions in the
Win32::ASP::DB system.  It inherits from C<Error::Unhandled>, which allows exceptions to handle
themselves if the calling program leaves the exception unhandled, and C<Class::SelfMethods>, which
allows instances to override methods and provides for method/attribute calling equivalence.

=head2 Utilization

In general, subclasses of C<Win32::ASP::Error> implement the C<as_html> method (properly
implemented as C<_as_html> so that instances can override it if necessary - see the
C<Class::SelfMethods> documentation for more explanation).  This method should return properly
formatted HTML that describes the condition that led to the exception and, if applicable, provides
instruction to the user about how to rectify the problem.

The return value from the C<title> method is used for the <TITLE> block in the returned web page.

=cut

package Win32::ASP::Error;
@Win32::ASP::Error::ISA = qw/Error::Unhandled Class::SelfMethods/;

sub _unhandled {
  my $self = shift;

  $main::Response->Clear;
  my $title = $self->title;
  my $mesg = $self->as_html;
  $main::Response->Write(<<ENDHTML);
<html>

<head>
<title>Error: $title</title>

</head>

<body bgcolor="#FFFFE1" text="#000000" link="#0000FF" vlink="#800080" alink="#4000C0">
$mesg
</body>
</html>
ENDHTML

  $main::Response->Flush;
  $main::Response->End;
  die;
}

sub _title {
  my $self = shift;

  return "";
}

1;

