package XML::SAXDriver::Excel;

use strict;

use Spreadsheet::ParseExcel;

use base qw(XML::SAX::Base);
use vars qw($VERSION $NS_SAXDriver_Excel);
$VERSION = '0.06';
$NS_SAXDriver_Excel = 'http://xmlns.perl.org/sax/XML::SAXDriver::Excel';

sub _parse_bytestream
{
  my $self = shift;
  my $stream = shift; 
  
  die ("Cannot use String to parse a binary Excel file.  You can only use a file by setting SystemId");
  
  $self->_parse_Excel(\$stream);  
}
sub _parse_string
{
  my $self = shift;
  my $stream = shift; 
  
  ### This is experimental due to the binary streams
  #require IO::String;
  #$io = IO::String->new($var);
  #$self->_parse_Excel($io);
  
  die ("Cannot use String to parse a binary Excel file.  You can only use a file by setting SystemId"); 
  
  #my @strings = split("\n", $self->{ParseOptions}->{Source}{String});
  #$self->_parse_Excel(\@strings);  
}
sub _parse_systemid
{
  my $self = shift;
  my $path = shift;
  
  $self->_init();
  $self->{ParseOptions}->{Parser}->Parse($path);
  $self->_end();
  
}

sub _init {
  my $self = shift;
  
  ### Reset vars before parsing
  $self->{_row} = [];  ## Used to push row values per row
	$self->{_row_num} = -1;  ## Set at -1 since rows are counted from 0
	$self->{_last_row_num} = 0;  ## Used to save the last row value received
	$self->{_last_col} = 0;
		    
  $self->{ParseOptions}->{Parser} ||= Spreadsheet::ParseExcel->new(CellHandler => \&cb_routine, Object => $self, NotSetCell => 1);
  
  $self->{ParseOptions}->{Headings_Handler} ||= \&_normalize_heading;
  
  $self->{_document} = {};
  $self->{ParseOptions}->{Handler}->start_document($self->{_document});
  $self->xml_decl($self->{ParseOptions}->{Declaration});
  my $pm_excel = $self->_create_node(
                                  Prefix       => 'SAXDriver::Excel',
                                  NamespaceURI => $NS_SAXDriver_Excel,
                                  );
  $self->start_prefix_mapping($pm_excel);
  $self->end_prefix_mapping($pm_excel);
    
  $self->{_doc_element} = {
              Name => $self->{ParseOptions}->{File_Tag} || "records",
              Attributes => {},
          };

  $self->{ParseOptions}->{Handler}->start_element($self->{_doc_element});  
}
  
  ## Parse file or string
  
  
sub _end
{  
  my $self = shift;
  _print_xml_finish($self);
  
  ### Reset vars after parsing
  $self->{_row} = [];  ## Used to push row values per row
	$self->{_row_num} = -1;  ## Set at -1 since rows are counted from 0
	$self->{_last_row_num} = 0;  ## Used to save the last row value received
  
  $self->{ParseOptions}->{Handler}->end_element($self->{_doc_element});
  
  return $self->{ParseOptions}->{Handler}->end_document($self->{_document});
  
}

sub cb_routine($$$$$$)
{    
  my ($self, $oBook, $iSheet, $iRow, $iCol, $oCell) = @_;
  
  my $oWkS = $oBook->{Worksheet}[$iSheet];
         
  $self->{ParseOptions}->{Col_Headings} ||= [];

if ($iCol < $oWkS->{MaxCol})
  {
    
    if ($self->{_last_col} > $iCol)
  	{
  	  while ($self->{_last_col} < $oWkS->{MaxCol})
  	  {
  	    push(@{$self->{_row}}, undef);
  	    $self->{_last_col}++;    	    
  	  }  	
  	  _print_xml(@_);  	
  	}
    
    if ($self->{_last_col} < $iCol)
  	{
  	  while ($self->{_last_col} < $iCol)
  	  {
  	    push(@{$self->{_row}}, undef);
  	    $self->{_last_col}++;    	    
  	  }    	  
  	}
  	
  	  push(@{$self->{_row}}, $oCell->Value());
  	  $self->{_last_row_num} = $iRow;
  	  $self->{_last_col}++;
  	  return;
  	
  	    	
  }

  push(@{$self->{_row}}, $oCell->Value());# if $flag == 0;
    
  _print_xml(@_);
  return;
        
}

sub _normalize_heading  ### Default if no Headings_Handler is provided
{ 
  my $heading= shift;
  my $sub_char = shift || '_';
  $heading =~ s/^\s//g;
  $heading =~ s/\s$//g;
  $heading =~ s/^([^a-zA-Z|^_|^:])/$sub_char/g;   ### We used to also replace the xml in the beginning, but I took it of per recommendation of Michael Rodriguez.
  $heading =~ s/[^a-zA-Z|^-|^.|^0-9|^:]/$sub_char/g;
  return $heading; 
}


