package Text::vCard::Precisely::V3::Node;

use Carp;
use Encode qw( decode_utf8 encode_utf8 is_utf8);

use 5.12.5;
use Text::LineFold;

use overload( '""' => \&as_string );

use Moose;
use Moose::Util::TypeConstraints;

enum 'Name' => [
    qw( FN N SORT_STRING ORG TITLE ROLE
        ADR LABEL TEL EMAIL PHOTO LOGO URL SOURCE SOUND
        TZ GEO KEY NOTE
        X-SOCIALPROFILE
        )
];
has name => ( is => 'rw', required => 1, isa => 'Name' );

subtype 'Content' => as 'Str';    # => where {

#    !is_utf8($_) && decode_utf8($_) =~ m|^[\w\p{ascii}\s]+$|s  # It seems these lines
#}    # Does it need to be more strictly?                       # do NOT work
#=> message {"The value you provided, $_, was not supported"};  # like what I've thought
has content => ( is => 'rw', required => 1, isa => 'Content' );

subtype 'Preffered' => as 'Int' => where { $_ > 0 and $_ <= 100 }
=> message {"The number you provided, $_, was not supported in 'Preffered'"};
has pref => ( is => 'rw', isa => 'Preffered' );

subtype 'Type' => as 'Str' => where {
    m/^(?:work|home|PGP)$/is or                       #common
        m|^(?:[a-zA-z0-9\-]+/X-[a-zA-z0-9\-]+)$|s;    # does everything pass?
} => message {"The text you provided, $_, was not supported in 'Type'"};

subtype 'Types' => as 'ArrayRef[Type]';
coerce 'Types'  => from 'Str' => via { [$_] };
has types       => ( is => 'rw', isa => 'Types', default => sub { [] }, coerce => 1 );

subtype 'Language' => as 'Str' =>
    where {m|^[a-z]{2}(?:-[a-z]{2})?$|s}              # does it need something strictly?
=> message {"The Language you provided, $_, was not supported"};
has language => ( is => 'rw', isa => 'Language' );

sub charset {    # DEPRECATED in vCard 3.0
    my $self = shift;
    croak "'CHARSET' param is DEPRECATED! vCard3.0 will accept just ONLY UTF-8";
}

__PACKAGE__->meta->make_immutable;
no Moose;

sub as_string {
    my ($self) = @_;
    my @lines;
    my $node = $self->name();
    $node =~ tr/_/-/;

    push @lines, uc($node) || croak "Empty name";
    push @lines, 'TYPE=' . join( ',', map { uc $_ } @{ $self->types() } )
        if ref $self->types() eq 'ARRAY' and $self->types()->[0];
    push @lines, 'PREF=' . $self->pref()         if $self->pref();
    push @lines, 'LANGUAGE=' . $self->language() if $self->language();

    my $content = $self->content();
    my $string
        = join( ';', @lines ) . ':'
        . (
        ref($content) eq 'Array'
        ? map { $node =~ /^(?:LABEL|GEO)$/s ? $content : $self->_escape($_) } @$content
        : $node =~ /^(?:LABEL|GEO)$/s ? $content
        :                               $self->_escape($content)
        );
    return $self->fold($string);
}

sub fold {
    my $self   = shift;
    my $string = shift;
    my %arg    = @_;
    my $lf     = Text::LineFold->new( CharMax => 74, Newline => "\x0D\x0A", TabSize => 1 )
        ;    # line break with 75bytes
    my $decoded = decode_utf8($string);

    $string =~ s/(?<!\r)\n/\t/g;
    $string
        = ( $decoded =~ /\P{ascii}+/ || $arg{'-force'} )
        ? $lf->fold( "", " ",  $string )
        : $lf->fold( "", "  ", $string );

    $string =~ tr/\t/\n/;

    return $string;
}

sub _escape {
    my $self = shift;
    my $txt  = shift;
    ( my $r = $txt ) =~ s/([,;\\])/\\$1/sg if $txt;
    return $r || '';
}

1;
