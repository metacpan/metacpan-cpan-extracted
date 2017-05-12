package WebService::AngelXML::Auth;
use strict;
use XML::Writer qw{};
use CGI qw{};

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.14';
}

=head1 NAME

WebService::AngelXML::Auth - Generates XML Authentication Document for Angel Web service

=head1 SYNOPSIS

  use WebService::AngelXML::Auth;
  my $ws = WebService::AngelXML::Auth->new();
  $ws->allow(1) if "test";
  print $ws->header, $ws->response;

=head1 DESCRIPTION

WebService::AngelXML::Auth is a Perl object oriented interface that allows for the creation of the XML response required for AngleXML Authentication.

=head1 USAGE

  use WebService::AngelXML::Auth;
  my $ws=WebService::AngelXML::Auth->new();
  if ("Some test here") {
    $ws->allow(1);
  } else {
    $ws->deny(1); #default
  }
  print $ws->header, $ws->response;

=head1 CONSTRUCTOR

=head2 new

  my $ws=WebService::AngelXML::Auth->new(
           cgi      => $query,     #pass this if already constructed else will construct
           allow    => 0,          #allow and deny are both stored in $ws->{'deny'};
           deny     => 1,          #default is deny=1 only set deny=0 if you are permissive
           mimetype => "text/xml", #default is application/vnd.angle-xml.xml+xml
           page     => "/1000",    #default next page is "/1000"
                             );

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=cut

sub initialize {
  my $self=shift;
  %$self=@_;
  $self->allow(delete $self->{'allow'}) if defined $self->{'allow'};
  $self->deny(1)                    unless defined $self->{'deny'};
  $self->cgi(CGI->new)              unless ref($self->cgi) eq 'CGI';
  $self->mimetype("application/vnd.angle-xml.xml+xml")
                                    unless defined $self->mimetype;
  $self->param_id("id")             unless defined $self->param_id;
  $self->param_pin("pin")           unless defined $self->param_pin;
  $self->param_page("page")         unless defined $self->param_page;
  $self->prompt(".")                unless defined $self->prompt;
  $self->page(delete $self->{'page'}) if defined $self->{'page'};
  $self->page("/1000")              unless defined $self->page;
}

=head2 allow

Set or returns the current allow state.  Allow and deny methods are inversly related.

You may set the allow and deny methods with any value that Perl evaluates to true or false. However, they will always return "-1" for true and "0" for false.

  if ($ws->allow) { "Do something!" }
  print $ws->allow;  #will always return "-1" for true and "0" for false
  $ws->allow(0);     #will set the allow to "0" and the deny to "-1"
  $ws->allow(1);     #will set the allow to "-1" and the deny to "0"

=cut

sub allow {
  my $self=shift;
  if (@_) {
    my $value=shift;
    $self->{'deny'} = $value ? "0" : "-1";
  }
  return $self->{'deny'} ? "0" : "-1";
}

=head2 deny

Set or returns the current deny state.  Allow and deny methods are inversly related.

You may set the allow and deny methods with any value that Perl evaluates to true or false. However, they will always return -1 for true and 0 for false.

  if ($ws->deny) { "Do something!" }
  print $ws->deny;  #will always return -1 for true and 0 for false
  $ws->deny(0);     #will set the deny to "0" and the allow to "-1"
  $ws->deny(1);     #will set the deny to "-1" and the allow to "0"

=cut

sub deny {
  my $self=shift;
  if (@_) {
    my $value=shift;
    $self->{'deny'} = $value ? "-1" : "0";
  }
  return $self->{'deny'} ? "-1" : "0";
}

=head2 response

Returns an XML document with an XML declaration and a root name of "ANGELXML"

  print $ws->response;

Example (Deny):

  <ANGELXML>
    <MESSAGE>
      <PLAY>
        <PROMPT type="text">.</PROMPT>
      </PLAY>
      <GOTO destination="/1000" />
    </MESSAGE>
    <VARIABLES>
      <VAR name="status_code" value="-1" />
    </VARIABLES>
  </ANGELXML>

=cut

sub response {
  my $self=shift;
  my $document='';
  my $writer=XML::Writer->new(OUTPUT=>\$document, DATA_MODE=>1, DATA_INDENT=>2);
  
  $writer->startTag("ANGELXML");
    $writer->startTag("MESSAGE");
      $writer->startTag("PLAY");
        $writer->startTag("PROMPT", type=>"text");
          $writer->characters($self->prompt);
        $writer->endTag("PROMPT");
      $writer->endTag("PLAY");
      $writer->emptyTag("GOTO", destination=>$self->page);
    $writer->endTag("MESSAGE");
    $writer->startTag("VARIABLES");
    $writer->emptyTag("VAR", name=>"status_code", value=>$self->deny);
    $writer->endTag("VARIABLES");
  $writer->endTag("ANGELXML");
  $writer->end();
  return $document;
}

=head2 header

  print $document->header;  

Example:

  Content-Type: application/vnd.angle-xml.xml+xml

=cut

sub header {
  my $self=shift;
  return sprintf("Content-Type: %s\n\n", $self->mimetype);
}

=head2 mimetype

Sets or returns mime type the default is application/vnd.angle-xml.xml+xml 

  $ws->mimetype('text/xml'); #This works better when testing with MSIE
  my $mt=$ws->mimetype;

=cut

sub mimetype {
  my $self=shift;
  if (@_) {
    $self->{'mimetype'}=shift;
  }
  return $self->{'mimetype'};
}

=head2 cgi

Sets or returns the cgi object which must be CGI from cpan.  Default is to construct a new CGI object.  If you already have a CGI object, you MUST pass it on construction.

  $cgi=CGI->new("id=9999;pin=0000;page=/1000");
  $ws=WebService::AngelXML::Auth->new(cgi=>$cgi);

DO NOT do this as we would have already created two CGI objects.

  $cgi=CGI->new("id=9999;pin=0000;page=/1000"); #a new CGI object is created
  $ws=WebService::AngelXML::Auth->new(); #a new CGI object is created on initialization
  $ws->cgi($cgi); #this CGI object may not be iniatialized correctly

CGI object is fully functional

  print $ws->cgi->p("Hello World!");  #All CGI methods are available

=cut

sub cgi {
  my $self=shift;
  if (@_) {
    my $obj=shift;
    $self->{'cgi'}=$obj if ref($obj) eq 'CGI';
  }
  return $self->{'cgi'};
}

=head2 id

Returns the user id which is passed from the CGI parameter.  The default CGI parameter is "id" but can be overriden by the param_id method.

  print $ws->id;
  $ws->id("0000");  #if you want to set it for testing.

=cut

sub id {
  my $self=shift;
  if (@_) {
    $self->cgi->param(-name=>$self->param_id, -value=>shift);
  }
  my $return=$self->cgi->param(-name=>$self->param_id);
  return $return;
}

=head2 param_id

The value of the CGI parameter holding the value of the user id.

  $ws->param_id("id");  #default

=cut

sub param_id {
  my $self=shift();
  $self->{'param_id'} = shift if @_;
  return $self->{'param_id'};
}

=head2 pin

Returns the user pin which is passed from the CGI parameter.  The default CGI parameter is "pin" but can be overriden by the param_pin method.

  print $ws->pin;
  $ws->pin("0000");  #if you want to set it for testing.

=cut

sub pin {
  my $self=shift;
  if (@_) {
    $self->cgi->param(-name=>$self->param_pin, -value=>shift);
  }
  my $return=$self->cgi->param(-name=>$self->param_pin);
  return $return;
}

=head2 param_pin

The value of the CGI parameter holding the value of the user pin.

  $ws->param_pin("pin"); #default

=cut

sub param_pin {
  my $self=shift;
  $self->{'param_pin'}=shift if @_;
  return $self->{'param_pin'};
}

=head2 page

Returns the authentication next page which can be passed from the POST parameter. See param_page method.

Three ways to set next page.

  $ws=WebService::AngelXML::Auth->new(page=>"/1000");      #during construction
  $ws->page("/1000");                                      #after constructing
  script.cgi?page=/1000                                    #as cgi parameter

=cut

sub page {
  my $self=shift;
  if (@_) {
    my $value=shift;
    $self->cgi->param(-name=>$self->param_page, -value=>$value);
  }
  return $self->cgi->param(-name=>$self->param_page);
}

=head2 param_page

The value of the CGI parameter holding the value of the next page.

  $ws->param_page("page"); #default

=cut

sub param_page {
  my $self=shift;
  if (@_) {
    $self->{'param_page'}=shift;
  }
  return $self->{'param_page'};
}

=head2 prompt

Sets or returns the prompt text.

  print $ws->prompt;
  $ws->prompt("."); #default

=cut

sub prompt {
  my $self=shift;
  if (@_) {
    $self->{'prompt'}=shift;
  }
  return $self->{'prompt'};

}

=head1 BUGS

=head1 SUPPORT

Try Angel first then the author of this package who is not an Angel employee

=head1 AUTHOR

    Michael R. Davis (mrdvt92)
    CPAN ID: MRDVT

=head1 COPYRIGHT

Copyright 2008 - STOP, LLC
Copyright 2008 - Michael R. Davis (mrdvt92)

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<XML::Writer> is used by this package to generate XML.

L<CGI> is used by this package to handle HTTP POST/GET parameters.

=cut

1;
