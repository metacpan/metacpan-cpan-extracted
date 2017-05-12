package Tk::IDElayout::DropBox;
our ($VERSION) = ('0.32');

use strict;
use warnings;
use Carp;


=head1 NAME

Tk::IDElayout::DropBox -  IDElayout Helper class for Drag Drop Operations

=head1 DESCRIPTION

This is a simple I<Singleton> class that implements a simple I<DropBox> to help
in drag-drop operations for the L<Tk::IDElayout> and L<Tk::IDEtabFrame> widgets. This dropbox is similar to
a global hash for temporary storage of objects that are dragged, so that the drop location can pickup the dropped
object perform any processing.

It only makes sense to have one instance of this object per process, so this
class implements the I<Singleton> design pattern to keep only one
instance. Therefore, there is no I<new> method, only an I<instance> method used
to gain access to the one instance of the class.

=head1 METHODS

=head2 _new

Internal method used to create the object.

=cut  

sub _new{

	my $type = shift;
	
	
	my $self = {};
	
	
	$self->{dropbox}  = {};
	
	bless $self, $type;
	
	return $self;
	
}

=head2 instance

Access the single instance of this class

B<Usage:>

  my $dropbox = Tk::IDElayout::DropBox->instance;


=cut  

my $numberOfInstances = 0;
my $DropBox;

sub instance{ 

	my $type = shift;
	
	unless( $numberOfInstances ){
		$DropBox = $type->_new;
		$numberOfInstances++;
	}
	
	return $DropBox;
}

#################################################################################3

=head2 set

Set a location in the dropbox to a value. This is similar to setting the value of a hash

B<Usage:>

 $DropBox->set($key, $value)
 
  where:
     $key: Location (i.e. key) in the dropbox to store
     $value: Data to store in the dropbox.
     

=cut  


sub set{

	my $self = shift;
        
        my ($key, $value) = @_;
        
        $self->{dropbox}{$key} = $value;
	
	
}

################################################################################

=head2 get

Get the data in a location in the dropbox. This is similar to getting the value of a hash

B<Usage:>

 my $value = $DropBox->get($key);
 
  where:
     $key: Location (i.e. key) in the dropbox to store
     $value: Data to retreived in the dropbox.
     

=cut  


sub get{

	my $self = shift;
        
        my $key  = shift;
        
       return $self->{dropbox}{$key};
	
	
}

################################################################################

=head2 delete

Delete the data in a location in the dropbox. This is similar to deleting the value of a hash.

B<Usage:>

 my $value = $DropBox->delete($key);
 
  where:
     $key: Location (i.e. key) in the dropbox to store
     $value: Data deleted in the dropbox.
     

=cut  


sub delete{

	my $self = shift;
        
        my $key  = shift;
        
       return delete $self->{dropbox}{$key};
	
	
}

	


1;
