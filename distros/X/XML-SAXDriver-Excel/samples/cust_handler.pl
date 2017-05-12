use XML::SAXDriver::Excel; 

my $code_handler= new code_handler; 

our $DATA = <<"CSV";
field1, field2, field3 
F1_1, F1_2, F1_3 
F2_1, F2_2, F2_3 
F3_1,, F3_3 
,, F4_3 
,, 
F6_1 
F7_1,, 
,F8_2,
CSV


my $driver = XML::SAXDriver::Excel->new(Source => {SystemId => "Test.xls"}, 
                                      Handler => $code_handler, 
                                      Dynamic_Col_Headings => 1, 
                                      IndentChar           => '  ', 
                                      File_Tag   => 'code'); 
$driver->parse(); 


package code_handler; 

sub new 
  { my $class= ref $_[0] || $_[0]; 
    return bless {}, $class; 
  } 

sub start_document 
  { my $code_handler= shift; 
    my $document= shift; 
  } 

sub end_document 
  { my $code_handler= shift; 
    my $document= shift; 
  } 

sub start_element 
  { my $code_handler= shift; 
    my $element= shift; 
    my $name= $element->{Name}; 
    my $atts= $element->{Attributes}; 
    print "<$name"; 
    foreach my $att (sort keys %$atts) 
      {print " $att='$atts->{$att}'";} 
    print ">"; 
  } 

sub characters 
  { my $code_handler= shift; 
    my $character= shift; 
    print $character->{Data} if( defined $character->{Data}); 
  } 

sub end_element 
  { my $code_handler= shift; 
    my $element= shift; 
    my $name= $element->{Name}; 
    print "</$name>"; 
  } 

