package WWW::Pastebin::PastebinCom::Retrieve;

use warnings;
use strict;

our $VERSION = '0.004';

use URI;
use HTML::TokeParser::Simple;
use HTML::Entities;
use base 'WWW::Pastebin::Base::Retrieve';

sub retrieve {
    my $self = shift;
    my $id   = shift;

    $self->$_(undef) for qw(error uri id results);

    return $self->_set_error('Missing or empty paste ID or URI')
        unless defined $id and length $id;

    ( my $uri, $id ) = $self->_make_uri_and_id( $id, @_ )
        or return;

    $self->id( $id );
    $self->uri( $uri );

    # Fetch the raw paste body directly. pastebin.com no longer exposes the
    # paste content in a form we can reliably scrape out of the HTML page, but
    # it still serves the exact, unmodified paste text at /raw/<id>.
    my $ua       = $self->ua;
    my $raw_uri  = URI->new( 'https://pastebin.com/raw/' . $id );
    my $response = $ua->get($raw_uri);

    if ( $response->is_success ) {
        return $self->_get_was_successful( $response->decoded_content );
    }
    elsif ( $response->code == 404 ) {
        return $self->_set_error('This paste does not seem to exist');
    }
    else {
        return $self->_set_error('Network error: ' . $response->status_line);
    }
}

