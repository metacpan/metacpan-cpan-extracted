package WWW::SpinnerChief;
{
    $WWW::SpinnerChief::VERSION = '0.01';
}

# ABSTRACT: SpinnerChief API

use strict;
use warnings;
use Carp 'croak';
use LWP::UserAgent;
use URI::Escape 'uri_escape';
use MIME::Base64;

use vars qw/$errstr/;
sub errstr { $errstr }

sub new {
    my $class = shift;
    my $args = scalar @_ % 2 ? shift : {@_};

    $args->{apikey}   or croak 'apikey is required';
    $args->{username} or croak 'username is required';
    $args->{password} or croak 'password is required';

    $args->{__url} =
"http://api.spinnerchief.com:9001/apikey=$args->{apikey}&username=$args->{username}&password=$args->{password}";

    bless $args, $class;
}

sub _send_request {
    my ( $self, $text, $params ) = @_;

    my $url = $self->{__url};
    $params ||= {};
    foreach my $k ( keys %$params ) {
        $url .= '&' . $k . '=' . uri_escape( $params->{$k} );
    }

    $text ||= '';
    $text = encode_base64($text) if length($text);
    my $resp = LWP::UserAgent->new->post( $url, Content => $text );

    #    use Data::Dumper; print Dumper(\$resp);

    unless ( $resp->is_success ) {
        $errstr = $resp->status_line;
        return;
    }

    my $data = decode_base64( $resp->content );
    if ( $data =~ s/^error=// ) {
        $errstr = $data;
        return;
    }

    return $data;
}

# The server returns today's used query times of this account.
sub quota_used { (shift)->_send_request( '', { querytimes => 1 } ) }

# The server returns today's remaining query times of this account.
sub quota_left { (shift)->_send_request( '', { querytimes => 2 } ) }

sub text_with_spintax {
    my ( $self, $text, $params ) = @_;

    $params ||= {};
    $params->{spintype} = 0;

    return $self->_send_request( $text, $params );
}

sub unique_variation {
    my ( $self, $text, $params ) = @_;

    $params ||= {};
    $params->{spintype} = 1;

    return $self->_send_request( $text, $params );
}

1;

__END__

=pod

=head1 NAME

WWW::SpinnerChief - SpinnerChief API

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use WWW::SpinnerChief;

    my $sc = WWW::SpinnerChief->new(
        apikey => 'blabla',
        username => 'fayland',
        password => 'password',
    );

    my $x = $sc->quota_left() or die $sc->errstr;
    print "quota_left: $x\n";

    my $spintax = $sc->text_with_spintax('Hello, what is your name? - ♠ ♣ ♦ ‾ ←') or die $sc->errstr;
    print "spintax: $spintax\n";

    my $unique_variation = $sc->unique_variation('This is a great software') or die $sc->errstr;
    print "unique_variation: $unique_variation\n";

=head1 DESCRIPTION

L<http://developer.spinnerchief.com/API_Document.aspx>

=head2 METHODS

=head3 CONSTRUCTION

    use WWW::SpinnerChief;

    my $sc = WWW::SpinnerChief->new(
        apikey => 'blabla',
        username => 'fayland',
        password => 'password',
    );

=over 4

=item * apikey

=item * username

=item * password

required

=back

=head3 quota_used

=head3 quota_left

    # querytimes=1
    my $x = $sc->quota_used() or die $sc->errstr;
    print "quota_used: $x\n";

    # querytimes=2
    my $x = $sc->quota_left() or die $sc->errstr;
    print "quota_left: $x\n";

=head3 text_with_spintax($text, $params)

B<spintype> = 0

    my $spintax = $sc->text_with_spintax('Hello, what is your name? - ♠ ♣ ♦ ‾ ←') or die $sc->errstr;
    print "spintax: $spintax\n";

=head3 unique_variation($text, $params)

B<spintype> = 1

    my $unique_variation = $sc->unique_variation('This is a great software') or die $sc->errstr;
    print "unique_variation: $unique_variation\n";

    my $new_text = $sc->unique_variation($text, {
        tagprotect => '[]',
        spinhtml => 1,
    }) or die $sc->errstr;

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
