package Web::AssetLib::InputEngine::Content;

use Method::Signatures;
use Moose;
use Carp;
use Digest::MD5 'md5_hex';

extends 'Web::AssetLib::InputEngine';

method load ($asset!) {
    croak sprintf( "%s requires 'content' asset input_arg", ref($self) )
        unless $asset->input_args->{content};

    my $contents = $asset->input_args->{content};

    $contents =~ s/^(<script type="text\/javascript">|<script>)//g;
    $contents =~ s/<\/script>$//g;

    my $digest = md5_hex $contents;
    $self->addAssetToCache( $digest => $contents );

    $self->storeAssetContents(
        asset    => $asset,
        digest   => $digest,
        contents => $contents
    );
}

no Moose;
1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::InputEngine::Content - allows importing an asset as a raw string

=head1 SYNOPSIS

    my $library = My::AssetLib::Library->new(
        input_engines => [
            Web::AssetLib::InputEngine::Content->new()
        ]
    );

    my $asset = Web::AssetLib::Asset->new(
        type         => 'javascript',
        input_engine => 'Content',
        input_args => { content => "console.log('hello world');", }
    );

    $library->compile( asset => $asset );

=head1 USAGE

No configuration required. Simply instantiate, and include in your library's
list of input engines.

Assets using the Content input engine must provide C<< content >> input arg.

=head1 SEE ALSO

L<Web::AssetLib::InputEngine>

L<Web::AssetLib::InputEngine::RemoteFile>

L<Web::AssetLib::InputEngine::LocalFile>

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut