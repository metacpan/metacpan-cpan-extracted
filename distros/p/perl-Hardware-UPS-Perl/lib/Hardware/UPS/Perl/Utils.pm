package Hardware::UPS::Perl::Utils;

#==============================================================================
# package description:
#==============================================================================
# This package supplies a set of usefull functions used in packages dealing
# with an UPS. For a detailed description see the pod documentation
# included at the end of this file.
#
# List of functions:
# ------------------
#   configure               - configures options
#   error                   - dealing with errors
#   warning                 - dealing with warnings
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
# Revision        : $Revision: 1.8 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/14 09:37:26 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
#   $Log: Utils.pm,v $
#   Revision 1.8  2007/04/14 09:37:26  creile
#   documentation update.
#
#   Revision 1.7  2007/04/07 15:14:45  creile
#   adaptations to "best practices" style;
#   update of documentation.
#
#   Revision 1.6  2007/03/03 21:15:53  creile
#   typing error removed.
#
#   Revision 1.5  2007/02/05 20:37:31  creile
#   pod documentation revised.
#
#   Revision 1.4  2007/02/04 14:01:32  creile
#   bug fix in pod documentation.
#
#   Revision 1.3  2007/02/03 15:36:03  creile
#   package Hardware::UPS::Perl::General removed, as we
#   use OO PID files now;
#   update of pod documentation.
#
#   Revision 1.2  2007/01/28 05:24:05  creile
#   bug fix concerning pod documentation.
#
#   Revision 1.1  2007/01/28 04:17:41  creile
#   initial version.
#
#
#==============================================================================

#==============================================================================
# module preamble:
#==============================================================================

use strict;

BEGIN {

    use Exporter ();
    use vars     qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    $VERSION     = sprintf( "%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/ );

    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw(
        &configure
        &error
        &warning
    );
    %EXPORT_TAGS = qw();

}

#==============================================================================
# end of module preamble
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   Carp                            - warn of errors (from perspective of
#                                     caller)
#
#==============================================================================

use Carp;

#==============================================================================
# public functions:
#==============================================================================

sub configure {

    # subroutine to configure the connection
    #
    # parameters: $actions   (input) - anonymous hash; the action table
    #             $arguments (input) - anonymous array; arguments supplied

    # input as hidden local variables
    my ($actions, $arguments) = @_ ;

    # hidden local variables
    my $opt;                # current option
    my $arg;                # current argument
    my @return;             # return list of  of builtin Perl function `grep'
    my @options;            # the option list

    # processing options
    @options = keys %{$actions};

    PROCESS_OPTIONS:
    while (@{$arguments}) {

        $opt    = shift(@{$arguments});
        @return = grep(/^$opt/, @options);

        if (1 != @return) {
            error("unknown or ambiguous option -- $opt");
        }

        $arg    = shift(@{$arguments});
        $actions->{$return[0]}->($arg);
    }

} # end of subroutine "configure"

sub error {

    # subroutine to display internal error messages
    #
    # parameters: $errorMessage (input) - error message to be displayed

    # input as hidden local variable
    my $errorMessage = shift;

    # hidden local variables
    my $i = 1;                      # calling level
    my $method = (caller($i))[3];   # calling public method

    # determine calling subroutine
    METHOD:
    while ($method =~ /::_/) {
        $method = (caller(++$i))[3];
    }

    # displaying error message and die
    croak("$method: $errorMessage");

} # end of subroutine "error"

sub warning {

    # subroutine to display internal warning messages
    #
    # parameters: $warningMessage (input) - warning message to be displayed

    # input as hidden local variable
    my $warningMessage = shift;

    # hidden local variables
    my $i      = 1;                 # calling level
    my $method = (caller($i))[3];   # calling public method

    # determine calling subroutine
    METHOD:
    while ($method =~ /::_/) {
        $method = (caller(++$i))[3];
    }

    # displaying error message and continue
    carp("$method: $warningMessage");

} # end of subroutine "warning"

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

Hardware::UPS::Perl::Utils - utility functions for packages dealing with an UPS

=head1 SYNOPSIS

    use Hardware::UPS::Perl::Utils qw(
       configure error warning
    );

=head1 DESCRIPTION

B<Hardware::UPS::Perl::Utils> provides functions for packages dealing with an
UPS.

=head1 LIST OF FUNCTIONS

=head2 configure

=over 4

=item B<Name:>

configure - processes arguments

=item B<Synopsis:>

	&configure($actions, \@arguments);

=item B<Description:>

B<configure> processes arguments C<@arguments> using the action table
C<$actions > being an anonymous hash of anonymous subroutines.

=item B<Arguments:>

=over 4

=item C<< $actions >>

the action table; supplies a set of anonymous subroutines to process the
options.

=item C<< $arguments >>

anonymous array of arguments.

=back

=back

=head2 error

=over 4

=item B<Name:>

error - displays internal error messages and dies

=item B<Synopsis:>

	&error($errorMessage);

=item B<Description:>

B<error> displays the error message $errorMessage with respect to the calling
method and dies using C<Carp::croak()>.

=item B<Arguments:>

=over 4

=item C<< $errorMessage >>

string; the error message.

=back

=item B<See Also:>

L<"warning">

=back

=head2 warning

=over 4

=item B<Name:>

warning - displays internal error messages

=item B<Synopsis:>

	&warning($warningMessage);

=item B<Description:>

B<warning> displays the error message $warningMessage with respect to the
calling method using C<Carp::carp()>.

=item B<Arguments:>

=over 4

=item C<< $warningMessage >>

string; the warning message.

=back

=item B<See Also:>

L<"error">

=back

=head1 SEE ALSO

Carp(3pm),
Hardware::UPS::Perl::Connection(3pm),
Hardware::UPS::Perl::Connection::Net(3pm),
Hardware::UPS::Perl::Connection::Serial(3pm)
Hardware::UPS::Perl::Constants(3pm),
Hardware::UPS::Perl::Driver(3pm),
Hardware::UPS::Perl::Driver::Megatec(3pm),
Hardware::UPS::Perl::General(3pm),
Hardware::UPS::Perl::Logging(3pm),
Hardware::UPS::Perl::PID(3pm),

=head1 NOTES

B<Hardware::UPS::Perl::Utils> was inspired by the B<usv.pl> program by Bernd
Holzhauer, E<lt>www.cc-c.deE<gt>. The latest version of this program can be
obtained from

    http://www.cc-c.de/german/linux/linux_usv.php

Another great resource was the B<Network UPS Tools> site, which can be found
at

    http://www.networkupstools.org

B<Hardware::UPS::Perl::Utils> was developed using B<perl 5.8.8> on a B<SuSE
10.1> Linux distribution.

=head1 BUGS

There are plenty of them for sure. Maybe the embedded pod documentation has to
be revised a little bit.

Suggestions to improve B<Hardware::UPS::Perl::Utils> are welcome, though due
to the lack of time it might take a while to incorporate them.

=head1 AUTHOR

Copyright (c) 2007 by Christian Reile, E<lt>Christian.Reile@t-online.deE<gt>.
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. For further licensing
details, please see the file COPYING in the distribution.

=cut
