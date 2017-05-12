package PerlConsole::Commands;
# Copyright © 2007 Alexis Sukrieh
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

use strict;
use warnings;

# All the internal commands of the Perl Console are defined here.

my $help = {
    preferences => "Display all the avaialbe preferences and how to change them.",
    quit => "Quit the console.",
};

# display the help message

# returns 1 if the string is an internal command
sub isInternalCommand($$)
{
    my ($class, $code) = @_;
    return 0 unless $code;
    chomp($code);
    return $code =~ /^\s*:(\S+)\s*/;
}

# Execute the internal command given
sub execute($$$)
{
    my ($class, $console, $code) = @_;

    # preference : output
    if ($code =~ /^\s*:set/) {
        if ($code =~ /^\s*:set\s+(\S+)\s*=\s*(\S+)/) {
            my ($pref, $val) = ($1, $2);
            if ($pref eq "output") {
                $console->setOutput($val);
            }
            else {
                $console->setPreference($pref, $val);
            }
        }
        else {
            $console->error("invalid syntax for setting a preference, see :help preferences");
        }
    }

    # The main help page
    elsif ($code =~ /^\s*:help\s*$/) {
        $console->message(PerlConsole::Commands->help($console));
    }
    
    # The help page of a specified topic
    elsif ($code =~ /^\s*:help\s+(\S+)/) {
        $console->message(PerlConsole::Commands->help($console, $1));
    }
    
    # display the logs stack
    elsif ($code =~ /^\s*:logs/) {
        foreach my $log (@{$console->getLogs}) {
            $console->message($log);
        }
    }
    
    # at this point, unrecognized command
    else {
        $console->error("no such command");
    }
    return 1;
}

# Returns an help message, on a topic 
sub help
{
    my ($class, $console, $topic) = @_;
    if (! defined $topic) {
        return "The following help topics are available:\n".
            join("\n- ", keys%{$help});
    }
    else {
        # preferences have automated online help
        if ($topic =~ /preferences/) {
            return $console->{'prefs'}->help();
        }
        elsif (grep /^$topic$/, $console->{'prefs'}->getPreferences()) {
            return $console->{'prefs'}->help($topic);
        }
        elsif (defined $help->{$topic}) {
            return $help->{$topic};
        }
        else {
            return "No such help topic: $topic";
        }
    }
}

# END
1;
