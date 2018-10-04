package Text::CSV::Unicode;

use strict;
use warnings;

use base qw(Text::CSV);

our $VERSION = '0.400';

sub new {
    my ($self, $hash) = @_;
    if ( $hash and $hash -> {binary} ) {
        warnings::warnif("deprecated",
                "binary is deprecated: use Text::CSV");
	return Text::CSV->new( $hash );
    }
    return $self->SUPER::new( { binary => 1, %{ $hash || {} } } );
}

sub combine {
    my $self = shift;
    for (grep defined, @_) { return if _bad(); }
    return $self->SUPER::combine(@_);
}

sub parse {  
    my $self = shift;
    for (map +$_, grep defined, @_) {
	    chomp;
	    return if _bad();
    }
    return $self->SUPER::parse( @_ );
}

sub _bad { m{ [^\t\P{Cntrl}] }x; }	# test $_

1;


__END__

=head1 NAME

Text::CSV::Unicode -	comma-separated values manipulation routines
			with potentially wide character data

=head1 SYNOPSIS

    use Text::CSV::Unicode;

    $csv = Text::CSV::Unicode->new();

    # then use methods from Text::CSV

    $version = Text::CSV::Unicode->VERSION();	# get the module version

    $csv = Text::CSV::Unicode->new();	# create a new object

    $status = $csv->combine(@columns);	# combine columns into a string
    $line = $csv->string();		# get the combined string

    $status = $csv->parse($line);	# parse a CSV string into fields
    @columns = $csv->fields();		# get the parsed fields

    $status = $csv->status();		# get the most recent status
    $bad_argument = $csv->error_input();# get the most recent bad argument

=head1 DESCRIPTION

Text::CSV::Unicode provides facilities for the composition and
decomposition of comma-separated values, based on Text::CSV.
Text::CSV::Unicode allows for input with wide character data
but does not permit control characters.

=head1 Incompatible Changes

=head2 Option always_quote=>1 (v0.300)

Before v0.300, the module behaviour defaulted to 
C<< always_quote => 1 >> in Text::CSV.  
This behaviour was only needed in tests.

To recreate the old behaviour:

    $csv = Text::CSV::Unicode->new( { always_quote => 1 } );

=head1 DEPRECATED

The option C<< binary => 1 >> does not require this module.

This code issues a 'deprecated' warning and creates a 
Text::CSV object:

    $csv = Text::CSV::Unicode->new( { binary => 1 } );

=head1 METHODS

=over 4

=item VERSION

This function may be called as a class or an object method.
As a class method, it returns the currrent module version.
As an object method, it returns the version of the underlying
Text::CSV module.

=item version

An object method: it returns the backend module version. 

=item new

    $csv = Text::CSV::Unicode->new( [{ binary => 1 }] );

This function may be called as a class method.
It returns a reference to a newly created object.

C<< binary => 0 >> allows the same ASCII input as Text::CSV.

C<< binary => 1 >> allows for all Unicode
characters in the input (including \r and \n):
the same functionality as C<< Text::CSV->new( { binary => 1 } >>.

=item combine

    $status = $csv->combine(@columns);

This object function constructs a CSV string from the arguments,
returning success or failure.  Failure can result from lack of
arguments or an argument containing an invalid character.  

Silently accepts undef values in input and treats as an empty string.

=item parse

    $status = $csv->parse($line);

This object function decomposes a CSV string into fields, returning
success or failure.  Failure can result from a lack of argument or
the given CSV string is improperly formatted.  
Upon failure, the value returned by C<fields()> is undefined
and C<error_input()> can be called to retrieve the invalid argument.


=back

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

See HASH option to C<< ->new >>.

=head1 DEPENDENCIES

perl 5.8.0

Text::CSV 1.0

=head1 VERSION

0.400

=head1 AUTHOR

Robin Barker <rmbarker@cpan.org>

=head1 SEE ALSO

Text::CSV 

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, 2008, 2010, 2011, 2012, 2018 Robin Barker.  
All rights reserved. 

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The documentation of Text::CSV::Unicode methods that are inherited 
from Text::CSV is taken from Text::CSV 0.01 (with some reformatting) 
and is Copyright (c) 1997 Alan Citterman.

=cut

