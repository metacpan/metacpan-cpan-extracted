package WebService::HIBP;

use strict;
use warnings;
use JSON();
use URI::Escape();
use LWP::UserAgent();
use Digest::SHA();
use WebService::HIBP::Breach();
use WebService::HIBP::Paste();

our $VERSION = '0.09';

sub _LENGTH_OF_PASSWORD_PREFIX { return 5; }

sub new {
    my ( $class, %params ) = @_;
    my $self = {};
    bless $self, $class;
    $self->{url}          = 'https://haveibeenpwned.com/api/v2/';
    $self->{password_url} = 'https://api.pwnedpasswords.com/range/';
    if ( $params{user_agent} ) {
        $self->{ua} = $params{user_agent};
    }
    else {
        $self->{ua} = LWP::UserAgent->new( agent => 'WebService-HIBP ' );
        $self->{ua}->env_proxy();
    }
    return $self;
}

sub _get {
    my ( $self, $url ) = @_;
    my $response = $self->{ua}->get($url);
    $self->{last_response} = $response;
    return $response;
}

sub last_request {
    my ($self) = @_;
    if ( defined $self->{last_response} ) {
        return $self->{last_response}->request();
    }
    return;
}

sub last_response {
    my ($self) = @_;
    if ( defined $self->{last_response} ) {
        return $self->{last_response};
    }
    return;
}

sub data_classes {
    my ($self)   = @_;
    my $url      = $self->{url} . 'dataclasses';
    my $response = $self->_get($url);
    if ( $response->is_success() ) {
        my $json = JSON::decode_json( $response->decoded_content() );
        my @classes;
        foreach my $class ( @{$json} ) {
            push @classes, $class;
        }
        return @classes;
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
}

sub breach {
    my ( $self, $name ) = @_;
    my $url      = $self->{url} . 'breach/' . $name;
    my $response = $self->_get($url);
    if ( $response->is_success() ) {
        my $json = JSON::decode_json( $response->decoded_content() );
        return WebService::HIBP::Breach->new( %{$json} );
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
}

sub pastes {
    my ( $self, $account ) = @_;
    my $url =
      $self->{url} . 'pasteaccount/' . URI::Escape::uri_escape($account);
    my $response = $self->_get($url);
    if ( $response->is_success() ) {
        my $json = JSON::decode_json( $response->decoded_content() );
        my @pastes;
        foreach my $paste ( @{$json} ) {
            push @pastes, WebService::HIBP::Paste->new( %{$paste} );
        }
        return @pastes;
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
}

sub breaches {
    my ( $self, %parameters ) = @_;
    my $url = $self->{url} . 'breaches';
    if ( $parameters{domain} ) {
        $url .= '?domain=' . URI::Escape::uri_escape( $parameters{domain} );
    }
    my $response = $self->_get($url);
    if ( $response->is_success() ) {
        my $json = JSON::decode_json( $response->decoded_content() );
        my @breaches;
        foreach my $breach ( @{$json} ) {
            push @breaches, WebService::HIBP::Breach->new( %{$breach} );
        }
        return @breaches;
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
}

sub account {
    my ( $self, $account, %parameters ) = @_;
    my $url =
      $self->{url} . 'breachedaccount/' . URI::Escape::uri_escape($account);
    my @filters;
    if ( $parameters{unverified} ) {
        push @filters, 'includeUnverified=true';
    }
    if ( $parameters{truncate} ) {
        push @filters, 'truncateResponse=true';
    }
    if ( $parameters{domain} ) {
        push @filters,
          'domain=' . URI::Escape::uri_escape( $parameters{domain} );
    }
    if (@filters) {
        $url .= q[?] . join q[&], @filters;
    }
    my $response = $self->_get($url);
    if ( $response->is_success() ) {
        my $json = JSON::decode_json( $response->decoded_content() );
        my @breaches;
        foreach my $breach ( @{$json} ) {
            push @breaches, WebService::HIBP::Breach->new( %{$breach} );
        }
        return @breaches;
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
}

sub password {
    my ( $self, $password ) = @_;
    my $sha1 = uc Digest::SHA::sha1_hex($password);
    my $url = $self->{password_url} . substr $sha1, 0,
      _LENGTH_OF_PASSWORD_PREFIX();
    my $response = $self->_get($url);
    if ( $response->is_success() ) {
        my $remainder = substr $sha1, _LENGTH_OF_PASSWORD_PREFIX();
        foreach my $line ( split /\r\n/smx, $response->decoded_content() ) {
            my ( $pwned, $count ) = split /:/smx, $line;
            if ( $pwned eq $remainder ) {
                return $count;
            }
        }
        return 0;
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
}

1;    # End of WebService::HIBP
__END__

=head1 NAME

WebService::HIBP - An interface to the Have I Been Pwned webservice at haveibeenpwned.com

=head1 VERSION

Version 0.08

=head1 SYNOPSIS

Check the security of your accounts/email addresses and passwords

    use WebService::HIBP();
    use IO::Prompt();

    my $hibp = WebService::HIBP->new();
    my $new_password = IO::Prompt::prompt(-echo => q[*], 'Enter your new password:');
    my $count = $hibp->password($new_password);
    if ($count == 0) {
    } elsif ($count <= 2) {
       warn "This password has been found in a data breach\n";
    } elsif ($count) {
       die "This password is too insecure\n";
    }

=head1 DESCRIPTION

This is a client module for the L<https://haveibeenpwned.com/api/v2/> API, which provides a searchable interface to account/password breaches and pastes on sites such as pastebin.com

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::HIBP> object, ready to check how bad the pwnage is.  It accepts an optional hash as a parameter.  Allowed keys are below;

=over 4

=item * user_agent - A pre-configured instance of L<LWP::UserAgent|LWP::UserAgent> that will be used instead of the automatically created one.  This allows full control of the user agent properties if desired

=back

=head2 password

The L<Pwned Passwords API|https://haveibeenpwned.com/API/v2#PwnedPasswords> has more than half a billion passwords which have previously been exposed in data breaches. The service is detailed in the L<launch blog post|https://www.troyhunt.com/introducing-306-million-freely-downloadable-pwned-passwords/> then L<further expanded on with the release of version 2|https://www.troyhunt.com/ive-just-launched-pwned-passwords-version-2>. 

In order to protect the value of the source password being searched for, this method implements a L<k-Anonymity|https://en.wikipedia.org/wiki/K-anonymity> model that searches for a password by partial hash. This method therefore only sends the first 5 characters of a SHA-1 hash of the password (the prefix) to the L<Pwned Passwords API|https://haveibeenpwned.com/API/v2#PwnedPasswords>.

The L<Pwned Passwords API|https://haveibeenpwned.com/API/v2#PwnedPasswords> responds with a list of the suffix of every hash beginning with the specified prefix, followed by a count of how many times it appears in the data set. This method searches the results of the response for a matching hash suffix.

This method then returns the count of how many times it appears in the data set or "0" if it dosen't appear.

    use WebService::HIBP();
    use IO::Prompt();

    my $hibp = WebService::HIBP->new();
    my $new_password = IO::Prompt::prompt(-echo => q[*], 'Enter your new password:');
    my $count = $hibp->password($new_password);
    if ($count == 0) {
    } elsif ($count <= 2) {
       warn "This password has been found in a data breach\n";
    } elsif ($count) {
       die "This password is too insecure\n";
    }

=head2 account

The most common use of the API is to return a list of all breaches a particular account has been involved in. The API takes a single parameter which is the account to be searched for. The account is not case sensitive and will be trimmed of leading or trailing white spaces.  Returns a list of L<breaches|WebService::HIBP::Breach>.

Parameters:

=over 4

=item * truncate - Returns only the name of the breach.

=item * domain - Filters the result set to only breaches against the domain specified. It is possible that one site (and consequently domain), is compromised on multiple occasions.

=item * unverified - Returns breaches that have been flagged as "unverified". By default, only verified breaches are returned web performing a search.

=back 

    use WebService::HIBP();
    use v5.10;

    my $hibp = WebService::HIBP->new();
    foreach my $breach ( $hibp->account( 'test@example.com', domain => 'adobe.com' ) ) {
        say $breach->name();
    }

=head2 breach

Sometimes just a single L<breach|WebService::HIBP::Breach> is required and this can be retrieved by the breach L<name|WebService::HIBP::Breach#name>. This is the stable value which may or may not be the same as the breach L<title|WebService::HIBP::Breach#title> (which can change). Returns a list of L<breaches|WebService::HIBP::Breach>.

    use WebService::HIBP();
    use v5.10;

    my $hibp = WebService::HIBP->new();
    my $breach = $hibp->breach( 'Adobe' );
    say $breach->title();

=head2 breaches

A L<breach|WebService::HIBP::Breach> is an instance of a system having been compromised by an attacker and the data disclosed. For example, Adobe was a breach, Gawker was a breach etc. This method returns the details of each of breach in the system.

Parameters:

=over 4

=item * domain - Filters the result set to only breaches against the domain specified. It is possible that one site (and consequently domain), is compromised on multiple occasions.  Returns a list of L<breaches|WebService::HIBP::Breach>.


=back 

    use WebService::HIBP();
    use v5.10;

    my $hibp = WebService::HIBP->new();
    foreach my $breach ( $hibp->breaches( domain => 'adobe.com' ) ) {
        say $breach->name();
    }

=head2 data_classes

A "data class" is an attribute of a record compromised in a breach. For example, many breaches expose data classes such as "Email addresses" and "Passwords". The values returned by this service are ordered alphabetically in a string array and will expand over time as new breaches expose previously unseen classes of data.

    use WebService::HIBP();
    use v5.10;

    my $hibp = WebService::HIBP->new();
    foreach my $class ( $hibp->data_classes() ) {
        say $class;
    }

=head2 pastes

This method takes a single parameter which is the email address to be searched for. Unlike searching for breaches, usernames that are not email addresses cannot be searched for. The email is not case sensitive and will be trimmed of leading or trailing white spaces.  Returns a list of L<pastes|WebService::HIBP::Paste>.

    use WebService::HIBP();
    use v5.10;

    my $hibp = WebService::HIBP->new();
    foreach my $paste ( $hibp->pastes( 'test@example.com' ) ) {
        say $paste->source();
    }

=head2 last_request

This method returns the L<request|HTTP::Request> that was sent to the L<https://haveibeenpwned.com/api/v2/> API.  This method is intended to only aid troubleshooting in the event of an error response.

=head2 last_response

This method returns the L<response|HTTP::Response> that came from the L<https://haveibeenpwned.com/api/v2/> API.  This method is intended to only aid troubleshooting in the event of an error response.

=head1 DIAGNOSTICS

=over

=item C<< Failed to retrieve %s >>

The URL could not be retrieved. Check network and proxy settings.

=back

=head1 CONFIGURATION AND ENVIRONMENT

WebService::HIBP requires no configuration files or environment variables.  However, it will use the values of C<$ENV{HTTPS_PROXY}> as a default for calls to the L<https://haveibeenpwned.com/api/v2/> API via the LWP::UserAgent module.

=head1 DEPENDENCIES

WebService::HIBP requires the following non-core modules

  JSON
  LWP::UserAgent
  LWP::Protocol::https
  URI::Escape
  Digest::SHA

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-webservice-hibp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-HIBP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::HIBP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-HIBP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-HIBP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-HIBP>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-HIBP/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Troy Hunt for providing the service at L<https://haveibeenpwned.com>

POD was extracted from the API help at L<https://haveibeenpwned.com/API/v2>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
