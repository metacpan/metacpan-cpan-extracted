package Text::CSV::Slurp;

use strict;
use warnings;

use Text::CSV;
use IO::File;
use IO::Scalar;

use vars qw/$VERSION/;

$VERSION = 1.03;

sub new {
  my $class = shift;
  return bless {}, $class;
}

sub load {
  my $class  = shift;
  my %opt    = @_;

  my %default = ( binary => 1 );
  %opt = (%default, %opt);

  my $io;
  if (defined $opt{filehandle}) {
    $io = $opt{filehandle};
    delete $opt{filehandle};
  }
  elsif (defined $opt{file}) {
    $io = new IO::File;
    open($io, "<$opt{file}") || die "Could not open $opt{file} $!";
    delete $opt{file};
    return _from_handle($io,\%opt);
  }
  elsif (defined $opt{string}) {
    $io = IO::Scalar->new(\$opt{string});
    delete $opt{string};
  }
  else {
    die "Need either a file, filehandle or string to work with";
  }
  return _from_handle($io,\%opt);
}

sub create {
    my ( undef, %arg ) = @_;

    die "Need an an array of hashes input to create CSV from"
        unless exists $arg{input} &&
               ref( $arg{input} ) eq 'ARRAY' &&
               ref( @{ $arg{input} }[0] ) eq 'HASH';

    my $list = $arg{input};
    delete $arg{input};

    # get the field names
    my @names = defined $arg{field_order}
              ? @{ $arg{field_order} }
              : sort keys %{ $list->[0] };

    delete $arg{field_order};

    %arg = ( binary => 1, %arg );

    my $csv = Text::CSV->new( \%arg );

    unless ( $csv->combine( @names ) ) {
        die "Failed to create the header row because of this invalid input: " . $csv->error_input;
    }

    my @string = $csv->string;

    for my $row ( @$list ) {
        my @data;
        for my $name ( @names ) {
            push @data, $row->{$name};
        }

        unless ( $csv->combine( @data ) ) {
            die "Failed to create a data row because of this invalid input: " . $csv->error_input;
        }

        push @string, $csv->string;
    }

    return join "\n", @string;
}

sub _from_handle {
  my $io  = shift;
  my $opt = shift;

  my $csv = Text::CSV->new($opt);

  if ( my $head = $csv->getline($io) ) {
    $csv->column_names( $head );
  }
  else {
    die $csv->error_diag();
  }

  my @results;
  while (my $ref = $csv->getline_hr($io)) {
    push @results, $ref;
  }

  return \@results;
}

return qw/Open hearts and empty minds/;

=pod

=encoding UTF-8

=head1 NAME

Text::CSV::Slurp - Text::CSV::Slurp - convert CSV into an array of hashes, or an array of hashes into CSV

=head1 VERSION

version 1.03

=head1 SUMMARY

I often need to take a CSV file that has a header row and turn it into
a perl data structure for further manipulation. This package does that
in as few steps as possible.

I added a C<create> method in version 0.8 because sometimes you just
want to create some bog standard CSV from an array of hashes.

=head1 USAGE

 use Text::CSV::Slurp;
 use strict;

 # load data from CSV input

 my $data = Text::CSV::Slurp->load(file       => $filename   [,%options]);
 my $data = Text::CSV::Slurp->load(filehandle => $filehandle [,%options]);
 my $data = Text::CSV::Slurp->load(string     => $string     [,%options]);

 # create a string of CSV from an array of hashes
 my $csv  = Text::CSV::Slurp->create( input => \@array_of_hashes [,%options]);

=head1 METHODS

=head2 new

 my $slurp = Text::CSV::Slurp->new();

Instantiate an object.

=head2 load

  my $data = Text::CSV::Slurp->load(file => $filename);
  my $data = $slurp->load(file => $filename);

Returns an arrayref of hashrefs. Any extra arguments are passed to L<Text::CSV>.
The first line of the CSV is assumed to be a header row. Its fields are
used as the keys for each of the hashes.

=head2 create

 my $csv = Text::CSV::Slurp->create( input => \@array_of_hashes [,%options]);
 my $csv = $slurp->create( input => \@array_of_hashes [,%options]);

 my $file = "/path/to/output/file.csv";

 open( FH, ">$file" ) || die "Couldn't open $file $!";
 print FH $csv;
 close FH;

Creates CSV from an arrayref of hashrefs and returns it as a string. All optional
arguments are passed to L<Text::CSV> except for C<field_order>.

=head3 field_order

C<field_order> which is used to determine the fields and order in which they
appear in the CSV. For example:

 my $csv = Text::CSV::Slurp->create( input => \@array_of_hashes,
                                     field_order => ['one','three','two'] );

If field_order is not supplied then the sorted keys of the first hash in the
input are used instead.

=head1 DEPENDENCIES

L<Text::CSV>

L<IO::File>

L<Test::Most> - for tests only

=head1 LICENCE

GNU General Public License v3

=head1 SOURCE

Available at L<https://github.com/babf/Text-CSV-Slurp>

=head1 SEE ALSO

L<Text::CSV>

L<Spreadsheet::Read>

=head1 THANKS

To Kyle Albritton for suggesting and testing the L<create> method
To Tomas Pokorny for the L<IO::Scalar> patch for the L<load> method

=head1 AUTHOR

BABF <babf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by BABF.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Text::CSV::Slurp - convert CSV into an array of hashes, or an array of hashes into CSV

