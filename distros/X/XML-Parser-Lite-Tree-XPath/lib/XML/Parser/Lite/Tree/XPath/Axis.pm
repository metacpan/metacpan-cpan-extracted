package XML::Parser::Lite::Tree::XPath::Axis;

use strict;
use XML::Parser::Lite::Tree::XPath::Result;

use vars qw( $axis );

sub instance {
	return $axis if $axis;
	$axis = __PACKAGE__->new;
}

sub new {
	return bless {}, $_[0];
}

sub filter {
	my ($self, $token, $context) = @_;

	$self->{token} = $token;
	$self->{axis} = defined($token->{axis}) ? $token->{axis} : 'child';

	return $self->_axis_child($context)		if $self->{axis} eq 'child';
	return $self->_axis_descendant($context, 0)	if $self->{axis} eq 'descendant';
	return $self->_axis_descendant($context, 1)	if $self->{axis} eq 'descendant-or-self';
	return $self->_axis_parent($context)		if $self->{axis} eq 'parent';
	return $self->_axis_ancestor($context, 0)	if $self->{axis} eq 'ancestor';
	return $self->_axis_ancestor($context, 1)	if $self->{axis} eq 'ancestor-or-self';
	return $self->_axis_following_sibling($context)	if $self->{axis} eq 'following-sibling';
	return $self->_axis_preceding_sibling($context)	if $self->{axis} eq 'preceding-sibling';
	return $self->_axis_following($context)		if $self->{axis} eq 'following';
	return $self->_axis_preceding($context)		if $self->{axis} eq 'preceding';
	return $self->_axis_attribute($context)		if $self->{axis} eq 'attribute';

	return $context if $self->{axis} eq 'self';

	return $self->ret('Error', "Unknown axis '$self->{axis}'");
}

sub ret {
	my ($self, $type, $value) = @_;
	return  XML::Parser::Lite::Tree::XPath::Result->new($type, $value);
}

sub _axis_child {
	my ($self, $in) = @_;

	my $out = $self->ret('nodeset', []);

	for my $tag(@{$in->{value}}){
		for my $child(@{$tag->{children}}){
			push @{$out->{value}}, $child;
		}
	}

	return $out;
}

sub _axis_descendant {
	my ($self, $in, $me) = @_;

	my $out = $self->ret('nodeset', []);

	for my $tag(@{$in->{value}}){

		map{
			push @{$out->{value}}, $_;

		}$self->_axis_descendant_single($tag, $me);
	}

	return $out;
}

sub _axis_descendant_single {
	my ($self, $tag, $me) = @_;

	my @out;

	push @out, $tag if $me;

	for my $child(@{$tag->{children}}){

		if ($child->{type} eq 'element'){

			map{
				push @out, $_;
			}$self->_axis_descendant_single($child, 1);
		}
	}

	return @out;
}

sub _axis_attribute {
	my ($self, $input) = @_;

	my $out = $self->ret('nodeset', []);
	my $nodes = [];

	if ($input->{type} eq 'nodeset'){
		$nodes = $input->{value};
	}

	if ($input->{type} eq 'node'){
		$nodes = [$input->{value}];
	}

	return $self->ret('Error', "attribute axis can only filter nodes and nodesets (not a $input->{type})") unless defined $nodes;

	my $i = 0;

	for my $node(@{$nodes}){
		for my $key(keys %{$node->{attributes}}){
			push @{$out->{value}}, {
				'name'	=> $key,
				'value'	=> $node->{attributes}->{$key},
				'type'	=> 'attribute',
				'order'	=> ($node->{order} * 10000000) + $i++,
			};
		}
	}

	return $out;
}

sub _axis_parent {
	my ($self, $in) = @_;

	my $out = $self->ret('nodeset', []);

	for my $tag(@{$in->{value}}){
		push @{$out->{value}}, $tag->{parent} if defined $tag->{parent};
	}

	return $out;
}

sub _axis_ancestor {
	my ($self, $in, $me) = @_;

	my $out = $self->ret('nodeset', []);

	for my $tag(@{$in->{value}}){

		map{
			push @{$out->{value}}, $_;

		}$self->_axis_ancestor_single($tag, $me);
	}

	return $out;
}

sub _axis_ancestor_single {
	my ($self, $tag, $me) = @_;

	my @out;

	push @out, $tag if $me;

	if (defined $tag->{parent}){

		map{
			push @out, $_;
		}$self->_axis_ancestor_single($tag->{parent}, 1);
	}

	return @out;	
}

sub _axis_following_sibling {
	my ($self, $in) = @_;

	my $out = $self->ret('nodeset', []);

	for my $tag(@{$in->{value}}){
		if (defined $tag->{parent}){
			my $parent = $tag->{parent};
			my $found = 0;
			for my $child(@{$parent->{children}}){
				push @{$out->{value}}, $child if $found;
				$found = 1 if $child->{order} == $tag->{order};
			}
		}
	}

	return $out;
}

sub _axis_preceding_sibling {
	my ($self, $in) = @_;

	my $out = $self->ret('nodeset', []);

	for my $tag(@{$in->{value}}){
		if (defined $tag->{parent}){
			my $parent = $tag->{parent};
			my $found = 0;
			for my $child(@{$parent->{children}}){
				$found = 1 if $child->{order} == $tag->{order};
				push @{$out->{value}}, $child unless $found;
			}
		}
	}

	return $out;
}

sub _axis_following {
	my ($self, $in) = @_;

	my $min_order  = 1 + $self->{token}->{max_order};
	for my $tag(@{$in->{value}}){
		$min_order = $tag->{order} if $tag->{order} < $min_order;
	}

	# recurse the whole tree, adding after we find $min_order (but don't descend into it!)

	my @tags = $self->_axis_following_recurse( $self->{token}->{root}->{value}->[0], $min_order );

	return $self->ret('nodeset', \@tags);
}

sub _axis_following_recurse {
	my ($self, $tag, $min) = @_;

	my @out;

	push @out, $tag if $tag->{order} > $min;

	for my $child(@{$tag->{children}}){

		if (($child->{order}) != $min && ($child->{type} eq 'element')){

			map{
				push @out, $_;
			}$self->_axis_following_recurse($child, $min);
		}
	}

	return @out;
}

sub _axis_preceding {
	my ($self, $in) = @_;

	my $max_order = -1;
	my $parents;
	for my $tag(@{$in->{value}}){
		if ($tag->{order} > $max_order){
			$max_order = $tag->{order};
			$parents = $self->_get_parent_orders($tag);
		}
	}

	# recurse the whole tree, adding until we find $max_order (but don't descend into it!)

	my @tags = $self->_axis_preceding_recurse( $self->{token}->{root}->{value}->[0], $parents, $max_order );

	return $self->ret('nodeset', \@tags);
}

sub _axis_preceding_recurse {
	my ($self, $tag, $parents, $max) = @_;

	my @out;

	push @out, $tag if $tag->{order} < $max && !$parents->{$tag->{order}};

	for my $child(@{$tag->{children}}){

		if (($child->{order}) != $max && ($child->{type} eq 'element')){

			map{
				push @out, $_;
			}$self->_axis_preceding_recurse($child, $parents, $max);
		}
	}

	return @out;
}

sub _get_parent_orders {
	my ($self, $tag) = @_;
	my $parents;

	while(defined $tag->{parent}){
		$tag = $tag->{parent};
		$parents->{$tag->{order}} = 1;
	}

	return $parents;
}

1;
