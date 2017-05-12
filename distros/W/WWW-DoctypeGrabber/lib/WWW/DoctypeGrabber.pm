package WWW::DoctypeGrabber;

use warnings;
use strict;

our $VERSION = '0.007';

use Carp;
use LWP::UserAgent;
use base 'Class::Accessor::Grouped';
use overload q|""|, sub { shift->doctype; };
__PACKAGE__->mk_group_accessors( simple => qw(
    ua
    error
    doctype
    result
    raw
));

sub new {
    my $self = bless {}, shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;
    $args{timeout}  ||= 30;
    $args{max_size} ||= 500;
    $args{ua}       ||= LWP::UserAgent->new(
        timeout  => 30,
        max_size => 500,
        agent    => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.13)'
                   . ' Gecko/20080325 Ubuntu/7.10 (gutsy) Firefox/2.0.0.13',
    );

    $self->ua( $args{ua} );
    $self->raw( $args{raw} );
    return $self;
}

sub grab {
    my ( $self, $uri ) = @_;

    $self->$_(undef) for qw(error  doctype  result);

    $uri = "http://$uri"
        unless $uri =~ m{^https?://};

    my $response = $self->ua->get( $uri );
    if ( $response->is_success ) {
        return $self->result(
            $self->_parse_doctype(
                $response->content,
                $response->header('Content-type'),
            )
        );
    }
    else {
        return $self->_set_error( $response, 'net' );
    }
}

sub _parse_doctype {
    my ( $self, $content, $mime ) = @_;

    my %parse_result = (
        xml_prolog      => 0,
        non_white_space => 0,
        has_doctype     => 0,
        doctype         => '',
        mime            => $mime,
    );

    DOCTYPE_PARSE: {
        if ( my ( $pre_text ) = $content =~ /(.+)(?=<!DOCTYPE)/si ) {
            if ( my $xml_count = $pre_text =~ s/<\?xml[^>]+?\?>//ig ) {
                $parse_result{xml_prolog} = $xml_count;
            }
            $pre_text =~ s/\s+//g;
            $parse_result{non_white_space} = length $pre_text;
        }

        if ( my ( $doctype_string ) = $content =~ m{(<!DOCTYPE[^>]+>)}i ) {
            $parse_result{has_doctype} = 1;
            $doctype_string =~ s/\s+/ /g;
            $doctype_string =~ s/^\s+|\s+$//g;
            $self->raw
                and return $self->doctype($doctype_string);

            if ( $doctype_string
                =~ s{^<!DOCTYPE html PUBLIC "-//W3C//DTD }{}i
            ) {
                my @doctype_bits = ();
                my ( $type ) = $doctype_string =~ m{^[^/]+?(?=//)}g;
                if ( !defined $type ) {
                    $parse_result{doctype} = 'Invalid/Unknown';

                    last DOCTYPE_PARSE;
                }
                $type =~ /^HTML 4.01$/i
                    and $type .= ' Strict';

                push @doctype_bits, $type;
                if ( my ( $dtd_uri ) =
                    $doctype_string =~ m{\s"(\S+)"\s*>$}
                ) {
                    my $dtd_uris = $self->_get_dtd_uri_table;
                    if ( exists $dtd_uris->{ $type } ) {
                        if ( $dtd_uris->{ $type } eq $dtd_uri ) {
                            push @doctype_bits, '+ url';
                        }
                        else {
                            push @doctype_bits, '+ Invalid url';
                        }
                    }
                    else {
                        push @doctype_bits, '+ Unknown url';
                    }
                }
                $parse_result{doctype} = join q| |, @doctype_bits;
            }
            else {
                $parse_result{doctype} = $doctype_string;
            }
        }
        elsif( $self->raw ) {
            return $self->doctype('NO DOCTYPE');
        }
    }

    if ( $parse_result{has_doctype} ) {
        my @bits;
        $parse_result{xml_prolog}
            and push @bits, "+ $parse_result{xml_prolog} XML prolog";

        $parse_result{non_white_space}
            and push @bits, "+ $parse_result{non_white_space} "
                        . "non-whitespace characters";

        $self->doctype( join q| |, $parse_result{doctype}, @bits );
    }
    else {
        $self->doctype('NO DOCTYPE');
    }

    return \%parse_result;
}

sub _get_dtd_uri_table {
    return {
        'HTML 4.01 Strict'                       =>
            'http://www.w3.org/TR/html4/strict.dtd',

        'HTML 4.01 Transitional'                 =>
            'http://www.w3.org/TR/html4/loose.dtd',

        'HTML 4.01 Frameset'                     =>
            'http://www.w3.org/TR/html4/frameset.dtd',

        'XHTML 1.0 Strict'                       =>
            'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd',

        'XHTML 1.0 Transitional'                 =>
            'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd',

        'XHTML 1.0 Frameset'                     =>
            'http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd',

        'XHTML 1.1'                              =>
            'http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd',

        'XHTML Basic 1.0'                        =>
            'http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd',

        'XHTML Basic 1.1'                        =>
            'http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd',

        'XHTML 1.1 plus MathML 2.0 plus SVG 1.1' =>
            'http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd',
    };
}

sub _set_error {
    my ( $self, $error_or_resp, $is_net ) = @_;
    if ( $is_net ) {
        $self->error( 'Network error: ' . $error_or_resp->status_line );
    }
    else {
        $self->error( $error_or_resp );
    }
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::DoctypeGrabber - grab doctypes from webpages

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::DoctypeGrabber;

    my $grabber = WWW::DoctypeGrabber->new;

    my $res_ref = $grabber->grab('http://zoffix.com/')
        or die "Error: " . $grabber->error;

    print "Results: $grabber\n";

=head1 DESCRIPTION

The module was developed to be used in an IRC bot and probably will be
useless for anything else. If your intent is to parse some doctypes of
HTML documents for validness etc. you are probably better off using some
other module.

The module accesses a given URI and checks if the page has doctype,
what kind of doctype, whether or not there are any (non-)whitespace
characters in front of the doctype, whether or not there is an XML prolog
and whether or not the DTD URI matches the ones provided by W3C.

=head1 CONSTRUCTOR

=head2 C<new>

    my $grabber = WWW::DoctypeGrabber->new;

    my $grabber = WWW::DoctypeGrabber->new(
        raw      => 1,
        timeout  => 30,
        max_size => 100,
    );

    my $grabber = WWW::DoctypeGrabber->new(
        ua  => LWP::UserAgent->new(
            agent       => 'SuperUA',
            timeout     => 30,
            max_size    => 500,
        ),
    );

Constructs and returns a new WWW::DoctypeGrabber object. Takes several
arguments as key/value pairs but all of them are optional. The possible
arguments are as follows:

=head3 C<raw>

    ->new( raw => 1 );

B<Optional>. When set to a true value will make the C<grab()> method (see
below) return the full doctype string as it appears in the document ( with
the exception that all whitespace will appear as single spaces ). When
set to a false value will cause the C<grab()> method return a hashref
and interpret the kind of doctype on the page. B<Defaults to:> C<undef>

=head3 C<timeout>

    ->new( timeout => 30 );

B<Optional>. Specifies L<LWP::UserAgent> timeout for the requests.
B<Defaults to:> C<30>

=head3 C<max_size>

    ->new( max_size => 30 );

B<Optional>. Since DOCTYPE is supposed to be at the beginning of the page
we are not really interested in anything past the first bytes of the
document. The C<max_size> argument specifies the "maximum" number of bytes
to download; however the final size may be larger as document is retrieved
in chunks. B<Defaults to:> C<500>

=head3 C<ua>

    ->new( ua => LWP::UserAgent->new( agent => 'Foos' ) );

B<Optional>. If C<timeout> and C<max_size> arguments are not enough for
your needs feel free to specify the C<ua> argument which takes
an L<LWP::UserAgent> object as a value. B<Defaults to:> default
L<LWP::UserAgent> object with C<timeout> and C<max_size>
set WWW::DoctypeGrabber constructor's C<timeout> and C<max_size> arguments
as well as C<agent> argument set to mimic FireFox.

=head1 METHODS

=head2 C<grab>

    my $data_ref = $grabber->grab('http://zoffix.com/')
        or die $grabber->error;

Instructs the object to grab the doctype from the webpage uri of which
is specified as the first and only argument. On failure returns either
C<undef> or an empty list depending on the context and the reason
for failure will be available via C<error> method. On success returns
the raw doctype if C<raw> argument to constructor is set to a true value,
otherwise returns a hashref with the following keys/values:

    $VAR1 = {
        'doctype' => 'HTML 4.01 Strict + url',
        'xml_prolog' => 0,
        'non_white_space' => 0,
        'has_doctype' => 1,
        'mime' => 'text/html; charset=UTF-8'
    };

=head3 C<doctype>

    { 'doctype' => 'HTML 4.01 Strict + url', }

The C<doctype> key will contain the name of the doctype (e.g. HTML 4.01
Strict) and possibly words C<+ url> indicating that a known DTD URI is also
specified. If DTD URI is not recognized the C<doctype> value will say so,
if doctype is not recognized the C<doctype> value will have the doctype
as is. If the page does not have a doctype then C<doctype> will contain an empty string.

=head3 C<xml_prolog>

    { 'xml_prolog' => 0, }

The C<xml_prolog> key will have the number of XML prologs present before
the doctype.

=head3 C<non_white_space>

    { 'non_white_space' => 0, }

The C<non_white_space> key will contain the number of non-whitespace
characters (excluding XML prologs) present before the doctype.

=head3 C<has_doctype>

    { 'has_doctype' => 1 }

The C<has_doctype> key will have either true or false value indicating
whether or not the doctype was found on the page.

=head3 C<mime>

    { 'mime' => 'text/html; charset=UTF-8' }

The C<mime> key will contain the value of the C<Content-type> header.

=head2 C<error>

    $grabber->grab('http://zoffix.com')
        or die $grabber->error;

Takes no arguments, returns an error message explaining why C<grab()>
method failed.

=head2 C<result>

    print "Last doctype: " . $grabber->result->{doctype};

Must be called after a successful call to C<grab()> method. Takes no
arguments, returns the exact same hashref (or raw doctype) last call to
C<grab()> returned.

=head2 C<doctype>

    $grabber->grab('http://zoffix.com');

    print "Doctype is: " . $grabber->doctype . "\n";

    # or

    print "Doctype is: $grabber\n";

Must be called after a successful call to C<grab()> method. Takes no
arguments, returns an "info string" which indicates what doctype is
present on the page (see C<doctype> key in C<grab()>'s return value) as
well as mention about the XML prolog and any non-whitespace characters
present. If no doctype was found on the page the string will only contain
words C<NO DOCTYPE>.

If C<raw> argument (see CONSTRUCTOR) is set to a true value the C<doctype()>
method will return the same raw doctype as C<result()> and C<grab()> method
would.

B<Note:> this method is overloaded for C<q|""|> thus you can simply
interpolate your object in a string to call this method.

=head2 C<raw>

    my $do_get_raw = $grabber->raw;

    $grabber->raw( 1 );

This method is an accessor/mutator of constructor's C<raw> argument.
See "CONSTRUCTOR" section for details. When given the optional argument
will assign a new value to C<raw> argument.

=head2 C<ua>

    my $old_ua = $grabber->ua;

    $grabber->ua( LWP::UserAgent->new( agent => 'foos' ) );

Returns a current L<LWP::UserAgent> object used for retrieving doctypes.
When called with its optional argument which must be an
L<LWP::UserAgent> object will use it in any subsequent calls to C<grab()>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-doctypegrabber at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-DoctypeGrabber>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::DoctypeGrabber

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-DoctypeGrabber>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-DoctypeGrabber>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-DoctypeGrabber>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-DoctypeGrabber>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

