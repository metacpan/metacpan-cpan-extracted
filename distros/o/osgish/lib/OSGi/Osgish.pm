#!/usr/bin/perl

package OSGi::Osgish;

use strict;
use Term::ANSIColor qw(:constants);
use OSGi::Osgish::Shell;
use OSGi::Osgish::ServerHandler;
use OSGi::Osgish::CompletionHandler;
use OSGi::Osgish::CommandHandler;
use Data::Dumper;
use vars qw($VERSION);

$VERSION = "0.3.1";

=head1 NAME 

OSGi::Osgish - Main osgish object 

=head1 DESCRIPTION

This object is pushed to commands and allows access to all relevant
informations shared between commands. A command should consult the 
osgish object when performing its operation for contacting the OSGi server. 
The osgish object gets updated in the background e.g. when the server changes. 

=head1 METHODS

=over

=item $osgish = new OSGi::Osgish(agent => $agent,...)


=cut

sub new { 
    my $class = shift;
    my $self = ref($_[0]) eq "HASH" ? $_[0] : {  @_ };
    bless $self,(ref($class) || $class);
    $self->_init();
    return $self;
}


=item $agent = $osgish->agent

Access to the agent object for accessing to the connected server. If there 
is no connected server, this methods returns C<undef>

=cut 

sub agent {
    my ($self,$val) = @_;
    my $ret = $self->{agent};
    if ($#_ > 0) {
        $self->{agent} = $val;
    }
    return $ret;
}

sub complete {
    return shift->{complete};
}

sub commands {
    return shift->{commands};
}

sub servers {
    return shift->{servers};
}

sub server {
    return shift->{servers}->{server};
}

sub color { 
    return shift->{shell}->color(@_);
}

sub run {
    my $self = shift;
    $self->{shell}->run;
}

sub last_error {
    my $self = shift;
    my $osgi = $self->agent;
    return $osgi->last_error if $osgi && $osgi->last_error;
    return $self->{last_error};
}

sub _init {
    my $self = shift;
    $self->{complete} = new OSGi::Osgish::CompletionHandler($self);
    $self->{servers} = new OSGi::Osgish::ServerHandler($self);
    my $shell = $self->_create_shell;
    $self->{shell} = $shell;
    my $no_color_prompt = $shell->readline ne "Term::ReadLine::Gnu";
    $self->{commands} = new OSGi::Osgish::CommandHandler($self,$self->{shell},no_color_prompt => $no_color_prompt);
}

sub _create_shell {
    my $self = shift;
    my $use_color;
    if (exists $self->{args}->{color}) {
        $use_color = $self->{args}->{color};
    } elsif (exists $self->{config}->{use_color}) {
        $use_color = $self->{config}->{use_color};
    } else {
        $use_color = "yes";
    }    
    return new OSGi::Osgish::Shell(use_color => $use_color =~ /(yes|true|on)$/);
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


1;



