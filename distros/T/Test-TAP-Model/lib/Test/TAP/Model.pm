#!/usr/bin/perl

package Test::TAP::Model;
use base qw/Test::Harness::Straps/;

use strict;
use warnings;

use Test::TAP::Model::File;

use List::Util qw/sum/;

our $VERSION = "0.10";

# callback handlers
sub _handle_bailout {
	my($self, $line, $type, $totals) = @_;

	$self->log_event(
		type => 'bailout',
		($self->{bailout_reason}
			? (reason => $self->{bailout_reason})
			: ()
		),
	);

	$self->{meat}{test_files}[-1]{results} = $totals;

	die "Bailed out"; # catch with an eval { }
}
        
sub _handle_test {
	my($self, $line, $type, $totals) = @_;
	my $curr = $totals->seen || 0;

	# this is used by pugs' Test.pm, it's rather useful
	my $pos;
	if ($line =~ /^(.*?) <pos:(.*)>(\r?$|\s*#.*\r?$)/){
		$line = $1 . $3;
		$pos = $2;
	}

	my %details = %{ $totals->details->[-1] };

	$self->log_event(
		type      => 'test',
		num       => $curr,
		ok        => $details{ok},
		actual_ok => $details{actual_ok},
		str       => $details{ok} # string for people
		             	? "ok $curr/" . $totals->max
		             	: "NOK $curr",
		todo      => ($details{type} eq 'todo'),
		skip      => ($details{type} eq 'skip'),

		reason    => $details{reason}, # if at all

		# pugs aux stuff
		line      => $line,
		pos       => $pos,
	);

	if( $curr > $self->{'next'} ) {
		$self->latest_event->{note} =
			"Test output counter mismatch [test $curr]\n";
	}
	elsif( $curr < $self->{'next'} ) {
		$self->latest_event->{note} = join("",
			"Confused test output: test $curr answered after ",
					  "test ", ($self->{'next'}||0) - 1, "\n");
	}
}

sub _handle_other {
	my($self, $line, $type, $totals) = @_;

	my $last_test = $self->{meat}{test_files}[-1];
	if (@{ $last_test->{events} ||= [] } > 0) {
		($self->latest_event->{diag} ||= "") .= "$line\n";
	} else {
		($last_test->{pre_diag} ||= "") .= "$line\n";
	}
}

sub new_with_tests {
	my $pkg = shift;
	my @tests = @_;

	my $self = $pkg->new;
	$self->run_tests(@tests);

	$self;
}

sub new_with_struct {
	my $pkg = shift;
	my $meat = shift;

	my $self = $pkg->new(@_);
	$self->{meat} = $meat; # FIXME - the whole Test::Harness::Straps model can be figured out from this

	$self;
}

sub structure {
	my $self = shift;
	$self->{meat};
}

# just a dispatcher for the above event handlers
sub _init {
	my $s = shift;

	$s->{callback} = sub {
		my($self, $line, $type, $totals) = @_;

		my $meth = "_handle_$type";
		$self->$meth($line, $type, $totals) if $self->can($meth);
	};

	$s->SUPER::_init( @_ );
}

sub log_time {
	my $self = shift;
	$self->{log_time} = shift if @_;
	$self->{log_time};
}

sub log_event {
	my $self = shift;
	my %event = (($self->log_time ? (time => time) : ()), @_);

	push @{ $self->{events} }, \%event;

	\%event;
}

sub latest_event {
	my($self) = shift;
        my %event = @_;
        $self->{events}[-1] || $self->log_event(%event);  
}

sub run {
	my $self = shift;
	$self->run_tests($self->get_tests);
}

sub get_tests {
	die 'the method get_tests is a stub. You must implement it yourself if you want $self->run to work.';
}

sub run_tests {
	my $self = shift;

	$self->_init;

	$self->{meat}{start_time} = time;

	foreach my $file (@_) {
		$self->run_test($file);
	}

	$self->{meat}{end_time} = time;
}

sub run_test {
	my $self = shift;
	my $file = shift;

	my $test_file = $self->start_file($file);
	
	my $results = eval { $self->analyze_file($file) } || Test::Harness::Results->new;
	$test_file->{results} = $results;
	$test_file->{results}->details(undef); # we don't need that

	$test_file;
}

sub start_file {
	my $self = shift;
	my $file = shift;

	push @{ $self->{meat}{test_files} }, my $test_file = {
		file => $file,
		events => ($self->{events} = []),
	};

	$test_file;
}

sub file_class { "Test::TAP::Model::File" }	

sub test_files {
	my $self = shift;
	@{$self->{_test_files_cache} ||= [ $self->get_test_files ]};
}

sub get_test_files {
	my $self = shift;
	map { $self->file_class->new($_) } @{ $self->{meat}{test_files} };
}

sub ok { $_->ok or return for $_[0]->test_files; 1 }; *passed = \&ok; *passing = \&ok;
sub nok { !$_[0]->ok }; *failing = \&nok; *failed = \&nok;
sub total_ratio { return $_ ? $_[0]->total_passed / $_ : ($_[0]->ok ? 1 : 0) for $_[0]->total_seen }; *ratio = \&total_ratio;
sub total_percentage { sprintf("%.2f%%", 100 * $_[0]->total_ratio) }
sub total_seen { sum map { scalar $_->seen } $_[0]->test_files }
sub total_todo { sum map { scalar $_->todo_tests } $_[0]->test_files }
sub total_skipped { sum map { scalar $_->skipped_tests } $_[0]->test_files }
sub total_passed { sum map { scalar $_->ok_tests } $_[0]->test_files }; *total_ok = \&total_passed;
sub total_failed { sum map { scalar $_->nok_tests } $_[0]->test_files }; *total_nok = \&total_failed;
sub total_unexpectedly_succeeded { sum map { scalar $_->unexpectedly_succeeded_tests } $_[0]->test_files }

sub summary {
	my $self = shift;
	$self->{_summary} ||=
	sprintf "%d test cases: %d ok, %d failed, %d todo, "
			."%d skipped and %d unexpectedly succeeded",
			map { my $m = "total_$_"; $self->$m }
			qw/seen passed failed todo skipped unexpectedly_succeeded/;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TAP::Model - DEPRECATED Use L<TAP::Harness>, L<TAP::Formatter::HTML>

=head1 SYNOPSIS

	use Test::TAP::Model;

	my $t = Test::TAP::Model->new();

	# Test::Harness::Straps methods are available, but they aren't enough.
	# Extra book keeping is required. See the run_test method

	# here's a convenient wrapper
	$t = Test::TAP::Model->new_with_tests(glob("t/*.t"));
	
	# that's shorthand for new->run_tests
	$t->run_tests(qw{ t/foo.t t/bar.t });

	# every file is an object (Test::TAP::Model::File)
	my @tests = $t->test_files;

	# this method returns a structure
	my $structure = $t->structure;

	# which is guaranteed to survive serialization
	my $other_struct = do { my $VAR; eval Data::Dumper::Dumper($structure) };

	# the same as $t1
	my $t2 = Test::TAP::Model->new_with_struct($other_struct);

=head1 DESCRIPTION

This module is a subclass of L<Test::Harness::Straps> (although in an ideal
world it would really use delegation).

It uses callbacks in the straps object to construct a deep structure, with all
the data known about a test run accessible within.

It's purpose is to ease the processing of test data, for the purpose of
generating reports, or something like that.

The niche it fills is creating a way to access test run data, both from a
serialized and a real source, and to ease the querying of this data.

=head1 YEAH YEAH, WHAT IS IT GOOD FOR?

Well, you can use it to send test results, and process them into pretty
reports. See L<Test::TAP::HTMLMatrix>.

=head1 TWO INTERFACES

There are two ways to access the data in L<Test::TAP::Model>. The complex one,
which creates objects, revolves around the simpler one, which for Q&D purposes
is exposed and encouraged too.

Inside the object there is a well defined deep structure, accessed as

	$t->structure;

This is the simple method. It is a hash, containing some fields, and basically
organizes the test results, with all the fun fun data exposed.

The second interface is documented below in L</METHODS>, and lets you create
pretty little objects from this structure, which might or might not be more
convenient for your purposes.

When it's ready, that is.

=head1 HASH STRUCTURE

I hope this illustrates how the structure looks.

	$structure = {
		test_files => $test_files,

		start_time => # when the run started
		end_time   => # ... and ended
	};

	$test_files = [
		$test_file,
		...
	];

	$test_file = {
		file => "t/filename.t",
		results => \%results;
		events => $events,

		# optional
		pre_diag => # diagnosis emitted before any test
	};

	%results = $strap->analyze_foo(); 

	$events = [
		{
			type => "test",
			num    => # the serial number of the test
			ok     => # a boolean
			result => # a string useful for display
			todo   => # a boolean
			line   => # the output line

			# pugs auxillery stuff, from the <pos:> comment
			pos    => # the place in the test file the case is in

			time   => # the time this event happenned
		},
		{
			type => "bailout",
			reason => "blah blah blah",
		}
		...,
	];

That's basically it.

=head1 OBJECT INTERFACE

The object interface is structured around three objects:

=over 4

=item L<Test::TAP::Model>

A whole run

=item L<Test::TAP::Model::File>

A test script

=item L<Test::TAP::Model::Subtest>

A single case in a test script

=back

Each of these is discussed in it's respectful manpage. Here's the whole run:

=head1 METHODS

=head2 The said OOP interface

=over 4

=item test_files

Returns a list of L<Test::TAP::Model::File> objects.

=item ok

=item passing

=item passed

=item nok

=item failed

=item failing

Whether all the suite was OK, or opposite.

=item total_ok

=item total_passed

=item total_nok

=item total_failed

=item total_percentage

=item total_ratio

=item total_seen

=item total_skipped

=item total_todo

=item total_unexpectedly_succeeded

These methods are all rather self explanatory and either provide aggregate
results based on the contained test files.

=item ratio

An alias to total_ratio.

=back

=head2 Misc methods

=over 4

=item new

Creates an empty harness.

=item new_with_struct $struct

Adopts a structure. This is how you take a thawed structure and query it.

=item new_with_tests @tests

Takes a list of tests and immediately runs them.

=item get_tests

A method invoked by C<run> to get a list of tests to run.

This is a stub, and you should subclass it if you care.

=item run

This method runs the list of tests returned by C<get_tests>.

=item run_tests @tests

Runs these tests. Just loops, and calls analyze file, with an eval { } around
it to catch bail out.

=item run_test $test

Actually this is the part which does eval and calls C<start_file> and
C<analyze_file>

=item start_file

This tells L<Test::TAP::Model> that we are about to analyze a new file.

This will eventually be moved into an overridden version of analyze, I think.

Consider it's existence a bug.

=item log_event

This logs a new event with time stamp in the event log for the current test.

=item latest_event

Returns the hash ref to the last event, or a new one if there isn't a last
event yet.

=item file_class

This method returns the class to call new on, when generating file objects in
C<test_files>.

=item structure

This method returns the hash reference you can save, browse, or use to create
new objects with the same date.

=item log_time

This is an accessor. If it's value is set to true, any events logged will have
a time stamp added.

=back

=head1 SERIALIZING

You can use any serializer you like (L<YAML>, L<Storable>, etc), to freeze C<<
$obj->structure >>, and then you can thaw it back, and pass the thawed
structure to C<new_with_struct>.

You can then access the object interface normally.

This behavior is guaranteed to remain consistent, at least between similar
versions of this module. This is there to simplify smoke reports.

=head1 ISA Test::Harness::Straps

L<Test::TAP::Model> is a L<Test::Harness::Straps> subclass. It knows to run
tests on it's own. See the C<run> methods and it's friends.

However, you should see how C<run_test> gets things done beforehand. It's a bit
of a hack because I'm not quite sure if L<Test::Harness::Straps> has the proper
events to encapsulate this cleanly (Gaal took care of the handlers way before I
got into the picture), and I'm too lazy to check it out.

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/Test-TAP-Model/>, and use C<darcs send> to
commit changes.

=head1 AUTHORS

This list was generated from svn log testgraph.pl and testgraph.css in the pugs
repo, sorted by last name.

=over 4

=item *

Michal Jurosz

=item *

Yuval Kogman <nothingmuch@woobling.org> NUFFIN

=item *

Max Maischein <corion@cpan.org> CORION

=item *

James Mastros <james@mastros.biz> JMASTROS

=item *

Scott McWhirter <scott-cpan@NOSPAMkungfuftr.com> KUNGFUFTR

=item *

putter (svn handle)

=item *

Audrey Tang <cpan@audreyt.org> AUDREYT

=item *

Gaal Yahas <gaal@forum2.org> GAAL

=back

=head1 COPYRIGHT & LICNESE

	Copyright (c) 2005 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
