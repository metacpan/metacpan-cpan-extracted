package Text::Microformat;
use strict;
use warnings;

=head1 NAME

Text::Microformat - A Microformat parser

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

	use Text::Microformat;
	use LWP::Simple;

	# Parse a document
	my $doc = Text::Microformat->new(
	    get('http://phil.windley.org/hcard.html')
	);
	
	# Extract all known Microformats
	my @formats = $doc->find;
	
	my $hcard = shift @formats;

	# Easiest way to get a value (returns the first one found, else undef)

	my $full_name = $hcard->Get('fn');
	my $family_name = $hcard->Get('n.family-name');
	my $city = $hcard->Get('adr.locality');

	# Get the human-readable version specifically

	my $family_name = $hcard->GetH('n.family-name');

	# Get the machine-readable version specifically

	my $family_name = $hcard->GetM('n.family-name');

	# The more powerful interface (access multiple properties)
		
	my $family_name = $hcard->n->[0]->family_name->[0]->Value;

	# Dump to a hash
	
	my $hash = $hcard->AsHash;
	
	# Dump to YAML
	
	print $hcard->ToYAML, "\n";
	
	# Free the document and all the formats
	
	$doc->delete;

=head1 DESCRIPTION

Text::Microformat is a Microformat parser for Perl.

Text::Microformat sports a very pluggable API, which allows not only new kinds
of Microformats to be added, but also extension of the parser itself, to allow
new parsing metaphors and source document encodings.

=head2 FEATURES

=over 4

=item * Extracting Microformats from HTML, XHTML and XML

=item * Extracting Microformats from entity-encoded or CDATA sections in RSS feeds.

=item * The include pattern

=item * Microformats built from other Microformats 

=back

=head2 SUPPORTED MICROFORMATS

=over 4

=item * hCard

=back

=head2 OTHER SUPPORTED SEMANTIC MARKUP

=over 4

=item * hGrant

=back

=cut

use Module::Pluggable require => 1, sub_name => 'plugins';
use Module::Pluggable search_path => 'Text::Microformat::Element', require => 1, sub_name => 'known_formats', except => qr/^Text\::Microformat\::Element\::\w+\::/;
use NEXT;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/tree content opts formats criteria/);
use Carp;

our @ISA;
push @ISA, $_ for  __PACKAGE__->plugins;

=head1 METHODS

=over 4

=item * new($content, %opts)

Parses the string $content and creates a new Text::Microformat object.

Recognized options:

=over 4

=item * content_type => 'text/html'

Specify the content type. Any content type containing 'html' invokes the HTML
Parser, and content type containing XML invokes XML Parser. Defaults to
'text/html'. (See L<HTML::TreeBuilder> and L<XML::TreeBuilder>)

=back

=cut

sub new {
    my $class = shift;
    my $content = shift;
    my %opts = @_;
    my $c = bless {opts => \%opts, content => $content, formats => []}, $class;
    $c->defaults;
	$c->pre_parse;
    $c->parse;
	croak("Could not find a parser for content type '", $c->opts->{content_type}, "'") unless $c->tree;
	$c->post_parse;
    return $c;
}

=item * find()

Returns an array of all known Microformats in the document.

=cut

sub find {
	my $c = shift;
	my $criteria = shift || {};
	$c->criteria($criteria);
	$c->pre_find_formats;
	$c->find_formats;
	$c->post_find_formats;
    return @{$c->formats};
}

sub plugin_opts {
    my $c = shift;
    my ($package) = caller;
    $package =~ s/^Text\::Microformat\::Plugin\:://;
    return $c->opts->{$package};
}

