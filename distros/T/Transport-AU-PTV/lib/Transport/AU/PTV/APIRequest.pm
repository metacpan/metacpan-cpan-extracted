package Transport::AU::PTV::APIRequest;
$Transport::AU::PTV::APIRequest::VERSION = '0.01';
use strict;
use warnings;
use 5.010;

use parent qw(Transport::AU::PTV::NoError);

use Transport::AU::PTV::Error;

use LWP::UserAgent;
use Carp;
use URI;
use JSON;
use Digest::SHA qw(hmac_sha1_hex);


sub new {
    my $class = shift;
    my ($credential_r) = @_;
    my %attributes;

    %attributes = %{$credential_r};
    $attributes{user_agent} = LWP::UserAgent->new;

    return bless \%attributes, $class;
}


sub request {
    my $self = shift;
    ($self->{path}, $self->{query_r}) = @_;

    my $ret = $self->_send_request()->_check_response();

}


sub content {
    my $self = shift;

    return $self->{content};
}


 
sub _send_request {
    my $self = shift;
    my ($path) = @_;

    $self->{api_response} = $self->{user_agent}->get( $self->_generate_signed_uri() );

    return $self;
}

sub _check_response {
    my $self = shift;
    
    my $response = $self->{api_response};

    if ($response->is_error) {
        return Transport::AU::PTV::Error->message("HTTP Error: ".$response->status_line);
    }

    $self->{content} = decode_json($self->{api_response}->decoded_content());

    # Clean up the HTTP::Response
    delete $self->{api_response};

    return $self;
}



sub _generate_signed_uri {
    my $self = shift;
    my $query_r = $self->{query_r} // {};
    my @query_pairs;

    $query_r->{devid} = $self->{dev_id};

    for (keys %{$query_r}) {
        push @query_pairs, ($_ => $query_r->{$_});
    }

    my $uri = URI->new('http://timetableapi.ptv.vic.gov.au');
    $uri->path($self->{path});
    $uri->query_form(\@query_pairs);
    
    push @query_pairs, (signature => hmac_sha1_hex($uri->path_query, $self->{api_key}));

    $uri->query_form(\@query_pairs);

    return $uri;
} 

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Transport::AU::PTV::APIRequest

=head1 VERSION

version 0.01

=head1 NAME

=head2 new

=head2 api_request

=head2 content

=head2 _send_request

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
