package YellowBot::API::Request;
$YellowBot::API::Request::VERSION = '0.97';
use Moose;
use URI ();
use Carp qw(croak);
use Digest::SHA qw(hmac_sha256_hex);
use HTTP::Request::Common qw(POST);
use namespace::clean -except => 'meta';

use YellowBot::API::Response;

has 'api' => (
   isa => 'YellowBot::API',
   is  => 'ro',
   required => 1,
);

has method => (
   isa => 'Str',
   required => 1,
   is  => 'ro',
);

has args => (
   isa => 'HashRef[Str | ArrayRef[Str | Undef]]',
   is  => 'rw',
);

sub _query {
    my %args = @_;

    my $api_secret = delete $args{api_secret};

    $args{api_ts}  ||= time;
    $args{api_sig}   = hmac_sha256_hex(_get_parameter_string(\%args), $api_secret);

    return %args;
}

sub _signed_args {
    return shift->args;
}

sub _signed_query_form {
    my $self = shift;

    my $signed_args = $self->_signed_args;
    return _query
      (
       %$signed_args,
       api_key    => $self->api->api_key,
       api_secret => $self->api->api_secret,
      );

}

sub _build_uri {
    my $self = shift;
    my $uri = URI->new( $self->api->server );
    $uri->path("/api/" . $self->method);
    return $uri;
}

sub _build_request {
    my $self = shift;
    
    my $uri = $self->_build_uri;
    my %content = $self->_signed_query_form;

    return POST($uri, [%content], 'Content-Type' => 'form-data');
}

sub http_request {
    my $self = shift;

    my $request = $self->_build_request;

    #$request->dump( prefix => ' > ' );

    if ($ENV{API_DEBUG}) {
        require Data::Dumper;
        warn "YellowBot::API Request: ", Data::Dumper::Dumper($request);
    }

    return $request;
}

sub _file_as_value {
    my $v  = shift;
    my $fn = $v->[1];
    unless (defined $fn) {    # Infer from local file name
        $fn = $v->[0];
        $fn =~ s,.*/,, if defined $fn;
    }
    unless ($fn) {
        croak "File uploads must have file names";
    }
    return $fn;
}
# Based on HTTP::Request::form_data() handling of uploads
# according to the specification [ $file, $usename, @headers ]

sub _get_parameter_string {
    my $args = shift;

    my $str = "";
    for my $key (sort {$a cmp $b} keys %{$args}) {
        next if $key eq 'api_sig';
        my $v = $args->{$key};
        my $value =
          defined($v)
          ? (ref($v) ? _file_as_value($v) : $v)
          : "";
        $str .= $key . $value;
    }
    return $str;
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


    my $req = YellowBot::API::Request->new
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

Copyright 2009 Solfo Inc, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

