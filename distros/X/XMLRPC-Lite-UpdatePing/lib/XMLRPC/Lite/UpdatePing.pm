package XMLRPC::Lite::UpdatePing;

use strict;
use vars qw($VERSION);
our $VERSION = '0.06';

use Encode;
use XMLRPC::Lite;

sub new {
    my $class = shift;
    bless { ping_servers => [
        'http://blogsearch.google.com/ping/RPC2',
        'http://www.blogpeople.net/servlet/weblogUpdates',
        'http://rpc.technorati.com/rpc/ping',
    ], }, $class;
}

sub ping_servers {
    my $self = shift;
    return $self->{ping_servers};
}

sub add_ping_server {
    my $self = shift;
    my $new_ping_server = shift;
    push @{$self->{ping_servers}}, $new_ping_server;
    return $self;
}

sub setup_ping_servers {
    my $self = shift;
    $self->{ping_servers} = shift;
    return $self;
}

sub ping {
    my $self = shift;
    my $feed_uris = shift;
    my ($all_res, $recent_res) = ('', '');
    for my $feed_name ( keys %{$feed_uris} ) {
        for my $ping_server_uri (@{$self->ping_servers}) {
            $recent_res = &_send_ping(
                rpc       => $ping_server_uri,
                site_name => encode('eucjp', $feed_name),
                feed_uri  => $$feed_uris{$feed_name},
            );
            $all_res .= &_as_string($recent_res) if defined $recent_res;
        }
    }
    return $all_res;
}

sub _send_ping {
    my %arg = @_;
    my $rpc_uri   = $arg{rpc};
    my $site_name = $arg{site_name};
    my $feed_uri  = $arg{feed_uri};

    if ( ! defined $rpc_uri || $rpc_uri !~ m/^http/ ) {
        return { flerror => 0,
                 message => 'local echo mode',
                 name    => $site_name,
                 uri     => $feed_uri,   };
    }

    my $result = eval { 
        XMLRPC::Lite->proxy($rpc_uri)
            ->call( 'weblogUpdates.ping', $site_name, $feed_uri, )
            ->result ;
    };
    return $@ if $@;

    return (defined $result) ? $result : { 'flerror' => 'none', 'message' => 'none' };
}

sub _as_string {
    my $input = shift;
    if (not ref $input) {
        return $input;
    } elsif (ref $input eq 'SCALAR') {
        return $$input;
    } elsif (ref $input eq 'ARRAY') {
        return join("<br />\n", @$input);
    } elsif (ref $input eq 'HASH') {
        my $return = '';
        for my $key (sort keys %$input) {
            $return .= "$key => $input->{$key}<br />\n";
        }
        return $return;
    } else {
        return 'unknown data format';
    }
}

1;

__END__

=head1 NAME

XMLRPC::Lite::UpdatePing - send update ping easily with XMLRPC::Lite

=head1 SYNOPSIS

  use XMLRPC::Lite::UpdatePing;

  my $your_rssfeeds = ( 'example1' => 'http://example.com/rss.xml',
                        'example2' => 'http://example.com/rss2', );

  my $client = XMLRPC::Lite::UpdatePing->new();
  my $result = $client->add_ping_server('http://rpc.reader.livedoor.com/ping')
                      ->ping($your_rssfeeds);
 
=head1 DESCRIPTION

XMLRPC::Lite::UpdatePing is a Perl modules that you can send update-ping to ping servers so easily.

You can send update ping to the following ping servers by default.

  http://blogsearch.google.com/ping/RPC2
  http://www.blogpeople.net/servlet/weblogUpdates
  http://rpc.technorati.com/rpc/ping

=head1 METHODS

=over 4

=item new()

  my $client = XMLRPC::Lite::UpdatePing->new();

Create and return a new XMLRPC::Lite::UpdatePing object.

=item add_ping_server(I<$url>)

  $client->add_ping_server('http://api.my.yahoo.com/RPC2');
 
Add a new ping server to the list of target ping servers and return self object.

=item setup_ping_servers(I<\@url>)

  my $ping_servers = [ 'http://api.my.yahoo.com/RPC2',
                       'http://rpc.reader.livedoor.com/ping',
                       'http://r.hatena.ne.jp/rpc',  ];

  $client->setup_ping_servers($ping_servers);

Set a new list of ping servers instead of the default list and return self object.

=item ping(I<\%feed_url>)

  my $result = $client->ping($your_rssfeeds);

Send update ping requests to the ping servers and return a result string.

=head1 DEPENDENCIES

XMLRPC::Lite

=head1 SEE ALSO

XMLRPC::Lite

=head1 AUTHOR

Kazuhiro Sera, E<lt>webmaster@seratch.ath.cxE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kazuhiro Sera

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