sub _make_uri_and_id {
    my ( $self, $what ) = @_;

    my ( $private, $id ) = $what =~ m{
        (?:https?://)?
        (?:www\.)?
        (.*?) # "private paste" subdomain
        pastebin\.com/
        (?:raw/)? # optional /raw/ prefix if a raw URI was passed in
        (\w+) # paste ID
    }xi;

    $id = $what
        unless defined $id and length $id;

    $private = ''
        unless defined $private;

    return ( URI->new("http://${private}pastebin.com/$id"), $id );
}

sub _get_was_successful {
    my ( $self, $raw_content ) = @_;

    # The raw body IS the paste content -- store it verbatim.
    $self->content($raw_content);

    my %data = ( content => $raw_content );

    # Best-effort scrape of the paste's metadata (name/posted_on/lang) from
    # the human-facing HTML page. The paste content itself never depends on
    # this succeeding, so any failure here degrades gracefully to 'N/A'.
    @data{ qw(name posted_on lang) }
        = $self->_get_metadata( $self->uri );

    for my $key ( qw(name posted_on lang) ) {
        unless ( defined $data{$key} and length $data{$key} ) {
            $data{$key} = 'N/A';
            next;
        }
        decode_entities $data{$key};
        $data{$key} =~ s/\240/ /g;
        $data{$key} =~ s/^\s+|\s+$//g;
    }

    return $self->results( \%data );
}

sub _get_metadata {
    my ( $self, $uri ) = @_;

    my $response = $self->ua->get($uri);
    return
        unless $response->is_success;

    my $content = $response->decoded_content;
    my $parser  = HTML::TokeParser::Simple->new( \$content );

    my ( %meta, %nav );
    while ( my $t = $parser->get_token ) {
        # Author name lives in an <h1> inside the paste's info bar.
        if ( $t->is_start_tag('h1') ) {
            $nav{get_name} = 1;
        }
        elsif ( $nav{get_name} and $t->is_text ) {
            $meta{name} = $t->as_is;
            $nav{get_name} = 0;
        }

        # Post date lives in <div class="date"><span title="...">Mar 22nd,
        # 2008</span>. Grab the first such span's text.
        elsif ( not defined $meta{posted_on}
            and $t->is_start_tag('div')
            and defined $t->get_attr('class')
            and $t->get_attr('class') =~ /\bdate\b/
        ) {
            $nav{in_date} = 1;
        }
        elsif ( $nav{in_date} and $t->is_start_tag('span') ) {
            $nav{get_date} = 1;
        }
        elsif ( $nav{get_date} and $t->is_text ) {
            $meta{posted_on} = $t->as_is;
            @nav{ qw(get_date in_date) } = (0, 0);
        }

        # Language is the first link into the /archive/<lang> section.
        elsif ( not defined $meta{lang}
            and $t->is_start_tag('a')
            and defined $t->get_attr('href')
            and $t->get_attr('href') =~ m{^/archive/}
        ) {
            $nav{get_lang} = 1;
        }
        elsif ( $nav{get_lang} and $t->is_text ) {
            $meta{lang} = $t->as_is;
            $nav{get_lang} = 0;
        }
    }

    return @meta{ qw(name posted_on lang) };
}


=head1 NAME

WWW::Pastebin::PastebinCom::Retrieve - retrieve pastes from http://pastebin.com/ website

=head1 SYNOPSIS

    use strict;
    use warnings;

    use lib '../lib';
    use WWW::Pastebin::PastebinCom::Retrieve;

    die "Usage: perl retrieve.pl <paste_ID_or_URI>\n"
        unless @ARGV;

    my $Paste = shift;

    my $paster = WWW::Pastebin::PastebinCom::Retrieve->new;

    my $results_ref = $paster->retrieve( $Paste )
        or die $paster->error;

    printf "Paste content is:\n%s\nPasted by %s on %s\n",
            @$results_ref{ qw(content name posted_on) };

=head1 DESCRIPTION

The module provides interface to retrieve pastes from
L<http://pastebin.com/> website via Perl.

=head1 CONSTRUCTOR

=head2 C<new>

    my $paster = WWW::Pastebin::PastebinCom::Retrieve->new;

    my $paster = WWW::Pastebin::PastebinCom::Retrieve->new(
        timeout => 10,
    );

    my $paster = WWW::Pastebin::PastebinCom::Retrieve->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new juicy
WWW::Pastebin::PastebinCom::Retrieve
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 C<timeout>

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for retrieving. B<Defaults to:> C<30> seconds.

=head3 C<ua>

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for retrieving, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::Pastebin::PastebinCom::Retrieve>'s C<timeout>
argument is
set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 C<retrieve>

    my $results_ref = $paster->retrieve('http://pastebin.com/f525c4cec')
        or die $paster->error;

    my $results_ref = $paster->retrieve('f525c4cec')
        or die $paster->error;

Instructs the object to retrieve a paste specified in the argument. Takes
one mandatory argument which can be either a full URI to the paste you
want to retrieve or just its ID.
On failure returns either C<undef> or an empty list depending on the context
and the reason for the error will be available via C<error()> method.
On success returns a hashref with the following keys/values:

    $VAR1 = {
        'lang' => 'Perl',
        'posted_on' => 'Sat 22 Mar 16:07',
        'content' => 'blah blah content of the paste',
        'name' => 'Zoffix'
    };

=head3 content

    { 'content' => 'blah blah content of the paste', }

The C<content> key will contain the actual content of the paste. See also
C<content()> method which is overloaded for this class.

=head3 lang

    { 'lang' => 'Perl' }

The C<lang> key will contain the (computer) language of the paste
(as specified by the person who pasted it)

=head3 posted_on

    { 'posted_on' => 'Sat 22 Mar 16:07', }

The C<posted_on> key will contain the date/time when the paste was created.

=head3 name

    { 'name' => 'Zoffix' }

The C<name> key will contain the name of the person who created the paste.


=head2 C<error>

    $paster->retrieve('http://pastebin.com/f525c4cec')
        or die $paster->error;

On failure C<retrieve()> returns either C<undef> or an empty list depending
on the context and the reason for the error will be available via C<error()>
method. Takes no arguments, returns an error message explaining the failure.

=head2 C<id>

    my $paste_id = $paster->id;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns a paste ID number of the last retrieved paste irrelevant of whether
an ID or a URI was given to C<retrieve()>

=head2 C<uri>

    my $paste_uri = $paster->uri;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns a L<URI> object with the URI pointing to the last retrieved paste
irrelevant of whether an ID or a URI was given to C<retrieve()>

=head2 C<results>

    my $last_results_ref = $paster->results;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the exact same hashref the last call to C<retrieve()> returned.
See C<retrieve()> method for more information.

=head2 C<content>

    my $paste_content = $paster->content;

    print "Paste content is:\n$paster\n";

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the actual content of the paste. B<Note:> this method is overloaded
for this module for interpolation. Thus you can simply interpolate the
object in a string to get the contents of the paste.

=head2 C<ua>

    my $old_LWP_UA_obj = $paster->ua;

    $paster->ua( LWP::UserAgent->new( timeout => 10, agent => 'foos' );

Returns a currently used L<LWP::UserAgent> object used for retrieving
pastes. Takes one optional argument which must be an L<LWP::UserAgent>
object, and the object you specify will be used in any subsequent calls
to C<retrieve()>.

=head1 SEE ALSO

L<LWP::UserAgent>, L<URI>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pastebin-pastebincom-retrieve at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Pastebin-PastebinCom-Retrieve>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Pastebin::PastebinCom::Retrieve

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Pastebin-PastebinCom-Retrieve>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Pastebin-PastebinCom-Retrieve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Pastebin-PastebinCom-Retrieve>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Pastebin-PastebinCom-Retrieve>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

