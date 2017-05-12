package VUser::Firewall;
use warnings;
use strict;

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: Firewall.pm,v 1.1 2006/01/04 18:45:40 perlstalker Exp $

our $VERSION = '0.1.0';

our $c_sec = 'Extension Firewall';
our %meta = (
	     'network' => VUser::Meta->new('name' => 'network',
					   'type' => 'string',
					   'description' => 'Network to work with (a.b.c.d/mask)'),
	     'port' => VUser::Meta->new('name' => 'port',
					'type' => 'int',
					'description' => 'TCP/UDP port to work with'),
	     'protocol' => VUser::Meta->new('name' => 'protocol',
					    'type' => 'string',
					    'description' => 'udp or tcp'),
	     'host' => VUser::Meta->new('name' => 'host',
					'type' => 'string',
					'description' => 'Firewall host')
	     );

$meta{'source'} = $meta{'network'}->new(name => 'source');
$meta{'destination'} = $meta{'network'}->new(name => 'destination');
$meta{'sport'} = $meta{'port'}->new(name => 'sport');
$meta{'dport'} = $meta{'port'}->new(name => 'dport');

my $log;

sub init
{
    my $eh = shift;
    my %cfg = @_;

    $log = $main::log;

    # firewall
    $eh->register_keyword('firewall', 'Manage firewalls');

    # firewall-block
    $eh->register_action('firewall', 'block', 'Block a network and/or a port');
    $eh->register_option('firewall', 'block', $meta{'source'});
    $eh->register_option('firewall', 'block', $meta{'sport'});
    $eh->register_option('firewall', 'block', $meta{'destination'});
    $eh->register_option('firewall', 'block', $meta{'dport'});
    $eh->register_option('firewall', 'block', $meta{'protocol'});

    # firewall-unblock
    $eh->register_action('firewall', 'unblock', 'Unblock a previously blocked network and/or port');
    $eh->register_option('firewall', 'unblock', $meta{'source'});
    $eh->register_option('firewall', 'unblock', $meta{'sport'});
    $eh->register_option('firewall', 'unblock', $meta{'destination'});
    $eh->register_option('firewall', 'unblock', $meta{'dport'});
    $eh->register_option('firewall', 'unblock', $meta{'protocol'});

    # firewall-allow
    $eh->register_action('firewall', 'allow', 'Allow a network and/or port');
    $eh->register_option('firewall', 'allow', $meta{'source'});
    $eh->register_option('firewall', 'allow', $meta{'sport'});
    $eh->register_option('firewall', 'allow', $meta{'destination'});
    $eh->register_option('firewall', 'allow', $meta{'dport'});
    $eh->register_option('firewall', 'allow', $meta{'protocol'});

    # firewall-unallow
    $eh->register_action('firewall', 'unallow', 'Stop allowing an allowed network and/or port');
    $eh->register_option('firewall', 'unallow', $meta{'source'});
    $eh->register_option('firewall', 'unallow', $meta{'sport'});
    $eh->register_option('firewall', 'unallow', $meta{'destination'});
    $eh->register_option('firewall', 'unallow', $meta{'dport'});
    $eh->register_option('firewall', 'unallow', $meta{'protocol'});

    # firewall-restart
    $eh->register_action('firewall', 'restart', 'Restart the firewall(s)');

    # firewall-flush
    $eh->register_action('firewall', 'flush', 'Flush the firewall rules. Use with care');
}

sub meta { return %meta; }
sub c_sec { return $c_sec; }

1;

__END__

=head1 NAME

VUser::Firewall - vuser plugin to manage firewalls

=head1 DESCRIPTION

VUser::Firewall is an extension to vuser that allows one to manage simple
firewall rules. VUser::Firewall is not meant to be used by itself but,
instead, registers the basic keywords, actions and options that other
VUser::Firewall::* extentions will use. Other options may be added by
firewall specific extensions.

=head1 CONFIGURATION

 [Extension Firewall]
 # Automatically restart the firewall after each command
 auto restart = no

Any Firewall::* extensions will automatically load I<Firewall>. There is no
need to add I<Firewall> to I<vuser|extensions>.
Other VUser::Firewall::* extensions may have their own configurations.

=head1 META SHORTCUTS

VUser::Firewall provides a few VUser::Meta objects that may be used by
other firewall extensions. The safest way to access them is to call
VUser::Firewall::meta() from within the extension's init() function.

Provided keys: network, port, protocol, host, source, destination, sport, dport

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
