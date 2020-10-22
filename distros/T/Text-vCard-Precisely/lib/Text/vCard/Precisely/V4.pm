package Text::vCard::Precisely::V4;

our $VERSION = '0.28';

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::DateTime qw(TimeZone);

extends 'Text::vCard::Precisely::V3';

use Carp;
use Encode;

=encoding utf8

=head1 NAME

Text::vCard::Precisely::V4 - Read, Write and Edit B<vCards 4.0>

=head1 SYNOPSIS
 
You can unlock types that will be available in vCard4.0

 use Text::vCard::Precisely;
 my $vc = Text::vCard::Precisely->new( version => '4.0' );
 # Or you can write like below:
 my $vc4 = Text::vCard::Precisely::V4->new();

The Usage is same with L<Text::vCard::Precisely::V3>

=head1 DESCRIPTION

This module is an additional version for reading/writing for vCard4.0. it's just a wrapper of L<Text::vCard::Precisely::V3|https://metacpan.org/pod/Text::vCard::Precisely::V3>

B<Caution!> It's NOT be recommended because some reasons below:

=over

=item

Mac OS X and iOS can't parse vCard4.0 with UTF-8 precisely.

=item

Android 4.4.x can't parse vCard4.0.

=back

Note that the vCard RFC requires C<FN> type.
And this module does not check or warn if these conditions have not been met.

=cut

use Text::vCard::Precisely::V4::Node;
use Text::vCard::Precisely::V4::Node::N;
use Text::vCard::Precisely::V4::Node::Address;
use Text::vCard::Precisely::V4::Node::Tel;
use Text::vCard::Precisely::V4::Node::Related;
use Text::vCard::Precisely::V4::Node::Member;
use Text::vCard::Precisely::V4::Node::Image;

has version => ( is => 'ro', isa => 'Str', default => '4.0' );

=head1 Constructors

=head2 load_hashref($HashRef)

SAME as 3.0

=head2 loadI<file($file>name)

SAME as 3.0

=head2 load_string($vCard)

SAME as 3.0

=cut

override '_parse_param' => sub {
    my ( $self, $content ) = @_;
    my $ref = super();
    $ref->{'media_type'} = $content->{'param'}{'MEDIATYPE'} if $content->{'param'}{'MEDIATYPE'};
    return $ref;
};

=head1 METHODS

=head2 as_string()

Returns the vCard as a string.
You HAVE TO use C<Encode::encode_utf8()> if your vCard is written in utf8

=cut

my $cr    = "\x0D\x0A";
my @types = qw(
    FN N NICKNAME
    ADR TEL EMAIL IMPP LANG GEO
    ORG TITLE ROLE CATEGORIES RELATED
    NOTE SOUND URL FBURL CALADRURI CALURI
    XML KEY SOCIALPROFILE PHOTO LOGO SOURCE
);

sub as_string {
    my ($self) = @_;
    my $str = $self->_header();
    $str .= $self->_make_types(@types);

    $str .= 'KIND:' . $self->kind() . $cr               if $self->kind();
    $str .= 'BDAY:' . $self->bday() . $cr               if $self->bday();
    $str .= 'ANNIVERSARY:' . $self->anniversary() . $cr if $self->anniversary();
    $str .= 'GENDER:' . $self->gender() . $cr           if $self->gender();
    $str .= 'UID:' . $self->uid() . $cr                 if $self->uid();
    $str .= join '', @{ $self->member() } if $self->member();
    map { $str .= "CLIENTPIDMAP:$_" . $cr } @{ $self->clientpidmap() } if $self->clientpidmap();

    $str .= $self->_footer();
    $str = $self->_fold($str);
    return decode( $self->encoding_out(), $str );
}

=head2 as_file($filename)

Write data in vCard format to $filename.

Dies if not successful.

=head1 SIMPLE GETTERS/SETTERS

These methods accept and return strings.

=head2 version()

Returns Version number of the vcard. Defaults to B<'3.0'>

It is B<READONLY> method. So you can NOT downgrade it to 3.0

=head2 rev()

To specify revision information about the current vCard

The format in as_string() is B<different from 3.0>, but the interface is SAME

=head1 COMPLEX GETTERS/SETTERS

They are based on Moose with coercion

So these methods accept not only ArrayRef[HashRef] but also ArrayRef[Str],
single HashRef or single Str

Read source if you were confused

=head2 n()

The format is SAME as 3.0

=cut

subtype 'v4N' => as 'Text::vCard::Precisely::V4::Node::N';
coerce 'v4N', from 'HashRef[Maybe[Ref]|Maybe[Str]]', via {
    my %param;
    while ( my ( $key, $value ) = each %$_ ) {
        $param{$key} = $value if $value;
    }
    return Text::vCard::Precisely::V4::Node::N->new( \%param );
},
    from 'HashRef[Maybe[Str]]',
    via { Text::vCard::Precisely::V4::Node::N->new( { content => $_ } ) },
    from 'ArrayRef[Maybe[Str]]', via {
    Text::vCard::Precisely::V4::Node::N->new(
        {   content => {
                family     => $_->[0] || '',
                given      => $_->[1] || '',
                additional => $_->[2] || '',
                prefixes   => $_->[3] || '',
                suffixes   => $_->[4] || '',
            }
        }
    )
    },
    from 'Str',
    via { Text::vCard::Precisely::V4::Node::N->new( { content => [ split /(?<!\\);/, $_ ] } ) };
has n => ( is => 'rw', isa => 'v4N', coerce => 1 );

=head2 tel()

The format in as_string() is B<different from 3.0>, but the interface is SAME
 
=cut

subtype 'v4Tels' => as 'ArrayRef[Text::vCard::Precisely::V4::Node::Tel]';
coerce 'v4Tels',
    from 'Str',
    via { [ Text::vCard::Precisely::V4::Node::Tel->new( { content => $_ } ) ] },
    from 'HashRef', via {
    my $types = ref( $_->{'types'} ) eq 'ARRAY' ? $_->{'types'} : [ $_->{'types'} ];
    [ Text::vCard::Precisely::V4::Node::Tel->new( { %$_, types => $types } ) ]
    }, from 'ArrayRef[HashRef]', via {
    [   map {
            my $types = ref( $_->{'types'} ) eq 'ARRAY' ? $_->{'types'} : [ $_->{'types'} ];
            Text::vCard::Precisely::V4::Node::Tel->new( { %$_, types => $types } )
        } @$_
    ]
    };
has tel => ( is => 'rw', isa => 'v4Tels', coerce => 1 );

=head2 adr(), address()

Both are same method with Alias

LABEL param and GEO param are now available

=cut

subtype 'v4Address' => as 'ArrayRef[Text::vCard::Precisely::V4::Node::Address]';
coerce 'v4Address',
    from 'HashRef',
    via { [ Text::vCard::Precisely::V4::Node::Address->new($_) ] }, from 'ArrayRef[HashRef]', via {
    [ map { Text::vCard::Precisely::V4::Node::Address->new($_) } @$_ ]
    };
has adr => ( is => 'rw', isa => 'v4Address', coerce => 1 );

=head2 email()

The format is SAME as 3.0

=head2 url()

The format is SAME as 3.0

=head2 photo(), logo()

The format is SAME as 3.0

=cut

subtype 'v4Photos' => as 'ArrayRef[Text::vCard::Precisely::V4::Node::Image]';
coerce 'v4Photos', from 'HashRef', via {
    my $name = uc [ split /::/, ( caller(2) )[3] ]->[-1];
    return [
        Text::vCard::Precisely::V4::Node::Image->new(
            {   name       => $name,
                media_type => $_->{media_type} || $_->{type},
                content    => $_->{content},
            }
        )
    ]
}, from 'ArrayRef[HashRef]', via {
    [   map {
            if ( ref $_->{types} eq 'ARRAY' ) {
                ( $_->{media_type} ) = @{ $_->{types} };
                delete $_->{types};
            }
            Text::vCard::Precisely::V4::Node::Image->new($_)
        } @$_
    ]
}, from 'Str',    # when parse BASE64 encoded strings
    via {
    my $name = uc [ split /::/, ( caller(2) )[3] ]->[-1];
    return [
        Text::vCard::Precisely::V4::Node::Image->new(
            {   name    => $name,
                content => $_,
            }
        )
    ]
    }, from 'ArrayRef[Str]',    # when parse BASE64 encoded strings
    via {
    my $name = uc [ split /::/, ( caller(2) )[3] ]->[-1];
    return [
        map { Text::vCard::Precisely::V4::Node::Image->new( { name => $name, content => $_, } ) }
            @$_ ]
    }, from 'Object',           # when URI.pm is used
    via { [ Text::vCard::Precisely::V4::Node::Image->new( { content => $_->as_string() } ) ] };
has [qw| photo logo |] => ( is => 'rw', isa => 'v4Photos', coerce => 1 );

=head2 note()

The format is SAME as 3.0

=head2 org(), title(), role(), categories()

The format is SAME as 3.0

=head2 fn(), full_name(), fullname()

They are same method at all with Alias

The format is SAME as 3.0

=head2 nickname()

The format is SAME as 3.0
 
=head2 lang()

To specify the language(s) that may be used for contacting the entity associated with the vCard

It's the B<new method from 4.0>

=head2 impp(), xml()

I don't think they are so popular paramater, but here are the methods!

They are the B<new method from 4.0>

=head2 geo(), key()

The format is SAME as 3.0

=cut

subtype 'v4Nodes' => as 'ArrayRef[Text::vCard::Precisely::V4::Node]';
coerce 'v4Nodes', from 'Str', via {
    my $name = uc [ split /::/, ( caller(2) )[3] ]->[-1];
    return [ Text::vCard::Precisely::V4::Node->new( { name => $name, content => $_ } ) ]
}, from 'HashRef', via {
    my $name = uc [ split /::/, ( caller(2) )[3] ]->[-1];
    return [
        Text::vCard::Precisely::V4::Node->new(
            {   name    => $_->{'name'}  || $name,
                types   => $_->{'types'} || [],
                sort_as => $_->{'sort_as'},
                content => $_->{'content'} || croak "No value in HashRef!",
            }
        )
    ]
}, from 'ArrayRef[Str]', via {
    my $name = uc [ split /::/, ( caller(2) )[3] ]->[-1];
    return [
        map {
            Text::vCard::Precisely::V4::Node->new(
                { name => $name, content => $_ || croak "No value in ArrayRef[Str]!", } )
        } @$_
    ]
}, from 'ArrayRef[HashRef]', via {
    my $name = uc [ split /::/, ( caller(2) )[3] ]->[-1];
    return [
        map {
            Text::vCard::Precisely::V4::Node->new(
                {   name    => $_->{'name'}  || $name,
                    types   => $_->{'types'} || [],
                    sort_as => $_->{'sort_as'},
                    content => $_->{'content'} || croak "No value in HashRef!",
                }
            )
        } @$_
    ]
};
has [qw|note org title role fn lang impp xml geo key|] =>
    ( is => 'rw', isa => 'v4Nodes', coerce => 1 );

=head2 source(), sound()

The formats are SAME as 3.0

=head2 fburl(), caladruri(), caluri()

I don't think they are so popular types, but here are the methods!

They are the B<new method from 4.0>

=cut

has [qw|source sound fburl caladruri caluri|] => ( is => 'rw', isa => 'URLs', coerce => 1 );

subtype 'Related' => as 'ArrayRef[Text::vCard::Precisely::V4::Node::Related]';
coerce 'Related',
    from 'HashRef',
    via { [ Text::vCard::Precisely::V4::Node::Related->new($_) ] }, from 'ArrayRef[HashRef]', via {
    [ map { Text::vCard::Precisely::V4::Node::Related->new($_) } @$_ ]
    };
has related => ( is => 'rw', isa => 'Related', coerce => 1 );

=head2 kind()

To specify the kind of object the vCard represents

It's the B<new method from 4.0>
 
=cut

subtype 'KIND' => as 'Str' =>
    where {m/^(?:individual|group|org|location|[a-z0-9\-]+|X-[a-z0-9\-]+)$/s}
=> message {"The KIND you provided, $_, was not supported"};
has kind => ( is => 'rw', isa => 'KIND' );

subtype 'v4TimeStamp' => as 'Str' => where {m/^\d{8}T\d{6}(?:Z(?:-\d{2}(?:\d{2})?)?)?$/is}
=> message {"The TimeStamp you provided, $_, was not correct"};
coerce 'v4TimeStamp', from 'Str', via {
    m/^(\d{4})-?(\d{2})-?(\d{2})(?:T(\d{2}):?(\d{2}):?(\d{2})Z)?$/is;
    return sprintf '%4d%02d%02dT%02d%02d%02dZ', $1, $2, $3, $4, $5, $6
}, from 'Int', via {
    my ( $s, $m, $h, $d, $M, $y ) = gmtime($_);
    return sprintf '%4d%02d%02dT%02d%02d%02dZ', $y + 1900, $M + 1, $d, $h, $m, $s
}, from 'ArrayRef[HashRef]', via { $_->[0]{content} };
has rev => ( is => 'rw', isa => 'v4TimeStamp', coerce => 1 );

=head2 member(), clientpidmap()

I don't think they are so popular types, but here are the methods!

It's the B<new method from 4.0>

=cut

subtype 'MEMBER' => as 'ArrayRef[Text::vCard::Precisely::V4::Node::Member]';
coerce 'MEMBER',
    from 'UID',
    via { [ Text::vCard::Precisely::V4::Node::Member->new($_) ] }, from 'ArrayRef[UID]', via {
    [ map { Text::vCard::Precisely::V4::Node::Member->new( { content => $_ } ) } @$_ ]
    };
has member => ( is => 'rw', isa => 'MEMBER', coerce => 1 );

subtype 'CLIENTPIDMAP' => as 'Str' =>
    where {m/^\d+;urn:uuid:[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$/is}
=> message {"The CLIENTPIDMAP you provided, $_, was not correct"};
subtype 'CLIENTPIDMAPs' => as 'ArrayRef[CLIENTPIDMAP]';
coerce 'CLIENTPIDMAPs', from 'Str', via { [$_] };
has clientpidmap => ( is => 'rw', isa => 'CLIENTPIDMAPs', coerce => 1 );

=head2 tz(), timezone()

Both are same method with Alias

The format is SAME as 3.0
 
=head2 bday(), birthday()

Both are same method with Alias

The format is SAME as 3.0

=head2 anniversary()

The date of marriage, or equivalent, of the object the vCard represents
 
It's the B<new method from 4.0>

=head2 gender()

To specify the components of the sex and gender identity of the object the vCard represents

It's the B<new method from 4.0>

=head2 prodid()

The format is SAME as 3.0

=cut

has [qw|bday anniversary gender prodid|] => ( is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;
no Moose;

=head1 DEPRECATED Methods

B<They're DEPRECATED in 4.0>

=head2 sort_string()

Use C<SORT-AS> param instead of it

=cut

sub sort_string {
    my $self = shift;
    croak "'SORT-STRING' type is DEPRECATED! Use 'SORT-AS' param instead of it.";
}

=head2 label()

Use C<LABEL> param in C<ADR> instead of it

=cut

sub label {
    my $self = shift;
    croak "'LABEL' Type is DEPRECATED in vCard4.0!";
}

=head2 class(), name(), profile(), mailer()

There is no method for these, just warn if you use them

=cut

sub class {
    my $self = shift;
    croak "'CLASS' Type is DEPRECATED from vCard4.0!";
}

sub name {
    my $self = shift;
    croak "'NAME' Type is DEPRECATED from vCard4.0!";
}

sub profile {
    my $self = shift;
    croak "'PROFILE' Type is DEPRECATED from vCard4.0!";
}

sub mailer {
    my $self = shift;
    croak "'MAILER' Type is DEPRECATED from vCard4.0!";
}

=head2 agent()

Use C<AGENT> param in C<RELATED> instead of it

=cut

sub agent {
    my $self = shift;
    croak "'AGENT' Type is DEPRECATED from vCard4.0! Use AGENT param in RELATED instead of it";
}

1;

=head1 aroud UTF-8

If you want to send precisely the vCard with UTF-8 characters to
the B<ALMOST> of smartphones, Use 3.0

It seems to be TOO EARLY to use 4.0

=head1 for under perl-5.12.5

This module uses C<\P{ascii}> in regexp so You have to use 5.12.5 and later

=head1 SEE ALSO

=over

=item

L<RFC 6350|https://tools.ietf.org/html/rfc6350>

=item

L<Text::vCard::Precisely::V3>

=item

L<vCard on Wikipedia|https://en.wikipedia.org/wiki/VCard>
 
=back
 
=head1 AUTHOR
 
Yuki Yoshida(L<worthmine|https://github.com/worthmine>)

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as Perl.
