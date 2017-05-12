#!/usr/bin/perl

package Test::TAP::Model::File;

use strict;
use warnings;

use Test::TAP::Model::Subtest;
use List::Util (); # don't import max, we have our own. We use it fully qualified

use overload '""' => "name", '==' => "equal";

use Method::Alias (
	(map { ($_ => 'cases') } qw/seen_tests seen test_cases subtests/),
	(map { ($_ => 'ok_tests') } qw/passed_tests/),
	(map { ($_ => 'nok_tests') } qw/failed_tests/),
	(map { ($_ => 'planned') } qw/max/),
	(map { ($_ => 'ok') } qw/passed/),
	(map { ($_ => 'nok') } qw/failed/),
);

# TODO test this more thoroughly, probably with Devel::Cover

sub new {
	my $pkg = shift;
	my $struct = shift;
	bless { struct => $struct }, $pkg; # don't bless the structure, it's not ours to mess with
}

# predicates about the test file
sub ok { $_[0]{struct}{results}->passing };
sub nok { !$_[0]->ok };
sub skipped { defined($_[0]{struct}{results}->skip_all) };
sub bailed_out {
	my $event = $_[0]{struct}{events}[-1] or return;
	return unless exists $event->{type};
	return $event->{type} eq "bailout";
}

# member data queries
sub name { $_[0]{struct}{file} }

# utility methods for extracting tests.
sub subtest_class { "Test::TAP::Model::Subtest" }
sub _mk_objs { my $self = shift; wantarray ? map { $self->subtest_class->new($_) } @_ : @_ }
sub _test_structs {
	my $self = shift;
	my $max = $self->{struct}{results}->max;

	# cases is an array of *copies*... that's what the map is about
	my @cases = grep { exists $_->{type} and $_->{type} eq "test" } @{ $self->{struct}{events} };

	if (defined $max){
		if ($max > @cases){
			# add failed stubs for tests missing from plan
			my %bailed = (
				type => "test",
				ok => 0,
				line => "stub",
			);

			for my $num (@cases + 1 .. $max) {
				push @cases, { %bailed, num => $num };
			}
		} elsif (@cases > $max) {
			# mark extra tests as unplanned
			my $diff = @cases - $max;
			for (my $i = $diff; $i; $i--){
				$cases[-$i]{unplanned} = 1;
			}	
		}
	}

	@cases;
}
sub _c {
	my $self = shift;
	my $sub = shift;
	my $scalar = shift;
	return $scalar if not wantarray and defined $scalar; # if we have a precomputed scalar
	$self->_mk_objs(grep { &$sub } $self->_test_structs);
}

# queries about the test cases
sub planned { $_[0]{struct}{results}->max };

sub cases {
	my @values = map { $_[0]{struct}{results}->$_ } qw/seen max/;
	my $scalar = List::Util::max(@values);
	$_[0]->_c(sub { 1 }, $scalar)
};
sub actual_cases { $_[0]->_c(sub { $_->{line} ne "stub" }, $_[0]{struct}{results}->seen) }
sub ok_tests { $_[0]->_c(sub { $_->{ok} }, $_[0]{struct}{results}->ok) };
sub nok_tests { $_[0]->_c(sub { not $_->{ok} }, $_[0]->seen - $_[0]->ok_tests )};
sub todo_tests { $_[0]->_c(sub { $_->{todo} }, $_[0]{struct}{results}->todo) }
sub skipped_tests { $_[0]->_c(sub { $_->{skip} }, $_[0]{struct}{results}->skip) }
sub unexpectedly_succeeded_tests { $_[0]->_c(sub { $_->{todo} and $_->{actual_ok} }) }

sub ratio {
	my $self = shift;
	$self->seen ? $self->ok_tests / $self->seen : ($self->ok ? 1 : 0); # no tests is an error
}

sub percentage {
	my $self = shift;
	sprintf("%.2f%%", 100 * $self->ratio);
}

sub pre_diag { $_[0]{struct}{pre_diag} || ""}

sub equal {
	my $self = shift;
	my $other = shift;

	# number of sub-tests
	return unless $self->seen == $other->seen;

	# values of subtests
	my @self = $self->cases;
	my @other = $other->cases;

	while (@self) {
		return unless (pop @self) == (pop @other);
	}

	1;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TAP::Model::File - an object representing the TAP results of a single
test script's output.

=head1 SYNOPSIS

	my $f = ( $t->test_files )[0];
	
	if ($f->ok){ # et cetera
		print "happy happy joy joy!";
	}

=head1 DESCRIPTION

This is a convenience object, which is more of a library of questions you can
ask about the hash structure described in L<Test::TAP::Model>.

It's purpose is to help you query status concisely, probably from a templating
kit.

=head1 METHODS

=head2 Miscelleneous

=over 4

=item new

This constructor accepts a hash like you can find in the return value of
L<Test::TAP::Model/structure>.

It does not bless that structure to stay friendly with others. Instead it
blesses a scalar reference to it.

=item subtest_class

This returns the name of the class used to construct subtest objects using
methods like L<ok_tests>.

=back

=head2 Predicates About the File

=over 4

=item ok

=item passed

Whether the file as a whole passed

=item nok

=item failed

Or failed

=item skipped

Whether skip_all was done at some point

=item bailed_out

Whether test bailed out

=back

=head2 Misc info

=over 4

=item name

The name of the test file.

=item

=back

=head2 Methods for Extracting Subtests

=over 4

=item cases

=item subtests

=item test_cases

=item seen_tests

=item seen

In scalar context, a number, in list context, a list of
L<Test::TAP::Model::Subtest> objects

This value is somewhat massaged, with stubs created for planned tests which
were never reached.

=item actual_cases

This method returns the same thing as C<cases> and friends, but without the
stubs.

=item max

=item planned

Just a number, of the expected test count.

=item ok_tests

=item passed_tests

Subtests which passed

=item nok_tests

=item failed_tests

Duh. Same list/scalar context sensitivity applies.

=item todo_tests

Subtests marked TODO.

=item skipped_tests

Test which are vegeterian.

=item unexpectedly_succeeded_tests

Please tell me you're not really reading these decriptions. The're really only
to get the =items sepeared in whatever POD viewer you are using.

=back

=head2 Statistical goodness

=over 4

=item ratio

OK/(max seen, planned)

=item percentage

Pretty printed ratio in percentage, with two decimal points and a percent sign.

=item pre_diag

Any diagnosis output seen in TAP that came before a subtest.

=cut
