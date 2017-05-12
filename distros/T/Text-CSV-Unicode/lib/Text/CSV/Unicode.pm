package Text::CSV::Unicode;

# $Date: 2012-02-19 22:33:13 +0000 (Sun, 19 Feb 2012) $
# $Revision: 291 $
# $Source: $
# $URL: $

use 5.008;
use strict;
use warnings;
use Text::CSV::Base ();
use base qw(Text::CSV::Base);

our $VERSION = '0.115';

sub new {
    my $self = shift->SUPER::new();
    my %opts =
      ( @_ == 1 and ref $_[0] and ( ref $_[0] ) eq 'HASH' ) ? %{ $_[0] } : @_;
    $self->{'_CHAROK'} =
      $opts{binary} ? qr{ \p{Any} }msx : qr{ \t | \P{Cntrl} }msx;
    return $self;
}

1;

__END__

=head1 NAME

Text::CSV::Unicode -	comma-separated values manipulation routines
			with potentially wide character data

=head1 SYNOPSIS

    use Text::CSV::Unicode;

    $csv = Text::CSV::Unicode->new( { binary => 1 } );

    # then use methods from Text::CSV::Base (= Text::CSV 0.01)

    $version = Text::CSV::Unicode->version();	# get the module version

    $csv = Text::CSV::Unicode->new();	# create a new object

    $status = $csv->combine(@columns);	# combine columns into a string
    $line = $csv->string();		# get the combined string

    $status = $csv->parse($line);	# parse a CSV string into fields
    @columns = $csv->fields();		# get the parsed fields

    $status = $csv->status();		# get the most recent status
    $bad_argument = $csv->error_input();# get the most recent bad argument

=head1 DESCRIPTION

Text::CSV::Unicode provides facilities for the composition and
decomposition of comma-separated values, based on Text::CSV 0.01.
Text::CSV::Unicode allows for input with wide character data.

An instance of the Text::CSV::Unicode class can combine fields
into a CSV string and parse a CSV string into fields.

=head1 FUNCTIONS

=over 4

=item version

    $version = Text::CSV::Unicode->version();

This function may be called as a class or an object method. 
It returns the current module version.

=item new

    $csv = Text::CSV::Unicode->new( [{ binary => 1 }] );

This function may be called as a class or an object method.
It returns a reference to a newly created Text::CSV::Unicode object.
C<< binary => 0 >> allows the same ASCII input as Text::CSV and all
other input, while C<< binary => 1 >> allows for all Unicode
characters in the input (including \r and \n),

=item combine

    $status = $csv->combine(@columns);

This object function constructs a CSV string from the arguments,
returning success or failure.  Failure can result from lack of
arguments or an argument containing an invalid character.  Upon
success, C<string()> can be called to retrieve the resultant CSV
string.  Upon failure, the value returned by C<string()> is undefined
and C<error_input()> can be called to retrieve an invalid argument.

Silently accepts undef values in input and treats as an empty string.

=item string

    $line = $csv->string();

This object function returns the input to C<parse()> or the resultant
CSV string of C<combine()>, whichever was called more recently.

=item parse

    $status = $csv->parse($line);

This object function decomposes a CSV string into fields, returning
success or failure.  Failure can result from a lack of argument or
the given CSV string is improperly formatted.  Upon success,
C<fields()> can be called to retrieve the decomposed fields.  
Upon failure, the value returned by C<fields()> is undefined
and C<error_input()> can be called to retrieve the invalid argument.

=item fields

    @columns = $csv->fields();

This object function returns the input to C<combine()> or the resultant
decomposed fields of C<parse()>, whichever was called more recently.

=item status

    $status = $csv->status();

This object function returns success (or failure) of C<combine()> or
C<parse()>, whichever was called more recently.

=item error_input

    $bad_argument = $csv->error_input();

This object function returns the erroneous argument (if it exists) of
C<combine()> or C<parse()>, whichever was called more recently.

=back

=head1 SUBROUTINES/METHODS

None

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

See HASH option to C<< ->new >>.

=head1 DEPENDENCIES

perl 5.8.0

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

As slow as Text::CSV 0.01.

Cannot change separators and delimiters.

=head1 EXAMPLE

    require Text::CSV::Unicode;

    my $csv = Text::CSV::Unicode->new;

    my $column = '';
    my $sample_input_string = '"I said, ""Hi!""",Yes,"",2.34,,"1.09"';
    if ($csv->parse($sample_input_string)) {
	my @field = $csv->fields;
	my $count = 0;
	for $column (@field) {
	    print ++$count, " => ", $column, "\n";
	}
	print "\n";
    }
    else {
	my $err = $csv->error_input;
	print "parse() failed on argument: ", $err, "\n";
    }

    my @sample_input_fields = ( 'You said, "Hello!"',
				5.67,
				'Surely',
				'',
				'3.14159');
    if ($csv->combine(@sample_input_fields)) {
	my $string = $csv->string;
	print $string, "\n";
    }
    else {
	my $err = $csv->error_input;
	print "combine() failed on argument: ", $err, "\n";
    }

=head1 CAVEATS

This module is based upon a working definition of CSV format
which may not be the most general.

=over 4

=item 1 

Allowable characters within a CSV field are all unicode characters,
with C<< binary => 1 >>; otherwise control characters are not allowed,
but the tab character is allowed.

=item 2

A field within CSV may be surrounded by double-quotes.

=item 3

A field within CSV must be surrounded by double-quotes to contain a comma.

=item 4

A field within CSV must be surrounded by double-quotes to contain an embedded
double-quote, represented by a pair of consecutive double-quotes.

=item 5

Line-ending characters are handled as part of the data.

=back

=head1 VERSION

0.115

=head1 AUTHOR

Robin Barker <rmbarker@cpan.org>

=head1 SEE ALSO

Text::CSV 0.01

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, 2008, 2010, 2011, 2012 Robin Barker.  
All rights reserved. 

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The documentation of Text::CSV::Unicode methods that are inherited from
Text::CSV::Base is taken from Text::CSV 0.01 (with some reformatting) 
and is Copyright (c) 1997 Alan Citterman.

=cut

