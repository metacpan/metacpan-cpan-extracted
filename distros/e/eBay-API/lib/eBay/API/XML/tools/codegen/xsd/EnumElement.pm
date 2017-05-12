package # put package name on different line to skip pause indexing
    EnumElement;

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

    # 1. value
  $self->{'value'} = $rhXmlSimple->{'value'};

    # 2. annotation
  my $rhAnnotation = $rhXmlSimple->{'xs:annotation'};
  my $pAnnotation;
  if ( defined $rhAnnotation ) {
     $pAnnotation = Annotation->new ( $rhAnnotation );
  }

  $self->setAnnotation( $pAnnotation );

  return $self;  
}

sub getValue {
  my $self = shift;
  return $self->{'value'};
}
sub setValue {
  my $self = shift;
  $self->{'value'} = shift;  
}

sub getAnnotation {
  my $self = shift;
  return $self->{'pAnnotation'};
}
sub setAnnotation {
  my $self = shift;
  $self->{'pAnnotation'} = shift;  
}

1;
