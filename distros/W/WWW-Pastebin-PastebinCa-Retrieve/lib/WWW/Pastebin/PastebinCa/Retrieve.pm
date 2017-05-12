package WWW::Pastebin::PastebinCa::Retrieve;

use warnings;
use strict;

our $VERSION = '1.001002'; # VERSION

use base 'WWW::Pastebin::Base::Retrieve';
use HTML::TokeParser::Simple;
use HTML::Entities;

sub _make_uri_and_id {
    my ( $self, $id ) = @_;

    my ( $private ) = $id =~ m{(?:http://)? (?:www\.)? (.+?) pastebin\.ca};

    $private = ''
        unless defined $private;

    $id =~ s{ ^ \s+ | (?:http://)? (?:www\.)?.*? pastebin\.ca/ | \s+ $}{}gxi;
    return ( URI->new("http://${private}pastebin.ca/$id"), $id );
}

sub _parse {
    my ( $self, $content ) = @_;
    return $self->_set_error( 'Nothing to parse (empty document retrieved)' )
        unless defined $content and length $content;

    my $parser = HTML::TokeParser::Simple->new( \$content );

    my %data;
    my %nav = (
        level       => 0,
        get_lang    => 0,
        get_name    => 0,
        get_date    => 0,
        get_desc    => 0,
    );
    while ( my $t = $parser->get_token ) {
        if ( $t->is_start_tag('h2')
            #and defined $t->get_attr('class')
            #and $t->get_attr('class') eq 'first'
        ) {

            $nav{level} = 1;
        }
        elsif ( $nav{level} == 1 and $t->is_start_tag('dt') ) {
            @nav{ qw(level  get_name) } = (2, 1);
        }
        elsif ( $nav{get_name} == 1 and $t->is_text ) {
            $data{name} = $t->as_is;
            $nav{get_name} = 0;
        }
        elsif ( $t->is_start_tag('p') and defined $t->get_attr('id')
            and $t->get_attr('id') eq 'des'
        ) {
            $nav{get_desc} = 1;
        }
        elsif ( $nav{get_desc} and $t->is_text ) {
            $data{desc} = $t->as_is;
            $nav{get_desc} = 0;
        }
        elsif ( $nav{level} == 2 and $t->is_start_tag('dd') ) {
            $nav{get_date} = 1;
            $nav{level}++;
        }
        elsif ( $nav{get_date} and $t->is_text ) {
            $data{post_date} = $t->as_is;
            $data{post_date} =~ s/\s+/ /g;
            $data{post_date} =~ s/&nbsp;//g;
            $nav{get_date}   = 0;
            $nav{level} = 7;
        }
        elsif ( $nav{level} == 7 and $t->is_start_tag('span') ) {
            $nav{level}++;
        }
        elsif ( $t->is_start_tag('textarea')
            and defined $t->get_attr('name')
            and $t->get_attr('name') eq 'content' ) {
            $nav{get_paste} = 1;
        }
        elsif ( $nav{get_paste} and $t->is_text ) {
            $data{content} = $t->as_is;
            $nav{get_paste} = 0;
            $nav{get_lang} = 1;
        }
        elsif ( $nav{get_lang} == 1 and  $t->is_start_tag('select') ) {
            $nav{get_lang} = 2;
        }
        elsif ( $nav{get_lang} == 2 and $t->is_start_tag('option')
            and $t->get_attr('selected')
        ) {
            $nav{get_lang} = 3;
        }
        elsif ( $nav{get_lang} == 3 and $t->is_text ) {
            $data{language} = $t->as_is;
            $nav{success} = 1;
            last;
        }

    }
    unless ( $nav{success} ) {
        my $message = "Failed to parse paste.. ";
        $message .= $nav{level}
                  ? "\$nav{level} == $nav{level}"
                  : "that paste ID doesn't seem to exist";
        return $self->_set_error( $message );
    }

    decode_entities( $_ ) for values %data;

    $self->content( $data{content} );
    return \%data;
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
          'language' => 'Raw',
          'content' => 'blah blah content of the paste',
          'post_date' => 'Friday, March 21st, 2008 at 1:05:19pm MDT',
          'name' => 'Unnamed',
          'desc' => 'Perl stuff'
    };

=over 14

=item language

    { 'language' => 'Raw' }

The (computer) language of the paste.

=item content

    { 'content' => 'select t.terr_id, max(t.start_date) as start_dat' }

The content of the paste.

=item post_date

    { 'post_date' => 'Wednesday, March 5th, 2008 at 10:31:42pm MST' }

The date when the paste was created

=item name

    { 'name' => 'Mine' }

The name of the poster or the title of the paste.

=item desc

    { 'desc' => 'Perl stuff' }

Contains description of the paste.

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
returns a L<URI> object with the URI pointing to the last retrieved paste
irrelevant of whether an ID or a URI was given to C<retrieve()>

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
