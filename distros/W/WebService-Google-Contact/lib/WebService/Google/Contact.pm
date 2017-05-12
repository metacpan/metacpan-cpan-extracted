package WebService::Google::Contact;

use warnings;
use strict;
use Carp;

our $VERSION = '0.1';

use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw(email contacts));

use URI;
use LWP::UserAgent;
use XML::Liberal;

sub name_by_email {
    my $self = shift;
    my ($name) = split '@', $self->email;
    return $name;
}

sub uri_to_login {
    my ($self, $next, $scope) = @_;
    $scope ||= 'http://www.google.com/m8/feeds';
    my $base = 'https://www.google.com/accounts/AuthSubRequest';
    my $uri = URI->new( $base );
    $uri->query_form(
       scope   => $scope,
       session => 1,
       next    => $next,
       secure  => 0,
    );
    $uri->as_string;
}

sub verify {
    my ($self, $token) = @_;
    if ( $self->upgrade_to_session_token( $token ) ) {
        return $self->get_email;
    }
    return;
}

sub upgrade_to_session_token {
    my ($self, $token) = @_;
	my $ua = LWP::UserAgent->new();
	my $res = $ua->get(
		'https://www.google.com/accounts/AuthSubSessionToken',
		'Content-Type' => 'application/x-www-form-urlencoded',
		'Authorization' => 'AuthSub token="' . $token . '"',
	);
    if ( $res->is_success and $res->content =~ /^Token=(.+)$/ ) {
        $self->{session_token} = $1;
        return 1;
    }
    Carp::cluck "error upgrade_to_session_token";
    return;
}

sub get_email {
    my $self = shift;
    my $token = $self->{session_token};
	my $ua = LWP::UserAgent->new();
	my $res = $ua->get(
		'http://www.google.com/m8/feeds/contacts/default/full',
		'Content-Type' => 'application/x-www-form-urlencoded',
		'Authorization' => 'AuthSub token="' . $token . '"',
	);
    if ( $res->is_success ) {
        $self->{xml_content} = $res->content;
        return $self->{email} = $1 if $self->{xml_content} =~ /<id>(.+?)<\/id>/;
    }
    Carp::cluck 'error get_contact';
}

sub get_contact {
    my $self = shift;
    my $xml  = $self->{xml_content};
    my $parser = XML::Liberal->new;
    my $doc = eval { $parser->parse_string( $xml ) };

    Carp::cluck $@ if $@;

    my $root = $doc->documentElement;

    my @entries = $root->findnodes("//*[local-name()='entry']");
    my @contacts;
    for my $entry ( @entries ) {
        my %elems;
        $elems{ $_ } = $entry->findvalue("./*[local-name()='" . $_ . "']") for qw(id updated title);
        $elems{"name"}  = $elems{"title"};
        $elems{"email"} = $entry->getElementsByTagName('gd:email')->[0]->getAttribute("address");
        push @contacts, \%elems;
    }
    return $self->{contacts} = \@contacts;
}

1;

__END__

=head1 NAME

WebService::Google::Contact - Simple Interface for Google Contact API.

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

    # step1 => make uri for google authorization.
    use CGI;
    use WebService::Google::Contact;

    my $google_contact = WebService::Google::Contact->new;
    my $next_uri = 'http://example.com/?next=1';
    my $google_login_uri = $google_contact->uri_to_login( $next_uri );

    my $q = CGI->new;

    print $q->redirect( $google_login_uri );

    # step2 => catch the token and go to verify stage.
    use CGI;
    use WebService::Google::Contact;

    my $q = CGI->new;
    my $token = $q->param('token');
    my $google_contact = WebService::Google::Contact->new;
    
    $google_contact->verify( $token ) or die;

    # success verify!
    my $email = $google_contact->email;
    my $contacts = $google_contact->get_contact; # $contacts is $emais's contact list.

    warn sprintf('Welcome %s!', $email);

=head1 FUNCTIONS

=head2 new

create WebService::Google::Contact constructor.

=head2 name_by_email

get user name from email address after verify stage.

=head2 uri_to_login($next, $scope)

make the uri for google authorization.

=head2 verify($token)

verify the token after google authorization.

=head2 get_contact

get contact list.

=head2 email

get email address after verified stage.

=head2 upgrade_to_session_token

upgrade_to_session_token(private method).

=head2 get_email

get email address(private method).

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-webservice-google-contact@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

DAISUKE ABUI  C<< <abui@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, DAISUKE ABUI C<< <abui@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
