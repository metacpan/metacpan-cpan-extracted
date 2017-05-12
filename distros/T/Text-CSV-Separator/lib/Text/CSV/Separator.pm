package Text::CSV::Separator;

use 5.008;
use strict;
use warnings;
use Carp qw(carp croak);

our $VERSION = '0.20';

use Exporter;
use base 'Exporter';
our @EXPORT_OK = qw(get_separator);


sub get_separator {
    
    my %options = @_;
    
    my $file_path = $options{path};
    
    # check options
    my $echo;
    if ($options{echo}) {
        $echo = 1;
        print "\nDetecting field separator of $file_path\n";
    }
    
    my (@excluded, @included);
    if (exists $options{exclude}) {
        @excluded = @{$options{exclude}};
    }
    
    if (exists $options{include}) {
        @included = @{$options{include}};
    }
    
    my ($lucky, $colon_timecol, $comma_decsep, $comma_groupsep);
    if (exists $options{lucky} && $options{lucky} == 1) {
        $lucky = 1;
        print "Scalar context...\n\n" if $echo;
    } else {
        $colon_timecol = $comma_decsep = $comma_groupsep = 1;
        print "List context...\n\n" if $echo;
    }
    
    # options checked
    
    # Default set of candidates
    my @candidates = (',', ';', ':', '|', "\t");
    
    my %survivors;
    $survivors{$_} = [] foreach (@candidates);
    
    if (@excluded > 0) {
        foreach (@excluded) {
            delete $survivors{$_};
            _message('deleted', $_) if $echo; 
        }
    }
    
    if (@included > 0) {
        foreach (@included) {
            if (length($_) == 1) {
                $survivors{$_} = [];
            }
            _message('added', $_) if $echo;
        }
    }
    
    if (keys %survivors == 0) {
        carp "No candidates left!";
        return;
    }
    
    my $csv;
    open ($csv, "<:crlf", $file_path) || croak "Couldn't open $file_path: $!";
    
    my $record_count = 0; # if $echo
    while (<$csv>) {
        my $record = $_;
        chomp $record;
        
        if ($echo) {
            $record_count++;
            print "\nRecord #$record_count\n";
        }
        
        foreach my $candidate (keys %survivors) {
            _message('candidate', $candidate) if $echo;
            
            my $rex = qr/\Q$candidate\E/;
            
            my $count = 0;
            $count++ while ($record =~ /$rex/g);
            
            print "Count: $count\n" if $echo;
            
            if ($count > 0 && !$lucky) {
                push @{$survivors{$candidate}}, $count;
            } elsif ($count == 0) {
                delete $survivors{$candidate};
            }
            
        }
        
        if (!$lucky) {
            $colon_timecol = _regularity($record, 'timecol') if $colon_timecol;
            $comma_decsep = _regularity($record, 'decsep') if $comma_decsep;
            $comma_groupsep = _regularity($record, 'groupsep') if $comma_groupsep;
        }
        
        
        my @alive = keys %survivors;
        my $survivors_count = @alive;
        if ($survivors_count == 1) {
            if ($echo) {
                _message('detected', $alive[0]);
                print "Returning control to caller...\n\n";
            }
            close $csv;
            if (!$lucky) {
                return @alive;
            } else {
                return $alive[0];
            }
        } elsif ($survivors_count == 0) {
                carp "\nNo candidates left!\n";
                return;
        }
    }
    
    #  More than 1 survivor. 2nd pass to determine count variability
    if ($lucky) {
        print "\nSeveral candidates left\n" if $echo;
        carp "\nBad luck. Couldn't determine the separator of $file_path.\n";
        return;
    } else {
        print "\nVariability:\n\n" if $echo;
        my %std_dev;
        foreach my $candidate (keys %survivors) {
            my $mean = _mean(@{$survivors{$candidate}});
            $std_dev{$candidate} = _std_dev($mean, @{$survivors{$candidate}});
            if ($echo) {
                _message('candidate', $candidate);
                print "Mean: $mean\tStd Dev: $std_dev{$candidate}\n\n";
            }
        }
    
        print "Couldn't determine the separator\n" if $echo;
            
        close $csv;
        
        my @penalized;
        if ($colon_timecol) {
            print "Detected time column\n" if $echo;
            delete $survivors{':'};
            push @penalized, ':';
        }
        
        if ($comma_decsep || $comma_groupsep) {
            delete $survivors{','};
            push @penalized, ',';
            if ($echo && $comma_decsep) {
                print "\nDetected comma-separated decimal numbers column\n";
            }
            if ($echo && $comma_groupsep) {
                print "\nDetected comma-grouped numbers column\n";
            }
        }
        
        my @alive = sort {$std_dev{$a} <=> $std_dev{$b}} keys %survivors;
        push @alive, sort {$std_dev{$a} <=> $std_dev{$b}} @penalized;
        if ($echo) {
            print "Remaining candidates: ";
            foreach my $left (@alive) {
                _message('left', $left);
            }
            print "\n\nReturning control to caller...\n\n";
        }
        return @alive;
    }
}

