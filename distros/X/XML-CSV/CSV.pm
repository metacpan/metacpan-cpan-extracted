package XML::CSV;

use Text::CSV_XS;
use Carp;

#use strict;
BEGIN
{
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require 5.004;
require Exporter;
#require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter);# DynaLoader);

@EXPORT = qw(
	
);
$VERSION = '0.14';
};
#bootstrap XML::CSV $VERSION;

my $xml_xs_obj;  #Declared for global usage
my $csvxml_error;  #Error container


sub new($;$)
{
	
	my $class = shift;
	my $attr = shift || {};

	my $self =	{  	'error_out' => 0,
		   		'column_headings' => 0,
		   		'column_data' => 0,
		   		'csv_xs' => 0,
		   		%$attr
			};
		
	bless $self, $class;
	
	if ($attr->{csv_xs})  ### if custom Text::CSV_XS object is provided use it
	{
		$xml_xs_obj = $attr->{csv_xs};
		$attr->{csv_xs} = undef;
	} else {   	      ### else create our own Text::CSV_XS object with it's defaults
		$xml_xs_obj = Text::CSV_XS->new();
	}
	
		
		
	return $self;
	
}

sub parse_doc
{
	my $class = shift;
	my $file_name = shift || croak "Usage: parse_doc(file_name, [\%attr])";
	my $attr = shift;  # %attr (headings, sub_char)
	
	eval {open FILE_CSV, "$file_name";};
	
	$csvxml_error = "Couldn't open file: $file_name.  $@" if $@;
	
	croak "$csvxml_error" if ($class->{'error_out'} == 1 && $@);
				
	my @col_headings;
	
	$attr->{headings} = 0 unless (exists($attr->{headings}));  ### default headings to 0
	
	if ($attr->{headings} == 0)  ### No headings to be used from file
	{
		if ($class->{column_headings})
		{
			@col_headings = @{$class->{column_headings}};   ### if column_heading are provided
		} 			                                ### by user, use them
			
	}
	  			
	my $line;  ### declare $line outside of scope to be use later

	if ($attr->{headings} != 0)
	{		
		$line = <FILE_CSV>;
		my $cols_returned = $get_header->($line, \@col_headings, defined($attr->{sub_char})? $attr->{sub_char}:undef );
		$csvxml_error = "There were no columns returned for headers, please check your CSV file" if (!$cols_returned);
				
		croak "$csvxml_error" if ($class->{'error_out'} == 1);
					
		return 0 if (!$cols_returned);
	}                                                               	
	
	my @arr_cols_data;   ### declare @arr_cols_data to be used for stacking data
	
	while ($line = <FILE_CSV>)
	{
	
 	my @cols_data;
	my $status = $xml_xs_obj->parse($line);  ### parse line by line
	@cols_data = $xml_xs_obj->fields();  ### CSV_XS method returns data array for line passed
	$escape_char->(\@cols_data);
	push @arr_cols_data, \@cols_data;    ### stack the returned data
	
	}
	
	$class->{'column_headings'} = \@col_headings;  ### assign reference of @col_headings (xml headers) to object	
	$class->{'column_data'} = \@arr_cols_data;     ### assign reference of @arr_cols_data (xml data) to object

	close FILE_CSV;	

	return 1;
}

sub print_xml
{
	my $class = shift;
	my $file_out = shift || 0;
	my $args = shift || {};  # %attr (file_tag, parent_tag, format)
	
	$args->{file_tag} = "records" unless $args->{file_tag};  #default {parent_tag} to record if not supplied
	$args->{parent_tag} = "record" unless $args->{parent_tag}; 
	$args->{format} = "\t" unless $args->{format};  #default {format} to tab if not supplied
	
	$class->{'document_element'} = $args->{file_tag};  ### Used later for declare_doctype() method
	
	if ($class->{'column_data'} == 0 || ($class->{'column_headings'} == 0 && $class->{'headings'}))
	{
		croak "There is no data to print, make sure that you parsed the document before printing";
	}
	
	###Open file $file_out for output or output to STDOUT
	if ($file_out)
	{
		open FILE_OUT, ">$file_out";
	} else {
		*FILE_OUT = *STDOUT;
	}
	
	print FILE_OUT $class->{'declare_xml'}."\n" if $class->{'declare_xml'};
	###This will replace the non-interpolated $class->{'document_element'} inside the $class->{'declare_doctype'} to get the real value
	###Should be replace with something more practical in the future...
	$class->{'declare_doctype'} =~ s/\$class\-\>\{\'document_element\'\}/$class->{'document_element'}/ if $class->{'declare_doctype'};
	
	print FILE_OUT $class->{'declare_doctype'}."\n" if $class->{'declare_doctype'};
	print FILE_OUT "<$args->{file_tag}>", "\n";	### print initial document tag
		
	### declare the $tag for <$tag> and $loop_num for headers and data index tracking
	my $tag;
	my $loop_num;

	if ($#{$class->{'column_headings'}} > 0)  ### if column headings are provided
	{
	
		foreach $loop_num (0..$#{$class->{'column_data'}})
		{
			print FILE_OUT $args->{format}, "<$args->{parent_tag}>", "\n";
			foreach $tag (0..$#{$class->{'column_headings'}})
			{
				print FILE_OUT $args->{format}, $args->{format}, "<$class->{'column_headings'}[$tag]>$class->{'column_data'}[$loop_num][$tag]</$class->{'column_headings'}[$tag]>\n";
			}
			print FILE_OUT $args->{format}, "</$args->{parent_tag}>", "\n";
		}
	
	} else {  ### if column headings are not provided we default to <tr$loop_num>
		
		foreach $loop_num (0..$#{$class->{'column_data'}})
		{
	       		print FILE_OUT $args->{format}, "<$args->{parent_tag}>", "\n";
			foreach $tag (0..$#{$class->{'column_data'}->[$loop_num]})
			{
				print FILE_OUT $args->{format}, $args->{format}, "<tr$loop_num>$class->{'column_data'}[$loop_num][$tag]</tr$loop_num>\n";
			}
			print FILE_OUT $args->{format}, "</$args->{parent_tag}>", "\n";
		}
	}
	
	print FILE_OUT "</$args->{file_tag}>", "\n";  ### print the final document tag
	
	close FILE_OUT;
	
}


sub declare_xml
{

	my $class = shift;
	my $attr = shift || {};
	
	### Attributes: version, encoding, standalone

	if (exists $attr->{'version'})
	{
		$class->{'declare_xml'} = "<?xml version=\"$attr->{'version'}\"" 
	}
	else
	{
		$csvxml_error = "The version attribute must be specified for declare_xml()\n
				Usage: declare_xml\({version=>1.0, [encoding=>..., standalone=>yes/no]}\)";
		croak "$csvxml_error" if ($class->{'error_out'} == 1);		
	}
	
	$class->{'declare_xml'} .= " encoding=\"$attr->{'encoding'}\"" if exists $attr->{'encoding'};
	if (exists $attr->{'standalone'} && ($attr->{'standalone'} =~ /[yes|no]/))
	{
		$class->{'declare_xml'} .= " standalone=\"$attr->{'standalone'}\""; 
	}
	elsif (!($attr->{'standalone'} =~ /[yes|no]/))
	{
		$csvxml_error = "The standalone attribute must be yes|no for declare_xml()\n
				Usage: declare_xml\({version=>1.0, [encoding=>..., standalone=>yes/no]}\)";
		croak "$csvxml_error" if ($class->{'error_out'} == 1);
	}
	
	$class->{'declare_xml'} .= "?>";
		
	return $class->{'declare_xml'};

}

sub declare_doctype
{
	
	my $class = shift;
	my $attr = shift || {};
	
	### Attributes: source, location1, location2, subset

	$class->{'declare_doctype'} = '<!DOCTYPE $class->{\'document_element\'}';
	if ($attr->{source} eq "SYSTEM" || $attr->{source} eq "PUBLIC")
	{
		$class->{'declare_doctype'} .= " $attr->{'source'}";
	}
	else
	{
		$csvxml_error = "The source attribute is not set correctly";
		croak "$csvxml_error" if ($class->{'error_out'} == 1);
	}
	
	if (exists $attr->{location1} && !(exists $attr->{subset}))
	{
		$class->{'declare_doctype'} .= " \"$attr->{'location1'}\"";
	}
	else
	{
		$csvxml_error = "$attr->{'source'} location1 must be specified";
		croak "$csvxml_error" if ($class->{'error_out'} == 1);
	}
	
	$class->{'declare_doctype'} .= " \"$attr->{'location2'}\"" if exists $attr->{'location2'};
	$class->{'declare_doctype'} .= " [$attr->{'subset'}]" if exists $attr->{'subset'};
	
	
	$class->{'declare_doctype'} .= ">";
	
	return $class->{'declare_doctype'};
	
}

$get_header = sub()
{
	my $line = shift;
	my $ref_col = shift;
	my $sub_char = shift;
		
	my $status = $xml_xs_obj->parse($line);
	@$ref_col = $xml_xs_obj->fields();
	
	if (defined($sub_char))
	{
		map {s/^([^a-zA-Z|_|:]|((x|X)(m|M)(l|L)))/$sub_char/g;} @$ref_col;  #convert all beginning \n or \t or \s to '_'	
		map {s/[^a-zA-Z|^-|^.|^0-9|^:]/$sub_char/g;} @$ref_col;
	}
	
	#print __LINE__.": $ref_col->[0]\n";

	if ($ref_col) {return $#$ref_col;}else{return 0;}
};

$escape_char = sub()  ### Escape char per XML 1.0 specifications
{                     ### Needs to be optimized for faster processing
	
	my $arg = shift;
	if (ref($arg) eq 'ARRAY')
	{
		my $arr_index;
		foreach $arr_index (0..$#{$arg})
		{
			@{$arg}[$arr_index] =~ s/\&/\&amp\;/g;
			@{$arg}[$arr_index] =~ s/\</\&lt\;/g;
			@{$arg}[$arr_index] =~ s/\>/\&gt\;/g;
			@{$arg}[$arr_index] =~ s/\'/\&apos\;/g;
			@{$arg}[$arr_index] =~ s/\"/\&quot\;/g;
		}
	}
	elsif (ref($arg) eq 'SCALAR')
	{
		${$arg} =~ s/\&/\&amp\;/g;
		${$arg} =~ s/\</\&lt\;/g;
		${$arg} =~ s/\>/\&gt\;/g;
		${$arg} =~ s/\'/\&apos\;/g;
		${$arg} =~ s/\"/\&quot\;/g;
		${$arg} =~ s/([\x80-\xFF])/$XmlUtf8Encode->(ord($1))/ge;		
	}
	else
	{
		croak "Usage: $escape_char->(\@cols_data) or $escape_char->(\$foo)\n";
	}
		
};

$XmlUtf8Encode = sub() {

    my $n = shift;
    if ($n < 0x80) {
        return chr ($n);
    } elsif ($n < 0x800) {
        return pack ("CC", (($n >> 6) | 0xc0), (($n & 0x3f) | 0x80));
    } elsif ($n < 0x10000) {
        return pack ("CCC", (($n >> 12) | 0xe0), ((($n >> 6) & 0x3f) | 0x80),
                     (($n & 0x3f) | 0x80));
    } elsif ($n < 0x110000) {
        return pack ("CCCC", (($n >> 18) | 0xf0), ((($n >> 12) & 0x3f) | 0x80),
                     ((($n >> 6) & 0x3f) | 0x80), (($n & 0x3f) | 0x80));
    }
    return $n;
};
  

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

XML::CSV - Perl extension converting CSV files to XML

=head1 SYNOPSIS

  use XML::CSV;
  $csv_obj = XML::CSV->new();
  $csv_obj = XML::CSV->new(\%attr);
  
  $status = $csv_obj->parse_doc(file_name);
  $status = $csv_obj->parse_doc(file_name, \%attr);
  
  $csv_obj->declare_xml(\%attr);
  $csv_obj->declare_doctype(\%attr);

  $csv_obj->print_xml(file_name, \%attr);



=head1 DESCRIPTION

XML::CSV is a new module in is going to be upgraded very often as my time permits.
For the time being it uses CSV_XS module object default values to parse the
(*.csv) document and then creates a perl data structure with xml tags names and data.  
At this point it does not allow for a write as you parse interface but is
the first upgrade for the next release.  I will also allow more access to the data structures
and more documentation.  I will also put in more support for XML, since currently
it only allows a simple XML structure.  Currently you can modify the tag structure
to allow for attributes.  No DTD support is currently available, but will be
implemented in a soon coming release.  As the module will provide both: object and event interfaces, it will
be used upon individual needs, system resources, and required performance.  Ofcourse the DOM
implementation takes up more resources and in some instances timing, it's the easiest to use.

=head1 ATTRIBUTES new()

error_out - Turn on the error handling which will die on all errors and assign the error message to
$XML::CSV::csvxml_error.

column_headings - Specifies the column heading to use.  Passed as an array reference.  Can be used 
as a supplement to using the first column in the file as the XML tag names.  Since XML::CSV does 
not require you to parse the CSV file, you can provide your own data structure to parse.

column_data - Specifies the CSV data in a two dimensional array.  Passed as an array reference.

csv_xs - Specifies the CSV_XS object to use.  This is used to create custom CSV_XS object and override
the default one created by XML::CSV.


=head1 ATTRIBUTES parse_doc()

headings - Specifies the number of rows to use as tag names.  Defaults to 0.
Ex.  {headings => 1} (This will use the first row of data as xml tags)
           
sub_char - Specifies the character with which the illegal tag characters will be
replaced with.  Defaults to undef meaning no substitution is done.  To eliminate
characters use "" (empty string) or to replace with another see below.
Ex.  {sub_char => "_"} or {sub_char => ""}           
           

=head1 ATTRIBUTES declare_xml()

version - Specifies the xml version.  
Ex.  {version => '1.0'}

encoding - Specifies the type of encoding.  XML standard defaults encoding to 'UTF-8' if notspecifically
           set.
Ex.  {encoding => 'ISO-8859_1'}

standalone - Specifies the the document as standalone (yes|no).  If the document is does not rely on an
             external DTD, DTD is internal, or the external DTD does not effect the contents of the document,
             the standalone attribute should be set to 'yes', otherwise 'no' should be used.  For more info
             see XML declaration documentation.
Ex.  {standalone => 'yes'}

=head1 ATTRIBUTES declare_doctype()

source - Specifies the source of the DTD (SYSTEM|PUBLIC)
Ex. {source => 'SYSTEM'}

location1 - URI to the DTD file.  Public ID may be used if source is PUBLIC.
Ex. {location1 => 'http://www.xmlproj.com/dtd/index_dtd.dtd'} or {location1 => '-//Netscape Communications//DTD RSS 0.90//EN'}

location2 - Optional second URI.  Usually used if the location1 public ID is not found by the
            validating parser.
Ex. {location2 => 'http://www.xmlproj.com/file.dtd'}

subset - Any other information that proceedes the DTD declaration.  Usually includes internal DTD if any.
Ex. {subset => 'ELEMENT first_name (#PCDATA)>\n<!ELEMENT last_name (#PCDATA)>'}
You can even enterpolate the string with $obj->{column_headings} to dynamically build the DTD.
Ex. {subset => "ELEMENT $obj->{columnt_headings}[0] (#PCDATA)>"}

           
=head1 ATTRIBUTES print_xml()

file_tag - Specifies the file parent tag.  Defaults to "records".
Ex. {file_tag => "file_data"} (Do not use < and > when specifying)

parent_tag - Specifies the record parent tag.  Defaults to "record".
Ex. {parent_tag => "record_data"} (Do not use < and > when specifying)

format - Specifies the character to use to indent nodes.  Defaults to "\t" (tab).
Ex. {format => " "} or {format => "\t\t"}


=head1 PUBLIC VARIABLES

$csv_obj->{column_headings}
$csv_obj->{column_data}

=head1 EXAMPLES
         

Example #1:

This is a simple implementation which uses defaults

use XML::CSV;
$csv_obj = XML::CSV->new();
$csv_obj->parse_doc("in_file.csv", {headings => 1});

$csv_obj->print_xml("out.xml");

Example #2:

This example uses a passed headings array reference which is used along with the parsed data.

use XML::CSV;
$csv_obj = XML::CSV->new();

$csv_obj->{column_headings} = \@arr_of_headings;

$csv_obj->parse_doc("in_file.csv");
$csv_obj->print_xml("out.xml", {format => " ", file_tag = "xml_file", parent_tag => "record"});


Example #3:

First it passes a reference to a array with column headings and then a reference to two dimensional array
of data where the first index represents the row number and the second column number.  We also pass a custom
Text::CSV_XS object to overwrite the default object.  This is usefull for creating your own CSV_XS object's args
before using the parse_doc() method.  See 'perldoc Text::CSV_XS' for different new() attributes.

use XML::CSV;

$default_obj_xs = Text::CSV_XS->new({quote_char => '"'});
$csv_obj = XML::CSV->new({csv_xs => $default_obj_xs});
$csv_obj->{column_headings} = \@arr_of_headings;

$csv_obj->{column_data} = \@arr_of_data;

$csv_obj->print_xml("out.xml");


=head1 AUTHOR

Ilya Sterin, isterin@mail.com

=head1 SEE ALSO

Text::CSV_XS

=cut
