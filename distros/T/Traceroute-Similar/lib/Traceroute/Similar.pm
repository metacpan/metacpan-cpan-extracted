#!/usr/bin/env perl
#
# vim:ts=4:sw=4:expandtab

package Traceroute::Similar;

use 5.000000;
use strict;
use warnings;
use Carp;

our $VERSION = '0.18';

=head1 NAME

Traceroute::Similar - calculate common route for a bunch of hosts

=head1 SYNOPSIS

  use Traceroute::Similar;
  my $ts = Traceroute::Similar->new();
  print $ts->get_last_common_hop('host1.com', 'host2.org');

=head1 DESCRIPTION

This module calculates the furthest common hop from a list of host. The backend
will be Net::Traceroute:PurePerl or Net::Traceroute or system
tracerroute (which may require root or sudo permissions).

=head1 CONSTRUCTOR

=over 4

=item new ( [ARGS] )

Creates an C<Traceroute::Similar> object. All arguments are optional.

    backend                   'Net::Traceroute' or 'Net::Traceroute::PurePerl'
    verbose                   verbose mode

=back

=cut

########################################
sub new {
    my($class,%options) = @_;
    my $self = {
                    "verbose"   => 0,
                    "backend"   => undef,
               };
    bless $self, $class;

    $self->{'verbose'} = $options{'verbose'} if defined $options{'verbose'};

    # which backend do we use?
    $self->{'backend'} = $options{'backend'}         if defined $options{'backend'};
    $self->{'backend'} = $self->_detect_backend() unless defined $self->{'backend'};

    if(!defined $self->{'backend'}) {
        carp("No backend found, please install one of Net::Traceroute or Net::Traceroute::PurePerl. Or make sure your traceroute binary is in your path.");
    }

    return $self;
}


########################################

=head1 METHODS

=over 4

=item get_backend ( )

returns the used backend or undef if none found

=cut

sub get_backend {
    my $self  = shift;
    return($self->{'backend'});
}

=item get_last_common_hop ( host 1, host 2, [ host x...] )

return the last hop which is part of all given hosts

=cut

sub get_last_common_hop {
    my $self  = shift;
    return if !defined $self->{'backend'};
    my $routes;
    while(my $host = shift) {
        $routes->{$host} = $self->_get_route_for_host($host);
    }

    return($self->_calculate_last_common_hop($routes))
}


########################################

=item get_common_hops ( host 1, host 2, [ host x...] )

return an array ref of the common hops from this list of hosts

=cut

sub get_common_hops {
    my $self  = shift;
    return if !defined $self->{'backend'};
    my $routes;
    while(my $host = shift) {
        $routes->{$host} = $self->_get_route_for_host($host);
    }

    return($self->_calculate_common_hops($routes))
}


########################################
# internal subs
########################################
sub _calculate_last_common_hop {
    my $self   = shift;
    my $routes = shift;
    my $last_common_addr;
    my $common = $self->_calculate_common_hops($routes);

    if(defined $common and scalar @{$common} >= 1) {
        $last_common_addr = pop @{$common};
    }

    return($last_common_addr);
}

########################################
sub _calculate_common_hops {
    my $self   = shift;
    my $routes = shift;
    my $common;

    return if !defined $routes;

    my @hostnames = keys %{$routes};
    if(scalar @hostnames <= 1) { croak("need at least 2 hosts to calculate similiar routes"); }

    my $last_common_addr = undef;
    for(my $x = 0; $x <= scalar(@{$routes->{$hostnames[0]}}); $x++) {
        my $current_hop = $routes->{$hostnames[0]}->[$x]->{'addr'};
        for my $host (@hostnames) {
            if(!defined $routes->{$host}->[$x]->{'addr'} or $current_hop ne $routes->{$host}->[$x]->{'addr'}) {
                return $common;
            }
        }
        $last_common_addr = $current_hop;
        push @{$common}, $last_common_addr;
    }

    return($common);
}

########################################
sub _get_route_for_host {
    my $self   = shift;
    my $host   = shift;
    my $routes = [];

    print "DEBUG: _get_route_for_host('".$host."')\n" if $self->{'verbose'};

    if($self->{'backend'} eq 'traceroute') {
        my $cmd = "traceroute $host";
        print "DEBUG: cmd: $cmd\n" if $self->{'verbose'};
        open(my $ph, "-|", "$cmd 2>&1") or confess("cmd failed: $!");
        my $output;
        while(<$ph>) {
            my $line = $_;
            $output .= $line;
            print "DEBUG: traceroute: $line" if $self->{'verbose'};
        }
        close($ph);
        my $rt = $?>>8;
        print "DEBUG: return code from traceroute: $rt\n" if $self->{'verbose'};

        if($rt == 0) {
            $routes = $self->_extract_routes_from_traceroute($output);
        }
    }
    elsif($self->{'backend'} eq 'Net::Traceroute') {
        my $tr = Net::Traceroute->new(host=> $host);
        my $hops = $tr->hops;
        my $last_hop;
        for(my $x = 0; $x <= $hops; $x++) {
            my $cur_hop = $tr->hop_query_host($x, 0);
            if(defined $cur_hop and (!defined $last_hop or $last_hop ne $cur_hop)) {
                push @{$routes}, { 'addr' => $cur_hop, 'name' => '' };
                $last_hop = $cur_hop;
            }
        }
    }
    elsif($self->{'backend'} eq 'Net::Traceroute::PurePerl') {
        my $tr = new Net::Traceroute::PurePerl( host => $host );
        $tr->traceroute;
        my $hops = $tr->hops;
        my $last_hop;
        for(my $x = 0; $x <= $hops; $x++) {
            my $cur_hop = $tr->hop_query_host($x, 0);
            if(defined $cur_hop and (!defined $last_hop or $last_hop ne $cur_hop)) {
                push @{$routes}, { 'addr' => $cur_hop, 'name' => '' };
                $last_hop = $cur_hop;
            }
        }
    }
    else {
        carp("unknown backend: ".$self->{'backend'});
    }

    return $routes;
}

########################################
sub _extract_routes_from_traceroute {
    my $self   = shift;
    my $output = shift;
    my @routes;

    for my $line (split /\n/xm, $output) {
        if($line =~ m/(\d+)\s+(.*?)\s+\((\d+\.\d+\.\d+\.\d+)\)/xm) {
            push @routes, { 'addr' => $3, 'name' => $2 };
        }
    }

    return(\@routes);
}

########################################
sub _detect_backend {
    my $self = shift;

    print "DEBUG: detecting backend\n" if $self->{'verbose'};

    # try to load Net::Traceroute:PurePerl
    eval {
        require Net::Traceroute::PurePerl;
        print "DEBUG: using Net::Traceroute::PurePerl as backend\n" if $self->{'verbose'};
        return("Net::Traceroute::PurePerl");
    };

    # try to load Net::Traceroute
    eval {
        require Net::Traceroute;
        print "DEBUG: using Net::Traceroute as backend\n" if $self->{'verbose'};
        return("Net::Traceroute");
    };

    # try to use traceroute
    chomp(my $traceroute_bin = qx{which traceroute});
    if(defined $traceroute_bin and $traceroute_bin ne '' and -x $traceroute_bin) {
        print "DEBUG: found traceroute in path: $traceroute_bin\n" if $self->{'verbose'};
        return('traceroute');
    }

    return;
}

########################################

1;

=head1 AUTHOR

Sven Nierlein, E<lt>nierlein@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Sven Nierlein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__END__
