package Text::CSV::Merge;
{
  $Text::CSV::Merge::VERSION = '0.05';
}
# ABSTRACT: Fill in gaps in a CSV file from another CSV file

use Modern::Perl '2010';
use autodie;
use utf8;

use Moo 1.001000;
use Carp;
use IO::File;
use Text::CSV_XS;
use DBI; # for DBD::CSV
use Log::Dispatch;


has +logger => (
    is => 'lazy',
    builder => sub {
        Log::Dispatch->new(
            outputs => [
                [ 'File', autoflush => 1, min_level => 'debug', filename => 'merge.log', newline => 1, mode => '>>' ],
                #[ 'Screen', min_level => 'info', newline => 1 ],
            ],
        );        
    }
);

has +csv_parser => (
    is => 'lazy',
    builder => sub {
        Text::CSV_XS->new({ binary => 1, eol => $/ })
            or croak("Cannot use module Text::CSV_XS: " . Text::CSV_XS->error_diag());
    }
);

has +dbh => (
    is => 'lazy',
    # must return only a code ref
    builder => sub {    
        DBI->connect("dbi:CSV:", undef, undef, { 
            RaiseError => 1, 
            PrintError => 1, 
            f_ext => ".csv/r", 
            # Better performance with XS
            csv_class => "Text::CSV_XS", 
            # csv_null => 1, 
        }) or croak("Cannot connect to CSV file via DBI: $DBI::errstr");
    }
);

has base_file => (
    is => 'rw',
    required => 1,
    #allow external names to be different from class attribute
    init_arg => 'base',
    #validate it
    #isa => sub {},
    coerce => sub {
        my $base_fh = IO::File->new( $_[0], '<' ) or croak("Open file: '$_[0]' failed: $!");
        $base_fh->binmode(":utf8");
        
        return $base_fh;
    }
);

has merge_file => (
    # We use only the raw file name/path and do not create a FH here, unlike base_file().
    is => 'rw',
    init_arg => 'merge',
    required => 1
);

has output_file => (
    is => 'rw',
    init_arg => 'output',
    # an output file name is NOT required
    required => 0,
    default => 'merged_output.csv',
    coerce => sub {
        my $output_fh = IO::File->new( $_[0], '>' ) or croak("Open file: '$_[0]' failed: $!");
        $output_fh->binmode(":utf8");
        
        return $output_fh;
    }
);

has columns=> (
    is => 'rw',
    required => 1,
);    

has search_field => (
    is => 'rw',
    required => 1,
    init_arg => 'search'
    #,
    #isa => sub {
        # validate that search_field is one of the columns in the base file
        #die "Search parameter: '$_[0]' is not one of the columns: @{$self->columns}";
        #    unless ( $_[0] ~~ @{$self->columns} );
    #}
);

has first_row_is_headers => (
    is => 'rw',
    required => 1,
    #validate it
    isa => sub {
        # @TODO: there's got to be a better way to do this!
        croak("Option 'first_row_is_headers' must be 1 or 0") unless ( $_[0] =~ m{'1'|'0'}x || $_[0] == 1 || $_[0] == 0 );
    },
);

sub merge {
    my $self = shift;

    # validate that search_field is one of the columns in the base file
    croak("Search parameter: '$self->search_field' is not one of the columns: @{$self->columns}")
        unless ( scalar(grep { $_ eq $self->search_field } @{$self->columns}) );
        # Use scalar() to force grep to return the number of matches; 
        # 0 -> false for the 'unless' statement.
    
    $self->csv_parser->column_names( $self->columns );
        
    # Loop through the base file to find missing data
    #@TODO: make into $self->rows?
    my @rows;
    
    while ( my $row = $self->csv_parser->getline_hr( $self->base_file ) ) {
        # skip column names
        next if ($. == 1 and $self->first_row_is_headers);

        if ( $self->csv_parser->parse($row) ) {
            # keep a list of null columns in this row
            my @nulls;

            # might be slightly more efficient to use while()
            foreach my $key ( keys %{$row} ) {
                # which fields is this row missing?
                if ( $row->{$key} eq 'NULL' or $row->{$key} eq "" ) {
                    push @nulls, $key;

                    $self->logger->info("Missing data in column: $key for '$row->{$self->search_field}'");
                }
            }

            # make a hash of arrays
            if ( @nulls  ) {
                # search $merge_file for the missing data's row
                local $" = ','; # reset the list separator for array interpolation to suit SQL
                
                # To get the original case for the columns, specify the column
                # names rather than using SELECT *, since it normalizes to
                # lowercase, per:
                # http://stackoverflow.com/questions/3350775/dbdcsv-returns-header-in-lower-case
                my $sth = $self->dbh->prepare(
                    "select @{$self->columns} from $self->{merge_file} where $self->{search_field} = ?"
                ) or croak("Cannot prepare DBI statement: " . $self->dbh->errstr ());

                $sth->execute($row->{$self->search_field});
                
                while ( my $filler = $sth->fetchrow_hashref() ) {
                    foreach my $gap ( @nulls ) {
                        if (exists $filler->{$gap} and defined $filler->{$gap} and $filler->{$gap} ne "") {
                            $self->logger->info(
                                "Found Data: '$gap' = '$filler->{$gap}' for '$row->{$self->search_field}'"
                            );
                            
                            $row->{$gap} = $filler->{$gap};
                        } else {
                            $self->logger->info(
                                "Data not Found for column: '$gap' for '$row->{$self->search_field}' $self->{merge_file}"
                            );
                        }
                    }
                }        
                
                # Be efficient and neat!
                $sth->finish();
            }
            
            # insert the updated row as a reference; even if not processed, the 
            # row will still appear in the final output.
            push @rows, $row;
        } else {
            my $err = $self->csv_parser->error_input;
            $self->logger->error("Failed to parse line: $err");
        }
    }

    # Ensure we've processed to the end of the file
    $self->csv_parser->eof or $self->csv_parser->error_diag();

    # print does NOT want an actual array! Use a hash slice, instead:
    #$self->csv_parser->print($output_fh, [ @$_{@columns} ]) for @rows;
    #
    # Or, here I've switched to Text::CSV_XS's specific print_hr(), which 
    # is simply missing from the PP (Pure Perl) version.
    $self->csv_parser->print_hr($self->output_file, $_) for @rows;
    
    return 1;
};

sub DEMOLISH {
    my $self = shift;

    ## Clean up!
    $self->base_file->close();
    $self->output_file->close() or croak("Close 'output.csv' failed: $!");
    
    return;
}


1;

__END__

=pod

=head1 NAME

Text::CSV::Merge - Fill in gaps in a CSV file from another CSV file

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    my $merger = Text::CSV::Merge->new({
        base    => 'into.csv',
        merge   => 'from.csv',
        output  => 'output.csv',  # optional
        columns => [q/email name age/],
        search  => 'email',
        first_row_is_headers => 1  # optional
    });

    $merger->merge();
    
    ## Now, there is a new CSV file named 'merged_output.csv' by default, 
    #  in the same directory as the code which called C<$merger->merge();>.

=head1 DESCRIPTION

The use case for this module is when one has two CSV files of largely the same structure. Yet, the 'from.csv' has data which 'into.csv' lacks. 

In this initial release, Text::CSV::Merge only fills in empty cells; it does not overwrite data in 'into.csv' which also exists in 'from.csv'. 

=head2 Subclassing

Text::CSV::Merge may be subclassed. In the subclass, the following attributes may be overridden:

=over 4

=item *

C<csv_parser>

=item *

C<dbh>

=item *

C<logger>

=back

=head1 ATTRIBUTES

=head2 C<logger>

The logger for all operations in this module.

The logger records data gaps in the base CSV file, and records which data from the merge CSV file was used fill the gaps in the base CSV file.

=head2 C<csv_parser>

The CSV parser used internally is an immutable class property. 

The internal CSV parser is the XS version of Text::CSV: Text::CSV_XS. You may use Text::CSV::PP if you wish, but using any other parser which does not duplicate Text::CSV's API will probably not work without modifying the source of this module.

Text::CSV_XS is also used, hard-coded, as the parser for DBD::CSV. This is configurable, however, and may be made configurable by the end-user in a future release. It can be overridden in a subclass. 

=head2 C<dbh>

Create reusable DBI connection to the CSV data to be merged in to base file. 

This method is overridable in a subclass. A good use of this would be to merge data into an existing CSV file from a database, or XML file. It must conform to the DBI's API, however.

DBD::CSV is a base requirement for this module.

=head2 C<base_file>

The CSV file into which new data will be merged.

The base file is readonly, not read-write. This prevents accidental trashing of the original data.

=head2 C<merge_file>

The CSV file used to find data to merge into C<base_file>.

=head2 C<output_file>

The output file into which the merge results are written. 

I felt it imperative not to alter the original data files. I may make this a configurable option in the future, but wold likely set its default to 'false'.

=head2 C<columns>

The columns to be merged.

A column to be merged must exist in both C<base_file> and C<merge_file>. Other than that requirement, each file may have other columns which do not exist in the other.

=head2 C<search_field>

The column/field to match rows in C<merge_file>. 

This column must exist in both files and be identically cased.

=head2 C<first_row_is_headers>

1 if the CSV files' first row are its headers; 0 if not. 

If there are no headers, then the column names supplied by the C<columns> argument/property are applied to the columns in each file virtually, in numerical orders as they were passed in the list.

=head1 METHODS

=head2 C<merge()>

Main method and is public.

C<merge()> performs the actual merge of the two CSV files.

=head2 C<DEMOLISH()>

This method locally overrides a Moo built-in. 

It close out all file handles, which will only occur after a call to C<merge()>.

=head1 SEE ALSO

=over 4

=item *

L<Text::CSV_XS>

=back

=head1 AUTHOR

Michael Gatto <mgatto@lisantra.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Gatto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
