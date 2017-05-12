package Web::AssetLib;
our $VERSION = '0.042';

use Method::Signatures;
use Moose;

no Moose;
1;
__END__

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib - Moose-based pluggable library manager for compiling and serving static assets

=head1 VERSION
 
version 0.042

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

Compile assets from that library:

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

Web::AssetLib allows you to build an easy-to-tweak input -> (minfiy) -> output 
pipeline for web assets, as well as a framework for managing those assets.

You have the option to compile groups of assets, or individual
ones.  Out of the box, Web::AssetLib supports L<local file|Web::AssetLib::InputEngine::LocalFile>,
L<remote file|Web::AssetLib::InputEngine::RemoteFile>, and L<string|Web::AssetLib::InputEngine::Content> 
inputs, minification with L<CSS::Minifier> and L<JavaScript::Minifier>, and 
L<local file|Web::AssetLib::OutputEngine::LocalFile> output.

Possibilities for future plugins: Amazon S3 output, other CDN outputs, SASS input, etc.

This documentation uses method signature notation as defined by L<Method::Signatures>.

=head1 USAGE
 
Basic usage is covered in L<Web::AssetLib::Library>.

The following base classes are provided for extendability:

=over 4
 
=item *
 
L<Web::AssetLib::Library> — a base class for writing your own asset library, and configuring the various pipeline plugins
 
=item *
 
L<Web::AssetLib::InputEngine> — a base class for writing your own Input Engine
 
=item *
 
L<Web::AssetLib::OutputEngine> — a base class for writing your own Output Engine
 
=item *
 
L<Web::AssetLib::MinifierEngine> — a base class for writing your own Minifier Engine

=back

The following objects are used to define assets or groups of assets:

=over 4

=item *
 
L<Web::AssetLib::Asset> — a representation of a particular asset in your library
 
=item *
 
L<Web::AssetLib::Bundle> — an indexed grouping of L<Web::AssetLib::Asset> objects
 
=back

Plugins provided by default:

=over 4

=item *
 
L<Web::AssetLib::InputEngine::LocalFile> — allows importing an asset from your local filesystem
 
=item *
 
L<Web::AssetLib::InputEngine::RemoteFile> — allows importing an asset via a URL

=item *
 
L<Web::AssetLib::InputEngine::Content> — allows importing an asset as a raw string

=item *
 
L<Web::AssetLib::MinifierEngine::Standard> — basic CSS/Javascript minification utilizing
either L<CSS::Minifier> and L<JavaScript::Minifier> or L<CSS::Minifier::XS> and L<JavaScript::Minifier::XS>
depending on availability

=item *
 
L<Web::AssetLib::OutputEngine::LocalFile> — allows exporting an asset or bundle to your local filesystem
 
=back

=head1 SUPPORT
 
=head2 Bugs / Feature Requests
 
Please report any bugs or feature requests through the issue tracker
at L<https://github.com/ryan-lang/Web-AssetLib/issues>.
You will be notified automatically of any progress on your issue.
 
=head2 Source Code
 
This is open source software.  The code repository is available for
public review and contribution under the terms of the license.
 
L<https://github.com/ryan-lang/Web-AssetLib>
 
  git clone https://github.com/ryan-lang/Web-AssetLib.git
 
=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut
