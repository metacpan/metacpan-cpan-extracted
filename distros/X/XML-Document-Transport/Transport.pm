package XML::Document::Transport;

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION $SELF /;

#use XML::Parser;
use XML::Simple;
use XML::Writer;
use XML::Writer::String;

use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;
use Data::Dumper;

'$Revision: 1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { DOCUMENT => undef,
                      WRITER   => undef,
                      BUFFER   => undef }, $class;

  # Configure the object
  $block->configure( @_ ); 

  return $block;

}

# A C C E S S O R   M E T H O D S -------------------------------------------

#  $xml = $object->build( Role       => $string,
#                         Origin     => $strng,
#                         Response   => $sting,
#                         TimeStamp  => $string,
#                         Meta => [ { Group => [ { Name  => $string,
#                                                UCD   => $string,
#                                                Value => $string,
#                                                Units => $string }, 
#                                                  .
#                                                  .
#                                                  .
#                                              { Name  => $string,
#                                                UCD   => $string,
#                                                Value => $string,
#                                                Units => $string } ], },
#                                  { Group => [ { Name  => $string,
#                                                UCD   => $string,
#                                                Value => $string,
#                                                Units => $string },
#                                                  .
#                                                  .
#                                                  .
#                                              { Name  => $string,
#                                                UCD   => $string,
#                                                Value => $string,
#                                                Units => $string } ], },
#                                  { Name  => $string,
#                                    UCD   => $string,
#                                    Value => $string,
#                                    Units => $string },
#                                      .
#                                      .
#                                      .
#                                  { Name  => $string,
#                                    UCD   => $string,
#                                    Value => $string,
#                                    Units => $string } ] );


sub build {
  my $self = shift;
  my %args = @_;

  # mandatory tags
  unless ( exists $args{Role} ) {
     return undef;
  }         

  # open the document
  $self->{WRITER}->xmlDecl( 'UTF-8' );
   
  # BEGIN DOCUMENT ------------------------------------------------------- 
  
  $self->{WRITER}->startTag( 'trn:Transport',
      'role' => $args{Role},
      'version' => '0.1',
      'xmlns:trn' => 'http://www.telescope-networks.org/xml/Transport/v0.1',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation' =>
  	 'http://www.telescope-networks.org/xml/Transport/v0.1 ' . 
  	 'http://www.telescope-networks.org/schema/Transport-v0.1.xsd'
      ); 

  # SKELETON DOCUMENT ----------------------------------------------------

  # Origin
  if ( exists $args{Origin} ) {
     $self->{WRITER}->startTag( 'Origin' );
     $self->{WRITER}->characters( $args{Origin} );
     $self->{WRITER}->endTag( 'Origin' );
  }   
  
  # Response
  if ( exists $args{Response} ) {
     $self->{WRITER}->startTag( 'Response' );
     $self->{WRITER}->characters( $args{Response} );
     $self->{WRITER}->endTag( 'Response' );
  } 
  
  # TimeStamp
  if ( exists $args{TimeStamp} ) {
     $self->{WRITER}->startTag( 'TimeStamp' );
     $self->{WRITER}->characters( $args{TimeStamp} );
     $self->{WRITER}->endTag( 'TimeStamp' );
  }    

  # Meta
  if ( exists $args{Meta} ) {
     $self->{WRITER}->startTag( 'Meta' );
     
     my @array = @{$args{Meta}};
     foreach my $i ( 0 ... $#array ) {
     
        my %hash = %{${$args{Meta}}[$i]};
        
        if ( exists $hash{Group} ) {
           $self->{WRITER}->startTag( 'Group' );
        
           my @subarray = @{$hash{Group}};
           foreach my $i ( 0 ... $#subarray ) {
           
              # Only UNITS is optional for Param tags
              if ( exists ${$subarray[$i]}{Units} ) {
                $self->{WRITER}->emptyTag('Param',
                                          'name'  => ${$subarray[$i]}{Name},
                                          'ucd'   => ${$subarray[$i]}{UCD},
                                          'value' => ${$subarray[$i]}{Value},
                                          'units' => ${$subarray[$i]}{Units} );
              } else {
                $self->{WRITER}->emptyTag('Param',
                                          'name'  => ${$subarray[$i]}{Name},
                                          'ucd'   => ${$subarray[$i]}{UCD},
                                          'value' => ${$subarray[$i]}{Value});
              }    
           }
                                         
           $self->{WRITER}->endTag( 'Group' );
        
        } else {
           # Only UNITS is optional for Param tags
           if ( exists $hash{Units} ) {
              $self->{WRITER}->emptyTag('Param',
                                        'name'  => $hash{Name},
                                        'ucd'   => $hash{UCD},
                                        'value' => $hash{Value},
                                        'units' => $hash{Units} ); 
           } else {
              $self->{WRITER}->emptyTag('Param',
                                        'name'  => $hash{Name},
                                        'ucd'   => $hash{UCD},
                                        'value' => $hash{Value} );  
           } 
        }                                                     
     }    
          
     $self->{WRITER}->endTag( 'Meta' );
  }
  
  # END DOCUMENT --------------------------------------------------------- 
  
  $self->{WRITER}->endTag( 'trn:Transport' );
  $self->{WRITER}->end();
  
  my $xml = $self->{BUFFER}->value();
  $self->_parse( XML => $xml );
  return $xml;  
   
     
}

sub role {
  my $self = shift;
  return $self->{DOCUMENT}->{role};
}

sub version {
  my $self = shift;
  return $self->{DOCUMENT}->{version};
}

sub origin {
  my $self = shift;
  return $self->{DOCUMENT}->{Origin};
}

sub response {
  my $self = shift;
  return $self->{DOCUMENT}->{Response};
}

sub time {
  my $self = shift;
  return $self->{DOCUMENT}->{TimeStamp};
}

sub meta {
  my $self = shift;
  
  return %{$self->{DOCUMENT}->{Meta}};
}

# C O N F I G U R E ---------------------------------------------------------

sub configure {
  my $self = shift;

  # BLESS XML WRITER
  # ----------------
  $self->{BUFFER} = new XML::Writer::String();  
  $self->{WRITER} = new XML::Writer( OUTPUT      => $self->{BUFFER},
                                     DATA_MODE   => 1, 
                                     DATA_INDENT => 4 );
				     
  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;
				        
  # Loop over the allowed keys
  for my $key (qw / File XML / ) {
     if ( lc($key) eq "file" && exists $args{$key} ) { 
        $self->_parse( File => $args{$key} );
	last;
	
     } elsif ( lc($key) eq "xml"  && exists $args{$key} ) {
        $self->_parse( XML => $args{$key} );
	last;
	      
     }  
  }				     

  # Nothing to configure...
  return undef;

}


# P R I V A T E   M E T H O D S ------------------------------------------

sub _parse {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  my $xs = new XML::Simple( );

  # Loop over the allowed keys
  for my $key (qw / File XML / ) {
     if ( lc($key) eq "file" && exists $args{$key} ) { 
	$self->{DOCUMENT} = $xs->XMLin( $args{$key} );
	last;
	
     } elsif ( lc($key) eq "xml"  && exists $args{$key} ) {
	$self->{DOCUMENT} = $xs->XMLin( $args{$key} );
	last;
	
     }  
  }
  
  #print Dumper( $self->{DOCUMENT} );      
  return;
}

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