sub _mean {
    my @array = @_;
    
    my $sum = 0;
    $sum += $_ foreach (@array);
    
    my $mean = $sum / scalar(@array);
    
    return $mean;
}

sub _std_dev {
    my ($mean, @array) = @_;
    
    my $sum = 0;
    $sum += ($_ - $mean)**2 foreach (@array);
    
    my $std_dev = sqrt( $sum / scalar(@array) );
    
    return $std_dev;
}

sub _regularity {
    my ($string, $kind) = @_;
    
    my $time_rx = qr/
                        (?:^|(?<=\s|[T,;|\t]))
                        (?:[01]?[0-9]|2[0-3])   # hours
                        :
                        (?:[0-5][0-9])          # minutes  
                        (?::[0-5][0-9])?        # seconds
                        (?:
                            Z
                            |
                            \.\d+
                            |
                            (?:\+|-)
                            (?:[01]?[0-9]|2[0-3])
                            :
                            (?:[0-5][0-9])
                        )?
                        (?=$|\s|[,;|\t])
                    /x;
    
    my $commadecsep_rx = qr/
                                (?:^|(?<=[^\d,.]))
                                (?:
                                    [-+]?
                                    (?:
                                        \d{0,3}?(?:\.\d{3})*
                                        |
                                        \d+
                                    )
                                    ,\d+
                                )
                                (?=$|[^\d,.])
                            /x;
    
    my $commagroupsep_rx = qr/
                                (?:^|(?<=[^\d,.]))
                                (?:
                                    [-+]?\d{0,3}?
                                    (?:,\d{3})+
                                    (?:\.\d+)?
                                )
                                (?=$|[^\d,.])
                             /x;
                             
    
    return 0 if ($kind eq 'timecol' && $string !~ /$time_rx/);
    return 0 if ($kind eq 'decsep' && $string !~ /$commadecsep_rx/);
    return 0 if ($kind eq 'groupsep' && $string !~ /$commagroupsep_rx/);
    
    return 1;
}

sub _message {
    my ($type, $candidate) = @_;
    
    my $char;
    if (ord $candidate == 9) { # tab character
        $char = "\\t";
    } else {
        $char = $candidate;
    }
    
    my %message = (
                   deleted => "Deleted $char from candidates list\n",
                   added => "Added $char to candidates list\n",
                   candidate => "Candidate: $char\t",
                   detected => "\nSeparator detected: $char\n",
                   left => " $char ",
                  );
    
    print $message{$type};
}

1;

__END__


=head1 NAME

Text::CSV::Separator - Determine the field separator of a CSV file

=head1 VERSION

Version 0.20 - November 2, 2008

=head1 SYNOPSIS

    use Text::CSV::Separator qw(get_separator);
    
    my @char_list = get_separator(
                                    path    => $csv_path,
                                    exclude => $array1_ref, # optional
                                    include => $array2_ref, # optional
                                    echo    => 1,           # optional
                                 );
    
    my $separator;
    if (@char_list) {
        if (@char_list == 1) {           # successful detection
            $separator = $char_list[0];
        } else {                         # several candidates passed the tests
            # Some code here
    } else {                             # no candidate passed the tests
        # Some code here
    }
    
    
    # "I'm Feeling Lucky" alternative interface
    # Don't forget to include the 'lucky' parameter
    
    my $separator = get_separator(
                                    path    => $csv_path,
                                    lucky   => 1, 
                                    exclude => $array1_ref, # optional
                                    include => $array2_ref, # optional
                                    echo    => 1,           # optional
                                 );
    


=head1 DESCRIPTION

This module provides a fast detection of the field separator character (also
called field delimiter) of a CSV file, or more generally, of a character
separated text file (also called delimited text file), and returns it ready
to use in a CSV parser (e.g., Text::CSV_XS, Tie::CSV_File, or
Text::CSV::Simple). 
This may be useful to the vulnerable -and often ignored- population of
programmers who need to process automatically CSV files from different sources.

The default set of candidates contains the following characters:
','  ';'  ':'  '|'  '\t'

The only required parameter is the CSV file path. Optionally, the user can
specify characters to be excluded or included in the list of candidates. 

The routine returns an array containing the list of candidates that passed
the tests. If it succeeds, this array will contain only one value: the field
separator we are looking for. On the other hand, if no candidate survives
the tests, it will return an empty list.

The technique used is based on the following principle:

=over 8

=item *

For every line in the file, the number of instances of the separator
character acting as separators must be an integer constant > 0 , although
a line may also contain some instances of that character as
literal characters.

=item *

Most of the other candidates won't appear in a typical CSV line.

=back

As soon as a candidate misses a line, it will be removed from the candidates
list.

This is the first test done to the CSV file. In most cases, it will detect the
separator after processing the first few lines. In particular, if the file
contains a header line, one line will probably be enough to get the job done.
Processing will stop and return control to the caller as soon as the program
reaches a status of 1 single candidate (or 0 candidates left).

If the routine cannot determine the separator in the first pass, it will do
a second pass based on several heuristic techniques. It checks whether the
file has columns consisting of time values, comma-separated decimal numbers,
or numbers containing a comma as the group separator, which can lead to false
positives in files that don't have a header row. It also measures the
variability of the remaining candidates.
Of course, you can always create a CSV file capable of resisting the siege,
but this approach will work correctly in many cases. The possibility of
excluding some of the default candidates may help to resolve cases with
several possible winners.
The resulting array contains the list of possible separators sorted by their
likelihood, being the first array item the most probable separator.

The module also provides an alternative interface with a simpler syntax,
which can be handy if you think that the files your program will have
to deal with aren't too exotic. To use it you only have to add the
B<lucky =E<gt> 1> key-value pair to the parameters hash and the routine
will return a single value, so you can assign it directly to a scalar variable.
If no candidate survives the first pass, it will return C<undef>.
The code skips the 2nd pass, which is usually unnecessary, so the program
won't store counts and won't check any existing regularities. Hence, it will
run faster and will require less memory. This approach should be enough in
most cases.

=head1 FUNCTIONS

=over 4

=item C<get_separator(%options)>

Returns an array containing the field separator character (or characters, if
more than one candidate passed the tests) of a CSV file. In case no candidate
passes the tests, it returns an empty list.

The available parameters are:

=over 8

=item * C<path>

Required. The path to the CSV file.

=item * C<exclude>

Optional. Array containing characters to be excluded from the candidates list.

=item * C<include>

Optional. Array containing characters to be included in the candidates list.

=item * C<lucky>

Optional. If selected, get_separator will return one single character,
or C<undef> in case no separator is detected. Off by default.

=item * C<echo>

Optional. Writes to the standard output messages describing the actions
performed. Off by default.
This is useful to keep track of what's going on, especially for debugging
purposes.

=back

=back

=head1 EXPORT

None by default.

=head1 EXAMPLE

Consider the following scenario: Your program must process a batch of csv files,
and you know that the separator could be a comma, a semicolon or a tab.
You also know that one of the fields contains time values. This field will
provide a fixed number of colons that could mislead the detection code.
In this case, you should exclude the colon (and you can also exclude the other
default candidate not considered, the pipe character):

    my @char_list = get_separator(
                                    path    => $csv_path,
                                    exclude => [':', '|'],
                                 );
    
    if (@char_list) {
        my $separator;
        if (@char_list == 1) {       
            $separator = $char_list[0];
        } else { 
            # Some code here
        }
    }
    
    
    # Using the "I'm Feeling Lucky" interface:
    
    my $separator = get_separator(
                                    path    => $csv_path,
                                    lucky   => 1,
                                    exclude => [':', '|'],
                                  );
    

=head1 MOTIVATION

Despite the popularity of XML, the CSV file format is still widely used
for data exchange between applications, because of its much lower overhead:
It requires much less bandwidth and storage space than XML, and it also has
a better performance under compression (see the References below).

Unfortunately, there is no formal specification of the CSV format.
The Microsoft Excel implementation is the most widely used and it has become
a I<de facto> standard, but the variations are almost endless.

One of the biggest annoyances of this format is that in most cases you don't
know a priori what is the field separator character used in a file.
CSV stands for "comma-separated values", but most of the spreadsheet
applications let the user select the field delimiter from a list of several
different characters when saving or exporting data to a CSV file.
Furthermore, in a Windows system, when you save a spreadsheet in Excel as a
CSV file, Excel will use as the field delimiter the default list separator of
your system's locale, which happens to be a semicolon for several European
languages. You can even customize this setting and use the list separator you
like. For these and other reasons, automating the processing of CSV files is a
risky task.

This module can be used to determine the separator character of a delimited
text file of any kind, but since the aforementioned ambiguity problems occur
mainly in CSV files, I decided to use the Text::CSV:: namespace.

=head1 REFERENCES

L<http://www.creativyst.com/Doc/Articles/CSV/CSV01.htm>

L<http://www.xml.com/pub/a/2004/12/15/deviant.html>

=head1 SEE ALSO

There's another module in CPAN for this task, Text::CSV::DetectSeparator,
which follows a different approach.

=head1 ACKNOWLEDGEMENTS

Many thanks to Xavier Noria for wise suggestions.
The author is also grateful to Thomas Zahreddin, Benjamin Erhart, Ferdinand Gassauer,
and Mario Krauss for valuable comments and bug reports.

=head1 AUTHOR

Enrique Nell, E<lt>perl_nell@telefonica.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Enrique Nell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut


