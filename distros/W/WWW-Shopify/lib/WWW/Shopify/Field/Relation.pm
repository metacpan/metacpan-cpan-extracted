#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Field::Relation;
use parent 'WWW::Shopify::Field';
sub new {
	my $package = shift; 
	my $calling_package = caller(0);
	return bless {
		arguments => [@_],
		name => undef,
		owner => $calling_package,
		relation => $_[0]
	}, $package;
}
sub relation { return $_[0]->{relation}; }
sub is_relation { return 1; }
sub is_many { return undef; }
sub is_one { return undef; }
sub is_own { return undef; }
sub is_reference { return undef; } 
sub is_parent { return undef; }
sub sql_type { return WWW::Shopify::Field::Identifier->sql_type(); }

sub is_db_belongs_to { return ($_[0]->is_reference && $_[0]->is_one) || ($_[0]->is_one && $_[0]->is_own && (!$_[0]->relation->parent || $_[0]->relation->parent ne $_[0]->owner )); }
sub is_db_has_one { return $_[0]->is_one && $_[0]->is_own && $_[0]->relation->parent && $_[0]->relation->parent eq $_[0]->owner}
sub is_db_has_many { 
	return !$_[0]->is_db_belongs_to && !$_[0]->is_db_has_one && $_[0]->is_many && (
		($_[0]->relation->parent && $_[0]->relation->parent eq $_[0]->owner) ||
		($_[0]->{arguments}->[1] && ref($_[0]->{arguments}->[1]) && ref($_[0]->{arguments}->[1]) eq 'HASH' && $_[0]->{arguments}->[1]->{direct})
	); }
sub is_db_many_many { return !$_[0]->is_db_belongs_to && !$_[0]->is_db_has_one && !$_[0]->is_db_has_many && ($_[0]->is_many || $_[0]->is_own); }
sub db_min_count { }
sub db_max_count { }
use Math::Round qw(round);
sub db_rand_count { return $_[0]->db_min_count + round(rand($_[0]->db_max_count - $_[0]->db_min_count)); }

package WWW::Shopify::Field::Relation::Parent;
use parent 'WWW::Shopify::Field::Relation';
sub is_parent { return 1; }
sub is_reference { return 1; }
sub is_one { return 1; }

sub db_min_count { return 1; }
sub db_max_count { return 1; }

package WWW::Shopify::Field::Relation::Many;
use parent 'WWW::Shopify::Field::Relation';
sub is_many { return 1; }

sub db_min_count { return defined $_[0]->{arguments}->[1] && !ref($_[0]->{arguments}->[1]) ? $_[0]->{arguments}->[1] : 0; }
sub db_max_count { return defined $_[0]->{arguments}->[2] && !ref($_[0]->{arguments}->[2]) ? $_[0]->{arguments}->[2] : 5; }

package WWW::Shopify::Field::Relation::ReferenceOne;
use parent 'WWW::Shopify::Field::Relation';
sub is_one { return 1; }
sub is_reference { return 1; }
sub data_type { return WWW::Shopify::Field->TYPE_QUANTITATIVE; }

sub db_min_count { return defined $_[0]->{arguments}->[1] && !ref($_[0]->{arguments}->[1]) ? $_[0]->{arguments}->[1] : 0; }
sub db_max_count { return 1; }

package WWW::Shopify::Field::Relation::OwnOne;
use parent 'WWW::Shopify::Field::Relation';
sub is_one { return 1; }
sub is_own { return 1; }

sub db_min_count { return defined $_[0]->{arguments}->[1] && !ref($_[0]->{arguments}->[1]) ? $_[0]->{arguments}->[1] : 0; }
sub db_max_count { return 1; }

1;
