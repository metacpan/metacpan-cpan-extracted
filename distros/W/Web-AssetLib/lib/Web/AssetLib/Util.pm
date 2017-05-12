package Web::AssetLib::Util;

use Method::Signatures;
use Moose;
use Carp;
use HTML::Element;

use v5.14;
no if $] >= 5.018, warnings => "experimental";

my %FILE_TYPES = (
    js         => 'js',
    javascript => 'js',
    css        => 'css',
    stylesheet => 'css',
    jpeg       => 'jpg',
    jpg        => 'jpg'
);

my %MIME_TYPES = (
    js         => 'text/javascript',
    javascript => 'text/javascript',
    css        => 'text/css',
    stylesheet => 'text/css',
    jpg        => 'image/jpeg',
    jpeg       => 'image/jpeg'
);

func normalizeFileType ($type!) {
    if ( my $normalized = $FILE_TYPES{$type} ) {
        return $normalized;
    }
    else {
        croak "could not map type '$type'";
    }
}

func normalizeMimeType ($type!) {
    if ( my $normalized = $MIME_TYPES{$type} ) {
        return $normalized;
    }
    else {
        croak "could not map type '$type'";
    }
}

func generateHtmlTag (:$output!, :$html_attrs = {}) {
    my $mime = normalizeMimeType( $output->type );
    my $el;

    for ( ref($output) ) {
        when (/Content/) {
            for ($mime) {
                when ('text/css') {
                    $el = HTML::Element->new(
                        'style',
                        type => $mime,
                        %$html_attrs
                    );
                    $el->push_content( $output->content );
                }
                when ('text/javascript') {
                    $el = HTML::Element->new(
                        'script',
                        type => $mime,
                        %$html_attrs
                    );
                    $el->push_content( $output->content );
                }
                when ('image/jpeg') {
                    croak "image/jpeg content output not supported";
                }
            }
        }
        when (/Link/) {
            for ($mime) {
                when ('text/css') {
                    $el = HTML::Element->new(
                        'link',
                        href => $output->src,
                        rel  => 'stylesheet',
                        type => $mime,
                        %$html_attrs
                    );
                }
                when ('text/javascript') {
                    $el = HTML::Element->new(
                        'script',
                        src  => $output->src,
                        type => $mime,
                        %$html_attrs
                    );
                }
                when ('image/jpeg') {
                    $el = HTML::Element->new(
                        'img',
                        src => $output->src,
                        %$html_attrs
                    );
                }
            }
        }
    }

    return $el->as_HTML;
}

no Moose;
1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::Util - core utilties for Web::AssetLib

=head1 FUNCTIONS

=head2 normalizeFileType

    my $type =  normalizeFileType( 'stylesheet' );
    # $type = 'css'

Converts file type string to a normalized version of that string.
e.g. "javascript" maps to "js"

=head2 normalizeMimeType

    my $mime =  normalizeMimeType( 'stylesheet' );
    # $mime = 'text/css'

Converts file type string to a mime type.
e.g. "javascript" maps to "text/javascript"

=head2 generateHtmlTag

    my $output = ... # a Web::AssetLib::Output object

    my $tag = generateHtmlTag(
        output     => $output,
        html_attrs => { async => 'async' }
    );

Generates an HTML tag for a L<Web::AssetLib::Output> object.  Optionally,
C<html_attrs> can be provided.

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut
