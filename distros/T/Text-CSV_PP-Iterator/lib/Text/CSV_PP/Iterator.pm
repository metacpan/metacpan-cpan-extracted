package Text::CSV_PP::Iterator;

# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	tab = 4 spaces || die.
#
# History Info:
#	Rev		Author		Date		Comment
#	1.00   	Ron Savage	20070612	Initial version <ron@savage.net.au>

use base 'Text::CSV_PP';
use strict;
use warnings;
no warnings 'redefine'; # This line is for t/test.t.

use Iterator;
use Iterator::IO;
use Exception::Class
(
	'Iterator::X::ColumnCountMismatch' =>
	{
		description	=> 'Heading column count does not match record column count',
		fields		=> 'info',
		isa			=> 'Iterator::X',
	},
	'Iterator::X::NoHeadingsInFile' =>
	{
		description	=> 'No headings in empty file',
		isa			=> 'Iterator::X',
	},
);

our $VERSION = '1.04';

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
		_column_names	=> [],
		_file_name		=> '',
	);

	sub _get_default_for
	{
		my($self, $attr_name) = @_;

		return $_attr_data{$attr_name};
	}

	sub _set_default_for
	{
		my($self, $attr_name, $attr_value) = @_;

		$_attr_data{$attr_name} = $attr_value;
	}

	sub _standard_keys
	{
		return keys %_attr_data;
	}
}

# -----------------------------------------------

sub column_names
{
	my($self) = @_;

	return $self -> _get_default_for('_column_names');

}	# End of column_names.

# -----------------------------------------------

sub fetchrow_hashref
{
	my($self)			= @_;
	my($heading_count)	= scalar @{$self -> column_names()};

	my($line);

	# If the parameter column_names was not supplied to the constructor,
	# we must get its value from the first line of the user's file.

	if (scalar @{$self -> column_names()} == 0)
	{
		eval{$line = $$self{'_iterator'} -> value()};

		# When exhausted return something more specific.

		if (Iterator::X::Exhausted -> caught() )
		{
			Iterator::X::NoHeadingsInFile -> throw(message => "No headings in empty file. \n");
		}

		$self -> parse($line);
		$self -> _set_default_for('_column_names', [$self -> fields()]);

		$heading_count = scalar @{$self -> column_names()};
	}

	eval{$line = $$self{'_iterator'} -> value()};

	if (Iterator::X -> caught() )
	{
		# Return undef at EOF to make while($h = $p -> fetchrow_hashref() ) nice to use.

		if (Iterator::X::Exhausted -> caught() )
		{
			return undef;
		}
		else
		{
			Iterator::X -> rethrow();
		}
	}

	$self -> parse($line);

	$line				= [$self -> fields()];
	my($column_count)	= scalar @$line;

	($heading_count != $column_count) && Iterator::X::ColumnCountMismatch -> throw(message => "Header/record column count mismatch. \n", info => "Headings: $heading_count. Columns: $column_count. Line: $line");

	my(%hash);

	$hash{$_} = shift @$line for @{$self -> column_names()};

	return \%hash;

}	# End of fetchrow_hashref.

# -----------------------------------------------

sub new
{
	my($class, $arg) = @_;

	# Keep this class happy.

	my($hash);

	for my $attr_name ($class -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($$arg{$arg_name}) )
		{
			$$hash{$attr_name} = $$arg{$arg_name};

			# Keep the super class happy.

			delete $$arg{$arg_name};
		}
		else
		{
			$$hash{$attr_name} = $class -> _get_default_for($attr_name);
		}
	}

	my($self)	= $class -> SUPER::new($arg);
	$self		= bless($self, $class); # Reconsecrate.

	for my $attr_name ($class -> _standard_keys() )
	{
		$self -> _set_default_for($attr_name, $$hash{$attr_name});
	}

	$$self{'_iterator'} = ifile($self -> _get_default_for('_file_name') );

	return $self;

}	# End of new.

# -----------------------------------------------

1;

=head1 NAME

C<Text::CSV_PP::Iterator> - Provide fetchrow_hashref() for CSV files

=head1 Synopsis

	use Text::CSV_PP::Iterator;

	my($parser) = Text::CSV_PP::Iterator -> new
	({
		column_names	=> [qw/One Two Three Four Five/],
		file_name		=> 'no.heading.in.file.csv',
	});

	my($hashref);

	while ($hashref = $parser -> fetchrow_hashref() )
	{
		print map{"$_ => $$hashref{$_}. "} sort keys %$hashref;
		print "\n";
	}


=head1 Description

C<Text::CSV_PP::Iterator> is a pure Perl module.

It is a convenient wrapper around Text::CSV_PP. Points of interest:

	o Text::CSV_PP::Iterator reads the file for you, using Iterator::IO.
		Warning: Iterator::IO V 0.02 has 3 bugs in it, where it does not
		call throw() properly. I've reported this via http://rt.cpan.org
	o All of Text::CSV_PP's new() parameters are supported by the fact
		that Text::CSV_PP::Iterator subclasses Text::CSV_PP
	o All data is returned as a hashref just like DBI's fetchrow_hashref(),
		using Text::CSV_PP::Iterator's only method, fetchrow_hashref()
	o The module reads the column headers from the first record in the file, or ...
	o The column headers can be passed in to new() if the file has none
	o Non-existent file errors throw the exception Iterator::X::IO_Error,
		which stringifies to a nice error message if you don't catch it
	o EOF returns undef to allow this neat construct:
		while ($hashref = $parser -> fetchrow_hashref() ){...}
	o Dependencies:
	- Iterator::IO
	- Text::CSV_PP
	o Example code: t/test.t demonstrates:
	- How to call fetchrow_hashref in isolation and in a loop
	- How to call fetchrow_hashref in eval{...} and catch exceptions

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<Text::CSV_PP::Iterator> object.

This is the class's contructor.

Usage: Text::CSV_PP::Iterator -> new({...}).

This method takes a hashref of parameters. Only the file_name parameter is mandatory.

For each parameter you wish to use, call new as new({param_1 => value_1, ...}).

=over 4

=item file_name

This is the name of the file that this module will read for you.

One record will be returned each time you call C<fetchrow_hashref()>.

There is no default value for file_name.

This parameter is mandatory.

=back

=head1 Method: fetchrow_hashref()

Returns an hashref ref of column data from the next record in the input file.

=head1 Example code

See the file t/test.t in the distro.

=head1 Similar Modules

There are quite a few modules on CPAN which offer ways of processing CSV (and similar) files:

=over 4

=item Text::CSV

The original, and pure-Perl, way of doing things.

The major drawback is the lack of options to C<new()>.

=item Text::CSV_PP

A pure-Perl version of the next module, and the parent of my module.

Allows the column separator to be surrounded by tabs or spaces. Nice.

Does not allow the column headers to be provided to C<new()>.

=item Text::CSV_XS

A compiled module, with many options.

Does not allow the column separator to be surrounded by tabs or spaces.

Does not allow the column headers to be provided to C<new()>.

I always use this module if I have a compiler available. But that was before I wrote the current module.

=item Text::CSV::LibCSV

Requires the external, compiled, library C<libcsv>, which is written in C.

I did not test this module.

=item Text::CSV::Simple

This is a wrapper around the compiled code in C<Text::CSV_XS>.

I did not test this module.

=item Text::LooseCSV

I did not test this module.

=item Text::RecordParser

This module has a fake C<META.yml>, which does not list any dependencies. However,
when you try to install it, you get:

	- ERROR: Test::Exception is not installed
	- ERROR: IO::Scalar is not installed
	- ERROR: Class::Accessor is not installed
	- ERROR: Readonly is not installed
	- ERROR: List::MoreUtils is not installed
	* Optional prerequisite Text::TabularDisplay is not installed
	* Optional prerequisite Readonly::XS is not installed

I did not test this module.

=item Tie::CSV_File

A different way of viewing CSV files.

This is a wrapper around the compiled code in C<Text::CSV_XS>.

It supports some of the same options as C<Text::CSV_XS>.

I did not test this module.

=item Text::xSV

This module has a huge, and I do mean huge, number of methods. If only they worked...

Unfortunately, in one set of tests this module kept overwriting my input file, which is very nasty.

In another set, the method C<print_header()> did not work. Now, that method calls C<format_header()>,
which looks for the field $self->{header}, but you have to have called C<read_header()>, which does
not set $self->{header}. Rather C<read_header()> is aliased to C<bind_header()>, which calls C<bind_fields()>,
which does not set $self->{header} either. It sets $self->{field_pos}. Oh, dear. Forget it.

=back

=head1 Repository

L<https://github.com/ronsavage/Text-CSV_PP-Iterator>

=head1 Support

Bugs should be reported via the CPAN bug tracker at

L<https://github.com/ronsavage/Text-CSV_PP-Iterator/issues>

=head1 Author

C<Text::CSV_PP::Iterator> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2007.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2007, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
