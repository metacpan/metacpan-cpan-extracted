{

=head1 NAME

XML::Filter::XML_Directory_2RSS - SAX2 filter for generating RSS from the output of XML::Directory::SAX

=head1 SYNOPSIS

  use IO::File;
  use XML::SAX::Writer;

  use XML::Directory::SAX;
  use XML::Filter::XML_Directory_2RSS;

  my $rss       = "/path/to/rss.xml";
  my $directory = "/path/to/some/directory";

 #

  my $output = IO::File->new(">$rss");
  my $writer = XML::SAX::Writer->new(Output=>$output);
  my $filter = XML::Filter::XML_Directory_2RSS->new(Handler=>$writer);

 # Various RSS meta data methods
  
  $rss->uri("http://www.foo.com/rss.xml");

  $rss->channel_data({title      => "foo",
                      link       => "http://foo.com",
                      subject    => "bar",
                      descripion => "foo is to bar as bar is to foo"});

  $rss->generator($0);

 # Set up one or more events for affecting the 
 # data describe in your RSS document

  $rss->callbacks({link => \&do_link});
  $rss->handlers({title=>MySax::Title->new(Handler=>$writer)});

 # Describe items to be explicily excluded (or included)
 # in your RSS document.

  $rss->exclude(exclude=>["RCS","CVS"],ending=>["~"]);

 # Parse parse parse

  my $directory = XML::Directory::SAX->new(Handler => $filter,
                                           detail  => 2,
                                           depth   => 1);

  $directory->order_by("a");
  $directory->parse_dir($directory);

 # 

  sub do_link { 
    my $link = shift; 
    $link =~ s!$directory!http://www.foo.com!s; 
    return $link; 
  }

=head1 DESCRIPTION

SAX2 filter for generating RSS from the output of XML::Directory::SAX.

=head1 NOTES

=over

=item *

This package has very limited support for RSS modules. I'm workin' on it.

=back

=cut

package XML::Filter::XML_Directory_2RSS;
use strict;

use base qw (XML::Filter::XML_Directory_2RSS::Base);
use XML::Filter::XML_Directory_2RSS::Items;

use Carp;

$XML::Filter::XML_Directory_2RSS::VERSION = '0.9.1';

=head1 OBJECT METHODS

=head2 $pkg->encoding($enc)

Set the encoding type for your RSS document. Default is I<UTF-8>

=cut

sub encoding {
  my $self = shift;
  $self->{'__encoding'} = $_[0];
}

=head2 $pkg->uri($uri)

Set the URI for your RSS document. This is the value of the I<channel@rdf:about> attribute.

=cut

sub uri {
  my $self = shift;
  $self->{'__uri'} = $_[0];
}

=head2 $pkg->channel_data(\%args)

Set channel data for your RSS document.

Valid arguments are :

=over

=item *

B<title>

String.

=item *

B<link>

String.

=item *

B<subject>

String.

=item *

B<description>

String.

=item *

B<dc:rights>

String.

=item *

B<dc:publisher>

String.

=item *

B<dc:creator>

String.

=item *

B<dc:language>

Array reference.

=back

Proper support for RSS 1.0 modules is in the works.

=cut

sub channel_data {
  my $self = shift;
  my $args = shift;

  if (ref($args) ne "HASH") {
    return undef;
  }

  foreach (keys %$args) {
    unless ($_ =~ /^(title|link|subject|description|dc:publisher|dc:rights|dc:creator|dc:language)$/) {
      carp "'$_' is an unknown element. Skipping.\n";
      delete $args->{$_}; 
    }
  } 
  
  if (($args->{'dc:language'}) && (ref($args->{'dc:language'}) ne "ARRAY")) {
    carp "dc:language mus be passed as an array reference. Skipping.\n";
    delete $args->{'dc:language'};
  }

  $self->{'__channel'} = $args;
  return 1;
}

=head2 $pkg->image(\%args)

Set image data for your RSS document.

Valid arguments are :

=over

=item *

B<title>

String.

=item *

B<url>

String.

=item *

B<link>

String.

=back

=cut

sub image {
  my $self = shift;
  my $args = shift;

  if (ref($args) ne "HASH") {
    return undef;
  }

  foreach (keys %$args) {
    unless ($_ =~ /^(title|url|link)$/) {
      carp "'$_' is an unknown element. Skipping.\n";
      delete $args->{$_};
    }
  }

  $self->{'__image'} = $args;
  return 1;
}

=head2 $pkg->textinput(\%args)

Set textinput data for your RSS document.

Valid arguments are :

=over

=item *

B<title>

String.

=item *

B<description>

String.

=item *

B<name>

String.

=item *

B<link>

String.

=back

=cut

sub textinput {
  my $self = shift;
  my $args = shift;

  if (ref($args) ne "HASH") {
    return undef;
  }

  foreach (keys %$args) {
    unless ($_ =~ /^(title|descripion|name|link)$/) {
      carp "'$_' is an unknown element. Skipping.\n";
      delete $args->{$_};
    }
  }

  $self->{'__textinput'} = $args;

}

=head2 $pkg->generator($agent)

Set generator agent data for your RSS document.

Currently this is really only used by the Syndic8 project, but it's a good idea so we'll add hooks  it for.

=cut

sub generator {
  my $self = shift;
  $self->{'__generator'} = $_[0];
}

=head2 $pkg->exclude(%args)

This method is inherited from I<XML::Filter::XML_Directory_Pruner>. See docs for details.

=head2 $pkg->include(%args);

This method is inherited from I<XML::Filter::XML_Directory_Pruner>. See docs for details.

=head2 $pkg->handlers(\%args)

A is a valid SAX2 thingy for assigning the I<title> or I<description> element of an RSS item. Thingies are like any other SAX2 thingy with a few requirements :

=over

=item *

Must inherit from XML::SAX::Base.

=item *

It's handler must be the same one passed to the XML_Directory_2RSS filter.

=item *

It must define a I<parse_uri> method.

=back

 # If this...

 my $writer = XML::SAX::Writer->new();
 my $rss = XML::Filter::XML_Directory_2RSS->new(Handler=>$writer);
 $rss->handler({title=>MySAX::TitleHandler->new(Handler=>$writer)});

 # Called this...

 package MySAX::TitleHandler;
 use base qw (XML::SAX::Base);
 
 sub parse_uri {
    my ($pkg,$path,$title) = @_;

    $pkg->SUPER::start_prefix_mapping({Prefix=>"me",NamespaceURI=>"..."});
    $pkg->SUPER::start_element({Name=>"me:woot"});
    $pkg->SUPER::characters({Data=>&get_title_from_file($path)});
    $pkg->SUPER::end_element({Name=>"me:woot"});
    $pkg->SUPER::end_prefix_mapping({Prefix=>"me"});
 }

 # Then the output would look like this...

 <item>
  <title>
   <me:woot xmlns:me="...">I Got My Title From the File</me:woot>
  </title>
  <link>...</link>
  <description />
 </item>
  
Valid arguments are :

=over

=item *

B<title>

Object.

The handler's I<parse_uri> method is passed the absolute path of the file and the filename itself.

If no handler, or callback, is defined then the filename will be assigned to the title element.

=item *

B<description>

Object.

The handler's I<parse_uri> method is passed the absolute path of the file.

If no handler, or callback, is defined then the description element will be left empty.

=back

Handlers have a higher precedence than callbacks.

=cut

# See XML::Filter::XML_Directory_2RSS::Base

=head2 $pkg->callbacks(\%args)

Register one of more callbacks for your RSS document.

Callbacks are like I<handlers> except that they are code references instead of SAX2 thingies.

A code reference might be used to munge the I<link> value of an item into a URI suitable for viewing in a web browser.

Valid arguments are

=over

=item *

B<title>

Code reference.

Code references will be passed the absolute path of the file and the filename itself.

If no callback, or handler, is defined then the filename will be assigned to the title element.

=item *

B<link>

Code reference.

Code references will be passed the absolute path of the file.

If no callback is defined then the absolute path of the file will be assigned to the link element.

=item *

B<description>

Code reference.

Code references will be passed the absolute path of the file.

If no callback, or handler, the descripion element will be left empty.

=back

Callbacks have a lower precedence than handlers.

=cut

# See XML::Filter::XML_Directory_2RSS::Base

sub start_document {
  my $self = shift;

  $self->SUPER::start_document();
  $self->SUPER::xml_decl({Version  => "1.0",
			  Encoding => ($self->{'__encoding'} || "UTF-8")});

  $self->start_default_namespaces();
  $self->SUPER::start_element({Name=>"rdf:RDF"});

  return 1;
}

sub end_document {
  my $self = shift;

  $self->add_textinput();
  $self->SUPER::end_element({Name=>"rdf:RDF"});
  $self->end_default_namespaces();
  $self->SUPER::end_document();

  return 1;
}

sub start_element {
  my $self = shift;
  my $data = shift;

  $self->on_enter_start_element($data) || return;

  if ($data->{Name} =~ /^(file|directory)$/) {
    $self->start_item($data);
  }

  return 1;
}

sub end_element {
  my $self = shift;
  my $data = shift;

  $self->on_enter_end_element($data);
  
  if ($data->{Name} eq "head") {
    $self->add_meta_data();
  }

  if (($self->{'__start'}) && 
      ($self->{'__rlevel'} > $self->{'__start'}) && 
      (! $self->{'__skip'})) {
    
    if ($data->{Name} =~ /^(file|directory)$/) {
      $self->prune_cwd($data);
      $self->end_item($data);
    }
  }
  
  $self->on_exit_end_element($data);
}

sub characters {
  my $self = shift;
  my $data = shift;

  $self->on_characters($data);
}

sub start_item {
  my $self = shift;
  my $data = shift;

  # am i a child?

  if (($self->{'__wasa'} eq "directory") && 
      ($self->{'__ima_level'} > $self->{'__wasa_level'})) {
 
    $self->SUPER::start_element({Name=>"thr:children"});
    $self->SUPER::start_element({Name=>"rdf:Seq"});
    $self->{'__children'}->{($self->{'__wasa_level'})} = 1;
  }

  $self->SUPER::start_element({Name       => "item",
			       Attributes => $self->rdf_about($self->make_link($data))});

  # title element
  
  $self->SUPER::start_element({Name=>"title"});
  
  if ($self->{'__handlers'}{'title'}) {
    $self->{'__handlers'}{'description'}->parse_uri($self->build_uri());
  }
  
  elsif ($self->{'__callbacks'}{'title'}) {
    $self->SUPER::characters({Data=>&{$self->{'__callbacks'}{'title'}}($self->build_uri(),$data->{Attributes}->{'{}name'}->{Value})});
  }
  
  else {
    $self->SUPER::characters({Data=>$data->{Attributes}->{'{}name'}->{Value}});
  }
  
  $self->SUPER::end_element({Name=>"title"});
  
  # link element
  
  $self->SUPER::start_element({Name=>"link"});
  $self->SUPER::characters({Data=>$self->make_link($data)});
  $self->SUPER::end_element({Name=>"link"});
  
  # description element
  
  $self->SUPER::start_element({Name=>"description"});
  
  if ($self->{'__handlers'}{'description'}) {
    $self->{'__handlers'}{'description'}->parse_uri($self->build_uri());
  }
  
  elsif ($self->{'__callbacks'}{'description'}) {
    $self->SUPER::characters({Data=>&{$self->{'__callbacks'}{'description'}}($self->build_uri())});
  }
  
  else { }
  
  $self->SUPER::end_element({Name=>"description"});
  
  return 1;
}

sub end_item {
  my $self = shift;
  my $data = shift;

  # do i have children?

  if (($data->{Name} eq "directory") && 
      ($self->{'__children'}{$self->{'__rlevel'}})) {

    $self->SUPER::end_element({Name=>"rdf:Seq"});
    $self->SUPER::end_element({Name=>"thr:children"});
    delete $self->{'__children'}{$self->{'__rlevel'}};
  }

  $self->SUPER::end_element({Name=>"item"});
  return 1;
}

sub add_meta_data {
  my $self = shift;

  $self->SUPER::start_element({Name       => "channel",
			       Attributes => $self->rdf_about($self->{'__uri'})});

  foreach my $el ("title","link","subject","description") {
    next if (! defined($self->{'__channel'}{$_}));

    $self->SUPER::start_element({Name=>$_});
    $self->SUPER::characters({Data=>$self->{'__channel'}{$_}});
    $self->SUPER::end_element({Name=>$_});
  }

  # Generator data for the nice people at Syndic8

  if ($self->{'__generator'}) {
    
    $self->SUPER::start_prefix_mapping({Prefix=>"admin",NamespaceURI=>$self->ns_map("admin")});
    $self->SUPER::start_element({Name       => "admin:generatorAgent",
				 Attributes => $self->rdf_resource($self->{'__generator'})});
    $self->SUPER::end_element({Name=> "admin:generatorAgent"});
    $self->SUPER::end_prefix_mapping({Prefix=>"admin"});
  }

  # Some basic Dublin Core elements
  # More to come...

  foreach my $el ("rights","publisher","creator") {
    next if (! defined($self->{'__channel'}{$_}));

    $self->SUPER::start_element({Name=>"dc:$_"});
    $self->SUPER::characters({Data=>$self->{'__channel'}{"dc:$_"}});
    $self->SUPER::end_element({Name=>"dc:$_"});
  }

  if (ref($self->{'__channel'}{'dc:language'}) eq "ARRAY") {
    foreach my $lang (@{$self->{'__channel'}{'dc:language'}}) {

      $self->SUPER::start_element({Name=>"dc:language"});
      $self->SUPER::characters({Data=>$lang});
      $self->SUPER::end_element({Name=>"dc:language"});
    }
  }

  #

  $self->add_channel_items();

  #

  if (ref($self->{'__image'}) eq "HASH") {
    $self->SUPER::start_element({
				 Name       => "image",
				 Attributes => $self->rdf_resource($self->{'__image'}{'url'}),
				});
    $self->SUPER::end_element({Name=>"image"});
  }

  $self->SUPER::end_element({Name=>"channel"});

  $self->add_image();

  return 1;
}

sub add_channel_items {
  my $self = shift;

  $self->SUPER::start_element({Name=>"items"});
  $self->SUPER::start_element({Name=>"rdf:Seq"});

  my $items = XML::Filter::XML_Directory_2RSS::Items->new(Handler=>$self->{Handler});

  my %exclude = ();
  my %include = ();
  
  if (defined($self->{'__exclude'}))          { $exclude{'exclude'}     = $self->{'__exclude'}; }
  if (defined($self->{'__exclude_starting'})) { $exclude{'starting'}    = $self->{'__exclude_starting'}; }
  if (defined($self->{'__exclude_ending'}))   { $exclude{'ending'}      = $self->{'__exclude_ending'}; }
  if (defined($self->{'__exclude_matching'})) { $exclude{'matching'}    = $self->{'__exclude_matching'}; }
  if (defined($self->{'__exclude_subdirs'}))  { $exclude{'directories'} = $self->{'__exclude_subdirs'}; }
  if (defined($self->{'__exclude_files'}))    { $exclude{'files'}       = $self->{'__exclude_subdirs'}; }
  
  if (defined($self->{'__include'}))          { $include{'include'}     = $self->{'__include'}; }
  if (defined($self->{'__include_starting'})) { $include{'starting'}    = $self->{'__include_starting'}; }
  if (defined($self->{'__include_ending'}))   { $include{'ending'}      = $self->{'__include_ending'}; }
  if (defined($self->{'__include_matching'})) { $include{'matching'}    = $self->{'__include_matching'}; }
  if (defined($self->{'__include_subdirs'}))  { $include{'directories'} = $self->{'__include_subdirs'}; }
  if (defined($self->{'__include_files'}))    { $include{'files'}       = $self->{'__include_subdirs'}; }
  
  if (keys %exclude) { $items->exclude(%exclude); }
  if (keys %include) { $items->include(%include); }

  if ($self->{'__callbacks'}{'link'}) {
    $items->callbacks({link=>$self->{'__callbacks'}->{'link'}});
  }

  my $xml_directory = XML::Directory::SAX->new(Handler => $items,
					       depth   => $self->{'__depth'},
					       detail  => $self->{'__detail'});
  
  $xml_directory->order_by($self->{'__orderby'});
  $xml_directory->parse_dir($self->{'__path'});

  $self->SUPER::end_element({Name=>"rdf:Seq"});
  $self->SUPER::end_element({Name=>"items"});
}

sub add_image {
  my $self = shift;

  if (ref($self->{'__image'}) ne "HASH") {
    return 0;
  }

  $self->SUPER::start_element({
			       Name       => "image",
			       Attributes => $self->rdf_about($self->{'__image'}{'url'}),
			      });
  
  foreach my $el ("title","url","link") {
    next if (! defined($self->{'__channel'}{$_}));

    $self->SUPER::start_element({Name=>$_});
    $self->SUPER::characters({Data=>$self->{'__image'}{$_}});
    $self->SUPER::end_element({Name=>$_});
  }
  
  $self->SUPER::end_element({Name=>"image"});
  
  return 1;
}

sub add_textinput {
  my $self = shift;

  if (ref($self->{'__textinput'}) ne "HASH") {
    return undef;
  }

  $self->SUPER::start_element({Name=>"textinput"});

  foreach my $el ("title","description","name","link") {
    next if (! defined($self->{'__textinput'}{$_}));

    $self->SUPER::start_element({Name=>$_});
    $self->SUPER::characters({Data=>$self->{'__textinput'}{$_}});
    $self->SUPER::end_element({Name=>$_});
  }

  # ti:function/ ti:inputType
  # Where are the docs for the 'textinput' module?

  $self->SUPER::end_element({Name=>"textinput"});
}

=head1 VERSION

0.9.1

=head1 DATE

May 24, 2002

=head1 AUTHOR

Aaron Straup Cope

=head1 TO DO

=over

=item *

Proper support for RSS modules.

=back

=head1 SEE ALSO

L<XML::Filter::XML_Directory::Pruner>

L<XML::Directory::SAX>

http://groups.yahoo.com/group/rss-dev/files/specification.html

=head1 LICENSE

Copyright (c) 2002, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
