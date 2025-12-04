package Trickster::Response;

use strict;
use warnings;
use v5.14;

use parent 'Plack::Response';

sub json {
    my ($self, $data, $status) = @_;
    
    require JSON::PP;
    require Encode;
    
    $self->status($status || 200);
    $self->content_type('application/json; charset=utf-8');
    
    my $json = JSON::PP::encode_json($data);
    $self->body(Encode::encode_utf8($json));
    
    return $self;
}

sub html {
    my ($self, $content, $status) = @_;
    
    require Encode;
    
    $self->status($status || 200);
    $self->content_type('text/html; charset=utf-8');
    $self->body(Encode::encode_utf8($content));
    
    return $self;
}

sub text {
    my ($self, $content, $status) = @_;
    
    require Encode;
    
    $self->status($status || 200);
    $self->content_type('text/plain; charset=utf-8');
    $self->body(Encode::encode_utf8($content));
    
    return $self;
}

sub redirect {
    my ($self, $location, $status) = @_;
    
    $self->status($status || 302);
    $self->header('Location' => $location);
    $self->body('');
    
    return $self;
}

sub render {
    my ($self, $template, $vars, $status) = @_;
    
    # This method requires a template engine to be set
    # It will be called by the template engine's response helper
    die "Template engine not configured. Use Trickster::Template->response_helper()";
}

1;

__END__

=head1 NAME

Trickster::Response - Enhanced response object for Trickster

=head1 SYNOPSIS

    $app->get('/api/user', sub {
        my ($req, $res) = @_;
        return $res->json({ name => 'Alice', age => 30 });
    });
    
    $app->get('/redirect', sub {
        my ($req, $res) = @_;
        return $res->redirect('/new-location');
    });

=head1 DESCRIPTION

Trickster::Response extends Plack::Response with convenience methods
for common response types.

=head1 METHODS

=head2 json($data, $status)

Returns a JSON response with the given data structure.

=head2 html($content, $status)

Returns an HTML response.

=head2 text($content, $status)

Returns a plain text response.

=head2 redirect($location, $status)

Returns a redirect response (default 302).

=cut
