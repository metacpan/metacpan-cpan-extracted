=head1 NAME

Test::Parser - Base class for parsing log files from test runs, and
displays in an XML syntax.

=head1 SYNOPSIS

 use Test::Parser::MyTest;

 my $parser = new Test::Parser::MyTest;
 $parser->parse($text) 
    or die $parser->error(), "\n";
 printf("Num Errors:    %8d\n", $parser->num_errors());
 printf("Num Warnings:  %8d\n", $parser->num_warnings());
 printf("Num Executed:  %8d\n", $parser->num_executed());
 printf("Num Passed:    %8d\n", $parser->num_passed());
 printf("Num Failed:    %8d\n", $parser->num_failed());
 printf("Num Skipped:   %8d\n", $parser->num_skipped());

 printf("\nErrors:\n");
 foreach my $err ($parser->errors()) {
     print $err;
 }

 printf("\nWarnings:\n");
 foreach my $warn ($parser->warnings()) {
     print $warn;
 }

 print $parser->to_xml();

=head1 DESCRIPTION

This module serves as a common base class for test log parsers.  These
tools are intended to be able to parse output from a wide variety of
tests - including non-Perl tests.

The parsers also write the test data into the 'Test Result Publication
Interface' (TRPI) XML schema, developed by SpikeSource.  See
http://www.spikesource.com/testresults/index.jsp?show=trpi-schema

=head1 FUNCTIONS

=cut

package Test::Parser;

use strict;
use warnings;
use File::Basename;

use fields qw(
              code-convention-report
              coverage-report
              test
              num-datum
              num-column
              build
              root
              url
              release
              vendor
              license
              summary
              description
              platform
              kernel
              version
              testname
              type
              path
              name
              units
              warnings
              errors
              testcases
              num_passed
              num_failed
              num_skipped
              outdir
              format
              _debug
              );

use vars qw( %FIELDS $VERSION );
our $VERSION = '1.7';
use constant END_OF_RECORD => 100;

=head2 new()

Creates a new Test::Parser object.

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = bless {%FIELDS}, $class;

    $self->{path}          = 0;
    $self->{units}         = $class;
    $self->{version}       = $class;
    $self->{type}          = 'unit';
    $self->{warnings}      = [];
    $self->{errors}        = [];
    $self->{testcases}     = [];
    $self->{num_passed}    = 0;
    $self->{num_failed}    = 0;
    $self->{num_skipped}   = 0;
    $self->{outdir}        = '.';
    $self->{format}        = 'png';
    $self->{_debug}	   = 0;
    $self->{name}          = "";
    $class=~s/^Test::Parser:://;
    $self->{'testname'}    = $class;
    $self->{'num-column'}    = 0;
    $self->{'num-datum'}     = 0;
    $self->{build}         = 0;
    $self->{root}          = 0;
    $self->{release}       = 0;
    $self->{url}           = 0;
    $self->{vendor}        = 0;
    $self->{license}       = 0;
    $self->{summary}       = 0;
    $self->{description}   = 0;
    $self->{platform}      = 0;
    $self->{kernel}        = 0;
    $self->{'coverage-report'}=0;
    $self->{'code-convention-report'}=0;   
 
    return $self;
}

=head2 name()

Gets/sets name parameter. user-customizable identification tag

=cut

sub name {
    my $self = shift;
    my $my_name = shift;

    if ($my_name) {
        $self->{name} = $my_name;
    }

    return $self->{name};
}

=head2 testname()

Gets/sets testname parameter.

=cut

sub testname {
    my $self = shift;
    my $testname = shift;

    if ($testname) {
        $self->{testname} = $testname;
    }

    return $self->{testname};
}

sub version {
    my $self = shift;
    my $version = shift;

    if ( $version ) {
        $self->{version} = $version;
    }

    return $self->{version};
}

sub units {
    my $self = shift;
    my $units = shift;

    if ( $units ) {
        $self->{units} = $units;
    }

    return $self->{units};
}

=head2 to_xml

Method to print test result data from the Test::Parser object in xml format following the trpi schema. Find the trpi schema here: http://developer.osdl.org/~jdaiker/trpi_extended_proposal.xsd

