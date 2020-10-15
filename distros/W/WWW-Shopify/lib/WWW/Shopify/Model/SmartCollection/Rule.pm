#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::SmartCollection::Rule;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"column" => new WWW::Shopify::Field::String::Enum(["title", "type", "vendor", "tag", "variant_weight", "variant_title", "variant_compare_at_price", "variant_inventory"]),
	"relation" => new WWW::Shopify::Field::String::Enum(["equals", "greater_than", "less_than", "starts_with", "ends_with", "contains"]),
	"condition" => new WWW::Shopify::Field::String(),
}; }

sub identifier { return ("column", "relation", "condition"); }

use Scalar::Util qw(blessed);
sub product_matches {
	my ($self, $product) = @_;
	die new WWW::Shopify::Exception("Requires a WWW::Shopify::Model::Product.") unless blessed($product) && $product->isa('WWW::Shopify::Model::Product');
	
	my $field = $self->column;
	my $operand = $self->condition;
	my $operator = $self->relation;
	$field = "tags" if $field eq "tag";
	$field = "variant_inventory_quantity" if $field eq "variant_inventory";
	$field = "product_type" if $field eq "type";
	
	my %operators = (
		"equals" => sub { 
			my ($field, $value, $operand, $item) = @_;
			$value = '' unless defined $value;
			if ($field eq "tags") {
				$operand = quotemeta($operand);
				return $value =~ m/(^|, )$operand($|,)/i;
			}
			return $value eq $operand && $item->inventory_management && $item->inventory_management eq "shopify" if $field eq "inventory_quantity";
			return $value eq $operand; 
		},
		"not_equals" => sub { 
			my ($field, $value, $operand, $item) = @_;
			$value = '' unless defined $value;
			if ($field eq "tags") {
				$operand = quotemeta($operand);
				return $value !~ m/(^|,)$operand($|,)/i;
			}
			return $value ne $operand && $item->inventory_management && $item->inventory_management eq "shopify" if $field eq "inventory_quantity";
			return $value ne $operand;
		},
		"less_than" => sub {
			my ($field, $value, $operand, $item) = @_;
			$value = 0 unless defined $value; 
			return $value < $operand && $item->inventory_management && $item->inventory_management eq "shopify" if $field eq "inventory_quantity";
			return $value < $operand;
		},
		"greater_than" => sub { 
			my ($field, $value, $operand, $item) = @_;
			$value = 0 unless defined $value;
			return $value > $operand && $item->inventory_management && $item->inventory_management eq "shopify" if $field eq "inventory_quantity";
			return $value > $operand;
		},
		"starts_with" => sub {  my ($field, $value, $operand) = @_; $value = 0 unless defined $value; return index(lc($value), lc($operand)) == 0; },
		"ends_with" => sub {  my ($field, $value, $operand) = @_; $value = 0 unless defined $value; return index(lc($value), lc($operand)) == length($value) - length($operand); },
		"contains" => sub { my ($field, $value, $operand) = @_;  $value = 0 unless defined $value; return index(lc($value), lc($operand)) != -1; },
		"not_contains" => sub {  my ($field, $value, $operand) = @_; $value = 0 unless defined $value; return index(lc($value), lc($operand)) == -1; }
	);
	if ($field =~ m/^variant_(.*)/) {
		$field = $1;
		return int(grep { $operators{$operator}->($field, $_->$field, $operand, $_) } $product->variants) > 0;
	}
	return $operators{$operator}->($field, $product->$field, $operand, $product);
}

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
