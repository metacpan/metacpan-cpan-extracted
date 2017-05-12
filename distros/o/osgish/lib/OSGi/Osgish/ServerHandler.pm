#!/usr/bin/perl
package OSGi::Osgish::ServerHandler;

use strict;
use Term::ANSIColor qw(:constants);
use OSGi::Osgish::Agent;
use Data::Dumper;

=head1 NAME 

OSGi::Osgish::ServerHandler - Handler for coordinating the server access

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

sub new { 
    my $class = shift;
    my $osgish = shift || die "No osgish object given";
    my $self = {
                osgish => $osgish
               };
    bless $self,(ref($class) || $class);
    my $server = $self->_init_server_list($osgish->{initial_server},$osgish);
    $self->connect_to_server($server) if $server;
    return $self;
}

sub connect_to_server {
    my $self = shift;    
    my $server = shift;
    my $name = shift;

    my $server_map = $self->{server_map};
    my $s = $server_map->{$server};
    unless ($s) {
        unless ($server =~ m|^\w+://[\w:]+/|) {
            print "Invalid URL $server\n";
            return;
        }
        $name ||= $self->_prepare_server_name($server);
        my $entry = { name => $name, url => $server };
        push @{$self->{server_list}},$entry;
        $self->{server_map}->{$name} = $entry;
        $s = $entry;
    }
    my $osgish = $self->{osgish};
    my ($old_server,$old_agent) = ($self->server,$osgish->agent);
    eval { 
        my $agent = $self->_create_agent($s->{name}) || die "Unknown $server (not an alias nor a proper URL).\n";;
        $agent->init();
        $osgish->agent($agent);
        $self->{server} = $s->{name};
        $osgish->{last_error} = undef;
    };
    if ($@) {
        if ($osgish->agent && $osgish->agent->last_error) {
            $osgish->{last_error} = $osgish->agent->last_error;
        } else {
            $osgish->{last_error} = $@;
        }
        $self->{server} = $old_server;
        $osgish->agent($old_agent);
        die $@;
    }   
}

sub server {
    return shift->{server};
}

sub list {
    my $self = shift;
    return $self->{server_list};
}


sub _init_server_list {
    my $self = shift;
    my $server = shift;
    my $context = shift;
    my $config = $context->{config};
    my $args = $context->{args};
    my @servers = map { { name => $_->{name}, url => $_->{url}, from_config => 1 } } @{$config->get_servers};
    my $ret_server;
    if ($server) {
        my $config_s = $config->get_server_config($server);
        if ($config_s) {
            my $found = 0;
            my $i = 0;
            my $entry = { name => $server, url => $config_s->{url}, from_config => 1 } ;
            for my $s (@servers) {
                if ($s->{name} eq $server) {
                    $servers[$i] = $entry;
                    $found = 1;                 
                    last;
                }
                $i++;
            } 
            push @servers,$entry unless $found;
            $ret_server = $config_s->{name};
        } else {
            die "Invalid URL ",$server,"\n" unless ($server =~ m|^\w+://|);
            my $name = $self->_prepare_server_name($server);
            push @servers,{ name => $name, url => $server };
            $ret_server = $name;
        }
    }
    $self->{server_list} = \@servers;
    $self->{server_map} = { map { $_->{name} => $_ } @servers };
    return $ret_server;
}

# ========================================================================================= 

sub _prepare_server_name {
    my $self = shift;
    my $url = shift;
    if ($url =~ m|^\w+://([^/]+)/?|) { 
        return $1;
    } else {
        return $url;
    }
}

sub _create_agent {
    my $self = shift;
    my $server = shift;
    return undef unless $server;
    # TODO: j4p_args, jmx_config;
    my $osgish = $self->{osgish};
    my $j4p_args = $self->_j4p_args($osgish->{args} || {});
    my $jmx_config = $osgish->{config} || {};
    my $sc = $self->{server_map}->{$server};
    return undef unless $sc;
    if ($sc->{from_config}) {
        return new OSGi::Osgish::Agent({ %$j4p_args, server => $server, config => $jmx_config});
    } else {
        return new OSGi::Osgish::Agent({ %$j4p_args, url => $sc->{url}});
    }
}

sub _j4p_args {
    my $self = shift;
    my $o = shift;
    my $ret = { };
    
    for my $arg (qw(user password)) {
        if (defined($o->{$arg})) {
            $ret->{$arg} = $o->{$arg};
        }
    }
    
    if (defined($o->{proxy})) {
        my $proxy = {};
        $proxy->{url} = $o->{proxy};
        for my $k (qw(proxy-user proxy-password)) {
            $proxy->{$k} = defined($o->{$k}) if $o->{$k};
        }
        $ret->{proxy} = $proxy;
    }        
    if (defined($o->{target})) {
        $ret->{target} = {
                          url => $o->{target},
                          $o->{'target-user'} ? (user => $o->{'target-user'}) : (),
                          $o->{'target-password'} ? (password => $o->{'target-password'}) : (),
                         };
    }
    return $ret;
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

