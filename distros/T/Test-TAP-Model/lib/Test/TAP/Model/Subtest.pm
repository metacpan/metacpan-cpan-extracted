#!/usr/bin/perl

package Test::TAP::Model::Subtest;

use strict;
use warnings;

use overload '""' => "str", '==' => "equal";

use Carp qw/croak/;

sub new {
	my $pkg = shift;
	my $struct = shift;

	croak "eek! You can't bless non test events into $pkg" unless $struct->{type} eq "test";
	
	bless \$struct, $pkg; # don't bless the structure, it's not ours to mess with
}

sub str { ${ $_[0] }->{str} }

# predicates about the case
sub ok { ${ $_[0] }->{ok} }; *passed = \&ok;
sub nok { !$_[0]->ok }; *failed = \&nok;
sub skipped { ${ $_[0] }->{skip} }
sub todo { ${ $_[0] }->{todo} }
sub actual_ok { ${ $_[0] }->{actual_ok} }
sub actual_nok { !$_[0]->actual_ok }
sub normal { $_[0]->actual_ok xor $_[0]->todo }
sub unexpected { !$_[0]->normal };
sub unplanned { ${ $_[0] }->{unplanned} }
sub planned { !$_[0]->unplanned }

# member data extraction
sub num { ${ $_[0] }->{num} }
sub diag { ${ $_[0] }->{diag} || ""}
sub line { ${ $_[0] }->{line} || ""}
sub reason { ${ $_[0] }->{reason} } # for skip or todo

# pugs specific
sub pos { ${ $_[0] }->{pos} || ""}

# heuristical
sub test_file { $_[0]->pos =~ /(?:file\s+|^)?(\S+?)[\s[:punct:]]*(?:\s+|$)/ ? $1 : "" };
sub test_line { $_[0]->pos =~ /line\s+(\d+)/i ? $1 : ""}
sub test_column { $_[0]->pos =~ /column?\s+(\d+)/ ? $1 : ""}

sub equal {
	my $self = shift;
	my $other = shift;

	($self->actual_ok xor $other->actual_nok)
		and
	($self->skipped xor !$other->skipped)
		and
	($self->todo xor !$other->todo)
}

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TAP::Model::Subtest - An object for querying a test case

=head1 SYNOPSIS

	my @cases = $f->cases;
	$case[0]->ok; # or whatever

=head1 DESCRIPTION

This object allows you to ask questions about a test case in a test file's
output.

=head1 METHODS

=over 4

=item new

This constructor accepts the hash reference to the event logged for this
subtest.

It doesn't bless the hash itself, but rather a reference to it, so that other
objects' feet aren't stepped on.

=item ok

=item passed

Whether the test is logically OK - if it's TODO and not OK this returns true.

=item actual_ok

This is the real value from the output. not OK and todo is false here.

=item nok

=item failed

The opposite of C<ok>

=item actual_nok

The opposite of C<actual_ok>

=item skipped

Whether the test was skipped

=item todo

Whether the test was todo

=item normal

Whether the result is consistent, that is OK xor TODO. An abnormal result
should be noted.

=item unexpected

The negation of C<normal>

=item planned

Whether this test is within the plan declared by the file.

=item unplanned

Maybe it's in love with another fish.

=item num

The number of the test (useful for when the test came from a filtered query).

=item line

The raw line the data was parsed from.

=item diag

Diagnosis immediately following the test line.

=item reason

If there was a reason (for skip or todo), it's here.

=item pos

=item test_file

=item test_line

=item test_column

These methods extract the little C<< <pos:file.t at line 5, column 3> >>
comments as outputted by pugs' Test.pm.

Supposedly this is where the test case that fail was written.

=item str

A stringy representation much like L<Test::Harness> prints in it's output:

	(?:not )?ok $num/$planned

=back

=cut