=cut

sub to_xml {
    my $self = shift;
    my $xml = "";
    my $data = $self->data();
    my @required = qw(testname version description summary license vendor release url platform);
    my @fields   = qw(testname version description summary license vendor release url platform kernel root build coverage-report code-convention-report);

    foreach my $field (@required) {
        if( !$self->{$field} ) {
            print "Missing required field: $field\n";
            return undef;
        }
    }
    $xml .= qq|<component name='$self->{testname}' version='$self->{version}'>\n|;
    foreach my $field (@fields) {
        if ($self->{$field}) {
            #Special case for build / status
            if ($field eq 'build' && $self->{build_status}) {
                $xml .= qq| <build status='$self->{build_status}'>$self->{build}</build>\n|;
            }
            else {
                $xml .= qq| <$field>$self->{$field}</$field>\n|;
            }
        }
    }
    if( $self->{test} ){
        $xml .= qq| <test|;
        if( $self->{test}->{'log-filename'} ){
            $xml .= qq| log-filename=$self->{test}->{'log-filename'}|;
        }
        if( $self->{test}->{path} ){
            $xml .= qq| path=$self->{test}->{path}|;
        }
        if( $self->{test}->{'suite-type'} ){
            $xml .= qq| suite-type=$self->{test}->{'suite-type'}>\n|;
        }    
        else {
            $xml .= qq|>\n|;
        }
        if( $self->{test}->{data} ){
            $xml .= qq|  <data>\n|;
            if( $self->{test}->{data}->{columns} ){
                $xml .= qq|   <columns>\n|;

                my %column_hash=%{$self->{test}->{data}->{columns}};
                foreach my $column_key(sort {$a <=> $b} keys %column_hash){
                    if( $column_hash{$column_key}->{'name'} ){       
                        $xml .= qq|    <c id="$column_key" name="$column_hash{$column_key}->{'name'}"|;
                    }
                    if( $column_hash{$column_key}->{units} ){
                        $xml .= qq| units="$column_hash{$column_key}->{units}"|;
                    }
                    $xml .= qq|/>\n|;
                }
                $xml .= qq|   </columns>\n|;
            }
            if( $self->{test}->{data}->{datum} ){
                my %datum_hash=%{ $self->{test}->{data}->{datum} };                 
                foreach my $datum_key( sort {$a <=> $b} keys %datum_hash ){
                    $xml .= qq|   <datum id="$datum_key">\n|;
                    foreach my $key_val( sort {$a <=> $b} keys %{ $datum_hash{$datum_key} }){
                        if( $key_val ){
                            $xml .= qq|    <d id="$key_val">|;
                            if( $self->{test}->{data}->{datum}->{$datum_key}->{$key_val} ){
                                $xml .= qq|$self->{test}->{data}->{datum}->{$datum_key}->{$key_val}|;
                            }
                            $xml .= qq|</d>\n|;
                        }
                    }
                    $xml .= qq|   </datum>\n|;
                }       
            }
            $xml .= qq|  </data>\n|;
        }
        $xml .= qq| </test>\n|;
    }
    $xml .= qq|</component>\n|;
    return $xml;
}


=head2 add_column

A method that adds test column information into the data structure of the Test::Parser object appropriately. This is a helper method to be used from the parse_line method.

=cut
sub add_column { 
    my $self=shift;
    my $name=shift;
    my $units=shift;
    $self->{'num-column'}+=1;
    my $columnId = $self->{'num-column'};
    $self->{test}->{data}->{columns}->{$columnId}->{name}=$name;
    $self->{test}->{data}->{columns}->{$columnId}->{units}=$units;
    return $columnId;
}


=head2 add_data

A method that adds data values corresponding to a given column

=cut
sub add_data {
    my $self = shift;
    my $val = shift;
    my $col = shift;
    my $temp = 1;
    
    if ( defined($self->{'num-datum'}) ) {
        $temp += $self->{'num-datum'};
    }

    for(my $dumy=1; $dumy<($self->{'num-column'}+1); $dumy+=1){
        $self->{test}->{data}->{datum}->{$temp}->{$col}= $val;
    }
    return;
}


