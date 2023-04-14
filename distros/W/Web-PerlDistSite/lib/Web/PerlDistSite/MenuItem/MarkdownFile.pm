package Web::PerlDistSite::MenuItem::MarkdownFile;

our $VERSION = '0.001010';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

use Text::Markdown ();

extends 'Web::PerlDistSite::MenuItem::File';

sub body_class {
	return 'page from-markdown';
}

sub extra_top ( $self ) {
	HTML::HTML5::Parser->new->parse_balanced_chunk(
		sprintf(
			'<div class="heading-wrapper"><div class="heading"><h1>%s</h1></div></div>',
			esc_html( $self->title ),
		)
	);
}

sub extra_bottom { return; }

sub compile_page ( $self ) {
	state $m = Text::Markdown->new( empty_element_suffix => '>' );
	state $p = HTML::HTML5::Parser->new;
	my $dom = $self->project->get_template_page( $self );
	
	$dom->getElementsByTagName( 'body' )->shift->setAttribute( class => $self->body_class );
	
	my $raw = $self->raw_content;
	my @raw = split /\n-{4}\n/, $raw;
	
	$dom->getElementsByTagName( 'main' )->shift->appendChild( $_ )
		for $self->extra_top;
	
	if ( @raw == 1 ) {
		my $html = $m->markdown( $raw );
		my $content = $p->parse_balanced_chunk( $html );
		my $article = $dom->createElement( 'article' );
		$article->setAttribute( class => 'container' );
		$article->appendChild( $content );
		$dom->getElementsByTagName( 'main' )->shift->appendChild( $article );
	}
	else {
		my $count = 0;
		my $article = $dom->createElement( 'article' );
		$article->setAttribute( class => 'has-sections has-section-count-' . scalar @raw );
		for my $raw ( @raw ) {
			my $html = $m->markdown( $raw );
			my $content = $p->parse_balanced_chunk( $html );
			my $section = $dom->createElement( 'section' );
			my $div = $dom->createElement( 'div' );
			$div->setAttribute( class => 'container' );
			$div->appendChild( $content );
			$section->appendChild( $div );
			$article->appendChild( $section );
		}
		$dom->getElementsByTagName( 'main' )->shift->appendChild( $article );
	}
	
	$dom->getElementsByTagName( 'main' )->shift->appendChild( $_ )
		for $self->extra_bottom;
	
	
	return $self->_compile_dom( $dom );
}

1;
