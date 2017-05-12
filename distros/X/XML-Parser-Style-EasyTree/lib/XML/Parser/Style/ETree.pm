package XML::Parser::Style::ETree;

use 5.006002;
use strict;
use warnings;
use Scalar::Util ();

=head1 NAME

XML::Parser::Style::ETree - Parse xml to simple tree

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

	use XML::Parser;
	my $p = XML::Parser->new( Style => 'ETree' );

=head1 EXAMPLE

	<root at="key">
		<nest>
			first
			<v>a</v>
			mid
			<v at="a">b</v>
			<vv></vv>
			last
		</nest>
	</root>

will be

	{
		root => {
			'-at' => 'key',
			nest => {
				'#text' => 'firstmidlast',
				vv => '',
				v => [
					'a',
					{
						'-at' => 'a',
						'#text' => 'b'
					}
				]
			}
		}
	}

=head1 SPECIAL VARIABLES

=over 4

=item $TEXT{ATTR} [ = '-' ]

Allow to set prefix for name of attribute nodes;

	<item attr="value" />
	# will be
	item => { -attr => 'value' };

	# with
	$TEXT{ATTR} = '+';
	# will be
	item => { '+attr' => 'value' };
	
=item $TEXT{NODE} [ = '#text' ]

Allow to set name for text nodes

	<item><sub attr="t"></sub>Text value</item>
	# will be
	item => { sub => { -attr => "t" }, #text => 'Text value' };

	# with
	$TEXT{NODE} = '';
	# will be
	item => { sub => { -attr => "t" }, '' => 'Text value' };

=item $TEXT{JOIN} [ = '' ]

Allow to set join separator for text node, splitted by subnodes

	<item>Test1<sub />Test2</item>
	# will be
	item => { sub => '', #text => 'Test1Test2' };

	# with
	$TEXT{JOIN} = '+';
	# will be
	item => { sub => '', #text => 'Test1+Test2' };

=item $TEXT{TRIM} [ = 1 ]

Trim leading and trailing whitespace from text nodes

	<item>  Test1  <sub />  Test2  </item>
	# will be
	item => { sub => '', #text => 'Test1Test2' };

	# with
	$TEXT{TRIM} = 0;
	# will be
	item => { sub => '', #text => '  Test1    Test2  ' };

=item %FORCE_ARRAY

Allow to force nodes to be represented always as arrays. If name is empty string, then ot means ALL

	<item><sub attr="t"></sub>Text value</item>

	# will be
	item => { sub => { -attr => "t" }, #text => 'Text value' };

	# with
	$FORCE_ARRAY{sub} = 1;
	# will be
	item => { sub => [ { -attr => "t" } ], #text => 'Text value' };

	# with
	$FORCE_ARRAY{''} = 1;
	# will be
	item => [ { sub => [ { -attr => "t" } ], #text => 'Text value' } ];

=item %FORCE_HASH

Allow to force text-only nodes to be represented always as hashes. If name is empty string, then ot means ALL

	<item><sub>Text value</sub><any>Text value</any></item>

	# will be
	item => { sub => 'Text value', any => 'Text value' };

	# with
	$FORCE_HASH{sub} = 1;
	# will be
	item => { sub => { #text => 'Text value' }, any => 'Text value' };

	# with
	$FORCE_HASH{''} = 1;
	# will be
	item => { sub => { #text => 'Text value' }, any => { #text => 'Text value' } };

=item @STRIP_KEY

Allow to strip something from tag names by regular expressions

	<a:item><b:sub>Text value</b:sub></a:item>

	# will be
	'a:item' => { 'b:sub' => 'Text value' };

	# with
	@STRIP_KEY = (qr/^[^:]+:/);
	# will be
	'item' => { 'sub' => 'Text value' };

=back

=cut

sub DEBUG () { 0 };

our %TEXT = (
	ATTR => '-',
	NODE => '#text',
	JOIN => '',
	TRIM => 1,
);

our @STRIP_KEY;

# '' means all since this can't be a name of tag

our %FORCE_ARRAY = ( '' => 0 );
our %FORCE_HASH = ( '' => 0 );


sub Init {
	my $xp = shift;
	my $t = $xp->{FunTree} ||= {};
	$t->{stack} = [];
	$t->{tree} = {};
	$t->{context} = { tree => {}, text => [] };
	$t->{opentag} = undef;
	$t->{depth} = 0 if DEBUG;
	return;
}

sub Start {
	my $xp = shift;
	my $t = $xp->{FunTree};
	
	#if ($enc) { @_ = @_; $_ = $enc->encode($_) for @_ };
	my $tag = shift;
	$tag =~ s{$_}{} for @STRIP_KEY;
	warn "++"x(++$t->{depth}) . $tag if DEBUG;
				
	my $node = {
		name  => $tag,
		tree  => undef,
		text  => [],
		textflag => 0,
	};
	Scalar::Util::weaken($node->{parent} = $t->{context});
	if (@_) {
		my %attr;
		while (my ($k,$v) = splice @_,0,2) {
			$attr{ $TEXT{ATTR}.$k } = $v;
		}
		#$flat[$#flat]{attributes} = \%attr;
		$node->{attrs} = \%attr;
		#warn "Need something to do with attrs on $tag\n";
	};
	$t->{opentag} = 1;
	{
		if (@{ $t->{context}{text} }) {
			${ $t->{context}{text} }[ $#{ $t->{context}{text} } ] =~ s{[\t\s\r\n]+$}{}s if $TEXT{TRIM};
			# warn "cleaning trailing whitespace on $#{ $t->{context}{text} } :  ${ $t->{context}{text} }[ $#{ $t->{context}{text} } ]";
			pop (@{ $t->{context}{text} }),redo unless length ${ $t->{context}{text} }[ $#{ $t->{context}{text} } ];
		}
	}
	#push @{ $t->{context}{text} }, $TEXT{JOIN} if $t->{context}{textflag} and length $TEXT{JOIN};
	$t->{context}{textflag} = 0;
	
	push @{ $t->{stack} }, $t->{context} = $node;
}

sub End  {
	my $xp = shift;
	my $t = $xp->{FunTree};
	
	#if ($enc) { @_ = @_; $_ = $enc->encode($_) for @_ };
	my $name = shift;
	$name =~ s{$_}{} for @STRIP_KEY;
	
	#my $node = pop @stack;
	my $text = $t->{context}{text};
	$t->{opentag} = 0;
	
	my $tree = $t->{context}{tree};

	my $haschild = scalar keys %$tree;
	if ( ! $FORCE_ARRAY{''} ) {
		foreach my $key ( keys %$tree ) {
			#warn "$key for $name\n";
			next if $FORCE_ARRAY{$key};
			next if ( 1 < scalar @{ $tree->{$key} } );
			$tree->{$key} = shift @{ $tree->{$key} };
		}
	}
	if ( @$text ) {
		{
			${ $text }[ $#$text ] =~ s{[\t\s\r\n]+$}{}s if $TEXT{TRIM};
			# warn "cleaning trailing whitespace on $#$text :${ $text }[ $#$text ]";
			pop (@$text),redo unless length ${ $text }[ $#$text ];
		}
		#warn "node $name have text '@$text'";
		if ( @$text == 1 ) {
			# one text node (normal)
			$text = shift @$text;
		}
		else {
			# some text node splitted
			$text = join( $TEXT{JOIN}, @$text );
		}
		if ( $haschild ) {
			# some child nodes and also text node
			$tree->{$TEXT{NODE}} = $text;
		}
		else {
			# only text node without child nodes
			$tree = $text;
		}
	}
	elsif ( ! $haschild ) {
		# no child and no text
		$tree = "";
	}
	
	# Move up!
	my $child = $tree;
	#warn "parent for $name = $context->{parent}\n";
	my $elem = $t->{context}{attrs};
	my $hasattr = scalar keys %$elem if ref $elem;
#    my $forcehash = $FORCE_HASH_ALL || ( $t->{context}{parent}{name} && $FORCE_HASH{$t->{context}{parent}{name}} ) || 0;
	my $forcehash = $FORCE_HASH{''} || ( $name && $FORCE_HASH{$name} ) || 0;
	#warn "$t->{context}{parent}{name} => $name forcehash = $forcehash\n";
	$t->{context} = $t->{context}{parent};
	
	#warn "$context->{name} have ".Dumper ($elem);
	if ( ref $child eq "HASH" ) {
		if ( $hasattr ) {
			# some attributes and some child nodes
			%$elem = ( %$elem, %$child );
		}
		else {
			# some child nodes without attributes
			$elem = $child;
		}
	}
	else {
		if ( $hasattr ) {
			# some attributes and text node
			#warn "${name}: some attributes and text node";
			$elem->{$TEXT{NODE}} = $child;
		}
		elsif ( $forcehash ) {
			# only text node without attributes
			$elem = { $TEXT{NODE} => $child };
		}
		else {
			# text node without attributes
			$elem = $child;
		}
	}
	
	warn "--"x($t->{depth}--) . $name if DEBUG;
	push @{ $t->{context}{tree}{$name} ||= [] },$elem;
	$name = $t->{context}{name};
	$tree = $t->{context}{tree} ||= {};
	
	warn "unused args on /$name: @_" if @_;
}

sub Char {
	my $xp = shift;
	my $t = $xp->{FunTree};
	#if ($enc) { @_ = @_; $_ = $enc->encode($_) for @_ };
	my $text = shift;
	unless ($t->{context}{textflag}) {
		$text =~ s{^[\t\s\r\n]+}{}s if $TEXT{TRIM};
	}
	if ( length $text ){
		warn ".."x(1+$t->{depth}) . $text if DEBUG;
		if ($t->{context}{textflag}) {
			${ $t->{context}{text} }[ $#{ $t->{context}{text} } ] .= $text;
		} else {
			push @{ $t->{context}{text} }, $text;
		}
		$t->{context}{textflag} = 1;
	};
}

sub Final {
	my $tree = $_[0]{FunTree}{context}{tree};
	delete $_[0]{FunTree};
	if ( ! $FORCE_ARRAY{''} ) {
		foreach my $key ( keys %$tree ) {
			next if $FORCE_ARRAY{$key};
			next if ( 1 < scalar @{ $tree->{$key} } );
			$tree->{$key} = shift @{ $tree->{$key} };
		}
	}
	return $tree;
}

=head1 SEE ALSO

=over 4

=item * L<XML::Parser>

The parser itself

=item * L<XML::Parser::EasyTree>

Another EasyTree (I didn't found it before my first commit of this package because of missing '::Style' in it's name)

But since L<XML::Parser::EasyTree> and L<XML::Parser::Style::EasyTree> use same style name, they're mutual exclusive ;(

So, all the functionality was moved to ETree, and EasyTree was kept as a compatibility wrapper

=item * L<XML::Bare>

Very-very fast XML parser. Recommend to look

=item * L<XML::Hash::LX>

Similar behaviour, same output, but using L<XML::LibXML>

=back

=head1 AUTHOR

Mons Anderson, <mons at cpan.org>

=head1 BUGS

None known

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
