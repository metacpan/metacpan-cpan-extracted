package WebService::BuzzurlAPI::Request::Add;

use strict;
use base qw(WebService::BuzzurlAPI::Request::Base);
use Readonly;

our $VERSION = 0.02;

Readonly my $KEYWORD_MAX => 8;
Readonly my $REALM       => "API AUTH";

sub filter_param {

    my($self, $param) = @_;

    $param->{url} = $self->drop_utf8flag($param->{url});
    $param->{title} = $self->drop_utf8flag($param->{title}) if exists $param->{title};
    $param->{comment} = $self->drop_utf8flag($param->{comment}) if exists $param->{comment};

    if(exists $param->{keyword}){

        if(ref($param->{keyword}) eq "ARRAY"){

            if(scalar @{$param->{keyword}} > $KEYWORD_MAX){
                my @tmp = splice @{$param->{keyword}}, 0, $KEYWORD_MAX;
                $param->{keyword} = \@tmp;
            }
            $param->{keyword} = [ map { $self->drop_utf8flag($_) } @{$param->{keyword}} ];
        }else{
            $param->{keyword} = $self->drop_utf8flag($param->{keyword});
        }
    }
}

sub make_request_url {

    my($self, $param) = @_;

    $self->uri->scheme("https");
    $self->uri->host("buzzurl.jp");
    $self->uri->path("/posts/add/v1");

# for basic auth
    my $netloc = sprintf "%s:%d", $self->uri->host, $self->uri->port;
    $self->buzz->ua->credentials($netloc, $REALM, $self->buzz->email ,$self->buzz->password);
}


sub make_request_content {

    my($self, $param) = @_;
    my $uri = $self->uri->clone;
    $uri->query_form($param);
    return $uri->query;
}

sub is_post_request { 1 }

1;

