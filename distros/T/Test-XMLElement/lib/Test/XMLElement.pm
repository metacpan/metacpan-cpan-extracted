package Test::XMLElement;
use strict;
use warnings;

our $VERSION = '0.04';

use Test::Builder;
use XML::Twig;
use XML::XPath;
use XML::Twig::XPath;

my $Tst = Test::Builder->new();
my $XML;
my $LAST = '';

## Import subroutine is inspired by Test::Pod import method

sub import {
   my $self = shift;
   my $caller = caller;
   no strict 'refs';
   *{$caller.'::have_child'}         = \&have_child;
   *{$caller.'::have_child_name'}    = \&have_child_name;
   *{$caller.'::child_count_is'}     = \&child_count_is;
   *{$caller.'::is_empty'}           = \&is_empty;
   *{$caller.'::has_attributes'}     = \&has_attributes;
   *{$caller.'::has_no_attrib'}      = \&has_no_attrib;
   *{$caller.'::number_of_attribs'}  = \&number_of_attribs;
   *{$caller.'::attrib_value'}       = \&attrib_value;
   *{$caller.'::attrib_name'}        = \&attrib_name;
   *{$caller.'::nth_child_name'}     = \&nth_child_name;
   *{$caller.'::all_children_are'}   = \&all_children_are;
   *{$caller.'::child_has_cdata'}    = \&child_has_cdata;
   *{$caller.'::is_descendants'}     = \&is_descendants;   
   *{$caller.'::is_xpath'}           = \&is_xpath;   
   *{$caller.'::is_xpath_count'}     = \&is_xpath_count;   
   
   $Tst->exported_to($caller);
   $Tst->plan(@_);
}



