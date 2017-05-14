package ERG::report_summary;

#  version:  1.13
#  date:     7/2/98

#  this package is a basic report summary class.
#
#  the report summary object is used to create and update values
#  which will be used in summaries in reports.

#  the package includes:
#
#      new
#	  creates report summary
#      setValue
#         set value in summary
#      tellValue
#         tell value in summary
#      addValue
#         add value to total in summary
#      avgAddValue
#         add value for average in summary
#      minValue
#         find identifier with minimum value
#      maxValue
#         find identifier with maximum value
#      clearValues
#         clear values
#
#  s. luebking  phoenixL@aol.com

$VERSION = "1.13";

require 5.000;

#
#------------------------------------------------------------------------------
#
#  BEGIN function
#

BEGIN
{
   $fieldSuffix = "SUM-";
}


#
#------------------------------------------------------------------------------
#
#  END function
#

END
{
}


#
#------------------------------------------------------------------------------
#
#  new method
#
#  ARGS:
#
#     none
#
#  RETURNS:  new object

sub new
{
   my $this = shift;
   my $specStr = shift;

   my $class = ref($this) || $this;

   my $self = bless {}, $class;

   return $self;
}


#
#------------------------------------------------------------------------------
#
#  method to set value to field summary
#
#  ARGS:
#
#     1  -  field name
#     2  -  value
#
#  RETURNS:  none

sub setValue
{
   my $self = shift;
   my $fieldName = shift;
   my $value = shift;

   my $fullName;

   $fullName = $fieldSuffix . $fieldName;

   $$self{$fullName} = $value;
}


#
#------------------------------------------------------------------------------
#
#  method to tell value of field summary
#
#  ARGS:
#
#     1  -  field name
#
#  RETURNS:  a value

sub tellValue
{
   my $self = shift;
   my $fieldName = shift;

   my $fullName;
   my $returnValue;

   $returnValue = undef;

   $fullName = $fieldSuffix . $fieldName;

   if( defined $$self{$fullName})
   {
      $returnValue = $$self{$fullName};
   }

   return $returnValue;
}


#
#------------------------------------------------------------------------------
#
#  method to add value to summary
#
#  ARGS:
#
#     1  -  name
#     2  -  value
#
#  RETURNS:  none

sub addValue
{
   my $self = shift;
   my $name = shift;
   my $value = shift;

   my $oldValue;

   $oldValue = $self->tellValue($name);

   if( ! defined $value)
   {
   }
   elsif($value =~ /^([+-]|\s*)$/)
   {
   }
   elsif($value !~ /^[+-]?\d*(|[.]d*)$/)
   {
   }
   elsif( ! defined $oldValue)
   {
      $value =~ s/^[+]//;
      $self->setValue($name,$value);
   }
   else
   {
      $value =~ s/^[+]//;
      $self->setValue($name,$oldValue + $value);
   }
}


#
#------------------------------------------------------------------------------
#
#  method to add value for averaging to summary
#
#  ARGS:
#
#     1  -  name
#     2  -  value
#
#  RETURNS:  none

sub avgAddValue
{
   my $self = shift;
   my $name = shift;
   my $value = shift;

   my $sum;
   my $count;

   $sum = $self->tellValue($name . "%%sum");
   $count = $self->tellValue($name . "%%count");

   if( ! defined $value)
   {
   }
   elsif($value =~ /^([+-]|\s*)$/)
   {
   }
   elsif($value !~ /^[+-]?\d*(|[.]d*)$/)
   {
   }
   elsif(( ! defined $sum) || ( ! defined $count))
   {
      $value =~ s/^[+]//;

      $self->setValue($name,$value);
      $self->setValue($name . "%%sum",$value);
      $self->setValue($name . "%%count",1);
   }
   else
   {
      $value =~ s/^[+]//;

      $sum += $value;
      $count++;

      $self->setValue($name,($sum/$count));
      $self->setValue($name . "%%sum",$sum);
      $self->setValue($name . "%%count",$count);
   }
}


#
#------------------------------------------------------------------------------
#
#  method for minimum value for summary
#
#  ARGS:
#
#     1  -  name
#     2  -  identifier
#     3  -  value
#
#  RETURNS:  none
#
#  if multiple identifiers have the same minimum value, the identifiers
#  will be saved as a string with identifiers separated by '|'

sub minValue
{
   my $self = shift;
   my $name = shift;
   my $identifier = shift;
   my $value = shift;

   my $oldValue;

   $oldValue = $self->tellValue($name . "%%value");

   if( ! defined $value)
   {
   }
   elsif($value =~ /^([+-]|\s*)$/)
   {
   }
   elsif($value !~ /^[+-]?\d*(|[.]d*)$/)
   {
   }
   elsif(! defined $oldValue)
   {
      $value =~ s/^[+]//;

      $self->setValue($name,$identifier);
      $self->setValue($name . "%%value",$value);
   }
   else
   {
      $value =~ s/^[+]//;

      if($value < $oldValue)
      {
         $self->setValue($name,$identifier);
         $self->setValue($name . "%%value",$value);
      }
      elsif($value == $oldValue)
      {
         $self->setValue($name, ($self->tellValue($name) . "|" .$identifier));
      }
   }
}


#
#------------------------------------------------------------------------------
#
#  method for maximum value for summary
#
#  ARGS:
#
#     1  -  name
#     2  -  identifier
#     3  -  value
#
#  RETURNS:  none
#
#  if multiple identifiers have the same maximum value, the identifiers
#  will be saved as a string with identifiers separated by '|'

sub maxValue
{
   my $self = shift;
   my $name = shift;
   my $identifier = shift;
   my $value = shift;

   my $oldValue;

   $oldValue = $self->tellValue($name . "%%value");

   if( ! defined $value)
   {
   }
   elsif($value =~ /^([+-]|\s*)$/)
   {
   }
   elsif($value !~ /^[+-]?\d*(|[.]d*)$/)
   {
   }
   elsif(! defined $oldValue)
   {
      $value =~ s/^[+]//;

      $self->setValue($name,$identifier);
      $self->setValue($name . "%%value",$value);
   }
   else
   {
      $value =~ s/^[+]//;

      if($value > $oldValue)
      {
         $self->setValue($name,$identifier);
         $self->setValue($name . "%%value",$value);
      }
      elsif($value == $oldValue)
      {
         $self->setValue($name, ($self->tellValue($name) . "|" .$identifier));
      }
   }
}


#
#------------------------------------------------------------------------------
#
#  method to clear summary values
#
#  ARGS:
#
#     none
#
#  RETURNS:  none

sub clearValues
{
   my $self = shift;

   foreach $fullName ( grep(/^$fieldSuffix/o, keys %$self ))
   {
      delete $$self{$fullName};
   }
}


#------------------------------------------------------------------------------
#  return 1 for require
1;


############################# Copyright #######################################

# Copyright (c) 1998 Scott Luebking. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

###############################################################################
