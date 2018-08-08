package UR::DeletedRef;

use strict;
use warnings;
require UR;

BEGIN {
    # this is to workaround a Perl bug where the overload magic flag is not updated
    # for references with a different RV (which happens anytime you do "my $object"
    # https://rt.perl.org/rt3/Public/Bug/Display.html?id=9472
    if ($^V lt v5.8.9) {
        eval "use overload fallback => 1";
    };
};

our $VERSION = "0.47"; # UR $VERSION;

our $all_objects_deleted = {};

sub bury {
    my $class = shift;

    for my $object (@_) {
        if ($ENV{'UR_DEBUG_OBJECT_RELEASE'}) {
            print STDERR "MEM BURY object $object class ",$object->class," id ",$object->id,"\n";
        }
        my $original_class = ref($object);
        my $original_id = $object->id;

        %$object = (original_class => ref($object), original_data => {%$object});
        bless $object, 'UR::DeletedRef';

        $all_objects_deleted->{$original_class}->{$original_id} = $object;
        Scalar::Util::weaken($all_objects_deleted->{$original_class}->{$original_id});
    }

    return 1;
}

sub resurrect {
    shift unless (ref($_[0]));

    foreach my $object (@_) {
        my $original_class = $object->{'original_class'};
        bless $object, $original_class;
        %$object = (%{$object->{original_data}});
        my $id = $object->id;
        delete $all_objects_deleted->{$original_class}->{$id};
        $object->resurrect_object if ($object->can('resurrect_object'));
    }

    return 1;
}

use Data::Dumper;

sub AUTOLOAD {
    our $AUTOLOAD;
    my $method = $AUTOLOAD;
    $method =~ s/^.*:://g;
    Carp::croak("Attempt to use a reference to an object which has been deleted.  A call was made to method '$method'\nRessurrect it first.\n" . Dumper($_[0]));
}

sub __rollback__ {
    return 1;
}

sub DESTROY {
    if ($ENV{'UR_DEBUG_OBJECT_RELEASE'}) {
        print STDERR "MEM DESTROY deletedref $_[0]\n";
    }
    delete $all_objects_deleted->{"$_[0]"};
}

1;


=pod

=head1 NAME

UR::DeletedRef - Represents an instance of a no-longer-existent object

=head1 SYNOPSIS

  my $obj = Some::Class->get(123);
  
  $obj->delete;
  print ref($obj),"\n";  # prints 'UR::DeletedRef'
  $obj->some_method();   # generates an exception through Carp::confess

  $obj->resurrect; 
  print ref($obj),"\n";  # prints 'Some::Class'

=head1 DESCRIPTION

Object instances become UR::DeletedRefs when some part of the application 
calls delete() or unload() on them, meaning that they no longer exist
in that Context.  The extant object reference is turned into a UR::DeletedRef
so that if that same reference is used in any capacity later in the program,
it will generate an exception through its AUTOLOAD to prevent using it by
mistake.

Note that UR::DeletedRef instances are different than Ghost objects.  When a
UR-based object is deleted through delete(), a new Ghost object reference is
created from the data in the old object, and the old object reference is
re-blessed as a UR::DeletedRef.  Any variables still referencing the original
object now hold a reference to this UR::DeletedRef.  The Ghost object can be
retrieved by issuing a get() against the Ghost class.

Objects unloaded from the Context using unload(), or indirectly by rolling-back
a transaction which triggers unload of objects loaded during the transaction,
are also turned into UR::DeletedRefs.  

You aren't likely to encounter UR::DeletedRefs in normal use.  What usually
happens is that an object will be deleted with delete() (or unload()), the
lexical variable pointing to the DeletedRef will soon go out of scope and
the DeletedRef will then be garbage-colelcted.

=head1 SEE ALSO

UR::Object, UR::Object::Ghost, UR::Context

=cut

