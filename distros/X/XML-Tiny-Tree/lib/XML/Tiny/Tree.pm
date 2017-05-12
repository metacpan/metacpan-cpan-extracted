package XML::Tiny::Tree;

use strict;
use warnings;

use Moo;

use Tree;

use Types::Standard qw/Int Str/;

use XML::Tiny;

has fatal_declarations =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);


has input_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has no_entity_parsing =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has strict_entity_parsing =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

our $VERSION = '1.00';

# ------------------------------------------------

sub convert
{
	my($self, %arg)            = @_;
	my($fatal_declarations)    = $arg{fatal_declarations}    || $self -> fatal_declarations;
	my($input_file)            = $arg{input_file}            || $self -> input_file;
	my($no_entity_parsing)     = $arg{no_entity_parsing}     || $self -> no_entity_parsing;
	my($strict_entity_parsing) = $arg{strict_entity_parsing} || $self -> strict_entity_parsing;

	die "Input file not specified\n" if (! defined $input_file);

	open(my $fh, '<', $input_file);

	my $xml = XML::Tiny::parsefile
	(
		$fh,
		fatal_declarations    => $fatal_declarations,
		no_entity_parsing     => $no_entity_parsing,
		strict_entity_parsing => $strict_entity_parsing,
	);

	close $fh;

	return $self -> _reformat($xml, undef, []);

} # End of convert.

# ------------------------------------------------

sub _reformat
{
	my($self, $ara_ref, $tree, $stack) = @_;

	my($name, $node);

	for my $hash_ref (@$ara_ref)
	{
		$name = $$hash_ref{name};

		# This assumes that a named node is created before its content,
		# so that by the time we get here, $node -> meta() has been called.

		if (! defined $name)
		{
			my($content) = $$hash_ref{content};

			if (defined $content)
			{
				my($meta) = $$stack[$#$stack] -> meta;
				$meta     = {%$meta, content => $content};

				$$stack[$#$stack] -> meta($meta);
			}

			next;
		}

		$node = Tree -> new($name);

		# Init $tree now that we need it.

		if (! defined $tree)
		{
			$tree = $node;

			push @$stack, $node;
		}

		$node -> meta({attributes => $$hash_ref{attrib}, content => ''});
		$$stack[$#$stack] -> add_child($node);

		push @$stack, $node;

		$self -> _reformat($$hash_ref{content}, $tree, $stack);

		pop @$stack;
	}

	return $tree;

} # End of _reformat.

# -----------------------------------------------

1;

=pod

=head1 NAME

XML::Tiny::Tree -  Convert XML::Tiny output into a Tree

=head1 Synopsis

This is scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use XML::Tiny::Tree;

	# ------------------------------------------------

	my($input_file) = shift || die "Usage $0 file. Try using data/test.xml as the input. \n";
	my($tree)       = XML::Tiny::Tree -> new
						(
							input_file        => $input_file,
							no_entity_parsing => 1,
						) -> convert;

	print "Input file: $input_file. \n";
	print "The whole tree: \n";
	print map("$_\n", @{$tree -> tree2string});
	print '-' x 50, "\n";
	print "Bits and pieces from the first child (tag_4) of the second child (tag_3) of the root (tag_1): \n";

	my(@children) = $tree -> children;
	@children     = $children[1] -> children;
	my($tag)      = $children[0] -> value;
	my($meta)     = $children[0] -> meta;
	my($attr)     = $$meta{attributes};

	print "tag:        $tag. \n";
	print "content:    $$meta{content}. \n";
	print 'attributes: ', join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr), ". \n";

=head1 Description

L<XML::Tiny::Tree> reads a file via L<XML::Tiny>, and reformats the output into a tree managed
by L<Tree>.

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = XML::Tiny::Tree -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<XML::Tiny::Tree>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</input_file([$string])>]):

=over 4

=item o fatal_declarations => $Boolean

Specify whether or not to get L<XML::Tiny> to error if such declarations are found.

Default: 0.

This key is optional.

=item o input_file => $string

Specify the name of the XML file to process.

Default: ''.

This key is mandatory.

=item o no_entity_parsing => $Boolean

Specify whether or not to get L<XML::Tiny> to do entity parsing.

Default: 0.

This key is optional.

=item o strict_entity_parsing => $Boolean

If set to true, any unrecognised entities (ie, those outside the core five plus numeric entities)
cause a fatal error.

Default: 0.

This key is optional.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installing the module

Install L<XML::Tiny::Tree> as you would for any C<Perl> module:

Run:

	cpanm XML::Tiny::Tree

or run:

	sudo cpan XML::Tiny::Tree

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake)
	make test
	make install

=head1 Methods

=head2 convert([%arg])

Here, the [] indicate an optional parameter.

Triggers reading the XML file and conversion of the output of L<XML::Tiny> into a L<Tree>.

Returns an object of type L<Tree>.

C<convert()> takes the same parameters as L</new([%arg])>.
See L</Constructor and Initialization> for details.

=head2 fatal_declarations([$Boolean])

Here, the [] indicate an optional parameter.

Gets or sets the value of the option to pass to L<XML::Tiny>.

C<fatal_declarations> is a parameter to L<new([%arg])>.

=head2 input_file([$string])

Here, the [] indicate an optional parameter.

Gets or sets the name of the input file to pass to L<XML::Tiny>'s method C<parsefile()>.

C<input_file> is a parameter to L<new([%arg])>.

=head2 new([%arg])

See L</Constructor and Initialization> for details.

=head2 no_entity_parsing([$Boolean])

Here, the [] indicate an optional parameter.

Gets or sets the value of the option to pass to L<XML::Tiny>.

C<no_entity_parsing> is a parameter to L<new([%arg])>.

=head2 strict_entity_parsing([$Boolean])

Here, the [] indicate an optional parameter.

Gets or sets the value of the option to pass to L<XML::Tiny>.

C<strict_entity_parsing> is a parameter to L<new([%arg])>.

=head1 FAQ

=head2 How to I access the names of the XML tags?

Each node in the tree is an object of type L<Tree>, and has a method called C<value()>. This method
returns a string which is the name of the tag.

See the L</Synopsis> for sample code.

=head2 How do I access the attributes of each XML tag?

Each node in the tree is an object of type L<Tree>, and has a method called C<meta()>. This method
returns a hashref containing 2 keys:

=over 4

=item o attributes => $hashref

=item o content => $string

=back

If the tag has no attributes, then $hashref is {}.

If the tag has no content, then $string is ''.

See the L</Synopsis> for sample code.

=head2 How do I access the content of each XML tag?

See the answer to the previous question.

See the L</Synopsis> for sample code.

=head2 Is it possible for a tag to have both content and sub-tags?

Yes. See data/test.xml in the distro for such a case.

=head1 See Also

L<XML::Tiny>.

L<XML::Tiny::DOM>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/XML-Tiny-Tree>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Tiny-Tree>.

=head1 Author

L<XML::Tiny::Tree> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut

