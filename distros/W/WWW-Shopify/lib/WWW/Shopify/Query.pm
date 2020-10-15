#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

Query - Basic Description of Filters on Shopify

=cut

=head1 DESCRIPTION

Queries describe Shopify filters that can be put on get requests. This allows them to be translated into local database queries for testing purposes.

The following queries exist:

=cut

package WWW::Shopify::Query;
sub new { return bless { name => undef }, $_[0]; }
sub name { $_[0]->{name} = $_[1] if defined $_[1]; return $_[0]->{name}; }
sub field_name { $_[0]->{field_name} = $_[1] if defined $_[1]; return $_[0]->{field_name}; }

=head2 WWW::Shopify::Query::LowerBound

Specifies a lower bound on the specified field. An example of this is WWW::Shopify::Model::Product's created_at_min query, which links to the created_at field.

=cut

package WWW::Shopify::Query::LowerBound;
use parent 'WWW::Shopify::Query';
sub new { return bless { 'field_name' => $_[1] }, $_[0]; }

=head2 WWW::Shopify::Query::UpperBound

As above, except an upper bound.

=cut

package WWW::Shopify::Query::UpperBound;
use parent 'WWW::Shopify::Query';
sub new { return bless { 'field_name' => $_[1] }, $_[0]; }

=head2 WWW::Shopify::Query::Enum

A query that states that a field can be equal to one of the specified enumerations.

=cut

package WWW::Shopify::Query::Enum;
use parent 'WWW::Shopify::Query';
sub new { return bless { 'field_name' => $_[1], 'enums' => $_[2] }, $_[0]; }
sub enums { return @{$_[0]->{enums}}; }

=head2 WWW::Shopify::Query::Match

A query that states that the specified field must exactly equal the input, though there is no restriction on what this input might be.

=cut

package WWW::Shopify::Query::Match;
use parent 'WWW::Shopify::Query';
sub new { return bless { 'field_name' => $_[1] }, $_[0]; }



=head2 WWW::Shopify::Query::MultiMatch

A query that states that the specified field must equal any element in the input, though there is no restriction on what this input might be.

=cut

package WWW::Shopify::Query::MultiMatch;
use parent 'WWW::Shopify::Query';
sub new { return bless { 'field_name' => $_[1] }, $_[0]; }

=head2 WWW::Shopify::Query::Custom

A query that takes a sub that details how to handle the query.

=cut


package WWW::Shopify::Query::Custom;
use parent 'WWW::Shopify::Query';
sub new { return bless { 'field_name' => $_[1], 'sub' => $_[2] }, $_[0]; }
sub routine { return $_[0]->{'sub'}; }

1;
