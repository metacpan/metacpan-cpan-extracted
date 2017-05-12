{

=head1 NAME

XML::Filter::XML_Directory_2XHTML - SAX2 filter for munging XML::Directory::SAX output into XHTML

=head1 SYNOPSIS

 use strict;

 package MySAX;
 use base qw (XML::SAX::Base);

 use Image::Magick;

 sub parse_uri {
     my $self = shift;
     my $uri  = shift;

     my $magick = Image::Magick->new();

     if (my $err = $magick->Read($uri)) {
        carp $err;
        return 0;
     }

     if (my $comment = $magick->Get("comment")) {
       $self->SUPER::start_element({Name=>"p"});
       $self->SUPER::characters({Data=>$comment});
       $self->SUPER::end_element({Name=>"p"});
     }

     return 1;
 }

 package main;

 use IO::File;
 use XML::SAX::Writer;

 use XML::Directory::SAX;
 use XML::Filter::XML_Directory_2XHTML;

 my $file   = IO::File->new(">/htdocs/myimages/index.html");
 my $writer = XML::SAX::Writer->new(Output=>$file);
 my $filter = XML::Filter::XML_Directory_2XHTML->new(Handler=>$writer);

 $filter->set_encoding("ISO-8858-1");

 # As Canadian as possible, under the circumstances
 $filter->set_lang("en-ca");

 # Define some images to associate with directory listing.

 $filter->set_images({
                      # Some defaults
	 	      directory => {src=>"/icons/dir.gif",height=>20,width=>20},
		      file      => {src=>"/icons/unknown.gif",height=>20,width=>20},

                      # An image for a file whose media type
                      # as defined by MIME::Types is 'image'.
		      # This is the case for .pl and .pm files
		      image => {src=>"/icons/image3.gif",height=>20,width=>20},
		    });

 # This package inherits from XML::Filter::XML_Directory_2::Base
 # which defines a framework for defining event based callbacks
 # and handlers.

 $filter->set_callbacks({
	 		 link     => sub { return "file://".$_[0];  },

                         # This is not the greatest example because
                         # this is actually what the linktext is set
                         # to if no 'linktext' callback or handler is
                         # defined but you get the idea.
                         linktext => sub { return &basename($_[0]); },

                         title    => sub { return "woot woot woot"; },
		        });

 $filter->set_handlers({
		        file => MySAX::File->new(Handler=>$writer),
		       });

 # In turn, XML::Filter::XML_Directory_2::Base inherits from 
 # XML::Filter::XML_Directory_Pruner which provides hooks for 
 # restricting the output of XML::Directory::SAX

 $filter->exclude(ending=>[".html"]);

 my $directory = XML::Directory::SAX->new(depth=>0,detail=>2,Handler=>$filter);

 $directory->order_by("a");
 $directory->parse_dir("/htdocs/myimages");

=head1 DESCRIPTION

SAX2 filter for munging XML::Directory::SAX output into XHTML.

=cut

package XML::Filter::XML_Directory_2XHTML;
use strict;

use Carp;
use Exporter;
use File::Basename;

use XML::Filter::XML_Directory_2::Base '1.4.4';

$XML::Filter::XML_Directory_2XHTML::VERSION   = '1.3.1';
@XML::Filter::XML_Directory_2XHTML::ISA       = qw (Exporter XML::Filter::XML_Directory_2::Base);
@XML::Filter::XML_Directory_2XHTML::EXPORT    = qw();
@XML::Filter::XML_Directory_2XHTML::EXPORT_OK = qw ();

use constant DTD_HTML_ROOT     => "html";
use constant DTD_HTML_PUBLICID => "-//W3C//DTD XHTML 1.0 Strict//EN";
use constant DTD_HTML_SYSTEMID => "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

=head1 EVENTS

This package allows for the following event callbacks and/or handlers to be registered:

Since this functionaliy is inherited from I<XML::Filter::XML_Directory_2::Base>, please consult the documentation for that package for details.

=head2 Handler events

=over

=item *

I<linktext>

Modify the linktext for the current document. The default value is the filename itself.

=item *

I<file>

Define additional output to follow the name of the current file.

=item *

I<directory>

Define additional output to follow the name of the current directory.

=back

=cut

use constant HANDLER_EVENTS  => qw [ linktext file directory ];

=head2 Callback events

=over

=item *

I<link>

Modify the value of the HTML a@href attribute for the current document. The default value is the absolute path of the document itself.

=item *

I<linktext>

Modify the linktext for the current document. The default value is the filename itself.

=item *

I<title>

Set the value of the HTML <title> element for your document. The default is the absolute path of the directory you are parsing.

=item *

I<file>

Define additional output to follow the name of the current file.

=item *

I<directory>

Define additional output to follow the name of the current directory.

=cut

use constant CALLBACK_EVENTS => qw [ link linktext title file directory ];

=head1 CSS AND HTML

Each directory and file in the XML::Directory output is wrapped in HTML <div> elements. Each element is assigned a class attributes whose name matches the type of file, either a file or directory.

The default CSS styles for those classes are :

 .file {
         border:1px dotted #ccc;
         margin-left:10px;
         margin-bottom:5px;
         margin-top:5px;
         padding-right:50px;
       }

 .directory {
        border:1px dotted #666;
        margin-left:10px;
        margin-bottom:10px;
        }

 .thumbnail { display: inline; }

They can be altered by passing a user-defined CSS stylesheet via the filter's I<set_styles> object method. You may also use the I<set_style> method to override the default and assign styles via the HTML <style> element.

Example HTML output:

 <div class = "(file|directory)" id = "...">
  <div class = "thumbnail">
   <img src = "..." />
  </div>
  <a href = "...">Hello World picture</a>
 </div>

=head1 OBJECT METHODS

=head2 $pkg = XML::Filter::XML_Directory_2XHTML->new()

Object constructor. Returns an object. Woot!

=cut

=head2 $pkg->set_lang($lang)

Set the language code to be assigned to the <html@xml:lang> and <html@lang> attributes.

=cut

sub set_lang {
  my $self = shift;
  $self->{__PACKAGE__.'__lang'} = $_[0];
}

=head2 $pkg->set_images(\%args)

Define image files to be included with a file or a directory.

Valid arguments are a hash ref whose key may be :

=over

=item *

B<directory>

=item *

B<file>

=item

I<string> - the value returned by the I<MIME::Types::mediaType> function for a document.

=back

Each key defines a value which is also a hash reference whose keys are :

=over

=item *

I<src>

String. Required.

=item *

I<height>

Int. Required.

=item *

I<width>

Int. Required.

=item *

I<alt>

String.

=back

Alternately, you may pass a code reference as the key value. If you do, your code reference wil be passed the absolute path of the current file as the first, and only, argument.

Your code reference should return a hash reference whose key/value pairs are the same as those outlined above.

=cut

sub set_images {
  my $self = shift;
  my $args = shift;

  if (ref($args) ne "HASH") {
    carp "Images must be passed as a hash ref of hash references.";
    return 0;
  }

  foreach my $img (keys %$args) {
    my $ref = ref($args->{$img});

    unless ($ref =~ /^(HASH|CODE)$/) {
      carp "Images must be passed as a hash ref of hash references or code references.";
      next;
    }

    if ($ref eq "CODE") {
      $self->{'__images'}{$img} = $args->{$img};
      next;
    }

    foreach ("src","height","width") {
      if (! $args->{$img}->{$_}) {
	carp "You must define an '$_' property for your image.";
	next;
      }
    }

    $self->{'__images'}{$img} = $args->{$img};
  }

  return 1;
}

=head2 $pkg->set_styles(\@styles)

Define additional stylesheets for your document.

Valid arguments are an array reference of hash reference. Each hash ref may contain the following keys:

=over

=item *

I<href>

String. Required.

=item *

I<rel>

String. Default is "stylesheet"

=item *

I<media>

String. Default is "all"

=item *

I<title>

=back

=cut

sub set_styles {
  my $self = shift;
  my $args = shift;

  if (ref($args) ne "ARRAY") {
    carp "Styles must be passed as an array ref of hash references.";
    return 0;
  }

  foreach my $css (@{$args}) {
    if (ref($css) ne "HASH") {
    carp "Styles must be passed as an array ref of hash references.";
      next;
    }
    
    if (! $css->{'href'}) {
      carp "You must define an 'href' property for your stylesheet.";
      next;
    }

    push @{$self->{'__styles'}} , $css;
  }

  return 1;
}

=head2 $pkg->set_style(\$css)

You may use this method to override the default styles altogether without also assigning remote stylesheets.

 $pkg->set_style(\qq(.file{ border:2px dotted pink};));

=cut

sub set_style {
  my $self = shift;
  if (ref($_[0]) eq "SCALAR") {
    $self->{__PACKAGE__.'__css'} = $_[0];
  }
}

=head2 $pkg->set_scripts(\@scripts)

Define scripts for your document.

Valid arguments are an array reference of hash reference. Each hash ref may contain the following keys:

=over

=item *

I<src>

String. Required.

=back

=cut

sub set_scripts {
  my $self = shift;
  my $args = shift;

  if (ref($args) ne "ARRAY") {
    carp "Scripts must be passed as an array ref of hash references.";
    return 0;
  }

  foreach my $js (@{$args}) {
    if (ref($js) ne "HASH") {
    carp "Scripts must be passed as an array ref of hash references.";
      next;
    }

    if (! $js->{'src'}) {
      carp "You must define an 'src' property for your stylesheet.";
      next;
    }

    push @{$self->{'__scripts'}} , $js;
  }

  return 1;
}

=head2 $pkg->set_handlers(\%args)

Please consults the docs for I<XML::Filter::XML_Directory_2::Base> for details

=head2 $pkg->set_callbacks(\%args)

Please consults the docs for I<XML::Filter::XML_Directory_2::Base> for details

=cut

sub _stylesheets {
  my $self = shift;

  $self->SUPER::start_element({Name=>"style",
			       Attributes=>{"{}type"=>{
						       Name=>"type",
						       Value=>"text/css",
						       LocalName=>"type",
						       NameSpaceURI=>""},
					   },
			      });

  if ($self->{__PACKAGE__.'__css'}) {
    $self->comment({Data=>${$self->{__PACKAGE__.'__css'}}});
  }

  else {
    $self->comment({Data=>qq(
.file { 
         border:1px dotted #ccc;
         margin-left:10px;
         margin-bottom:5px;
         margin-top:5px;
         padding-right:50px;
       }
 .directory {
        border:1px dotted #666;
        margin-left:10px;
        margin-bottom:10px;
        }
 .thumbnail { display:inline; }

)});
  }

  $self->SUPER::end_element({Name=>"style"});

  # 

  if (ref($self->{'__styles'}) ne "ARRAY") {
    return 1;
  }
  
  foreach my $style (@{$self->{'__styles'}}) {

    $self->SUPER::start_element({Name=>"link",Attributes=>{
							   "{}href"  => {Name=>"href",
									 Value=>$style->{'href'},
									 Prefix=>"",
									 LocalName=>"href",
									 NameSpaceURI=>""},
							   "{}type"  => {Name=>"type",
									 Value=>"text/css",
									 LocalName=>"type",
									 NameSpaceURI=>""},
							   "{}rel"   => {Name=>"rel",
									 Value=>($style->{'rel'} || "stylesheet"),
									 Prefix=>"",
									 LocalName=>"rel",
									 NameSpaceURI=>""},
							   "{}media" => {Name=>"media",
									 Value=>($style->{'media'} || "all"),
									 Prefix=>"",
									 LocalName=>"media",
									 NameSpaceURI=>""},
							   "{}title" => {Name=>"title",
									 Value=>($style->{'title'} || ""),
									 Prefix=>"",
									 LocalName=>"title",
									 NameSpaceURI=>""},
							  }});
    $self->SUPER::end_element({Name=>"link"});
  }

  return 1;
}

sub _scripts {
  my $self = shift;

  foreach my $style (@{$self->{'__scripts'}}) {

    $self->SUPER::start_element({Name=>"script",Attributes=>{
							     "{}href"  => {Name=>"src",
									   Value=>$style->{'src'},
									   Prefix=>"",
									   LocalName=>"src",
									   NameSpaceURI=>""},
							     "{}type"  => {Name=>"type",
									   Value=>"text/javascript",
									   LocalName=>"type",
									   NameSpaceURI=>""},
							    }});
    $self->SUPER::comment({Data=>""});
    $self->SUPER::end_element({Name=>"script"});
  }

  return 1;
}

sub _image {
  my $self = shift;
  my $type = shift;
  my $data = shift;

  if (! $type) {
    return 0;
  }

  my $src = $self->{'__images'}{$type};

  if (! $src) {
    return 0;
  }

  if (ref($src) eq "CODE") {
    $src = &$src($self->build_uri($data)."/".&basename($self->current_location()));

    if (ref($src) ne "HASH") { return 0; }

    foreach ("src","height","width") {
      if (! $src->{$_}) { return 0; }
    }

  }

  $self->SUPER::start_element({Name=>"div",__PACKAGE__->attributes(class=>"thumbnail")});
  $self->SUPER::start_element({Name=>"img",Attributes=>{
							"{}src"  => {Name=>"src",
								     Value=>$src->{'src'},
								     Prefix=>"",
								     LocalName=>"src",
								     NameSpaceURI=>""},
							"{}alt"  => {Name=>"alt",
								     Value=>($src->{'alt'} || $type),
								     Prefix=>"",
								     LocalName=>"alt",
								     NameSpaceURI=>""},
							"{}height" => {Name=>"height",
								       Value=>$src->{'height'},
								       Prefix=>"",
								       LocalName=>"height",
								       NameSpaceURI=>""},
							"{}width"  => {Name=>"width",
								       Value=>$src->{'width'},
								       Prefix=>"",
								       LocalName=>"width",
								       NameSpaceURI=>""},
						       }});
  $self->SUPER::end_element({Name=>"img"});
  $self->SUPER::end_element({Name=>"div"});
  return 1;
}

sub _link {
  my $self = shift;
  my $data = shift;

  $self->SUPER::start_element({
			       Name=>"a",
			       __PACKAGE__->attributes(href=>$self->make_link($data)),
			      });

  #

  if (my $h = $self->retrieve_handler("linktext")) {
    $self->SUPER::characters({Data=>$h->parse_uri($self->build_uri($data))});
  }
  
  elsif (my $c = $self->retrieve_callback("linktext")) {
    $self->SUPER::characters({Data=>&$c(
					$self->build_uri($data),
					$data->{Attributes}->{'{}name'}->{Value}
				       )});
  }
  
  else {
    $self->SUPER::characters({Data=>&basename($self->make_link($data))});
  }

  #

  $self->SUPER::end_element({Name=>"a"});
  return 1;
}

sub handler_events {
  return HANDLER_EVENTS;
}

sub callback_events {
  return CALLBACK_EVENTS;
}

# SAX METHODS

sub start_document {
  my $self = shift;
  $self->SUPER::start_document();

  $self->SUPER::xml_decl({Version  => "1.0",
			  Encoding => $self->encoding()});

  $self->SUPER::start_dtd({Name     => DTD_HTML_ROOT,
			   PublicId => DTD_HTML_PUBLICID,
			   SystemId => DTD_HTML_SYSTEMID});
  $self->SUPER::end_dtd();

  $self->SUPER::start_prefix_mapping({Prefix => "",
				     NamespaceURI => "http://www.w3.org/1999/xhtml"});

  my %attrs = ();

  if (my $lang = $self->{__PACKAGE__.'__lang'}) {
    %attrs = __PACKAGE__->attributes(lang=>$lang,"xml:lang"=>$lang);
  }

  $self->SUPER::start_element({Name=>DTD_HTML_ROOT,%attrs});
  $self->SUPER::end_prefix_mapping({Prefix=>""});

  return 1;
}

sub end_document {
  my $self = shift;
  $self->SUPER::end_element({Name=>DTD_HTML_ROOT});
  $self->SUPER::end_document();
  return 1;
}

sub start_cdata {}

sub end_cdata {}

sub start_dtd { }

sub end_dtd { }

sub element_decl {}

sub internal_entity_decl {}

sub start_element {
  my $self = shift;
  my $data = shift;

  if (! $self->on_enter_start_element($data)) {
    return 0;
  }

  if ($data->{Name} =~ /^(file|directory)$/) {
    my $name = lc $1;

    $self->{'__'.$name.'name'} = $data->{Attributes}->{'{}name'}->{Value};

    $self->SUPER::start_element({Name=>"div",
				 __PACKAGE__->attributes(class=>$name,id=>$self->generate_id())});

    my $type = ($name eq "directory") ? "directory" :
      ($self->mtype($self->{'__filename'}) || "file");

    $self->_image($type);
    $self->_link($data);

    if (my $h = $self->retrieve_handler($name)) {
      $h->parse_uri($self->build_uri($data));
    }

    elsif (my $c = $self->retrieve_callback($name)) {
      $self->SUPER::characters({Data=>&$c($self->build_uri($data))});
    }

    else {}
  }

  return 1;
}

sub end_element {
  my $self = shift;
  my $data = shift;

  $self->on_enter_end_element($data);

  if ($data->{Name} eq "head") {

    $self->SUPER::start_element({Name=>"head"});

    #

    my $title = $self->current_location() || &basename($self->build_uri($data));

    if (my $c = $self->retrieve_callback("title")) {
      $title = &$c();
    }

    $self->SUPER::start_element({Name=>"title"});
    $self->SUPER::characters({Data=>$title});
    $self->SUPER::end_element({Name=>"title"});

    #

    $self->_stylesheets();
    $self->_scripts();

    $self->SUPER::end_element({Name=>"head"});
    $self->SUPER::start_element({Name=>"body"});

    $self->{'__body'} ++;
  }

  if (($self->start_level()) && 
      ($self->current_level() > $self->start_level()) && 
      (! $self->skip_level())) {

    if ($data->{Name} =~ /^(directory|file)$/) {
      $self->SUPER::end_element({Name=>"div"});
    }
  }

  if ($data->{Name} eq "dirtree") {
    $self->SUPER::end_element({Name=>"body"});
  }

  $self->on_exit_end_element($data);

  return 1;
}

sub characters {
  my $self = shift;
  my $data = shift;
  $self->on_characters($data);
  return 1;
}

=head1 VERSION

1.3.1

=head1 DATE

July 22, 2002

=head1 AUTHOR

Aaron Straup Cope

=head1 TO DO

=over

=item *

Add hooks to set <meta> tags

=item *

Add hooks to set <link> tags

=back

=head1 SEE ALSO

L<XML::Filter::XML_Directory_2::Base>

L<XML::Directory::SAX>

=head1 LICENSE

Copyright (c) 2002, Aaron Straup Cope. All Rights Reserved.

=cut

return 1;

}
