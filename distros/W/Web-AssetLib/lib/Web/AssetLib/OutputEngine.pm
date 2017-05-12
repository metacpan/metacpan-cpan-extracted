package Web::AssetLib::OutputEngine;

use Method::Signatures;
use Moose;
use HTML::Element;
use Digest;
use Encode qw(encode encode_utf8);
use Carp;

use v5.14;
no if $] >= 5.018, warnings => "experimental";

with 'Web::AssetLib::Role::Logger';

method _export (:$bundle?, :$asset?, :$minifier?) {
    if ( $asset && !$bundle ) {
        return $self->_exportAsset(
            asset    => $asset,
            minifier => $minifier
        );
    }
    elsif ( $bundle && !$asset ) {
        return $self->_exportBundle(
            bundle   => $bundle,
            minifier => $minifier
        );
    }
    elsif ( $bundle && $asset ) {
        croak "cannot provide both bundle and asset - dont know what to do";
    }
    else {
        croak "either asset or bundle must be provided";
    }
}

method _exportBundle (:$bundle!,:$minifier?) {
    my $output = $self->export(
        assets   => $bundle->assets,
        minifier => $minifier
    );

    $bundle->output($output);
    return $bundle;
}

method _exportAsset (:$asset!,:$minifier?) {
    my $output = $self->export(
        assets   => [$asset],
        minifier => $minifier
    );

    $asset->output($output);
    return $asset;
}

method generateDigest ($contents) {
    my $digest = Digest->new("MD5");
    $digest->add( encode_utf8($contents) );
    return $digest->hexdigest;
}

no Moose;
1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::OutputEngine - a base class for writing your own Output Engine

=head1 SYNOPSIS

    package My::Library::OutputEngine;

    use Method::Signatures;
    use Moose;

    extends 'Web::AssetLib::OutputEngine';

    method export ( :$assets!, :$minifier? ) {
        # see Web::AssetLib::OutputEngine::LocalFile for examples
    }

=head1 USAGE

If you have a need for a special file output scenario, you can simply extend this
class, and it will plug in to the rest of the Web::AssetLib pipeline.

The only requirement is that your Output Engine implements the 
L<export> method, which returns a properly-formatted HTML tag as a string.

=head1 IMPLEMENTATION

=head2 export

Process the arrayref of L<Web::AssetLib::Asset> objects, and export a file with type
C<< $type >>.  If C<< $mininfier >> is provided (will be a 
L<Web::AssetLib::MinifierEngine> instance), then it is your responsibility to 
call L<< $minifier->minify()|Web::AssetLib::MinifierEngine/"minify( :$contents!, :$type! )" >>.

export() should return a properly-formatted HTML tag as a string.

For help with common ouput operations, see the provided methods below.

=head1 METHODS

=head2 generateDigest
 
Pass in an arrayref of L<Web::AssetLib::Asset> objects, and returns
a string of the concatenated contents, and an MD5 digest string.

=head1 SEE ALSO

L<Web::AssetLib::OutputEngine::LocalFile>

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut
