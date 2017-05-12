use 5.008001;
use strict;
use warnings;

use Scalar::Util ();
use Encode ();

package XML::Builder;
$XML::Builder::VERSION = '0.906';
# ABSTRACT: programmatic XML generation, conveniently

use Object::Tiny::Lvalue qw( nsmap default_ns encoding );

# these aren't constants, they need to be overridable in subclasses
my %class = (
	ns       => 'XML::Builder::NS',
	fragment => 'XML::Builder::Fragment',
	qname    => 'XML::Builder::Fragment::QName',
	tag      => 'XML::Builder::Fragment::Tag',
	unsafe   => 'XML::Builder::Fragment::Unsafe',
	root     => 'XML::Builder::Fragment::Root',
	document => 'XML::Builder::Fragment::Document',
);

my ( $name, $class );
eval XML::Builder::Util::factory_method( $name, $class )
	while ( $name, $class ) = each %class;

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	$self->encoding ||= 'us-ascii';
	$self->nsmap ||= {};
	return $self;
}

sub register_ns {
	my $self = shift;
	my ( $uri, $pfx ) = @_;

	my $nsmap = $self->nsmap;

	$uri = $self->stringify( $uri );

	if ( exists $nsmap->{ $uri } ) {
		my $ns = $nsmap->{ $uri };
		my $registered_pfx = $ns->prefix;

		XML::Builder::Util::croak( "Namespace '$uri' being bound to '$pfx' is already bound to '$registered_pfx'" )
			if defined $pfx and $pfx ne $registered_pfx;

		return $ns;
	}

	if ( not defined $pfx ) {
		my %pfxmap = map {; $_->prefix => $_ } values %$nsmap;

		if ( $uri eq '' and not exists $pfxmap{ '' } ) {
			return $self->register_ns( '', '' );
		}

		my $counter;
		my $letter = ( $uri =~ m!([[:alpha:]])[^/]*/?\z! ) ? lc $1 : 'ns';
		do { $pfx = $letter . ++$counter } while exists $pfxmap{ $pfx };
	}

	# FIXME needs proper validity check per XML TR
	XML::Builder::Util::croak( "Invalid namespace prefix '$pfx'" )
		if length $pfx and $pfx !~ /[\w-]/;

	my $ns = $self->new_ns(
		uri     => $uri,
		prefix  => $pfx,
	);

	$self->default_ns = $uri if '' eq $pfx;
	return $nsmap->{ $uri } = $ns;
}

sub get_namespaces {
	my $self = shift;
	return values %{ $self->nsmap };
}

sub ns { shift->register_ns( @_ )->factory }
sub null_ns { shift->ns( '', '' ) }

sub qname {
	my $self   = shift;
	my $ns_uri = shift;
	return $self->register_ns( $ns_uri )->qname( @_ );
}

sub parse_qname {
	my $self = shift;
	my ( $name ) = @_;

	my $ns_uri = '';
	$ns_uri = $1 if $name =~ s/\A\{([^}]+)\}//;

	return $self->qname( $ns_uri, $name );
}

sub root {
	my $self = shift;
	my ( $tag ) = @_;
	return $tag->root;
}

sub document {
	my $self = shift;
	return $self->new_document( content => [ @_ ] );
}

sub unsafe {
	my $self = shift;
	my ( $string ) = @_;
	return $self->new_unsafe( content => $string );
}

sub comment {
	my $self = shift;
	my ( $comment ) = $self->stringify( @_ );
	XML::Builder::Util::croak( "Comment contains double dashes '$1...'" )
		if $comment =~ /(.*?--)/;
	return $self->new_unsafe( "<!--$comment-->" );
}

sub pi {
	my $self = shift;
	my ( $name, $content ) = map $self->stringify( $_ ), @_;
	XML::Builder::Util::croak( "PI contains terminator '$1...'" )
		if $content =~ /(.*\?>)/;
	return $self->new_unsafe( "<?$name $content?>" );
}

sub render {
	my $self = shift;
	return 'SCALAR' eq ref $_[0]
		? $self->qname( ${$_[0]}, @_[ 1 .. $#_ ] )
		: $self->new_fragment( content => [ @_ ] );
}

sub test_fragment {
	my $self = shift;
	my ( $obj ) = @_;
	return $obj->isa( 'XML::Builder::Fragment::Role' );
}

{
	no warnings 'qw';

	my %XML_NCR = map eval "qq[$_]", qw(
		\xA &#10;  \xD &#13;
		&   &amp;  <   &lt;   > &gt;
		"   &#34;  '   &#39;
	);

	my %type = (
		encode      => undef,
		escape_text => qr/([<>&'"])/,
		escape_attr => qr/([<>&'"\x0A\x0D])/,
	);

	# using eval instead of closures to avoid __ANON__
	while ( my ( $subname, $specials_rx ) = each %type ) {
		my $esc = '';

		$esc = sprintf '$str =~ s{ %s }{ $XML_NCR{$1} }gex', $specials_rx
			if defined $specials_rx;

		eval sprintf 'sub %s {
			my $self = shift;
			my $str = $self->stringify( shift );
			%s;
			return Encode::encode $self->encoding, $str, Encode::HTMLCREF;
		}', $subname, $esc;
	}
}

sub stringify {
	my $self = shift;
	my ( $thing ) = @_;

	return if not defined $thing;

	return $thing if not Scalar::Util::blessed $thing;

	my $conv = $thing->can( 'as_string' ) || overload::Method( $thing, '""' );
	return $conv->( $thing ) if $conv;

	XML::Builder::Util::croak( 'Unstringifiable object ', $thing );
}

#######################################################################

package XML::Builder::NS;
$XML::Builder::NS::VERSION = '0.906';
use Object::Tiny::Lvalue qw( builder uri prefix qname_for_localname );
use overload '""' => 'uri', fallback => 1;

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	$self->qname_for_localname ||= {};
	Scalar::Util::weaken $self->builder;
	return $self;
}

sub qname {
	my $self = shift;
	my $name = shift;

	my $builder = $self->builder
		|| XML::Builder::Util::croak( 'XML::Builder for this NS object has gone out of scope' );

	my $qname
		= $self->qname_for_localname->{ $name }
		||= $builder->new_qname( name => $name, ns => $self );

	return @_ ? $qname->tag( @_ ) : $qname;
}

sub xmlns {
	my $self = shift;
	my $pfx = $self->prefix;
	return ( ( '' ne $pfx ? "xmlns:$pfx" : 'xmlns' ), $self->uri );
}

sub factory { bless \shift, 'XML::Builder::NS::QNameFactory' }

#######################################################################

package XML::Builder::NS::QNameFactory;
$XML::Builder::NS::QNameFactory::VERSION = '0.906';
sub AUTOLOAD { my $self = shift; $$self->qname( ( our $AUTOLOAD =~ /.*::(.*)/ ), @_ ) }
sub _qname   { my $self = shift; $$self->qname(                                  @_ ) }
sub DESTROY  {}

#######################################################################

package XML::Builder::Fragment::Role;
$XML::Builder::Fragment::Role::VERSION = '0.906';
sub depends_ns_scope { 1 }

#######################################################################

package XML::Builder::Fragment;
$XML::Builder::Fragment::VERSION = '0.906';
use parent -norequire => 'XML::Builder::Fragment::Role';

use Object::Tiny::Lvalue qw( builder content );

sub depends_ns_scope { 0 }

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	my $builder = $self->builder;
	my $content = $self->content;

	my ( @gather, @take );

	for my $r ( 'ARRAY' eq ref $content ? @$content : $content ) {
		@take = $r;

		if ( not Scalar::Util::blessed $r ) {
			@take = $builder->render( @$r ) if 'ARRAY' eq ref $r;
			next;
		}

		if ( not $builder->test_fragment( $r ) ) {
			@take = $builder->stringify( $r );
			next;
		}

		next if $builder == $r->builder;

		XML::Builder::Util::croak( 'Cannot merge XML::Builder fragments built with different namespace maps' )
			if $r->depends_ns_scope;

		@take = $r->flatten;

		my ( $self_enc, $r_enc ) = map { lc $_->encoding } $builder, $r->builder;
		next
			if $self_enc eq $r_enc
			# be more permissive: ASCII is one-way compatible with UTF-8 and Latin-1
			or 'us-ascii' eq $r_enc and grep { $_ eq $self_enc } 'utf-8', 'iso-8859-1';

		XML::Builder::Util::croak(
			'Cannot merge XML::Builder fragments with incompatible encodings'
			. " (have $self_enc, fragment has $r_enc)"
		);
	}
	continue {
		push @gather, @take;
	}

	$self->content = \@gather;

	return $self;
}

sub as_string {
	my $self = shift;
	my $builder = $self->builder;
	return join '', map { ref $_ ? $_->as_string : $builder->escape_text( $_ ) } @{ $self->content };
}

sub flatten {
	my $self = shift;
	return @{ $self->content };
}

#######################################################################

package XML::Builder::Fragment::Unsafe;
$XML::Builder::Fragment::Unsafe::VERSION = '0.906';
use parent -norequire => 'XML::Builder::Fragment';

sub depends_ns_scope { 0 }

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	$self->content = $self->builder->stringify( $self->content );
	return $self;
}

sub as_string {
	my $self = shift;
	return $self->builder->encode( $self->content );
}

sub flatten { shift }

#######################################################################

package XML::Builder::Fragment::QName;
$XML::Builder::Fragment::QName::VERSION = '0.906';
use Object::Tiny::Lvalue qw( builder ns name as_qname as_attr_qname as_clarkname as_string );

use parent -norequire => 'XML::Builder::Fragment';
use overload '""' => 'as_clarkname', fallback => 1;

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;

	my $uri = $self->ns->uri;
	my $pfx = $self->ns->prefix;
	Scalar::Util::weaken $self->ns; # really don't even need this any more
	Scalar::Util::weaken $self->builder;

	# NB.: attributes without a prefix not in a namespace rather than in the
	# default namespace, so attributes without a namespace never need a prefix

	my $name = $self->name;
	$self->as_qname      = ( '' eq $pfx               ) ? $name : "$pfx:$name";
	$self->as_attr_qname = ( '' eq $pfx or '' eq $uri ) ? $name : "$pfx:$name";
	$self->as_clarkname  = (               '' eq $uri ) ? $name : "{$uri}$name";
	$self->as_string     = '<' . $self->as_qname . '/>';

	return $self;
}

sub tag {
	my $self = shift;

	if ( 'SCALAR' eq ref $_[0] and 'foreach' eq ${$_[0]} ) {
		shift @_; # throw away
		return $self->foreach( @_ );
	}

	# has to be written this way so it'll drop undef attributes
	my $attr = {};
	XML::Builder::Util::merge_param_hash( $attr, \@_ );

	my $builder = $self->builder
		|| XML::Builder::Util::croak( 'XML::Builder for this QName object has gone out of scope' );

	return $builder->new_tag(
		qname   => $self,
		attr    => $attr,
		content => [ map $builder->render( $_ ), @_ ],
	);
}

sub foreach {
	my $self = shift;

	my $attr = {};
	my @out  = ();

	my $builder = $self->builder
		|| XML::Builder::Util::croak( 'XML::Builder for this QName object has gone out of scope' );

	do {
		XML::Builder::Util::merge_param_hash( $attr, \@_ );
		my $content = 'HASH' eq ref $_[0] ? undef : shift;
		push @out, $builder->new_tag(
			qname   => $self,
			attr    => {%$attr},
			content => $builder->render( $content ),
		);
	} while @_;

	return $builder->new_fragment( content => \@out )
		if @out > 1 and not wantarray;

	return @out[ 0 .. $#out ];
}

#######################################################################

package XML::Builder::Fragment::Tag;
$XML::Builder::Fragment::Tag::VERSION = '0.906';
use parent -norequire => 'XML::Builder::Fragment';
use Object::Tiny::Lvalue qw( qname attr );

sub depends_ns_scope { 1 }

sub as_string {
	my $self = shift;

	my $builder = $self->builder;
	my $qname   = $self->qname->as_qname;
	my $attr    = $self->attr || {};

	my $tag = join ' ', $qname,
		map { sprintf '%s="%s"', $builder->parse_qname( $_ )->as_attr_qname, $builder->escape_attr( $attr->{ $_ } ) }
		sort keys %$attr;

	my $content = @{ $self->content } ? $self->SUPER::as_string : undef;
	return defined $content
		? "<$tag>$content</$qname>"
		: "<$tag/>";
}

sub append {
	my $self = shift;
	return $self->builder->new_fragment( content => [ $self, $self->builder->render( @_ ) ] );
}

sub root {
	my $self = shift;
	bless $self, $self->builder->root_class;
}

sub flatten { shift }

#######################################################################

package XML::Builder::Fragment::Root;
$XML::Builder::Fragment::Root::VERSION = '0.906';
use parent -norequire => 'XML::Builder::Fragment::Tag';
use overload '""' => 'as_string', fallback => 1;

sub depends_ns_scope { 0 }

sub as_string {
	my $self = shift;

	my %decl = map $_->xmlns, $self->builder->get_namespaces;

	# make sure to always declare the default NS (if not bound to a URI, by
	# explicitly undefining it) to allow embedding the XML easily without
	# having to parse the fragment
	$decl{'xmlns'} = '' if not defined $decl{'xmlns'};

	local @{ $self->attr }{ keys %decl } = values %decl;

	return $self->SUPER::as_string( @_ );
}

#######################################################################

package XML::Builder::Fragment::Document;
$XML::Builder::Fragment::Document::VERSION = '0.906';
use parent -norequire => 'XML::Builder::Fragment';
use overload '""' => 'as_string', fallback => 1;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );
	$self->validate;
	return $self;
}

sub validate {
	my $self = shift;
	my @root;

	for ( @{ $self->content } ) {
		if ( Scalar::Util::blessed $_ ) {
			if ( $_->isa( $self->builder->tag_class ) ) { push @root, $_; next }
			if ( $_->isa( $self->builder->unsafe_class ) ) { next }
		}
		XML::Builder::Util::croak( 'Junk at top level of document' );
	}

	XML::Builder::Util::croak( 'Document must have exactly one document element, not ' . @root )
		if @root != 1;

	$root[0]->root;

	return;
}

sub as_string {
	my $self = shift;
	my $preamble = qq(<?xml version="1.0" encoding="${\$self->builder->encoding}"?>\n);
	return $preamble . $self->SUPER::as_string( @_ );
}

#######################################################################

BEGIN {
package XML::Builder::Util;
$XML::Builder::Util::VERSION = '0.906';
use Carp::Clan '^XML::Builder(?:\z|::)';

sub merge_param_hash {
	my ( $cur, $param ) = @_;

	return if not ( @$param and 'HASH' eq ref $param->[0] );

	my $new = shift @$param;

	@{ $cur }{ keys %$new } = values %$new;
	while ( my ( $k, $v ) = each %$cur ) {
		delete $cur->{ $k } if not defined $v;
	}
}

sub factory_method {
	my ( $name, $class ) = @_;
	my ( $class_method, $new_method ) = ( "$name\_class", "new_$name" );
	return <<";";
sub $class_method { "\Q$class\E" }
sub $new_method { \$_[0]->$class_method->new( builder => \@_ ) }
;
}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Builder - programmatic XML generation, conveniently

=head1 VERSION

version 0.906

=head1 DESCRIPTION

For now, please refer to the test suite that ships with this module.

Documentation will be added when the design settles.
Please be unreasonably patient.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
