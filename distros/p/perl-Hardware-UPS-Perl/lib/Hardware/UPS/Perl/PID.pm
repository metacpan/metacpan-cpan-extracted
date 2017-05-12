package Hardware::UPS::Perl::PID;

#==============================================================================
# package description:
#==============================================================================
# This package supplies a set of methods to deal with PID files. For a
# detailed description see the pod documentation included at the end of this
# file.
#
# List of public methods:
# -----------------------
#   new                     - initializing a Hardware::UPS::Perl PID file
#                             object
#   setLogger               - setting the current logger
#   getLogger               - getting the current logger
#   getErrorMessage         - getting internal error messages
#   delete                  - deleting the PID file
#   getPID                  - getting the current PID
#   getPIDFile              - getting the current PID file
#
#==============================================================================

#==============================================================================
# Copyright:
#==============================================================================
# Copyright (c) 2007 Christian Reile, <Christian.Reile@t-online.de>. All
# rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#==============================================================================

#==============================================================================
# Entries for Revision Control:
#==============================================================================
# Revision        : $Revision: 1.9 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/17 19:47:48 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
#   $Log: PID.pm,v $
#   Revision 1.9  2007/04/17 19:47:48  creile
#   documentation bugfixes.
#
#   Revision 1.8  2007/04/14 09:37:26  creile
#   documentation update.
#
#   Revision 1.7  2007/04/07 15:15:13  creile
#   adaptations to "best practices" style;
#   update of documentation.
#
#   Revision 1.6  2007/03/13 17:21:49  creile
#   options as anonymous hashes.
#
#   Revision 1.5  2007/03/03 21:17:23  creile
#   new variable $UPSERROR added;
#   adaptations to revised Constants.pm;
#   "return undef" replaced by "return".
#
#   Revision 1.4  2007/02/25 17:07:33  creile
#   option handling redesigned.
#
#   Revision 1.3  2007/02/05 20:36:40  creile
#   pod documentation revised.
#
#   Revision 1.2  2007/02/04 14:00:39  creile
#   public method delete() revised;
#   logging support added;
#   private method _open() renamed to _writePID();
#   update of documentation.
#
#   Revision 1.1  2007/02/01 10:53:21  creile
#   initial revision.
#
#
#==============================================================================

#==============================================================================
# module preamble:
#==============================================================================

use strict;

BEGIN {
    
    use vars qw($VERSION @ISA);

    $VERSION = sprintf( "%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/ );

    @ISA     = qw();

}

#==============================================================================
# end of module preamble
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   Fcntl                           - load the C Fcntl.h defines
#   FileHandle                      - supply object methods for filehandles
#
#   Hardware::UPS::Perl::Constants  - importing Hardware::UPS::Perl constants
#   Hardware::UPS::Perl::General    - importing Hardware::UPS::Perl variables
#                                     and functions for scripts
#   Hardware::UPS::Perl::Logging    - importing Hardware::UPS::Perl methods
#                                     dealing with logfiles
#   Hardware::UPS::Perl::Utils      - importing Hardware::UPS::Perl utility
#                                     functions for packages
#
#==============================================================================

use Fcntl;
use FileHandle;

use Hardware::UPS::Perl::Constants qw(
    UPSPIDFILE
    UPSSCRIPT
);
use Hardware::UPS::Perl::General qw(
    $UPSERROR
);
use Hardware::UPS::Perl::Logging;
use Hardware::UPS::Perl::Utils qw(
    error
);

#==============================================================================
# defining user invisible package variables:
#------------------------------------------------------------------------------
# 
#
# 
#==============================================================================


#==============================================================================
# public methods:
#==============================================================================

sub new {

    # public method to construct a PID file object
    #
    # parameters: $class   (input) - class
    #             $options (input) - anonymous hash; options
    #
    # The following option keys are recognized:
    #
    #   PIDFile ($) - string; the PID file; optional
    #   Logger  ($) - Hardware::UPS::Perl::Logging object; the logger to use;
    #                 optional

    # input as hidden local variables
    my $class   = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $self    = {};       # referent to be blessed
    my $refType;            # a reference type
    my $option;             # an option
    my $logger;             # the logger object
    my $pidFile;            # the PID file

    # checking options
    $refType = ref($options);
    if ($refType ne 'HASH') {
        error("not a hash reference -- <$refType>");
    }

    # the logger; if we don't have one, we have to create our own with output
    # on STDERR
    $logger = delete $options->{Logger};

    if (!defined $logger) {
        $logger = Hardware::UPS::Perl::Logging->new()
            or return;
    }

    # the name of the PID file
    if (exists $options->{PIDFile}) {
        $pidFile = delete $options->{PIDFile};
    }
    else {
        $pidFile = UPSPIDFILE;
    }

    # checking for misspelled options
    foreach $option (keys %{$options}) {
        error("option unknown -- $option");
    }

    # blessing PID file object
    bless $self, $class;

    # initializing
    $self->{errorMessage} = q{};
    $self->_setPIDFile($pidFile);
    $self->_setPID($$);

    # initializing logging object
    $self->setLogger($logger);

    # opening file
    $self->_writePID($self->getPIDFile())
       or   do {
                $UPSERROR = $self->getErrorMessage();
                return;
            };

    # returning blessed PID file object
    return $self;

} # end of public method "new"

sub DESTROY {

    # the destructor will delete the PID file
    #
    # parameters: $self (input) - referent to a PID file object

    # input as hidden local variable
    my $self = shift;

    # delete PID file
    $self->delete();

} # end of the destructor

sub delete {

    # public method to delete a PID file
    #
    # parameters: $self (input) - referent to a PID file object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $pid;                # a PID, not necessarily ours
    my $pidFile;            # the current PID file

    # getting PID file
    $pidFile = $self->getPIDFile();

    # deleting
    if (defined $pidFile and $pidFile and -w $pidFile) {

        # getting PID from file
        #
        # defining PID file handle
        my $pid_fh = new FileHandle $pidFile, O_RDONLY;

        # getting PID
        chomp($pid = <$pid_fh>);

        # closing PID file
        undef $pid_fh;

        # deleting PID file if it does exist and does belong to this process
        if ($pid != $self->getPID() and kill(0, $pid)) {
            # another process is not dead yet
            $self->{errorMessage}
                = "another instance ".UPSSCRIPT." still running .(".$pid.")";
            return 0;
        }

        # now we can safely delete
        if (unlink($pidFile)) {
            return 1;
        }
        else {
            $self->{errorMessage} = "could not delete PID file -- $!";
            return 0;
        }

    }
    else {

        # PID file unavailable
        $self->{errorMessage} = "PID file unavailable";
        return 0;

    }

} # end of public method "delete"

sub getErrorMessage {

    # public method to get the current error message
    #
    # parameters: $self (input) - referent to a PID file object

    # input as hidden local variable
    my $self = shift;

    # getting the error message
    if (exists $self->{errorMessage}) {
        return $self->{errorMessage};
    }
    else {
        return;
    }

} # end of public method "getErrorMessage"

sub getPID {

    # public method to get the current PID
    #
    # parameters: $self (input) - referent to a PID file object

    # input as hidden local variable
    my $self = shift;

    # getting PID
    if (exists $self->{pid}) {
        return $self->{pid};
    }
    else {
        return;
    }

} # end of public method "getPID"

sub getPIDFile {

    # public method to get the current PID file
    #
    # parameters: $self (input) - referent to a PID file object

    # input as hidden local variable
    my $self = shift;

    # getting PID file currently used
    if (exists $self->{file}) {
        return $self->{file};
    }
    else {
        return;
    }

} # end of public method "getPIDFile"

sub getLogger {

    # public method to get the logger
    #
    # parameters: $self (input) - referent to an PID file object

    # input as hidden local variable
    my $self = shift;

    # getting logger
    if (exists $self->{logger}) {
        return $self->{logger};
    }
    else {
        return;
    }

} # end of public method "getLogger"

sub setLogger {

    # public method to set the logger
    #
    # parameters: $self   (input) - referent to a PID file object
    #             $logger (input) - the logging object

    # input as hidden local variables
    my $self   = shift;

    1 == @_ or error("usage: setLogger(LOGGER)");
    my $logger = shift;

    if (defined $logger) {
        my $loggerRefType = ref($logger);
        ($loggerRefType eq 'Hardware::UPS::Perl::Logging')
            or error("no logger -- <$loggerRefType>");
    }

    # getting old logger
    my $oldLogger = $self->getLogger();

    # setting logger
    $self->{logger} = $logger;

    # returning old logger
    return $oldLogger;

} # end of public method "setLogger"

#==============================================================================
# private methods:
#==============================================================================

sub _writePID {

    # private method to write a PID file
    #
    # parameters: $self    (input) - referent to a PID file object
    #             $pidFile (input) - the PID file

    # input as hidden local variables
    my $self    = shift;
    my $pidFile = shift;

    # hidden local variables
    my $pid_fh;             # the PID file filehandle         
    my $pid;                # the PID

    # getting the logger
    my $logger = $self->getLogger();

    # checking for an existing PID file of this name
    if ( -w $pidFile ) {

        # defining PID file handle
        $pid_fh = new FileHandle $pidFile, O_RDONLY
            or  $logger->fatal(
                    "cannot open PID file $pidFile for reading -- $!"
                );

        # getting PID
        chomp($pid = <$pid_fh>);

        # closing PID file
        undef $pid_fh;

        if (kill(0, $pid)) {
            # still running
            $logger->fatal(
                "there is already another instance of ".UPSSCRIPT." running -- pid = ".$pid
            );
        }
        else {
            # try to remove PID file
            if (!unlink($pidFile)) {
                $logger->fatal("cannot remove PID file $pidFile -- $!");
            }
        }

    }

    # now defining the PID file filehandle for writing PID to PID file 
    $pid_fh = new FileHandle $pidFile, O_CREAT| O_WRONLY | O_EXCL, 0644
        or $logger->fatal("cannot create PID file $pidFile -- $!");

    # writing PID to file
    $pid = $self->getPID();
    if (defined $pid) {
        print $pid_fh "$pid\n";
    }
    else {
        $self->{errorMessage} = "PID unavailable";
        return 0;
    }

    # closing PID file
    undef $pid_fh;

    return 1;

} # end of private method "_writePID"

sub _setPID {

    # private method to set the PID
    #
    # parameters: $self (input) - referent to a PID file object
    #             $pid  (input) - the PID

    # input as hidden local variables
    my $self = shift;
    my $pid  = shift; 

    # hidden local variable
    my $oldPID;         # the previous PID file

    # getting old PID
    $oldPID = $self->getPID();

    # setting PID
    $self->{pid} = $pid;

    return $oldPID;

} # end of private method "_setPID"

sub _setPIDFile {

    # private method to set the PID file
    #
    # parameters: $self    (input) - referent to a PID file object
    #             $pidFile (input) - the PID file

    # input as hidden local variables
    my $self    = shift;
    my $pidFile = shift; 

    # hidden local variable
    my $oldPIDFile;         # the previous PID file

    # getting old PID file
    $oldPIDFile = $self->getPIDFile();

    # setting PID file
    $self->{file} = $pidFile;

    return $oldPIDFile;

} # end of private method "_setPIDFile"

#==============================================================================
# package return:
#==============================================================================
1;

__END__

#==============================================================================
# embedded pod documentation:
#==============================================================================

=pod

=head1 NAME

Hardware::UPS::Perl::PID - package for OO PID files.

=head1 SYNOPSIS

    use Hardware::UPS::Perl::PID;

    $Pid = Hardware::UPS::Perl::PID->new();

    $Pid->setLogger($Logger);
    $Logger = $Pid->getLogger();

    $Pid = Hardware::UPS::Perl::PID->new({
        PIDFile =>  "/var/run/ups.pid"
        Logger  =>  $Logger,
    });

    $pid = $Pid->getPID();
    $pidFile = $Pid->getPIDFile();

    $Pid->delete();

    undef $Pid;                         # deletes PID file, if possible

=head1 DESCRIPTION

B<Hardware::UPS::Perl::PID> provides methods dealing with PID files.

=head1 LIST OF METHODS

=head2 new

=over 4

=item B<Name:>

new - creates a new PID file object

=item B<Synopsis:>

	$Logger = Hardware::UPS::Perl::Logging->new();
	$Pid    = Hardware::UPS::Perl::PID->new();

	$Pid    = Hardware::UPS::Perl::PID->new({
	    PIDFile => $file,
	    Logger  => $Logger,
    });

	undef $Pid;                    # deletes the PID file

=item B<Description:>

B<new> initializes a PID file object by writing the PID of the current process
to the PID file. The PID file will be deleted, when the object is destroyed.
Thus, the object created must be globally declared, otherwise the
PID file will vanish when leaving the local context.

B<new> expects the options as an anonymous hash.

=item B<Arguments:>

=over 4

=item C<< PIDFile   => $file >>

optional; the PID file; if not specified, the default PID file F<UPSPIDFILE>
supplied by package B<Hardware::UPS::Perl::Constants> will be used.

=item C<< Logger    => $logger >>

optional; a B<Hardware::UPS::Perl::Logging> object; defines a logger; if not
specified, a logger sending its output to STDERR is created.

=back

=item B<See Also:>

L<"delete">,
L<"getPID">,
L<"getPIDFile">,
L<"getLogger">,
L<"setLogger">

=back

=head2 setLogger

=over 4

=item B<Name:>

setLogger - sets the logger to use

=item B<Synopsis:>

	$Pid    = Hardware::UPS::Perl::PID->new();

	$Logger = Hardware::UPS::Perl::Logging->new();

	$Pid->setLogger($logger);

=item B<Description:>

B<setLogger> sets the logger object used for logging. B<setLogger> returns
the previous logger used.

=item B<Arguments:>

=over 4

=item C<< $logger >>

required; a B<Hardware::UPS::Perl:Logging> object; defines the logger for
logging.

=back

=item B<See Also:>

L<"new">,
L<"getLogger">

=back

=head2 getLogger

=over 4

=item B<Name:>

getLogger - gets the current logger for logging

=item B<Synopsis:>

	$Pid    = Hardware::UPS::Perl::PID->new();

	$logger = $Pid->getLogger();

=item B<Description:>

B<getLogger> returns the current logger, a Hardware::UPS::Perl::Logging object
used for logging, if defined, undef otherwise.

=item B<See Also:>

L<"new">,
L<"setLogger">

=back

=head2 delete

=over 4

=item B<Name:>

delete - deletes the PID file currently used

=item B<Synopsis:>

	$Pid = Hardware::UPS::Perl::PID->new();

	$Pid->delete();
	undef $Pid;

=item B<Description:>

B<delete> removes the PID file from the disk. This method will be called
automatically, when the object is destroyed. Thus, the PID file object created
by method B<new> must be globally declared, otherwise the PID file will vanish
when leaving the local context.

=item B<See Also:>

L<"new">,
L<"getPID">,
L<"getPIDFile">

=back

=head2 getErrorMessage

=over 4

=item B<Name:>

getErrorMessage - gets the internal error message

=item B<Synopsis:>

	$Pid = Hardware::UPS::Perl::PID->new();

	unless ( $Pid->delete() ) {
	    print STDERR $Pid->getErrorMessage(), "\n";
	    exit 0;
	}

=item B<Description:>

B<getErrorMessage> returns the internal error message, if something went
wrong.

=back

=head2 getPID

=over 4

=item B<Name:>

getPID - gets the current PID file

=item B<Synopsis:>

	$Pid = Hardware::UPS::Perl::PID->new();

	$pid = $Pid->getPID();

=item B<Description:>

B<getPID> returns the current PID if available, undef otherwise.

=item B<See Also:>

L<"new">,
L<"getPIDFile">

=back

=head2 getPIDFile

=over 4

=item B<Name:>

getPIDFile - gets the current PID file

=item B<Synopsis:>

	$Pid = Hardware::UPS::Perl::PID->new();

	$pidFile = $Pid->getPIDFile();

=item B<Description:>

B<getPIDFile> returns the current PID file if available, undef otherwise.

=item B<See Also:>

L<"new">,
L<"getPID">

=back

=head1 SEE ALSO

Fcntl(3pm),
FileHandle(3pm),
Hardware::UPS::Perl::Connection(3pm),
Hardware::UPS::Perl::Connection::Net(3pm),
Hardware::UPS::Perl::Connection::Serial(3pm),
Hardware::UPS::Perl::Constants(3pm),
Hardware::UPS::Perl::Driver(3pm),
Hardware::UPS::Perl::Driver::Megatec(3pm),
Hardware::UPS::Perl::General(3pm),
Hardware::UPS::Perl::Logging(3pm),
Hardware::UPS::Perl::Utils(3pm) 

=head1 NOTES

B<Hardware::UPS::Perl::PID> was inspired by many Perl modules dealing with PID
files. Alas, either those modules are not included in a standard B<SuSE 10.1>
Linux distribution, or they did not quite fit to my needs.

B<Hardware::UPS::Perl::PID> was developed using B<perl 5.8.8> on a B<SuSE
10.1> Linux distribution.

=head1 BUGS

There are plenty of them for sure. Maybe the embedded pod documentation has to
be revised a little bit.

Suggestions to improve B<Hardware::UPS::Perl::PID> are welcome, though due
to the lack of time it might take a while to incorporate them.

=head1 AUTHOR

Copyright (c) 2007 by Christian Reile, E<lt>Christian.Reile@t-online.deE<gt>.
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. For further licensing
details, please see the file COPYING in the distribution.

=cut
