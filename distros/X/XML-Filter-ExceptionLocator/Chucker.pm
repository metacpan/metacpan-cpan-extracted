  package Chucker;
  use base 'XML::SAX::Base';
  use XML::SAX::Exception;
  sub start_element {
      XML::SAX::Exception->throw(Message => "Element found.");
  }
  1;

