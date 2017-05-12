package WordPress::Base::Data::Object;
use strict;
use Carp;
#use Smart::Comments '###';
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /(\d+)/g;
 
sub new {
   my($class,$self) = @_;
   $self||={};
   bless $self,$class;
   return $self;
}


#*{structure_data_set} = \&structure_data;

sub make_structure_data {
   my $class = shift;
   $class->can('structure_data') and return;

   my $namespace = "$class\::structure_data";

   no strict 'refs';
   *{$namespace} = {};


   *{$namespace} = sub {
      my $self = shift;
      my ($val) = @_;
      if ( defined $val ){
         ### got val here
         $self->{structure_data} = $val;
      }
      unless( defined $self->{structure_data} ){
         my %copy = %{"$namespace"};
         $self->{structure_data} = \%copy;
      }
      return $self->{structure_data};
   };
   
   *{"$namespace\_set"} = *{$namespace};

}


sub make_structure_data_accessor {
   my $class = shift;
   my @names = @_;
   no strict 'refs';
   
   make_structure_data($class);

   for my $name ( @names ){

      *{"$class\::structure_data"}->{$name} = undef;
      
      *{"$class\::$name"} = 
      sub {
         my ($self,$val) = (shift,shift);
         if (defined $val){
            $self->structure_data->{$name} = $val;
         }
         return $self->structure_data->{$name};      
      };
   }
   return;
}




1;


__END__

=pod

=head1 NAME

WordPress::Base::Data::Object

=head1 DESCRIPTION

This module is not meant to be used alone. It is used as base these sorts of objects:

   WordPress::Base::Data::Author
   WordPress::Base::Data::Category
   WordPress::Base::Data::MediaObject
   WordPress::Base::Data::Post
   WordPress::Base::Data::Page

It contains a constructor, and object method builders.

=head1 CAVEAT

This package is under development. Use base packages at your own peril.

=head1 METHODS

=head2 new()

=head2 structure_data()

Returns the data structure as you would present to a WordPress::XMLRPC set call.
Perl setget method.

=head2 make_structure_data_accessor()

Argument is list of method names.

=head1 SEE ALSO

WordPress::Base::Data::Author
WordPress::Base::Data::Category
WordPress::Base::Data::MediaObject
WordPress::Base::Data::Post
WordPress::Base::Data::Page
WordPress::XMLRPC

WordPress::API

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut
