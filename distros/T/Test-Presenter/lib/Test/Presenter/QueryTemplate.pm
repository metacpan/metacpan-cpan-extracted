=head1 NAME

Test::Presenter::QueryTemplate - A submodule for Test::Presenter
    This module provides methods for opening and inputting both Template
    and Configuration files.  The loaded files are then "merged" to create
    DBXml queries.

=head1 SYNOPSIS

    $report->open_template("/path/to/template/files", "report.tmpl");

    or

    $report->open_template("report");

    $report->open_config("/path/to/config/file", "report.config");
    $report->process();
    $report->query_with_template("doc_name");
    $report->save_query("/path/to/saved/query", "filename.query");
    $report->load_query("/path/to/loaded/query", "filename.query");


=head1 DESCRIPTION

Test::Presenter::QueryTemplate is a helper module to give Test::Presenter the
    ability to query a DBXml Container with the use of preexisting
    Query Template files and a configured Query Configuration file.

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use Data::Dumper;
use IO::File;


=head2 open_template()

    Purpose: Read the Template file into the 'template' variable.
    Input: Template Path, Template Filename
    Output: 1

=cut
sub open_template {
    my $self = shift;
    my $pathname = '/usr/share/Test-Presenter/templates';
    my $filename = '';

    if ($#_ == 0){
        $filename = shift;
    } elsif ($#_ == 1){
        $pathname = shift or warn("open_template missing pathname\n") and return undef;
        $filename = shift or warn("open_template missing filename\n") and return undef;
    }

    # Open the query template and store it in a string for later...
    my $inFile = new IO::File ("< $pathname/$filename") || new IO::File ("< $pathname/$filename" . '.tmpl')
        or die "Cannot open Template File: $filename: $!\n";

    my $template_data = "";

    while (<$inFile>) {
        chomp;
        push @{$self->{'template'}}, $_ ;
    }
    $self->{'component'}{'report'}{'type'} = $filename;
    $self->{'component'}{'report'}{'type'} =~ s/\.tmpl//;

    return 1;
}


=head2 open_config()

    Purpose: Read the Configuration file into the 'config' variable.
    Input: Configuration Path, Configuration Filename
    Output: 1

=cut
sub open_config {
    my $self = shift;

    my $pathname = shift or warn("open_config missing pathname\n") and return undef;
    my $filename = shift or warn("open_config missing filename\n") and return undef;

    # Open the query template and store it in a string for later...
    my $inFile = new IO::File ("< $pathname/$filename")
        or die "Cannot open Config File: $filename: $!\n";

    while (<$inFile>) {
        chomp;
        push @{$self->{'config'}}, $_ ;
    }

    return 1;
}


=head2 process()

    Purpose: Merge the Configuration and Template files to produce
        Query Script.  The Query Script is then stored in the 'queries'
        variable.
    Input: NA
    Output: 1

