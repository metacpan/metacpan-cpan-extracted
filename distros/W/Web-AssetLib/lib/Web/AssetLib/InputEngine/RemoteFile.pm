package Web::AssetLib::InputEngine::RemoteFile;

use Method::Signatures;
use Moose;
use Carp;

use HTTP::Request;
use LWP::UserAgent;
use Digest::MD5 'md5_hex';

extends 'Web::AssetLib::InputEngine';

has 'ua' => (
    is         => 'rw',
    isa        => 'LWP::UserAgent',
    lazy_build => 1
);

method _build_ua () {
    my $ua = LWP::UserAgent->new;
    return $ua;
}

method load ($asset!) {
    croak sprintf( "%s requires 'url' asset input_arg", ref($self) )
        unless $asset->input_args->{url};

    if ( $asset->isPassthru ) {
        $asset->link_path( $asset->input_args->{url} );
        return;
    }
    else {
        my $request
            = $self->_buildRequest( url => $asset->input_args->{url} );
        my $contents = $self->_doRequest( request => $request );

        my $digest = md5_hex $contents;
        $self->addAssetToCache( $digest => $contents );

        $self->storeAssetContents(
            asset    => $asset,
            digest   => $digest,
            contents => $contents
        );
    }
}

method _buildRequest (:$url!) {
    return HTTP::Request->new( GET => $url );
}

method _doRequest (:$request!) {
    my $res = $self->ua->request($request);
    if ( $res->code == 200 ) {
        return $res->decoded_content;
    }
    else {
        croak $res->decoded_content;
    }

}

no Moose;
1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::InputEngine::RemoteFile - allows importing an asset via a URL

=head1 SYNOPSIS

    my $library = My::AssetLib::Library->new(
        input_engines => [
            Web::AssetLib::InputEngine::RemoteFile->new()
        ]
    );

    my $asset = Web::AssetLib::Asset->new(
        type         => 'javascript',
        input_engine => 'RemoteFile',
        input_args   => { url => "http://somecdn.com/asset.js", }
    );

    $library->compile( asset => $asset );

=head1 USAGE

No configuration required. Simply instantiate, and include in your library's
list of input engines.

Assets using the RemoteFile input engine must provide C<< url >> input arg.

=head1 SEE ALSO

L<Web::AssetLib::InputEngine>

L<Web::AssetLib::InputEngine::LocalFile>

L<Web::AssetLib::InputEngine::Content>

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut
