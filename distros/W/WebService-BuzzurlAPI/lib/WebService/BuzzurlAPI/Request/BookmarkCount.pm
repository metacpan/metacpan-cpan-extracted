package WebService::BuzzurlAPI::Request::BookmarkCount;

use strict;
use base qw(WebService::BuzzurlAPI::Request::Base);
use Readonly;

our $VERSION = 0.02;

Readonly my $URL_MAX => 30;

sub filter_param {

    my($self, $param) = @_;

    if(exists $param->{url}){
        
        if(ref($param->{url}) eq "ARRAY"){
            
            if(scalar @{$param->{url}} > $URL_MAX){
                my @tmp = splice @{$param->{url}}, 0, $URL_MAX;
                $param->{url} = \@tmp;
            }
            $param->{url} = [ map { $self->drop_utf8flag($_) } @{$param->{url}} ];
        }else{
            $param->{url} = $self->drop_utf8flag($param->{url});
        }
    }
}

sub make_request_url {

    my($self, $param) = @_;
    my $path = sprintf $self->uri->path, "counter";
    $self->uri->path($path);
    $self->uri->query_form($param);
}

1;

