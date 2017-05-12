package # put package name on different line to skip pause indexing
    Element;

use strict;
use warnings;

use Exporter;

use Data::Dumper;

use Annotation;

sub new {

  my $classname = shift;
  my $rhXmlSimple = shift;

  my $self = {};
  bless($self, $classname);

  $self->{'name'}         = $rhXmlSimple->{'name'};
  $self->{'typeNS'}       = $rhXmlSimple->{'type'};
  $self->{'maxOccurs'}    = $rhXmlSimple->{'maxOccurs'};

  my $rhAnnotation = $rhXmlSimple->{'xs:annotation'};
  my $pAnnotation;
  if ( defined $rhAnnotation ) {
	   $pAnnotation = Annotation->new ( $rhAnnotation );
  }
  $self->setAnnotation( $pAnnotation );

  return $self;  
}

sub getName {
  my $self = shift;
  return $self->{'name'};
}
sub setName {
  my $self = shift;
  $self->{'name'} = shift;  
}

sub getAnnotation {
  my $self = shift;
  return $self->{'pAnnotation'};
}
sub setAnnotation {
  my $self = shift;
  $self->{'pAnnotation'} = shift;  
}

sub getTypeNS {
  my $self = shift;
  return $self->{'typeNS'};
}
sub setTypeNS {
  my $self = shift;
  $self->{'typeNS'} = shift;  
}

sub getMaxOccurance {
  my $self = shift;
  return $self->{'maxOccurs'};
}
sub setMaxOccurance {
  my $self = shift;
  $self->{'maxOccurs'} = shift;  
}

#
# derived properties
#
sub isArray () {

  my $self = shift;

  my $maxOccurance = $self->{'maxOccurs'};
  if ( defined $maxOccurance 
	    && ( $maxOccurance eq 'unbounded'
	              || $maxOccurance > 1 )
     ) {
     return 1;
  }
  return 0;
}


1;
