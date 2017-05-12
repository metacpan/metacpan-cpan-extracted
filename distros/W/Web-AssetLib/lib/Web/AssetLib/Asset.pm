package Web::AssetLib::Asset;

use Method::Signatures;
use Moose;
use MooseX::Aliases;
use Data::Dumper;
use Digest::MD5 'md5_hex';
use Web::AssetLib::Util;

has 'rank' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0
);

# javascript, css
has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

around 'type' => sub {
    my ( $orig, $self ) = @_;

    return Web::AssetLib::Util::normalizeFileType( $self->$orig );
};

# the engine that knows what to do
has 'input_engine' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'LocalFile'
);

has 'input_args' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

has 'isPassthru' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

has 'default_html_attrs' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

# private attrs:

has 'fingerprint' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        local $Data::Dumper::Terse = 1;
        my $string = sprintf( '%s%s%s',
            $self->type, $self->input_engine, Dumper( $self->input_args ) );
        $string =~ s/\s//g;
        return md5_hex $string;
    }
);

has 'contents' => (
    is     => 'ro',
    isa    => 'Str',
    writer => 'set_contents'
);

has 'digest' => (
    is     => 'ro',
    isa    => 'Str',
    writer => 'set_digest'
);

has 'link_path' => (
    is  => 'rw',
    isa => 'Str'
);

has 'output' => (
    is  => 'rw',
    isa => 'Maybe[Web::AssetLib::Output]'
);

has 'isCompiled' => (
    is      => 'ro',
    isa     => 'Bool',
    writer  => '_set_isCompiled',
    default => 0
);

method as_html ( :$html_attrs = {} ) {
    $self->log->warn('attempting to generate html before asset is compiled')
        unless $self->isCompiled;

    $html_attrs = { %{ $self->default_html_attrs }, %$html_attrs };

    my $tag;
    if ( $self->output ) {
        $tag = Web::AssetLib::Util::generateHtmlTag(
            output     => $self->output,
            html_attrs => $html_attrs
        );
    }

    return $tag;
}

no Moose;

1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::Asset - a representation of a particular asset in your library

=head1 SYNOPSIS

    my $asset = Web::AssetLib::Asset->new(
        type         => 'javascript',
        input_engine => 'LocalFile',
        rank         => -100,
        input_args => { path => "your/local/path/jquery.min.js", }
    );

=head1 ATTRIBUTES
 
=head2 type (required)
 
File type string. Currently supports: js, javascript, css, stylesheet, jpeg, jpg

=head2 input_engine
 
string; partial class name that will match one of the provided input_engines for your library (defaults to "LocalFile") 

=head2 rank
 
number; Assets added to bundles will be exported in the order in which they are added. If an
asset should be exported in a different order, provide a rank.  Lower numbers will 
result in the asset being compiled earlier, and higher numbers will result in the asset
being compiled later.  (defaults to 0)

=head2 input_args
 
hashref; a place to store arguments that the various input plugins may 
require for a given asset (see input plugin docs for specific requirements)

=head2 isPassthru
 
boolean; assets marked isPassthru will not be minified or concatenated

=head2 default_html_attrs
 
hashref; provides html attribute defaults for C<< as_html() >>

=head1 METHODS

=head2 set_digest

    $asset->set_digest( $digest );
 
Stores the digest in the Asset object. (It is required that this value be set, 
if writing your own input engine.)

=head2 set_contents

    $asset->set_contents( $contents );
 
Stores the file contents in the Asset object. (It is required that this value be set, 
if writing your own input engine.)

=head2 fingerprint

    my $fingerprint = $asset->fingerprint();
 
(Somewhat) unique identifier for asset, created by concatenating and hashing: type, input_engine, and input_args.
Helpful to identify asset uniqueness prior to opening and reading the file.

=head2 digest

    my $digest = $asset->digest();
 
Truly unique identifier for asset - an MD5 file digest. Only available after the 
file has been opened and read (compile() has been called on asset), otherwise returns undef.

=head2 as_html

    my $html_tag = $asset->as_html( html_attrs => { async => 'async' } );
 
Returns an HTML-formatted string linking to asset's output location.  Only available after the 
file has been opened and read (compile() has been called on asset), otherwise returns undef.

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut
