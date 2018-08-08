#####
#
# Support "Ghost" objects.  These represent deleted items which are not saved.
# They are omitted from regular class lists.
#
#####

package UR::Object::Ghost;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

sub _init_subclass {
    my $class_name = pop;
    no strict;
    no warnings;
    my $live_class_name = $class_name;
    $live_class_name =~ s/::Ghost$//;
    *{$class_name ."\:\:class"}  = sub { "$class_name" };
    *{$class_name ."\:\:live_class"}  = sub { "$live_class_name" };
}

sub create { Carp::croak('Cannot create() ghosts.') };

sub delete { Carp::croak('Cannot delete() ghosts.') };

sub __rollback__ {
    my $self = shift;

    # revive ghost object

    my $ghost_copy = eval("no strict; no warnings; " . Data::Dumper::Dumper($self));
    if ($@) {
        Carp::confess("Error re-constituting ghost object: $@");
    }
    my($saved_data, $saved_key);
    if (exists $ghost_copy->{'db_saved_uncommitted'} ) {
        $saved_data = $ghost_copy->{'db_saved_uncommitted'};
    } elsif (exists $ghost_copy->{'db_committed'} ) {
        $saved_data = $ghost_copy->{'db_committed'};
    } else {
        return; # This shouldn't happen?!
    }

    my $new_object = $self->live_class->UR::Object::create(%$saved_data);
    $new_object->{db_committed} = $ghost_copy->{db_committed} if (exists $ghost_copy->{'db_committed'});
    $new_object->{db_saved_uncommitted} = $ghost_copy->{db_saved_uncommitted} if (exists $ghost_copy->{'db_saved_uncommitted'});
    unless ($new_object) {
        Carp::confess("Failed to re-constitute $self!");
    }

    return $new_object;
}

sub _load {
    shift->is_loaded(@_);
}


sub unload {
    return;
}

sub __errors__ {
    return;  # Ghosts are always valid, don't check their properties
}

sub edit_class { undef }

sub ghost_class { undef }

sub is_ghost { return 1; }

sub live_class
{
    my $class = $_[0]->class;
    $class =~ s/::Ghost//;
    return $class;
}

my @ghost_changes;
sub changed {
    @ghost_changes = UR::Object::Tag->create ( type => 'changed', properties => ['id']) unless @ghost_changes;
    return @ghost_changes;
}

sub AUTOSUB
{
    # Delegate to the similar function on the regular class.
    my ($func, $self) = @_;
    my $live_class = $self->live_class;
    return $live_class->can($func);
}

1;


=pod

=head1 NAME

UR::Object::Ghost - Abstract class for representing deleted objects not yet committed

=head1 SYNOPSIS

  my $obj = Some::Class->get(1234);
  $obj->some_method();

  $obj->delete();   # $obj is now a UR::DeletedRef

  $ghost = Some::Class::Ghost->get(1234);
  $ghost->some_method;  # Works

=head1 DESCRIPTION

Ghost objects are a bookkeeping entity for tracking objects which have been
loaded from an external data source, deleted within the application, and not
yet committed.  This implies that they still exist in the external data
source.  When the Context is committed, the existence of Ghost objects
triggers commands to the external data sources to also delete the object(s).
When objects are brought into the Context by querying a data source, they
are compared against any ghosts that may already exist, and matching objects
are not re-loaded or returned to the user from a call to get().  If the
user wants to get Ghost objects, they must call get() explicitly on the
Ghost class.

Each class in the system also has an associated Ghost class, the name of which
is formed by tacking '::Ghost' to the name of the regular class.  Ghost 
classes do not have ghosts themselves.  
 
Instances of Ghosts are not instantiated with create() directly, they are
created as a concequence of deleting a regular object instance.  A Ghost 
can be turned back into a "live" object by re-creating it, or rolling back
the transaction it was deleted in.

=head1 DEPRECATED

Applications will not, and should not, normally interact with Ghosts.  The
whole Ghost system is scheduled for elimination as we refactor the Context
and software transaction framework.

=head1 SEE ALSO

UR::Object, UR::Object::Type

=cut

