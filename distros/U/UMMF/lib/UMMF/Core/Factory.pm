package UMMF::Core::Factory;

use 5.6.0;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/06 };
our $VERSION = do { my @r = (q$Revision: 1.14 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Core::Factory - Defines a factory for model construction.

=head1 SYNOPSIS

  use UMMF::Core::Factory;
  $factory = UMMF::Core::Factory->new('classMap' => ...,
                                             );
  $factory->create('SomeClassName', ...);
  $factory->createInstance('SomeClassName', ...);

=head1 DESCRIPTION

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/06

=head1 SEE ALSO

L<UMMF::Core::MetaModel|UMMF::Core::MetaModel>

=head1 VERSION

$Revision: 1.14 $

=head1 METHODS

=cut


#######################################################################


use base qw(UMMF::Core::Object);

#######################################################################

use Carp qw(confess);

#######################################################################


my $loaded = { };

sub initialize
{
  my ($self, $expr) = @_;

  confess("classMap undefined") unless $self->{'classMap'};

  # confess("classMap POOP!!!") if $self->{'classMap'} == 1;

  $self->{'debugCreate'} ||= 0;

  # Use global loaded hash.
  $self->{'.loaded'} ||= $loaded;

  $self->SUPER::initialize;
}


#######################################################################


=head2 classMap

  my $map = $self->classMap;

Returns a hash that maps names to Perl package names.

If $self->{'classMap'} is a SCALAR, $self->{'classMap'} = $self->{'classMap'}->factory_map is performed, loading the class map from a package's factory_map method..

If $self->{'classMap'} is an ARRAY, the ARRAY is transformed into a hash.  In this case, colliding $names will have concatenated package names that should cause $self->class($name) to fail.

=cut
#emacs'
sub classMap
{
  my ($self) = @_;

  unless ( ref($self) ) {
    use Devel::StackTrace;

    print STDERR join("\n" . ('*' x 60) . "\n", "", Devel::StackTrace->new->as_string, "");
  }


  unless ( $self->{'classMapInited'} ) {

    #$DB::single = 1;
    # Get rid of the next line!!!
    # $self->{'classMap'} ||= 'UMMF::UML::MetaMetaModel';
    confess("classMap undefined") unless $self->{'classMap'};
    
    # Get class factory map from a class?
    unless ( ref($self->{'classMap'}) ) { 
      eval "use $self->{classMap};"; die $@ if $@;
      
      {
	use Data::Dumper;
	
	print STDERR Data::Dumper->new( [ $self->{classMap} ], [ qw($self->{classMap}) ])->Dump;
      }

      $self->{'classMap'} = $self->{'classMap'}->factory_map;
    }
    
    if ( ref($self->{'classMap'}) eq 'ARRAY' ) {
      my %map;
      
      my @x = @{$self->{'classMap'}};
      
      while ( @x ) {
	my ($name, $cls) = splice(@x, 0, 2);
	if ( exists $map{$name} && $map{$name} ne $cls ) {
	  # This will cause an error for ambigous names.
	  $map{$name} .= ' ' . $cls;
	} else {
	  $map{$name} = $cls;
	}
      }
      
      $self->{'classMap'} = \%map;
    }
    
    # $DB::single = 1;
    
    confess("classMap not a hash") unless ref($self->{'classMap'}) eq 'HASH';
    
    $self->{'classMapInited'} ++; 
  }

  $self->{'classMap'};
}


=head2 class

  my $pkg = $self->class($name, @args);

Returns the Perl package for the Classifier named C<$name>.

The Perl package is dynamically loaded, if necessary.

Called by C<create> and C<create_instance>.

=cut
sub class
{
  my ($self, $name, @args) = @_;

  my $cls = $self->classMap->{$name};
  die("Unknown Classifier '$name'") unless $cls;

  # Dynamically load it?
  unless ( $self->{'.loaded'}{$cls} ) {
    # $DB::single = 1;
    no strict 'refs';
    unless ( ${"${cls}::VERSION"} ) {
      # $DB::single = 1;
      eval "use $cls"; die $@ if $@;
      ${"${cls}::VERSION"} ||= 1;
    }
    $self->{'.loaded'}{$cls} = 1;
  }

  $cls;
}


sub class_add
{
  my ($self, $name, $cls) = @_;

  # print STDERR "class_add $name $cls\n";

  $self->classMap->{$name} = $cls;
  # Mark it as loaded.
  $self->{'.loaded'}{$cls} = 1;

  $self;
}


=head2 create_instance

  my $obj = $self->create_instance($name, @args);

Creates a new instance of the class named $name, via $pkg->__new_instance(@args).

This creates a new uninitialized object.

=cut
sub create_instance
{
  my ($self, $name, @args) = @_;

  # Get the class for the name.
  my $cls = $self->class($name);

  # Call the class' new method.
  my $obj = $cls->__new_instance(@args);

  # Print some crap.
  if ( $self->{'debugCreate'} ) {
    local $" = ', ';
    print STDERR ref($self),"->create_instance($name, @args) = $obj\n";
  }

  $obj;
}


=head2 create

  my $obj = $self->create($name, @args);

Creates a new initialized instance of the class named $name, via $pkg->new(@args).


=cut
sub create
{
  my ($self, $name, @args) = @_;
  
  #$DB::single = $name eq 'Model';
  
  # Get the class for the name.
  my $cls = $self->class($name);

  # Call the classes new method.
  my $obj = $cls->new(@args);

  # Print some crap.
  if ( $self->{'debugCreate'} ) {
    local $" = ', ';
    print STDERR ref($self),"->create($name, @args) = $obj\n";
  }

  # die("Attribute 2561!!!\n") if $obj->{'_id'} eq 2561;

  $obj;
}



=head2 flush

  $self->flush($kind);

Called by C<UMMF::Core::Builder> for each $kind of object created during Model construction.

Subclasses may override this method.

=cut
sub flush
{
  $_[0];
}


#######################################################################

1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

