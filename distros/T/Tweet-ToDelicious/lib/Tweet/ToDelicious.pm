package Tweet::ToDelicious;

use v5.14;
use utf8;
use warnings;
use Getopt::Long;
use Net::Delicious;
use AnyEvent;
use AnyEvent::Twitter::Stream;
use AnyEvent::HTTP;
use Coro;
use Coro::LWP;
use Coro::AnyEvent;
use Log::Minimal;
use Tweet::ToDelicious::Entity;
use Sub::Retry;

our $VERSION = '0.08';

sub new {
    my $class = shift;
    my $cfg   = shift;
    my $self  = bless { config => $cfg }, $class;
    return $self;
}

sub run {
    my $self = shift;

    local $|                      = 1;
    local $Log::Minimal::AUTODUMP = 1;

    my $myname   = $self->{config}->{t2delicious}->{twitter_screen_name};
    my $cv       = AE::cv;
    my ($connector, $connect, $stream, $listener);

    $listener = sub {
        AnyEvent::Twitter::Stream->new(
            %{ $self->{config}->{twitter} },
            method     => 'userstream',
            on_connect => sub {
                undef $connector;
                infof( 'Start watching twitter:@%s, delicious:%s',
                    $myname, $self->{config}->{delicious}->{user} );
            },
            on_event => sub {
                my $tweet = shift;
                my $entry = Tweet::ToDelicious::Entity->new($tweet);
                if ( $entry->is_favorite && $entry->screen_name ~~ $myname ) {
                    my @posts = $entry->posts;
                    $self->_posts(@posts);
                }
            },
            on_tweet => sub {
                my $tweet = shift;
                my $entry = Tweet::ToDelicious::Entity->new($tweet);
                if (   ( $entry->screen_name ~~ $myname )
                    or ( $entry->in_reply_to_screen_name ~~ $myname ) )
                {
                    my @posts = $entry->posts;
                    $self->_posts(@posts);
                }
            },
            on_keepalive => sub {
                debugf("ping received");
            },
            on_eof => sub {
                debugf("eof received");
                $connect->();
            },
            on_error => sub {
                critf(shift);
                $connect->();
            },
		);
    };
    $connect = sub {
        $connector = AE::timer 0, 2, sub { $stream = $listener->() };
    };

    $connect->();
    $cv->recv;

}

sub delicious {
    my $self = shift;
    state $delicious = Net::Delicious->new( $self->{config}->{delicious} );
    return $delicious;
}

sub coro_head {
    my $self = shift;
    my $uri  = shift;
    http_head $uri, Coro::rouse_cb;
    my ( $data, $headers ) = Coro::rouse_wait;
    if ( $headers->{Status} ~~ [ 200, 301, 302, 304 ] ) {
        debugf( "expand: %s => %s", $uri, $headers->{URL} );
        return $headers->{URL};
    }
    else {
        debugf( "Status != 200. headers: %s", ddf($headers) );
        return $headers->{Redirect}->[0]->{URL}
            if exists $headers->{Redirect};
    }
}

sub _posts {
    my $self      = shift;
    my $delicious = $self->delicious;
    my @posts     = @_;
    debugf( "posts: %s", \@posts );
    if ( @posts > 0 ) {
        for my $post (@posts) {
            async {
                my $done = retry 3, 1, sub {
                    $post->{url} = $self->coro_head( $post->{url} );
                    $delicious->add_post($post);
                };
                infof( "Post %s done", $post->{url} )
                    if $done;
            };
        }
    }
}

1;
__END__

=head1 NAME

Tweet::ToDelicious - Links in your tweet to delicious.

=head1 SYNOPSIS

  use Tweet::ToDelicious;
  Tweet::ToDelicious->new($cfg)->run;

=head1 DESCRIPTION

use L<t2delicious.pl> instead of this module directly.

=head1 DEPENDENCIES

L<Config::Any>, L<YAML::XS>, L<Net::Delicious>, L<LWP::Protocol::https>, L<Coro>, L<AnyEvent::Twitter::Stream>, L<Net::OAuth>, L<Net::SSLeay>, L<List::MoreUtils>, L<Log::Minimal>, L<Sub::Retry>

=head1 SEE ALSO

L<AnyEvent::Twitter::Stream>, L<Net::Delicious>

=head1 AUTHOR

Yoshihiro Sasaki, E<lt>ysasaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Yoshihiro Sasaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
