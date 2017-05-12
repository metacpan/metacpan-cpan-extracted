package Wiki::Toolkit::Plugin::Ping;

use strict;
use warnings;

use vars qw( @ISA $VERSION );

use Wiki::Toolkit::Plugin;
use LWP;
use LWP::UserAgent;

@ISA = qw( Wiki::Toolkit::Plugin );
$VERSION = '0.03';


# Set things up
sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;

    # Get list of services
    unless($args{services}) { 
        $self->{services} = {};
        return $self; 
    }
    my %services = %{$args{services}};

    # Get node -> URL mapping
    unless($args{node_to_url}) {
        die("Must supply 'node_to_url;");
    }
    unless($args{node_to_url} =~ /\$node/) {
        die("node_to_url '$args{node_to_url}' must contain \$node");
    }
    $self->{node_to_url} = $args{node_to_url};
    $self->{agent} = $args{agent} || "Wiki::Toolkit::Plugin::Ping $VERSION";
    

    # Check the services
    foreach my $service (keys %services) {
        my $url = $services{$service};

        # Make valid
        unless($url =~ /^http:\/\//) {
            $url = "http://".$url;
            $services{$service} = $url;
        }
        unless($url =~ /\$url/) {
            die("For $service, URL '$url' didn't contain \$url anywhere\n");
        }
    }

    # Save
    $self->{services} = \%services;

    # Done setup
    return $self;
}

# Return our list of services, in case anyone's interested
sub services {
    my $self = shift;
    return %{$self->{services}};
}

# Define our post_write plugin, which does the ping
# Happens in another thread, to stop it slowing things down
sub post_write {
    my $self = shift;
    unless(keys %{$self->{services}}) { return; }

    my %args = @_;
    my ($node,$node_id,$version,$content,$metadata) =
        @args{ qw( node node_id version content metadata ) };

    # Spawn a new thread
    my $pid = fork();
    if($pid) {
        # We're the main thread, return now
        return;
    } else {
        # We're the child, do the work

        # Apply the formatter escaping on the node name, if there's one
        if($self->formatter) {
            # Eval, in case the formatter doesn't support node name escaping
            eval {
                $node = $self->formatter->node_name_to_node_param($node);
            };
        }

        # What's the URL of the node?
        my $node_url = $self->{node_to_url};
        $node_url =~ s/\$node/$node/;

        # Get a LWP instance
        my $ua = LWP::UserAgent->new;
        $ua->agent($self->{agent});

        # Ping each service
        foreach my $service (keys %{$self->{services}}) {
            # Build the ping URL
            my $ping_url = $self->{services}->{$service};
            $ping_url =~ s/\$url/$node_url/;

            # Ping
            my $req = HTTP::Request->new(GET => $ping_url);
            my $res = $ua->request($req);
            unless($res->is_success) {
                warn("Error pinging $service: $res->status_line");
            }
        }

        # All done, close the thread
        exit;
    }
}

# Returns a list of well known services
sub well_known {
    return (
            pingerati => 'http://pingerati.net/ping/$url',
            geourl    => 'http://geourl.org/ping/?p=$url',
    );
}

1;
__END__

=head1 NAME

Wiki::Toolkit::Plugin::Ping - "ping" various services when nodes are written

=head1 SYNOPSIS

  use Wiki::Toolkit::Plugin::Ping;
  my $ping = Wiki::Toolkit::Plugin::Ping->new( 
            node_to_url => 'http://mywiki/$node',
            services => {
                    "geourl" => 'http://geourl.org/ping?p=$url'
            },
            agent    => "My Wiki ping agent",
  );
  $wiki->register_pugin( plugin => $ping );

=head1 DESCRIPTION

A plug-in for Wiki::Toolkit sites, which will "ping" various external services
when a node is written. A list of the services to ping, and where in their
URLs to add the URL of the node, are supplied when the plugin is created.

You need to tell it how to turn a node into a URL (node_to_url), and what
services to ping (services). You can optionally pass a custom user-agent
string

=head1 AUTHOR

The Wiki::Toolkit team (http://www.wiki-toolkit.org/)

=head1 COPYRIGHT

Copyright (C) 2003-2004 I. P. Williams (ivorw_openguides [at] xemaps {dot} com).
Copyright (C) 2006-2009 the Wiki::Toolkit team (http://www.wiki-toolkit.org/)
All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Wiki::Toolkit>, L<Wiki::Toolkit::Plugin>, L<OpenGuides>

=cut
