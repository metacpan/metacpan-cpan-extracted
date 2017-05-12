package WWW::Anonymouse;

use strict;
use warnings;

use LWP::UserAgent;
use URI;
use Carp ();

our $VERSION = '0.04';

use constant DEBUG => $ENV{ WWW_ANONYMOUSE_DEBUG } || 0;
use constant MAX_BYTES => 3072;

sub new {
    my ($class, %params) = @_;
    if ( $class eq __PACKAGE__ ) {
        Carp::croak __PACKAGE__,
            ' is a virtual class; use the Email or News class';
    }

    unless ( ref $params{ua} and $params{ua}->isa( q(LWP::UserAgent) ) ) {
        $params{ua} = LWP::UserAgent->new( agent => __PACKAGE__.'/'.$VERSION );
    }

    return bless \%params, $class;
}

sub error {
    return $_[0]->{error};
}

sub _ua_content_cb {
    my ($data, $res, $proto) = @_;
    $res->add_content(\$data);

    # Abort the request if enough content is received to parse for status.
    die if length $res->content > MAX_BYTES;
}

sub send {
    my ($self, %params) = @_;
    my %fields;

    unless ( $fields{qw( to )} = $params{qw( to )} ) {
        $self->{error} = qq(Missing field "to");
        return;
    }

    for my $field ( qw( subject text ) ) {
        $fields{$field} = $params{$field} || '';
    }

    my $res = $self->{ua}->post(
        $self->_url, \%fields, ':read_size_hint' => MAX_BYTES,
        ':content_cb' => \&_ua_content_cb,
    );
    unless ( $res->is_success ) {
        $self->{error} = $res->status_line;
        return;
    }

    # TODO: consider using HTML::TreeBuilder::XPath

    $self->{error} = 'Unknown error';
    my $cref = $res->content_ref;

    if ( $$cref !~ /<FONT size="\+2"/g ) { }
    elsif ( $$cref =~ /\G color="#FF0000">(?:Mixmaster-)?Error - ([^>]+?)\!?</gc ) {
        $self->{error} = $1;
    }
    elsif ( $$cref =~ /\G>(?:Email|Posting) has been sent anonymously/ ) {
        $self->{error} = undef;
        return 1;
    }

    return;
}

BEGIN {
    package WWW::Anonymouse::Email;
    use base qw( WWW::Anonymouse );
    sub _url { 'http://anonymouse.org/cgi-bin/anon-email.cgi' }
    sub _referer { 'http://anonymouse.org/anonemail.html' }
}

BEGIN {
    package WWW::Anonymouse::News;
    use base qw( WWW::Anonymouse );
    sub _url { 'http://anonymouse.org/cgi-bin/anon-news.cgi' }
    sub _referer { 'http://anonymouse.org/anonnews.html' }
}

1;

__END__

=head1 NAME

WWW::Anonymouse - interface to Anonymouse.org Email and News posting

=head1 SYNOPSIS

    use WWW::Anonymouse;

    my $an = WWW::Anonymouse::Email->new;
    $an->send( to=>'bubba@example.com', subject=>'test', text=>'test' );

    my $an = WWW::Anonymouse::News->new;
    $an->send( to=>'alt.test', subject=>'test', text=>'test' );

=head1 DESCRIPTION

The C<WWW::Anonymouse> module provides an interface to the Anonymouse.org
anonymous email and news posting.

=head1 METHODS

=over

=item $an = WWW::Anonymouse::Email->B<new>

=item $an = WWW::Anonymouse::Email->B<new>( ua => $ua )

=item $an = WWW::Anonymouse::News->B<new>

=item $an = WWW::Anonymouse::News->B<new>( ua => $ua )

Creates a new Email or News object. The constructor accepts an optional
LWP::UserAgent derived object.

=item $ret = $an->B<send>( to => $to, subject => $subject, text => $text )

Sends a message to the given email address(es) or newsgroup(s). Returns true
on success.

=item $error = $an->B<error>

Returns the error string, if present.

=back

=head1 NOTES

Anonymouse has a flood protection limit of about 1 message per minute. If you
need to post more frequently, you can use http proxies or cgi proxies- but
don't abuse the service.

=head1 SEE ALSO

L<http://anonymouse.org/anonemail.html>

L<http://anonymouse.org/anonnews.html>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Anonymouse>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Anonymouse

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Anonymouse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Anonymouse>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Anonymouse>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Anonymouse>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
