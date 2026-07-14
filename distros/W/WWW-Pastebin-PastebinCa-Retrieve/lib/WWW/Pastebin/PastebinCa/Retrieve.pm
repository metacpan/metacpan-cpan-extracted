package WWW::Pastebin::PastebinCa::Retrieve;

use warnings;
use strict;

our $VERSION = '1.001003'; # VERSION

use base 'WWW::Pastebin::Base::Retrieve';
use JSON::PP ();
use POSIX ();

# pastebin.ca was rebuilt in 2026 behind a modern API. The old numeric
# ("legacy") pastes were restored and are served through two endpoints:
#   GET /raw/<id>              -> the raw paste body (text/plain)
#   GET /api/v1/legacy/<id>    -> JSON metadata about the paste
# There is no longer an HTML page to scrape, so we fetch the raw body via
# the base class and grab the remaining metadata from the JSON probe.

my $Base = 'https://pastebin.ca';

sub _make_uri_and_id {
    my ( $self, $id ) = @_;

    # Accept either a bare numeric id or any pastebin.ca URL pointing at one.
    $id =~ s{\s+}{}g;
    $id =~ s{^https?://}{}i;
    $id =~ s{^(?:www\.)?pastebin\.ca/}{}i;
    $id =~ s{/(?:raw|dl|edit|embed).*$}{}i;
    $id =~ s{^raw/}{}i;

    return $self->_set_error(
        q|Doesn't look like a correct paste ID or URI|
    ) unless length $id and $id =~ /\A[0-9]+\z/;

    # The URI the base class fetches is the raw-body endpoint; that response
    # becomes the paste content in _get_was_successful().
    return ( URI->new("$Base/raw/$id"), $id );
}

sub _get_was_successful {
    my ( $self, $content ) = @_;

    # $content here is the raw paste body from GET /raw/<id>.
    $self->content( $content );

    my %data = ( content => $content );

    # Pull the remaining metadata (title, language, date) from the JSON probe.
    my $meta_uri = "$Base/api/v1/legacy/" . $self->id;
    my $meta_res = $self->ua->get( $meta_uri );
    if ( $meta_res->is_success ) {
        my $json = eval { JSON::PP::decode_json( $meta_res->decoded_content ) };
        my $p = ref $json eq 'HASH' ? $json->{paste} : undef;
        if ( ref $p eq 'HASH' ) {
            $data{name}     = defined $p->{title} ? $p->{title} : 'Unnamed';
            $data{language} = defined $p->{syntax_hint}
                            ? $p->{syntax_hint} : '';
            $data{post_date} = _format_date( $p->{created_at} );
        }
    }

    # These keys always exist for a consistent return shape, even when the
    # metadata probe is unavailable.
    $data{name}      = 'Unnamed' unless defined $data{name};
    $data{language}  = ''        unless defined $data{language};
    $data{post_date} = ''        unless defined $data{post_date};
    # pastebin.ca no longer stores a separate paste description; kept for
    # backwards compatibility of the return shape.
    $data{desc}      = '';

    return $self->results( \%data );
}

sub _format_date {
    my $ms = shift;
    return '' unless defined $ms and $ms =~ /\A\d+\z/;
    my $epoch = int( $ms / 1000 );
    my @t = gmtime $epoch;
    # e.g. "Thursday, March 6th, 2008 at 3:57:44pm UTC"
    my $day    = POSIX::strftime( '%A',  @t );
    my $month  = POSIX::strftime( '%B',  @t );
    my $mday   = $t[3];
    my $year   = $t[5] + 1900;
    my $suffix = _ordinal_suffix( $mday );
    my $hour24 = $t[2];
    my $ampm   = $hour24 >= 12 ? 'pm' : 'am';
    my $hour12 = $hour24 % 12; $hour12 = 12 unless $hour12;
    my $time   = sprintf '%d:%02d:%02d%s', $hour12, $t[1], $t[0], $ampm;
    return "$day, $month ${mday}${suffix}, $year at $time UTC";
}

sub _ordinal_suffix {
    my $n = shift;
    return 'th' if $n % 100 >= 11 and $n % 100 <= 13;
    my %s = ( 1 => 'st', 2 => 'nd', 3 => 'rd' );
    return $s{ $n % 10 } || 'th';
}

sub _parse {
    # Not used any more: the raw endpoint returns the body directly, and
    # _get_was_successful() assembles the result. Kept as a courtesy for the
    # base-class contract in case a subclass calls it.
    my ( $self, $content ) = @_;
    $self->content( $content );
    return { content => $content, name => 'Unnamed',
             language => '', post_date => '', desc => '' };
}

1;
__END__

=for stopwords desc

=head1 NAME

WWW::Pastebin::PastebinCa::Retrieve - a module to retrieve pastes from http://pastebin.ca/ website

=head1 SYNOPSIS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    my $paster = WWW::Pastebin::PastebinCa::Retrieve->new;

    $paster->retrieve('http://pastebin.ca/951898')
        or die $paster->error;

    print "Paste content is:\n$paster\n";

=for html  </div></div>

=head1 DESCRIPTION

The module provides interface to retrieve pastes from
L<http://pastebin.ca/> website via Perl.

B<Note:> pastebin.ca was rebuilt in 2026 and now exposes a documented API
(see L<https://pastebin.ca/api/v1/openapi.json>) instead of scrapeable HTML.
The original numeric ("legacy") pastes were restored and remain retrievable.
This module fetches a paste's raw body from C<< /raw/<id> >> and its metadata
from C<< /api/v1/legacy/<id> >>.

=head1 CONSTRUCTOR

=head2 C<new>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

    my $paster = WWW::Pastebin::PastebinCa::Retrieve->new;

    my $paster = WWW::Pastebin::PastebinCa::Retrieve->new(
        timeout => 10,
    );

    my $paster = WWW::Pastebin::PastebinCa::Retrieve->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new juicy WWW::Pastebin::PastebinCa::Retrieve
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 C<timeout>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for retrieving. B<Defaults to:> C<30> seconds.

=head3 C<ua>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png">

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for retrieving, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::Pastebin::PastebinCa::Retrieve>'s C<timeout>
argument is set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 C<retrieve>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-hashref.png">

    my $results_ref = $paster->retrieve('http://pastebin.ca/951898')
        or die $paster->error;

    my $results_ref = $paster->retrieve('951898')
        or die $paster->error;

Instructs the object to retrieve a paste specified in the argument. Takes
one mandatory argument which can be either a full URI to the paste you
want to retrieve or just its ID.
On failure returns either C<undef> or an empty list depending on the context
and the reason for the error will be available via C<error()> method.
On success returns a hashref with the following keys/values:

    $VAR1 = {
          'language' => 'perl',
          'content' => 'blah blah content of the paste',
          'post_date' => 'Thursday, March 6th, 2008 at 3:57:44pm UTC',
          'name' => 'Unnamed',
          'desc' => ''
    };

=over 14

=item language

    { 'language' => 'perl' }

The (computer) language / syntax hint of the paste, as reported by
pastebin.ca. B<Note:> since the 2026 site rebuild this is the site's short
syntax code (e.g. C<perl>, C<text>) rather than the long descriptive name
used by the old site.

=item content

    { 'content' => 'select t.terr_id, max(t.start_date) as start_dat' }

The content of the paste.

=item post_date

    { 'post_date' => 'Thursday, March 6th, 2008 at 3:57:44pm UTC' }

The date when the paste was created, formatted from the paste's creation
timestamp (in UTC).

=item name

    { 'name' => 'Unnamed' }

The name of the poster or the title of the paste.

=item desc

    { 'desc' => '' }

Contains description of the paste. B<Note:> pastebin.ca no longer stores a
separate paste description, so this is always an empty string; the key is
retained for backwards compatibility.

=back

=head2 C<error>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    $paster->retrieve('951898')
        or die $paster->error;

On failure C<retrieve()> returns either C<undef> or an empty list depending
on the context and the reason for the error will be available via C<error()>
method. Takes no arguments, returns an error message explaining the failure.

=head2 C<id>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    my $paste_id = $paster->id;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns a paste ID number of the last retrieved paste irrelevant of whether
an ID or a URI was given to C<retrieve()>

=head2 C<uri>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    my $paste_uri = $paster->uri;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns a L<URI> object with the URI pointing to the raw body of the last
retrieved paste irrelevant of whether an ID or a URI was given to
C<retrieve()>

=head2 C<results>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-hashref.png">

    my $last_results_ref = $paster->results;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the exact same hashref the last call to C<retrieve()> returned.
See C<retrieve()> method for more information.

=head2 C<content>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    my $paste_content = $paster->content;

    print "Paste content is:\n$paster\n";

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the actual content of the paste. B<Note:> this method is overloaded
for this module for interpolation. Thus you can simply interpolate the
object in a string to get the contents of the paste.

=head2 C<ua>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-subref.png">

    my $old_LWP_UA_obj = $paster->ua;

    $paster->ua( LWP::UserAgent->new( timeout => 10, agent => 'foos' );

Returns a currently used L<LWP::UserAgent> object used for retrieving
pastes. Takes one optional argument which must be an L<LWP::UserAgent>
object, and the object you specify will be used in any subsequent calls
to C<retrieve()>.

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Retrieve>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Retrieve/issues>

If you can't access GitHub, you can email your request
to C<bug-www-pastebin-pastebinca-retrieve at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
