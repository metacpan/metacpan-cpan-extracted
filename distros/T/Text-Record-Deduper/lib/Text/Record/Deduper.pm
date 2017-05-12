=head1 NAME

Text::Record::Deduper - Separate complete, partial and near duplicate text records

=head1 SYNOPSIS

    use Text::Record::Deduper;

    my $deduper = new Text::Record::Deduper;

    # Find and remove entire lines that are duplicated
    $deduper->dedupe_file("orig.txt");

    # Dedupe comma separated records, duplicates defined by several fields
    $deduper->field_separator(',');
    $deduper->add_key(field_number => 1, ignore_case => 1 );
    $deduper->add_key(field_number => 2, ignore_whitespace => 1);
    # unique records go to file names_uniqs.csv, dupes to names_dupes.csv
    $deduper->dedupe_file('names.csv');

    # Find 'near' dupes by allowing for given name aliases
    my %nick_names = (Bob => 'Robert',Rob => 'Robert');
    my $near_deduper = new Text::Record::Deduper();
    $near_deduper->add_key(field_number => 2, alias => \%nick_names) or die;
    $near_deduper->dedupe_file('names.txt');

    # Create a text report, names_report.txt to identify all duplicates
    $near_deduper->report_file('names.txt',all_records => 1);

    # Find 'near' dupes in an array of records, returning references 
    # to a unique and a duplicate array
    my ($uniqs,$dupes) = $near_deduper->dedupe_array(\@some_records);

    # Create a report on unique and duplicate records
    $deduper->report_file("orig.txt",all_records => 0);


=head1 DESCRIPTION

This module allows you to take a text file of records and split it into 
a file of unique and a file of duplicate records. Deduping of arrays is
also possible.

Records are defined as a set of fields. Fields may be separated by spaces, 
commas, tabs or any other delimiter. Records are separated by a new line.

If no options are specifed, a duplicate will be created only when all the
fields in a record (the entire line) are duplicated.

By specifying options a duplicate record is defined by which fields or partial 
fields must not occur more than once per record. There are also options to 
ignore case sensitivity, leading and trailing white space.

Additionally 'near' or 'fuzzy' duplicates can be defined. This is done by creating
aliases, such as Bob => Robert.

This module is useful for finding duplicates that have been created by
multiple data entry, or merging of similar records


=head1 METHODS

=head2 new

The C<new> method creates an instance of a deduping object. This must be
called before any of the following methods are invoked.

=head2 field_separator

Sets the token to use as the field delimiter. Accepts any character as well as
Perl escaped characters such as "\t" etc.  If this method ins not called the 
deduper assumes you have fixed width fields .

    $deduper->field_separator(',');


=head2 add_key

Lets you add a field to the definition of a duplicate record. If no keys
have been added, the entire record will become the key, so that only records 
duplicated in their entirity are removed.

    $deduper->add_key
    (
        field_number => 1, 
        key_length => 5, 
        ignore_case => 1,
        ignore_whitespace => 1,
        alias => \%nick_names
    );

=over 4

=item field_number

Specifies the number of the field in the record to add to the key (1,2 ...). 
Note that this option only applies to character separated data. You will get a 
warning if you try to specify a field_number for fixed width data.

=item start_pos

Specifies the position of the field in characters to add to the key. Note that 
this option only applies to fixed width data. You will get a warning if you 
try to specify a start_pos for character separated data. You must also specify
a key_length.

Note that the first column is numbered 1, not 0.


=item key_length

The length of a key field. This must be specifed if you are using fixed width 
data (along with a start_pos). It is optional for character separated data.

=item ignore_case 

When defining a duplicate, ignore the case of characters, so Robert and ROBERT
are equivalent.

=item ignore_whitespace

When defining a duplicate, ignore white space that leasd or trails a field's data.

=item alias

When defining a duplicate, allow for aliases substitution. For example

    my %nick_names = (Bob => 'Robert',Rob => 'Robert');
    $near_deduper->add_key(field_number => 2, alias => \%nick_names) or die;

Whenever field 2 contains 'Bob', it will be treated as a duplicate of a record 
where field 2 contains 'Robert'.

=back


=head2 dedupe_file

This method takes a file name F<basename.ext> as it's only argument. The file is
processed to detect duplicates, as defined by the methods above. Unique records
are place in a file named  F<basename_uniq.ext> and duplicates in a file named 
F<basename_dupe.ext>. Note that If either of this output files exist, they are 
over written The orignal file is left intact.

    $deduper->dedupe_file("orig.txt");


=head2 dedupe_array

This method takes an array reference as it's only argument. The array is
processed to detect duplicates, as defined by the methods above. Two array
references are retuned, the first to the set of unique records and the second 
to the set of duplicates.

Note that the memory constraints of your system may prevent you from processing 
very large arrays.

    my ($unique_records,duplicate_records) = $deduper->dedupe_array(\@some_records);


=head2 report_file

This method takes a file name F<basename.ext> as it's initial argument. 

A text report is produced with the following columns

    record number : the line number of the record

    key : the key values that define record uniqueness

    type: the type of record
            unique    : record only occurs once
            identical : record occurs more than once, first occurence has parent record number of 0
            alias     : record occurs more than once, after alias substitutions have been applied

    parent record number : the line number of the record that THIS record is a duplicate of.

By default, the report file name is  F<basename_report.ext>.

Various  setup options may be defined in a hash that is passed as an optional argument to 
the C<report_file> method. Note that all the arguments are optional. They include

=over 4

=item all_records 

When this option is set to a positive value, all records will be included in
the report. If this value is not set, only the duplicate records will be included 
in the report 

=back


    $deduper->report_file("orig.txt",all_records => 0)

=head2 report_array

This method takes an array as it's initial argument. The behaviour is the same as
C<report_file> above except that the report file is named F<deduper_array_report.txt>

=head1 EXAMPLES

=head2 Dedupe an array of single records 

Given an array of strings:

    my @emails = 
    (
        'John.Smith@xyz.com',
        'Bob.Smith@xyz.com',
        'John.Brown@xyz.com.au,
        'John.Smith@xyz.com'
    );

    use Text::Record::Deduper;

    my $deduper = new Text::Record::Deduper();
    my ($uniq,$dupe);
    ($uniq,$dupe) = $deduper->dedupe_array(\@emails);

The array reference $uniq now contains

    'John.Smith@xyz.com',
    'Bob.Smith@xyz.com',
    'John.Brown@xyz.com.au'

The array reference $dupe now contains

    'John.Smith@xyz.com'


=head2 Dedupe a file of fixed width records 

Given a text file F<names.txt> with space separated values and duplicates defined 
by the second and third columns:

    100 Bob      Smith    
    101 Robert   Smith    
    102 John     Brown    
    103 Jack     White   
    104 Bob      Smythe    
    105 Robert   Smith    


    use Text::Record::Deduper;

    my %nick_names = (Bob => 'Robert',Rob => 'Robert');
    my $near_deduper = new Text::Record::Deduper();
    $near_deduper->add_key(start_pos =>  5, key_length => 9, ignore_whitespace => 1, alias => \%nick_names) or die;
    $near_deduper->add_key(start_pos => 14, key_length => 9,) or die;
    $near_deduper->dedupe_file("names.txt");
    $near_deduper->report_file("names.txt");


Text::Record::Deduper will produce a file of unique records, F<names_uniqs.txt>
in the same directory as F<names.txt>.

    101 Robert   Smith    
    102 John     Brown    
    103 Jack     White   
    104 Bob      Smythe    
       

and a file of duplicates, F<names_dupes.txt> in the same directory as F<names.txt>

    100 Bob      Smith    
    105 Robert   Smith   

The original file, F<names.txt> is left intact.

A report file F<names_report.txt>, is created in the same directory as F<names.txt>

    Number Key                            Type       Parent Parent Key                    
    --------------------------------------------------------------------------------
         1 Bob_Smith                      alias           2 Robert_Smith                  
         2 Robert_Smith                   identical       0                               
         3 John_Brown                     unique          0                               
         4 Jack_White                     unique          0                               
         5 Bob_Smythe                     unique          0                               
         6 Robert_Smith                   identical       2 Robert_Smith                  


=head1 TO DO

    Allow for multi line records
    Add batch mode driven by config file or command line options
    Allow option to warn user when over writing output files
    Allow user to customise suffix for uniq and dupe output files


=head1 SEE ALSO

sort(3), uniq(3), L<Text::ParseWords>, L<Text::RecordParser>, L<Text::xSV>


=head1 AUTHOR

Text::Record::Deduper was written by Kim Ryan <kimryan at cpan d o t org>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Kim Ryan. 


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

package Text::Record::Deduper;
use FileHandle;
use File::Basename;
use Text::ParseWords;
use Data::Dumper;



use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '0.07';


#-------------------------------------------------------------------------------
# Create a new instance of a deduping object. 

sub new
{
    my $class = shift;
    my %args = @_;

    my $deduper = {};
    bless($deduper,$class);

    # Default to no separator, until we find otherwise
    $deduper->{field_separator} = '';

    return ($deduper);
}
#-------------------------------------------------------------------------------
# Create a new instance of a deduping object. 

sub field_separator
{
    my $deduper = shift;

    my ($field_separator) = @_;

    # Escape pipe symbol so it does get interpreted as alternation character
    # when splitting fields in _get_key_fields
    $field_separator eq '|' and $field_separator = '\|';

    # add more error checking here

    $deduper->{field_separator} = $field_separator;
    return($deduper);
}
#-------------------------------------------------------------------------------
# Dewfine a key field in  the record 
sub add_key
{
    my $deduper = shift;
    my %args = @_;


    $deduper->{key_counter}++;

    if ( $args{field_number} )
    {
        unless ( $deduper->{field_separator} )
        {
            warn "Cannot use field_number on fixed width lines";
            return;
        }
    }
    elsif ( $args{start_pos} )
    {
        if ( $deduper->{field_separator} )
        {
            warn "Cannot use start_pos on character separated records";
            return;
        }
        else
        {
            unless ( $args{key_length} )
            {
                warn "No key_length defined for start_pos: $args{start_pos}";
                return;
            }
        }
    }

    foreach my $current_key (keys %args)
    {
        if ($current_key eq 'ignore_case' )
        {
            $deduper->{ignore_case}{$deduper->{key_counter}} = 1;
        }
        if ($current_key eq 'ignore_whitespace' )
        {
            $deduper->{ignore_whitespace}{$deduper->{key_counter}} = 1;
        }
        if ($current_key eq 'alias' )
        {
            if ( $args{ignore_case} )
            {
                # if ignore case, fold all of alias to upper case
                my %current_alias = %{ $args{$current_key} };
                my %corrected_alias;
                foreach my $current_alias_key ( keys %current_alias )
                {
                    $corrected_alias{uc($current_alias_key)} = uc($current_alias{$current_alias_key});
                    
                }
                $deduper->{alias}{$deduper->{key_counter}} = \%corrected_alias;
            }
            else
            {
                $deduper->{alias}{$deduper->{key_counter}} = $args{$current_key};
            }
        }
        if ($current_key =~ /field_number|start_pos|key_length/ )
        {
            $deduper->{key}{$deduper->{key_counter}}{$current_key} = $args{$current_key};
        }
    }

    return ($deduper);
}
#-------------------------------------------------------------------------------
# 
sub dedupe_file
{
    my $deduper = shift;
    my ($input_file_name) = @_;

    unless ( -T $input_file_name and -s $input_file_name )
    {
        warn("Could not find input file: $input_file_name"); 
        return(0);
    }

    my $input_fh = new FileHandle "<$input_file_name";
    unless ($input_fh)
    {
        warn "Could not open input file: $input_file_name";
        return(0);
    }

    my ($file_name,$path,$suffix) = File::Basename::fileparse($input_file_name,qr{\..*});
    my $file_name_unique_records    = "$path$file_name\_uniqs$suffix";
    my $file_name_duplicate_records = "$path$file_name\_dupes$suffix";

    # TO DO!!! test for overwriting of previous Deduper output
    my $unique_fh = new FileHandle ">$file_name_unique_records";
    unless($unique_fh)
    {
        warn "Could not open file: $file_name_unique_records: $!";
        return(0);
    }

    my $dupes_fh = new FileHandle ">$file_name_duplicate_records";
    unless ( $dupes_fh )
    {
        warn "Could not open file: $file_name_duplicate_records: $!";
        return(0);
    }

    my ($master_record_index) = $deduper->_analyse('file',undef,$input_fh);
    $deduper->_separate('file',$master_record_index,undef,$input_fh,$unique_fh,$dupes_fh);

    $input_fh->close;
    $unique_fh->close;
    $dupes_fh->close;
}
#-------------------------------------------------------------------------------

sub _rewind_file
{
    my ($input_fh) = @_;
    $input_fh->seek(0,0); # rewind file
}
#-------------------------------------------------------------------------------
#                  
sub dedupe_array
{
    my $deduper = shift;

    my ($input_array_ref) = @_;
    my ($master_record_index) = $deduper->_analyse('array',$input_array_ref,undef);
    my ($uniq_array_ref,$dupe_array_ref) = $deduper->_separate('array',$master_record_index,$input_array_ref,undef);

    return($uniq_array_ref,$dupe_array_ref);
}
#-------------------------------------------------------------------------------
#  Produce a text report on deduping statistics                
sub report_file
{

    my $deduper = shift;
    my ($input_file_name,%report_options) = @_;

    unless ( -T $input_file_name and -s $input_file_name )
    {
        warn("Could not find input file: $input_file_name"); 
        return(0);
    }

    my $input_fh = new FileHandle "<$input_file_name";
    unless ($input_fh)
    {
        warn "Could not open input file: $input_file_name";
        return(0);
    }

    my ($master_record_index_ref) = $deduper->_analyse('file',undef,$input_fh);

    my $report_file_name;
    if ( $report_options{file_name} )
    {
        # user has specified name and  path to report file
        $report_file_name = $report_options{file_name};
    }
    else
    {
        # use base of input file, append _report.txt to report file name
        my ($file_name,$path,$suffix) = File::Basename::fileparse($input_file_name,qr{\..*});
        $report_file_name = "$path$file_name\_report\.txt";
    }


    $deduper->_report($master_record_index_ref,$report_file_name,%report_options);
    $input_fh->close;

}
#-------------------------------------------------------------------------------
#                  
sub report_array
{

    my $deduper = shift;
    my ($input_array_ref,%report_options) = @_;

    my ($master_record_index_ref) = $deduper->_analyse('array',$input_array_ref,undef);

    my $report_file_name;
    if ( $report_options{file_name} )
    {
        # user has specified name and  path to report file
        $report_file_name = $report_options{file_name};
    }
    else
    {
        # TO DO, make name more unique, eg add time stamp
        $report_file_name = "./deduper_array_report.txt";
    }

    $deduper->_report($master_record_index_ref,$report_file_name,%report_options);

}
#-------------------------------------------------------------------------------
#                  
sub _report
{
    my $deduper = shift;
    my ($master_record_index_ref,$report_file_name,%report_options) = @_;

    
    my $report_fh = new FileHandle ">$report_file_name";
    unless($report_fh)
    {
        warn "Could not open report file: $report_file_name: $!";
        return(0);
    }

    # TO DO, report format, side be side or interleaved?
    # options, all records or dupes (default), group all dupes even first
    # full record dump, not just key

    my $current_line = sprintf("%6s %-30.30s %-10.10s %6s %-30.30s\n",
        'Number', 'Key','Type','Parent','Parent Key');
    $report_fh->print($current_line);
    $report_fh->print('-' x 80,"\n");

    foreach my $record_num ( sort { $a <=> $b } keys %$master_record_index_ref )
    {
        
        if ( $report_options{all_records} or 
             ($master_record_index_ref->{$record_num}->{type} ne 'unique' and 
              $master_record_index_ref->{$record_num}->{parent} > 0  ) )
        {
            my $parent_record_key = '';
            if ( $master_record_index_ref->{$record_num}->{parent} )
            {
                $parent_record_key = $master_record_index_ref->{$master_record_index_ref->{$record_num}->{parent}}->{key};
            }
            my $current_line = sprintf("%6d %-30.30s %-10.10s %6d %-30.30s\n",
                $record_num,
                $master_record_index_ref->{$record_num}->{key},
                $master_record_index_ref->{$record_num}->{type},
                $master_record_index_ref->{$record_num}->{parent},
                $parent_record_key);

            $report_fh->print($current_line);
        }
    }
    $report_fh->close;
}
#-------------------------------------------------------------------------------
#                  
sub _analyse
{
    my $deduper = shift;
    my ($storage_type,$input_array_ref,$input_fh) = @_;

    my $current_record_number = 0;
    my $current_line;
    my $finished = 0;


    my %alias_candidates;
    if ( $deduper->{alias} )
    {
        my %all_alias_values = $deduper->_get_all_alias_values;
        while ( not $finished )
        {
            ($current_line,$finished) = _read_one_record($storage_type,$current_record_number,$input_array_ref,$input_fh);
            $current_record_number++;
            my $alias_candidate_key = $deduper->_alias_candidate($current_line,%all_alias_values);
            if ( $alias_candidate_key and not $alias_candidates{$alias_candidate_key}  )
            {
                $alias_candidates{$alias_candidate_key} = $current_record_number;
            }
        }
    }
    # print(Dumper(\%alias_candidates));
    # die;

    my %seen_exact_dupes;
    my $unique_ref = [];
    my $dupe_ref = [];
    $current_record_number = 0;
    my %master_record_index;

    $finished = 0;
    if ( $storage_type eq 'file' and $deduper->{alias} )
    {
        _rewind_file($input_fh);
    }

    while ( not $finished )
    {
        ($current_line,$finished) = _read_one_record($storage_type,$current_record_number,$input_array_ref,$input_fh);
        $current_record_number++;

        my $dupe_type;
        my %record_keys = $deduper->_get_key_fields($current_line);
        

        %record_keys = $deduper->_transform_key_fields(%record_keys);
        my $full_key = _assemble_full_key(%record_keys);

        my $parent_record_number;
        if ( $parent_record_number = $deduper->_alias_dupe(\%alias_candidates,%record_keys) )
        {
            $dupe_type = 'alias';
        }
        # add soundex dupe
        # add string approx dupe
        elsif ( $parent_record_number = _exact_dupe($current_line,$full_key,%seen_exact_dupes) )
        {
            $dupe_type = 'identical';
        }
        else
        {
            $dupe_type = 'unique';
            # retain the record number of dupe, useful for detailed reporting and grouping
            $seen_exact_dupes{$full_key} = $current_record_number;
            $parent_record_number = 0;
        }

        _classify_record($dupe_type,$parent_record_number,$current_record_number,$full_key,\%master_record_index);
    }
    return(\%master_record_index);
    
}

#-------------------------------------------------------------------------------
sub _alias_candidate
{
    my $deduper = shift;
    my ($current_line,%all_alias_values) = @_;

    my %record_keys = $deduper->_get_key_fields($current_line);
    %record_keys = $deduper->_transform_key_fields(%record_keys);
    
    my $alias_candidate_key = '';
    foreach my $current_key ( sort keys %record_keys )  
    {

        my $current_key_data = $record_keys{$current_key};
        if ( $deduper->{alias}{$current_key} )
        {
            not $all_alias_values{$current_key} and next;
            if ( grep(/^$current_key_data$/,@{ $all_alias_values{$current_key} }) )
            {
                $alias_candidate_key .= $current_key_data . ':';
            }
            else
            {
                return(0);
            }
        }
        else
        {
            $alias_candidate_key .= $current_key_data . ':';
        }
    }
    return($alias_candidate_key); 
}
#-------------------------------------------------------------------------------
# 
sub _get_all_alias_values
{
    my $deduper = shift;

    my %all_alias_values;

    foreach my $key_number ( sort keys %{$deduper->{alias}} )
    {
        my %current_alias =  %{ $deduper->{alias}{$key_number} };
        my (@current_alias_values,%seen_alias_values);
        foreach my $current_alias_value ( values %current_alias )
        {
            unless ( $seen_alias_values{$current_alias_value} )
            {
                push(@current_alias_values,$current_alias_value);
                $seen_alias_values{$current_alias_value}++;
            }
        }
        $all_alias_values{$key_number}= [ @current_alias_values ];
    }
    return(%all_alias_values)
}

#-------------------------------------------------------------------------------
# 

sub _get_key_fields
{

    my $deduper = shift;
    my ($current_line) = @_;

    my %record_keys;


    if ( $deduper->{key} )
    {
        if ( $deduper->{field_separator} )
        {

            # The ParseWords module will not handle single quotes within fields, 
            # so add an escape sequence between any apostrophe bounded by a
            # letter on each side. Note that this applies even if there are no
            # quotes in your data, the module needs balanced quotes.        
            if (  $current_line =~ /\w'\w/ )
            {
                # check for names with apostrophes, like O'Reilly
                $current_line =~ s/(\w)'(\w)/$1\\'$2/g;
            }

            # Use ParseWords module to spearate delimited field. 
            # '0' option means don't return any quotes enclosing a field
            my (@field_data) = &Text::ParseWords::parse_line($deduper->{field_separator},0,$current_line);

        
            foreach my $key_number ( sort keys %{$deduper->{key}} )
            {
                my $current_field_data = $field_data[$deduper->{key}->{$key_number}->{field_number} - 1];
                unless ( $current_field_data )
                {
                    # A record has less fields then we were expecting, so no
                    # point searching for anymore.
                    print("Short record\n");
                    print("Current line : $current_line\n");
                    print("All fields   :", @field_data,"\n");
                    last;
                    # TO DO, add a warning if user specifies records that must have 
                    # a full set of fields??
                }

                if ( $deduper->{key}->{$key_number}->{key_length} )
                {
                    $current_field_data = substr($current_field_data,0,$deduper->{key}->{$key_number}->{key_length});
                }
                $record_keys{$key_number} = $current_field_data;
            }
        }
        else
        {
            foreach my $key_number ( sort keys %{$deduper->{key}} )
            {
                my $current_field_data = substr($current_line,$deduper->{key}->{$key_number}->{start_pos} - 1,
                    $deduper->{key}->{$key_number}->{key_length});
                if ( $current_field_data )
                {
                    $record_keys{$key_number} = $current_field_data;
                }
                else
                {
                    print("Short record\n");
                    print("Current line : $current_line\n");
                    last;
                    # TO DO, add a warning if user specifies records must have 
                    # a full set of fields??
                }
            }
        }
    }
    else
    {
        # no key fileds defined, use whole line as key
        $record_keys{1} = $current_line;
    }
    return(%record_keys);
}
#-------------------------------------------------------------------------------
# 

sub _transform_key_fields
{
    my $deduper = shift;
    my (%record_keys) = @_;

    if ( $deduper->{ignore_whitespace} )
    {
        foreach my $key_number ( keys %{$deduper->{ignore_whitespace}} )
        {
            # strip out leading and/or trailing whitespace
            $record_keys{$key_number} =~ s/^\s+//;
            $record_keys{$key_number} =~ s/\s+$//;
        }
    }

    if ( $deduper->{ignore_case} )
    {
        # Transform every field where ignore_case was specified

        foreach my $key_number ( keys %{$deduper->{ignore_case}} )
        {
            # If this key is case insensitive, fold data to upper case
            $record_keys{$key_number} = uc($record_keys{$key_number});
        }
    }
    return(%record_keys);
}
#-------------------------------------------------------------------------------
# 

sub _assemble_full_key
{
    my (%record_keys) = @_;
    my $full_key;
    my @each_key;
    foreach my $current_key ( sort keys %record_keys )
    {
        push(@each_key,$record_keys{$current_key});
    }
    $full_key = join('_',@each_key);
    return($full_key);

}
#-------------------------------------------------------------------------------
# 

sub _alias_dupe
{
    my $deduper = shift;
    my ($alias_candidates_ref,%record_keys) = @_;


    my $alias_dupe = 0;
    if ( $deduper->{alias} )
    {
        my $alias_was_substituted = 0;

        foreach my $key_number ( keys %{$deduper->{alias}} )
        {
            my %current_alias =  %{ $deduper->{alias}{$key_number} };
            foreach my $current_alias_key ( keys  %current_alias )
            {
                if ( $record_keys{$key_number} eq $current_alias_key )
                {
                    $alias_was_substituted = 1;
                    $record_keys{$key_number} = $current_alias{$current_alias_key};
                    last;
                }
            }
        }
        if ( $alias_was_substituted )
        {
            my $full_key;
            foreach my $current_key ( sort keys %record_keys )
            {
                $full_key .= $record_keys{$current_key} . ':';
            }
            if ( $alias_candidates_ref->{$full_key} )
            {
                $alias_dupe = $alias_candidates_ref->{$full_key};
            }
        }
    }
    # returns the number of the orignal unique record for which this current record is an alias dupe of
    return($alias_dupe);
}
#-------------------------------------------------------------------------------
# 

sub _exact_dupe
{
    my $deduper = shift;
    my ($full_key,%seen_exact_dupes) = @_;
    # problem with unitialized value, set to undef??
    if ( $seen_exact_dupes{$full_key} )
    {
        return($seen_exact_dupes{$full_key});
    }
    else
    {
        return(0);
    }
}

#-------------------------------------------------------------------------------
# 

sub _read_one_record
{
    my ($storage_type,$current_record_number,$input_array_ref,$input_fh) = @_;

    my $finished = 0;
    my $current_line;

    if ( $storage_type eq 'file' )
    {
        if ( $current_line = $input_fh->getline )
        {
            chomp($current_line);
            if ( $input_fh->eof )
            {
                $finished = 1;
            }
        }
        else
        {
            warn "Could not read line from input file";
            $finished = 1;
        }
    }
    elsif ( $storage_type eq 'array' )
    {
        $current_line =  @$input_array_ref[$current_record_number];
        my $last_element =  @$input_array_ref - 1;
        if ( $current_record_number == $last_element )
        {
            $finished = 1;
        }
        elsif ( $current_record_number > $last_element )
        {
            warn "You are trying to access beyond the input array boundaries";
            $finished = 1;
        }
    }
    else
    {
        warn "Illegal storage type";
        $finished = 1;
    }
    return($current_line,$finished);
}


#-------------------------------------------------------------------------------
# 

sub _classify_record
{
    my ($dupe_type,$parent_record_number,$current_record_number,$full_key,$master_record_index) = @_;
    $master_record_index->{$current_record_number}{key} = $full_key;
    $master_record_index->{$current_record_number}{parent} = $parent_record_number;
    $master_record_index->{$current_record_number}{type} = $dupe_type;

    # If there is a parent, update it now, so that is marked as the first
    # dupe in a set (of current type alias, indentical etc). Note that
    # a record can be parent to several record types, eg alias and indentical
    # Currently only updating from last child, but may want to record all in future. 

    if ( $parent_record_number )
    {
        $master_record_index->{$parent_record_number}{type} = $dupe_type;
        $master_record_index->{$parent_record_number}{parent} = 0;
    }
}

#-------------------------------------------------------------------------------
# 

sub _separate
{
    my $deduper = shift;
    my ($storage_type,$master_record_index_ref,$input_array_ref,$input_fh,$unique_fh,$dupes_fh) = @_;

    if ( $storage_type eq 'file' )
    {
        _rewind_file($input_fh);
    }

    my $unique_ref = [];
    my $dupe_ref = [];


    my $current_record_number = 0;
    my $current_line;
    my $finished = 0;


    while ( not $finished )
    {
        my $current_line;
        ($current_line,$finished) = _read_one_record($storage_type,$current_record_number,$input_array_ref,$input_fh);
        $current_record_number++;
        my $dupe_type = $master_record_index_ref->{$current_record_number}{type};
        my $parent_record_number = $master_record_index_ref->{$current_record_number}{parent};

        # The first duplicate in a set of 1 or more dupes (the parent), is treated as a unique record
        # TO DO!!! allow user to define this initial dupe as not unique, and group with it's childeren dupes
        # TO DO!!! separate out to alias, soundex dupes to their own file if needed
        if (  $parent_record_number == 0  )
        {
            $dupe_type = 'unique';
        }

        _write_one_record($storage_type,$dupe_type,$current_line,$unique_ref,$dupe_ref,$input_fh,$unique_fh,$dupes_fh);
    }
    return($unique_ref,$dupe_ref);

}
#-------------------------------------------------------------------------------
# 

sub _write_one_record
{
    my ($storage_type,$dupe_type,$current_line,$unique_ref,$dupe_ref,$input_fh,$unique_fh,$dupes_fh) = @_;

    if ( $storage_type eq 'file' )
    {

        if ( $dupe_type eq 'unique' )
        {
            $unique_fh->print("$current_line\n");
        }
        else
        {
            $dupes_fh->print("$current_line\n");
        }
    }
    elsif ( $storage_type eq 'array' )
    {
        if ( $dupe_type eq 'unique' )
        {
            push(@$unique_ref,$current_line);
        }
        else
        {
            # TO DO!!! separate out to alias, soundex dupes etc if needed
            push(@$dupe_ref,$current_line);
        }
    }
}


1;