sub have_child {
  my ($elt, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  return 
	  (
	     $Tst->ok(scalar(_child_elements($valid_elt)),$msg) ||
	     $Tst->diag("Element ",$valid_elt->name," do not have any children")
       );
}

sub have_child_name {
  my ($elt, $name, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  my @child = _child_elements($valid_elt);
  return 
	  (  
	     $Tst->ok(scalar(@child),$msg) || 
	     $Tst->diag("Element ",$valid_elt->name," do not have any children")
	  ) unless (@child); 
  return 
	  (
	     $Tst->ok(scalar(grep {$_->name eq $name} @child), $msg) ||
	     $Tst->diag("Element \'",$valid_elt->name,"\' do not have any child named $name")
      );
}

sub nth_child_name {
  my ($elt, $n, $name, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  my @child = _child_elements($valid_elt);
  return 
	  (  
	     $Tst->ok(scalar(@child),$msg) || 
	     $Tst->diag("Element ",$valid_elt->name," do not have any children")
	  ) unless (@child); 
  return 
	  (
	     $Tst->is_eq( $child[$n - 1]->name,$name, $msg) ||
	     $Tst->diag("Element \'",$valid_elt->name,"\' do not have ",$n - 1," child named $name")
      );
}

sub all_children_are {
  my ($elt, $name, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  my @child = _child_elements($valid_elt);
  return 
	  (  
	     $Tst->ok(scalar(@child),$msg) || 
	     $Tst->diag("Element ",$valid_elt->name," do not have any children")
	  ) unless (@child); 
  return 
	  (
	     $Tst->is_num( scalar (grep {$_->name eq $name} @child), scalar @child,  $msg) ||
	     $Tst->diag("Element \'",$valid_elt->name,"\' do not have all child named $name")
      );
}


sub child_count_is {
  my ($elt, $num, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  my @child = _child_elements($valid_elt);
  return 
	  (
	     $Tst->is_num(scalar(@child), $num, $msg) ||
	     $Tst->diag("Element \'",$valid_elt->name,"\' do not have $num children")
      );
}

sub is_empty {
  my ($elt, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  return 
	  (
	     $Tst->ok($valid_elt->is_empty, $msg) ||
	     $Tst->diag("Element ",$valid_elt->name," is not empty")
       );
}

sub has_attributes {
  my ($elt, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  return 
	  (
	     $Tst->ok($valid_elt->has_atts, $msg) ||
	     $Tst->diag("Element ",$valid_elt->name," dont have attributes")
	  );
}

sub has_no_attrib {
  my ($elt, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  return 
	  (
	     $Tst->ok($valid_elt->has_no_atts, $msg) || 
	     $Tst->diag("Element ",$valid_elt->name," have attributes")
	  );
}

sub number_of_attribs {
  my ($elt, $num, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  return 
	  (
	     $Tst->is_num($valid_elt->att_nb, $num, $msg) || 
	     $Tst->diag("Element ",$valid_elt->name," have ",$valid_elt->att_nb," attributes")
	  );
}

sub attrib_name {
  my ($elt, $name, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  my @atts = $valid_elt->att_names;
  return 
	  (  
	     $Tst->ok(scalar(@atts),$msg) || 
	     $Tst->diag("Element ",$valid_elt->name," do not have any attributes")
	  ) unless (@atts); 
  return 
	  (
	     $Tst->ok(scalar(grep {$_ eq $name} @atts), $msg) ||
	     $Tst->diag("Element \'",$valid_elt->name,"\' do not have any attribute named $name")
      );
}


sub attrib_value {
  my ($elt, $name, $value, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  my @atts = $valid_elt->att_names;
  return 
	  (  
	     $Tst->ok(scalar(@atts),$msg) || 
	     $Tst->diag("Element ",$valid_elt->name," do not have any attributes")
	  ) unless (@atts); 
  return 
	  (
	     $Tst->is_eq($valid_elt->att($name), $value, $msg) ||
	     $Tst->diag("Element \'",$valid_elt->name,"\' do not have any attribute named $name")
      );
}

sub child_has_cdata {
  my ($elt, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  my @cdata = grep {$_->is_cdata} $valid_elt->children;
  return 
	  (  
	     $Tst->ok(scalar(@cdata),$msg) || 
	     $Tst->diag("Element ",$valid_elt->name," do not have any CDATA")
	  )
}

sub is_descendants {
  my ($elt, $name, $msg) = @_;
  my $valid_elt = _parse($elt,$msg);
  return 0 unless $valid_elt;
  return 
	  (  
	     $Tst->ok(scalar($valid_elt->descendants($name)),$msg) || 
	     $Tst->diag("Element ",$valid_elt->name," do not have any descendants for $name")
	  ); 
}

sub is_xpath {
    my ($elt, $xpath, $msg) = @_;
    my $valid_elt = _parse($elt,$msg,"xpath");
	my @xp_cnt;
    return 0 unless $valid_elt;
	eval {
     @xp_cnt = $valid_elt->findnodes($xpath,$valid_elt->root);
    };
	return 
	  (
	     $Tst->ok(0,$msg) || 
	     $Tst->diag("Failed due to $@")
	  ) if $@; 

	return 
	  (  
	     $Tst->ok(scalar(@xp_cnt),$msg) || 
	     $Tst->diag("Element ",$valid_elt->root->name," do not have elements matching $xpath")
	  ); 
}

sub is_xpath_count {
    my ($elt, $xpath, $count, $msg) = @_;
    my $valid_elt = _parse($elt,$msg,"xpath");
	my @xp_cnt;
    return 0 unless $valid_elt;
	eval {
     @xp_cnt = $valid_elt->findnodes($xpath,$valid_elt->root);
    };
	return 
	  (
	     $Tst->ok(0,$msg) || 
	     $Tst->diag("Failed due to $@")
	  ) if $@; 

	return 
	  (  
	     $Tst->is_num(scalar(@xp_cnt),$count,$msg) || 
	     $Tst->diag("XPath expression $xpath did not had same elements as required count $count")
	  ); 
}

### Private Subroutines ##

sub _parse {
  local $Test::Builder::Level += 2; 
  my $string = shift or return $Tst->diag("XML String is not defined");
  my $msg    = shift;
  my $xp     = shift;
  return $XML if ($string eq $LAST);
  if (not $xp) {
    eval {
      $XML = parse XML::Twig::Elt($string); 
    };
  }
  else {
   eval {
	   $XML = parse XML::Twig::XPath($string); 
   };
  }
    $@ ? ($Tst->ok(0,$msg)||$Tst->diag($@)) : $XML;
}

sub _child_elements {
  my ($elt) = shift;
  return grep {$_->is_elt} $elt->children;
}

1;
__END__
=head1 NAME

Test::XMLElement - Perl extension for testing element properties using XML Twig

=head1 SYNOPSIS

 use Test::XMLElement tests => 22;

 my $elt = "<bar/>";

  have_child("<a>abc</a>", "Element 'a' have children"); #FAIL
  have_child("<a>abc<b/></a>", "Element 'a' have children"); #PASS

  have_child_name("<a><c/></a>", "b", "Element 'a' contains child b"); #FAIL
  have_child_name("<a><b/></a>", "b", "Element 'a' contains child b"); #PASS
  
  child_count_is("<a></b><c>abc</c></a>", 1, "Element contains N children"); #FAIL
  child_count_is("<a></b><c>abc</c></a>", 2, "Element contains N children"); #PASS
  
  is_empty($elt, "Check empty"); #PASS
  is_empty("<a></a>", "Check empty"); #FAIL
  
  has_attributes($elt, "has Attributes"); #FAIL
  has_attributes("<a murug='a'/>", "has Attributes"); #PASS
  
  has_no_attrib("<a murug='a'/>", "has no attrib"); #FAIL
  has_no_attrib($elt, "has no attrib"); #PASS
  
  number_of_attribs("<a murug='b' c='d' e='f'/>", 1, "Number of attributes 3"); #FAIL
  number_of_attribs("<a murug='b'/>", 1, "Number of attributes 1"); #PASS
  
  attrib_name("<a murug='b' c='d' e='f'/>", "k", "Attribute name k"); #FAIL
  attrib_name("<a murug='b' c='d' e='f'/>", "c", "Attribute name c"); #PASS
  
  attrib_value("<a murug='b' c='d' e='f'/>", "c", "e", "Attribute value c"); #FAIL
  attrib_value("<a murug='b' c='d' e='f'/>", "c", "d", "Attribute value d"); #PASS
  
  nth_child_name("<a><b/><c/><d/></a>", 1, "c", "First child name is c"); #FAIL
  nth_child_name("<a><b/><c/><d/></a>", 1, "b", "First child name is b"); #PASS
  
  all_children_are("<a><b/><c/><d/></a>", "b", "All Children are b"); #FAIL
  all_children_are("<a><b/><b/><b/></a>", "b", "All Children are b"); #PASS


=head1 DESCRIPTION

This test module allows you to check some of the XML element properties.  This is useful in
testing applications which generate/validates XML. Input for this module is valid XML Element. This module 
contains wrapper subroutines which acts as testing block for custom XML test tools.

=head1 SUBROUTINES

=over 4

=item have_child($xml, $desc);

Test passes if the XML string in C<$xml> contains any direct child elements. C<$desc> is description of the test

=item have_child_name($xml, $name, $desc);

Test passes if the XML string in C<$xml> contains any direct child element with tag or gi value as C<$name>. Name or Describe the test with C<$desc>.

=item child_count_is($xml, $count, $desc);

Test passes if the XML string in C<$xml> contains exactly C<$count> number of the child elements. Describe or name the test with C<$name>.

=item is_empty($xml, $desc);

Test passes if the XML string in C<$xml> is empty. C<$desc> is description of the test

=item has_attributes($xml, $desc);

Test passes if the XML string in C<$xml> contains any attributes. Describe or name the test with C<$name>.

=item has_no_attrib($xml, $desc);

Test passes if the XML string in C<$xml> does not contain any attributes. Describe or name the test with C<$name>.

=item number_of_attribs($xml, $count, $desc);

Test passes if the XML string in C<$xml> contains exactly C<$count> number of the attributes. Describe or name the test with C<$name>.

=item attrib_name($xml, $name, $desc);

Test passes if the XML string in C<$xml> contains attribute with name C<$name>. Describe or name the test with C<$name>.

=item attrib_value($xml, $name, $value, $desc);

Test passes if the XML string in C<$xml> contains attribute with name C<$name> and its value as C<$value>. Describe or name the test with C<$name>.

=item nth_child_name($xml, $count, $name, $desc);

Test passes if the XML string in C<$xml> contains any direct Nth child element with tag or gi value as C<$name> and location at C<$count>. Name or Describe the test with C<$desc>.

=item all_children_are($xml, $name, $desc);

Test passes if the XML string in C<$xml> contains all direct child element with tag or gi value as C<$name>. Name or Describe the test with C<$desc>.

=item child_has_cdata($xml, $desc);

Test passes if the XML string in C<$xml> contains any CDATA element as its direct child. Name or Describe the test with C<$desc>.

=item is_xpath($xml, $xpath, $desc);

Test passes if the XML string in C<$xml> matches the XPath expression C<$xpath>. Name or Describe the test with C<$desc>.

=item is_xpath_count($xml, $xpath, $count, $desc);

Test passes if the XML string in C<$xml> matches C<$count> number of XPath expression C<$xpath>. Name or Describe the test with C<$desc>.

=back

=head1 EXPORTS

Everything in L<"SUBROUTINES">

=head1 SEE ALSO

L<Test::More>

L<Test::Builder>

L<XML::Twig>

=head1 AUTHOR

Murugesan Kandasamy, E<lt>murugu@cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Murugesan Kandasamy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.
=cut
