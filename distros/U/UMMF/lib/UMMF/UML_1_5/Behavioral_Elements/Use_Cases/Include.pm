# -*- perl -*-
# DO NOT EDIT - This file is generated by UMMF; http://ummf.sourceforge.net 
# From template: $Id: Perl.txt,v 1.77 2006/05/14 01:40:03 kstephens Exp $

package UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include;

#use 5.6.1;
use strict;
use warnings;

#################################################################
# Version
#

our $VERSION = do { my @r = (q{1.5} =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };


#################################################################
# Documentation
#

=head1 NAME

UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include -- 

=head1 VERSION

1.5

=head1 SYNOPSIS

=head1 DESCRIPTION 

=head1 USAGE

=head1 EXPORT

=head1 METATYPE

L<UMMF::UML_1_5::Foundation::Core::Class|UMMF::UML_1_5::Foundation::Core::Class>

=head1 SUPERCLASSES

L<UMMF::UML_1_5::Foundation::Core::Relationship|UMMF::UML_1_5::Foundation::Core::Relationship>




=head1 ATTRIBUTES

I<NO ATTRIBUTES>


=head1 ASSOCIATIONS


=head2 C<include_addition> : I<THIS> C<0..*> E<lt>---E<gt>  C<addition> : UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase C<1>



=over 4

=item metatype = L<UMMF::UML_1_5::Foundation::Core::AssociationEnd|UMMF::UML_1_5::Foundation::Core::AssociationEnd>

=item type = L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase>

=item multiplicity = C<1>

=item changeability = C<changeable>

=item targetScope = C<instance>

=item ordering = C<>

=item isNavigable = C<1>

=item aggregation = C<none>

=item visibility = C<public>

=item container_type = C<Set::Object>

=back


=head2 C<include> : I<THIS> C<0..*> E<lt>---E<gt>  C<base> : UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase C<1>



=over 4

=item metatype = L<UMMF::UML_1_5::Foundation::Core::AssociationEnd|UMMF::UML_1_5::Foundation::Core::AssociationEnd>

=item type = L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase>

=item multiplicity = C<1>

=item changeability = C<changeable>

=item targetScope = C<instance>

=item ordering = C<>

=item isNavigable = C<1>

=item aggregation = C<none>

=item visibility = C<public>

=item container_type = C<Set::Object>

=back



=head1 METHODS

=cut



#################################################################
# Dependencies
#





use Carp qw(croak confess);
use Set::Object 1.05;
use Class::Multimethods 1.70;
use Data::Dumper;
use Scalar::Util qw(weaken);
use UMMF::UML_1_5::__ObjectBase qw(:__ummf_array);


#################################################################
# Generalizations
#

use base qw(
  UMMF::UML_1_5::Foundation::Core::Relationship



);


#################################################################
# Exports
#

our @EXPORT_OK = qw(
);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );





#################################################################
# Validation
#


=head2 C<__validate_type>

  UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include->__validate_type($value);

Returns true if C<$value> is a valid representation of L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include>.

=cut
sub __validate_type($$)
{
  my ($self, $x) = @_;

  no warnings;

  UNIVERSAL::isa($x, 'UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include')  ;
}


=head2 C<__typecheck>

  UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include->__typecheck($value, $msg);

Calls C<confess()> with C<$msg> if C<<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include->__validate_type($value)>> is false.

=cut
sub __typecheck
{
  my ($self, $x, $msg) = @_;

  confess("typecheck: $msg: type '" . 'UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include' . ": value '$x'")
    unless __validate_type($self, $x);
}


=head2 C<isaInclude>


Returns true if receiver is a L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include>.
Other receivers will return false.

=cut
sub isaInclude { 1 }


=head2 C<isaBehavioral_Elements__Use_Cases__Include>


Returns true if receiver is a L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include>.
Other receivers will return false.
This is the fully qualified version of the C<isaInclude> method.

=cut
sub isaBehavioral_Elements__Use_Cases__Include { 1 }


#################################################################
# Introspection
#

=head2 C<__model_name> 

  my $name = $obj_or_package->__model_name;

Returns the UML Model name (C<'Behavioral_Elements::Use_Cases::Include'>) for an object or package of
this Classifier.

=cut
sub __model_name { 'Behavioral_Elements::Use_Cases::Include' }



=head2 C<__isAbstract>

  $package->__isAbstract;

Returns C<0>.

=cut
sub __isAbstract { 0; }


my $__tangram_schema;
=head2 C<__tangram_schema>

  my $tangram_schema $obj_or_package->__tangram_schema

Returns a HASH ref that describes this Classifier for Tangram.

See L<UMMF::Export::Perl::Tangram|UMMF::Export::Perl::Tangram>