=head2 inc_datum

A method that increments the num-datum variable

=cut
sub inc_datum {
    my $self = shift;
    if ( defined($self->{'num-datum'}) ) {
        $self->{'num-datum'} += 1;
    }
    else {
        $self->{'num-datum'} = 1;
    }
    return $self->{'num-datum'};
}


=head2 to_dump()

Function to output all data, good for debuging

=cut
sub to_dump {
    my $self = shift;

    require Data::Dumper;
    print Data::Dumper->Dumper($self->{test});
}


=head2 set_debug($debug)

Turns on debug level.  Set to 0 or undef to turn off.

=cut
sub num_data {
    my $self =shift;
    if (@_) {
        $self->{num_columns} = @_;
    }
    return $self->{num_columns};
}

sub build {
    my $self =shift;
    if (@_) {
        $self->{build} = @_;
    }
    return $self->{build};
}

sub root {
    my $self =shift;
    if (@_) {
        $self->{root} = @_;
    }
    return $self->{root};
}
sub url {
    my $self =shift;
    if (@_) {
        $self->{url} = @_;
    }
    return $self->{url};
}

sub release {
    my $self =shift;
    if (@_) {
        $self->{release} = @_;
    }
    return $self->{release};
}

sub vendor {
    my $self =shift;
    if (@_) {
        $self->{vendor} = @_;
    }
    return $self->{vendor};
}

sub license {
    my $self =shift;
    if (@_) {
        $self->{license} = @_;
    }
    return $self->{license};
}

sub summary {
    my $self =shift;
    if (@_) {
        $self->{summary} = @_;
    }
    return $self->{summary};
}

sub description {
    my $self =shift;
    if (@_) {
        $self->{description} = @_;
    }
    return $self->{description};
}

sub platform {
    my $self =shift;
    if (@_) {
        $self->{platform} = @_;
    }
    return $self->{platform};
}

sub type {
    my $self =shift;
    if (@_) {
        $self->{type} = @_;
    }
    return $self->{type};
}

sub set_debug {
    my $self = shift;

    if (@_) {
        $self->{_debug} = shift;
    }

    return $self->{_debug};
}

=head3 type()

Gets or sets the testsuite type.  Valid values include the following:
unit, regression, load, integration, boundary, negative, stress, demo, standards

=cut

sub type_2 {
    my $self =shift;
    if (@_) {
        $self->{type} = @_;
    }
    return $self->{type};
}

sub path {
    my $self =shift;
    if (@_) {
        $self->{path} = @_;
    }
    return $self->{path};
}

sub warnings {
    my $self = shift;
    if (@_) {
        $self->{warnings} = shift;
    }
    $self->{warnings} ||= [];
    return $self->{warnings};
}

sub num_warnings {
    my $self = shift;
    return 0 + @{$self->warnings()};
}

sub errors {
    my $self = shift;
    if (@_) {
        $self->{errors} = shift;
    }
    $self->{errors} ||= [];
    return $self->{errors};
}

sub num_errors {
    my $self = shift;
    return 0 + @{$self->errors()};
}

sub testcases {
    my $self = shift;
    if (@_) {
        $self->{testcases} = shift;
    }
    $self->{testcases} ||= [];
    return $self->{testcases};
}

sub num_executed {
    my $self = shift;
    return 0 + @{$self->testcases()};
}

sub num_passed {
    my $self = shift;
    return $self->{num_passed};
}

sub num_failed {
    my $self = shift;
    return $self->{num_failed};
}

sub num_skipped {
    my $self = shift;
    return $self->{num_skipped};
}

sub format {
    my $self = shift;
    if (@_) {
        $self->{format} = shift;
    }
    return $self->{format};
}

sub outdir {
    my $self = shift;
    if (@_) {
        $self->{outdir} = shift;
    }
    return $self->{outdir};
}


=head2 get_key

    Purpose: To find individual key values parsed from test results
    Input: The search key, the 'datum' the key is stored in
    Output: Data stored under the search key, or the search key if not found

=cut
sub get_key {
    my $self = shift;
    my $key = shift or warn ("No search key specified");
    my $datum_id = shift or warn ("No datum id specified");

    my $col_id = undef;
    
    foreach my $id ( keys %{ $self->{test}->{data}->{columns} } ) {
        my $check_key = $self->{test}->{data}->{columns}->{$id}->{name};
        
        if( $self->{test}->{data}->{columns}->{$id}->{name} eq $key ) {
            $col_id = $id;
        }
    }
    
    if (defined($col_id)) {
        return $self->{test}->{data}->{datum}->{$datum_id}->{$col_id}
    }
    else {
        warn ("Unable to find key: " . $key . "\n");
        return $key;
    }
}


=head2 parse($input, [$name[, $path]])

Call this routine to perform the parsing process.  $input can be any of
the following:

    * A text string
    * A filename of an external log file to parse
    * An open file handle (e.g. \*STDIN)

If you are dealing with a very large file, then using the filename
approach will be more memory efficient.  If you wish to use this program
in a pipe context, then the file handle style will be more suitable.

This routine simply iterates over each newline-separated line of text,
calling _parse_line.  Note that the default _parse_line() routine does
nothing particularly interesting, so you will probably wish to subclass
Test::Parser and provide your own implementation of parse_line() to do
what you need.

The 'name' argument allows you to specify the log filename or other
indication of the source of the parsed data.  'path' allows specification
of the location of this file within the test run directory.  By default,
if $input is a filename, 'name' and 'path' will be taken from that, else
they'll be left blank.

If the filename contains multiple test records, parse() simply parses
the first one it finds, and then returns the constant
Test::Parser::END_OF_RECORD.  If your input file contains multiple
records, you probably want to call parse in the GLOB fashion.  E.g.,

    my @logs;
    open (FILE, 'my.log') or die "Couldn't open: $!\n";
    while (FILE) {
        my $parser = new Test::Parser;
        $parser->parse(\*FILE);
        push @logs, $parser;
    }
    close (FILE) or die "Couldn't close: $!\n";

=cut

sub parse {
    my $self = shift;
    my $input = shift or return undef;
    my ($name, $path) = @_;

    my $retval = 1;

    # If it's a GLOB, we're probably reading from STDIN
    if (ref($input) eq 'GLOB') {
        while (<$input>) {
            $retval = $self->parse_line($_) || $retval;
            last if $retval == END_OF_RECORD;
        }
    }
    # If it's a scalar and has newlines, it's probably the full text
    elsif (!ref($input) && $input =~ /\n/) {
        my @lines = split /\n/, $input;
        while (shift @lines) {
            $retval = $self->parse_line($_) || $retval;
            last if $retval == END_OF_RECORD;
        }
    }

    # If it appears to be a valid filename, assume we're reading an external file
    elsif (!ref($input) && -f $input) {
        $name ||= basename($input);
        $path ||= dirname($input);

        open (FILE, "< $input")
            or warn "Could not open '$input' for reading:  $!\n"
            and return undef;
        while (<FILE>) {
            $retval = $self->parse_line($_) || $retval;
            last if $retval eq END_OF_RECORD;
        }
        close(FILE);
    }
    $self->{path} = $path;

    return $retval;
}

=head2 parse_line($text)

Virtual function for parsing a line of test result data.  The base class' 
implementation of this routine does nothing interesting.

You will need to override this routine to customize it to your
application.  The parse() routine will call this iteratively for each
line of text in the test output file.

Returns undef on error.  The error message can be retrieved via error().

=cut

sub parse_line {
    my $self = shift;
    my $text = shift or return undef;

    return undef;
}


=head2 num_warnings()

The number of warnings found

=head2 warnings()

Returns a reference to an array of the warnings encountered.

=head2 num_errors()

The number of errors found

=head2 errors()

Returns a reference to an array of the errors encountered.

=head1 AUTHOR

Bryce Harrington <bryce@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2005 Bryce Harrington.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Test::Metadata>

=cut


1;

