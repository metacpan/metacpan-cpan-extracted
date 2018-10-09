#!/usr/bin/perl

use strict;
use warnings;

# Analyzes liquid in a non-trivial manner to perform useful calculations.
# Generaly for dependncy analysis.
package WWW::Shopify::Liquid::Analyzer::Entity;
sub new { 
	my ($package, $hash) = @_;
	$hash = {} unless $hash;
	return bless {
		id => undef,
		# Things we include.
		dependencies => [],
		# Things that include us.
		references => [],
		# Flattened lists of dependencies and references.
		full_dependencies => [],
		full_references => [],
		file => undef,
		ast => undef,
		%$hash
	}, $package;
}
sub ast { return $_[0]->{ast}; }
sub id { return $_[0]->{id}; }
sub file { return $_[0]->{file}; }

package WWW::Shopify::Liquid::Analyzer;
sub new { 
	my ($package) = shift;
	my $self = bless {
		@_
	}, $package;
	$self->{liquid} = WWW::Shopify::Liquid->new unless $self->liquid;
	return $self;
}
sub liquid { return $_[0]->{liquid}; }

sub retrieve_includes_ast {
	my ($self, $ast) = @_;
	return () unless $ast;
	return grep { defined $_ && $_->isa('WWW::Shopify::Liquid::Tag::Include') } $ast->tokens;
}

sub expand_entity {
	my ($self, $entity, $type, $used_list) = @_;
	$used_list = { $entity->id => 1 } unless $used_list;
	return map { $used_list->{$_->id} ? () : ($_, $self->expand_entity($_, $type, $used_list)) } @{$entity->{$type}};
}

sub generate_include_entity {
	my ($self, $include) = @_;
	my ($path) = $include->retrieve_include({}, "render", $self->liquid->renderer, $include->include_literal);
	my $entity = $self->generate_entity_file($path);
	return $entity;
	
}

use List::MoreUtils qw(uniq);
sub populate_dependencies {
	my ($self, @entities) = @_;
	my %entity_list = map { $_->id => $_ } @entities;
	# Go through, and flatten out those lists.
	for my $entity (grep { $_->ast } @entities) {
		my @included_literals = $self->retrieve_includes_ast($entity->ast);
		$entity_list{$_->include_literal} = $self->generate_include_entity($_) for (grep { !$entity_list{$_->include_literal} } @included_literals);
		my @included_entities = map { $entity_list{$_->include_literal} } @included_literals;
		push(@{$entity->{dependencies}}, @included_entities);
		push(@{$_->{references}}, $entity) for (@included_entities);
	}
	for (@entities) {
		$_->{full_dependencies} = [$self->expand_entity($_, 'dependencies')];
		$_->{full_references} = [$self->expand_entity($_, 'references')];
	}
	
	return @entities;
}

# If an entity is changed/added, then this should be called on the entity.
sub add_refresh_entity {
	my ($self, $entity, @entities) = @_;
	my %entity_list = map { $_->id => $_ } @entities;
	if (!$entity_list{$entity->id}) {
		my @included_literals = $self->retrieve_includes_ast($entity->ast);
		$entity_list{$_->include_literal} = $self->generate_include_entity($_) for (grep { !$entity_list{$_->include_literal} } @included_literals);
		my @included_entities = map { $entity_list{$_->include_literal} } @included_literals;
		push(@{$entity->{dependencies}}, @included_entities);
		push(@{$_->{references}}, $entity) for (@included_entities);
		$entity->{full_dependencies} = [$self->expand_entity($entity, 'dependencies')];
		$entity->{full_references} = [$self->expand_entity($entity, 'references')];
	}
	return $entity;
}

sub add_refresh_path {
	my ($self, $path, @entities) = @_;
	return $self->add_refresh_entity($self->generate_entity_file($path), @entities);
}

sub generate_entity_file {
	my ($self, $path) = @_;
	return WWW::Shopify::Liquid::Analyzer::Entity->new({
		id => do { my $handle = $path; $handle =~ s/^.*\/([^\/]+?)(\.liquid)?$/$1/; $handle },
		ast => $self->liquid->parse_file($path),
		file => $path
	})
}

sub generate_entities_files {
	my ($self, @paths) = @_;
	return map {
		$self->generate_entity_file($_);
	} @paths;
}

1;