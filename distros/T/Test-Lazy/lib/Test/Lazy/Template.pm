package Test::Lazy::Template;

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/tester template/);

use Test::Lazy::Tester;
use Test::Builder();
use Scalar::Util qw/blessed/;
use Carp;

=head1 NAME

Test::Lazy::Template

=head1 SYNOPSIS

Build a template for running a similar set of tests repeatedly.

The purpose of this module is to provide a convenient way of
testing a set of initial conditions in different ways.

The best way to show this is in an example:

	# Template up the intial condition template.
	my $template = new Test::Lazy::Template([ 
		[ "qw/1/" ],
		[ "qw/a/" ],
		[ "qw/apple/" ],
		[ "qw/2/" ],
		[ "qw/0/" ],
		[ "qw/-1/" ],
		[ "map { \$_ => \$_ * 2 } qw/0 1 2 3 4/" ],
	]);

	# Run some different tests.
	# NOTE: Don't have to use '%?' if the statement will run without modification.
	$template->test("defined(%?)" => ok => undef);
	$template->test("length(%?) >= 1" => ok => undef);
	$template->test("length(%?)" => '>=' => 1);
	$template->test("length(%?)" => '<' => 10);
	$template->test([
		[ '%?' => is => 1 ],
		[ is => 'a' ],
		[ is => 'apple' ],
		[ is => 2 ],
		[ is => 0 ],
		[ is => is => -1 ],
		[ is => { 0 => 0, 1 => 2, 2 => 4, 3 => 6, 4 => 8 } ],
	]);

=head1 METHODS

=head2 Test::Lazy::Template->new( <template> )

=head2 Test::Lazy::Template->new( <test>, <test>, ..., <test> )

Create a new C<Test::Lazy::Template> object using the giving test specification.

If <template> is a SCALAR reference, then new will split <template> on each newline,
ignoring empty lines and lines beginning with a pound (#).

		# You could do something like this:
		my $template = template(\<<_END_);
	qw/1/
	qw/a/
	qw/apple/
	qw/2/
	qw/0/
	qw/-1/

	# Let's test this one too.
	map { \$_ => \$_ * 2 } qw/0 1 2 3 4/
	_END_
	

Returns the new C<Test::Lazy::Template> object

=cut

sub new {
	my $self = bless {}, shift;
    my $tester = blessed $_[0] && $_[0]->isa("Test::Lazy::Tester") ? shift : Test::Lazy::Tester->new;
	my $template = $_[0];
	if (ref $template eq 'SCALAR') {
		my @template = map { [ $_ ] } grep { length $_ && $_ !~ m/^\s*#/ } split m/\n/, $$template;
		$template = \@template;
	}
	elsif (ref $template eq 'ARRAY') {
	}
	else {
		$template = [ @_ ];
	}
	$self->tester($tester);
	$self->template($template);
	return $self;
}

=head2 $template->test( <template> )

For each test in $template, modify and run each the test according to the corresponding entry in <template>.

=head2 $template->test( <test> )

Modify and then run each test in $template by using <test> to complete each test's specification.

=cut

sub test {
	my $self = shift;

	my $template = $self->template;
	my $size = @$template;
	my $mdf_template;
	my $base_stmt;
	if (ref $_[0] eq 'ARRAY') {
		$mdf_template = shift;
	}
	elsif (ref $_[1] eq 'ARRAY') {
		$base_stmt = shift;
		$mdf_template = shift;
	}
	else {
		my ($mdf_stmt, $mdf_cmpr, $mdf_rslt);
		if (2 == @_) {
			($mdf_stmt, $mdf_cmpr, $mdf_rslt) = (undef, @_);
		}
		else {
			($mdf_stmt, $mdf_cmpr, $mdf_rslt) = @_;
		}

		$mdf_template = [ map { [ $mdf_stmt, $mdf_cmpr, $mdf_rslt ] } (0 .. $size - 1) ];
	}

	for (my $index = 0; $index < $size; ++$index) {
		my $line = $template->[$index];
		my $mdf_line = $mdf_template->[$index];
		
		my ($mdf_stmt, $mdf_cmpr, $mdf_rslt);
		if (2 == @$mdf_line) {
			($mdf_stmt, $mdf_cmpr, $mdf_rslt) = ($base_stmt, @$mdf_line);
		}
		else {
			($mdf_stmt, $mdf_cmpr, $mdf_rslt) = @$mdf_line;
		}

		if (defined $mdf_stmt) {
			$mdf_stmt =~ s/%\?/$line->[0]/;
		}
		else {
			$mdf_stmt = $line->[0];
		}

		my $stmt = $mdf_stmt;
		my ($cmpr) = grep { defined } ($mdf_cmpr, $line->[1]);
		my ($rslt) = grep { defined } ($mdf_rslt, $line->[2]);

		{
			local $Test::Builder::Level = $Test::Builder::Level + 1;

			$self->tester->try($stmt, $cmpr, $rslt, "$index: %");
		}
	}

}

1;
