# ABSTRACT: turns baubles into trinkets
package Text::vCard::Precisely::V3;

our $VERSION = '0.20';

use 5.8.9;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::DateTime qw(TimeZone);

use Carp;
use Data::UUID;
use Encode;
use Text::LineFold;
use URI;
use Path::Tiny;

=encoding utf8

=head1 NAME

Text::vCard::Precisely::V3 - Read, Write and Edit B<just ONLY vCards 3.0> precisely

=head1 SYNOPSIS

 my $vc = Text::vCard::Precisely->new( version => '3.0' );
 # Or you can write like below if you want to be expressly using 3.0:
 #my $vc = Text::vCard::Precisely::V3->new();

 $vc->n([ 'Gump', 'Forrest', , 'Mr', '' ]);
 $vc->fn( 'Forrest Gump' );

 use GD;
 use MIME::Base64;

 my $img = GD->new( ... some param ... )->plot->png;
 my $base64 = MIME::Base64::encode($img);

 $vc->photo([
    { content => 'https://avatars2.githubusercontent.com/u/2944869?v=3&s=400',  media_type => 'image/jpeg' },
    { content => $img, media_type => 'image/png' }, # Now you can set a binary image directly
    { content => $base64, media_type => 'image/png' }, # Also accept the text encoded in Base64
 ]);

 $vc->org('Bubba Gump Shrimp Co.'); # Now you can set/get org!

 $vc->tel({ content => '+1-111-555-1212', types => ['work'], pref => 1 });

 $vc->email({ content => 'forrestgump@example.com', types => ['work'] });

 $vc->adr( {
    types => ['work'],
    pobox     => '109',
    extended  => 'Shrimp Bld.',
    street    => 'Waters Edge',
    city      => 'Baytown',
    region    => 'LA',
    post_code => '30314,
    country   => 'United States of America',
 });

 $vc->url({ content => 'https://twitter.com/worthmine', types => ['twitter'] }); # for URL param

And you can use X-SOCIALPROFILE type if you want like below:

 use Facebook::Graph;
 use Encode;

 my $fb = Facebook::Graph->new(
    app_id => 'your app id',
    secret => 'your secret key',
 );
 $fb->authorize;
 $fb->access>token( $fb->{'app_id'} . '|' . $fb->{'secret'} );
 my $q = $fb->query->find( 'some facebookID' )
 ->select>fields(qw( id name ))
 ->request
 ->as_hashref;

 $vc->socialprofile({ # Now you can set X-Social-Profile but Android ignore it
    content => 'https://www.facebook/' . 'some facebookID',
    types => 'facebook',
    displayname => encode_utf8( $q->{'name'} ),
    userid => $q->{'id'},
 });

 print $vc->as_string();

=head1 DESCRIPTION

A vCard is a digital business card. vCard and L<Text::vFile::asData|https://github.com/richardc/perl-text-vfile-asdata> provide an API for parsing vCards.

This module is forked from L<Text::vCard|https://github.com/ranguard/text-vcard> because some reason below:

=over

=item

Text::vCard B<doesn't provide> full methods based on L<RFC2426|https://tools.ietf.org/html/rfc2426>

=item

Mac OS X and iOS can't parse vCard4.0 with UTF-8 precisely. they cause some Mojibake

=item

Android 4.4.x can't parse vCard4.0

=back

To handle an address book with several vCard entries in it, start with
L<Text::vFile::asData|https://github.com/richardc/perl-text-vfile-asdata> and then come back to this module.

Note that the vCard RFC requires FN type.
And this module does not check or warn if these conditions have not been met.

=cut

use Text::vFile::asData;
my $vf = Text::vFile::asData->new({ preserve_params => 1 });

use Text::vCard::Precisely::V3::Node;
use Text::vCard::Precisely::V3::Node::N;
use Text::vCard::Precisely::V3::Node::Address;
use Text::vCard::Precisely::V3::Node::Tel;
use Text::vCard::Precisely::V3::Node::Email;
use Text::vCard::Precisely::V3::Node::Image;
use Text::vCard::Precisely::V3::Node::URL;
use Text::vCard::Precisely::V3::Node::SocialProfile;

has encoding_in  => ( is => 'rw', isa => 'Str', default => 'UTF-8', );
has encoding_out => ( is => 'rw', isa => 'Str', default => 'UTF-8', );

=head1 Constructors

=head2 load_hashref($HashRef)

Accepts a HashRef that looks like below:

 my $hashref = {
    N   => [ 'Gump', 'Forrest', '', 'Mr.', '' ],
    FN  => 'Forrest Gump',
    SORT_STRING => 'Forrest Gump',
    ORG => 'Bubba Gump Shrimp Co.',
    TITLE => 'Shrimp Man',
    PHOTO => { media_type => 'image/gif', content => 'http://www.example.com/dir_photos/my_photo.gif' },
    TEL => [
        { types => ['WORK','VOICE'], content => '(111) 555-1212' },
        { types => ['HOME','VOICE'], content => '(404) 555-1212' },
    ],
    ADR =>[{
        types       => ['work'],
        pref        => 1,
        extended    => 100,
        street      => 'Waters Edge',
        city        => 'Baytown',
        region      => 'LA',
        post_code   => '30314',
        country     => 'United States of America'
    },{
        types       => ['home'],
        extended    => 42,
        street      => 'Plantation St.',
        city        => 'Baytown',
        region      => 'LA',
        post_code   => '30314',
        country     => 'United States of America'
    }],
    URL => 'http://www.example.com/dir_photos/my_photo.gif',
    EMAIL => 'forrestgump@example.com',
    REV => '2008-04-24T19:52:43Z',
 };

=cut

sub load_hashref {
    my ( $self, $hashref ) = @_;
    while ( my ( $key, $content ) = each %$hashref ) {
        my $method = $self->can( lc $key );
        next unless $method and $content;
        if ( ref $content eq 'Hash' ) {
            $self->$method( { name => uc($key), %$content } );
        }elsif( ref $content eq 'Array'  ){
            $self->$method({ name => uc($key), @$content });
        }else{
            $self->$method($content);
        }
    }
    return $self;
}

=head2 load_file($file_name)

Accepts a file name

=cut

sub load_file {
    my ( $self, $filename ) = @_;
    open my $vcf, "<", $filename or croak "couldn't open vcf: $!";
    my $data = $vf->parse($vcf)->{'objects'}[0];
    close $vcf;
    
    croak "$filename is NOT a vCard file." unless $data->{'type'} eq 'VCARD';

    my $hashref = $self->_make_hashref($data->{'properties'});
    $self->load_hashref($hashref);
}

=head2 load_string($vCard)

Accepts a vCard string

=cut

sub load_string {
    my ( $self, $str ) = @_;
    my @lines = split /\r\n/, $str;
    my $data = $vf->parse_lines(@lines);
    my $hashref = $self->_make_hashref($data->{'objects'}[0]->{properties});
    $self->load_hashref($hashref);
}

sub _make_hashref {
    my ( $self, $data ) = @_;
    my $hashref = {};
    while( my( $name, $content ) = each %{$data->{'properties'}} ){
        next if $name eq 'VERSION';
        foreach my $node (@$content) {
            if( $name eq 'N' ){
                my @names = split /(?<!\\);/, $node->{'value'};
                $hashref->{$name} ||= \@names;
            }elsif( $name eq 'TEL' ){
                my $content = $node->{'value'};
                $hashref->{$name} = [] unless exists $hashref->{$name};
                if( ref($node->{'params'}) eq 'ARRAY' ){
                    my @types = map{ values %$_ } @{$node->{'params'}};
                    push @{$hashref->{$name}}, { types => \@types, content => $content };
                }elsif( ref($node->{'param'}) eq 'HASH' ){
                    push my @types, sort @{$node->{'params'}} if ref $node->{'params'};
                    push @{$hashref->{$name}}, { types => \@types, content => $content };
                }else{
                    push my @types, $node->{'param'};
                    push @{$hashref->{$name}}, { types => \@types, content => $content };
                }
                $hashref->{$name} ||= $content;
            }elsif( $name eq 'REV' ){
                $hashref->{$name} ||= $node->{'value'};
            }elsif( $name eq 'ADR' ){
                my $ref = $self->_parse_param($node);
                my @addesses = split /(?<!\\);/, $node->{'value'};
                $ref->{'pobox'}     = $addesses[0];
                $ref->{'extended'}  = $addesses[1];
                $ref->{'street'}    = $addesses[2];
                $ref->{'city'}      = $addesses[3];
                $ref->{'region'}    = $addesses[4];
                $ref->{'post_code'} = $addesses[5];
                $ref->{'country'}   = $addesses[6];
                push @{$hashref->{$name}}, $ref;
            }else{
                my $ref = $self->_parse_param($node);
                $ref->{'content'} = $node->{'value'};
                push @{$hashref->{$name}}, $ref;
            }
        }
    }
    return $hashref;
}

sub _parse_param {
    my ( $self, $content ) = @_;
    my $ref = {};
    $ref->{'types'} = [split /,/, $content->{'param'}{'TYPE'}] if $content->{'param'}{'TYPE'};
    $ref->{'pref'} = $content->{'param'}{'PREF'} if $content->{'param'}{'PREF'};
    return $ref;
}

=head1 METHODS

=head2 as_string()

Returns the vCard as a string.
You have to use Encode::encode_utf8() if your vCard is written in utf8

=cut

my $cr = "\x0D\x0A";
our $will_be_deprecated = [qw(name profile mailer agent class)];

my @types = ( qw(
    FN N NICKNAME
    ADR LABEL TEL EMAIL GEO
    ORG TITLE ROLE CATEGORIES
    NOTE SOUND UID URL KEY
    SOCIALPROFILE PHOTO LOGO SOURCE
    SORT-STRING
), map{uc} @$will_be_deprecated );

sub as_string {
    my ($self) = @_;
    my $str = $self->_header();
    $str .= $self->_make_types(@types);
    $str .= 'BDAY:' . $self->bday() . $cr if $self->bday();
    $str .= 'UID:' . $self->uid() . $cr if $self->uid();
    $str .= $self->_footer();
    $str = $self->_fold($str);
    return decode( $self->encoding_out(), $str ) unless $self->encoding_out() eq 'none';
    return $str;
}

sub _header {
    my ($self) = @_;
    my $str = "BEGIN:VCARD" . $cr;
    $str .= 'VERSION:' . $self->version() . $cr;
    $str .= 'PRODID:' . $self->prodid() . $cr if $self->prodid();
    return $str;
}

sub _make_types {
    my $self = shift;
    my $str = '';
    foreach my $node (@_) {
        $node =~ tr/-/_/;
        my $method = $self->can( lc $node );
        croak "the Method you provided, $node is not supported." unless $method;
        if( ref $self->$method eq 'ARRAY' ) {
            foreach my $item ( @{ $self->$method } ){
                if( $item->isa('Text::vCard::Precisely::V3::Node') ){
                    $str .= $item->as_string();
                }elsif($item){
                    $str .= uc($node) . ":" . $item->as_string() . $cr;
                }
            }
        }elsif( $self->$method() and $self->$method()->isa('Text::vCard::Precisely::V3::Node::N') ){
            $str .= $self->$method()->as_string();
        }elsif( $self->$method ){
            $str .= $self->$method();
        }
    }
    return $str;
}

sub _footer {
    my $self = shift;
    my $str = '';
    map { $str .= "TZ:" . $_->name() . $cr } @{ $self->tz() } if $self->tz();
    $str .= 'REV:' . $self->rev() . $cr if $self->rev();
    $str .= "END:VCARD";
    return $str;
}

sub _fold {
    my $self = shift;
    my $str = shift or croak "Can't fold empty strings!";
    my $lf = Text::LineFold->new(   # line break with 75bytes
        CharMax => 74,
        Charset => $self->encoding_in(),
        OutputCharset => $self->encoding_out(),
        Newline => $cr,
    );
    $str = $lf->fold( "", "  ", $str );
    return $str;
}

=head2 as_file($filename)

Write data in vCard format to $filename.
Dies if not successful.

=cut

sub as_file {
    my ( $self, $filename ) = @_;
    croak "No filename was set!" unless $filename;
    
    my $file = path($filename);
    #$file->spew( {binmode => ":encoding(UTF-8)"}, $self->as_string() );
    $file->spew_utf8( $self->as_string() );
    return $file;
}

=head1 SIMPLE GETTERS/SETTERS

These methods accept and return strings

=head2 version()

returns Version number of the vcard. Defaults to B<'3.0'> and this method is B<READONLY>
=cut

has version => ( is => 'ro', isa => 'Str', default => '3.0' );

=head2 rev()

To specify revision information about the current vCard3.0

=cut

subtype 'TimeStamp'
    => as 'Str'
    => where { m/^\d{4}-?\d{2}-?\d{2}(:?T\d{2}:?\d{2}:?\d{2}Z)?$/is }
    => message { "The TimeStamp you provided, $_, was not correct" };
coerce 'TimeStamp',
    from 'Int',
    via {
        my ( $s, $m, $h, $d, $M, $y ) = gmtime($_);
        return sprintf '%4d-%02d-%02dT%02d:%02d:%02dZ', $y + 1900, $M + 1, $d, $h, $m, $s
    },
    from 'ArrayRef[HashRef]',
    via { $_->[0]{'content'} };
has rev => ( is => 'rw', isa => 'TimeStamp', coerce => 1 );

=head2 name(), profile(), mailer(), agent(), class();

These Types will be DEPRECATED in vCard 4.0 and it seems they are useless
So just sapport as B<READONLY> methods
 
=cut

has $will_be_deprecated => ( is => 'ro', isa => 'Str' );

=head1 COMPLEX GETTERS/SETTERS

They are based on Moose with coercion.
So, these methods accept not only ArrayRef[HashRef] but also ArrayRef[Str], single HashRef or single Str.
Read source if you were confused.

=head2 n()

To specify the components of the name of the object the vCard represents.

=cut

subtype 'N' => as 'Text::vCard::Precisely::V3::Node::N';
coerce 'N',
    from 'HashRef[Maybe[Ref]|Maybe[Str]]',
    via {
        my %param;
        while( my ($key, $content) = each %$_ ) {
            $param{$key} = $content if $content;
        }
        return Text::vCard::Precisely::V3::Node::N->new(\%param);
    },
    from 'HashRef[Maybe[Str]]',
    via { Text::vCard::Precisely::V3::Node::N->new($_) },
    from 'ArrayRef[Maybe[Str]]',
    via { Text::vCard::Precisely::V3::Node::N->new({
        family      => $_->[0] || '',
        given       => $_->[1] || '',
        additional  => $_->[2] || '',
        prefixes    => $_->[3] || '',
        suffixes    => $_->[4] || '',
    }) },
    from 'Str',
    via { Text::vCard::Precisely::V3::Node::N->new({ content => [split /(?<!\\);/, $_] }) };
has n => ( is => 'rw', isa => 'N', coerce => 1 );

=head2 tel()

 Accepts/returns an ArrayRef that looks like:

 [
    { type => ['work'], content => '651-290-1234', preferred => 1 },
    { type => ['home'], content => '651-290-1111' },
 ]
 
=cut

subtype 'Tels' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::Tel]';
coerce 'Tels',
    from 'Str',
    via {[ Text::vCard::Precisely::V3::Node::Tel->new({ content => $_ }) ]},
    from 'HashRef',
    via {[       Text::vCard::Precisely::V3::Node::Tel->new({ %$_, types => [@{ $_->{'types'} || [] }] }) ]},
    from 'ArrayRef[HashRef]',
    via {[ map { Text::vCard::Precisely::V3::Node::Tel->new({ %$_, types => [@{ $_->{'types'} || [] }], %$_ }) } @$_ ]};
has tel => ( is => 'rw', isa => 'Tels', coerce => 1 );

=head2 adr(), address()

Accepts/returns an ArrayRef that looks like:

 [
    { types => ['work'], street => 'Main St', pref => 1 },
    { types     => ['home'],
        pobox     => 1234,
        extended  => 'asdf',
        street    => 'Army St',
        city      => 'Desert Base',
        region    => '',
        post_code => '',
        country   => 'USA',
        pref      => 2,
    },
 ]

=cut

subtype 'Address' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::Address]';
coerce 'Address',
    from 'HashRef',
    via { [ Text::vCard::Precisely::V3::Node::Address->new($_) ] },
    from 'ArrayRef[HashRef]',
    via { [ map { Text::vCard::Precisely::V3::Node::Address->new($_) } @$_ ] };
has adr => ( is => 'rw', isa => 'Address', coerce => 1 );

=head2 email()

Accepts/returns an ArrayRef that looks like:

 [
    { type => ['work'], content => 'bbanner@ssh.secret.army.mil' },
    { type => ['home'], content => 'bbanner@timewarner.com', pref => 1 },
 ]

or accept the string as email like below

 'bbanner@timewarner.com'

=cut

subtype 'Email' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::Email]';
coerce 'Email',
    from 'Str',
    via { [ Text::vCard::Precisely::V3::Node::Email->new({ content => $_ }) ] },
    from 'HashRef',
    via { [ Text::vCard::Precisely::V3::Node::Email->new($_) ] },
    from 'ArrayRef[HashRef]',
    via { [ map { Text::vCard::Precisely::V3::Node::Email->new($_) } @$_ ] };
has email => ( is => 'rw', isa => 'Email', coerce => 1 );

=head2 url()

Accepts/returns an ArrayRef that looks like:

 [
    { content => 'https://twitter.com/worthmine', types => ['twitter'] },
    { content => 'https://github.com/worthmine' },
 ]

or accept the string as URL like below

 'https://github.com/worthmine'

=cut

subtype 'URLs' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::URL]';
coerce 'URLs',
    from 'Str',
    via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [Text::vCard::Precisely::V3::Node::URL->new({ name => $name, content => $_ })]
    },
    from 'HashRef[Str]',
    via  {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V3::Node::URL->new({
            name => $name,
            content => $_->{'content'}
        }) ]
    },
    from 'Object',    # Can't asign 'URI' or 'Object[URI]'
    via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [Text::vCard::Precisely::V3::Node::URL->new({
            name => $name,
            content => $_->as_string(),
        })]
    },
    from 'ArrayRef[HashRef]',
    via  { [ map{ Text::vCard::Precisely::V3::Node::URL->new($_) } @$_ ] };
has url => ( is => 'rw', isa => 'URLs', coerce => 1 );

=head2 photo(), logo()

Accepts/returns an ArrayRef of URLs or Images: Even if they are raw image binary or text encoded in Base64, it does not matter
Attention! Mac OS X and iOS B<ignore> the description beeing URL
 use Base64 encoding or raw image binary if you have to show the image you want

=cut

subtype 'Photos' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::Image]';
coerce 'Photos',
    from 'HashRef',
    via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V3::Node::Image->new({
            name => $name,
            media_type => $_->{'media_type'} || $_->{'type'},
            content => $_->{'content'},
        }) ] },
    from 'ArrayRef[HashRef]',
    via { [ map{
        if( ref $_->{types} eq 'ARRAY' ){
            ( $_->{'media_type'} ) = @{$_->{'types'}};
            delete $_->{'types'};
        }
        Text::vCard::Precisely::V3::Node::Image->new($_)
    } @$_ ] },
    from 'Str',   # when parse BASE64 encoded strings
    via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V3::Node::Image->new({
            name => $name,
            content => $_,
        } ) ]
    },
    from 'ArrayRef[Str]',   # when parse BASE64 encoded strings
    via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ map{ Text::vCard::Precisely::V3::Node::Image->new({
            name => $name,
            content => $_,
        }) } @$_ ]
    },
    from 'Object',   # when URI.pm is used
    via { [ Text::vCard::Precisely::V3::Node::Image->new( { content => $_->as_string } ) ] };
has [qw| photo logo |] => ( is => 'rw', isa => 'Photos', coerce => 1 );

=head2 note()

To specify supplemental information or a comment that is associated with the vCard

=head2 org(), title(), role(), categories()

To specify additional information for your jobs
 
=head2 fn(), full_name(), fullname()

A person's entire name as they would like to see it displayed

=head2 nickname()

To specify the text corresponding to the nickname of the object the vCard represents

=head2 geo()

To specify information related to the global positioning of the object the vCard represents

=head2 key()

To specify a public key or authentication certificate associated with the object that the vCard represents

=head2 label()
ToDo: because B<It's DEPRECATED in 4.0>
To specify the formatted text corresponding to delivery address of the object the vCard represents

=cut

subtype 'Node' => as 'ArrayRef[Text::vCard::Precisely::V3::Node]';
coerce 'Node',
    from 'Str',
    via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V3::Node->new( { name => $name, content => $_ } ) ]
    },
    from 'HashRef',
    via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V3::Node->new({
            name => $_->{'name'} || $name,
            types => $_->{'types'} || [],
            content => $_->{'content'} || croak "No value in HashRef!",
        }) ]
    },
    from 'ArrayRef[HashRef]',
    via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ map { Text::vCard::Precisely::V3::Node->new({
            name => $_->{'name'} || $name,
            types => $_->{'types'} || [],
            content => $_->{'content'} || croak "No value in HashRef!",
        }) } @$_ ]
    };
has [qw|note org title role categories fn nickname geo key label|]
    => ( is => 'rw', isa => 'Node', coerce => 1 );

=head2 sort_string()

To specify the family name, given name or organization text to be used for national-language-specific sorting of the FN, N and ORG
B<This method will be DEPRECATED in vCard4.0> Use SORT-AS param instead of it. (L<Text::vCard::Precisely::V4|https://github.com/worthmine/Text-vCard-Precisely/blob/master/lib/Text/vCard/Precisely/V4.pm> supports it)

=cut

has sort_string => ( is => 'rw', isa => 'Node', coerce => 1 );

=head2 uid()

To specify a value that represents a globally unique identifier corresponding to the individual or resource associated with the vCard

=cut

subtype 'UID'
    => as 'Str'
    => where { m/^urn:uuid:[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$/is }
    => message { "The UID you provided, $_, was not correct" };
has uid => ( is => 'rw', isa => 'UID' );

=head2 tz(), timezone()

Both are same method with Alias
To specify information related to the time zone of the object the vCard represents
utc-offset format is NOT RECOMMENDED in vCard 4.0
TZ can be a URL, but there is no document in L<RFC2426|https://tools.ietf.org/html/rfc2426> or L<RFC6350|https://tools.ietf.org/html/rfc6350>
So it just supports some text values

=cut

subtype 'TimeZones' => as 'ArrayRef[DateTime::TimeZone]';
coerce 'TimeZones',
    from 'ArrayRef',
    via {[ map{ DateTime::TimeZone->new( name => $_ ) } @$_ ]},
    from 'Str',
    via {[ DateTime::TimeZone->new( name => $_ ) ]};
has tz =>  ( is => 'rw', isa => 'TimeZones', coerce => 1 );

=head2 bday(), birthday()

Both are same method with Alias
To specify the birth date of the object the vCard represents
 
=cut

has bday => ( is => 'rw', isa => 'Str' );

=head2 prodid()

To specify the identifier for the product that created the vCard object

=cut

subtype 'ProdID' => as 'Str';
coerce 'ProdID',
    from 'ArrayRef[HashRef]',
    via { $_[0]->[0]{'content'} };
has prodid => ( is => 'rw', isa => 'ProdID', coerce => 1 );


=head2 source()

To identify the source of directory information contained in the content type

=head2 sound()

To specify a digital sound content information that annotates some aspect of the vCard
This property is often used to specify the proper pronunciation of the name property value of the vCard
 
=cut

has [qw|source sound|] => ( is => 'rw', isa => 'URLs', coerce => 1 );

=head2 socialprofile()
 
There is no documents about X-SOCIALPROFILE in RFC but it works!

=cut

subtype 'SocialProfile' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::SocialProfile]';
coerce 'SocialProfile',
    from 'HashRef',
    via { [ Text::vCard::Precisely::V3::Node::SocialProfile->new($_) ] },
    from 'ArrayRef[HashRef]',
    via { [ map { Text::vCard::Precisely::V3::Node::SocialProfile->new($_) } @$_ ] };
has socialprofile => ( is => 'rw', isa => 'SocialProfile', coerce => 1 );

__PACKAGE__->meta->make_immutable;
no Moose;

#== Alias =================================================================
sub organization {
    my $self = shift;
    $self->org(@_);
}

sub address {
    my $self = shift;
    $self->adr(@_);
}

sub fullname {
    my $self = shift;
    $self->fn(@_);
}

sub full_name {
    my $self = shift;
    $self->fn(@_);
}

sub birthday {
    my $self = shift;
    $self->bday(@_);
}

sub timezone {
    my $self = shift;
    $self->tz(@_);
}

1;

=head1 aroud UTF-8

if you want to send precisely the vCard3.0 with UTF-8 characters to the B<Android4.4.x or before>, you have to set Charset param for each values like below:

 ADR;CHARSET=UTF-8:201号室;マンション;通り;市;都道府県;郵便番号;日本

=head1 for under perl-5.12.5

This module uses C<\P{ascii}> in regexp so You have to use 5.12.5 and later
And this module uses Data::Validate::URI and it has bug on 5.8.x. so I can't support them

=head1 SEE ALSO

=over

=item

L<RFC 2426|https://tools.ietf.org/html/rfc2426>

=item

L<RFC 2425|https://tools.ietf.org/html/rfc2425>

=item

L<Text::vFile::asData|https://github.com/richardc/perl-text-vfile-asdata>

=item

L<Text::vCard::Precisely::V4 on GitHub|https://github.com/worthmine/Text-vCard-Precisely/blob/master/lib/Text/vCard/Precisely/V4.pm>

=back

=head1 AUTHOR

L<Yuki Yoshida(worthmine)|https://github.com/worthmine>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as Perl.
 
