package Text::MediawikiFormat;

use strict;
use warnings::register;

=head1 NAME

Text::MediawikiFormat - Translate Wiki markup into other text formats

=head1 VERSION

Version 1.04

=cut

our $VERSION = '1.04';

=head1 SYNOPSIS

    use Text::MediawikiFormat 'wikiformat';
    my $html = wikiformat ($raw);
    my $text = wikiformat ($raw, {}, {implicit_links => 1});

=head1 DESCRIPTION

L<http://wikipedia.org> and its sister projects use the PHP Mediawiki to format
their pages.  This module attempts to duplicate the Mediawiki formatting rules.
Those formatting rules can be simple and easy to use, while providing more
advanced options for the power user.  They are also easy to translate into
other, more complicated markup languages with this module.  It creates HTML by
default, but could produce valid POD, DocBook, XML, or any other format
imaginable.

The most important function is C<Text::MediawikiFormat::format()>.  It is
not exported by default, but will be exported as C<wikiformat()> if any
options at all are passed to the exporter, unless the name is overridden
explicitly.  See L<"EXPORT"> for more information.

It should be noted that this module is written as a drop in replacement for
L<Text::WikiMarkup> that expands on that modules functionality and provides
a default rule set that may be used to format text like the PHP Mediawiki.  It
is also well to note early that if you just want a Mediawiki clone (you don't
need to customize it heavily and you want integration with a back end
database), you should look at L<Wiki::Toolkit::Formatter::Mediawiki>.

=cut

use Carp qw(carp confess croak);
use CGI qw(:standard);
use Scalar::Util qw(blessed);
use Text::MediawikiFormat::Blocks;
use URI;
use URI::Escape qw(uri_escape uri_escape_utf8);

use vars qw($missing_html_packages %tags %opts %merge_matrix
	$uric $uricCheat $uriCruft);

BEGIN {
	# Try to load optional HTML packages, recording any errors.
	eval { require HTML::Parser };
	$missing_html_packages = $@;
	eval { require HTML::Tagset };
	$missing_html_packages .= $@;
}

