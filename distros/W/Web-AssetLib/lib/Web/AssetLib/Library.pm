package Web::AssetLib::Library;

use Method::Signatures;
use Moose;
use Carp;
use Scalar::Util qw/blessed/;

use Web::AssetLib::Asset;

with 'Web::AssetLib::Role::Logger';

has 'input_engines' => (
    is      => 'rw',
    isa     => 'ArrayRef[Web::AssetLib::InputEngine]',
    traits  => [qw/Array/],
    handles => { _findInputEngine => 'first', allInputEngines => 'elements' }
);

has 'minifier_engines' => (
    is     => 'rw',
    isa    => 'ArrayRef[Web::AssetLib::MinifierEngine]',
    traits => [qw/Array/],
    handles =>
        { _findMinifierEngine => 'first', allMinifierEngines => 'elements' }
);

has 'output_engines' => (
    is     => 'rw',
    isa    => 'ArrayRef[Web::AssetLib::OutputEngine]',
    traits => [qw/Array/],
    handles =>
        { _findOutputEngine => 'first', allOutputEngines => 'elements' }
);

method compile (:$bundle, :$asset, :$output_engine = 'LocalFile', 
    :$minifier_engine = 'Standard') {

    # possible to pass in a minifier object here
    $minifier_engine = $self->findMinifierEngine($minifier_engine)
        if $minifier_engine && !blessed($minifier_engine);

    $output_engine = $self->findOutputEngine($output_engine);

    if ( $asset && !$bundle ) {
        return $self->_compileAsset(
            asset           => $asset,
            output_engine   => $output_engine,
            minifier_engine => $minifier_engine
        );
    }
    elsif ( $bundle && !$asset ) {
        return $self->_compileBundle(
            bundle          => $bundle,
            output_engine   => $output_engine,
            minifier_engine => $minifier_engine
        );
    }
    elsif ( $bundle && $asset ) {
        croak "cannot provide both bundle and asset - dont know what to do";
    }
    else {
        croak "either asset or bundle must be provided";
    }
}

method _compileBundle (:$bundle!, :$output_engine!, :$minifier_engine?) {

    $self->log->dump( 'attempting to compile assets=',
        $bundle->assets, 'trace' );

    foreach my $asset ( $bundle->allAssets ) {
        my $input_engine = $self->findInputEngine( $asset->input_engine );

        # populate contents and digest attributes
        $input_engine->load($asset);

        # bundle should not contain assets with matching
        # fingerprints, but it's possible that two assets
        # can have different fingerprints, but the same digest
        # (same file, different parameters)

        if ( $asset->digest ) {
            if ( $bundle->getDigest( $asset->digest ) ) {
                my $idx
                    = $bundle->findAssetIdx(
                    sub { $_->digest eq $asset->digest } );
                $bundle->deleteAsset($idx);
                $self->log->dump( 'duplicate digest found for asset=',
                    $bundle->getAsset($idx), 'trace' );
            }
            else {
                $bundle->addDigest( $asset->digest => 1 );
            }
        }
    }

    $bundle->_set_isCompiled(1);

    # output
    return $output_engine->_export(
        bundle   => $bundle,
        minifier => $minifier_engine
    );
}

method _compileAsset (:$asset!,:$output_engine!, :$minifier_engine?) {
    my $input_engine = $self->findInputEngine( $asset->input_engine );
    $input_engine->load($asset);

    $asset->_set_isCompiled(1);

    return $output_engine->_export(
        asset    => $asset,
        minifier => $minifier_engine
    );
}

method findInputEngine ($name!) {
    my $engine = $self->_findInputEngine( sub { ref($_) =~ /$name/ } );
    return $engine if $engine;

    croak
        sprintf( "could not find input engine $name - available engines: %s",
        join( ', ', map { ref($_) } $self->allInputEngines ) );
}

method findMinifierEngine ($name!) {
    my $engine = $self->_findMinifierEngine( sub { ref($_) =~ /$name/ } );
    return $engine if $engine;

    croak
        sprintf(
        "could not find minifier engine $name - available engines: %s",
        join( ', ', map { ref($_) } $self->allMinifierEngines ) );
}

method findOutputEngine ($name!) {
    my $engine = $self->_findOutputEngine( sub { ref($_) =~ /$name/ } );
    return $engine if $engine;

    croak
        sprintf( "could not find output engine $name - available engines: %s",
        join( ', ', map { ref($_) } $self->allOutputEngines ) );
}

no Moose;
1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::Library - a base class for writing your own asset library, and configuring the various pipeline plugins

=head1 SYNOPSIS

Create a library for your project:

    package My::Library;

    use Moose;

    extends 'Web::AssetLib::Library';

    sub jQuery{
        return Web::AssetLib::Asset->new(
            type         => 'javascript',
            input_engine => 'LocalFile',
            rank         => -100,
            input_args => { path => "your/local/path/jquery.min.js", }
        );
    }

    1;

Instantiate your library

    use My::Library;

    # configure at least one input and one output plugin
    # (and optionally, a minifier plugin)
    my $lib = My::Library->new(
        input_engines => [
            Web::AssetLib::InputEngine::LocalFile->new(
                search_paths => ['/my/assets/root/']
            )
        ],
        output_engines => [
            Web::AssetLib::OutputEngine::LocalFile->new(
                output_path => '/my/webserver/path/assets/'
            )
        ]
    );

    # create an asset bundle to represent a group of assets
    # that should be compiled together:

    my $homepage_javascript = Web::AssetLib::Bundle->new();
    $hompage_javascript->addAsset($lib->jQuery);


    # compile your bundle
    my $html_tag = $lib->compile( bundle => $homepage_javascript )->as_html;

=head1 DESCRIPTION

Web::AssetLib::Library holds the instances of the plugins you wish to use. It is also suggested that 
this class be subclassed and used as a place to manage availalbe assets.

=head1 ATTRIBUTES
 
=head2 input_engines
 
Arrayref of L<Web::AssetLib::InputEngine> instance(s) that you wish to use with your library

=head2 minifier_engines
 
Arrayref of L<Web::AssetLib::MinifierEngine> instance(s) that you wish to use with your library
 
=head2 output_engines
 
Arrayref of L<Web::AssetLib::OutputEngine> instance(s) that you wish to use with your library

=head1 METHODS
 
=head2 compile( :$bundle, :$asset, :$output_engine = 'LocalFile', :$minifier_engine = 'Standard' )
 
    $library->compile( bundle => $bundle )
    $library->compile( asset => $asset )

    # specify desired output and/or minifier engine:
    $library->compile( ..., output_engine => 'String', minifier_engine => 'CustomMinifier' );

    # skip minification
    $library->compile( bundle => $bundle, minifier_engine => undef )

    print $bundle->as_html();
    print $library->compile( bundle => $bundle )->as_html()
    # <script src="/your/output.js" type="text/javascript"></script>

Combines and processes a bundle or asset, sending it through the provided minifer, and 
provided output engine.  Provide a type to selectively filter to only a single file type.

=head3 parameters

One of:

=over 4
 
=item *
 
C<< bundle >> - L<Web::AssetLib::Bundle> object

=item *

C<< asset >> - L<Web::AssetLib::Asset> object
 
=back

Optionally:

=over 4

=item *
 
C<< output_engine >> — string; partial class name that will match one of the provided 
output_engines for your library (defaults to "LocalFile")
 
=item *
 
C<< minifier_engine >> — string; partial class name that will match one of the provided 
minifer_engines for your library. Set to undef if no minification is desired. (defaults to "Standard")
 
=item *
 
C<< type >> — string; filter compilation by file type (will output only assets of this type).  The following types are supported: js, javascript, css, stylesheet.

=item *
 
C<< html_attrs >> — hashref; attributes to be included in output html

=back

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut
