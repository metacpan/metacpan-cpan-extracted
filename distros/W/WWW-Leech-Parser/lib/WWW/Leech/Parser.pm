package WWW::Leech::Parser;
use strict;
use HTML::TreeBuilder::XPath;
use Encode qw|is_utf8 encode decode|;
use utf8;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.04';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

sub new{

  my $class = shift;
  my $params = shift;


  my $fields = {};

  if(ref($params->{'fields'}) eq 'ARRAY'){
    foreach( @{$params->{'fields'}}  ){
      $fields->{$_->{'name'}} = $_;
    }
    $params->{'fields'} = $fields;
  }

  $params->{'current_dom'} = undef;

  return bless $params, __PACKAGE__;

}

sub parseList{
  my $this = shift;
  my $str = shift;

  $this->{'current_dom'} = HTML::TreeBuilder::XPath->new;
  $this->{'current_dom'}->parse_content($str);

  my $links = [];
  my $links_text = [];
  foreach(@{$this->{'current_dom'}->findnodes($this->{'item:link'})}){
    push(@$links, $_->attr('href'));
    push(@$links_text, $_->as_text());    
  }

  my $np = undef;
  if($this->{'nextpage:link'}){
    $np = $this->{'current_dom'}->findnodes($this->{'nextpage:link'})->[0];

    if($np){
      $np = $np->attr('href');
    }
  }

  return {
    'links' => $links,
    'links_text' => $links_text,
    'next_page' => $np
  }
}

sub parse{
  my $this = shift;
  my $str = shift;

  if(!is_utf8($str)){
    $str = decode('UTF-8',$str);
  }

  $this->{'current_dom'}= HTML::TreeBuilder::XPath->new;
  $this->{'current_dom'}->ignore_unknown(0);
  $this->{'current_dom'}->parse_content($str);

  my $item = {};

  foreach my $field_name ( keys(%{$this->{'fields'}}) ){

    my $field = $this->{'fields'}->{$field_name};

    if(ref($field) ne 'HASH') {
      $field = {
        'xpath' => $field
      };
    }

    $field->{'name'} = $field_name;

    if($field->{'xpath'}){
      if(!is_utf8($field->{'xpath'})){
        $field->{'xpath'} = decode('UTF-8',$field->{'xpath'});
      }

      my $type = ($field->{'type'} ? $field->{'type'} : 'text');
      my $wantarray = ( $field_name =~ /\[\]$/ ? 1 : undef );

      my $value;

      if($wantarray){
        $value = [];

        if($type eq 'html'){

          foreach my $n ($this->{'current_dom'}->findnodes($field->{'xpath'})){
            push(@$value,$n->as_XML);
          }
          
        } else {
          $value = [$this->{'current_dom'}->findvalues($field->{'xpath'})];

          if($type eq 'unique'){
            my %u;
            $u{$_} = 1 foreach(@$value);
            $value = [keys(%u)];
          }
        }
      } else {
        if($type eq 'html'){

          if([$this->{'current_dom'}->findnodes($field->{'xpath'})]->[0]){
            $value = [$this->{'current_dom'}->findnodes($field->{'xpath'})]->[0]->as_XML;
          }
          
        }
        else {
          $value = $this->{'current_dom'}->findvalue($field->{'xpath'});
        }

        if($type eq 'int'){
          $value =~ s/[^\d]//g;
        }
      }

      if($field->{'filter'}){
        $value = $field->{'filter'}->($value,$field);
      }

      $item->{$field_name} = $value;
    }
  }

  return $item;

}

1;

__END__
=head1 NAME

WWW::Leech::Parser - HTML Page parser used by WWW::Leech::Walker

=head1 SYNOPSIS

  use WWW::Leech::Parser;

  my $parser = new WWW::Leech::Parser({
    'item:link' => '//a[contains(@class,"item-link")]',
    'nextpage:link' => '//a[contains(@class,"next-page-link")]',
    'fields' => {
      'name' => '//h1',
      'images[]' => '//img/@src',
      'comments[]' =>{
        type => 'html',
        xpath => '//div[@class="comments"]/div',
        filter => sub{
          my $values = shift;
          my $field_defs = shift;

          # ....

          return $values;
        }

      }
      # ....
    }
  });

  my $html_string = '...';
  
  my $links_and_next_page_url = $parser->parseList($html_string);

  my $item = $parser->parse($html_string);



=head1 DESCRIPTION

WWW::Leech::Parser extracts certain information from web page using provided XPath expressions.

First of all it is used to get links to 'sub-pages' and links to 'next-page' from a links-list-page (e.g. search engine results). 
Also it extracts required data from given HTML using rules defined upon object creation.

=head1 DETAILS

=over 4

=item new($rules)

$rules is a hashref with following keys:

=over 4

=item item:link

XPath extracting links to sub-pages

=item nextpage:link

XPath extracting link to next links-list page

=item fields

Fields tell parser how to extract data. Can be provided as an arrayref:

  $fields = [
    {
      name => 'fieldname1',
      xpath => '//somenode'
    },
    {
      name => 'fieldname2',
      xpath => '//othernode'
    }
  ]
  

Or a hashref:

  $fields = 
    {
      fieldname1 => '//somenode',
      fieldname2 => {
        xpath => '//othernode'
      }
    }
  ]


By default parser uses first node found text as a value for the element.
Appending '[]' sequence to key name switches parser to 'wantarray' mode. Parser will return an array of values in this case.

Every element can be provided in a simple or a complex form. 

Simple form is just a key-value pair where key is a name of a field and value is an XPath expression.

In complex form a hashref determining details about the field must be provided. Following keys are recognized:

=over 4

=item xpath

Required. 

XPath expression for element data.

=item type

Optional. 

 text - gets text content only (default)
 html - extracts all node content including node itself as is
 int - not appliable in 'wantarray' mode - removes non numeric characters from text value
 unique - only appliable in 'wantarray' mode - removes duplicates 

=item filter

Optional.

Coderef. Parser runs filter callback passing extracted value and field definitions. Field value is replaced with whatever callback returns.

=back

=back

=item parseList($html_string)

returns list-page links as a hashref:

  {
    links => [...], # URL's array
    links_text => [...], # Text inside corresponding 'a' tags
    next_page => "/page/N" # next page URL
  }


=item parse($html_string)

returns hashref with data extracted from page using 'fields' section from rules

=back


=head1 AUTHOR

    Dmitry Selverstov
    CPAN ID: JAREDSPB
    jaredspb@cpan.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut
