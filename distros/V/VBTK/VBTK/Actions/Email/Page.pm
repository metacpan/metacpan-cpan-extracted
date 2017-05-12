#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Actions/Email/Page.pm,v $
#            $Revision: 1.6 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: An extension of the VBTK::Actions library which defaults
#                       to common settings used in creating a page action.
#
#           Depends on: VBTK::Common, VBTK::Actions
#
#       Copyright (C) 1996-2002  Brent Henry
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of version 2 of the GNU General Public
#       License as published by the Free Software Foundation available at:
#       http://http://www.gnu.org/copyleft/gpl.html
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#############################################################################
#
#
#       REVISION HISTORY:
#
#       $Log: Page.pm,v $
#       Revision 1.6  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.5  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.4  2002/03/04 16:46:39  bhenry
#       *** empty log message ***
#
#       Revision 1.3  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.2  2002/02/20 19:25:18  bhenry
#       *** empty log message ***
#
#       Revision 1.1  2002/02/19 19:01:28  bhenry
#       Rewrote Actions to make use of inheritance
#

package VBTK::Actions::Email::Page;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Actions::Email;

# Inherit methods from Actions::Email class
our @ISA = qw(VBTK::Actions::Email);

our $VERBOSE = $ENV{VERBOSE};

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    # Store all passed input name pairs in the object
    $self->set(@_);

    # Setup a hash of default parameters
    my $defaultParms = {
        Name          => $::REQUIRED,
        To            => undef,
        Cc            => undef,
        Bcc           => undef,
        From          => undef,
        Subject       => "VBServer_$::HOST",
        MessagePrefix => undef,
        Smtp          => undef,
        Timeout       => 20,
        SendUrl       => undef,
        LimitToEvery  => '10 min',
        SubActionList => undef,
        LogActionFlag => undef,
    };

    # Run a validation on the passed parms, using the default parms        
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Now call the parents 'new' method
    $self->SUPER::new() || &fatal("Exiting");

    ($self);
}

1;
__END__

=head1 NAME

VBTK::Actions::Email::Page - A sub-class of VBTK::Actions::Email for sending
pager notifications via email

=head1 SYNOPSIS

  $t = new VBTK::Actions::Page (
    Name         => 'pageMe',
    Email        => 'page.me@nowhere.com' );

=head1 DESCRIPTION

The VBTK::Actions::Page is a simple sub-class off the VBTK::Actions class.
It is used to define an pager notification action.  It accepts all of the
same paramters as VBTK::Actions, but will appropriately default most if 
not specified.  It is essentially identical to VBTK::Actions::Email
except that it defaults the 'LimitToEvery' and 'SendUrl' parms differently
to better work with sending email to a pager or other wireless device.

=head1 METHODS

The following methods are supported

=over 4

=item $s = new VBTK::Actions (<parm1> => <val1>, <parm2> => <val2>, ...)

The allowed parameters are the same as for the 
L<VBTK::Actions::Email|VBTK::Actions::Email> module except that it defaults
the following parameters as specified below:

=over 4

=item LimitToEvery

    LimitToEvery => '10 min',

=item SendUrl

    SendUrl => 0,

=back

=back

=head1 SEE ALSO

=over 4

=item L<VBTK::Server|VBTK::Server>

=item L<VBTK::Parser|VBTK::Parser>

=item L<VBTK::Actions|VBTK::Actions>

=item L<VBTK::Actions::Email|VBTK::Actions::Email>

=item L<Mail::Sendmail|Mail::Sendmail>

=back

=head1 AUTHOR

Brent Henry, vbtoolkit@yahoo.com

=head1 COPYRIGHT

Copyright (C) 1996-2002 Brent Henry

This program is free software; you can redistribute it and/or
modify it under the terms of version 2 of the GNU General Public
License as published by the Free Software Foundation available at:
http://http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
