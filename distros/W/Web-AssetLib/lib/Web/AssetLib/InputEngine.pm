package Web::AssetLib::InputEngine;

use Method::Signatures;
use Moose;

with 'Web::AssetLib::Role::Logger';

has 'asset_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    traits  => [qw/Hash/],
    handles => {
        addAssetToCache   => 'set',
        getAssetFromCache => 'get'
    }
);

method storeAssetContents (:$asset!,:$digest!,:$contents!) {
    $asset->set_digest($digest);
    $asset->set_contents($contents);
}

no Moose;
1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::InputEngine - a base class for writing your own Input Engine

=head1 SYNOPSIS

    package My::Library::InputEngine;

    use Moose;

    extends 'Web::AssetLib::InputEngine';

    sub load {
        my ( $self, $asset ) = @_;

        # your special file handing for $asset

        # store the digest and contents with the asset
        $self->storeAssetContents(
            asset    => $asset,
            digest   => $digest,
            contents => $contents
        );
    }

Using the cache:

    sub load {
        ...

		unless( $self->getAssetFromCache($digest) ){
			# not in cache, so load it

			my $contents = ...;

			# add it to the cache
			$self->addAssetToCache( $digest => $contents );
		}
		
        ...
    }

=head1 USAGE

If you have a need for a special file input scenario, you can simply extend this
class, and it will plug in to the rest of the Web::AssetLib pipeline.

The only requirement is that your Input Engine implements the 
L<< load( $asset )|/"load( $asset )" >> method.  Load your file however you wish, 
and then call L<storeAssetContents>.

Optionally, you may utilize the cache, with the 
L<addAssetToCache> and L<getAssetFromCache> methods.

=head1 IMPLEMENTATION

=head2 load( $asset )

Load/consume an asset represented by C<< $asset >>, which will be a 
L<Web::AssetLib::Asset> object.  Load however you'd like, then call
L<storeAssetContents> to store the file for later use in the pipeline.

=head1 METHODS

=head2 storeAssetContents

    $engine->storeAssetContents(
        asset    => $asset,
        digest   => $digest,
        contents => $contents
    );

Associates the file contents and digest with the asset instance.  C<< $asset >>
should be a L<Web::AssetLib::Asset> object, and C<< $contents >> and C<< $digest >>
must be strings.

This is the only method that must be called when you implement the 
L<< load()|/"load( $asset )" >> method.

All arguments are required.

=head2 addAssetToCache

    $engine->addAssetToCache(
        digest => $digest
    );
 
Creates a mapping between your file C<< $digest >> and file C<< $contents >> in the
cache.  It is reccomended that the cache be utilized when implementing L<< load()|/"load( $asset )" >>
but it is not a requirement.

=head2 getAssetFromCache

    my $asset = $engine->getAssetFromCache( $digest );
 
Returns file contents associated with the digest if present in cache, otherwise
returns undef. It is reccomended that the cache be utilized when 
implementing L<< load()|/"load( $asset )" >> but it is not a requirement.

=head1 SEE ALSO

L<Web::AssetLib::InputEngine::LocalFile>

L<Web::AssetLib::InputEngine::RemoteFile>

L<Web::AssetLib::InputEngine::Content>

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut
