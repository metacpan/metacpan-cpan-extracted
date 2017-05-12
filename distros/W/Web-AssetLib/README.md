# NAME

Web::AssetLib - Moose-based pluggable library manager for compiling and serving static assets

# VERSION

version 0.042

# SYNOPSIS

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

# DESCRIPTION

Web::AssetLib allows you to build an easy-to-tweak input -> (minfiy) -> output 
pipeline for web assets, as well as a framework for managing those assets.

You have the option to compile groups of assets, or individual
ones.  Out of the box, Web::AssetLib supports [local file](https://metacpan.org/pod/Web::AssetLib::InputEngine::LocalFile),
[remote file](https://metacpan.org/pod/Web::AssetLib::InputEngine::RemoteFile), and [string](https://metacpan.org/pod/Web::AssetLib::InputEngine::Content) 
inputs, minification with [CSS::Minifier](https://metacpan.org/pod/CSS::Minifier) and [JavaScript::Minifier](https://metacpan.org/pod/JavaScript::Minifier), and 
[local file](https://metacpan.org/pod/Web::AssetLib::OutputEngine::LocalFile) output.

Possibilities for future plugins: Amazon S3 output, other CDN outputs, SASS input, etc.

This documentation uses method signature notation as defined by [Method::Signatures](https://metacpan.org/pod/Method::Signatures).

# USAGE

Basic usage is covered in [Web::AssetLib::Library](https://metacpan.org/pod/Web::AssetLib::Library).

The following base classes are provided for extendability:

- [Web::AssetLib::Library](https://metacpan.org/pod/Web::AssetLib::Library) — a base class for writing your own asset library, and configuring the various pipeline plugins
- [Web::AssetLib::InputEngine](https://metacpan.org/pod/Web::AssetLib::InputEngine) — a base class for writing your own Input Engine
- [Web::AssetLib::OutputEngine](https://metacpan.org/pod/Web::AssetLib::OutputEngine) — a base class for writing your own Output Engine
- [Web::AssetLib::MinifierEngine](https://metacpan.org/pod/Web::AssetLib::MinifierEngine) — a base class for writing your own Minifier Engine

The following objects are used to define assets or groups of assets:

- [Web::AssetLib::Asset](https://metacpan.org/pod/Web::AssetLib::Asset) — a representation of a particular asset in your library
- [Web::AssetLib::Bundle](https://metacpan.org/pod/Web::AssetLib::Bundle) — an indexed grouping of [Web::AssetLib::Asset](https://metacpan.org/pod/Web::AssetLib::Asset) objects

Plugins provided by default:

- [Web::AssetLib::InputEngine::LocalFile](https://metacpan.org/pod/Web::AssetLib::InputEngine::LocalFile) — allows importing an asset from your local filesystem
- [Web::AssetLib::InputEngine::RemoteFile](https://metacpan.org/pod/Web::AssetLib::InputEngine::RemoteFile) — allows importing an asset via a URL
- [Web::AssetLib::InputEngine::Content](https://metacpan.org/pod/Web::AssetLib::InputEngine::Content) — allows importing an asset as a raw string
- [Web::AssetLib::MinifierEngine::Standard](https://metacpan.org/pod/Web::AssetLib::MinifierEngine::Standard) — basic CSS/Javascript minification utilizing
either [CSS::Minifier](https://metacpan.org/pod/CSS::Minifier) and [JavaScript::Minifier](https://metacpan.org/pod/JavaScript::Minifier) or [CSS::Minifier::XS](https://metacpan.org/pod/CSS::Minifier::XS) and [JavaScript::Minifier::XS](https://metacpan.org/pod/JavaScript::Minifier::XS)
depending on availability
- [Web::AssetLib::OutputEngine::LocalFile](https://metacpan.org/pod/Web::AssetLib::OutputEngine::LocalFile) — allows exporting an asset or bundle to your local filesystem

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/ryan-lang/Web-AssetLib/issues](https://github.com/ryan-lang/Web-AssetLib/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

[https://github.com/ryan-lang/Web-AssetLib](https://github.com/ryan-lang/Web-AssetLib)

     git clone https://github.com/ryan-lang/Web-AssetLib.git
    

# AUTHOR

Ryan Lang <rlang@cpan.org>
