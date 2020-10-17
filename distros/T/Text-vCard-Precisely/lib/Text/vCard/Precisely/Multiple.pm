package Text::vCard::Precisely::Multiple;

our $VERSION = '0.27';

use Moose;
use Moose::Util::TypeConstraints;

use Carp;
use Text::vCard::Precisely;
use Text::vFile::asData;
my $vf = Text::vFile::asData->new();
use Path::Tiny;

enum 'Version' => [qw( 3.0 4.0 )];
has version    => ( is => 'ro', isa => 'Version', default => '3.0', required => 1 );

subtype 'vCards' => as 'ArrayRef[Text::vCard::Precisely]';
coerce 'vCards', from 'Text::vCard::Precisely', via { [$_] };
has options => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'vCards',
    coerce  => 1,
    default => sub { [] },
    handles => {
        all_options   => 'elements',
        add_option    => 'push',
        clear_options => 'clear',

        #map_options    => 'map',
        #filter_options => 'grep',
        #find_option    => 'first',
        #get_option     => 'get',
        #join_options   => 'join',
        count_options => 'count',

        #has_options    => 'count',
        has_no_options => 'is_empty',

        #sorted_options => 'sort',
    },
);

__PACKAGE__->meta->make_immutable;
no Moose;

sub load_arrayref {
    my $self = shift;
    my $ref  = shift;
    croak "Attribute must be an ArrayRef: $ref" unless ref($ref) eq 'ARRAY';
    $self->clear_options();

    foreach my $data (@$ref) {
        my $vc = Text::vCard::Precisely->new( version => $self->version() );
        $self->add_option( $vc->load_hashref($data) );
    }
    return $self;
}

sub load_file {
    my $self     = shift;
    my $filename = shift;
    open my $vcf, "<", $filename or croak "couldn't open vcf: $!";
    my $objects = $vf->parse($vcf)->{'objects'};
    close $vcf;

    $self->clear_options();
    foreach my $data (@$objects) {
        croak "$filename contains unvalid vCard data." unless $data->{'type'} eq 'VCARD';
        my $vc      = Text::vCard::Precisely->new( version => $self->version() );
        my $hashref = $vc->_make_hashref($data);
        $self->add_option( $vc->load_hashref($hashref) );
    }
    return $self;
}

sub as_string {
    my $self = shift;
    my $str  = '';
    foreach my $vc ( $self->all_options() ) {
        $str .= $vc->as_string();
    }
    return $str;
}

sub as_file {
    my ( $self, $filename ) = @_;
    croak "No filename was set!" unless $filename;

    my $file = path($filename);
    $file->spew( { binmode => ":encoding(UTF-8)" }, $self->as_string() );
    return $file;
}

1;

__END__

=encoding UTF8

=head1 NAME

Text::vCard::Precisely::Multiple - some add-on for Text::vCard::Precisely

=head1 SYNOPSIS

 use Text::vCard::Precisely::Multiple;
 my $vcm  = Text::vCard::Precisely::Multiple->new();                    # default is 3.0
 my $vcm4 = Text::vCard::Precisely::Multiple->new( version => '4.0' );  # for using 4.0
 
 my $path = path( 'some', 'dir', 'example.vcf' );
 $vcm->load_file($path);

 or

 my $arrayref = [
    {
        N   => [ 'Gump', 'Forrest', '', 'Mr.', '' ],
        FN  => 'Forrest Gump',
        ORG => 'Bubba Gump Shrimp Co.',
        TITLE => 'Shrimp Man',
        TEL => [
            { types => ['WORK','VOICE'], content => '(111) 555-1212' },
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
        }],
        EMAIL => 'forrestgump@example.com',
        REV => '20080424T195243Z',
    },{
        N   => [ 'One', 'Other', '', '', '' ],
        FN  => 'Other One',
        TEL => [
            { types => ['HOME','VOICE'], content => '(404) 555-1212', preferred => 1 },
        ],
        ADR =>[{
            types       => ['home'],
            extended    => 42,
            street      => 'Plantation St.',
            city        => 'Baytown',
            region      => 'LA',
            post_code   => '30314',
            country     => 'United States of America'
        }],
        EMAIL => 'other.one@example.com',
        REV => '20080424T195243Z',
    },
 ];

 $vcm->load_arrayref($arrayref);

 and

 $vcm->as_string();

 or

 $vcm->as_file('output.vcf');

=cut

=head1 DESCRIPTION

If you have a file that  contains multiple vCards, This module may be useful.

=head1 Constructors

=head2 load_arrayref($ArrayRef)

Accepts an ArrayRef that looks like below:

 my $arrayref = [
    {
        N   => [ 'Gump', 'Forrest', '', 'Mr.', '' ],
        FN  => 'Forrest Gump',
        ORG => 'Bubba Gump Shrimp Co.',
        TITLE => 'Shrimp Man',
        TEL => [
            { types => ['WORK','VOICE'], content => '(111) 555-1212' },
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
        }],
        EMAIL => 'forrestgump@example.com',
        REV => '20080424T195243Z',
    },{...}
 ];

=head2 load_file($file_name)

Accepts a file name

=head1 METHODS

=head2 as_string()

Returns the vCards as a single string that is serialized.

=head2 as_file($filename)

Write vCards formated text into a single file to $filename.
Dies if not successful

=head1 SIMPLE GETTERS/SETTERS

These methods accept and return strings

=head2 version()

returns Version number of the vcard.
Defaults to B<'3.0'> and this method is B<READONLY>

=head1 for under perl-5.12.5

This module uses Text::vCard::Precisely and it require you to use 5.12.5 and later

=head1 SEE ALSO

=over

=item

L<RFC 2426|https://tools.ietf.org/html/rfc2426>

=item

L<RFC 2425|https://tools.ietf.org/html/rfc2425>

=item

L<RFC 6350|https://tools.ietf.org/html/rfc6350>

=item

L<Text::vFile::asData>

=back

=head1 AUTHOR

Yuki Yoshida(L<worthmine|https://github.com/worthmine>)

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as Perl.
