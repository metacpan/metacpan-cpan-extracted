#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::LinkList::Link;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"position" => new WWW::Shopify::Field::Int(),
	"subject" => new WWW::Shopify::Field::String(),
	"subject_id" => new WWW::Shopify::Field::Int(),
	"subject_params" => new WWW::Shopify::Field::String(),
	"title" => new WWW::Shopify::Field::String(),
	"link_list_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::LinkList'),
	"link_type" => new WWW::Shopify::Field::String::Enum(["collection", "product", "frontpage", "catalog", "page", "blog", "search", "http"])
}; }

sub creation_minimal { return qw(title link_type); }
sub creation_filled { return qw(link_list_id); }
sub update_filled { return qw(); }

sub link_model_type {
	return ('WWW::Shopify::Model::CustomCollection', 'WWW::Shopify::Model::SmartCollection') if $_[0]->link_type eq 'collection';
	return 'WWW::Shopify::Model::Product' if $_[0]->link_type eq 'product';
	return 'WWW::Shopify::Model::Page' if $_[0]->link_type eq 'page';
	return 'WWW::Shopify::Model::Blog' if $_[0]->link_type eq 'blog';
	return () if wantarray;
	return undef;
}

sub link_url {
	return '/search' if $_[0]->link_type eq "search";
	return '/' if $_[0]->link_type eq "frontpage";
	return '/collections/all' if $_[0]->link_type eq "catalog";
	return $_[0]->subject if $_[0]->link_type eq "http";
	return '/collections/' . $_[0]->subject if $_[0]->link_type eq 'collection';
	return '/products/' . $_[0]->subject if $_[0]->link_type eq 'product';
	return '/pages/' . $_[0]->subject if $_[0]->link_type eq 'page'; 
	return '/blogs/' . $_[0]->subject if $_[0]->link_type eq 'blogs';
	return undef;
}

sub needs_login { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
