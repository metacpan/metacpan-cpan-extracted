package YellowBot::API::Request::JSON;
$YellowBot::API::Request::JSON::VERSION = '0.97';
use Moose;

use HTTP::Request;
use JSON qw(encode_json);

use namespace::clean -except => 'meta';

extends 'YellowBot::API::Request';

has '+args' => (
   isa => 'HashRef[Any]',
);

sub _signed_args {
    my $self = shift;
    my $all_args = $self->args;
    my %args;
    for my $p (qw(api_ts api_user_identifier)) {
        $args{$p} = $all_args->{$p} if exists $all_args->{$p};
    }
    return \%args;
}

sub _more_args {
    my $self = shift;
    my %args = %{ $self->args };
    delete @args{qw(api_ts api_key api_user_identifier api_sig api_secret auth_token)};
    return %args;
}

sub _build_request {
    my $self = shift;

    my $uri = $self->_build_uri;
    my %query = $self->_signed_query_form;
    $uri->query_form(%query);

    my %extra = $self->_more_args;

    # JSON POST request
    my $req = HTTP::Request->new('POST', $uri, ['Content-Type' => 'application/json; charset=utf-8']);
    my $req_content = encode_json(\%extra);
    $req->content($req_content);
    return $req;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

YellowBot::API::Request::JSON - Request object for YellowBot::API (JSON POST)

=head1 SYNOPSIS

This class manages setting up JSON POST requests for the YellowBot::API.

No user servicable parts inside.  This part of the API is subject to change.


    my $req = YellowBot::API::Request::JSON->new
       (api    => $yellowbot_api,
        method => 'location/detail',
        args   => { foo => 'bar',
                    fob => 123,
                  },
       );

    my $http_request = $req->http_request;


=head1 METHODS

=head2 api

=head2 http_request

Returns a HTTP::Request version of the request.

=head1 AUTHOR

Ask Bjørn Hansen, C<< <ask at develooper.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009–2011 Solfo Inc, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

