package WWW::Lipsum;

use strict;
use warnings;

our $VERSION = '1.001012'; # VERSION

use Carp qw/croak/;
use LWP::UserAgent;
use Mojo::DOM;
use Moo;
use overload q|""| => sub {
    my $self = shift;
    my $text = $self->generate;
    return $text || '[Error: ' . $self->error . ']';
};

has what   => ( is => 'rw', default => 'paras'  );
has start  => ( is => 'rw', default => 1        );
has amount => ( is => 'rw', default => 5        );
has html   => ( is => 'rw', default => 0        );
has lipsum => ( is => 'rw', build_args => undef );

has error => ( is => 'rw', build_arg => undef );
has _ua    => ( is => 'ro', build_arg => undef, default => sub {
    return LWP::UserAgent->new( timeout => 30,
        agent => 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:26.0) '
                    . 'Gecko/20100101 Firefox/26.0'
    );
});

sub generate {
    my $self = shift;
    $self->lipsum(undef);

    $self->_prep_args( @_ );

    # sometimes we fail to get decent Lipsum content,
    # so let's retry once in that case and bail out if we still fail
    my $did_already_retry = 0;
    my ( $res, $dom );
    GET_LIPSUM: {
        $res = $self->_ua->post( 'http://lipsum.com/feed/html', {
            amount => $self->amount,
            what   => $self->what,
            start  => $self->start ? 1 : 0,
            generate => 'Generate Lorem Ipsum',
        });

        return $self->_set_error( 'Network error: ' . $res->status_line )
            unless $res->is_success;

        $dom = eval {
            Mojo::DOM->new( $res->decoded_content )
                ->find('#lipsum')
                ->first
                ->children;
        };
        @$ and return $self->_set_error("Parsing error: $@");
        unless ( $dom ) {
            redo GET_LIPSUM unless $did_already_retry;
            $did_already_retry = 1;

            return $self->_set_error(
                'Unknown error. HTML we got from Lipsum is: '
                    . $res->decoded_content
            );
        }
    }

    $self->html
        or return $self->lipsum(
            join "\n\n", map $_->all_text,
                $dom->grep(sub{ $_->tag eq 'p'})->each
        );

    my $html = join '', $dom->each;

    # a little hackery to get rid of lipsum.com's invalid markup
    $self->what eq 'lists' and $html =~ s{<p>|</p>}{}gi;
    $html =~ s/^\s+|\s+$//g;

    return $self->lipsum( $html );
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

sub _prep_args {
    my $self = shift;
    my %args = @_;

    $self->start( $args{start} )
        if exists $args{start};

    $self->html( $args{html} )
        if exists $args{html};

    if ( defined $args{what} ) {
        croak q{Argument 'what' must be one of 'paras', 'words', 'bytes',}
                . q{ or 'lists'}
            unless $args{what} =~ /\A(paras|words|bytes|lists)\z/;

        $self->what( $args{what} );
    }

    if ( defined $args{amount} ) {
        croak q{Argument 'amount' must contain a positive integer}
            unless $args{amount} and $args{amount} =~ /\A\d+\z/;

        $self->amount( $args{amount} );
    }

    return;
}

q|
0 bottles of beer on the wall, 0 bottles of beer! You take one down,
and pass it around, 4294967295 bottles of beer on the wall!
|;

__END__

=encoding utf8

=for stopwords BackPAN Ipsum lipsum Lorem www.lipsum.com. Znet Zoffix

=head1 NAME

WWW::Lipsum - perl interface to www.lipsum.com

=head1 SYNOPSIS

    use WWW::Lipsum;

    my $lipsum = WWW::Lipsum->new(
        html => 1, amount => 50, what => 'bytes', start => 0
    );

    print "$lipsum\n"; # auto-fetches lipsum text


    # Change an arg and check for errors explicitly
    $lipsum->generate( html => 0 )
        or die "Error: " . $lipsum->error;

    print $lipsum->lipsum . "\n";


    # Change some args and fetch using interpolation overload
    $lipsum->start(0);
    $lipsum->amount(5);
    $lipsum->what('paras');

    print "$lipsum\n";

    # generate a whole bunch of lipsums
    my @lipsums = map "$lipsum", 1..10;


=head1 DESCRIPTION

Generate I<Lorem Ipsum> place holder text from perl, using
L<www.lipsum.com|http://www.lipsum.com/>

=head1 SEE ALSO

You most likely want L<Text::Lorem> or L<Text::Lorem::More>
instead of this module, as those generate I<Lorem Ipsum> text without
using a web service.

=head1 METHODS

=head2 C<new>

    my $lipsum = WWW::Lipsum->new;

    my $lipsum = WWW::Lipsum->new(
        html => 1, amount => 50, what => 'bytes', start => 0
    );

Creates and returns a brand new C<WWW::Lipsum> object. Takes
a number of B<optional> arguments that are given as key/value
pairs. These specify the format of the generated lipsum
text and can be changed either individually, using the
appropriate accessor methods, or when calling C<< ->generate >> method.
Possible arguments are as follows:

=head3 C<what>

    my $lipsum = WWW::Lipsum->new( what => 'paras' );
    my $lipsum = WWW::Lipsum->new( what => 'lists' );
    my $lipsum = WWW::Lipsum->new( what => 'words' );
    my $lipsum = WWW::Lipsum->new( what => 'bytes' );

B<Optional.> Specifies in what form to get the
I<Lorem Ipsum> text. Valid values are lowercase strings
C<paras>, C<lists>, C<words>, and C<bytes> that mean to get the text
as C<paragraps>, C<lists>, C<words>, or C<bytes> respectively.
B<Defaults to:> C<paras>.

The meaning is most relevant for the C<amount> argument (see below). The
C<lists> value will cause generation of variable-item-number lists of
I<Lorem Ipsum> text. B<Note:> there seems to be very loose adherence
to the C<amount> you specified and what you get when you
request C<bytes>, and the value seems to be ignored
if C<amount> is set too low.

=head3 C<amount>

    my $lipsum = WWW::Lipsum->new( amount => 10 );

B<Optional.> B<Takes> a positive integer as a value. Large values
will likely be abridged by L<www.lipsum.com|http://www.lipsum.com/> to something reasonable.
Specifies the number of C<what> (see above) things to get.
B<Defaults to:> C<5>.

=head3 C<html>

    my $lipsum = WWW::Lipsum->new( html => 1 );

B<Optional.> B<Takes> true or false values. B<Specifies> whether to wrap
I<Lorem Ipsum> text in HTML markup (will wrap in HTML when set to
a true value). This will be C<< <ul>/<li> >>
elements when C<what> is set to C<lists> and C<< <p> >> elements
for everything else. When set to false, paragraphs and lists will
be separated by double new lines. B<Defaults to:> C<0> (false).

=head3 C<start>

    my $lipsum = WWW::Lipsum->new( start => 0 );

B<Optional.> B<Takes> true or false values as a value. When set
to a true value, will ask L<www.lipsum.com|http://www.lipsum.com/>
to start the generated
text with I<"Lorem Ipsum">. B<Defaults to:> C<1> (true)

B<Note:> it seems sometimes L<www.lipsum.com|http://www.lipsum.com/>
would return text that starts with I<"Lorem Ipsum"> simply by chance.

=head2 C<generate>

    my $text = $lipsum->generate(
        html => 1, amount => 50, what => 'bytes', start => 0
    ) or die $lipsum->error;
    my $x = $text;

    # or
    $lipsum->generate or die $lipsum->error;
    $text = $lipsum->lipsum;

    # or
    my $text = "$lipsum";

Accesses L<www.lipsum.com|http://www.lipsum.com/> to obtain requested
chunk of I<Lorem Ipsum> text.
B<Takes> the same arguments as C<new> (see above); all B<optional>.
B<On success> returns generated I<Lorem Ipsum> text. B<On failure>
returns C<undef> or an empty list, depending on the context, and
the reason for failure will be available via the C<< ->error >> method.

B<Note:> if you call C<< ->generate >> with arguments, the new
values will persist for all subsequent calls to C<< ->generate >>,
until you change them either by, again, passing arguments to
C<< ->generate >>, or by using accessor methods.

You can call C<< ->generate >> by simply interpolating the C<WWW::Lipsum>
object in a string. When called this way, if an error occurs, the
interpolated value will be C<[Error: ERROR_DESCRIPTION_HERE]>, where
C<ERROR_DESCRIPTION_HERE> is the return value of C<< ->error >> method.
On success, the interpolated value will be the generated I<Lorem Ipsum>
text.

=head2 C<lipsum>

    $lipsum->generate or die $lipsum->error;
    $text = $lipsum->lipsum;

B<Takes> no arguments. Must be called after a successful call to
C<< ->generate >>. Returns the same thing the last successful call
to C<< ->generate >> returned.

=head2 C<error>

    $lipsum->generate
        or die 'Error occured: ' . $lipsum->error;

B<Takes> no arguments. Returns the human-readable message, explaining
why the last call to C<< ->generate >> failed.

=head2 C<what>

    my $current_what = $lipsum->what;
    $lipsum->what('paras');
    $lipsum->what('lists');
    $lipsum->what('words');
    $lipsum->what('bytes');

B<Takes> a single B<optional> argument that is the same as the value for the
C<what> argument of the C<< ->new >> method.
When given an argument, modifies the currently active value for the
C<what> argument.
B<Returns> the currently active value of C<what> argument (which
will be the provided argument, if one is given).
See C<< ->new >> method for more info.

=head2 C<start>

    my $current_start = $lipsum->start;
    $lipsum->start(0);
    $lipsum->start(1);

B<Takes> a single B<optional> argument that is the same as the value for the
C<start> argument of the C<< ->new >> method.
When given an argument, modifies the currently active value for the
C<start> argument. B<Returns> the currently active value of C<start>
argument (which will be the provided argument, if one is given).
See C<< ->new >> method for more info.

=head2 C<amount>

    my $current_amount = $lipsum->amount;
    $lipsum->amount(50);
    $lipsum->amount(15);

B<Takes> a single B<optional> argument that is the same as the value for the
C<amount> argument of the C<< ->new >> method.
When given an argument, modifies the currently active value for the
C<amount> argument.
See C<< ->new >> method for more info.

=head2 C<html>

    my $current_html = $lipsum->html;
    $lipsum->html(1);
    $lipsum->html(0);

B<Takes> a single B<optional> argument that is the same as the value for the
C<html> argument of the C<< ->new >> method.
When given an argument, modifies the currently active value for the
C<html> argument. B<Returns> the currently active value of C<html>
argument (which will be the provided argument, if one is given).
See C<< ->new >> method for more info.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/WWW-Lipsum>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/WWW-Lipsum/issues>

If you can't access GitHub, you can email your request
to C<bug-www-lipsum at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=head1 HISTORY AND NOTES ON OLD VERSION

There used to be another version of C<WWW::Lipsum> on CPAN, developed
by Earle Martin. I have a couple of modules that depend on
C<WWW::Lipsum>. Earle, or someone else, subsequently deleted it from
CPAN, leaving my modules dead.

At first, I resurrected Earle's version, but it had a bug. The code
was using L<HTML::TokeParser> and was a pain in the butt
to maintain, and the interface really irked me.
So, I rewrote the whole thing from scratch, broke the API
(more or less), and released the module under a same-as-perl license.

If you are looking for Earle's version, it can still be accessed on
L<BackPAN|http://backpan.perl.org/authors/id/E/EM/EMARTIN/>.

=cut