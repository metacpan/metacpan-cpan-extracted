#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Comment;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"article_id" => new WWW::Shopify::Field::Relation::Parent("WWW::Shopify::Model::Article"),
	"blog_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Blog"),
	"body" => new WWW::Shopify::Field::Text(),
	"body_html" => new WWW::Shopify::Field::Text::HTML(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"email" => new WWW::Shopify::Field::String::Email(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"ip" => new WWW::Shopify::Field::String::IPAddress(),
	"published_at" => new WWW::Shopify::Field::Date(),
	"status" => new WWW::Shopify::Field::String::Enum([qw(removed unapproved published spam)]),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"user_agent" => new WWW::Shopify::Field::String(),
	"author" => new WWW::Shopify::Field::String()

}; }

my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	article_id => new WWW::Shopify::Query::Match('article_id'),
	blog_id => new WWW::Shopify::Query::Match('blog_id'),
	since_id => new WWW::Shopify::Query::LowerBound('id'),
	published_status => new WWW::Shopify::Query::Enum("published_status", [{ "published" => { status => "published" } }, { "unpublished" => { status => {"!=" => "published"} } }, { "any" => { } }]),
	status => new WWW::Shopify::Query::Match('status'),
	created_at_min => new WWW::Shopify::Query::LowerBound('created_at'),
	created_at_max => new WWW::Shopify::Query::UpperBound('created_at'),
	updated_at_min => new WWW::Shopify::Query::LowerBound('updated_at'),
	updated_at_max => new WWW::Shopify::Query::UpperBound('updated_at'),
	published_at_min => new WWW::Shopify::Query::LowerBound('published_at'),
	published_at_max => new WWW::Shopify::Query::UpperBound('published_at'),
}; }

sub updatable { return undef; }
sub deletable { return undef; }
sub parent { return "WWW::Shopify::Model::Article" }
sub actions { return qw(remove approve not_spam spam); }
sub create_minimal { return qw(body author email ip blog_id article_id); }
sub create_filled { return qw(body_html created_at id published_at status updated_at user_agent); }

sub read_scope { return "read_content"; }
sub write_scope { return "write_content"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
