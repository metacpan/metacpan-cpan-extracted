package Web::PerlDistSite;
use utf8;

=pod

=encoding utf-8

=head1 NAME

Web::PerlDistSite - generate fairly flashy websites for CPAN distributions

=head1 DESCRIPTION

Basically a highly specialized static site generator.

=head2 Prerequisites

You will need B<cpanm>.

You will need B<nodejs> with B<npm>.

You will need B<make>.

=head2 Setup

Create a directory and copy the example F<Makefile> and F<package.json>
files from this distribution into it. Then run C<< make install >> to
install additional Nodejs and Perl dependencies.

=head2 Site Configuration

Configuration is via a file F<config.yaml>. This is a YAML file containing
a hash with the following keys. Each key is optional, unless noted as required.
An example F<config.yaml> is included in this distribution.

=over

=item C<< theme >> I<< (required) >>

A hashref of colour codes. You need at least "primary", "secondary", "light",
and "dark". "info", "success", "warning", and "danger" are also allowed.

  theme:
    light: "#e4e3e1"
    dark: "#32201D"
    primary: "#763722"
    secondary: "#E4A042"

A good colour generator can be found at L<https://huemint.com/bootstrap-basic/>
if you're stuck for ideas.

The C<theme> hashref can also include Bootstrap's non-colour SASS options.
See L<https://getbootstrap.com/docs/5.2/customize/options/>.

An example is:

  theme:
    light: "#e4e3e1"
    dark: "#32201D"
    primary: "#763722"
    secondary: "#E4A042"
    "enable-shadows": "true"

=item C<< name >> I<< (required) >>

The name of the project you're building a website for. This is assumed
to be a CPAN distribution name, like "Exporter-Tiny" or "Foo-Bar-Baz".

=item C<< abstract >> I<< (required) >>

A short plain-text summary of the project.

=item C<< abstract_html >>

A short HTML summary of the project.

=item C<< copyright >> I<< (required) >>

A short plain-text copyright statement for the website footers.

=item C<< github >>

Link to a GitHub repo for the site. Expected to be of the form
"https://github.com/username/reponame".

=item C<< issues >>

Link to an issue tracker.

=item C<< sponsor >>

Hashref containing project sponsorship info. The "html" key is required.
The "href" key is optional.

  sponsor:
    html: "<strong>Please sponsor us!</strong> Blah blah blah."
    href: https://paypal.example/foo-bar-baz

=item C<< menu >>

A list of files to include in the navbar. If this key is missing, will
be loaded from F<menu.yaml> instead.

=item C<< homepage >>

Hashref of options for the homepage (index.html). May contain keys
"animation", "banner", "banner_fixation", "banner_position_x", and
"banner_position_y".

The "animation" may be "waves1", "waves2", "swirl1", "attract1", or "circles1".
Each of these will create a pretty animation on the homepage. Some
day I'll add support for more animations.

If "animation" is not defined, then "banner" can be used to supply
the URL of a static image to use instead of an animation.

"banner_fixation" can be "scroll" or "fixed", and defaults to the latter.
"banner_position_x" can be "left", "center", or "right". "banner_position_y"
can be "top", "center", or "bottom". These each default to "center".

"hero_options" is I<itself> a hashref and allows various parts of the
banner/animation to be overridden. In particular, "title" and "abstract".

  homepage:
    animation: waves1
    hero_options:
      title: "Blah"
      abstract: "Blah blah blah"

In the future, more homepage options may be available.

=item C<< dist_dir >>

Directory for output. Defaults to a subdirectory called "docs".

=item C<< root_url >>

