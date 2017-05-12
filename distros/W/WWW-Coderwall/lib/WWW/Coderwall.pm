package WWW::Coderwall;

# ABSTRACT: Simple Perl interface to the coderwall API

use WWW::Coderwall::User;
use LWP::UserAgent;
use Data::Printer;
use JSON;

use Moo;

our $VERSION = "0.003";



sub get_user {
    my ( $self, $username ) = @_;

    my $uri = "http://coderwall.com/$username.json";

    my %user_data = %{$self->_call_api($uri)};

    return WWW::Coderwall::User->new(
        username    => $user_data{'username'}, 
        name        => $user_data{'name'},
        location    => $user_data{'location'},
        team        => $user_data{'team'},
        accounts    => $user_data{'accounts'},
        badges      => $user_data{'badges'},
        endorsements    => $user_data{'endorsements'},
    );
}


has http_agent => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $ua = LWP::UserAgent->new;
        $ua->agent($self->http_agent_name);
        return $ua;
    },
);


has http_agent_name => (
    is => 'ro',
    lazy => 1,
    default => sub { __PACKAGE__.'/'.$VERSION },
);


sub _call_api {
    my ( $self, $uri ) = @_;

    my $response = $self->http_agent->get($uri);

    if ( $response->is_success ) {

        my $json = JSON->new->allow_nonref;

        return $json->decode( $response->decoded_content );

    }

    die __PACKAGE__.' API request failed: ' . $response->status_line. "\n";
}


1;

__END__
=pod

=head1 NAME

WWW::Coderwall - Simple Perl interface to the coderwall API

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WWW::Coderwall;

    $cw = WWW::Coderwall->new;

    # Get a WWW::Coderwall::User object representing a user
    $user = $cw->get_user($username);

=head1 ATTRIBUTES

=head2 http_agent

An L<LWP::UserAgent> object used to make the API calls.

    use WWW::Coderwall;
    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new;
    my $cw = WWW::Coderwall->new;

    $cw->http_agent($ua);

    # ...and you're using your own agent

=head2 http_agent_name

The user agent string used when making the API call. Defaults to WWW::Coderwall/$VERSION.

    use WWW::Coderwall;

    my $cw = WWW::Coderwall->new;

    $cw->http_agent_name('mysite/0.2.3)';

    # ...and you're using your own agent name

=head1 METHODS

=head2 get_user

Returns a L<WWW::Coderwall::User> object given a username.

=head2 _call_api

Takes a URI, calls it, and returns the decoded json response.

For internal use. Use get_user or another get_* function instead.

=head1 SEE ALSO

L<WWW::Coderwall::User>

=head1 AUTHOR

Robert Picard <mail@robert.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robert Picard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

