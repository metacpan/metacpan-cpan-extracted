use 5.008001; # no good Unicode support? you lose
use strict;
use warnings;

package XML::Atom::SimpleFeed;
$XML::Atom::SimpleFeed::VERSION = '0.902';
# ABSTRACT: No-fuss generation of Atom syndication feeds

use Carp;
use Encode ();
use POSIX ();

my @XML_ENC = 'us-ascii'; # use array because local($myvar) error but local($myvar[0]) OK
                          # and use a lexical because not a public interface

sub ATOM_NS           () { 'http://www.w3.org/2005/Atom' }
sub XHTML_NS          () { 'http://www.w3.org/1999/xhtml' }
sub PREAMBLE          () { qq(<?xml version="1.0" encoding="$XML_ENC[0]"?>\n) }
sub W3C_DATETIME      () { '%Y-%m-%dT%H:%M:%S' }
sub DEFAULT_GENERATOR () { {
	uri     => 'https://metacpan.org/pod/' . __PACKAGE__,
	version => __PACKAGE__->VERSION || 'git',
	name    => __PACKAGE__,
} }

####################################################################
# superminimal XML writer
# 

sub xml_encoding { local $XML_ENC[0] = shift; &{(shift)} }

my %XML_ESC = (
	"\xA" => '&#10;',
	"\xD" => '&#13;',
	'"'   => '&#34;',
	'&'   => '&#38;',
	"'"   => '&#39;',
	'<'   => '&lt;',
	'>'   => '&gt;',
);

sub xml_cref { Encode::encode $XML_ENC[0], $_[0], Encode::HTMLCREF }

sub xml_escape {
	$_[0] =~ s{ ( [<>&'"] ) }{ $XML_ESC{ $1 } }gex;
	&xml_cref;
}

sub xml_attr_escape {
	$_[0] =~ s{ ( [\x0A\x0D<>&'"] ) }{ $XML_ESC{ $1 } }gex;
	&xml_cref;
}

sub xml_cdata_flatten {
	for ( $_[0] ) {
		my $cdata_content;
		s{<!\[CDATA\[(.*?)]]>}{ xml_escape $cdata_content = $1 }gse;
		croak 'Incomplete CDATA section' if -1 < index $_, '<![CDATA[';
		return $_;
	}
}

sub xml_string { xml_cref xml_cdata_flatten $_[ 0 ] }

sub xml_tag {
	my $name = shift;
	my $attr = '';
	if( ref $name eq 'ARRAY' ) {
		my $i = 1;
		while( $i < @$name ) {
			$attr .= ' ' . $name->[ $i ] . '="' . xml_attr_escape( $name->[ $i + 1 ] ) . '"';
			$i += 2;
		}
		$name = $name->[ 0 ];
	}
	@_ ? join( '', "<$name$attr>", @_, "</$name>" ) : "<$name$attr/>";
}

####################################################################
# misc utility functions
#

sub natural_enum {
	my @and;
	unshift @and, pop @_ if @_;
	unshift @and, join ', ', @_ if @_;
	join ' and ', @and;
}

sub permalink {
	my ( $link_arg ) = ( @_ );
	if( ref $link_arg ne 'HASH' ) {
		return $link_arg;
	}
	elsif( not exists $link_arg->{ rel } or $link_arg->{ rel } eq 'alternate' ) {
		return $link_arg->{ href };
	}
	return;
}

####################################################################
# actual implementation of RFC 4287
#

sub simple_construct {
	my ( $name, $content ) = @_;
	xml_tag $name, xml_escape $content;
}

sub date_construct {
	my ( $name, $dt ) = @_;
	eval { $dt = $dt->epoch }; # convert to epoch to avoid dealing with everyone's TZ crap
	$dt = POSIX::strftime( W3C_DATETIME . 'Z', gmtime $dt ) unless $dt =~ /[^0-9]/;
	xml_tag $name, xml_escape $dt;
}

sub person_construct {
	my ( $name, $arg ) = @_;

	my $prop = 'HASH' ne ref $arg ? { name => $arg } : $arg;

	croak "name required for $name element" if not exists $prop->{ name };

	return xml_tag $name => (
		map { xml_tag $_ => xml_escape $prop->{ $_ } }
		grep { exists $prop->{ $_ } }
		qw( name email uri )
	);
}

sub text_construct {
	my ( $name, $arg ) = @_;

	my ( $type, $content );

	if( ref $arg eq 'HASH' ) {
		# FIXME doesn't support @src attribute for $name eq 'content' yet

		$type = exists $arg->{ type } ? $arg->{ type } : 'html';

		croak "content required for $name element" unless exists $arg->{ content };

		# a lof of the effort that follows is to omit the type attribute whenever possible
		# 
		if( $type eq 'xhtml' ) {
			$content = xml_string $arg->{ content };

			if( $content !~ /</ ) { # FIXME does this cover all cases correctly?
				$type = 'text';
				$content =~ s/[\n\t]+/ /g;
			}
			else {
				$content = xml_tag [ div => xmlns => XHTML_NS ], $content;
			}
		}
		elsif( $type eq 'html' or $type eq 'text' ) {
			$content = xml_escape $arg->{ content };
		}
		else {
			croak "type '$type' not allowed in $name element"
				if $name ne 'content';

			# FIXME non-XML/text media types must be base64 encoded!
			$content = xml_string $arg->{ content };
		}
	}
	else {
		$type = 'html';
		$content = xml_escape $arg;
	}

	if( $type eq 'html' and $content !~ /&/ ) {
		$type = 'text';
		$content =~ s/[\n\t]+/ /g;
	}

	return xml_tag [ $name => $type ne 'text' ? ( type => $type ) : () ], $content;
}

sub link_element {
	my ( $name, $arg ) = @_;

	# omit atom:link/@rel value when possible
	delete $arg->{'rel'}
		if 'HASH' eq ref $arg
		and exists $arg->{'rel'}
		and 'alternate' eq $arg->{'rel'};

	my @attr = 'HASH' eq ref $arg
		? do {
			croak "href required for link element" if not exists $arg->{'href'};
			map { $_ => $arg->{ $_ } } grep exists $arg->{ $_ }, qw( href rel type title hreflang length );
		}
		: ( href => $arg );

	# croak "link '$attr[1]' is not a valid URI"
	# 	if $attr[1] XXX TODO

	xml_tag [ link => @attr ];
}

sub category_element {
	my ( $name, $arg ) = @_;

	my @attr = 'HASH' eq ref $arg
		? do {
			croak "term required for category element" if not exists $arg->{'term'};
			map { $_ => $arg->{ $_ } } grep exists $arg->{ $_ }, qw( term scheme label );
		}
		: ( term => $arg );

	xml_tag [ category => @attr ];
}

sub generator_element {
	my ( $name, $arg ) = @_;
	if( ref $arg eq 'HASH' ) {
		croak 'name required for generator element' if not exists $arg->{ name };
		my $content = delete $arg->{ name };
		xml_tag [ generator => map +( $_ => $arg->{ $_ } ), grep exists $arg->{ $_ }, qw( uri version ) ], xml_escape( $content );
	}
	elsif( defined $arg ) {
		xml_tag generator => xml_escape( $arg );
	}
	else { '' }
}

# tag makers are called with the name of the tag they're supposed to handle as the first parameter
my %make_tag = (
	icon        => \&simple_construct,
	id          => \&simple_construct,
	logo        => \&simple_construct,
	published   => \&date_construct,
	updated     => \&date_construct,
	author      => \&person_construct,
	contributor => \&person_construct,
	title       => \&text_construct,
	subtitle    => \&text_construct,
	rights      => \&text_construct,
	summary     => \&text_construct,
	content     => \&text_construct,
	link        => \&link_element,
	category    => \&category_element,
	generator   => \&generator_element,
);

sub container_content {
	my ( $name, %arg ) = @_;

	my ( $elements, $required, $optional, $singular, $deprecation, $callback ) =
		@arg{ qw( elements required optional singular deprecate callback ) };

	my ( $content, %permission, %count, $permalink );

	undef @permission{ @$required, @$optional }; # populate

	while( my ( $elem, $arg ) = splice @$elements, 0, 2 ) {
		if( exists $permission{ $elem } ) {
			$content .= $make_tag{ $elem }->( $elem, $arg );
			++$count{ $elem };
		}
		else {
			croak "Unknown element $elem";
		}

		if( $elem eq 'link' and defined ( my $alt = permalink $arg ) ) {
			$permalink = $alt unless $count{ 'alternate link' }++;
		}

		if( exists $callback->{ $elem } ) { $callback->{ $elem }->( $arg ) }

		if( not @$elements ) { # end of input?
			# we would normally fall off the bottom of the loop now;
			# before that happens, it's time to defaultify stuff and
			# put it in the input so we will keep going for a little longer
			if( not $count{ id } and defined $permalink ) {
				carp 'Falling back to alternate link as id';
				push @$elements, id => $permalink;
			}
			if( not $count{ updated } ) {
				push @$elements, updated => $arg{ default_upd };
			}
		}
	}

	my @error;

	my @missing = grep { not exists $count{ $_ } } @$required;
	my @toomany = grep { ( $count{ $_ } || 0 ) > 1 } 'alternate link', @$singular;

	push @error, 'requires at least one ' . natural_enum( @missing ) . ' element' if @missing;
	push @error, 'must have no more than one ' . natural_enum( @toomany ) . ' element' if @toomany;

	croak $name, ' ', join ' and ', @error if @error;

	return $content;
}

####################################################################
# implementation of published interface and rest of RFC 4287
#

sub XML::Atom::SimpleFeed::new {
	my $self = bless { xml_encoding => $XML_ENC[0] }, shift;

	if ( my @i = grep { '-encoding' eq $_[$_] } grep { not $_ % 2 } 0 .. $#_ ) {
		croak 'multiple encodings requested' if @i > 1;
		( undef, my $encoding ) = splice @_, $i[0], 2;
		$self->{ xml_encoding } = $encoding;
	}

	@_ ? $self->feed( @_ ) : $self;
}

sub XML::Atom::SimpleFeed::feed {
	my $self = shift;

	my $have_generator;

	local $XML_ENC[0] = $self->{ xml_encoding };
	$self->{ meta } = container_content feed => (
		elements    => \@_,
		required    => [ qw( id title updated ) ],
		optional    => [ qw( author category contributor generator icon logo link rights subtitle ) ],
		singular    => [ qw( generator icon logo id rights subtitle title updated ) ],
		callback    => {
			author    => sub { $self->{ have_default_author } = 1 },
			updated   => sub { $self->{ global_updated } = $_[ 0 ] },
			generator => sub { $have_generator = 1 },
		},
		default_upd => time,
	);

	$self->{ meta } .= $make_tag{ generator }->( generator => DEFAULT_GENERATOR )
		unless $have_generator;

	return $self;
}

sub XML::Atom::SimpleFeed::add_entry  {
	my $self = shift;

	my @required = qw( id title updated );
	my @optional = qw( category content contributor link published rights summary );

	push @{ $self->{ have_default_author } ? \@optional : \@required }, 'author';

	# FIXME
	# 
	# o  atom:entry elements that contain no child atom:content element
	#    MUST contain at least one atom:link element with a rel attribute
	#    value of "alternate".
	# 
	# o  atom:entry elements MUST contain an atom:summary element in either
	#    of the following cases:
	#    *  the atom:entry contains an atom:content that has a "src"
	#       attribute (and is thus empty).
	#    *  the atom:entry contains content that is encoded in Base64;
	#       i.e., the "type" attribute of atom:content is a MIME media type
	#       [MIMEREG], but is not an XML media type [RFC3023], does not
	#       begin with "text/", and does not end with "/xml" or "+xml".

	local $XML_ENC[0] = $self->{ xml_encoding };
	push @{ $self->{ entries } }, xml_tag entry => container_content entry => (
		elements    => \@_,
		required    => \@required,
		optional    => \@optional,
		singular    => [ qw( content id published rights summary ) ],
		default_upd => $self->{ global_updated },
	);

	return $self;
}

sub XML::Atom::SimpleFeed::as_string {
	my $self = shift;
	local $XML_ENC[0] = $self->{ xml_encoding };
	PREAMBLE . xml_tag [ feed => xmlns => ATOM_NS ], $self->{ meta }, @{ $self->{ entries } };
}

sub XML::Atom::SimpleFeed::print {
	my $self = shift;
	my ( $handle ) = @_;
	local $, = local $\ = '';
	defined $handle ? print $handle $self->as_string : print $self->as_string;
}

sub XML::Atom::SimpleFeed::save_file { croak q{no longer supported, use 'print' instead and pass in a filehandle} }

!!'Funky and proud of it.';

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Atom::SimpleFeed - No-fuss generation of Atom syndication feeds

=head1 VERSION

version 0.902

=head1 SYNOPSIS

 use XML::Atom::SimpleFeed;
 
 my $feed = XML::Atom::SimpleFeed->new(
     title   => 'Example Feed',
     link    => 'http://example.org/',
     link    => { rel => 'self', href => 'http://example.org/atom', },
     updated => '2003-12-13T18:30:02Z',
     author  => 'John Doe',
     id      => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6',
 );
 
 $feed->add_entry(
     title     => 'Atom-Powered Robots Run Amok',
     link      => 'http://example.org/2003/12/13/atom03',
     id        => 'urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a',
     summary   => 'Some text.',
     updated   => '2003-12-13T18:30:02Z',
     category  => 'Atom',
     category  => 'Miscellaneous',
 );
 
 $feed->print;

=head1 DESCRIPTION

This is a minimal API for generating Atom syndication feeds quickly and easily.
It supports all aspects of the Atom format itself but has no mechanism for the
inclusion of extension elements.

You can supply strings for most things, and the module will provide useful
defaults. When you want more control, you can provide data structures, as
documented, to specify more particulars.

=head1 INTERFACE

=head2 C<new>

Takes a list of key-value pairs.

Most keys are used to create corresponding L<"Atom elements"|/ATOM ELEMENTS>.
To specify multiple instances of an element that may be given multiple times,
pass multiple key-value pairs with the same key.

Keys that start with a dash specify how the XML document will be generated.

The following keys are supported:

=over

=item * C<-encoding> (I<omissible>, default C<us-ascii>)

=item * L</C<id>> (I<omissible>)

=item * L</C<link>> (I<omissible>, multiple)

=item * L</C<title>> (B<required>)

=item * L</C<author>> (optional, multiple)

=item * L</C<category>> (optional, multiple)

=item * L</C<contributor>> (optional, multiple)

=item * L</C<generator>> (optional)

=item * L</C<icon>> (optional)

=item * L</C<logo>> (optional)

=item * L</C<rights>> (optional)

=item * L</C<subtitle>> (optional)

=item * L</C<updated>> (optional)

=back

=head2 C<add_entry>

Takes a list of key-value pairs,
used to create corresponding L<"Atom elements"|/ATOM ELEMENTS>.
To specify multiple instances of an element that may be given multiple times,
pass multiple key-value pairs with the same key.

The following keys are supported:

=over

=item * L</C<author>> (B<required> unless there is a feed-level author, multiple)

=item * L</C<id>> (I<omissible>)

=item * L</C<link>> (B<required>, multiple)

=item * L</C<title>> (B<required>)

=item * L</C<category>> (optional, multiple)

=item * L</C<content>> (optional)

=item * L</C<contributor>> (optional, multiple)

=item * L</C<published>> (optional)

=item * L</C<rights>> (optional)

=item * L</C<summary>> (optional)

=item * L</C<updated>> (optional)

=back

=head2 C<as_string>

Returns the XML representation of the feed as a string.

=head2 C<print>

Outputs the XML representation of the feed to a handle which should be passed
as a parameter. Defaults to C<STDOUT> if you do not pass a handle.

=head1 ATOM ELEMENTS

=head2 C<author>

A L</Person Construct> denoting the author of the feed or entry.

If you supply at least one author for the feed, you can omit this information
from entries; the feed's author(s) will be assumed as the author(s) for those
entries. If you do not supply any author for the feed, you B<must> supply one
for each entry.

=head2 C<category>

One or more categories that apply to the feed or entry. You can supply a string
which will be used as the category term. The full range of details that can be
provided by passing a hash instead of a string is as follows:

=over

=item C<term> (B<required>)

The category term.

=item C<scheme> (optional)

A URI that identifies a categorization scheme.

It is common to provide the base of some kind of by-category URL here. F.ex.,
if the weblog C<http://www.example.com/blog/> can be browsed by category using
URLs such as C<http://www.example.com/blog/category/personal>, you would supply
C<http://www.example.com/blog/category/> as the scheme and, in that case,
C<personal> as the term.

=item C<label> (optional)

A human-readable version of the term.

=back

=head2 C<content>

The actual, honest-to-goodness, body of the entry. This is like a
L</Text Construct>, with a couple of extras.

In addition to the C<type> values of a L</Text Construct>, you can also supply
any MIME Type (except multipart types, which the Atom format specification
forbids). If you specify a C<text/*> type, the same rules apply as for C<text>.
If you pass a C<*/xml> or C<*/*+xml> type, the same rules apply as for C<xhtml>
(except in that case there is no wrapper C<< <div> >> element). Any other type
will be transported as Base64-encoded binary.

XXX Furthermore, you can supply a C<src> key in place of the C<content> key. In
that case, the value of the C<src> key should be a URL denoting the actual
location of the content. FIXME This is not currently supported. XXX

=head2 C<contributor>

A L</Person Construct> denoting a contributor to the feed or entry.

=head2 C<generator>

The software used to generate the feed. Can be supplied as a string
or as a hash with C<uri>, C<version> and C<name> keys. Can also be undef to
suppress the element entirely. If nothing is passed, defaults to reporting
XML::Atom::SimpleFeed as the generator.

=head2 C<icon>

The URI of a small image whose width and height should be identical.

=head2 C<id>

A URI that is a permanent, globally unique identifier for the feed or entry
that B<MUST NEVER CHANGE>.

You are encouraged to generate a UUID using L<Data::UUID> for the purpose of
identifying entries/feeds. It should be stored alongside the resource
corresponding to the entry/feed, f.ex. in a column of the article table of your
weblog database. To use it as an identifier in the entry/feed, use the
C<urn:uuid:########-####-####-####-############> URI form.

If you do not specify an ID, the permalink will be used instead. This is
unwise, as permalinks do unfortunately occasionally change.
B<It is your responsibility to ensure that the permalink NEVER CHANGES.>

=head2 C<link>

A link element. You can either supply a bare string as the parameter, which
will be used as the permalink URI, or a hash. The permalink for a feed is
generally a browser-viewable weblog, upload browser, search engine results page
or similar web page; for an entry, it is generally a browser-viewable article,
upload details page, search result or similar web page. This URI I<should> be
unique. If you supply a hash, you can provide the following range of details in
the given hash keys:

=over

=item C<rel> (optional)

The link relationship. If omitted, defaults to C<alternate> (note that you can
only have one alternate link per feed/entry). Other permissible values are
C<related>, C<self>, C<enclosure> and C<via>, as well as any URI.

=item C<href> (B<required> URL)

Where the link points to.

=item C<type> (optional)

An advisory media type that provides a hint about the type of the resource
pointed to by the link.

=item C<hreflang> (optional)

The language of the resource pointed to by the link, an an RFC3066 language tag.

=item C<title> (optional)

Human-readable information about the link.

=item C<length> (optional)

A hint about the content length in bytes of the resource pointed to by the link.

=back

=head2 C<logo>

The URI of an image that should be twice as wide as it is high.

=head2 C<published>

A L</Date Construct> denoting the moment in time when the entry was first
published. This should never change.

=head2 C<rights>

A L</Text Construct> containing a human-readable statement of legal rights for
the content of the feed or entry. This is not intended for machine processing.

=head2 C<subtitle>

A L</Text Construct> containing an optional additional description of the feed.

=head2 C<summary>

A L</Text Construct> giving a short summary of the entry.

=head2 C<title>

A L</Text Construct> containing the title of the feed or entry.

=head2 C<updated>

A L</Date Construct> denoting the moment in time when the feed or entry was
last updated. Defaults to the current date and time if omitted.

In entries, you can use this element to signal I<significant> changes at your
discretion.

=head1 COMMON ATOM CONSTRUCTS

A number of Atom elements share a common structure. The following sections
outline the data you can (or must) pass in each case.

=head2 Date Construct

A string denoting a date and time in W3CDTF format. You can generate those
using something like

 use POSIX 'strftime';
 my $now = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime;

However, you can also simply pass a Unix timestamp (a positive integer) or an
object that responds to an C<epoch> method call. (Make sure that the timezone
reported by such objects is correct!)

The following datetime classes from CPAN are compatible with this interface:

=over 4

=item * L<Time::Piece|Time::Piece>

=item * L<DateTime|DateTime>

=item * L<Time::Moment|Time::Moment>

=item * L<Panda::Date|Panda::Date>

=item * L<Class::Date|Class::Date>

=item * L<Time::Object|Time::Object> (an obsolete precursor to L<Time::Piece|Time::Piece>)

=item * L<Time::Date|Time::Date> (version 0.05 or newer)

=back

The following are not:

=over 4

=item * L<DateTime::Tiny|DateTime::Tiny>

This class lacks both an C<epoch> method or any way to emulate one E<ndash> as
well as any timezone support in the first place.
That makes it unsuitable in principle for use in Atom feeds E<ndash> unless you
have separate information about the timezone.

=item * L<Date::Handler|Date::Handler>

This class has a suitable methodE<hellip> but sadly, calls it C<Epoch>.
So it is left up to you to call C<< $dh->Epoch >> to pass such values.

=back

=head2 Person Construct

You can supply a string to Person Construct parameters, which will be used as
the name of the person. The full range of details that can be provided by
passing a hash instead of a string is as follows:

=over

=item C<name> (B<required>)

The name of the person.

=item C<email> (optional)

The person's email address.

=item C<uri> (optional)

A URI to distinguish this person. This would usually be a homepage, but need
not actually be a dereferencable URL.

=back

=head2 Text Construct

You can supply a string to Text Construct parameters, which will be used as the
HTML content of the element.

FIXME details, text/html/xhtml

=head1 SEE ALSO

=over

=item * Atom Enabled (L<http://www.atomenabled.org/>)

=item * W3CDTF Spec (L<http://www.w3.org/TR/NOTE-datetime>)

=item * RFC 3066 (L<http://rfc.net/rfc3066.html>)

=item * L<XML::Atom::Syndication>

=item * L<XML::Feed>

=back

=head1 BUGS AND LIMITATIONS

In C<content> elements, the C<src> attribute cannot be used, and non-XML or
non-text media types do not get Base64-encoded automatically. This is a bug.

There are practically no tests. This is a bug.

Support for C<xml:lang> and C<xml:base> is completely absent. This is a bug and
should be partially addressed in a future version. There are however no plans
to allow these attributes on arbitrary elements.

There are no plans to ever support generating feeds with arbitrary extensions,
although support for specific extensions may or may not be added in the future.

The C<source> element is not and may never be supported.

Nothing is done to ensure that text constructs with type C<xhtml> and entry
contents using either that or an XML media type are well-formed. So far, this
is by design. You should strongly consider using an XML writer if you want to
include content with such types in your feed.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