URL for the output. Can be an absolute URL, but something like "/"
is probably okay. (That's the default.)

=item C<< codestyle >>

Name of a highlight.js theme, used for code syntax highlighting.
Defaults to "github".

=item C<< pod_filter >>

A list of section names which will be filtered out of pages generated
from pod files. Uses "|" as a separator. Defaults to:
"NAME|BUGS|AUTHOR|THANKS|COPYRIGHT AND LICENCE|DISCLAIMER OF WARRANTIES".

=item C<< pod_titlecase >>

Boolean. Should ALL CAPS "=head1" headings from pod be converted to
Title Case? Defaults to true.

=item C<< pod_downgrade_headings >>

Converts pod "=head1" to C<< <h2> >> tags in HTML, etc.

=back

=head2 Menu Configuration

The menu can be configured under the C<menu> key of F<config.yaml>, or in
a separate file F<menu.yaml>. This is a list of menu items. For example:

  - name: installation
    title: Installation
    source: _pages/installation.md
  - name: hints
    title: Hints and Tips
    source: _pages/hints.pod
  - name: manual
    title: Manual
    children:
      - name: Foo-Bar
        pod: Foo::Bar
      - name: Foo-Bar-Baz
        pod: Foo::Bar::Baz

The C<name> key is used for the output filename. ".html" is automatically
appended.

The C<title> key is the title of the document generated. It is used in the
navbar and in the page's C<< C<title> >> element.

Each entry needs a C<source> which is an input filename. The input may
be pod or markdown. (At some future point, HTML input will also be supported.)

If the C<pod> key is found, we'll find the pod via C<< @INC >>, like
perldoc does. This will helpfully also default C<title> and C<name> for you!

A C<children> key allows child pages to be listed. Only one level of nesting
is supported in the navbar, but if further levels of nesting are used, these
pages will still be built. (You'll just need to link to them manually somehow.)

A C<meta> key allows you to provide metadata for a page. It's an array of
hashrefs. Each item in the array will result in a C<< <meta content=""> >>
or C<< <link href=""> >> tag added to the document's C<< <head> >>. For
example:

      - name: installation
        title: How to install
        source: _pages/installation.html
        meta:
          - name: description
            content: "How to install my module."
          - rel: related
            href: "https://videotube.example/1234"
            title: "Watch a screen recording of module installation"

A list item like this can be used to add dividers:

      - divider: true

If the input is pod, you can also provide C<pod_filter>, C<pod_titlecase>,
and C<pod_downgrade_headings> settings which override the global settings.

If the input is markdown, you may use "----" (four hyphens) on a line by
itself to divide the page into cute sections.

=head2 Homepage

You'll need a file called F<< _pages/index.md >> for the site's homepage.
The filename may be configurable some day.

=head2 Custom CSS

You can create a file called F<< custom.scss >> containing custom SCSS
code to override or add to the defaults.

=head2 Adding Images

If you create a directory called F<images>, this will be copied to
F<docs/assets/images/> during the build process. This should be used
for things like background images, etc.

=head2 Building the Site

Running C<< make all >> will build the site.

Running C<< make clean >> will remove the C<docs> directory and
also any temporary SCSS files created during the build process.

=head1 EXAMPLE

Example: L<https://github.com/exportertiny/exportertiny.github.io>

Generated this site: L<https://exportertiny.github.io>

=head2 More Examples

=over

=item *

L<https://typetiny.toby.ink/>

=item *

L<https://story-interact.xlc.pl/>

=item *

L<https://ology.github.io/midi-drummer-tiny-tutorial/>

=item *

L<https://ology.github.io/music-duration-partition-tutorial/>

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-web-perldistsite/issues>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

our $VERSION = '0.001011';

use Web::PerlDistSite::MenuItem ();
use HTML::HTML5::Parser ();

has root => (
	is       => 'ro',
	isa      => PathTiny,
	required => true,
	coerce   => true,
);

has root_url => (
	is       => 'rwp',
	isa      => Str,
	default  => '/',
);

has dist_dir => (
	is       => 'lazy',
	isa      => PathTiny,
	coerce   => true,
	builder  => sub ( $s ) { $s->root->child( 'docs' ) },
);

has name => (
	is       => 'ro',
	isa      => Str,
	required => true,
);

has abstract => (
	is       => 'ro',
	isa      => Str,
	required => true,
);

has abstract_html => (
	is       => 'lazy',
	isa      => Str,
	default  => sub ( $s ) { esc_html( $s->abstract ) },
);

has issues => (
	is       => 'ro',
	isa      => Str,
);

has copyright => (
	is       => 'ro',
	isa      => Str,
);

has github => (
	is       => 'ro',
	isa      => Str,
);

has sponsor => (
	is       => 'ro',
	isa      => HashRef,
);

has theme => (
	is      => 'ro',
	isa     => HashRef->of( Str ),
);

has codestyle => (
	is       => 'ro',
	isa      => Str,
	default  => 'github',
);

has pod_filter => (
	is       => 'ro',
	isa      => Str,
	default  => 'NAME|BUGS|AUTHOR|THANKS|COPYRIGHT AND LICENCE|DISCLAIMER OF WARRANTIES',
);

has pod_titlecase => (
	is       => 'ro',
	isa      => Bool,
	default  => true,
);

has pod_downgrade_headings => (
	is       => 'ro',
	isa      => Bool,
	default  => true,
);

has menu => (
	is      => 'ro',
	isa      => ArrayRef->of(
		InstanceOf
			->of( 'Web::PerlDistSite::MenuItem' )
			->plus_constructors( HashRef, 'from_hashref' )
	),
	coerce   => true,
);

has homepage => (
	is       => 'ro',
	isa      => HashRef,
	default  => sub ( $s ) {
		return { animation => 'waves1' };
	},
);

sub css_timestamp ( $self ) {
	$self->dist_dir->child( 'assets/styles/main.css' )->stat->mtime;
}

sub load ( $class, $filename='config.yaml' ) {
	my $data = YAML::PP::LoadFile( $filename );
	$data->{root} //= path( $filename )->absolute->parent;
	$data->{menu} //= YAML::PP::LoadFile( $data->{root}->child( 'menu.yaml' ) );
	$class->new( $data->%* );
}

sub footer ( $self ) {
	my @sections;
	
	if ( $self->github ) {
		push @sections, sprintf(
			'<h2>Contributing</h2>
			<p>%s is an open source project <a href="%s">hosted on GitHub</a> —
			open an issue if you have an idea or find a bug.</p>',
			esc_html( $self->name ),
			esc_html( $self->github ),
		);
		if ( $self->github =~ m{^https://github.com/(.+)$} ) {
			my $path = $1;
			$sections[-1] .= sprintf(
				'<p><img alt="GitHub repo stars"
				src="https://img.shields.io/github/stars/%s?style=social"></p>',
				$path,
			);
		}
	}
	
	if ( $self->sponsor ) {
		push @sections, sprintf(
			'<h2>Sponsoring</h2>
			<p>%s</p>',
			esc_html( $self->sponsor->{html} ),
		);
		if ( $self->sponsor->{href} ) {
			$sections[-1] .= sprintf(
				'<p><a class="btn btn-light" href="%s"><span class="text-dark">Sponsor</span></a></p>',
				esc_html( $self->sponsor->{href} ),
			);
		}
	}
	
	my $width = int( 12 / @sections );
	my @html;
	push @html, '<div class="container">';
	push @html, '<div class="row">';
	for my $section ( @sections ) {
		push @html, "<div class=\"col-12 col-lg-$width\">$section</div>";
	}
	if ( $self->copyright ) {
		push @html, '<div class="col-12 text-center pt-3">';
		push @html, sprintf( '<p>%s</p>', esc_html( $self->copyright ) );
		push @html, '</div>';
	}
	push @html, '</div>';
	push @html, '</div>';
	return join qq{\n}, @html;
}

sub navbar ( $self, $active_item ) {
	my @html;
	push @html, '<nav class="navbar navbar-expand-lg">';
	push @html, '<div class="container">';
	push @html, sprintf( '<a class="navbar-brand" href="%s">%s</a>', $self->root_url, $self->name );
	push @html, '<button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">';
	push @html, '<span class="navbar-toggler-icon"></span>';
	push @html, '</button>';
	push @html, '<div class="collapse navbar-collapse" id="navbarSupportedContent">';
	push @html, '<ul class="navbar-nav ms-auto mb-2 mb-lg-0">';
	push @html, map $_->nav_item( $active_item ), $self->menu->@*;
	push @html, '</ul>';
	push @html, '</div>';
	push @html, '</div>';
	push @html, '</nav>';
	return join qq{\n}, @html;
}

sub BUILD ( $self, $args ) {
	$_->project( $self ) for $self->menu->@*;
	$self->root_url( $self->root_url . '/' ) unless $self->root_url =~ m{/$};
}

sub write_pages ( $self ) {
	for my $item ( $self->menu->@* ) {
		$item->write_pages;
	}
	$self->write_homepage;
}

sub write_variables_scss ( $self ) {
	my $scss = '';
	for my $key ( sort keys $self->theme->%* ) {
		$scss .= sprintf( '$%s: %s;', $key, $self->theme->{$key} ) . "\n";
	}
	$self->root->child( '_build/variables.scss' )->spew_if_changed( $scss );
}

sub write_homepage ( $self ) {
	require Web::PerlDistSite::MenuItem::Homepage;
	my $page = Web::PerlDistSite::MenuItem::Homepage->new(
		$self->homepage->%*,
		project => $self,
	);
	$page->write_pages;
}

sub get_template_page ( $self, $item=undef ) {
	state $template = do {
		local $/;
		my $html = <DATA>;
		$html =~ s[\{\{\s*\$root\s*\}\}]{$self->root_url}ge;
		$html =~ s[\{\{\s*\$codestyle\s*\}\}]{$self->codestyle}ge;
		$html =~ s[\{\{\s*\$css_timestamp\s*\}\}]{$self->css_timestamp}ge;
		$html;
	};
	
	state $p = HTML::HTML5::Parser->new;
	my $dom = $p->parse_string( $template );
	
	my $navbar = $p->parse_balanced_chunk( $self->navbar( $item ) );
	$dom->getElementsByTagName( 'header' )->shift->appendChild( $navbar );
	
	my $footer = $p->parse_balanced_chunk( $self->footer );
	$dom->getElementsByTagName( 'footer' )->shift->appendChild( $footer );
	
	$dom->getElementsByTagName( 'title' )->shift->appendText( $item ? $item->page_title : $self->name );
	
	if ( $item ) {
		my $head = $dom->getElementsByTagName( 'head' )->shift;
		if ( my $meta = $item->meta ) {
			for my $m ( @$meta ) {
				my $tagname = exists( $m->{href} ) ? 'link' : 'meta';
				%{ $head->addNewChild( $head->namespaceURI, $tagname ) } = %$m;
			}
		}
	}
	
	return $dom;
}

1;

__DATA__
<html prefix="rdfs: http://www.w3.org/2000/01/rdf-schema# dc: http://purl.org/dc/terms/ foaf: http://xmlns.com/foaf/0.1/ s: https://schema.org/ og: https://ogp.me/ns#">
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<title></title>
		<link href="{{ $root }}assets/styles/main.css?v={{ $css_timestamp }}" rel="stylesheet">
		<link rel="stylesheet" href="//unpkg.com/@highlightjs/cdn-assets@11.7.0/styles/{{ $codestyle }}.min.css">
	</head>
	<body id="top">
		<header></header>
		<main></main>
		<div id="footer-swish" style="height: 150px; overflow: hidden;"><svg viewBox="0 0 500 150" preserveAspectRatio="none" style="height: 100%; width: 100%;"><path d="M0.00,49.98 C138.82,121.67 349.20,-49.98 500.00,49.98 L500.00,150.00 L0.00,150.00 Z" style="stroke: none; fill: rgba(var(--bs-dark-rgb), 1);"></path></svg></div>
		<footer id="bottom"></footer>
		<a id="return-to-top" href="#top"><i class="fa-solid fa-circle-up"></i></a>
		<script src="{{ $root }}assets/scripts/bootstrap.bundle.min.js"></script>
		<script src="//kit.fontawesome.com/6d700b1a29.js" crossorigin="anonymous"></script>
		<script src="//unpkg.com/@highlightjs/cdn-assets@11.7.0/highlight.min.js"></script>
		<script>
		const classy_scroll = function () {
			const scroll = document.documentElement.scrollTop;
			const avail  = window.screen.availHeight;
			if ( scroll > 75 ) {
				document.body.classList.add( 'is-scrolled' );
				document.body.classList.remove( 'at-top' );
			}
			else if ( scroll < 25 ) {
				document.body.classList.remove( 'is-scrolled' );
				document.body.classList.add( 'at-top' );
			}
			if ( scroll > avail ) {
				document.body.classList.add( 'is-scrolled-deeply' );
			}
			else if ( scroll < avail ) {
				document.body.classList.remove( 'is-scrolled-deeply' );
			}
		};
		classy_scroll();
		window.addEventListener( 'scroll', classy_scroll );
		
		hljs.highlightAll();
		</script>
	</body>
</html>
