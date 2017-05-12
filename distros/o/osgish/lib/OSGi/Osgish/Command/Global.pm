#!/usr/bin/perl

package OSGi::Osgish::Command::Global;
use strict;
use vars qw(@ISA);
use Term::ANSIColor qw(:constants);
use Term::Clui;

@ISA = qw(OSGi::Osgish::Command);

=head1 NAME 

OSGi::Osgish::Command::Global - Globally available commands

=head1 DESCRIPTION

=head1 COMMANDS

=over

=cut 



sub name { "global" }

sub global_commands {
    my $self = shift;
    my $osgi = $self->agent;
    
    return 
        {
         "error" => {
                     desc => "Show last error (if any)",
                     proc => $self->cmd_last_error,
                     doc => <<EOT
Show the last error, if any occured. Including all
stacktraces returned by the server.
EOT
                    },
         "help" => {
                    desc => "Print online help",
                    args => sub { shift->help_args(undef, @_); },
                    method => sub { shift->help_call(undef, @_); },
                    doc => <<EOT,
help [<command>]
h [<command>]

Print online help. Without option, show a summary. With 
option, show specific help for command <command>.
EOT
                   },
         "h" => { alias => "help", exclude_from_completion=>1},
         "history" => { 
                       desc => "Command History",
                       doc => <<EOT,

history [-c] [-d <num>]

Specify a number to list the last N lines of history

Options:
   -c      : Clear the command history
   -d <num> : Delete a single item <num>
EOT
                       args => "[-c] [-d] [number]",
                       method => sub { shift->history_call(@_) },                       
                      },
         "quit" => {
                    desc => "Quit",
                    maxargs => 0,
                    method => sub { shift->exit_requested(1); },
                    doc => <<EOT,
Quit osgish.
EOT
                   },
         "q" => { alias => 'quit', exclude_from_completion => 1 },
         $osgi ? ("shutdown" => {
                                 desc => "Shutdown server",
                                 proc => $self->cmd_shutdown,
                                },
                  "restart" => {
                                desc => "Restart server",
                                proc => $self->cmd_restart
                               }
                 ) : ()
        };
}

# Shutdown a server
sub cmd_shutdown {
    my $self = shift;
    return sub {
        my $osgish = $self->osgish;
        my $osgi = $osgish->agent;
        unless ($osgi) {
            print "Not connected to a server\n";
            return;
        }
        my ($yellow,$reset) = $osgish->color("host",RESET);
        my $server = $osgish->server;
        my $answer = &choose("Really shutdown " . $yellow . $server . $reset . " ?","yes","no");
        if ($answer eq "yes") {
            $osgi->shutdown;
            $osgish->agent(undef);
            $osgish->commands->reset_stack;
        } else {
            print "Shutdown of ". $yellow . $server . $reset . " cancelled\n";
        }
    }
}

# Restart the server's framework
sub cmd_restart {
    my $self = shift;
    return sub {
        my $osgish = $self->osgish;
        my $osgi = $osgish->agent;
        unless ($osgi) {
            print "Not connected to a server\n";
            return;
        }
        my ($yellow,$reset) = $osgish->color("host",RESET);
        my $server = $osgish->server;
        my $answer = &choose("Really restart " . $yellow . $server . $reset . " ?","yes","no");
        if ($answer eq "yes") {
            $osgi->restart;
        } else {
            print "Restart of ". $yellow . $server . $reset . " cancelled\n";
        }
    }
}


sub cmd_last_error {
    my $self = shift;
    return sub {
        my $osgi = $self->osgish->agent;
        my $txt = $self->osgish->last_error;
        if ($txt) { 
            chomp $txt;
            print "$txt\n";
        } else {
            print "No errors\n";
        }
    }
}

=head1 LICENSE

This file is part of osgish.

Osgish is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

osgish is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with osgish.  If not, see <http://www.gnu.org/licenses/>.

A commercial license is available as well. Please contact roland@cpan.org for
further details.

=head1 PROFESSIONAL SERVICES

Just in case you need professional support for this module (or JMX or OSGi in
general), you might want to have a look at www.consol.com Contact
roland.huss@consol.de for further information (or use the contact form at
http://www.consol.com/contact/)

=head1 AUTHOR

roland@cpan.org

=cut

1;

