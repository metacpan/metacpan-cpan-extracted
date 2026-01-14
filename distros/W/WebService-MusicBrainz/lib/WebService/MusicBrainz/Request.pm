package WebService::MusicBrainz::Request;

use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Util qw/dumper/;

has url_base => 'https://musicbrainz.org/ws/2';
has ua => sub
{
    Mojo::UserAgent->with_roles('+Retry')->new(
        retries         => 4,           # try up to 4 times (total 5 attempts)
        retry_wait_min  => 1,           # seconds
        retry_wait_max  => 15,          # exponential backoff up to 15s
        # Optional: custom policy (default retries on connection errors + 429/503)
        # retry_policy    => sub { ... }
        )};
has 'format' => 'json';
has 'search_resource';
has 'mbid';
has 'discid';
has 'inc' => sub { [] };
has 'query_params';
has offset => 0;
has debug => sub { $ENV{MUSICBRAINZ_DEBUG} || 0 };;

our $VERSION = '1.1';

binmode STDOUT, ":encoding(UTF-8)";

sub make_url {
    my $self = shift;

    my @url_parts;

    push @url_parts, $self->url_base();
    push @url_parts, $self->search_resource();
    push @url_parts, $self->mbid() if $self->mbid;
    push @url_parts, $self->discid() if $self->discid;

    my $url_str = join '/', @url_parts;

    $url_str .= '?fmt=' . $self->format;

    if(scalar(@{ $self->inc }) > 0) {
        my $inc_query = join '+', @{ $self->inc }; 

        $url_str .= '&inc=' . $inc_query;
    }

    my @extra_params;

    foreach my $key (keys %{ $self->query_params }) {
        push @extra_params, $key . ':"' . $self->query_params->{$key} . '"';
    }

    if(scalar(@extra_params) > 0) {
        my $extra_param_str = join ' AND ', @extra_params;

        $url_str .= '&query=' . $extra_param_str; 
    }

    $url_str .= '&offset=' . $self->offset();

    print "REQUEST URL: $url_str\n" if $self->debug();

    my $url = Mojo::URL->new($url_str);

    return $url;
}

sub result {
    my $self = shift;

    my $request_url = $self->make_url();

    my $get_result = $self->ua->get($request_url => { 'Accept-Encoding' => 'application/json' })->result;

    my $result_formatted;

    if($self->format eq 'json') {
        $result_formatted = $get_result->json;
        print "JSON RESULT: ", dumper($get_result->json) if $self->debug;
    } elsif($self->format eq 'xml') {
        $result_formatted = $get_result->dom;
        print "XML RESULT: ", $get_result->dom->to_string, "\n" if $self->debug;
    } else {
        warn "Unsupported format type : $self->format";
    }

    return $result_formatted;
}

=head1 NAME

WebService::MusicBrainz::Request

=head1 SYNOPSIS

=head1 ABSTRACT

WebService::MusicBrainz::Request - Handle queries using the MusicBrainz WebService API version 2

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

=over 4

=item Bob Faist <bob.faist@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2017 by Bob Faist

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

https://wiki.musicbrainz.org/XMLWebService

=cut

1;
