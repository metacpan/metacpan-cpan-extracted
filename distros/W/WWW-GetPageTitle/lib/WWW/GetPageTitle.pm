package WWW::GetPageTitle;

use warnings;
use strict;

our $VERSION = '0.0104';

use LWP::UserAgent;
use HTML::Entities;
use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors( qw/
    error
    title
    ua
    uri
/);

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    $self->ua(
        $args{ua}
        ||
        LWP::UserAgent->new(
            agent    => "Mozilla",
            timeout  => 30,
            max_size => 2000,
        )
    );

    return $self;
}

sub get_title {
    my ( $self, $uri ) = @_;

    $uri = "http://$uri"
        unless $uri =~ m{^(?:https?|ftps?)://}i;

    $self->uri( $uri );

    $self->$_(undef)
        for qw/title error/;

    my $response = $self->ua->get($uri);

    unless ( $response->is_success ) {
        $self->error("Network error: " . $response->status_line );
        return;
    }

    my $title = $response->title;

    unless ( defined $title ) {
        ( $title ) = $response->decoded_content =~ m|<title[^>]*>(.+?)</title>|si;
        decode_entities( $title )
            if defined $title;
    }

    $title = 'N/A'
        unless defined $title;

    return $self->title( $title );
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::GetPageTitle - get titles of web pages

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::GetPageTitle;

    my $t = WWW::GetPageTitle->new;

    $t->get_title('http://zoffix.com')
        or die $t->error;

    printf "Title for %s is %s\n", $t->uri, $t->title;

=head1 DESCRIPTION

The module doesn't do much, it was designed for an IRC bot,
so flames > /dev/null.

The module simply accesses a website and gets its title. 

=head1 IMPORTANT WARNING

B<After reviewing this module 5 years after writing it, I came
across> L<URI::Title>B<, which seems to be much more robust and useful.
If URI::Title does the job for you, please use it, as I might
remove this module in the future, seeing as URI::Title
does the same thing and MORE than this module.>

=head1 CONSTRUCTOR

=head2 C<new>

    my $t = WWW::GetPageTitle->new;

    my $t = WWW::GetPageTitle->new(
        ua => LWP::UserAgent->new(
            agent    => "Mozilla",
            timeout  => 30,
            max_size => 2000,
        )
    );

Constructs and returns a fresh L<WWW::GetPageTitle> object. So far takes one optional
argument in key/value form:

=head3 C<ua>

    my $t = WWW::GetPageTitle->new(
        ua => LWP::UserAgent->new(
            agent    => "Mozilla",
            timeout  => 30,
            max_size => 2000,
        )
    );

The value for the C<ua> argument must be an object that has a C<get()> method that returns
an L<HTTP::Response> object. By default the following is used:

    LWP::UserAgent->new(
        agent    => "Mozilla",
        timeout  => 30,
        max_size => 2000,
    )

=head1 METHODS

=head2 C<get_title>

    my $title = $t->get_title("http://zoffix.com/")
        or die $t->error;

Instructs the object to fetch the title of the page. Takes one mandatory argument which is the
web page of which you want the title. On failure returns either C<undef> or an empty list,
depending on the context, and the description of the error will be available via C<error()>
method. On success returns the title of the page. B<Note:> if argument doesn't match
C<< m{^(?:https?|ftps?)://}i >> then C<http://> will be prepended to it.

=head2 C<error>

    $t->get_title("http://zoffix.com/")
        or die $t->error;

Takes no arguments, returns a human parsable error message explaining why C<get_title()>
failed.

=head2 C<title>

    $t->get_title("http://zoffix.com/")
        or die $t->error;
    my $title = $t->title;

Takes no arguments, must be called after a successful call to C<get_title()>. Returns the
exact same thing as the last call to C<get_title()> returned, i.e. the title of the page.

=head2 C<uri>

    $t->get_title("http://zoffix.com/);
    my $uri = $->uri; # contains http://zoffix.com/

Takes no arguments, must be called after at least one call to C<get_title()>. Returns the
argument passed to the last call of C<get_title()>, which may be modified (see the I<Note:>
in C<get_title()> above).

=head2 C<ua>

    $t->ua( LWP::UserAgent->new );
    my $ua = $t->ua;
    $ua->proxy('http', 'http://foobar.com' );

Takes one optional argument which must satisfy the same criteria as the C<ua> argument in
constructor (C<new()> method). Returns the object that is used to access pages.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

Bug reports and fixes by: Geistteufel

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-getpagetitle at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-GetPageTitle>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::GetPageTitle

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-GetPageTitle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-GetPageTitle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-GetPageTitle>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-GetPageTitle>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

