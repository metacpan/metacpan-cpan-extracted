package WebSource::Extract::xslt;
use strict;
use XML::LibXML;
use XML::LibXSLT;
use Carp;
use Date::Language;
use Date::Format;

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Extract::xslt - Apply an XSL Stylesheet to the input

=head1 DESCRIPTION

This flavor of the B<Extract> operator applies an XSL stylesheet to the input
an returns the transformation result.

Such an extraction operator should be described as follows :

  <ws:extract type="xslt" name="opname" forward-to="ops">
    <xsl:stylesheet>
    ...
    </xsl:stylesheet>
  </ws:extract>
  
  where the xsl prefix should be associated to the URI http://www.w3.org/1999/XSL/Transform

=head1 SYNOPSIS

=head1 METHODS

=cut

sub new {
  my $class = shift;
  my %params = @_;
  my $self = bless \%params, $class;
  $self->SUPER::_init_;
  my $wsd = $self->{wsdnode};
  if($wsd) {
    $wsd->setNamespace("http://www.w3.org/1999/XSL/Transform","xsl",0);
    my %param_mapping;
    foreach my $paramEl ($wsd->findnodes('xsl:stylesheet/xsl:param')) {
        my $paramName = $paramEl->getAttribute('name');
        my $wsEnvKey  = $paramEl->getAttributeNS("http://wwwsource.free.fr/ns/websource","mapped-from");
        if(!$wsEnvKey) {
          $wsEnvKey = $paramName;
        }
        $self->log(2,"Found parameter : $paramName (mapped from $wsEnvKey)");
        $param_mapping{$paramName} = $wsEnvKey;
    }
    $self->{xslparams} = \%param_mapping;
    my @stylesheet = $wsd->findnodes('xsl:stylesheet');
    if(@stylesheet) {
      my $wsdoc = $wsd->ownerDocument;
      my $xsltdoc = XML::LibXML::Document->new($wsdoc->version,$wsdoc->encoding);
      $xsltdoc->setDocumentElement($stylesheet[0]->cloneNode(1));
      my $xslt = XML::LibXSLT->new();	
      $xslt->register_function('http://wwwsource.free.fr/ns/websource/xslt-ext','reformat-date','WebSource::Extract::xslt::reformatDate');
      $xslt->register_function('http://wwwsource.free.fr/ns/websource/xslt-ext','string-replace','WebSource::Extract::xslt::stringReplace');
      $xslt->register_function('http://wwwsource.free.fr/ns/websource/xslt-ext','html-lint','WebSource::Extract::xslt::htmlLint');
      $self->{xsl} = $xslt->parse_stylesheet($xsltdoc);
      $self->{format} = $wsd->getAttribute("format");
    } else {
      croak "No stylesheet found\n";
    }
  }
  $self->{xsl} or croak "No XSLT stylesheet given";
  return $self;
}

sub handle {
  my $self = shift;
  my $env = shift;

  $self->log(5,"Got document ",$env->{baseuri});
  my $data = $env->data;
  if(!$data->isa("XML::LibXML::Document")) {
    $self->log(5,"Creating document from DOM node");
    my $doc = XML::LibXML::Document->new("1.0","UTF-8");
    $doc->setDocumentElement($data->cloneNode(1));
    $data = $doc;
  }
  $self->log(6,"We have : \n".$data->toString(1,'utf-8')."\n");
  $self->log(6,".. encoding: ".$data->ownerDocument->actualEncoding()."\n");
  
  my $mapping = $self->{xslparams};
  my %parameters;
  foreach my $param (keys(%$mapping)) {
    my $origKey = $mapping->{$param};
    my $value = $env->{$origKey};
    $self->log(2,"Found value for $param (using $origKey) : ",$value);
    $parameters{$param} = $value;
  }
  my $result = $self->{xsl}->transform($data,XML::LibXSLT::xpath_to_string(%parameters));
  $self->{format} eq "document" or $result = $result->documentElement;
  $self->log(6,"Produced :\n",$result->toString(1,'UTF-8'));
  return WebSource::Envelope->new(type => "object/dom-node", data => $result);
}

=head1 XSLT EXTENSIONS

The module implements extra pratical XSLT extension functions
These can be used by delaring a prefix for theses extensions whose namespace
is C<http://wwwsource.free.fr/ns/websource/xslt-ext> and declaring that this prefix is
an extension prefix. For example:

  <xsl:stylesheet
      xmlns:wsx="http://wwwsource.free.fr/ns/websource/xslt-ext"
      extension-element-prefixes="wsx"
  >
    ...
  </xsl:stylesheet>

=cut


=head2 reformat-date

Extension function to reformat dates
{http://wwwsource.free.fr/ns/websource/xslt-ext}reformat-date(
   date, targetTemplate, sourceLanguage?
)

=cut

sub reformatDate {
  my ($srcdate,$template,@langs) = @_;
  my $dsttime = undef;
  while(!defined($dsttime) && @langs) {
    my $l = shift @langs;
    my $lang = Date::Language->new($l);
    $dsttime = $lang->str2time($srcdate);
  }
  if($dsttime) {
    return time2str($template,$dsttime);
  } else {
    return "";
  }
}


=head2 string-replace

Extension function to do a string replacement using a perl regular expression
{http://wwwsource.free.fr/ns/websource/xslt-ext}string-replace(regexp, replacement, data)

=cut

sub stringReplace {
  my ($regexp,$replace,$data) = @_;
  $data =~ s/$regexp/$replace/g;
  return $data;
}

=head2 parse-encoded

Extension function parse-encoded which parses an encoded XML string an returns a cleaned-up version
{http://wwwsource.free.fr/ns/websource/xslt-ext}html-lint

=cut

sub htmlLint {
  my ($string) = @_;
  my $temp = "<ws:artificial-root xmlns:ws='urn:artificial-urn'>" . $string . "</ws:artificial-root>";
  my $parser = XML::LibXML->new( recover => 2);
  open(TEMP,">>",'/tmp/ws-xslt.log');
  print TEMP $temp,"\n==============================\n";
  close(TEMP);
  my $doc = $parser->load_xml( string => $temp);
  my @children = $doc->documentElement->childNodes();
  return join("\n", map { $_->toString(1,'utf-8') } @children);
}

=head1 SEE ALSO

WebSource

=cut

1;
