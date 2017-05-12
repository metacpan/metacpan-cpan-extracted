package Text::CSV_PP::Simple;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.5');

use Text::CSV_PP;
use IO::File;

sub new {
    my $class = shift;
    return bless { _parser => Text::CSV_PP->new(@_), } => $class;
}

sub field_map {
    my $self = shift;
    if (@_) {
        $self->{_map} = [@_];
    }
    return @{ $self->{_map} || [] };
}

sub want_fields {
    my $self = shift;
    if (@_) {
        $self->{_wanted} = [@_];
    }
    return @{ $self->{_wanted} || [] };
}

sub read_file {
    my ($self, $file) = @_;
    
    my @result;
    my $csv = $self->{"_parser"};
    my $fh = IO::File->new($file, 'r') or croak $!;
    while (not $fh->eof) {
        my $cells = $csv->getline($fh);
        if (my @wanted = $self->want_fields){
            @{$cells} = @{$cells}[@wanted];
        }
        use Data::Dumper;
        print Dumper $cells;
        
        
        my $addition = $cells;
        if (my @map = $self->field_map ){
            my $hash = { map { $_ => shift @{$cells} } @map };
            delete $hash->{null};
            $addition = $hash;
        }
        push @result, $addition;
    }
    return @result;
}

1; 
__END__

=head1 NAME

Text::CSV_PP::Simple - Simpler parsing of CSV files [PP version]

=head1 VERSION

This document describes Text::CSV_PP::Simple version 0.0.5

=head1 SYNOPSIS

    use Text::CSV_PP::Simple;
    my $parser = Text::CSV_PP::Simple->new;
    my @data = $parser->read_file($datafile);
    print @$_ foreach @data;

    # Only want certain fields?
    my $parser = Text::CSV::Simple->new;
    $parser->want_fields(1, 2, 4, 8);
    my @data = $parser->read_file($datafile);

    # Map the fields to a hash?
    my $parser = Text::CSV_PP::Simple->new;
    $parser->field_map(qw/id name null town/);
    my @data = $parser->read_file($datafile);

=head1 DESCRIPTION

Text::CSV_PP::Simple simply provide a little wrapper around Text::CSV_PP to streamline the
common case scenario.

=head1 METHODS

=head2 new

    my $parser = Text::CSV_PP::Simple->new(\%options);

Construct a new parser. This takes all the same options as Text::CSV_PP.

=head2 field_map

    $parser->field_map(qw/id name null town null postcode/);

Rather than getting back a listref for each entry in your CSV file, you
often want a hash of data with meaningful names. If you set up a field_map
giving the name you'd like for each field, then we do the right thing
for you! Fields named 'null' vanish into the ether.

=head2 want_fields

    $parser->want_fields(1, 2, 4, 8);

If you only want to extract certain fields from the CSV, you can set up
the list of fields you want, and, hey presto, those are the only ones
that will be returned in each listref. The fields, as with Perl arrays,
are zero based (i.e. the above example returns the second, third, fifth
and ninth entries for each line)

=head2 read_file

    my @data = $parser->read_file($filename);

Read the data in the given file, parse it, and return it as a list of
data.

Each entry in the returned list will be a listref of parsed CSV data.

=head1 AUTHOR

Kota Sakoda  C<< <cohtan@cpan.org> >>

=head1 SEE ALSO

Text::CSV_XS, Text::CSV_PP, Text::CSV::Simple

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Kota Sakoda C<< <cohtan@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.