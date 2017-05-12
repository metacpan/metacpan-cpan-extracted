package YellowBot::API::Response;
$YellowBot::API::Response::VERSION = '0.97';
use Moose;
use JSON qw(decode_json);
use namespace::clean -except => 'meta';

has http => (
   is  => 'ro',
   isa => 'HTTP::Response',
   required => 1,
);

has data => (
   is   => 'ro', 
   isa  => 'HashRef',
   lazy_build => 1,
);

sub _build_data {
    my $self = shift;
    unless ($self->http->code == 200) {
        return +{ error_code => $self->http->code,
                  error      => $self->http->status_line,
                };
    }
    my $data = decode_json($self->http->content);
    if ($ENV{API_DEBUG} and $ENV{API_DEBUG} > 2) {
        warn "JSON response:\n" . $self->http->content . "\n";
    }

    # if return isn't a hashref, then wrap it in one, with 'result' key
    if(ref($data) ne 'HASH') {
        $data = { result => $data };
    }
    if ($ENV{API_DEBUG}) {
        require Data::Dumper;
        warn "YellowBot::API Response: ", Data::Dumper::Dumper($data);
    }
    return $data;
}

__PACKAGE__->meta->make_immutable;

1;


__END__

=pod

=encoding utf8

=head1 NAME

YellowBot::API::Request - Request object for YellowBot::API

=head1 SYNOPSIS

This class manages setting up requests for the YellowBot::API,
including signing of requests.

No user servicable parts inside.  This part of the API is subject to change.

=head1 METHODS

=head2 api

=head2 http_request

Returns a HTTP::Request version of the request.

=head1 AUTHOR

Ask Bjørn Hansen, C<< <ask at develooper.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Solfo Inc, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

