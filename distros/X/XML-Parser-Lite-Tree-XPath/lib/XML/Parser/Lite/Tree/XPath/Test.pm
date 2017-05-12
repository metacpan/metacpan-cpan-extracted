package XML::Parser::Lite::Tree::XPath::Test;

use strict;
use vars qw(@ISA @EXPORT);
use Test::More;

use XML::Parser::Lite::Tree;
use XML::Parser::Lite::Tree::XPath;
use Data::Dumper;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
	set_xml
	test_tree
	test_nodeset
	test_number
	test_string
	test_error
	test_boolean
);

our $xpath;

sub set_xml {
	my ($xml) = @_;

	$xml =~ s/>\s+</></sg;
	$xml =~ s/^\s*(.*?)\s*$/$1/;

	my $parser = new XML::Parser::Lite::Tree(process_ns => 1);
	my $tree = $parser->parse($xml);
	$xpath = new XML::Parser::Lite::Tree::XPath($tree);
}

sub test_tree {
	my ($path, $dump) = @_;

	my $tokener = XML::Parser::Lite::Tree::XPath::Tokener->new();
	if (!$tokener->parse($path)){
		print "Path: $path\n";
		print "Failed toke: ($tokener->{error})\n";
		ok(0);
		return;
	}

	my $tree = XML::Parser::Lite::Tree::XPath::Tree->new();
	if (!$tree->build_tree($tokener->{tokens})){
		print "Path: $path\n";
		print "Failed tree: ($tree->{error})\n";
		#print Dumper $tree;
		ok(0);
		return;
	}

	my $dump_got = $tree->dump_flat();

	ok($dump_got eq $dump);

	unless ($dump_got eq $dump){
		print "Path:     $path\n";
		print "Expected: $dump\n";
		print "Dump:     $dump_got\n";
		print $tree->dump_tree();
	}

	return $dump_got;
}

sub test_nodeset {
	my ($path, $expected) = @_;

	my $nodes = $xpath->select_nodes($path);

	unless ('ARRAY' eq ref $nodes){

		print "Error: $xpath->{error}\n";

		ok(0);
		ok(0) for @{$expected};
		return;
	}

	my $bad = 0;

	my $ok = scalar(@{$nodes}) == scalar(@{$expected});
	$bad++ unless $ok;
	ok($ok);

	if (!$ok){
		print "# wrong node count. got ".scalar(@{$nodes}).", expected ".scalar(@{$expected})."\n";
	}


	my $i = 0;
	for my $xnode(@{$expected}){

		# $xnode is a hash ref which should match stuff in $nodes[$i]

		for my $key(keys %{$xnode}){

			if ($key eq 'nodename'){

				$ok = $nodes->[$i]->{name} eq $xnode->{$key};

				print "# node name - expected: $xnode->{$key}, got: $nodes->[$i]->{name}\n" unless $ok;

			}elsif ($key eq 'attributecount'){

				$ok = scalar(keys %{$nodes->[$i]->{attributes}}) == $xnode->{$key};

				print "# attribute count - expected: $xnode->{$key}, got: ".scalar(keys %{$nodes->[$i]->{attributes}})."\n" unless $ok;

			}elsif ($key eq 'type'){

				$ok = $nodes->[$i]->{type} eq $xnode->{$key};

				print "# node type - expected: $xnode->{$key}, got: $nodes->[$i]->{type}\n" unless $ok;

			}elsif ($key eq 'value'){

				$ok = $nodes->[$i]->{value} eq $xnode->{$key};

				print "# value - expected: $xnode->{$key}, got: $nodes->[$i]->{value}\n" unless $ok;

			}else{
				$ok = $nodes->[$i]->{attributes}->{$key} eq $xnode->{$key};

				print "# attribute $key - expected: $xnode->{$key}, got: $nodes->[$i]->{attributes}->{$key}\n" unless $ok;
			}

			$bad++ unless $ok;
			ok($ok);
		}

		$i++;
	}

	if ($bad){
		print "# codes don't match. got:\n";
		for my $node(@{$nodes}){
			print "# \t";
			print "($node->{type} : $node->{order}) ";
			print "$node->{name}";
			for my $key(keys %{$node->{attributes}}){
				print ", $key=$node->{attributes}->{$key}";
			}
			print "\n";
		}
		print "# expected:\n";
		my $i = 1;
		for my $node(@{$expected}){
			print "# \t$i";
			for my $key(keys %{$node}){
				print ", $key={$node->{$key}}";
			}
			print "\n";
			$i++;
		}
		print Dumper $nodes;
	}
}

sub test_number {
	my ($path, $expected) = @_;

	my $ret = $xpath->query($path);

	if (!$ret){
		print "Error: $xpath->{error}\n";
		ok(0);
		ok(0);
		return;
	}

	ok($ret->{type} eq 'number');

	if ($ret->{type} eq 'number'){
		ok($ret->{value} == $expected);

		if ($ret->{value} != $expected){
			print "expected $expected, got $ret->{value}\n";
		}
	}else{
		print "got a $ret->{type} result\n";
		ok(0);
	}
}

sub test_string {
	my ($path, $expected) = @_;

	my $ret = $xpath->query($path);

	if (!$ret){
		print "Error: $xpath->{error}\n";
		ok(0);
		ok(0);
		return;
	}

	ok($ret->{type} eq 'string');

	if ($ret->{type} eq 'string'){
		ok($ret->{value} eq $expected);

		if ($ret->{value} ne $expected){
			print "# expected $expected, got $ret->{value}\n";
		}
	}else{
		print "# got a $ret->{type} result\n";
		ok(0);
	}
}

sub test_error {
	my ($path, $expected) = @_;

	my $ret = $xpath->query($path);

	if ($ret){
		print "# no error - but we expected one!\n";
		ok(0);
	}else{
		if ($xpath->{error} =~ $expected){

			ok(1);
		}else{
			print "# wrong error\n";
			print "#     expected: $expected\n";
			print "#          got: $xpath->{error}\n";
			ok(0);
		}
	}
}

sub test_boolean {
	my ($path, $expected) = @_;

	my $ret = $xpath->query($path);

	if (!$ret){
		print "Error: $xpath->{error}\n";
		ok(0);
		ok(0);
		return;
	}

	ok($ret->{type} eq 'boolean');

	if ($ret->{type} eq 'boolean'){
		my $ok = 0;
		$ok = 1 if $expected && $ret->{value};
		$ok = 1 if !$expected && !$ret->{value};

		ok($ok);

		unless ($ok){
			print "# expected $expected, got $ret->{value}\n";
		}
	}else{
		print "# got a $ret->{type} result\n";
		ok(0);
	}
}

1;