###
### Defaults
###
%tags = (
	indent         => qr/^(?:[:*#;]*)(?=[:*#;])/,
	link           => \&_make_html_link,
	strong         => sub {"<strong>$_[0]</strong>"},
	emphasized     => sub {"<em>$_[0]</em>"},
	strong_tag     => qr/'''(.+?)'''/,
	emphasized_tag => qr/''(.+?)''/,

	code            => [ '<pre>',  "</pre>\n", '',       "\n" ],
	line            => [ '',       '',         '<hr />', "\n" ],
	paragraph       => [ "<p>",    "</p>\n",   '',       "\n", 1 ],
	paragraph_break => [ '',       '',         '',       "\n" ],
	unordered       => [ "<ul>\n", "</ul>\n",  '<li>',   "</li>\n" ],
	ordered         => [ "<ol>\n", "</ol>\n",  '<li>',   "</li>\n" ],
	definition => [ "<dl>\n", "</dl>\n", \&_dl ],
	header     => [ '',       "\n",      \&_make_header ],

	blocks => {
		code            => qr/^ /,
		header          => qr/^(=+)\s*(.+?)\s*\1$/,
		line            => qr/^-{4,}$/,
		ordered         => qr/^#\s*/,
		unordered       => qr/^\*\s*/,
		definition      => qr/^([;:])\s*/,
		paragraph       => qr/^/,
		paragraph_break => qr/^\s*$/,
	},

	indented       => { map { $_ => 1 } qw(ordered unordered definition) },
	nests          => { map { $_ => 1 } qw(ordered unordered definition) },
	nests_anywhere => { map { $_ => 1 } qw(nowiki) },

	blockorder => [
		qw(code header line ordered unordered definition
			paragraph_break paragraph)
	],
	implicit_link_delimiters => qr!\b(?:[A-Z][a-z0-9]\w*){2,}!,
	extended_link_delimiters => qr!\[(?:\[[^][]*\]|[^][]*)\]!,

	schemas => [qw(http https ftp mailto gopher)],

	unformatted_blocks => [qw(header nowiki pre)],

	allowed_tags => [    #HTML
		qw(b big blockquote br caption center cite code dd
			div dl dt em font h1 h2 h3 h4 h5 h6 hr i li ol p
			pre rb rp rt ruby s samp small strike strong sub
			sup table td th tr tt u ul var),

		# Mediawiki Specific
		qw(nowiki),
	],
	allowed_attrs => [
		qw(title align lang dir width height bgcolor),
		qw(clear),              # BR
		qw(noshade),            # HR
		qw(cite),               # BLOCKQUOTE, Q
		qw(size face color),    # FONT
		                        # For various lists, mostly deprecated but safe
		qw(type start value compact),

		# Tables
		qw(summary width border frame rules cellspacing
			cellpadding valign char charoff colgroup col
			span abbr axis headers scope rowspan colspan),
		qw(id class name style),    # For CSS
	],

	_toc => [],
);

%opts = (
	extended       => 1,
	implicit_links => 0,
	absolute_links => 1,
	prefix         => '',
	process_html   => 1,
	charset        => 'utf-8',
);

# Make sure import's argument hash contains an `as' entry.  `as' defaults to
# `wikiformat' when none is given.
sub _process_args {
	shift;    # Class
	return as => shift if @_ == 1;
	return as => 'wikiformat', @_;
}

# Delete the options (prefix, extended, implicit_links, ...) from a hash,
# returning a new hash with the deleted options.
sub _extract_opts {
	my %newopts;

	for my $key (
		qw{prefix extended implicit_links absolute_links
		process_html debug}
		)
	{
		if ( defined( my $val = delete $_[0]->{$key} ) ) {
			$newopts{$key} = $val;
		}
	}

	return \%newopts;
}

# Shamelessly ripped from Hash::Merge, which doesn't work in a threaded
# environment with two threads trying to use different merge matrices.
%merge_matrix = (
	SCALAR => {
		SCALAR => sub { return $_[0] },
		ARRAY  => sub { # Need to be able to replace scalar with array
			    # for extended_link_delimiters (could be array
			    # or regex).
			return $_[0];
		},
		HASH => sub {
			confess "Attempt to replace hash with scalar"
				if defined $_[0];
			return _clone( $_[1] );
		}
	},

	ARRAY => {
		SCALAR => sub {    # Need to be able to replace array with scalar
			               # for extended_link_delimiters (could be array
			               # or regex).
			return _clone( $_[0] );
		},
		ARRAY => sub { return _clone( $_[0] ); },
		HASH  => sub { confess "Attempt to replace hash with array" }
	},

	HASH => {
		SCALAR => sub { confess "Attempt to replace scalar with hash" },
		ARRAY  => sub { confess "Attempt to replace array with hash" },
		HASH   => sub { _merge_hash_elements( $_[0], $_[1] ) }
	}
);

# Return arrays and a deep copy of hashes.
sub _clone {
	my ($obj) = @_;
	my $type;
	if ( !defined $obj ) {    # Perl 5.005 compatibility
		$type = 'SCALAR';
	}
	elsif ( ref $obj eq 'HASH' ) {
		$type = 'HASH';
	}
	elsif ( ref $obj eq 'ARRAY' ) {
		$type = 'ARRAY';
	}
	else {
		$type = 'SCALAR';
	}

	return $obj if $type eq 'SCALAR';
	return $obj if $type eq 'ARRAY';

	my %copy;
	foreach my $key ( keys %$obj ) {
		$copy{$key} = _clone( $obj->{$key} );
	}
	return \%copy;
}

# This does a straight merge of hashes, delegating the merge-specific
# work to '_merge_hashes'.
sub _merge_hash_elements {
	my ( $left, $right ) = @_;
	die "Arguments for _merge_hash_elements must be hash references"
		unless UNIVERSAL::isa( $left, 'HASH' ) && UNIVERSAL::isa( $right, 'HASH' );

	my %newhash;
	foreach my $leftkey ( keys %$left ) {
		if ( exists $right->{$leftkey} ) {
			$newhash{$leftkey} = _merge_hashes( $left->{$leftkey}, $right->{$leftkey} );
		}
		else {
			$newhash{$leftkey} = _clone( $left->{$leftkey} );
		}
	}
	foreach my $rightkey ( keys %$right ) {
		$newhash{$rightkey} = _clone( $right->{$rightkey} )
			if !exists $left->{$rightkey};
	}
	return \%newhash;
}

sub _merge_hashes {
	my ( $left, $right ) = @_;

	# if one argument or the other is undefined or empty, don't worry about
	# copying, just return the original.
	return $right unless defined $left;
	return $left  unless defined $right;

	# For the general use of this function, we want to create duplicates
	# of all data that is merged.

	my ( $lefttype, $righttype );
	if ( ref $left eq 'HASH' ) {
		$lefttype = 'HASH';
	}
	elsif ( ref $left eq 'ARRAY' ) {
		$lefttype = 'ARRAY';
	}
	else {
		$lefttype = 'SCALAR';
	}

	if ( ref $right eq 'HASH' ) {
		$righttype = 'HASH';
	}
	elsif ( ref $right eq 'ARRAY' ) {
		$righttype = 'ARRAY';
	}
	else {
		$righttype = 'SCALAR';
	}

	return $merge_matrix{$lefttype}->{$righttype}( $left, $right );
}

sub _require_html_packages {
	croak "$missing_html_packages\n" . "HTML::Parser & HTML::Tagset is required for process_html\n"
		if $missing_html_packages;
}

sub import {
	return unless @_ > 1;

	my $class = shift;
	my %args  = $class->_process_args(@_);
	my $name  = delete $args{as};

	my $caller = caller();
	my $iopts  = _merge_hashes _extract_opts( \%args ), \%opts;
	my $itags  = _merge_hashes \%args, \%tags;

	_require_html_packages
		if $iopts->{process_html};

	# Could verify ITAGS here via _check_blocks, but what if a user
	# wants to add a block to block_order that they intend to override
	# the implementation of with every call to format()?

	no strict 'refs';
	*{ $caller . "::" . $name } = sub {
		Text::MediawikiFormat::_format( $itags, $iopts, @_ );
		}
}

=head1 FUNCTIONS

=head2 format

C<format()> takes one required argument, the text to convert, and returns the
converted text.  It allows two optional arguments.  The first is a reference to
a hash of tags used to override the function's default behavior.  Anything
passed in here will override the default tags.  The second argument is a hash
reference of options.  The options are currently:

=over 4

=item prefix

The prefix of any links to wiki pages.  In HTML mode, this is the path to the
Wiki.  The actual linked item itself will be appended to the prefix.  This is
useful to create full URIs:

    {prefix => 'http://example.com/wiki.pl?page='}

=item extended

A boolean flag, true by default, to let square brackets mark links.
An optional title may occur after the Wiki targets, preceded by an open pipe.
URI titles are separated from their title with a space.  These are valid
extended links:

    [[A wiki page|and the title to display]]
    [http://ximbiot.com URI title]

Where the linking semantics of the destination format allow it, the result will
display the title instead of the URI.  In HTML terms, the title is the content
of an C<A> element (not the content of its C<HREF> attribute).

You can use delimiters other than single square brackets for marking extended
links by passing a value for C<extended_link_delimiters> in the C<%tags> hash
when calling C<format>.

Note that if you disable this flag, you should probably enable
C<implicit_links> or there will be no automated way to link to other pages in
your wiki.

=item implicit_links

A boolean flag, false by default, to create links from StudlyCapsStrings.

=item absolute_links

A boolean flag, true by default, which treats any links that are absolute URIs
(such as C<http://www.cpan.org/>) specially.  Any prefix will not apply.
This should maybe be called implicit_absolute_links since the C<extended>
option enables absolute links inside square brackets by default.

A link is any text that starts with a known schema followed by a colon and one
or more non-whitespace characters.  This is a distinct subset of what L<URI>
recognizes as a URI, but is a good first-order approximation.  If you need to
recognize more complex URIs, use the standard wiki formatting explained
earlier.

The recognized schemas are those defined in the C<schema> value in the C<%tags>
hash.  C<schema> defaults to C<http>, C<https>, C<ftp>, C<mailto>, and
C<gopher>.

=item process_html

This flag, true by default, causes the formatter to ignore block level wiki
markup (code, ordered, unordered, etc...) when they occur on lines which also
contain allowed block-level HTML tags (<pre>, <ol>, <ul>, </pre>, etc...).
Phrase level wiki markup (emphasis, strong, & links) is unaffected by this
flag.

=back

=cut

sub format {
	_format( \%tags, \%opts, @_ );
}

# Turn the contents after a ; or : into a dictionary list.
# Using : without ; just looks like an indent.
sub _dl {

	#my ($line, $indent, $lead) = @_;
	my ( $term, $def );

	if ( $_[2] eq ';' ) {
		if ( $_[0] =~ /^(.*?)\s+:\s+(.*)$/ ) {
			$term = $1;
			$def  = $2;
		}
		else {
			$term = $_[0];
		}
	}
	else {
		$def = $_[0];
	}

	my @retval;
	push @retval, "<dt>", $term, "</dt>\n" if defined $term;
	push @retval, "<dd>", $def,  "</dd>\n" if defined $def;
	return @retval;
}

# Makes a regex out of the allowed schema array.
sub _make_schema_regex {
	my $re = join "|", map {qr/\Q$_\E/} @_;
	return qr/(?:$re)/;
}

$uric      = $URI::uric;
$uricCheat = $uric;

# We need to avoid picking up 'HTTP::Request::Common' so we have a
# subset of uric without a colon.
$uricCheat =~ tr/://d;

# Identifying characters often accidentally picked up trailing a URI.
$uriCruft = q/]),.!'";}/;

# escape a URI based on our charset.
sub _escape_uri {
	my ( $opts, $uri ) = @_;
	confess "charset not initialized" unless $opts->{charset};
	return uri_escape_utf8 $uri if $opts->{charset} =~ /^utf-?8$/i;
	return uri_escape $uri;
}

# Turn [[Wiki Link|Title]], [URI Title], scheme:url, or StudlyCaps into links.
sub _make_html_link {
	my ( $tag, $opts, $tags ) = @_;

	my ( $class, $trailing ) = ( '', '' );
	my ( $href, $title );
	if ( $tag =~ /^\[\[([^|#]*)(?:(#)([^|]*))?(?:(\|)(.*))?\]\]$/ ) {

		# Wiki link
		$href = $opts->{prefix} . _escape_uri $opts, $1 if $1;
		$href .= $2 . _escape_uri $opts, $3 if $2;

		if ($4) {

			# Title specified explicitly.
			if ( length $5 ) {
				$title = $5;
			}
			else {
				# An empty title asks Mediawiki to strip any parens off the end
				# of the node name.
				$1 =~ /^([^(]*)(?:\s*\()?/;
				$title = $1;
			}
		}
		else {
			# Title defaults to the node name.
			$title = $1;
		}
	}
	elsif ( $tag =~ /^\[(\S*)(?:(\s+)(.*))?\]$/ ) {

		# URI
		$href = $1;
		if ($2) {
			$title = $3;
		}
		else {
			$title = ++$opts->{_uri_refs};
		}
		$href =~ s/'/%27/g;
	}
	else {
		# Shouldn't be able to get here without either $opts->{absolute_links}
		# or $opts->{implicit_links};
		$tags->{_schema_regex} ||= _make_schema_regex @{ $tags->{schemas} };
		my $s = $tags->{_schema_regex};

		if ( $tag =~ /^$s:[$uricCheat][$uric]*$/ ) {

			# absolute link
			$href     = $&;
			$trailing = $& if $href =~ s/[$uriCruft]$//;
			$title    = $href;
		}
		else {
			# StudlyCaps
			$href = $opts->{prefix} . _escape_uri $opts, $tag;
			$title = $tag;
		}
	}

	return "<a$class href='$href'>$title</a>$trailing";
}

# Store a TOC line for later.
#
# ASSUMPTIONS
#   $level >= 1
sub _store_toc_line {
	my ( $toc, $level, $title, $name ) = @_;

	# TODO: Strip formatting from $title.

	if ( @$toc && $level > $toc->[-1]->{level} ) {

		# Nest a sublevel.
		$toc->[-1]->{sublevel} = []
			unless exists $toc->[-1]->{sublevel};
		_store_toc_line( $toc->[-1]->{sublevel}, $level, $title, $name );
	}
	else {
		push @$toc, { level => $level, title => $title, name => $name };
	}

	return $level;
}

# Make header text, storing the line for the TOC.
#
# ASSUMPTIONS
#   $tags->{_toc} has been initialized to an array ref.
sub _make_header {
	my $level = length $_[2];
	my $n = _escape_uri $_[-1], $_[3];

	_store_toc_line( $_[-2]->{_toc}, $level, $_[3], $n );

	return "<a name='$n'></a><h$level>", Text::MediawikiFormat::format_line( $_[3], @_[ -2, -1 ] ), "</h$level>\n";
}

sub _format {
	my ( $itags, $iopts, $text, $tags, $opts ) = @_;

	# Overwriting the caller's hashes locally after merging its contents
	# is okay.
	$tags = _merge_hashes( $tags || {}, $itags );
	$opts = _merge_hashes( $opts || {}, $iopts );

	_require_html_packages
		if $opts->{process_html};

	# Always verify the blocks since the user may have slagged the
	# default hash on import.
	_check_blocks($tags);

	my @blocks = _find_blocks( $text, $tags, $opts );
	@blocks = _nest_blocks( \@blocks );
	return _process_blocks( \@blocks, $tags, $opts );
}

sub _check_blocks {
	my $tags   = shift;
	my %blocks = %{ $tags->{blocks} };
	delete @blocks{ @{ $tags->{blockorder} } };

	carp "No order specified for blocks: " . join( ', ', keys %blocks ) . ".\n"
		if keys %blocks;
}

# This sub recognizes three states:
#
#   1.  undef
#       Normal wiki processing will be done on this line.
#
#   2.  html
#       Links and phrasal processing will be done, but formatting should be
#       ignored.
#
#   3.  nowiki
#       No further wiki processing should be done.
#
# Each state may override the lower ones if already set on a given line.
#
sub _append_processed_line {
	my ( $parser, $text, $state ) = @_;
	my $lines = $parser->{processed_lines};

	$state ||= '';

	my @newlines = split /(?<=\n)/, $text;
	if (
		   @$lines
		&& $lines->[-1]->[1] !~ /\n$/
		&&    # State not changing from or to 'nowiki'
		!( $state ne $lines->[-1]->[0] && grep /^nowiki$/, $state, $lines->[-1]->[0] )
		)
	{
		$lines->[-1]->[1] .= shift @newlines;
		$lines->[-1]->[0] = $state if $state eq 'html';
	}

	foreach my $line (@newlines) {
		$lines->[-1]->[2] = '1' if @$lines;
		push @$lines, [ $state, $line ];
	}
	$lines->[-1]->[2] = '1'
		if @$lines && $lines->[-1]->[1] =~ /\n$/;
}

sub _html_tag {
	my ( $parser, $type, $tagname, $orig, $attr ) = @_;
	my $tags = $parser->{tags};

	# $tagname may have been generated by an empty tag.  If so, HTML::Parser
	# will sometimes include the trailing / in the tag name.
	my $isEmptyTag = $orig =~ m#/>$#;
	$tagname =~ s#/$## if $isEmptyTag;

	unless ( grep /^\Q$tagname\E$/, @{ $tags->{allowed_tags} } ) {
		_append_processed_line $parser, CGI::escapeHTML $orig;
		return;
	}

	# Any $tagname must now be in the allowed list, including <nowiki>.

	my $tagstack = $parser->{tag_stack};
	my $stacktop = @$tagstack ? $tagstack->[-1] : '';

	# First, process end tags, since they can change our state.
	if ( $type eq 'E' && $stacktop eq $tagname ) {

		# The closing tag is at the top of the stack, like it should be.
		# Pop it and append the close tag to the output.
		pop @$tagstack;
		my $newtag;

		if ( $tagname eq 'nowiki' ) {

			# The browser doesn't need to see the </nowiki> tag.
			$newtag = '';
		}
		else {
			$newtag = "</$tagname>";
		}

		# Can't close a state into <pre> or <nowiki>
		_append_processed_line $parser, $newtag, 'html';
		return;
	}

	if ( @$tagstack && grep /^\Q$stacktop\E$/, qw{nowiki pre} ) {

		# Ignore all markup within <pre> or <nowiki> tags.
		_append_processed_line $parser, CGI::escapeHTML($orig), 'nowiki';
		return;
	}

	if ( $type eq 'E' && $HTML::Tagset::isPhraseMarkup{$tagname} )

		# If we ask for artificial end element events for self-closed elements,
		# then we need to check $HTML::Tagset::emptyElement($tagname) here too.
	{
		# We didn't record phrase markup on the stack, so it's okay to just
		# let it close.
		_append_processed_line $parser, "</$tagname>";
		return;
	}

	if ( $type eq 'E' ) {

		# We got a non-phrase end tag that wasn't on the stack.  Escape it.
		_append_processed_line $parser, CGI::escapeHTML($orig);
		return;
	}

	###
	### $type must now eq 'S'.
	###

	# The browser doesn't need to see the <nowiki> tag.
	if ( $tagname eq 'nowiki' ) {
		push @$tagstack, $tagname
			unless $isEmptyTag;
		return;
	}

	# Strip disallowed attributes.
	my $newtag = "<$tagname";
	foreach ( @{ $tags->{allowed_attrs} } ) {
		if ( defined $attr->{$_} ) {
			$newtag .= " $_";
			unless ( $attr->{$_} eq '__TEXT_MEDIAWIKIFORMAT_BOOL__' ) {

				# CGI::escapeHTML escapes single quotes.
				$attr->{$_} = CGI::escapeHTML $attr->{$_};
				$newtag .= "='" . $attr->{$_} . "'";
			}
		}
	}
	$newtag .= " /" if $HTML::Tagset::emptyElement{$tagname} || $isEmptyTag;
	$newtag .= ">";

	# If this isn't a block level element, there's no need to track nesting.
	if (   $HTML::Tagset::isPhraseMarkup{$tagname}
		|| $HTML::Tagset::emptyElement{$tagname} )
	{
		_append_processed_line $parser, $newtag;
		return;
	}

	# Some elements can close implicitly
	if (@$tagstack) {
		if (   $tagname eq $stacktop
			&& $HTML::Tagset::optionalEndTag{$tagname} )
		{
			pop @$tagstack;
		}
		elsif ( !$HTML::Tagset::is_Possible_Strict_P_Content{$tagname} ) {

			# Need to check more than the last item for paragraphs.
			for ( my $i = $#{$tagstack}; $i >= 0; $i-- ) {
				my $checking = $tagstack->[$i];
				last if grep /^\Q$checking\E$/, @HTML::Tagset::p_closure_barriers;

				if ( $checking eq 'p' ) {

					# pop 'em all.
					splice @$tagstack, $i;
					last;
				}
			}
		}
	}

	# Could verify here that <li> and <table> sub-elements only appear where
	# they belong.

	# Push the new tag onto the stack.
	push @$tagstack, $tagname
		unless $isEmptyTag;

	_append_processed_line $parser, $newtag, $tagname eq 'pre' ? 'nowiki' : 'html';
	return;
}

sub _html_comment {
	my ( $parser, $text ) = @_;

	_append_processed_line $parser, $text, 'nowiki';
}

sub _html_text {
	my ( $parser, $dtext, $skipped_text, $is_cdata ) = @_;
	my $tagstack = $parser->{tag_stack};
	my ( $newtext, $newstate );

	warnings::warnif("Got skipped_text: `$skipped_text'")
		if $skipped_text;

	if (@$tagstack) {
		if ( grep /\Q$tagstack->[-1]\E/, qw{nowiki pre} ) {
			$newstate = 'nowiki';
		}
		elsif ( $is_cdata && $HTML::Tagset::isCDATA_Parent{ $tagstack->[-1] } ) {

			# If the user hadn't specifically allowed a tag which contains
			# CDATA, then it won't be on the tag stack.
			$newtext = $dtext;
		}
	}

	unless ( defined $newtext ) {
		$newtext = CGI::escapeHTML $dtext unless defined $newtext;

		# CGI::escapeHTML escapes single quotes so the text may be included
		# in attribute values, but we know we aren't processing an attribute
		# value here.
		$newtext =~ s/&#39;/'/g;
	}

	_append_processed_line $parser, $newtext, $newstate;
}

sub _find_blocks_in_html {
	my ( $text, $tags, $opts ) = @_;

	my $parser = HTML::Parser->new(
		start_h                 => [ \&_html_tag,     'self, "S", tagname, text, attr' ],
		end_h                   => [ \&_html_tag,     'self, "E", tagname, text' ],
		comment_h               => [ \&_html_comment, 'self, text' ],
		text_h                  => [ \&_html_text,    'self, dtext, skipped_text, is_cdata' ],
		marked_sections         => 1,
		boolean_attribute_value => '__TEXT_MEDIAWIKIFORMAT_BOOL__',
	);
	$parser->{opts}            = $opts;
	$parser->{tags}            = $tags;
	$parser->{processed_lines} = [];
	$parser->{tag_stack}       = [];

	my @blocks;
	my @lines = split /\r?\n/, $text;
	for ( my $i = 0; $i < @lines; $i++ ) {
		$parser->parse( $lines[$i] );
		$parser->parse("\n");
		$parser->eof if $i == $#lines;

		# @{$parser->{processed_lines}} may be empty when tags are
		# still open.
		while ( @{ $parser->{processed_lines} }
			&& $parser->{processed_lines}->[0]->[2] )
		{
			my ( $type, $dtext )
				= @{ shift @{ $parser->{processed_lines} } };

			my $block;
			if ($type) {
				$block = _start_block( $dtext, $tags, $opts, $type );
			}
			else {
				chomp $dtext;
				$block = _start_block( $dtext, $tags, $opts );
			}
			push @blocks, $block if $block;
		}
	}

	return @blocks;
}

sub _find_blocks {
	my ( $text, $tags, $opts ) = @_;
	my @blocks;

	if ( $opts->{process_html} ) {
		@blocks = _find_blocks_in_html $text, $tags, $opts;
	}
	else {
		# The original behavior.
		for my $line ( split /\r?\n/, $text ) {
			my $block = _start_block( $line, $tags, $opts );
			push @blocks, $block if $block;
		}
	}

	return @blocks;
}

sub _start_block {
	my ( $text, $tags, $opts, $type ) = @_;

	return new_block( 'end', level => 0 ) unless $text;
	return new_block(
		$type,
		level => 0,
		opts  => $opts,
		text  => $text,
		tags  => $tags,
	) if $type;

	for my $block ( @{ $tags->{blockorder} } ) {
		my ( $line, $level, $indentation ) = ( $text, 0, '' );

		( $level, $line, $indentation ) = _get_indentation( $tags, $line )
			if $tags->{indented}{$block};

		my $marker_removed = length( $line =~ s/$tags->{blocks}{$block}// );

		next unless $marker_removed;

		return new_block(
			$block,
			args => [ grep {defined} $1, $2, $3, $4, $5, $6, $7, $8, $9 ],
			level => $level || 0,
			opts  => $opts,
			text  => $line,
			tags  => $tags,
		);
	}
}

sub _nest_blocks {
	my $blocks = shift;
	return unless @$blocks;

	my @processed = shift @$blocks;

	for my $block (@$blocks) {
		push @processed, $processed[-1]->nest($block);
	}

	return @processed;
}

sub _process_blocks {
	my ( $blocks, $tags, $opts ) = @_;

	my @open;
	for my $block (@$blocks) {
		push @open, _process_block( $block, $tags, $opts )
			unless $block->type() eq 'end';
	}

	return join '', @open;
}

sub _process_block {
	my ( $block, $tags, $opts ) = @_;
	my $type = $block->type();

	my ( $start, $end, $start_line, $end_line, $between );
	if ( $tags->{$type} ) {
		( $start, $end, $start_line, $end_line, $between ) = @{ $tags->{$type} };
	}
	else {
		( $start, $end, $start_line, $end_line ) = ( '', '', '', '' );
	}

	my @text = ();
	for my $line (
		grep ( /^\Q$type\E$/, @{ $tags->{unformatted_blocks} } )
		? $block->text()
		: $block->formatted_text()
		)
	{
		if ( blessed $line) {
			my $prev_end = pop @text || ();
			push @text, _process_block( $line, $tags, $opts ), $prev_end;
			next;
		}

		my @triplets;
		if ( ( ref($start_line) || '' ) eq 'CODE' ) {
			@triplets = $start_line->( $line, $block->level(), $block->shift_args(), $tags, $opts );
		}
		else {
			@triplets = ( $start_line, $line, $end_line );
		}
		push @text, @triplets;
	}

	pop @text if $between;
	return join '', $start, @text, $end;
}

sub _get_indentation {
	my ( $tags, $text ) = @_;

	return 1, $text unless $text =~ s/($tags->{indent})//;
	return length($1) + 1, $text, $1;
}

=head2 format_line

	$formatted = format_line ($raw, $tags, $opts);

This function is never exported.  It formats the phrase elements of a single
line of text (emphasised, strong, and links).

This is only meant to be called from L<Text::MediawikiFormat::Block> and so
requires $tags and $opts to have all elements filled in.  If you find a use for
it, please let me know and maybe I will have it default the missing elements as
C<format()> does.

=cut

sub format_line {
	my ( $text, $tags, $opts ) = @_;

	$text =~ s!$tags->{strong_tag}!$tags->{strong}->($1, $opts)!eg;
	$text =~ s!$tags->{emphasized_tag}!$tags->{emphasized}->($1, $opts)!eg;

	$text = _find_links( $text, $tags, $opts )
		if $opts->{extended}
		|| $opts->{absolute_links}
		|| $opts->{implicit_links};

	return $text;
}

sub _find_innermost_balanced_pair {
	my ( $text, $open, $close ) = @_;

	my $start_pos = rindex $text, $open;
	return if $start_pos == -1;

	my $end_pos = index $text, $close, $start_pos;
	return if $end_pos == -1;

	my $open_length     = length $open;
	my $close_length    = length $close;
	my $close_pos       = $end_pos + $close_length;
	my $enclosed_length = $close_pos - $start_pos;

	my $enclosed_atom = substr $text, $start_pos, $enclosed_length;
	return substr( $enclosed_atom, $open_length, 0 - $close_length ),
		substr( $text, 0, $start_pos ),
		substr( $text, $close_pos );
}

sub _find_links {
	my ( $text, $tags, $opts ) = @_;

	# Build Regexp
	my @res;

	if ( $opts->{absolute_links} ) {

		# URI
		my $s;
		$tags->{_schema_regex} ||= _make_schema_regex @{ $tags->{schemas} };
		$s = $tags->{_schema_regex};
		push @res, qr/\b$s:[$uricCheat][$uric]*/;
	}

	if ( $opts->{implicit_links} ) {

		# StudlyCaps
		if ( $tags->{implicit_link_delimiters} ) {
			push @res, qr/$tags->{implicit_link_delimiters}/;
		}
		else {
			warnings::warnif("Ignoring implicit_links option since implicit_link_delimiters is empty");
		}
	}

	if ( $opts->{extended} ) {

		# [[Wiki Page]]
		if ( !$tags->{extended_link_delimiters} ) {
			warnings::warnif("Ignoring extended option since extended_link_delimiters is empty");
		}
		elsif ( ref $tags->{extended_link_delimiters} eq "ARRAY" ) {

			# Backwards compatibility for extended links.
			# Bypasses the regex substitution used by absolute and implicit
			# links.
			my ( $start, $end ) = @{ $tags->{extended_link_delimiters} };
			while ( my @pieces = _find_innermost_balanced_pair( $text, $start, $end ) ) {
				my ( $tag, $before, $after ) = map { defined $_ ? $_ : '' } @pieces;
				my $extended = $tags->{link}->( $tag, $opts, $tags ) || '';
				$text = $before . $extended . $after;
			}
		}
		else {
			push @res, qr/$tags->{extended_link_delimiters}/;
		}
	}

	if (@res) {
		my $re = join "|", @res;
		$text =~ s/$re/$tags->{link}->($&, $opts, $tags)/ge;
	}

	return $text;
}

=head1 Wiki Format

Refer to L<http://en.wikipedia.org/wiki/Help:Contents/Editing_Wikipedia> for
description of the default wiki format, as interpreted by this module.  Any
discrepencies will be considered bugs in this module, with a few exceptions.

=head2 Unimplemented Wiki Markup

=over 4

=item Templates, Magic Words, and Wanted Links

Templates, magic words, and the colorization of wanted links all require a back
end data store that can be consulted on the existance and content of named
pages.  C<Text::MediawikiFormat> has deliberately been constructed such that it
operates independantly from such a back end.  For an interface to
C<Text::MediawikiFormat> which implements these features, see
L<Wiki::Toolkit::Formatter::Mediawiki>.

=item Tables

This is on the TODO list.

=back

=head1 EXPORT

If you'd like to make your life more convenient, you can optionally import a
subroutine that already has default tags and options set up.  This is
especially handy if you use a prefix:

    use Text::MediawikiFormat prefix => 'http://www.example.com/';
    wikiformat ('some text');

Tags are interpreted as default members of the $tags hash normally passed to
C<format>, except for the five options (see above) and the C<as> key, who's
value is interpreted as an alternate name for the imported function.

To use the C<as> flag to control the name by which your code calls the imported
function, for example,

    use Text::MediawikiFormat as => 'formatTextWithWikiStyle';
    formatTextWithWikiStyle ('some text');

You might choose a better name, though.

The calling semantics are effectively the same as those of the C<format()>
function.  Any additional tags or options to the imported function will
override the defaults.  This code:

    use Text::MediawikiFormat as => 'wf', extended => 0;
    wf ('some text', {}, {extended => 1});

enables extended links, after specifying that the default behavior should be
to disable them.

=head1 GORY DETAILS

=head2 Tags

There are two types of Wiki markup: phrase markup and blocks.  Blocks include
lists, which are made up of lines and can also contain other lists.

=head3 Phrase Markup

The are currently three types of wiki phrase markup.  These are the
strong and emphasized markup and links.  Links may additionally be of three
subtypes, extended, implicit, or absolute.

You can change the regular expressions used to find strong and emphasized tags:

    %tags = (
        strong_tag     => qr/\*([^*]+?)\*/,
        emphasized_tag => qr|/([^/]+?)/|,
    );

    $wikitext = 'this is *strong*, /emphasized/, and */em+strong/*';
    $htmltext = wikiformat ($wikitext, \%tags, {});

You can also change the regular expressions used to find links.  The following
just sets them to their default states (but enables parsing of implicit links,
which is I<not> the default):

    my $html = wikiformat
    (
        $raw,
        {implicit_link_delimiters => qr!\b(?:[A-Z][a-z0-9]\w*){2,}!,
         extended_link_delimiters => qr!\[(?:\[[^][]*\]|[^][]*)\]!,
        },
        {implicit_links => 1}
    );

In addition, you may set the function references that format strong and
emphasized text and links.  The strong and emphasized functions receive only
the text to be formatted as an argument and are expected to return the
formatted text.  The link formatter also recieves references to the C<$tags>
and C<$opts> arrays.  For example, the following sets the strong and
emphasized formatters to their default state while replacing the link formatter
with one which strips href information and returns only the title text:

    my $html = wikiformat
    (
        $raw,
        {strong => sub {"<strong>$_[0]</strong>"},
         emphasized => sub {"<em>$_[0]</em>"},
         link => sub
         {
         my ($tag, $opts, $tags) = @_;
         if ($tag =~ s/^\[\[([^][]+)\]\]$/$1/)
         {
             my ($page, $title) = split qr/\|/, $tag, 2;
             return $title if $title;
             return $page;
         }
         elsif ($tag =~ s/^\[([^][]+)\]$/$1/)
         {
             my ($href, $title) = split qr/ /, $tag, 2;
             return $title if $title;
             return $href;
         }
         else
         {
             return $tag;
         }
         },
        },
    );

=head3 Blocks

The default block types are C<code>, C<line>, C<paragraph>, C<paragraph_break>,
C<unordered>, C<ordered>, C<definition>, and C<header>.

Block entries in the tag hashes must contain array references.  The first two
items are the tags used at the start and end of the block.  The third and
fourth contain the tags used at the start and end of each line.  Where there
needs to be more processing of individual lines, use a subref as the third
item.  This is how the module processes ordered lines in HTML lists and
headers:

    my $html = wikiformat
    (
        $raw,
        {ordered => ['<ol>', "</ol>\n", '<li>', "<li>\n"],
         header => ['', "\n", \&_make_header],
        },
    );

The first argument to these subrefs is the post-processed text of the line
itself.  (Processing removes the indentation and tokens used to mark this as a
list and checks the rest of the line for other line formattings.)  The second
argument is the indentation level (see below).  The subsequent arguments are
captured variables in the regular expression used to find this list type.  The
regexp for headers is:

    $html = wikiformat
    (
        $raw,
        {blocks => {header => qr/^(=+)\s*(.+?)\s*\1$/}}
    );

The module processes indentation first, if applicable, and stores the
indentation level (the length of the indentation removed).

Lists automatically start and end as necessary.

Because regular expressions could conceivably match more than one line, block
level markup is processed in a specific order.  The C<blockorder> tag governs
this order.  It contains a reference to an array of the names of the
appropriate blocks to process.  If you add a block type, be sure to add an
entry for it in C<blockorder>:

    my $html = wikiformat
    (
        $raw,
        {invisible => ['', '', '', ''],
         blocks => {invisible => qr!^--(.*?)--$!},
            blockorder => [qw(code header line ordered
                      unordered definition invisible
                      paragraph_break paragraph)]
               },
        },
);

=head3 Finding blocks

As has already been mentioned in passing, C<Text::MediawikiFormat> uses regular
expressions to find blocks.  These are in the C<%tags> hash under the C<blocks>
key.  For example, to change the regular expression to find code block items,
use:

    my $html = wikiformat ($raw, {blocks => {code => qr/^:\s+/}});

This will require a leading colon to mark code lines (note that as writted
here, this would interfere with the default processing of definition lists).

=head3 Finding Blocks in the Correct Order

As intrepid bug reporter Tom Hukins pointed out in CPAN RT bug #671, the order
in which C<Text::MediawikiFormat> searches for blocks varies by platform and
version of Perl.  Because some block-finding regular expressions are more
specific than others, what you intend to be one type of block may turn into a
different list type.

If you're adding new block types, be aware of this.  The C<blockorder> entry in
C<%tags> exists to force C<Text::MediawikiFormat> to apply its regexes from
most specific to least specific.  It contains an array reference.  By default,
it looks for ordered lists first, unordered lists second, and code references
at the end.

=head1 SEE ALSO

L<Wiki::Toolkit::Formatter::Mediawiki>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::MediawikiFormat

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-MediawikiFormat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-MediawikiFormat>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-MediawikiFormat>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-MediawkiFormat>

=back

=head1 AUTHOR

Derek Price C<derek at ximbiot.com> is the author.

=head1 ACKNOWLEDGEMENTS

This module is derived from L<Text::WikiFormat>, written by chromatic.
chromatic's original credits are below:

chromatic, C<chromatic at wgz.org>, with much input from the Jellybean team
(including Jonathan Paulett).  Kate L Pugh has also provided several patches,
many failing tests, and is usually the driving force behind new features and
releases.  If you think this module is worth buying me a beer, she deserves at
least half of it.  

Alex Vandiver added a nice patch and tests for extended links.

Tony Bowden, Tom Hukins, and Andy H. all suggested useful features that are now
implemented.  

Sam Vilain, Chris Winters, Paul Schmidt, and Art Henry have all found and
reported silly bugs.

Blame me for the implementation.

=head1 BUGS

The link checker in C<format_line()> may fail to detect existing links that do
not follow HTML, XML, or SGML style.  They may die with some SGML styles too.
I<Sic transit gloria mundi>.

=head1 TODO

=over 4

=item * Optimize C<format_line()> to work on a list of lines

=back

=head1 COPYRIGHT & LICENSE

 Copyright (c) 2006-2008 Derek R. Price, all rights reserved.
 Copyright (c) 2002 - 2006, chromatic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Text::MediaiwkiFormat
