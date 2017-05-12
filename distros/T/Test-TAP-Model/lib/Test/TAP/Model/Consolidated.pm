#!/usr/bin/perl

package Test::TAP::Model::Consolidated;
use base qw/Test::TAP::Model/;
use List::Util ();

use strict;
use warnings;

use Test::TAP::Model::File::Consolidated;

sub new {
	my $pkg = shift;
	bless { _submodels => [ @_ ] }, $pkg;
}

sub submodels {
	my $self = shift;
	@{$self->{_submodels}};
}

sub submodels_ref {
	my $self = shift;
	[ $self->submodels ];
}

sub submodel_count {
	my $self = shift;
	scalar $self->submodels;
}

sub submodel_count_plus_one {
	my $self = shift;
	$self->submodel_count + 1;
}

sub file_class { "Test::TAP::Model::File::Consolidated" }
sub get_test_files {
	my $self = shift;
	my @files = map { [ $_->test_files ] } $self->submodels;
	map { $self->file_class->new(@$_) } _transpose_arrays(@files);
}

sub _transpose_arrays {
	# FIXME skip intelligently when there are holes
	#
	#  good      vs.  broken
	# a   c d e       a c d e
	# a b c   e       a b c e
	#

	my @arrays = @_ or return ();

	my $max = List::Util::max(map { scalar @$_ } @arrays);
	
	my @result;

	for (my $i = 0; $i < $max; $i++) {
		push @result, [];

		foreach my $arr (@arrays) {
			push @{$result[-1]}, $arr->[$i];
		}
	}

	@result;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Test::TAP::Model::Consolidated - The unification of several L<Test::TAP::Model>
reports.

=head1 SYNOPSIS

	use Test::TAP::Model::Consolidated;
	
	my $c = Test::TAP::Model::Consolidated->new(@models); # see Test::TAP::Model

	$c->ok; # all tests from all models are OK?

=head1 DESCRIPTION

L<Test::TAP::Model::Consolidated> is the same interface to Test::TAP::Model
except that it provides an aggregate interface to result processing.

Using it with the L<Test::Harness::Straps> kind of methods will not work.

=cut


