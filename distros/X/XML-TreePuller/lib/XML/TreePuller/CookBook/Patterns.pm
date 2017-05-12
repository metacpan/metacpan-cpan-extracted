#!/usr/bin/env perl

1;

__END__

=head1 NAME

XML::TreePuller::CookBook::Patterns - Recipes for dealing with XML patterns

=head1 LISTS

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  use Data::Dumper;
  
  use XML::TreePuller;
  
  my $xml = <<EOF;
  <array>
  	<element>zero</element>
  	<element>one</element>
  	<element>two</element>	
  </array>
  
  EOF
  
  my $root = XML::TreePuller->parse(string => $xml);
  my @array;
  
  map({ push(@array, $_->text) } $root->get_elements('element'));
  
  print join(' ', @array), "\n";
  
=head1 HASHES

=head2 With attributes

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  
  use XML::TreePuller;
  
  my $xml = <<EOF;
  <hash>
  	<entry key="0">zero</entry>
  	<entry key="1">one</entry>
  	<entry key="2">two</entry>
  </hash>
  
  EOF
  
  my $root = XML::TreePuller->parse(string => $xml);
  my %hash;
  
  map({ $hash{$_->attribute('key')} = $_->text; } $root->get_elements('entry'));
  
  foreach (0..2) {
  	print $hash{$_}, "\n";	
  }

=head2 Without attributes

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  use Data::Dumper;
  
  use XML::TreePuller;
  
  my $xml = <<EOF;
  <hash>
    <key>0</key>
    <value>zero</value>
    <key>1</key>
    <value>one</value>
    <key>2</key>
    <value>two</value>
  </hash>
  
  EOF
  
  my $root = XML::TreePuller->parse(string => $xml);
  my %hash;
  
  my @keys = $root->get_elements('key/');
  my @values = $root->get_elements('value/');
  
  map({ $hash{$_->text} = shift(@values)->text } @keys);
  
  foreach (0..2) {
  	print $hash{$_}, "\n";	
  }
  

=head1 COPYRIGHT 

All content is copyright Tyler Riddle; see the README for licensing terms. 
  