sub defaults {
    my $c = shift;
    $c->opts->{content_type} ||= 'text/html';
    $c->opts->{$_} ||= {} for  map({s/^Text\::Microformat\::Plugin\:://; $_} __PACKAGE__->plugins);
    $c->opts->{'Parser::HTML'}{empty_element_tags} = 1 
        unless defined $c->opts->{'Parser::HTML'}{empty_element_tags};
    $c->NEXT::defaults(@_);
}

sub parse {
    my $c = shift;
    $c->NEXT::parse(@_);
}

sub pre_parse {
    my $c = shift;
    $c->NEXT::pre_parse(@_);
}

sub post_parse {
    my $c = shift;
    $c->NEXT::post_parse(@_);
}

sub find_formats {
    my $c = shift;
    my $format_re;
    
    my $formats = $c->criteria->{formats} || $c->criteria->{format};
    if (defined $formats) {
        if (ref $formats eq 'Regex') {
            $format_re = $formats;
        }
        elsif (ref $formats eq 'ARRAY' or !ref $formats) {
            $format_re = join '|', (ref $formats eq 'ARRAY' ? @$formats : $formats);
            $format_re = qr/^(?:$format_re)$/mis;
        }
        print "$format_re\n";
    }
    
	foreach my $format ($c->known_formats) {
	    (my $short_name = $format) =~ s/Text\::Microformat\::Element\:://;
	    next if defined $format_re and $short_name !~ $format_re;
		next unless $format->_params->{criteria};
		push @{$c->formats}, $format->Find($c->tree);
	}
	
    $c->NEXT::find_formats(@_);
}

sub pre_find_formats {
    my $c = shift;
    $c->NEXT::pre_find_formats(@_);
}

sub post_find_formats {
    my $c = shift;
    $c->NEXT::post_find_formats(@_);
}

sub class_regex {
	my $c = shift;
	my $classes = join '|', @_;
	return qr/(?:\A|\s)(?:$classes)(?:\s|\z)/mis;
}

# make a regex that matches one or more tagnames (for look_down)
# right now it makes a regex that ignores namespaces,
# and just matches the local name of the tag.
# might want to make this behavior alterable via an option later.
sub tag_regex {
	my $c = shift;
	my $names = join '|', @_;
	return qr/^(?:\w[\w\.-]*:)?(?:$names)$/mis;
}

# Returns a closure that is a default filter for the
# Find() method (I.e. it is passed to $context_element->look_down).
# Currently it just ensures that the returned elements:
#  - are not $context_element
#  - are not child elements of elements which matched previously
#
# XXX TODO - Will using a closure here cause memory leaks?

sub element_filter {
    my $c = shift;
    my $context_element = shift;
    my @found;
    return sub {
		my $e = $_[0];
		if ($e eq $context_element or grep $e->is_inside($_), @found) {
			return 0;
		}
		push @found, $e;
		return 1;
	};
}

=item * delete()

Deletes the underlying parse tree - which is required by L<HTML::TreeBuilder> to free up memory.  Behavior of Text::Microformat::Element::* objects is undefined after this method is called.

=cut

sub delete {
	my $c = shift;
	$c->tree->delete if $c->tree;
}

=back

=head1 EXTENDING Text::Microformat

=head2 CREATING A NEW FORMAT

This is as easy as creating a new module in the Text::Microformat::Element::*
namespace, having Text::Microformat::Element as a super-class. It will be
auto-loaded by Text::Microformat.

Every Microformat element has it's own namespace auto-generated, for example:

 Text::Microformat::Element::hCard::n::family_name

So it's easy to override the default behavior of Text::Microformat::Element
via inheritance.

See existing formats for hints.

=head2 CREATING A PLUGIN

This is as easy as creating a new module in the Text::Microformat::Plugin::*
namespace. It will be auto-loaded by Text::Microformat. Text::Microformat has
several processing phases, and uses L<NEXT> to traverse the plugin chain.

Current processing phases are, in order of execution:

=over 4

=item * defaults

Set default options in $c->opts

=item * pre_parse

Pre-parsing activities (Operations on the document source, perhaps)

=item * parse

Parsing - at least one plugin must parse $c->content into $c->tree

=item * post_parse

Post-parsing activities (E.g. the include pattern happens here)

=item * pre_find_formats

Before looking for Microformats

=item * find_formats

Populate the $c->formats array with Text::Microformat::Element objects

=item * post_find_formats

After looking for Microformats

=back

A plugin may add handlers to one or more phases.  

See existing plugins for hints.

=head1 TODO

=over 4

=item * Documentation!

=item * Add more formats

=item * Add filtering options to the find() method

=item * Parsing and format-finding performance could definitely be improved

=back

=head1 SEE ALSO

L<HTML::TreeBuilder>, L<XML::TreeBuilder>, L<http://microformats.org>

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

=head1 BUGS

Log bugs and feature requests here: L<http://code.google.com/p/ufperl/issues/list>

=head1 SUPPORT

Project homepage: L<http://code.google.com/p/ufperl/>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::Microformat
