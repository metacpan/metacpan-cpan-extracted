package Web::PerlDistSite::MenuItem;
use utf8;

our $VERSION = '0.001010';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

use HTML::HTML5::Writer;
use HTML::HTML5::Sanity;
use XML::LibXML::PrettyPrint;

has project => (
	is       => 'rw',
	isa      => Object,
	weak_ref => true,
	trigger  => sub ( $self, $new_val, $old_val=undef ) {
		$_->project( $new_val ) for $self->children->@*;
	},
);

has name => (
	is       => 'ro',
	isa      => Str,
	required => true,
);

has title => (
	is       => 'ro',
	isa      => Str,
	required => true,
);

has href => (
	is       => 'lazy',
	isa      => Str,
	builder  => true,
);

has rel => (
	is       => 'ro',
	isa      => Str,
	default  => 'related',
);

has target => (
	is       => 'ro',
	isa      => Str,
	default  => '_self',
);

has icon => (
	is       => 'ro',
	isa      => Str,
);

has children => (
	is       => 'rw',
	isa      => ArrayRef->of(
		InstanceOf
			->of( 'Web::PerlDistSite::MenuItem' )
			->plus_constructors( HashRef, 'from_hashref' )
	),
	coerce   => true,
	default  => sub { [] },
);

sub from_hashref ( $class, $hashref ) {
	
	if ( exists $hashref->{divider} ) {
		$class .= '::Divider';
	}
	elsif ( exists $hashref->{pod} ) {
		$class .= '::Pod';
	}
	elsif ( exists $hashref->{source} and $hashref->{source} =~ /.pod/ ) {
		$class .= '::PodFile';
	}
	elsif ( exists $hashref->{source} and $hashref->{source} =~ /.md/ ) {
		$class .= '::MarkdownFile';
	}
	elsif ( exists $hashref->{source} and $hashref->{source} =~ /.html/ ) {
		$class .= '::HTMLFile';
	}
	
	return Module::Runtime::use_module( $class )->new( $hashref );
}

sub system_path ( $self ) {
	path( $self->project->dist_dir )->child( $self->name . '.html' )
}

sub write_page ( $self ) {
	return $self;
}

sub write_pages ( $self ) {
	$self->write_page;
	$_->write_pages for $self->children->@*;
}

sub _build_href ( $self ) {
	if ( $self->name ) {
		if ( $self->name eq 'github' ) {
			return $self->project->github;
		}
		if ( $self->name eq 'metacpan' ) {
			return 'https://metacpan.org/dist/' . $self->project->name;
		}
		if ( $self->name eq 'issues' ) {
			return $self->project->issues // ( $self->project->github . '/issues' );
		}
	}
	return $self->project->root_url . $self->name . '.html';
}

sub _make_safe_class ( $self, $classname ) {
	( $classname = lc( $classname ) )
		=~ s{\W+}{-}g;
	return $classname;
}

sub _compile_dom ( $self, $dom ) {
	my $body = $dom->getElementsByTagName( 'body' )->shift;
	$body->setAttribute(
		'class',
		join(
			' ',
			grep { defined($_) && length($_) }
				$body->getAttribute( 'class' ),
				$self->_make_safe_class( 'pagetype-' . ref($self) ),
				$self->_make_safe_class( 'page-' . $self->name ),
		),
	);
	
	state $p = do {
		my $pp = XML::LibXML::PrettyPrint->new;
		push $pp->{element}{preserves_whitespace}->@*, sub ( $node ) {
			return undef unless $node->can( 'tagName' );
			return 1 if $node->tagName eq 'code' and $node->parentNode->tagName eq 'pre';
			return undef;
		};
		unshift $pp->{element}{inline}->@*, sub ( $node ) {
			return undef unless $node->can( 'tagName' );
			return 1 if $node->tagName eq 'pre' and $node->getElementsByTagName( 'code' )->size;
			return undef;
		};
		unshift $pp->{element}{compact}->@*, 'a';
		$pp;
	};
	state $w = HTML::HTML5::Writer->new( markup => 'xhtml', polyglot => true );
	my $sane = fix_document( $dom );
	$p->pretty_print( $sane );
	return $w->document( $sane );
}

sub nav_item ( $self, $active_item ) {
	my $icon = $self->icon // '';
	if ( length $icon ) {
		$icon .= ' ';
	}
	
	if ( $self->children->@* ) {
		my @items = map $_->dropdown_item( $active_item ), $self->children->@*;
		return sprintf(
			'<li class="nav-item dropdown"><a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false">%s%s</a><ul class="dropdown-menu">%s</ul></li>',
			$icon,
			esc_html( $self->title ),
			join( q{}, @items ),
		);
	}
	elsif ( $self == $active_item ) {
		return sprintf(
			'<li class="nav-item"><a class="nav-link active" rel="%s" target="%s" href="%s">%s%s</a></li>',
			esc_html( $self->rel ),
			esc_html( $self->target ),
			esc_html( $self->href ),
			$icon,
			esc_html( $self->title ),
		);
	}
	else {
		return sprintf(
			'<li class="nav-item"><a class="nav-link" rel="%s" target="%s" href="%s">%s%s</a></li>',
			esc_html( $self->rel ),
			esc_html( $self->target ),
			esc_html( $self->href ),
			$icon,
			esc_html( $self->title ),
		);
	}
}

sub dropdown_item ( $self, $active_item ) {
	my $icon = $self->icon // '';
	if ( length $icon ) {
		$icon .= ' ';
	}
	
	if ( $self == $active_item ) {
		return sprintf(
			'<li><a class="dropdown-item active" rel="%s" target="%s" href="%s">%s%s</a></li>',
			esc_html( $self->rel ),
			esc_html( $self->target ),
			esc_html( $self->href ),
			$icon,
			esc_html( $self->title ),
		);
	}
	else {
		return sprintf(
			'<li><a class="dropdown-item" rel="%s" target="%s" href="%s">%s%s</a></li>',
			esc_html( $self->rel ),
			esc_html( $self->target ),
			esc_html( $self->href ),
			$icon,
			esc_html( $self->title ),
		);
	}
}

sub page_title ( $self ) {
	return sprintf( '%s — %s', $self->project->name, $self->title );
}

1;
