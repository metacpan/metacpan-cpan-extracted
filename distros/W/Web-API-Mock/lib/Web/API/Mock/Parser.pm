package Web::API::Mock::Parser;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.11";

use utf8;
use B qw(perlstring);
use Text::Markdown::Hoedown;
use Web::API::Mock::Map;
use Class::Accessor::Lite (
    new => 1,
    rw  => [ qw/map md cb _resource_name _paragraph _url _method _status _content_type _header _body api/ ],
);

sub create_map {
    my $self =shift;

    $self->_callback();

    my $md = Text::Markdown::Hoedown::Markdown->new(HOEDOWN_EXT_AUTOLINK, 16, $self->cb);

    eval {
        $md->render($self->md);
    };
    if ( $@ ) {
        die "cannot parse markdown. $@";
    }

    my $map = Web::API::Mock::Map->new();
    $map->init();
    for my $name ( keys %{$self->api} ) {
        $map->add_resource( $self->api->{$name}->{url}, {
            status       => $self->api->{$name}->{status},
            content_type => $self->api->{$name}->{content_type},
            method       => $self->api->{$name}->{method},
            header       => $self->api->{$name}->{header},
            body         => $self->api->{$name}->{body}
        });
    }

    return $map;
}

sub _callback {
    my $self = shift;

    $self->api({});

    my $cb = Text::Markdown::Hoedown::Renderer::Callback->new();

    $cb->blockcode( sub {
        return unless $self->_resource_name;

        if ( $self->_paragraph =~ /^body/i ) {
           $self->_body($_[0]);
        }
        elsif ( $self->_paragraph =~ /^header/i ) {
            my @line = split("\n", $_[0]);
            for (@line) {
                my ($key, $value) = split(':',$_);
                chomp $value;
                $value =~ s/^ +//g;
                $self->_header->{$key} = $value;
            }
        }
        else {
           $self->_body($_[0]);
        }

    } );

    # TODO 
    $cb->blockquote( sub {} );

    # TODO
    $cb->blockhtml( sub {} );

    $cb->header( sub {
        $self->_add_api();

        my ($method, $url) = split(' ', $_[0]);
        $self->_header({});
        $self->_body('');
        $self->_url($url);
        $self->_method($method);
        $self->_resource_name($_[0]);
    } );

    $cb->paragraph( sub {
        $self->_paragraph($_[0]);
    } );

    # TODO 
    $cb->list(sub{});

    $cb->listitem(sub{
        if ( $_[0] =~ /^response +(\d+) +\((.+?)\)/i ) {
            $self->_status($1);
            $self->_content_type($2);
        }
    });

    $cb->doc_footer(sub{
        $self->_add_api();
    });

    $self->cb($cb);
}

sub _add_api {
    my $self = shift;
    # APIドキュメント上でコメント等に利用するため
    # GET,POST,PUT,DELETE以外のメソッドは無視する
    if ( $self->_resource_name && $self->_url && $self->_method &&
         $self->_method =~ /^(GET|POST|PUT|DELETE)$/ ) {
        $self->api->{$self->_resource_name} = {
            content_type => $self->_content_type // '',
            status => $self->_status // '',
            url    => $self->_url // '',
            method => $self->_method // '',
            header => $self->_header // {},
            body   => $self->_body // '',
        };
    }
}

1;
