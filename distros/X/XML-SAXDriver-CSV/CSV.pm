package XML::SAXDriver::CSV;

use strict;

use Text::CSV_XS;

use base qw(XML::SAX::Base);
use vars qw($VERSION $NS_SAXDriver_CSV);
$VERSION = '0.07';
$NS_SAXDriver_CSV = 'http://xmlns.perl.org/sax/XML::SAXDriver::CSV';

sub _parse_bytestream
{
  my $self = shift;
  my $stream = shift; 
  
  $self->_parse_CSV(\$stream);  
}
sub _parse_string
{
  my $self = shift;
  my $stream = shift; 
  
  my @strings = split("\n", $self->{ParseOptions}->{Source}{String});
  $self->_parse_CSV(\@strings);  
}
sub _parse_systemid
{
  my $self = shift;
  my $path = shift;
  
  require IO::File;
  my $ioref = IO::File->new($self->{ParseOptions}->{Source}{SystemId})
               || die "Cannot open SystemId '$self->{ParseOptions}->{Source}{SystemId}' : $!";
       
  $self->_parse_CSV($ioref);  
}

sub _parse_CSV 
{
  
  my $self = shift;
  my $source = shift;
  
  $self->{ParseOptions}->{Parser} ||= Text::CSV_XS->new();
  
  $self->{ParseOptions}->{Declaration}->{Version} ||= '1.0';
  
  my $document = {};
  $self->start_document($document);
  $self->xml_decl($self->{ParseOptions}->{Declaration});
  my $pm_csv = $self->_create_node(
                                  Prefix       => 'SAXDriver::CSV',
                                  NamespaceURI => $NS_SAXDriver_CSV,
                                  );
  $self->start_prefix_mapping($pm_csv);
  $self->end_prefix_mapping($pm_csv);
    
  my $doc_element = {
              Name => $self->{ParseOptions}->{File_Tag} || "records",
              Attributes => {},
          };

  $self->start_element($doc_element);
  
  $self->{ParseOptions}->{Col_Headings} ||= [];
    
  $self->{ParseOptions}->{Headings_Handler} ||= \&_normalize_heading;
           
  while (my $row = _get_row($self->{ParseOptions}->{Parser}, $source)) {
      my $el = {
          Name => $self->{ParseOptions}->{Parent_Tag} || "record",
          Attributes => {},
      };
      
      if (!@{$self->{ParseOptions}->{Col_Headings}} && !$self->{ParseOptions}->{Dynamic_Col_Headings}) 
      {
              my $i = 1;
              @{$self->{ParseOptions}->{Col_Headings}} = map { "column" . $i++ } @$row;
      }
      elsif (!@{$self->{ParseOptions}->{Col_Headings}} && $self->{ParseOptions}->{Dynamic_Col_Headings})
      {
              @{$self->{ParseOptions}->{Col_Headings}} = map { $self->{ParseOptions}->{Headings_Handler}->($_, $self->{ParseOptions}->{SubChar}); } @$row; 
              next; # causes the first (heading) row to be skipped 
                          
      }   
  
      $self->start_element($el);
      
      for (my $i = 0; $i <= $#{$row}; $i++) {
          my $column = { Name => $self->{ParseOptions}->{Col_Headings}->[$i], Attributes => {} };
          
          $self->start_element($column);
          $self->characters({Data => $row->[$i]});
          $self->end_element($column);          
      }

      $self->end_element($el);      
  }

  $self->end_element($doc_element);
  
  return $self->end_document($document);
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

sub _get_row {
    my ($parser, $source, $strings) = @_;
    
    if (ref($source) eq "ARRAY")
    {
      my $line = shift @$source;
      if ($line && $parser->parse($line)) {
        return [$parser->fields()];
      }
    }
    else
    {
      my $line = <$source>;
      if ($line && $parser->parse($line)) {
        return [$parser->fields()];
      }
    }
    
    return;
}

sub _create_node {
    shift;
    # this may check for a factory later
    return {@_};
}

1;
__END__




=head1 NAME

    XML::SAXDriver::CSV - SAXDriver for converting CSV files to XML

=head1 SYNOPSIS

      use XML::SAXDriver::CSV;
      my $driver = XML::SAXDriver::CSV->new(%attr);
      $driver->parse(%attr);

=head1 DESCRIPTION

    XML::SAXDriver::CSV was developed as a compliment to XML::CSV, though it provides a SAX
    interface, for gained performance and efficiency, to CSV files.  Specific object attributes
    and handlers are set to define the behavior of the parse() method.  It does not matter where 
    you define your attributes.  If they are defined in the new() method, they will apply to all
    parse() calls.  You can override in any call to parse() and it will remain local to that
    function call and not effect the rest of the object.

=head1 XML::SAXDriver::CSV properties

    Source - (Reference to a String, ByteStream, SystemId)
    
        String - Contains literal CSV data. Ex (Source => {String => $foo})
        
        ByteStream - Contains a filehandle reference.  Ex. (Source => {ByteStream => \*STDIN})
        
        SystemId - Contains the path to the file containing the CSV data. Ex (Source => {SystemId => '../csv/foo.csv'})
        
    Handler - Contains the object to be used as a XML print handler
    
    Declaration
        
        Version - Specifies an XML version for declaration.  Defaults to '1.0'.
        
        Encoding - Specifies the endcoding in XML declaration.  Omitted by default.
        
        Standalone - Specifies the standalone attribute.  Omitted by default.  
    
    DTDHandler - Contains the object to be used as a XML DTD handler.  
                 ****There is no DTD support available at this time.  
                 I'll make it available in the next version.****
    
    SubChar - Specifies the character(s) to use to substitute illegal chars in xml tag names, that
              will be generated from the first row, but setting the Dynamic_Col_Headings.
                 
    Col_Headings - Reference to the array of column names to be used for XML tag names.
    
    Dynamic_Col_Headings - Should be set if you want the XML tag names generated dynamically
                           from the first row in CSV file.  **Make sure that the number of columns
                           in your first row is equal to the largest row in the document.  You
                           don't generally have to worry about if you are submitting valid CSV
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

Originally written by Matt Sergeant, matt@sergeant.org
Modified and maintained by Ilya Sterin, isterin@cpan.org

=head1 SEE ALSO

XML::CSV.

=cut