=cut
sub __tangram_schema
{
  my ($self) = @_;

  $__tangram_schema ||=
  {
   'classes' =>
   [
     'UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include' =>
     {
       'table' => 'Behavioral_Elements__Use_Cases__Include',
       'abstract' => 0,
       'slots' => 
       { 
	 # Attributes
	 
	 # Associations
	 	 	       'addition'
       => {
	 'type_impl' => 'ref',
         'class' => 'UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase',

                                             'col' => 'addition', 

                                                                                                                   }
      ,
                  	 	       'base'
       => {
	 'type_impl' => 'ref',
         'class' => 'UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase',

                                             'col' => 'base', 

                                                                                                                   }
      ,
                         },
       'bases' => [  'UMMF::UML_1_5::Foundation::Core::Relationship',  ],
       'sql' => {

       },
     },
   ],

   'sql' =>
   {
    # Note Tangram::Ref::get_exporter() has
    # "UPDATE $table SET $self->{col} = $refid WHERE id = $id",
    # The id_col is hard-coded, 
    # Thus id_col will not work.
    #'id_col' => '__sid',
    #'class_col' => '__stype',
   },
     # 'set_id' => sub { }
     # 'get_id' => sub { }

      
  };
}


#################################################################
# Class Attributes
#


    

#################################################################
# Class Associations
#


    

#################################################################
# Initialization
#


=head2 C<___initialize>

Initialize all Attributes and AssociationEnds in a instance of this Classifier.
Does B<not> initalize slots in its Generalizations.

See also: C<__initialize>.

=cut
sub ___initialize
{
  my ($self) = @_;

  # Attributes



  # Associations

  # AssociationEnd 
  #  include_addition 0..*
  #  <--> 
  #  addition 1 UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase.
    if ( defined $self->{'addition'} ) {
    my $x = $self->{'addition'};
    $self->{'addition'} = undef;
    $self->set_addition($x);
  }
  
  # AssociationEnd 
  #  include 0..*
  #  <--> 
  #  base 1 UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase.
    if ( defined $self->{'base'} ) {
    my $x = $self->{'base'};
    $self->{'base'} = undef;
    $self->set_base($x);
  }
  

  $self;
}


my $__initialize_use;

=head2 C<__initialize>

Initialize all slots in this Classifier and all its Generalizations.

See also: C<___initialize>.

=cut
sub __initialize
{
  my ($self) = @_;

  # $DB::single = 1;

  unless ( ! $__initialize_use ) {
    $__initialize_use = 1;
    $self->__use('UMMF::UML_1_5::Foundation::Core::Element');
    $self->__use('UMMF::UML_1_5::Foundation::Core::ModelElement');
    $self->__use('UMMF::UML_1_5::Foundation::Core::Relationship');
  }

  $self->UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include::___initialize;
  $self->UMMF::UML_1_5::Foundation::Core::Element::___initialize;
  $self->UMMF::UML_1_5::Foundation::Core::ModelElement::___initialize;
  $self->UMMF::UML_1_5::Foundation::Core::Relationship::___initialize;

  $self;
}
      

=head2 C<__create>

Calls all <<create>> Methods for this Classifier and all Generalizations.

See also: C<___create>.

=cut
sub __create
{
  my ($self, @args) = @_;

  # $DB::single = 1;
  $self->UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include::___create(@args);
  $self->UMMF::UML_1_5::Foundation::Core::Element::___create();
  $self->UMMF::UML_1_5::Foundation::Core::ModelElement::___create();
  $self->UMMF::UML_1_5::Foundation::Core::Relationship::___create();

  $self;
}




#################################################################
# Attributes
#




#################################################################
# Association
#


=for html <hr/>

=cut

#################################################################
# AssociationEnd include_addition <---> addition
# type = UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase
# multiplicity = 1
# ordering = 

=head2 C<addition>

  my $val = $obj->addition;

Returns the AssociationEnd C<addition> value of type L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase>.

=cut
sub addition ($)
{
  my ($self) = @_;
		  
  $self->{'addition'};
}


=head2 C<set_addition>

  $obj->set_addition($val);

Sets the AssociationEnd C<addition> value.
C<$val> must of type L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase>.
Returns C<$obj>.

=cut
sub set_addition ($$)
{
  my ($self, $val) = @_;
		  
  no warnings; # Use of uninitialized value in string ne at ...
		  
  my $old;
  if ( ($old = $self->{'addition'}) ne $val ) { # Recursion lock

    if ( defined $val ) { $self->__use('UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase')->__typecheck($val, "UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include.addition") }

    # Recursion lock
        $self->{'addition'} = $val
    ;

    # Remove and add associations with other ends.
        
    $old->remove_include_addition($self) if $old;
    $val->add_include_addition($self)    if $val;

    }
		  
  $self;
}


=head2 C<add_addition>

  $obj->add_addition($val);

Adds the AssociationEnd C<addition> value.
C<$val> must of type L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase>.
Throws exception if a value already exists.
Returns C<$obj>.

=cut
sub add_addition ($$)
{
  my ($self, $val) = @_;

  no warnings; # Use of uninitialized value in string ne at ...

  my $old;
  if ( ($old = $self->{'addition'}) ne $val ) { # Recursion lock
    $self->__use('UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase')->__typecheck($val, "UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include.addition");
      
    # confess("UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include::addition: too many")
    # if defined $self->{'addition'};

    # Recursion lock
        $self->{'addition'} = $val
    ;

    # Remove and add associations with other ends.
        
    $old->remove_include_addition($self) if $old;
    $val->add_include_addition($self)    if $val;

  
  }

  $self;
}


=head2 C<remove_addition>

  $obj->remove_addition($val);

Removes the AssociationEnd C<addition> value C<$val>.
Returns C<$obj>.

=cut
sub remove_addition ($$)
{
  my ($self, $val) = @_;

  no warnings; # Use of uninitialized value in string ne at ...

  my $old;
  if ( ($old = $self->{'addition'}) eq $val ) { # Recursion lock
    $val = $self->{'addition'} = undef;         # Recursion lock

    # Remove and add associations with other ends.
        
    $old->remove_include_addition($self) if $old;
    $val->add_include_addition($self)    if $val;

  
  }
}


=head2 C<clear_addition>

  $obj->clear_addition;

Clears the AssociationEnd C<addition> links to L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase>.
Returns C<$obj>.

=cut
sub clear_addition ($@)
{
  my ($self) = @_;

  my $old;
  if ( defined ($old = $self->{'addition'}) ) { # Recursion lock
    my $val = $self->{'addition'} = undef;      # Recursion lock

    # Remove and add associations with other ends.
        
    $old->remove_include_addition($self) if $old;
    $val->add_include_addition($self)    if $val;

    }

  $self;
}


=head2 C<count_addition>

  $obj->count_addition;

Returns the number of elements of type L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase> associated with C<addition>.

=cut
sub count_addition ($)
{
  my ($self) = @_;

  my $x = $self->{'addition'};

  defined $x ? 1 : 0;
}




=for html <hr/>

=cut

#################################################################
# AssociationEnd include <---> base
# type = UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase
# multiplicity = 1
# ordering = 

=head2 C<base>

  my $val = $obj->base;

Returns the AssociationEnd C<base> value of type L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase>.

=cut
sub base ($)
{
  my ($self) = @_;
		  
  $self->{'base'};
}


=head2 C<set_base>

  $obj->set_base($val);

Sets the AssociationEnd C<base> value.
C<$val> must of type L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase>.
Returns C<$obj>.

=cut
sub set_base ($$)
{
  my ($self, $val) = @_;
		  
  no warnings; # Use of uninitialized value in string ne at ...
		  
  my $old;
  if ( ($old = $self->{'base'}) ne $val ) { # Recursion lock

    if ( defined $val ) { $self->__use('UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase')->__typecheck($val, "UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include.base") }

    # Recursion lock
        $self->{'base'} = $val
    ;

    # Remove and add associations with other ends.
        
    $old->remove_include($self) if $old;
    $val->add_include($self)    if $val;

    }
		  
  $self;
}


=head2 C<add_base>

  $obj->add_base($val);

Adds the AssociationEnd C<base> value.
C<$val> must of type L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase>.
Throws exception if a value already exists.
Returns C<$obj>.

=cut
sub add_base ($$)
{
  my ($self, $val) = @_;

  no warnings; # Use of uninitialized value in string ne at ...

  my $old;
  if ( ($old = $self->{'base'}) ne $val ) { # Recursion lock
    $self->__use('UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase')->__typecheck($val, "UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include.base");
      
    # confess("UMMF::UML_1_5::Behavioral_Elements::Use_Cases::Include::base: too many")
    # if defined $self->{'base'};

    # Recursion lock
        $self->{'base'} = $val
    ;

    # Remove and add associations with other ends.
        
    $old->remove_include($self) if $old;
    $val->add_include($self)    if $val;

  
  }

  $self;
}


=head2 C<remove_base>

  $obj->remove_base($val);

Removes the AssociationEnd C<base> value C<$val>.
Returns C<$obj>.

=cut
sub remove_base ($$)
{
  my ($self, $val) = @_;

  no warnings; # Use of uninitialized value in string ne at ...

  my $old;
  if ( ($old = $self->{'base'}) eq $val ) { # Recursion lock
    $val = $self->{'base'} = undef;         # Recursion lock

    # Remove and add associations with other ends.
        
    $old->remove_include($self) if $old;
    $val->add_include($self)    if $val;

  
  }
}


=head2 C<clear_base>

  $obj->clear_base;

Clears the AssociationEnd C<base> links to L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase>.
Returns C<$obj>.

=cut
sub clear_base ($@)
{
  my ($self) = @_;

  my $old;
  if ( defined ($old = $self->{'base'}) ) { # Recursion lock
    my $val = $self->{'base'} = undef;      # Recursion lock

    # Remove and add associations with other ends.
        
    $old->remove_include($self) if $old;
    $val->add_include($self)    if $val;

    }

  $self;
}


=head2 C<count_base>

  $obj->count_base;

Returns the number of elements of type L<UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase|UMMF::UML_1_5::Behavioral_Elements::Use_Cases::UseCase> associated with C<base>.

=cut
sub count_base ($)
{
  my ($self) = @_;

  my $x = $self->{'base'};

  defined $x ? 1 : 0;
}







# End of Class Include


=pod

=for html <hr/>

I<END OF DOCUMENT>

=cut

############################################################################

1; # is true!

############################################################################

### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

