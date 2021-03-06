package UMMF::Core::Object;

use 5.6.0;
use strict;
#use warnings;


our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/15 };
our $VERSION = do { my @r = (q$Revision: 1.16 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Core::Object - A base class for all meta-metamodel classes.

=head1 SYNOPSIS

  use base qw(UMMF::Core::Object);

=head1 DESCRIPTION

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/15

=head1 SEE ALSO

L<UMMF::UML::XMI|UMMF::UML::XMI>

=head1 VERSION

$Revision: 1.16 $

=head1 METHODS

=cut


#######################################################################
# Base class for all meta-metamodle classes.
#
# Note: no AUTOLOAD facilities.
#

package UMMF::Core::Object::Base;

our $VERSION = do { my @r = (q$Revision: 1.16 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };


sub new
{
  my ($self, %opts) = @_;
  $self = bless(\%opts, ref($self) || $self);
  $self->initialize();
}


sub initialize
{
  my ($self) = @_;

  $self;
}


####################################################################
# Base class for all meta model objects.
# Note: Clients of this class rely on AUTOLOAD functionality.
#


package UMMF::Core::Object;

use base qw(UMMF::Core::Object::Base);


use UMMF::Core::Util qw(__fix_association_end_names);
use Carp qw(confess);


sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  # Use accessors to initialize.
  for my $key ( keys %$self ) {
    my $val = $self->{$key};
    my $meth;

    # $DB::single = 1 if $key eq 'connection';

    if ( ref($val) eq 'ARRAY' && $self->can($meth = "add_$key") ) {
      $self->{$key} = undef;
      $self->$meth(@$val);
    }
    elsif ( $self->can($meth = "set_$key") ) {
      $self->{$key} = undef;
      # $DB::single = 1 if $val =~ /::Smc/;
      $self->$meth($val);
    }
  }

  $self;
}


use vars qw($AUTOLOAD);

our $AUTOLOAD_verbose = 0;

use UMMF::Core::Util qw(ISA_super);
my %__isa; # isa<Classifier> cache.


sub AUTOLOAD
{
  no strict 'refs';
  
  my ($self, @args) = @_;
  local ($1, $2);
  
  my ($package, $operation) = $AUTOLOAD =~ m/^(?:(.+)::)([^:]+)$/;
  return if $operation eq 'DESTROY';
  
  #$DB::single = 1;
  
  # warn __PACKAGE__ . ": package='$package' operation='$operation'";
  
  # $DB::single = 1 if $operation eq 'importedElement';

  my ($method); # The autogenerated method.  

  if ( $operation =~ /^isa([A-Z][A-Za-z_0-9]*)$/ ) {
    my $target_cls = $1;
    $target_cls =~ s/__/::/sg;
    $target_cls = "::$target_cls" unless $target_cls =~ /^::/;

    my $ref = ref($self) || $self;
    # confess("WHOOPS!!!") if $ref =~ /::FoldMultipleInheritance/;

    # Try cache.
    my $method = $__isa{"$ref\t$operation"};
    return $method if defined $method;

    my @super = ISA_super($ref);
    # local $" = ', '; print STDERR "$operation : $ref supers: @super\n";
    # $DB::single = 1;
    $method = grep(/$target_cls$/, @super) ? 1 : 0;
    # print STDERR "$ref \t $operation \t = ", $method, "\n";
    
    # Save in cache.
    return $__isa{"$ref\t$operation"} = $method;
  }
  elsif ( $operation =~ /^set_(\w+)$/ # and exists($self->{$1})
       ) {
    my $slot = $1;
    $method = sub {
      no warnings; # Use of uninitialized value in string ne
      if ( $_[0]->{$slot} ne $_[1] ) {
	$_[0]->{$slot} = $_[1];
      }
      $_[0];
    };
  }
  elsif ( @_ == 1 ) {
    warn "$_[0] -> {$operation} does not exist" 
    if ( $AUTOLOAD_verbose && ! exists($self->{$operation}) );
    
    $method = sub {
      if ( wantarray ) {
	if ( ref($_[0]->{$operation}) eq 'ARRAY' ) {
	  @{$_[0]->{$operation}}
	} else {
	  ( $_[0]->{$operation} )
	}
      } else {
	$_[0]->{$operation};
      }
    };
  }
  
  # Save the generated method and invoke it.
  if ( $method ) {
    *{$AUTOLOAD} = $method;
    # Tail call now.
    goto &$method;
  } else {
    confess('Exception::Object::UndefinedMethod: ' . 
	join(' ',
	    'package'   => $package,
	    'operation' => $operation,
	    'reciever'  => $self,
	    'arguments' => [ @args ],
	     )
	);
  }
}


sub __clone
{
  my ($self) = @_;

  $self = bless({ %$self }, ref($self));

  for my $key ( keys %$self ) {
    my $v = $self->{$key};
    if ( ref($v) eq 'ARRAY' ) {
      $self->{$key} = [ @$v ];
    } elsif ( ref($v) eq 'HASH' ) {
      $self->{$key} = { %$v };
    }
  }

  $self;
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

