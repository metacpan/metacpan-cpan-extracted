package Web::PerlDistSite::MenuItem::_PodCommon;

our $VERSION = '0.001011';

use Moo::Role;
use Web::PerlDistSite::Common -lexical, -all;

use Lingua::EN::Titlecase;
use Pod::POM;
use TOBYINK::Pod::HTML;

has _link_map => (
	is       => 'lazy',
	isa      => Map[ Str, Str ],
	builder  => true,
);

has pod_filter => (
	is       => 'lazy',
	isa      => Str,
	builder  => sub ( $s ) { $s->project->pod_filter },
);

has pod_titlecase => (
	is       => 'lazy',
	isa      => Bool,
	builder  => sub ( $s ) { $s->project->pod_titlecase },
);

has pod_downgrade_headings => (
	is       => 'lazy',
	isa      => Bool,
	builder  => sub ( $s ) { $s->project->pod_downgrade_headings },
);

sub filtered_pod ( $self ) {
	state $parser = Pod::POM->new();
	my $orig = $self->raw_content;
	utf8::encode( $orig ); # Pod::POM isn't unicode-aware.
	my $pom = $parser->parse_text( $orig );
	my $pod = '';
	my %filter = map { lc($_) => 1 } split /\|/, $self->pod_filter;
	foreach my $section ( $pom->head1->@* ) {
		next if $filter{ lc $section->title };
		$pod .= sprintf(
			"=head1 %s\n\n",
			( $self->pod_titlecase and $section->title !~ /[a-z]/ )
				? Lingua::EN::Titlecase->new( $section->title )->title
				: $section->title,
		);
		$pod .= $section->content . "\n\n";
	}
	utf8::decode( $pod );
	return $pod;
}

sub compile_page ( $self ) {
	my $dom = $self->project->get_template_page( $self );
	$dom->getElementsByTagName( 'body' )->shift->setAttribute( class => $self->body_class );
	my $content = $self->_pod2html( $self->filtered_pod );
	my $article = $dom->createElement( 'article' );
	$article->setAttribute( class => 'container' );
	$article->appendChild( $_ ) for $content->get_nodelist;
	$dom->getElementsByTagName( 'main' )->shift->appendWellBalancedChunk(
		sprintf(
			'<div class="heading container py-3"><h1 class="display-2">%s</h1></div>',
			esc_html( $self->title ),
		)
	);
	$dom->getElementsByTagName( 'main' )->shift->appendChild( $article );
	return $self->_compile_dom( $dom );
}

sub _pod2html ( $self, $pod ) {
	state $pod2html = TOBYINK::Pod::HTML->new(
		pretty            => true,
		code_highlighting => false,
	);
	my $dom = $pod2html->string_to_dom( $pod );
	for my $node ( $dom->getElementsByTagName('pre') ) {
		my $new_node = $dom->createElement( 'pre' );
		my $child = $new_node->addChild( $dom->createElement( 'code' ) );
		$child->appendText( $node->textContent );
		$node->replaceNode( $new_node );
	}
	for my $node ( $dom->getElementsByTagName('a') ) {
		$self->_fix_pod_link( $node );
	}
	# Demote heading levels
	if ( $self->pod_downgrade_headings ) {
		for my $i ( 5, 4, 3, 2, 1 ) {
			my $j = $i + 1;
			for my $node ( $dom->getElementsByTagName( "h$i" ) ) {
				$node->setNodeName( "h$j" );
			}
		}
	}
	my @nodes = $dom->getElementsByTagName('body')->map( sub { shift->childNodes } );
	return XML::LibXML::NodeList->new( @nodes );
}

sub _build__link_map ( $self ) {
	my %map;
	my @items = $self->project->menu->@*;
	while ( @items ) {
		my $item = shift @items;
		if ( $item->isa( 'Web::PerlDistSite::MenuItem::Pod' ) ) {
			$map{ $item->pod } = $item->href;
		}
		push @items, @{ $item->children // [] };
	}
	return \%map;
}

sub _fix_pod_link ( $self, $element ) {
	my $map = $self->_link_map;
	my $href = $element->getAttribute( 'href' ) or return;
	
	if ( $href =~ m{^https://metacpan.org/pod/(perl[a-z0-9]*)(#.+)?$} ) {
		my $page = $1;
		my $anchor = $2 // '';
		$element->setAttribute( 'href', 'https://perldoc.perl.org/' . $page . $anchor );
	}
	elsif ( $href =~ m{^https://metacpan.org/pod/(.+)(#.+)?$} ) {
		require URI::Escape;
		my $page = $1;
		my $anchor = $2 // '';
		$page = URI::Escape::uri_unescape( $page );
		if ( defined $map->{$page} ) {
			$element->setAttribute( 'href', $map->{$page} . $anchor );
		}
	}
	return;
}

1;
