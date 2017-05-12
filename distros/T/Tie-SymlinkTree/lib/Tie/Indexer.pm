package Tie::Indexer;
use strict;
use B::Deparse;
my $dp = new B::Deparse("-sCi0");
our $VERSION="0.1";

BEGIN {
	no strict;
	no warnings;
	use constant Equals => do { package main; sub { $_[0] eq $_[1] } };
	use constant Not => do { package main; sub { !exists $_[1]->{$_[0]}; } };
	use constant Exists => do { package main; sub { exists $_[0]->{$_[1]}; } };
	use constant IndexSimple => do { package main; sub { Tie::Indexer::get_value(@_); } };
	use constant IndexExists => do{ package main; sub { keys %{Tie::Indexer::get_value(@_)}; } };
}

my %operators = (
	'=' => Equals,
	'!' => Not,
	'E' => Exists,
);

my %codeindex;
sub code2text {
	my ($operator) = @_;
	return undef if !defined $operator;
	if (!exists $codeindex{$operator}) {
		$codeindex{$operator} = $dp->coderef2text($operator);
		$codeindex{$operator} =~ s/\n/ /g;
	}
	return $codeindex{$operator};
}

my %indexers = (
	code2text(Equals) => IndexSimple,
	code2text(Exists) => IndexExists,
);

sub get_value {
	my ($tie, $expr, $node) = @_;
	return $node if !defined $expr || $expr eq '';
	my ($prefix) = ($expr =~ m/^([a-z]+);/);
	$expr =~ s/^[a-z]+;//;
	my @path = split("/",$expr);
	my $value = $node;
	while (@path) {
		if (UNIVERSAL::isa($value,'HASH')) {
			$value = $value->{shift @path};
		} elsif (UNIVERSAL::isa($value,'ARRAY')) {
			$value = $value->[shift @path];
		} else {
			undef $value;
			undef @path;
		}
	}
	return $value;
}

sub deindex_node {
	my ($tie, $node, $nodeid) = @_;
	foreach my $index (get_indices($tie)) {
		if ($$index[3]) {
			delete $$index[0]{$_}{$nodeid} foreach ($$index[3]->($tie,$$index[2],$node,$$index[0]));
		} else {
			delete $$index[0]{$_}{$nodeid} foreach ($$index[4]->($tie,$$index[2],$node,$$index[0]));
		}
	}
}

sub index_node_single {
	my ($tie, $node, $nodeid, $index) = @_;
	if ($$index[3]) {
		no warnings 'uninitialized';
		$$index[0]{$_}{$nodeid} = undef foreach ($$index[3]->($tie,$$index[2],$node,$$index[0]));
	} else {
		foreach my $value ($$index[4]->($tie,$$index[2],$node,$$index[0])) {
			$$index[0]{$value}{$nodeid} = undef if ($$index[1]->($value,get_value($tie,$$index[2],$node)));
		}
	}
}

sub index_node {
	my ($tie, $node, $nodeid) = @_;
	foreach my $index (get_indices($tie)) {
		index_node_single(@_,$index);
	}
}

sub get_indices {
	my ($tie) = @_;
	my @res;
	my $index = $tie->_get_index() || {};
	while (my ($expr, $eindex) = each %$index) {
		next if $expr =~ m/^\x{200b}[^\x{200b}]/;
		$expr =~ s/^\x{200b}\x{200b}/\x{200b}/;
		my $values = eval "no strict; package main; return sub ".$$eindex{"\x{200b}values"} if exists $$eindex{"\x{200b}values"};
		$values ||= do { no strict; package main; sub { keys %{$_[3]} } };
		while (my ($operator, $oindex) = each %$eindex) {
			my $indexer = eval "no strict; package main; return sub ".$$index{"\x{200b}indexers"}{$operator} if exists $$index{"\x{200b}indexers"}{$operator};
			push @res, [$oindex, eval "no strict; package main; return sub ".$operator, $expr, $indexer, $values];
		}
	}
	return @res;
}

sub get_index {
	my ($tie, $expr, $operator, $force) = @_;
	$operator = code2text($operator);
	my $index = $tie->_get_index() || return undef;
	$expr = '' if (!defined $expr);
	$expr =~ s/^\x{200b}/\x{200b}\x{200b}/;
	return undef if (!$force && (!exists $$index{$expr} || !exists $$index{$expr}{$operator}));
	return $$index{$expr}{$operator};
}

sub add_index {
	my ($tie, $operator, $expr, $indexer, $values) = @_;
	$operator = $operators{$operator} if (exists $operators{$operator});
	$operator = code2text($operator);
	$indexer ||= $indexers{$operator} if (exists $indexers{$operator});
	$indexer = code2text($indexer);
	$values = code2text($values);

	my $index = $tie->_get_index(1);
	$$index{"\x{200b}indexers"}{$operator} ||= $indexer if (defined $indexer);
	$expr =~ s/^\x{200b}/\x{200b}\x{200b}/;
	$$index{$expr} ||= {};
	$index = $$index{$expr};
	$$index{"\x{200b}values"} ||= $values if (defined $values);
	$$index{$operator} ||= {};
}

