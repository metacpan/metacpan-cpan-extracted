package SAPNW::RFC::Parameter;
=pod

    Copyright (c) 2006 - 2010 Piers Harding.
    All rights reserved.

=cut
use strict;

use SAPNW::Base;
use base qw(SAPNW::Base);

use vars qw($VERSION $AUTOLOAD);
$VERSION = '0.37';


  sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
        #debug("SUPPER->new: ".Dumper(\@_));
        my $first = shift;
        my ($name, $type, $len, $ulen, $decimals, $direction, $typedef);
        if (ref($first) eq "HASH") {
          foreach my $key (keys %{$first}) {
              unless (exists $first->{lc($key)}){
                  $first->{lc($key)} = $first->{$key};
                  delete($first->{$key});
                }
            }
          ($name, $type, $len, $ulen, $decimals, $direction, $typedef) = 
            ($first->{name},
             $first->{type},
             $first->{len},
             $first->{ulen},
             $first->{decimals},
             $first->{direction},
             $first->{typedef});
        } else {
          ($name, $type, $len, $ulen, $decimals, $direction, $typedef) = ($first, @_);
        }
    #debug("parm: $name type: $type len: $len decimals: $decimals\n");
        die "Missing Parameter name\n" unless $name;
        die "Missing Parameter type ($name) \n" unless defined($type);
        $len ||= 0;
        $decimals ||= 0;
        $ulen ||= 2*$len;
        die "Invalid type ($type) for Parameter $name\n" unless 
                $type == RFCTYPE_CHAR ||
                $type == RFCTYPE_DATE ||
                $type == RFCTYPE_BCD ||
                $type == RFCTYPE_TIME ||
                $type == RFCTYPE_BYTE ||
                $type == RFCTYPE_TABLE ||
                $type == RFCTYPE_NUM ||
                $type == RFCTYPE_FLOAT ||
                $type == RFCTYPE_INT ||
                $type == RFCTYPE_INT2 ||
                $type == RFCTYPE_INT1 ||
                $type == RFCTYPE_NULL ||
                $type == RFCTYPE_STRUCTURE ||
                $type == RFCTYPE_DECF16 ||
                $type == RFCTYPE_DECF34 ||
                $type == RFCTYPE_XMLDATA ||
                $type == RFCTYPE_STRING ||
                $type == RFCTYPE_XSTRING ||
                $type == RFCTYPE_EXCEPTION ||
                ref($type) eq "SAPNW::RFC::Type";
      if (ref($type) eq "SAPNW::RFC::Type") {
          $typedef = $type;
          $type = $typedef->type;
          $len = $typedef->len;
          $ulen = $typedef->ulen;
       }
    my $self = {
               name => $name,
               type => $type,
               len => int($len),
               ulen => int($ulen),
               decimals => int($decimals),
               direction => $direction,
               typedef => $typedef,
               value => undef,
    };
    bless($self, $class);
    return $self;
    }

    sub DESTROY {
      #print STDERR "DESTROY Parameter\n";
    }

  sub name { 
      my $self = shift;
        return $self->{name};
    }

    sub value {
      my $self = shift;
        $self->{value} = shift if scalar @_;
        return $self->{value};
    }

  sub type { 
      my $self = shift;
        return $self->{type};
    }

  sub len { 
      my $self = shift;
        return $self->{len};
    }

  sub ulen { 
      my $self = shift;
        return $self->{ulen};
    }

  sub decimals { 
      my $self = shift;
        return $self->{decimals};
    }

  sub direction { 
      my $self = shift;
        return $self->{direction};
    }


package SAPNW::RFC::Import;
use base qw(SAPNW::RFC::Parameter);
use SAPNW::Base;
  sub new {
      my $class = shift;
        #debug(Dumper(\@_));
      my $self =  $class->SUPER::new({@_, 'direction', RFCIMPORT});
        bless ($self, $class);
        return $self;
    }


package SAPNW::RFC::Export;
use base qw(SAPNW::RFC::Parameter);
use SAPNW::Base;
#use Data::Dumper;
  sub new {
      my $class = shift;
    #debug("parms: ".Dumper(\@_));
      my $self =  $class->SUPER::new({@_, 'direction', RFCEXPORT});
        bless ($self, $class);
        return $self;
    }


package SAPNW::RFC::Changing;
use base qw(SAPNW::RFC::Parameter);
use SAPNW::Base;
  sub new {
      my $class = shift;
      my $self =  $class->SUPER::new({@_, 'direction', RFCCHANGING});
        bless ($self, $class);
        return $self;
    }


package SAPNW::RFC::Table;
use base qw(SAPNW::RFC::Parameter);
use SAPNW::Base;
  sub new {
      my $class = shift;
      my $self =  $class->SUPER::new({@_, 'direction', RFCTABLES});
        bless ($self, $class);
        return $self;
    }


package SAPNW::RFC::Type;
use SAPNW::Base;

  sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
        my $self = { 'decimals' => 0, 'len' => 0, @_};
        foreach my $key (keys %{$self}) {
          unless (exists $self->{lc($key)}){
              $self->{lc($key)} = $self->{$key};
              delete($self->{$key});
          }
        }
        #my ($name, $type, $len, $ulen, $decimals, $fields) = @_;
        die "Missing Type name\n" unless exists $self->{name};
        die "Missing Type type ($self->{name}) \n" unless exists $self->{type};
        $self->{ulen} ||= 2*$self->{len};
        my $type = $self->{type};
        die "Invalid type ($type) for Type $self->{name}\n" unless 
        $type == RFCTYPE_CHAR ||
        $type == RFCTYPE_DATE ||
        $type == RFCTYPE_BCD ||
        $type == RFCTYPE_TIME ||
        $type == RFCTYPE_BYTE ||
        $type == RFCTYPE_TABLE ||
        $type == RFCTYPE_NUM ||
        $type == RFCTYPE_FLOAT ||
        $type == RFCTYPE_INT ||
        $type == RFCTYPE_INT2 ||
        $type == RFCTYPE_INT1 ||
        $type == RFCTYPE_NULL ||
        $type == RFCTYPE_STRUCTURE ||
        $type == RFCTYPE_DECF16 ||
        $type == RFCTYPE_DECF34 ||
        $type == RFCTYPE_XMLDATA ||
        $type == RFCTYPE_STRING ||
        $type == RFCTYPE_XSTRING ||
        $type == RFCTYPE_EXCEPTION;

    if (exists $self->{fields} && ref($self->{fields}) eq "ARRAY") {
          my $slen = 0;
          my $sulen = 0;
          foreach my $f ( @{$self->{fields}} ) {
               die "Each field in a Type must be a HASH - $self->{name}\n" unless ref($f) eq "HASH";
                 die "Each field in a Type must have at least { name => 'aname', type => <sometype>, len => <somelen>}\n"
                    unless exists($f->{name}) && exists($f->{type}) && exists($f->{len});
                 $f->{ulen} = $f->{len} * 2 unless exists($f->{ulen});
                 $f->{decimals} = 0 unless exists($f->{decimals});
                 $slen += $f->{len};
                 $sulen += $f->{ulen};
                 if (ref($f->{type}) eq "SAPNW::RFC::Type") {
                     $f->{typedef} = $f->{type};
                     $f->{type} = $f->{typedef}->type;
                 }
            }
            $self->{len} = $slen unless $self->{len} > 0;
            $self->{ulen} = $sulen unless $self->{ulen} > 0;
      } elsif (exists $self->{fields}) {
          die "FIELDS must be an ARRAY for Type $self->{name}\n";
        }
    bless($self, $class);
    return $self;
    }

  sub name { 
      my $self = shift;
        return $self->{name};
    }

  sub type { 
      my $self = shift;
        return $self->{type};
    }

  sub typedef { 
      my $self = shift;
        if (exists($self->{typedef})) {
          return $self->{typedef};
        } else {
          return undef;
        }
    }

  sub len { 
      my $self = shift;
        return $self->{len};
    }

  sub ulen { 
      my $self = shift;
        return $self->{ulen};
    }

  sub decimals { 
      my $self = shift;
        return $self->{decimals};
    }

    sub fields {
      my $self = shift;
        return $self->{fields};
    }


1;
