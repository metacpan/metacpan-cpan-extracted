package Text::vCard::Precisely::V4::Node;

use Carp;
use Encode qw(decode_utf8);

use Moose;
use Moose::Util::TypeConstraints;

extends 'Text::vCard::Precisely::V3::Node';

enum 'Name' => [
    qw( FN ORG TITLE ROLE
        ADR TEL EMAIL PHOTO LOGO URL
        TZ GEO IMPP LANG XML KEY NOTE
        SOURCE SOUND FBURL CALADRURI CALURI
        RELATED X-SOCIALPROFILE
        )
];
has name => ( is => 'rw', required => 1, isa => 'Name' );

subtype 'SortAs' => as 'Str' =>
    where { decode_utf8($_) =~ m|^[\p{ascii}\w\s]+$|s }    # Does everything pass?
=> message {"The SORT-AS you provided, $_, was not supported"};
has sort_as => ( is => 'rw', isa => 'Maybe[SortAs]' );

subtype 'PIDNum' => as 'Num' => where {m/^\d(?:.\d)?$/s}
=> message {"The PID you provided, $_, was not supported"};
has pid => ( is => 'rw', isa => subtype 'PID' => as 'ArrayRef[PIDNum]' );

subtype 'ALTID' => as 'Int' => where { $_ > 0 and $_ <= 100 }
=> message {"The number you provided, $_, was not supported in 'ALTID'"};
has altID => ( is => 'rw', isa => 'ALTID' );

subtype 'MediaType' => as 'Str' =>
    where {m{^(?:application|audio|example|image|message|model|multipart|text|video)/[\w+\-\.]+$}is}
=> message {"The MediaType you provided, $_, was not supported"};
has media_type => ( is => 'rw', isa => 'MediaType' );

sub as_string {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name() || croak "Empty name";
    push @lines, 'ALTID=' . $self->altID() if $self->altID();
    push @lines, 'PID=' . join ',', @{ $self->pid() } if $self->pid();
    push @lines, 'TYPE="' . join( ',', map {uc} @{ $self->types() } ) . '"'
        if ref $self->types() eq 'ARRAY' and $self->types()->[0];
    push @lines, 'PREF=' . $self->pref()            if $self->pref();
    push @lines, 'MEDIATYPE=' . $self->media_type() if $self->media_type();
    push @lines, 'LANGUAGE=' . $self->language()    if $self->language();
    push @lines, 'SORT-AS="' . $self->sort_as() . '"'
        if $self->sort_as()
        and $self->name() =~ /^(?:FN|ORG)$/;

    my $content = $self->content();
    my $string
        = join( ';', @lines ) . ':'
        . (
        ref($content) eq 'Array'
        ? map { $self->name() eq 'GEO' ? $content : $self->_escape($_) } @$content
        : $self->name() eq 'GEO' ? $content
        :                          $self->_escape($content)
        );
    return $self->fold($string);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