sub _print_xml
{
  my ($self, $oBook, $iSheet, $iRow, $iCol, $oCell) = @_;  ### Remember self is passed through the Spreadsheet::ParseExcel object
  
  my $oWkS = $oBook->{Worksheet}[$iSheet];
  
  $self->{_last_row_num} = $iRow;
      
  
  $self->{_last_col} = 0;      
  my $temp_row = $oCell->Value();
  $self->{_row_num} = $self->{_last_row_num};       
      
              
      if (!@{$self->{ParseOptions}->{Col_Headings}} && !$self->{ParseOptions}->{Dynamic_Col_Headings}) 
      {
              my $i = 1;
              @{$self->{ParseOptions}->{Col_Headings}} = map { "column" . $i++ } @{$self->{_row}};                
      }
      elsif (!@{$self->{ParseOptions}->{Col_Headings}} && $self->{ParseOptions}->{Dynamic_Col_Headings})
      {
              @{$self->{ParseOptions}->{Col_Headings}} = map { $self->{ParseOptions}->{Headings_Handler}->($_, $self->{ParseOptions}->{SubChar}); } @{$self->{_row}};
              $self->{_row} = [];  ### Clear the @$row array
              return;  ### So that it does not print the column headings as the content of the first node.                
      }
      
      
      my $el = {
        Name => $self->{ParseOptions}->{Parent_Tag} || "record",
        Attributes => {},
      };
      
      $self->{ParseOptions}->{Handler}->start_element($el);
      
      for (my $i = 0; $i <= $#{$self->{ParseOptions}->{Col_Headings}}; $i++) {
          my $column = { Name => $self->{ParseOptions}->{Col_Headings}->[$i], Attributes => {} };
          
          $self->{ParseOptions}->{Handler}->start_element($column);
          $self->{ParseOptions}->{Handler}->characters({Data => $self->{_row}->[$i]});
          $self->{ParseOptions}->{Handler}->end_element($column);          
      }

      $self->{ParseOptions}->{Handler}->end_element($el);      
  
  $self->{_row} = [];  ### Clear $row and start the new row processing
  
}

sub _print_xml_finish
{
  my $self = shift;
  
  while (@{$self->{_row}} < 9)
  {
    push(@{$self->{_row}}, undef);
  }
  
  my $el = {
        Name => $self->{ParseOptions}->{Parent_Tag} || "record",
        Attributes => {},
      };
      
      $self->{ParseOptions}->{Handler}->start_element($el);
      
      for (my $i = 0; $i <= $#{$self->{ParseOptions}->{Col_Headings}}; $i++) {
          my $column = { Name => $self->{ParseOptions}->{Col_Headings}->[$i], Attributes => {} };
          
          $self->{ParseOptions}->{Handler}->start_element($column);
          $self->{ParseOptions}->{Handler}->characters({Data => $self->{_row}->[$i]});
          $self->{ParseOptions}->{Handler}->end_element($column);          
      }

      $self->{ParseOptions}->{Handler}->end_element($el); 
}

sub _create_node {
    shift;
    # this may check for a factory later
    return {@_};
}

1;
__END__




=head1 NAME

  XML::SAXDriver::Excel - SAXDriver for converting Excel files to XML

=head1 SYNOPSIS

    use XML::SAXDriver::Excel;
    my $driver = XML::SAXDriver::Excel->new(%attr);
    $driver->parse(%attr);

=head1 DESCRIPTION

  XML::SAXDriver::Excel was developed as a complement to 
  XML::Excel, though it provides a SAX interface, for 
  gained performance and efficiency, to Excel files.  
  Specific object attributes and handlers are set to 
  define the behavior of the parse() method.  It does 
  not matter where you define your attributes.  If they 
  are defined in the new() method, they will apply to 
  all parse() calls.  You can override in any call to 
  parse() and it will remain local to that function call 
  and not effect the rest of the object.

=head1 XML::SAXDriver::Excel properties

  Source - (Reference to a String, ByteStream, SystemId)
  
    String - **currently not supported** Contains literal Excel data. 
             Ex (Source => {String => $foo})  
      
    ByteStream - **currently not supported** Contains a filehandle reference.  
                 Ex. (Source => {ByteStream => \*STDIN})
      
    SystemId - Contains the path to the file containing 
               the Excel  data. Ex (Source => {SystemId => '../excel/foo.xls'})
      
  
  Handler - Contains the object to be used as a XML print handler
  
  DTDHandler - Contains the object to be used as a XML DTD handler.  
               ****There is no DTD support available at this time.  
               I'll make it available in the next version.****
  
  SubChar - Specifies the character(s) to use to substitute illegal chars in xml tag names, that
            will be generated from the first row, but setting the Dynamic_Col_Headings.              
               
  Col_Headings - Reference to the array of column names to be used for XML tag names.
  
  Dynamic_Col_Headings - Should be set if you want the XML tag names generated dynamically
                         from the first row in Excel file.  **Make sure that the number of columns
                         in your first row is equal to the largest row in the document.  You
                         don't generally have to worry about if you are submitting valid Excel
                         data, where each row will have the same number of columns, even if
                         they are empty.
                           
  Headings_Handler - Should be used along with Dynamic_Col_Headings to provide a heading 
                     normalization handler, to conform the headings to the XML 1.0 
                     specifications.  If not provided, a default will be used that only
                     works with ASCII chars, therefore any other character sets need to 
                     provide a custom handler!  The handler sub will be passed the heading
                     string as the first argument.
                         
=head1 AUTHOR

Ilya Sterin (isterin@cpan.org)

=head1 SEE ALSO

XML::Excel
Spreadsheet::ParseExcel

=cut
