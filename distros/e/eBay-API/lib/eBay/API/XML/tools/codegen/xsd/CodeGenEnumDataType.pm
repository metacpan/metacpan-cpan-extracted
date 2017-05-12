################################################################################
# Location: ............. <user defined location>eBay/API/XML/tools/codegen/xsd
# File: ................. CodeGenEnumDataType.pm
# Original Author: ...... Milenko Milanovic
#
################################################################################

=pod

=head1 CodeGenEnumDataType

Generate code for the enumerated data types.

=cut

package # put package name on different line to skip pause indexing
    CodeGenEnumDataType;

use strict;
use warnings;

use Exporter;
use BaseCodeGenDataType;
our @ISA = (
             'Exporter',
             'BaseCodeGenDataType',
           );

use Data::Dumper;
use EnumElement;

#
# use superclass new constructor
#

#
#  Overridden methods
#

sub _initElementsAndAttributes {

  my $self = shift;
  my $rh= shift;

     # 3. superclass name, elements and attributes

  my $rhRestrictions = $rh->{'xs:restriction'};
  if ( defined $rhRestrictions ) {

     my $sBase = $rhRestrictions->{'base'};

     if ( defined $sBase ) {

        # 3.1 superclass name
         $self->setSuperclassName( $sBase );
     }

     my $raEnums = $rhRestrictions->{'xs:enumeration'};
     if (! (ref ($raEnums) eq 'ARRAY') ) {
         $raEnums = [ $raEnums ];
     }

     my @aEnums = ();
     foreach my $rhEnum (@$raEnums) {

        my $pEnum = EnumElement->new( $rhEnum );
        push @aEnums, $pEnum;
     }

     $self->setEnums( \@aEnums );
  }
}

#
# auxilary methods
#

sub _determineFullPackageName {
   
   my $self = shift;
   
   my $str =  $self->getRootPackageName()
                 . '::' . 'DataType'
                 . '::' . 'Enum'
                 . '::' . $self->getName();
   return $str;
}

sub isScalar {
   return 1;
}

sub _getClassBody {

  my $self = shift;

  my %args = @_;

  my $raEnums          = $self->getEnums();

  my $strEnums = $self->_generateEnums ( 'raEnums'=> $raEnums );

  my $packageBody = <<"PACKAGE_BODY";

=head1 Enums:

=cut

$strEnums



PACKAGE_BODY

  return $packageBody
}


sub _generateEnums {

   my $self = shift;

   my %args = @_;
   my $raEnums = $args{'raEnums'};
   my $name;           # Scalar used to store the name portion of an ENUM.

   my $str = '';
   foreach my $pEnum (@$raEnums) {

      my $value = $pEnum->getValue();

      # Nokes: 03/09/2007 @ 18:49
      # If the eBay XSD schema has Enums defined as numbers, then we need to make sure we
      # rename any constants we generate so Perl won't choke on a variable or subroutine created
      # (under the hood via `use constant`) that starts with a number as the first character
      # in it's name.
      #
      # i.e.   use constant 1  => scalar '1';    # WRONG - won't compile
      #        use constant N1 => scalar '1';    # GOOD  - will compile

        # Test for string beginning with a number.
          if   ($value =~ /^[0-9].*$/io)
               {# Debugging use only
                  #print STDERR ('$value begins with an numeric char = ' . $value . "\n");
                $name = 'N' . $value;
               }# end if

        # Else, it already has a alpha character as the first part, just use it as is.
          else {# Debugging use only
                  # print STDERR ('$value begins with an alpha char = ' . $value . "\n");
                $name = $value;
               }# end else


      my $pAnnotation = $pEnum->getAnnotation();

      my $annotDoc = $self->_formatDocumentation( $pAnnotation );

      if ( $annotDoc eq '' ) {
         $str .=<<"ANNOT_DESC_EMPTY";

=head2 $name

=cut

ANNOT_DESC_EMPTY
     } else {
        $str .=<<"ANNOT_DESC";

=head2 $name

$annotDoc

=cut

ANNOT_DESC
    }# end else

    $str .= <<"ENUM_VAL";

use constant $name => scalar('$value');

ENUM_VAL
   }# end if
   return $str;

} # end _generateEnums()





1;
