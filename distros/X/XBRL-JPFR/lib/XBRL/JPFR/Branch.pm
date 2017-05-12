package XBRL::JPFR::Branch;

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;
use Clone qw(clone);
use Data::Dumper;

use base qw(XBRL::JPFR::Element);

my @fields = qw(depth order weight prefLabel label priority prefixed_name use from from_full from_short id_full id_short tos);
XBRL::JPFR::Branch->mk_accessors(@fields);

sub new() {
	my ($class, $element) = @_;
	my $self = clone($element);
	$$self{'tos'} = [];
	bless $self, $class;

	return $self;
}

sub splice_undefs {
	my ($tree) = @_;
	my $tos = $$tree{'tos'};
	$$tree{'tos'} = [grep {defined} @$tos];
	foreach my $to (@{$$tree{'tos'}}) {
		$to->splice_undefs();
	}
}

sub splice_branch_by_id_short {
	my ($parent, $id_short, $prefLabel) = @_;
	$prefLabel = 'http://www.xbrl.org/2003/role/label' unless $prefLabel;
	my $tos = $$parent{'tos'};
	for (my $i = 0 ; $i < @$tos ; $i++) {
		next if $$tos[$i]->id_short() ne $id_short;
		next if $$tos[$i]->prefLabel() ne $prefLabel;
		splice @$tos, $i, 1;
		return;
	}
}

sub delete_branch_by_id_short {
	my ($parent, $id_short, $prefLabel) = @_;
	$prefLabel = 'http://www.xbrl.org/2003/role/label' unless $prefLabel;
	my $tos = $$parent{'tos'};
	my @dels;
	for (my $i = 0 ; $i < @$tos ; $i++) {
		next if !$$tos[$i];
		next if $$tos[$i]->id_short() ne $id_short;
		next if $$tos[$i]->prefLabel() ne $prefLabel;
		push @dels, $i;
	}
	delete @$tos[@dels];
}

sub clone_branch {
	my ($self) = @_;
	my ($from, $tos) = delete @$self{'from', 'tos'};
	my $clone = clone($self);
	@$clone{'from', 'tos'} = ($from, $tos);
	@$self{'from', 'tos'} = ($from, $tos);
	return $clone;
}

sub connect_to {
	my ($from, $to, $arc, $from_label, $to_label) = @_;
	my ($from_full, $from_short) = @$arc{'from_full', 'from_short'};
	my ($to_full, $to_short) = @$arc{'to_full', 'to_short'};
	my ($order, $pref, $weight) = @$arc{'order', 'prefLabel', 'weight'};
	my ($priority, $use) = @$arc{'priority', 'use'};
	if ($to->from()) {
		$to = $to->clone_branch();
		$to->from(undef);
		$to->tos([]);
	}
	push @{$$from{'tos'}}, $to;
	$from->label($from_label);
	$from->id_full($from_full);
	$from->id_short($from_short);
	$to->from($from);
	$to->label($to_label);
	$to->from_full($from_full);
	$to->from_short($from_short);
	$to->id_full($to_full);
	$to->id_short($to_short);
	$to->order($order);
	$to->prefLabel($pref);
	$to->weight($weight);
	$to->priority($priority);
	$to->use($use);
}

sub find_branch_by_name {
	my ($tree, $name) = @_;
	return $tree if $tree->name() eq $name;
	foreach my $to (@{$$tree{'tos'}}) {
		my $t = $to->find_branch_by_name($name);
		return $t if $t;
	}
	return undef;
}

sub find_branch_by_id {
	my ($tree, $id) = @_;
	return $tree if $tree->id_short() eq $id;
	foreach my $to (@{$$tree{'tos'}}) {
		my $t = $to->find_branch_by_id($id);
		return $t if $t;
	}
	return undef;
}

sub find_branch_by_label_and_relation {
	my ($tree, $branch) = @_;
	my $is_branch = $tree->label() eq $branch->label();
	$is_branch &&= $tree->depth() == $branch->depth();
	if ($branch->abstract() eq 'false') {
		$is_branch &&= $tree->abstract() eq 'false';
	}
	if ($tree->from() && $branch->from()) {
		$is_branch &&= $tree->from()->label() eq $branch->from()->label();
	}
	return $tree if $is_branch;
	foreach my $to (@{$$tree{'tos'}}) {
		my $t = $to->find_branch_by_label_and_relation($branch);
		return $t if $t;
	}
	return undef;
}

sub dump_branch {
	my ($branch) = @_;
	my $clone = $branch->clone_branch();
	delete @$clone{'from', 'tos'};
	return Dumper($clone);
}

=head1 XBRL::JPFR::Branch

XBRL::JPFR::Branch - OO Module for Encapsulating XBRL::JPFR Branchs

=head1 SYNOPSIS

  use XBRL::JPFR::Branch;

	my $branch = XBRL::JPFR::Branch->new(XBRL::JPFR::Element);

=head1 DESCRIPTION

This module is part of the XBRL::JPFR modules group and is intended for use with XBRL::JPFR.

=over 4

=item new

Constructor for object takes the branch XML from the element.

=item depth

Get or set the Branch's depth.

=item order

Get or set the branch's order.

=item weight

Get or set the branch's weight.

=item label

Get or set the branch's label

=item from_short

Get or set the branch's from_short

=item from_full

Get or set the branch's from_full

=item to_short

Get or set the branch's to_short.

=item to_full

Get or set the branch's to_full.

=item id_short

Get or set the branch's id_short.

=item id_full

Get or set the branch's id_full.

=item tos

Get or set the branch's children.

=back

=head1 AUTHOR

Tetsuya Yamamoto <yonjouhan@gmail.com>

=head1 SEE ALSO

Modules: XBRL XBRL::JPFR

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Tetsuya Yamamoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;
