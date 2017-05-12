{

=head1 NAME

XML::Filter::XML_Directory_2::Base - base class for creating XML::Directory to something else SAX filters.

=head1 SYNOPSIS

 package XML::Filter::XML_Directory_2Foo;
 use base qw (XML::Filter::XML_Directory_2::Base);

=head1 DESCRIPTION

Base class for creating XML::Directory to something else SAX filters.

This class inherits from I<XML::Filter::XML_Directory_Pruner>.

=cut

package XML::Filter::XML_Directory_2::Base;
use strict;

use Carp;
use Exporter;
use Digest::MD5 qw (md5_hex);
use XML::Filter::XML_Directory_Pruner '1.3';

$XML::Filter::XML_Directory_2::Base::VERSION   = '1.4.4';
@XML::Filter::XML_Directory_2::Base::ISA       = qw ( XML::Filter::XML_Directory_Pruner );
@XML::Filter::XML_Directory_2::Base::EXPORT    = qw ();
@XML::Filter::XML_Directory_2::Base::EXPORT_OK = qw ();

=head1 PACKAGE METHODS

=head2 __PACKAGE__->attributes(\%args)

This is a simple helper method designed to save typing. 

Value arguments are

=over

=item *

The name of an attribute

=item *

The value of an attribute

=back

Returns a hash with a single key named I<Attributes> whose value is a hash ref for passing to the I<XML::SAX::Base::start_element> method.

This method does not support namespaces (yet.)

=cut

sub attributes {
  my $pkg   = shift;
  my %attrs = @_;
  
  my %saxtributes = ();
  
  foreach (sort keys %attrs) {
    $saxtributes{"{}$_"} = { 
                            Name         => $_,
                            Value        => $attrs{$_},
                            Prefix       => "",
                            LocalName    => $_,
                            NameSpaceURI => "",
                           };
  }

  return (Attributes=>\%saxtributes);
}

=head1 OBJECT METHODS

=head2 $pkg->encoding($type)

=cut

sub encoding {
  my $self = shift;
  my $type = shift;

  if ($type) {
    $self->{__PACKAGE__.'__type'} = $type;
  }

  return $self->{__PACKAGE__.'__type'} || "UTF-8";
}

=head2 $pkg->set_encoding($type)

Alias for I<encoding>

=cut

sub set_encoding {
  my $self = shift;
  $self->encoding(@_);
}

=head2 $pkg->exclude_root($bool)

By default, XML::Directory will include the directory you pass to the I<XML::Directory(::SAX)::parse_dir> method. 

You can use this method to instruct your filter to only include the contents of the root directory and not the directory itself.

=cut

sub exclude_root {
  my $self = shift;
  my $bool = shift;

  if (defined($bool)) {
    $self->{__PACKAGE__.'__includeroot'} = ($bool) ? 0 : 1;
  }

  return $self->{__PACKAGE__.'__includeroot'};
}

=head2 $pkg->start_level()

Read-only.

=cut

sub start_level {
  my $self = shift;
  return $self->{__PACKAGE__.'__start'};
}

=head2 $pkg->cwd()

Read-only.

=cut

sub cwd {
  my $self = shift;
  return $self->{__PACKAGE__.'__cwd'};
}

=head2 $pkg->current_directory()

Short-cut (ahem) for $pkg->cwd()

=cut

sub current_directory {
  return $_[0]->cwd();
}

=head2 $pkg->current_location()

Returns the current location relative to the directory root

=cut

sub current_location {
  my $self = shift;
  return $self->{__PACKAGE__.'__loc'};
}

=head2 $pkg->set_handlers(\%args)

Define one or more valid SAX2 thingies to be called when your package encounters a specific event. Thingies are like any other SAX2 thingy with a few requirements :

=over

=item *

Must inherit from XML::SAX::Base.

=item *

It must define a I<parse_uri> method.

=back

 # If this...

 my $writer = XML::SAX::Writer->new();
 my $rss = XML::Filter::XML_Directory_2RSS->new(Handler=>$writer);
 $rss->set_handlers({title=>MySAX::TitleHandler->new(Handler=>$writer)});

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

Valid events are defined on a per class basis. Your class needs to define a I<handler_events> package method that returns a list of valid handler events.

Handlers have a higher precedence than callbacks.

=cut

sub handler_events { return (); }

sub set_handlers {
  my $self = shift;
  my $args = shift;

  if (ref($args) ne "HASH") {
    return undef;
  }

  foreach ($self->handler_events()) {
    next if (! $args->{$_});

    if (! UNIVERSAL::can($args->{$_},"parse_uri")) {
      carp "Handler must define a 'parse_uri' method.\n";
      next;
    }

    $self->{__PACKAGE__.'__handlers'}{$_} = $args->{$_};
  }

  return 1;
}

=head2 $pkg->retrieve_handler($event_name)

Returns the handler (object) associated with I<$event_name>

=cut

sub retrieve_handler {
  my $self = shift;
  return $self->{__PACKAGE__.'__handlers'}{$_[0]};
}

sub callback_events { return (); }

=head2 $pkg->set_callbacks(\%args)

Register one of more callbacks for your document.

Callbacks are like I<handlers> except that they are code references instead of SAX2 thingies.

A code reference might be used to munge the I<link> value of an item into a URI suitable for viewing in a web browser.

Valid events are defined on a per class basis. Your class needs to define a I<callback_events> package method that returns a list of valid callback events.

Callbacks have a lower precedence than handlers.

=cut

sub set_callbacks {
  my $self = shift;
  my $args = shift;

  if (ref($args) ne "HASH") {
    return undef;
  }

  foreach ($self->callback_events()) {
    next if (! $args->{$_});

    if (ref($args->{$_}) ne "CODE") {
      carp "Not a CODE reference";
      return undef;
    }

    $self->{__PACKAGE__.'__callbacks'}{$_} = $args->{$_};
  }

  return 1;
}

=head2 $pkg->retrieve_callback($event_name)

Return the callback (code reference) associated with I<$event_name>.

=cut

sub retrieve_callback {
  my $self = shift;
  return $self->{__PACKAGE__.'__callbacks'}{$_[0]};
}

=head2 $pkg->generate_id()

Returns an MD5 hash of the path, relative to the root, for the current file

=cut

sub generate_id {
  my $self = shift;
  return "ID".&md5_hex($self->{__PACKAGE__.'__loc'});
}

=head2 $pkg->build_uri(\%data)

Returns the absolute path for the current document.

=cut

sub build_uri {
  my $self = shift;
  my $data = shift;

  my $uri = $self->{__PACKAGE__.'__path'}.$self->{__PACKAGE__.'__cwd'};

  if ($data->{Name} eq "file") {
    $uri .= "/$data->{Attributes}->{'{}name'}->{Value}";
  }

  return $uri;
}

=head2 $pkg->make_link(\%data)

Returns the output of $pkg->build_uri.

If your program has defined a I<link> callback (see above) then the output will be filtered through the callback before being returned your program.

=cut

sub make_link {
  my $self = shift;
  my $data = shift;

  my $link = $self->build_uri($data);

  if (my $c = $self->retrieve_callback("link")) {
    $link = &$c($link);
  }

  return $link;
}

=head2 $pkg->on_enter_start_element(\%data)

This method should be called as the first action in your class' I<start_element> method. It will perform a number of helper actions, like keeping track of the current node level and the absolute path of the current document.

Additionalllly it will check to see if the current node should be included or excluded based on rules defined by I<XML::Filter::XML_Directory_Pruner>.

Returns true if everything is honky-dorry.

Returns false if the current node is to be excluded or if the document has not "started" (see docs for the I<start_level> method.)

=cut

sub on_enter_start_element {
  my $self = shift;
  my $data = shift;

  $self->SUPER::on_enter_start_element($data);
  $self->{__PACKAGE__.'__last'} = $data->{Name};

  if ($data->{Name} eq "head") {
      $self->{__PACKAGE__.'__head'} = 1;
  }

  if ($data->{Name} =~ /^(directory|file)$/) {
    $self->{__PACKAGE__.'__'.$1} ++;
#    map { print " "; } (0..$self->{__PACKAGE__.'__'.$1});
#    print $self->{__PACKAGE__.'__'.$1} ." ($1) $data->{Attributes}->{'{}name'}->{Value} ".__PACKAGE__."\n";
  }

  #

  if ((! $self->{__PACKAGE__.'__start'}) && ($data->{Name} =~ /^(file|directory)$/)) {

    if (! exists($self->{__PACKAGE__.'__includeroot'})) {
      $self->{__PACKAGE__.'__start'} = $self->current_level();
      return 1;
    }

    else {

      if ((! $self->{__PACKAGE__.'__includeroot'}) &&
	  (($self->{__PACKAGE__.'__file'} == 1) || ($self->{__PACKAGE__.'__directory'} == 2))) {

	$self->{__PACKAGE__.'__start'} = $self->current_level();
	$self->grow_cwd($data);

	$self->compare($data);

	if (! $self->skip_level()) {
	  return 1;
	}

	$self->prune_cwd($data);
	return 0;
      }
    }

  }

  #

  if (! $self->{__PACKAGE__.'__start'}) {
    return 0;
  }

  $self->compare($data);

  if ($self->skip_level()) {
    return 0;
  }

  $self->grow_cwd($data);
  return 1;
}

=head2 $pkg->on_enter_end_element(\%data)


=cut

sub on_enter_end_element {
  my $self = shift;
  my $data = shift;

  if ($data->{Name} eq "head") {
    $self->{__PACKAGE__.'__head'} = 0;
  }

  return 1;
}

=head2 $pkg->on_exit_end_element(\%data)

This method should be called as the first action in your class' I<end_element> method.

=cut

sub on_exit_end_element {
  my $self = shift;
  my $data = shift;

  unless ($self->skip_level()) {
    $self->prune_cwd($data);
  }

  if ($data->{Name} =~ /^(directory|file)$/) {
    $self->{__PACKAGE__.'__'.$1} --;
  }

  $self->SUPER::on_exit_end_element($data);
  return 1;
}

=head2 $pkg->on_characters(\%data)

This method should be called as the first action in your class' I<characters> method.

=cut

sub on_characters {
  my $self = shift;
  my $data = shift;

  if ($self->{__PACKAGE__.'__head'}) {
    $self->{ __PACKAGE__.'__'.$self->{__PACKAGE__.'__last'} } ||= $data->{Data};
  }

  return 1;
}

# =head2 $pkg->grow_cwd(\%data)
#
# =cut

sub grow_cwd {
  my $self = shift;
  my $data = shift;

  if ($data->{Name} =~ /^(file|directory)$/) {
    $self->{__PACKAGE__.'__loc'} .= "/$data->{Attributes}->{'{}name'}->{Value}";
  }

  if ($data->{Name} eq "directory") {
    $self->{__PACKAGE__.'__cwd'} .= "/$data->{Attributes}->{'{}name'}->{Value}";
    # print STDERR $self->{__PACKAGE__.'__cwd'}."\n";
  }

  return 1;
}

# =head2 $pkg->prune_cwd(\%data)
#
# =cut

sub prune_cwd {
  my $self = shift;
  my $data = shift;

  if ($data->{Name} =~ /^(file|directory)$/) {
    $self->{__PACKAGE__.'__loc'} =~ s/^(.*)\/([^\/]+)$/$1/;
  }

  if ($data->{Name} eq "directory") {
    $self->{__PACKAGE__.'__cwd'} =~ s/^(.*)\/([^\/]+)$/$1/;
    # print STDERR "[prune] ".$self->{__PACKAGE__.'__cwd'}."\n";
  }


  return 1;
}

=head1 VERSION

1.4.4

=head1 DATE

July 22, 2002

=head1 AUTHOR

Aaron Straup Cope

=head1 TO DO

=over

=item *

Investigate mucking with the symbol table to hide having to call the various on_foo_bar methods.

=back

=head1 SEE ALSO

L<XML::Directory::SAX>

L<XML::Filter::XML_Directory_Pruner>

=head1 LICENSE

Copright (c) 2002, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}

