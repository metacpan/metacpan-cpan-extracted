#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Actions/Email.pm,v $
#            $Revision: 1.8 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: An extension of the VBTK::Actions library which defaults
#                       to common settings used in creating an email action.
#
#           Depends on: VBTK::Common, VBTK::Actions
#
#       Copyright (C) 1996 - 2002  Brent Henry
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
#       $Log: Email.pm,v $
#       Revision 1.8  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.7  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.6  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.5  2002/02/20 20:41:35  bhenry
#       *** empty log message ***
#
#       Revision 1.4  2002/02/20 19:25:18  bhenry
#       *** empty log message ***
#
#       Revision 1.3  2002/02/19 19:01:28  bhenry
#       Rewrote Actions to make use of inheritance
#
#       Revision 1.2  2002/01/21 17:07:44  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project

package VBTK::Actions::Email;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Actions;
use Mail::Sendmail;

# Inherit methods from Actions class
our @ISA = qw(VBTK::Actions);

our $VERBOSE = $ENV{VERBOSE};

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my ($type,$self);
    
    # If we're passed a hash, then it's probably from an inheriting class
    if((defined $_[0])&&(UNIVERSAL::isa($_[0], 'HASH')))
    {
        $self = shift;
    }
    # Otherwise, allocate a new hash, bless it and handle any passed parms
    else
    {
        $type = shift;
        $self = {};
        bless $self, $type;

        # Set any passed parms
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
            SendUrl       => 1,
            LimitToEvery  => '2 min',
            SubActionList => undef,
            LogActionFlag => undef,
        };

        # Run a validation on the passed parms, using the default parms        
        $self->validateParms($defaultParms) || &fatal("Exiting");
    }

    # Make sure the user put in some recipient    
    &fatal("Must specify To, Cc, or Bcc in call to new VBTK::Actions::Email")
        unless($self->{To} or $self->{Cc} or $self->{Bcc});

    # Call the parent object    
    $self->SUPER::new() || &fatal("Exiting");

    # Setup the mail hash
    $self->{mailHash} = { 
        To      => $self->{To},
        Cc      => $self->{Cc},
        Bcc     => $self->{Bcc},
        From    => $self->{From},
        Subject => $self->{Subject},
        Smtp    => $self->{Smtp},
    };

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     run
# Description:  Run the email action.  Send email to the specified recipients
# Input Parms:
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub run
{
    my $self = shift;
    my $message = shift;
    my $mailHash      = $self->{mailHash};
    my $Timeout       = $self->{Timeout};
    my $To            = $self->{To};
    my $Smtp          = $self->{Smtp};
    my $MessagePrefix = $self->{MessagePrefix};

    # Append the 
    $mailHash->{Message} = $MessagePrefix . $message;
    
    # Run all network operations within an alarmed eval, so that nomatter
    # where it hangs, if it doesn't finish in $timeout seconds, then it will
    # just fail gracefully.
    eval {
        local $SIG{ALRM} = sub { die "Timed out while connecting\n"; };
        alarm $Timeout;

        &log("Sending email to '$To'") if ($VERBOSE > 1);

        &sendmail(%{$mailHash}) || die "$Mail::Sendmail::error\n";

        alarm 0;
    };

    alarm 0;

    # Check for errors
    if($@ ne '')
    {
        my $msg = "Error sending mail to '$Smtp' - $@";
        &error($msg);
        return 0;
    }
    
    1;
}


1;
__END__

=head1 NAME

VBTK::Actions::Email - A sub-class of VBTK::Actions for sending email notifications

=head1 SYNOPSIS

  $t = new VBTK::Actions::Email (
    Name         => 'emailMe',
    To           => 'me@nowhere.com' );
    
=head1 DESCRIPTION

The VBTK::Actions::Email is a simple sub-class off the VBTK::Actions class.
It is used to define an email notification action.  It accepts many of the
same paramters as VBTK::Actions, but will appropriately default most if 
not specified.  It makes use of the L<Mail::Sendmail|Mail::Sendmail> module
to actually send the email.

=head1 METHODS

The following methods are supported

=over 4

=item $s = new VBTK::Actions (<parm1> => <val1>, <parm2> => <val2>, ...)

The allows parameters are:

=over 4

=item Name

See L<VBTK::Actions> (required)

=item To, Cc, Bcc

A string containing a list of email addresses to which a message should be sent
when the action is triggered.  You must specify either 'To', 'Cc', or 'Bcc' 
when calling the 'new' method for this package.

    To => 'me@somewhere.com',
    Cc => 'me2@somewhere.com',
    Bcc => 'me3@somewhere.com',

=item From

A string containing the 'From' address to use when constructing the notification
email.  (Defaults to use whatever was setup in the L<Mail::Sendmail|Mail::Sendmail>
package).

    From => 'vbtk@mydomain.com',

=item Subject

A string containing the subject line to use when contructing the notification
email.  (Defaults to 'VBServer_<hostname>')

    Subject => 'VBTK Message from $HOST',

=item MessagePrefix

A string containing a block of text to add to the front of each email sent.
(Defaults to none).

    MessagePrefix => "The following is a message from VBTK\n";

=item Smtp

A string containing the hostname or IP address of the Smtp server to which the
email messages should be sent.  If no value is specified, it will make use of
the default set in the L<Mail::Sendmail|Mail::Sendmail> perl module.

    Smtp => "mysmtphost",

=item Timeout

A numeric value which specifies the max number of seconds to wait when sending
the email to the Smtp server.  (Default to 20).

    Timeout => 20,

=item SendUrl

See L<VBTK::Actions/item_SendUrl>.  (Defaults to '1').

=item LimitToEvery

See L<VBTK::Actions/item_LimitToEvery>.  (Defaults to '2 min').

=item SubActionList

See L<VBTK::Actions/item_SubActionList>.

=item LogActionFlag

See L<VBTK::Actions/item_LogActionFlag>.

=back

=back

=head1 SUB-CLASSES

The following sub-classes were created to provide common defaults in the use
of VBTK::Actions::Email objects.

=over 4

=item L<VBTK::Actions::Email::Page|VBTK::Actions::Email::Page>

Sending an email to a pager as an action

=back

Others are sure to follow.  If you're interested in adding your own sub-class,
just copy and modify some of the existing ones.  Eventually, I'll get around
to documenting this better.

=head1 SEE ALSO

=over 4

=item L<VBTK::Server|VBTK::Server>

=item L<VBTK::Parser|VBTK::Parser>

=item L<VBTK::Actions|VBTK::Actions>

=item L<VBTK::Actions::Email::Page|VBTK::Actions::Email::Page>

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