sub search {
	my $tie = shift;
	my $base = shift;
	my ($expr, $operator, $value) = ($base, Equals, undef);
	if (ref($base) eq 'HASH') {
		return (wantarray?values(%$base):(values %$base)[0]) if !@_;
		$expr = shift;
	} else {
		undef $base;
	}

	$expr = $operators{$expr} if (exists $operators{$expr});

	if (!ref($expr) || ref($expr) ne 'CODE') {
		$value = shift;
		if (ref($value) eq 'CODE') {
			$operator = $value;
			$value = shift;
		} elsif (exists $operators{$value}) {
			$operator = $operators{$value};
			$value = shift;
		}
	} elsif (ref($expr) eq 'CODE') {
		$operator = $expr;
		$expr = undef;
		$value = undef;
	}
	my $index;
	if ($operator ne Not) {
		if (defined ($index = get_index($tie, $expr, $operator))) {
			# do nothing
		} elsif (!$base && defined ($index = get_index($tie, $expr, Equals))) {
			# TODO: use an Equals index for base matches as well?
			# perhaps some heuristic: if (keys %$base > keys %$index)
			my %res;
			foreach my $exp (keys %$index) {
				local $_ = $exp;
				if ($operator->($exp,$value)) {
					$res{$_} ||= $tie->FETCH($_) foreach (keys %{$$index{$exp}});
					last if !wantarray;
				}
			}
			return search($tie,\%res,@_);
		}
	}
	if (!$index && !$base && (wantarray || $operator eq Not)) {
		$base = {};
		my $key = $tie->FIRSTKEY;
		while (defined $key) {
			$$base{$key} = $tie->FETCH($key);
			$key = $tie->NEXTKEY;
		}
	}

	if ($operator eq Not) {
		if (!$expr) {
			return search($tie,$base,@_,{ %$base },Not);
		} else {
			delete $$expr{$_} foreach (keys %$base);
			return search($tie,$expr);
		}
	}
	if ($index) {
		if (defined ($index = $$index{$value})) {
			if (!$base) {
				$base = { map { ($_ => $tie->FETCH($_)) } keys %$index };
			} else {
				foreach my $key (keys %$base) {
					delete $$base{$key} if !exists $$index{$key};
				}
			}
			return search($tie,$base,@_);
		}
		return ();
	}

	if (!$base) {
		my $key = $tie->FIRSTKEY;
		while (defined $key) {
			my $node = $tie->FETCH($key);
			local $_ = get_value($tie,$expr,$node);
			return $node if $operator->($_,$value) && search($tie,{$key => $node},@_);
			$key = $tie->NEXTKEY;
		}
		return undef;
	}

	while (my ($key, $node) = each %$base) {
		local $_ = get_value($tie,$expr,$node);
		delete $$base{$key} if !$operator->($_,$value);
	}
	return search($tie,$base,@_);
}

sub build_index {
	my ($tie) = @_;
	foreach my $index (get_indices($tie)) {
		foreach my $key (keys %{$$index[0]}) {
			undef $$index[0]{$key};
		}
		my $key = $tie->FIRSTKEY;
		while (defined $key) {
			index_node_single($tie,$tie->FETCH($key),$key,$index);
			$key = $tie->NEXTKEY;
		}
	}
}

no warnings;
"Dahut!";
__END__

=head1 NAME

Tie::Indexer - fast searches through complex perl structures/ties

=head1 SYNOPSIS

 use Tie::SomeModule
 tie %hash, 'Tie::SomeModule', 'some_parameter';
 $hash{'one'} = "some text";         # Creates symlink /some_directory/one
                                     # with contents "some text"
 $hash{'bar'} = "some beer";
 $hash{'two'} = [ "foo", "bar", "baz" ];
 $hash{'three'} = {
   one => { value => 1, popularity => 'high'},
   two => { value => 2, popularity => 'medium'},
   four => { value => 4, popularity => 'low'},
   eleven => { value => 11, popularity => 'medium'},
 };

 # Warning: experimental and subject to change without notice:
 my @entries = tied(%hash)->search(sub { m/some/ }); # returns ("some text","some beer")
 my $firstmatch = $hash{'two'}->search(sub { m/b/ }); # returns "bar"
 my @result1 = $hash{'three'}->search('popularity','medium'); # returns ($hash{'three'}{'two'}, $hash{'three'}{'eleven'})
 my @result2 = $hash{'three'}->search('popularity','=','medium'); # the same
 my @result3 = $hash{'three'}->search('popularity',sub { $_[0] eq $_[1] },'medium'); # the same
 print $hash{'two'}->id; # prints out "two"

=head1 DESCRIPTION

This module provides searches through entries in a tied hash or array. It was developed for
use with Tie::SymlinkTree but should work with any module. All you need to do is to provide
a method Tie::YourModule::_get_index($) which returns a (preferably tied) hashref where
this module can store it's information in. That hashref must support nested hashes.

You will probably also want to provide a sub C<search> which calls Tie::Indexer::search(@_).

For now, read the source to see how to create and rebuild indexes. This is still considered
experimental.

=head1 AUTHOR and LICENSE

Copyright (C) 2004, JÃ¶rg Walter

This plugin is licensed under either the GNU GPL Version 2, or the Perl Artistic
License.

=cut