=cut
sub process {
    my $self = shift;

    $self->_find_good_configs() or warn("Unable to find good configs\n") and return undef;

    $self->{'queries'} = ();
    $self->{'plaintext'} = "";

    # Get a config line
    foreach my $c_line (@{$self->{'config'}}) {
        # This will find all plaintext definitions found in a file which do not need template line
        if ( $c_line =~ m/[\D]*[\s]*=[\s]*\"/) {
            if ( $self->{'plaintext'} =~ m/($c_line)/ ) {
                ;
            }
            else {
                $self->{'plaintext'} .= $c_line . "\n";
            }

            # These last 3 lines are around for debugging information
            my ($key, $text) = split("=", $c_line, 2);
            warn "process() Key:  *" . $key . "*\n" if $self->{_debug}>2;
            warn "process() Text: *" . $text . "*\n" if $self->{_debug}>2;
            next;
        }
        # And a template line
        foreach my $t_line (@{$self->{'template'}}) {
            warn "\nprocess() Template: " . $t_line . "\tConfig: " . $c_line . "\n" if $self->{_debug}>4;
            # Here we are finding all "predefined" tags that should be included
            if ( $t_line =~ m/summary:/ && $c_line =~ m/summary[\s]*=[\s]*y/ ) {
                push @{$self->{'queries'}}, $t_line;
                last;
            }
            elsif ( $t_line =~ m/summary:/ && $c_line =~ m/summary[\s]*=[\s]*n/ ) {
                warn "process() Summary Not Wanted" if $self->{_debug}>2;
                last;
            }
            elsif ( $t_line =~ m/plot_title:/ && $c_line =~ m/plot_title[\s]*=[\s]*y/ ) {
                push @{$self->{'queries'}}, $t_line;
                last;
            }
            elsif ( $t_line =~ m/plot_title:/ && $c_line =~ m/plot_title[\s]*=[\s]*n/ ) {
                warn "process() Plot Title Not Wanted" if $self->{_debug}>2;
                last;
            }
            elsif ( $c_line =~ m/(\wdata|key_title)(\w+)\s*=\s*y\s*$/ and $t_line =~ m/^$2:.*/ ){
                # This is for _data_ queries in main schema like 'xdatakernel' for kernel.
                my ( $data ) = $c_line =~ m/(\wdata|key_title)\w+\s*=\s*y/;
                $t_line =~ s/\w+(\:.*)/$data$1/;
                push @{$self->{'queries'}}, $t_line;
                last;
            }
            else {
                # Split the config line into it's component parts (based on the
                # necessary logic....    <>=! but not &|   
                my ($key, $logic, $value) = $c_line =~ m/(.*?)\s*([<>=!]+)\s*(.*)/ or die;
                # We want our results ordered...
                if ( $key =~ m/^order/ ) {
                    my ($order, $dir, $attrib, $key2, $scrap) = split(" ", $key, 5) or die;
                    $key = $key2;    # For backwards compatibility with config files
                    warn "process() Key2: " . $key2 . " Dir: " . $dir . " Attrib: " . $attrib . "\n" if $self->{_debug}>5;
                }

                warn "process() Key=" . $key . "\tLogic: " . $logic . "\tValue: " . $value . "\n" if $self->{_debug}>4;

                # If we find our "key" inside of the template line,
                # then we replace the value.
                my $alpha_key = $key;
                $alpha_key =~ s/[0-9]//;
                $alpha_key =~ s/[\s]//g;
                warn "process() Non-Numeric Key = *" . $alpha_key . "*\n" if $self->{_debug}>4;
                if ( $key =~ m/^(\wdata)$/ and $t_line =~ m/\%${1}id/ ){
                     # This is for converting field names to id's and adding the constraints.
                     my ($label) = $value =~ m/(\w+)\s*/;
                     my $id = $self->data_get_id($label);
                     if ( ! defined $id ) { warn "Cannot create query from $label\n"; return undef; }
                     $alpha_key .= 'id';
                     # Now process each constraint, no parentheses yet.
                     if ( $value =~ m/ and /i){
                         my $next_value = $value;
                         $next_value =~  s/$label\s+//;
                         my $first = 1;
                         my $constraint_string="[";
                         my ($andorlogic, $constraint_field, $my_logic, $my_value);
                         while ( defined $next_value and $next_value =~ m/^(and|or)\s/ ){
                             no warnings;
                             ($andorlogic, $constraint_field, $my_logic, $my_value, $next_value) = $next_value =~ m/(and|or)\s+(.*?)([<>=!]+)(.*?)\s*((and |or ).*)*$/i;
                             warn "Building Constraints:  $andorlogic, $constraint_field, $my_logic, $my_value\n" if $self->{_debug}>2;
                             warn "Next Constraint(s):  $next_value\n" if $self->{_debug}>2;
                             use warnings;
                             if ( ! $first ){
                                  $constraint_string .= " $andorlogic ";
                             }
                             my $id2 = $self->data_get_id($constraint_field);
                             if ( ! defined $id2 ) { warn "Cannot create query from $label\n"; return undef; }
                             if ($my_value=~ m/^[\d\.]+$/){
                                 # No quotes for numbers
                                 $constraint_string .= "\(d$my_logic$my_value and d/\@id=$id2\)";
                             } else {
                                 $constraint_string .= "\(d$my_logic\"$my_value\" and d/\@id=$id2\)";
                             }
                             $first = 0;
                         }
                         $constraint_string .= "]";
                         $t_line =~ s/(.*datum)(.*)/$1$constraint_string$2/;
                     }
                     $value = $id;
                }
                if ( $t_line =~ m/\%$alpha_key/ ) {
                    my $te_temp = $t_line;
                    
                    $te_temp =~ s/(\"*)\%$alpha_key/$logic $1$value/g;
                    
                    my $template_at;
                    if ($value =~ m/and/ || $value =~ m/or/) {
                        warn "Value contains an _and_ or an _or_: *" . $value . "*\n" if $self->{_debug}>4;
                        $t_line =~ m/\[(\@[\w]+)([\s]+)/;
                        $template_at = $1;
                        warn "Template At: *" . $template_at . "*\n" if $self->{_debug}>4;
                        $te_temp =~ s/and[\s]+/and $template_at/g;
                        $te_temp =~ s/or[\s]+/or $template_at/g;
                    }

                    warn "process() Final Query: " . $te_temp . "\n" if $self->{_debug}>3;
                    push @{$self->{'queries'}}, $key . ":" . $logic . ":" . $te_temp;
                    last;
                }
            }
        }
    }
    
    warn "process() Plaintexts:\n" . $self->{'plaintext'} . "\n" if $self->{_debug}>1;

    return 1;
}


=head2 query_with_template()

    Purpose: Execute the Query Script on the DBXml object. After being
        executed, the results will be pushed into the 'component' object.
    Input: NA
    Output: 1

=cut
sub query_with_template {
    my $self = shift;
    
    my $doc = shift;
    
    my %query_results = ();

    foreach my $line (@{$self->{'queries'}}) {
        # _create_query will return the key that is involved, too
        my ($fullQuery, $key) = $self->_create_query($line, $doc);
        if (defined($fullQuery)) {
            warn "query_with_template() FullQuery: " . $fullQuery . "\n    Key:  " . $key . "\n" if $self->{_debug}>3;

            $query_results{$key} = $self->_doQuery( $self->{'manager'}, 
                                                    $self->{'container'}, 
                                                    "$fullQuery");
            my @res_array = ();

            my $val;
            my $res_count=0;
            my $prev_val = "";

            # Loop until we run out of results for each key
            while ( $query_results{$key}->next($val) ) {
                $val =~ s/{}name=//g;
                $val =~ s/{}units=//g;
                $val =~ s/\"//g;

                warn "query_with_template() Returned Value: " . $val . "\n" if $self->{_debug}>5;
                
                # This ensures that we don't push duplicate values into the array (good for labels and units)
                if ( $prev_val eq $val && !($key =~ m/data/) ) {
                }
                else {
                    push(@res_array, $val);
                }

                $prev_val = $val;
                $res_count++;
            }

            warn "query_with_template() Results: " . "@res_array" . "\n" if $self->{_debug}>2;
            if ( $key =~ m/plot_title/ ){
                $self->{'component'}{'report'}{$key} = \@res_array;
                delete  $self->{'component'}{'report'}{"item$self->{'item_count'}"}{$key};
            } else {
                $self->{'component'}{'report'}{"item$self->{'item_count'}"}{$key} = \@res_array;
            }
        }
    } # End ForEach

    $self->_process_plaintext() or warn("Unable to process plaintext configurations\n") and return undef;

    $self->_recursive_replace() or warn("Unable to recursively replace configurations\n") and return undef;

    $self->{'item_count'}++;

    return 1;
}

# _create_query()
#
# Purpose: To create a query capable of being exec'd on the Database
# Input: Line from queries list and document to query
# Output: string or undef
#
sub _create_query() {
    my $self = shift;
    
    # This is awesome... what's the query... and on what document (if any)?
    my $line = shift;
    my $doc = shift;

    my ($key, $logic, $query) = split(":", $line, 3);

    # If the query isn't set, we only split 2 things.  Adjust accordingly.
    if ( !defined($query) ) {
        $query = $logic;
    }

    # These error out if split only goes twice
    if(defined($key)) { warn "\n_create_query() Key:\t" . $key . "\n" if $self->{_debug}>2; }
    if(defined($query)) { warn "_create_query() Query:\t" . $query . "\n" if $self->{_debug}>2; }
    if(defined($logic)) { warn "_create_query() Logic:\t" . $logic . "\n" if $self->{_debug}>2; }

    $key =~ s/[\s]//g;

    # Here we are removing the unwanted 'id', 'name', and 'units' text
    # These are all necessary to make the configuration files work properly
    # We don't want this in our perl object, so we kill it here.

    if ( $key =~ m/^\/\*/ ) {
        warn "_create_query() OnlyKey:\t" . $key . "\n" if $self->{_debug}>2;
        my $temp_query = "";
        if ( defined($doc) ) {
            $temp_query = qq|doc(|;
            $temp_query .= qq|"$self->{'container_name'}/$doc"|;
        }
        else {
            $temp_query .= qq|collection(|;
            $temp_query .= qq|"$self->{'container_name'}"|;
        }
            
        $temp_query .= qq|)$key|;
        
        return $temp_query;
    }
    # This removes the 'id', 'name' or 'units' from the configuration file key
    # This helps make our perl data structure more consistent
    elsif ($key =~ m/(id|name|units)$/ ) {
        $key =~ s/(id|name|units)$//g;
        warn "_create_query() Replace ID or Name or Units Key:\t" . $key . "\n" if $self->{_debug}>2;
    }
    else {
        warn "_create_query() Clean Key:\t" . $key . "\n" if $self->{_debug}>2;
    }

    # We don't treat the replacement queries like the rest of them, so weed
    # them out now
    if ( $key =~ m/^r=/ ) {
        warn "_create_query() Pushing replacement query: " . $query . "\n" if $self->{_debug}>2;
        $key =~ s/^r=//;

        $self->{'component'}{'report'}{"item$self->{'item_count'}"}{$key} = $query;
        return undef;
    }        
    else {
        my $prefix = "";
        my $order_by = "";
            
        my $temp_query = "";

        # Just in case we don't want to query a doc
        if ( defined($doc) ) {
            $temp_query = qq|doc(|;
            $temp_query .= qq|"$self->{'container_name'}/$doc"|;
        }
        else {
            $temp_query .= qq|collection(|;
            $temp_query .= qq|"$self->{'container_name'}"|;
        }
            
        $temp_query .= qq|)$query|;
            
        # Sort _all_ these by id
        if ( $key =~ m/\wdata/){
            my $dir = 'ascending';
            $prefix = qq|for \$temp in (|;
            $order_by = qq|) order by xs:decimal(\$temp/\@id) $dir return \$temp|;
            # The 'datum' assures that this substitution doe not happen on i.e. 'xdatakernel'
            $temp_query =~ s/(^.*datum.*)(\/d.*?$)/$prefix$1$order_by$2/;
        }
            
        warn "_create_query() Full Query:\t" . $temp_query . "\n" if $self->{_debug}>2;
        return $temp_query, $key;
    }
}


=head2 save_query()

    Purpose: To save the processed query script to a file so that it
        may be used later
    Input: Pathname and Filename
    Output: 1 or undef

=cut
sub save_query() {
    my $self = shift;
    my $pathname = shift or warn("save_query missing pathname\n") and return undef;
    my $filename = shift or warn("save_query missing filename\n") and return undef;

    # Open the query template
    my $outFile = new IO::File ("> $pathname/$filename")
        or die "Cannot open the file $filename for reading: $!\n";

    # Here we take each line from our 'queries', and put them into the file
    foreach my $line (@{$self->{'queries'}}) {
        print $outFile $line . "\n";
    }

    # Close the file to safety's sake
    close ($outFile);

    return 1;
}


=head2 load_query()

    Purpose: To load a processed query script from a file
    Input: Pathname and Filename
    Output: 1 or undef

=cut
sub load_query()
{
    my $self = shift;
    my $pathname = shift or warn("load_query missing pathname\n") and return undef;
    my $filename = shift or warn("load_query missing filename\n") and return undef;

    $self->{'queries'} = ();

    # Open the query template
    my $inFile = new IO::File ("< $pathname/$filename")
        or die "Cannot open the file $filename for reading: $!\n";

    my $qs = "";

    # Here we take each line from the file, and place it in our 'queries' object
    while (<$inFile>) {
        chomp;
        push @{$self->{'queries'}}, $_;
    }

    # Close the file to safety's sake
    close ($inFile);

    return 1;
}

# _process_plaintext()
#
# Purpose: To automatically place plaintext config entries directly into
#          the report->item object
# Input: None
# Output: 1
sub _process_plaintext {
    my $self = shift;

    # If it's empty or has a newline, take it.  Otherwise, return undef and fail.
    return undef unless ( $self->{'plaintext'} =~ /\n/ || $self->{'plaintext'} eq "" );

    my @texts = split("\n", $self->{'plaintext'});
    
    foreach my $l (@texts) {
        my ($key, $target) = split("[<>=!&|]+", $l, 2);
        warn "_process_plaintext() Plain_Key:    *" . $key . "*\n" if $self->{_debug}>3;
        warn "_process_plaintext() Plain_Target: *" . $target . "*\n" if $self->{_debug}>3;

        # Strip off the newlines and extra quotes before setting us up the bomb
        $target =~ s/^\"(.*)\"$/$1/;
        $target =~ s/\n//;

        if ($key =~ m/plot_title/){
            $self->{'component'}{'report'}->{$key} = $target;
            delete  $self->{'component'}{'report'}{"item$self->{'item_count'}"}{$key}->{$key};
        } else {
            $self->{'component'}{'report'}{"item$self->{'item_count'}"}{$key} = $target;
        }

        warn "_process_plaintext() Finished Key:    *" . $key . "*\n" if $self->{_debug}>3;
        warn "_process_plaintext() Finished Target: *" . $target . "*\n" if $self->{_debug}>3;
    }

    return 1;
}

# _recursive_replace()
#
# Purpose: To find all instances of one variable, and replace it with a value
#          based on various template and configuration file properties
# Input: None
# Output: 1
sub _recursive_replace {
    my $self = shift;
    my $current_item = $self->{'component'}{'report'}{"item$self->{'item_count'}"};

    # We pushed the "recursive replacements" into the perl data structure
    # Now we have to take care of them
    foreach my $key (keys %{ $current_item }) {
        my $target = $current_item->{$key};
        warn "_recursive_replace() Recurse_Key:    *" . $key . "*\n" if $self->{_debug}>3;
        warn "_recursive_replace() Recurse_Target: *" . $target . "*\n" if $self->{_debug}>3;
        # Are there actually any '%keyword%' fields to be replaced ?
        unless ( $target =~ m/\%.*\%/ or ( ref($target) =~ m/ARRAY/ and $target->[0] =~ m/\%.*\%/ ) ){ 
            next; 
        }
        
        my $val;
        foreach my $key2 (keys %{ $current_item }) {
            $val = $current_item->{$key2};

            if ( defined($val) && defined($target) ) {
                warn "_recursive_replace() Key: " . $key2 . " Data: " . $val . "\n" if $self->{_debug}>3;
                if ( ref($val) ) {
                    # This needs to be done for arrays. We assume a
                    # replacement takes the first index in the array. FIXME
                    $target =~ s/\%$key2\%/$val->[0]/;
                }
                else {
                    $target =~ s/\%$key2\%/$val/;
                }
                warn "_recursive_replace() New target: " . $target . "\n" if $self->{_debug}>3;
            }
            else {
                warn "asd: " . $key2 . "\n" if $self->{_debug}>3;
            }
            undef($val);
        }

        $target =~ s/\n//;

        if ($key =~ m/plot_title/){
            $self->{'component'}{'report'}->{$key} = $target;
            delete  $current_item->{$key};
        } else {
            $current_item->{$key} = $target;
        }

        warn "_recursive_replace() Finished Key:    *" . $key . "*\n" if $self->{_debug}>3;
        warn "_recursive_replace() Finished Target: *" . $target . "*\n" if $self->{_debug}>3;
    }

    return 1;
}

# _find_good_configs()
#
# Purpose: To find all configuration lines, and to force plaintext config
#          definitions to override template replacements
# Input: None
# Output: 1
sub _find_good_configs {
    my $self = shift;

    my $count = 0;
    
    foreach my $l (@{$self->{'config'}}) {
        if ( $l =~ m/^\s*#/){
            # Get rid of comments
            warn "_find_good_configs() Removing [$count] line:  " . $self->{'config'}->[$count] . "\n\n" if $self->{_debug}>2;
            delete $self->{'config'}->[$count];
            next;
        }
        # First logical operator cannot have & or |
        my ($key, $logic, $target) = $l =~ m/^\s*(.*?)\s*([<>=!]+)\s*(.*?)\s*$/;
        
        if ( !defined($key) || !defined($target) || !defined($logic) ) {
            warn "Invalid Config Line: " . $l . "\n" if $self->{_debug}>1;
            die "This is not a config line: $l";
        }
        else {
            warn "_find_good_configs() Key:    " . $key . "\n" if $self->{_debug}>2;
            warn "_find_good_configs() Target: " . $target . "\n" if $self->{_debug}>2;
            warn "_find_good_configs() Logic:  " . $logic . "\n\n" if $self->{_debug}>2;

            # We may add other checks later
            # This is to clean up spaces
            $self->{'config'}->[$count] = $key . $logic . $target;
            warn "_find_good_configs() Config line:  " . $self->{'config'}->[$count] . "\n\n" if $self->{_debug}>2;
            $count += 1;
        }
    }

    return 1;
}

1;
