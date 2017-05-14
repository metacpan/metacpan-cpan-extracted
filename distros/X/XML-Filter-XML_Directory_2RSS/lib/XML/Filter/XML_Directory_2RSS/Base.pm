{

=head1 NAME 

XML::Filter::XML_Directory_2RSS::Base - base class for XML::Filter::XML_Directory_2RSS

=head1 SYNOPSIS

 package XML::Filter::XML_Directory_2RSS
 use base qw (XML::Filter::XML_Directory_2RSS::Base);

=head1 DESCRIPTION

Base class for XML::Filter::XML_Directory_2RSS and XML::Filter::XML_Directory_2RSS::Items

This is used internally by XML::Filter::XML_Directory_2RSS.

=cut

package XML::Filter::XML_Directory_2RSS::Base;
use strict;

$XML::Filter::XML_Directory_2RSS::Base::VERSION = 0.9;

use Carp;

use base qw (XML::Filter::XML_Directory_Pruner);

use constant DEFAULT_NS => ( "","rdf","dc","thr" );

use constant NS => {
		    ""      => "http://purl.org/rss/1.0/", 
		    "admin" => "http://webns.net/mvcb/",
		    "dc"    => "http://purl.org/dc/elements/1.1/", 
		    "rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
		    "sy"    => "http://purl.org/rss/1.0/modules/syndication/",
		    "ti"    => "http://purl.org/rss/1.0/modules/textinput/",
		    "thr"   => "http://purl.org/rss/1.0/modules/threading/",
		   };

sub start_default_namespaces {
  my $self = shift;
  foreach my $prefix (DEFAULT_NS) {
    $self->SUPER::start_prefix_mapping({
					Prefix       => $prefix,
					NamespaceURI => NS->{$prefix},
				       });
  }

  return 1;
}

sub end_default_namespaces {
  my $self = shift;
  foreach my $prefix (DEFAULT_NS) {
    $self->SUPER::end_prefix_mapping({Prefix => $prefix});
  }

  return 1;
}

sub handlers {
  my $self = shift;
  my $args = shift;

  if (ref($args) ne "HASH") {
    return undef;
  }

  foreach ("title","description") {
    next if (! $args->{$_});

    if (! UNIVERSAL::isa($args->{$_},"XML::SAX::Base")) {
      carp "Handler must be derived from XML::SAX::Base";
      next;
    }

    if (! UNIVERSAL::can($args->{$_},"parse_uri")) {
      carp "Handler must define a 'parse_uri' method.\n";
      next;
    }

    $self->{'__handlers'}{$_} = $args->{$_};
  }

  return 1;
}

sub callbacks {
  my $self = shift;
  my $args = shift;

  if (ref($args) ne "HASH") {
    return undef;
  }

  foreach ("title","link","description") {
    next if (! $args->{$_});

    if (ref($args->{$_}) ne "CODE") {
      carp "Not a CODE reference";
      return undef;
    }

    $self->{'__callbacks'}{$_} = $args->{$_};
  }

  return 1;
}

sub on_enter_start_element {
  my $self = shift;
  my $data = shift;

  $self->{'__level'} ++;
  $self->{'__last'} = $data->{Name};

  if ($data->{Name} eq "head") {
      $self->{'__head'} = 1;
  }

  if ((! $self->{'__start'}) && ($data->{Name} eq "directory")) {
    $self->{'__start'} = 1;
    return;
  }
  
  return unless $self->{'__start'};

  #  map { print STDERR " "; } (0..$self->{'__level'});
  #  print STDERR "[$self->{'__level'}] $data->{Name} : $data->{Attributes}->{'{}name'}->{Value}\n";

  if (($data->{'Name'} =~ /^(file|directory)$/) && (! $self->{'__skip'})) {
    $self->{'__ima'} = $1;
    $self->_compare($data->{Attributes}->{'{}name'}->{Value});
  }

  if ($self->{'__skip'}) {
    return 0;
  }

  $self->grow_cwd($data);

  return 1;
}

sub on_enter_end_element {
  my $self = shift;
  my $data = shift;

  if ($data->{Name} eq "head") {
    $self->{'__head'} = 0;
  }

  return 1;
}

sub on_exit_end_element {
  my $self = shift;
  my $data = shift;


  if ($self->{'__skip'} == $self->{'__level'}) {
    $self->{'__skip'} = 0;
  }

  $self->{'__level'} --;

  return 1;
}

sub on_characters {
  my $self = shift;
  my $data = shift;

  if ($self->{'__head'}) {
      $self->{ '__'.$self->{'__last'} } = $data->{Data};
  }

  return 1;
}

sub grow_cwd {
  my $self = shift;
  my $data = shift;

  if ($data->{Name} eq "directory") {
    $self->{'__cwd'} .= "/$data->{Attributes}->{'{}name'}->{Value}";
  }

  return 1;
}

sub prune_cwd {
  my $self = shift;
  my $data = shift;

  if ($data->{Name} eq "directory") {
    $self->{'__cwd'} =~ s/^(.*)\/([^\/]+)$/$1/;
  }

  return 1;
}

sub build_uri {
  my $self = shift;
  my $data = shift;

  my $uri = $self->{'__path'}.$self->{'__cwd'};
  
  if ($data->{Name} eq "file") {
    $uri .= "/$data->{Attributes}->{'{}name'}->{Value}";
  }

  return $uri;
}

sub make_link {
  my $self = shift;
  my $data = shift;

  my $link = $self->build_uri($data);
  
  if ($self->{'__callbacks'}{'link'}) {
    $link = &{$self->{'__callbacks'}{'link'}}($link);
  }
  
  return $link;
}

sub ns_map {
  my $self   = shift;
  my $prefix = shift;
  return NS->{$prefix};
}

sub rdf_resource {
    my $self     = shift;
    my $resource = shift;

    my $ns = NS->{"rdf"};

    return {"{$ns}rdf:resource" => {
	Name         => "rdf:resource",
	Value        => $resource,
	Prefix       => "rdf",
	LocalName    => "resource",
	NamespaceURI => $ns,
    }};
}

sub rdf_about {
    my $self    = shift;
    my $subject = shift;
    
    my $ns = NS->{"rdf"};

    return {"{$ns}rdf:about" => {
	Name         => "rdf:about",
	Value        => $subject,
	Prefix       => "rdf",
	LocalName    => "about",
	NamespaceURI => $ns,
    }};
}

=head1 VERSION

0.9

=head1 DATE

May 14, 2002

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO 

L<XML::Filter::XML_Directory_2RSS>

=head1 LICENSE

Copright (c) 2002, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
