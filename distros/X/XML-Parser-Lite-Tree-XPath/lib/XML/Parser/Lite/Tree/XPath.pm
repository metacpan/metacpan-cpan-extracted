package XML::Parser::Lite::Tree::XPath;

use strict;
use XML::Parser::Lite::Tree::XPath::Tokener;
use XML::Parser::Lite::Tree::XPath::Tree;
use XML::Parser::Lite::Tree::XPath::Eval;

our $VERSION = '0.24';

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	$self->{tree} = shift;
	$self->{error} = 0;

	return $self;
}

sub query {
	my ($self, $xpath) = @_;

	#
	# toke the xpath
	#

	my $tokener = XML::Parser::Lite::Tree::XPath::Tokener->new();

	unless ($tokener->parse($xpath)){
		$self->{error} = $tokener->{error};
		return 0;
	}


	#
	# tree the xpath
	#

	my $xtree = XML::Parser::Lite::Tree::XPath::Tree->new();

	unless ($xtree->build_tree($tokener->{tokens})){
		$self->{error} = $xtree->{error};
		return 0;
	}


	#
	# eval
	#

	my $eval = XML::Parser::Lite::Tree::XPath::Eval->new();

	my $out = $eval->query($xtree, $self->{tree});

	$self->{error} = $eval->{error};

	return $out;
}

sub select_nodes {
	my ($self, $xpath) = @_;

	my $out = $self->query($xpath);

	return 0 unless $out;

	if ($out->{type} ne 'nodeset'){
                $self->{error} = "Result was not a nodeset (was a $out->{type})";
                return 0;
        }

        return $out->{value};
}

1;

__END__

=head1 NAME

XML::Parser::Lite::Tree::XPath - XPath access to XML::Parser::Lite::Tree structures

=head1 SYNOPSIS

  use XML::Parser::Lite::Tree;
  use XML::Parser::Lite::Tree::XPath;

  my $parser = new XML::Parser::Lite::Tree(process_ns => 1);
  my $tree = $parser->parse($xml);

  my $xpath = new XML::Parser::Lite::Tree::XPath($tree);
  my $nodes = $xpath->select_nodes('/aaa');

  my $nodes = $xpath->select_nodes('/*/*/parent::*');
  my $nodes = $xpath->select_nodes('//ccc[ position() = floor(last() div 2 + 0.5) or position() = ceiling(last() div 2 + 0.5) ]');


=head1 DESCRIPTION

This pure-Perl implementation of XPath is a complement to XML::Parser::Lite::Tree, a pure-Perl 
XML tree parser and builder. It aims to implement 100% of the W3C XPath specification.

=head1 METHODS

=over

=item C<new( $tree )>

The constructor returns a new XPath parser for the given tree.

=item C<query( $path )>

Returns a XML::Parser::Lite::Tree::XPath::Result object containing the result of the query.

=item C<select_nodes( $path )>

A convinience function around C<query()> which returns 0 unless the result is a nodeset, else returns the value of the nodeset.

=back

=head1 AUTHORS

Copyright (C) 2004-2008, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<XML::Parser::Lite::Tree>

=cut
