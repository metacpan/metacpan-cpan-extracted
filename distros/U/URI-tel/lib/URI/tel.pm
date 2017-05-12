
package URI::tel;

use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.02';

=head1 NAME

URI::tel - The tel URI for Telephone Numbers (RFC 3966)

=head1 SYNOPSIS

    use URI::tel;

    my $uri_client = new URI::tel;

    $uri_client->telephone_uri('tel:+1-201-555-0123');
    print $uri_client->telephone_subscriber, "\n";

    $uri_client->telephone_uri('tel:7042;phone-context=example.com');
    print $uri_client->context, "\n";

    # or

    use URI;
    use URI::tel;

    my $uri = URI->new('tel:+1-201-555-0123')


=head1 DESCRIPTION

The termination point of the "tel" URI telephone number is not
restricted.  It can be in the public telephone network, a private
telephone network, or the Internet.  It can be fixed or wireless and
address a fixed wired, mobile, or nomadic terminal.  The terminal
addressed can support any electronic communication service (ECS),
including voice, data, and fax.  The URI can refer to resources
identified by a telephone number, including but not limited to
originators or targets of a telephone call.

The "tel" URI is a globally unique identifier ("name") only; it does
not describe the steps necessary to reach a particular number and
does not imply dialling semantics.  Furthermore, it does not refer to
a specific physical device, only to a telephone number.

Changes Since RFC 2806

The specification is syntactically backwards-compatible with the
"tel" URI defined in RFC 2806 [RFC2806] but has been completely
rewritten.  This document more clearly distinguishes telephone
numbers as identifiers of network termination points from dial
strings and removes the latter from the purview of "tel" URIs.

Compared to RFC 2806, references to carrier selection, dial context,
fax and modem URIs, post-dial strings, and pause characters have been
removed.  The URI syntax now conforms to RFC 2396 [RFC2396].

=cut

our $VISUAL_SEPARATORS = '-.()';

our %syntax = ( 
    'telephone_subscriber'  => '^tel:',
    'isdn_subaddress'       => '.*;isub=',
    'extension'             => '.*;ext=',
    'context'               => '.*;phone-context='
);

=head1 ATTRIBUTES


=head2 telephone_uri


=head2 isdn_subaddress


=head2 extension


=head2 context


=cut

# The URI package automatically detects URI::* modules installed on a
# system and will try to use them if the * matches the scheme. The URI
# package will then called a method called _init on your package and fail.
# Thanks for Douglas Christopher Wilson

sub _init {
    my ($class, $uri, $scheme) = @_;
#    $uri = "$scheme:$uri" unless $uri =~ m{\A $scheme}x;
    return $class->new(telephone_uri => join(':', 'tel', $uri));
}

sub _init_implementor() {}

subtype 'Istel'
    => as 'Str'
    => where { $_ =~ /^tel:/ }
    => message { 'tel must init with tel:' };

has 'telephone_uri' => (
    is => 'rw',
    isa => 'Istel',
    trigger => sub {
        my $self = shift;
        $self->$_() for map {'_clear_' . $_ } keys %syntax;
    }
);

=head1 METHODS

=head2 telephone_subscriber

=cut

for my $field (keys %syntax) {
    has $field => (
        is => 'ro',
        isa => 'Str',
        lazy => 1,
        clearer => ('_clear_' . $field),
        default => sub {
            my $self = shift;
            my $str = $self->telephone_uri;
            $str =~ s/$syntax{"$field"}//g;
            $str;
        }
    ); 
}

=head2 tel_cmp

Compare two numbers, according to RFC 3866:

- Both must be either local or global numbers.

- The 'global-number-digits' and the 'local-number-digits' must be equal, after removing all visual separators.

=cut

sub tel_cmp () {
    my ($self, $number1, $number2) = @_;
    $number1 =~ s/[$VISUAL_SEPARATORS]//g;
    $number2 =~ s/[$VISUAL_SEPARATORS]//g;
    lc($number1) eq lc($number2);
}

1;

__END__

=head1 CREDITS

Douglas Christopher Wilson

=head1 AUTHOR

Thiago Rondon <thiago@aware.com.br>

http://www.aware.com.br/

=head1 LICENSE

Perl License.

=cut


