# $Id: NSNormalise.pm,v 1.5 2002/10/11 02:01:43 grantm Exp $

package XML::Filter::NSNormalise;

use strict;
use warnings;
use Carp;

use XML::SAX::Base; 

use vars qw($VERSION @ISA);

$VERSION = '0.04';

@ISA = qw(XML::SAX::Base);


##############################################################################
# Constructor: new()
#
# Validate mappings and delegate to base class constructor.
#

sub new {
  my $class = shift;
  my %args  = @_;

  if(!$args{Map}  or  !ref($args{Map})  or  !%{$args{Map}}) {
    croak "No 'Map' option in call to XML::Filter::NSNormalise->new()";
  }
  my %revmap;
  while(my($uri, $prefix) = each %{$args{Map}} ) {
    if($revmap{$prefix}  and  $revmap{$prefix} ne $uri) {
      croak "Multiple URIs mapped to prefix '$prefix'"
    }
    $revmap{$prefix} = $uri;
  }
  
  $class->SUPER::new(@_, ReverseMap => \%revmap);
}


##############################################################################
# Method: start_prefix_mapping()
# Method: end_prefix_mapping()
#
# Intercept any namespace prefix events for which we have a mapping and 
# normalise the 'Prefix'.
#

sub start_prefix_mapping {
  my $self = shift;
  my $event = shift;

  if($self->{Map}->{$event->{NamespaceURI}}) {
    $event = { %$event };
    $event->{Prefix} = $self->{Map}->{$event->{NamespaceURI}};
  }
  $self->SUPER::start_prefix_mapping($event);
}

sub end_prefix_mapping {
  my $self = shift;
  my $event = shift;

  if($self->{Map}->{$event->{NamespaceURI}}) {
    $event = { %$event };
    $event->{Prefix} = $self->{Map}->{$event->{NamespaceURI}};
  }
  $self->SUPER::end_prefix_mapping($event);
}


##############################################################################
# Method: start_element()
# Method: end_element()
#
# - Fix the 'Prefix' and 'Name' data for elements in a mapped namespace
# - Fix the 'LocalName' and 'Name' data for namespace declaration attributes
# - Fix the 'Prefix' and 'Name' data for attributes in a mapped namespace
#

sub start_element {
  my $self = shift;
  my $event = shift;

  $event = { %$event }; # make a (shallow) copy of the event data
  my %new_attr;

  if($self->{Map}->{$event->{NamespaceURI}}) {
    $event->{Prefix} = $self->{Map}->{$event->{NamespaceURI}};
    $event->{Name}   = "$event->{Prefix}:$event->{LocalName}";
  }
  foreach my $key (keys %{$event->{Attributes}}) {
    my $attr = $event->{Attributes}->{$key};

    if($attr->{Prefix} eq 'xmlns') {
      if($self->{ReverseMap}->{$attr->{LocalName}}) {
        if($attr->{Value} ne $self->{ReverseMap}->{$attr->{LocalName}}) {
	  die "Cannot map '$self->{ReverseMap}->{$attr->{LocalName}}' to " .
	      "'$attr->{LocalName}' - prefix already occurs in document";
        }
      }
      if($self->{Map}->{$attr->{Value}}) {
	$attr = { %$attr };
        $attr->{LocalName} = $self->{Map}->{$attr->{Value}};
        $attr->{Name}      = "xmlns:$attr->{LocalName}";
	$new_attr{"{http://www.w3.org/2000/xmlns/}$attr->{LocalName}"} = $attr;
      }
      else {
        $new_attr{$key} = $attr;
      }
    }
    elsif($self->{Map}->{$attr->{NamespaceURI}}) {
      $attr = { %$attr };
      $attr->{Prefix} = $self->{Map}->{$attr->{NamespaceURI}};
      $attr->{Name}   = "$attr->{Prefix}:$attr->{LocalName}";
      my $new_key = "{$attr->{NamespaceURI}}$attr->{LocalName}";
      $new_attr{$new_key} = $attr;
      delete($event->{Attributes}->{$key});
    }
    else {
      $new_attr{$key} = $attr;
    }

  }
  $event->{Attributes} = \%new_attr;
  $self->SUPER::start_element($event);
}

sub end_element {
  my $self = shift;
  my $event = shift;

  if($self->{Map}->{$event->{NamespaceURI}}) {
    $event = { %$event };
    $event->{Prefix} = $self->{Map}->{$event->{NamespaceURI}};
    $event->{Name}   = "$event->{Prefix}:$event->{LocalName}";
  }
  $self->SUPER::end_element($event);
}


1;
__END__

=head1 NAME

XML::Filter::NSNormalise - SAX filter to normalise namespace prefixes

=head1 SYNOPSIS

  use XML::SAX::Machines qw( :all );
  use XML::Filter::NSNormalise;

  my $p = Pipeline(
    XML::Filter::NSNormalise->new(
      Map => {
        'http://purl.org/dc/elements/1.1/' => 'dc',
        'http://purl.org/rss/1.0/modules/syndication/' => 'syn'
      }
    )
    => \*STDOUT
  );

  $p->parse_uri($filename);



=head1 DESCRIPTION

This SAX (version 2) filter can be used to transform documents to ensure the
prefixes associated with namespaces are used consistently.

For example, feeding this document...

  <rdf:RDF
   xmlns="http://purl.org/rss/1.0/"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:theonetruedublincore="http://purl.org/dc/elements/1.1/" >
    <theonetruedublincore:date>2002-10-08</theonetruedublincore:date>
  </rdf:RDF>

... through this filter ...

  XML::Filter::NSNormalise->new(
    Map => {
      'http://purl.org/dc/elements/1.1/' => 'dc'
    }
  )

... would produce this output ...

  <rdf:RDF
   xmlns="http://purl.org/rss/1.0/"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:dc="http://purl.org/dc/elements/1.1/" >
    <dc:date>2002-10-08</dc:date>
  </rdf:RDF>

You can specify more than one namespace URI to prefix mapping, eg:

  XML::Filter::NSNormalise->new(
    Map => {
      'http://purl.org/dc/elements/1.1/' => 'dc',
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#' => 'rdf',
      'http://purl.org/rss/1.0/modules/syndication/' => 'syn'
    }
  )

=head1 METHODS

=head2 new()

The constructor expects a list of options as Key => Value pairs. 

The 'Map' option must be specified and must be set to a hashref.  Each key of
the hashref is a namespace URI and each value is the corresponding namespace
prefix you want in the output document.  Any namespaces which occur in the
document but do not occur in the Map hash, will be passed through unaltered.

All other options are passed to the default constructor in L<XML::SAX::Base>.

=head1 ERROR HANDLING

Attempting to map more than one URI to the same prefix will cause a fatal
exception, eg:

  XML::Filter::NSNormalise->new(
    Map => {
      'http://x.com/ => 'z',
      'http://y.com/ => 'z'
    }
  )

Attempting to map a URI to a prefix that is already mapped to a different URI
will cause a fatal exception (eg: you map a URI to the prefix 'foo' but the
document your are filtering already uses 'foo' for a different URI).

=head1 SEE ALSO

L<XML::SAX>, L<XML::SAX::Base>, L<XML::SAX::Machines>.

=head1 COPYRIGHT 

Copyright 2002 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut
