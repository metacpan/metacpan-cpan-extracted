package UR::Context::AutoUnloadPool;

use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION

use Scalar::Util qw();

# These are plain Perl objects that get garbage collected in the normal way,
# not UR::Objects

our @CARP_NOT = qw( UR::Context );

my $pool_count = 0;
sub _pool_count { $pool_count }

sub create {
    my $class = shift;
    my $self = bless { pool => {} }, $class;
    $self->_attach_observer();
    $pool_count++;
    UR::Context::manage_objects_may_go_out_of_scope();
    return $self;
}

sub delete {
    my $self = shift;
    delete $self->{pool};
    $self->_detach_observer();
    $pool_count--;
    UR::Context::manage_objects_may_go_out_of_scope();
    return 1;
}

sub _attach_observer {
    my $self = shift;
    Scalar::Util::weaken($self);
    my $o = UR::Object->add_observer(
                aspect => 'load',
                callback => sub {
                    my $loaded = shift;

                    return if ! $loaded->is_prunable();
                    $self->_object_was_loaded($loaded);
                }
            );
    $self->{observer} = $o;
}

sub _detach_observer {
    my $self = shift;
    delete($self->{observer})->delete();
}

sub _is_printing_debug {
    $ENV{UR_DEBUG_OBJECT_PRUNING} || $ENV{'UR_DEBUG_OBJECT_RELEASE'};
}

sub _object_was_loaded {
    my($self, $o) = @_;
    if (_is_printing_debug()) {
        my($class, $id) = ($o->class, $o->id);
        print STDERR Carp::shortmess("MEM AUTORELEASE $class id $id loaded in pool $self\n");
    }
    $self->{pool}->{$o->class}->{$o->id} = undef;
}

sub _unload_objects {
    my $self = shift;
    return unless $self->{pool};

    print STDERR Carp::shortmess("MEM AUTORELEASE pool $self draining\n") if _is_printing_debug();

    foreach my $class_name ( keys %{$self->{pool}} ) {
        if (_is_printing_debug()) {
            printf STDERR "MEM AUTORELEASE class $class_name: %s\n",
                            join(', ', values %{ $self->{pool}->{$class_name}} );
        }
        my $objs_for_class = $UR::Context::all_objects_loaded->{$class_name};
        next unless $objs_for_class;
        my @objs_to_release = grep { ! $_->__changes__ }
                              @$objs_for_class{ keys %{$self->{pool}->{$class_name}}};
        UR::Context->current->_weaken_references_for_objects(\@objs_to_release);
    }
    delete $self->{pool};
}

sub DESTROY {
    local $@;

    my $self = shift;
    return unless ($self->{pool});
    $self->_detach_observer();
    $self->_unload_objects();
    $pool_count--;
    UR::Context::manage_objects_may_go_out_of_scope();
}

1;

=pod

=head1 NAME

UR::Context::AutoUnloadPool - Automatically unload objects when scope ends

=head1 SYNOPSIS

  my $not_unloaded = Some::Class->get(...);
  do {
    my $guard = UR::Context::AutoUnloadPool->create();
    my $object = Some::Class->get(...);  # load an object from the database
    ...                                  # load more things
  };  # $guard goes out of scope - unloads objects

=head1 DESCRIPTION

UR Objects retrieved from the database normally live in the object cache for
the life of the program.  When a UR::Context::AutoUnloadPool is instantiated,
it tracks every object loaded during its life.  The Pool's destructor calls
unload() on those objects.

Changed objects and objects loaded before before the Pool is created will not
get unloaded.

=head1 METHODS

=over 4

=item create

  my $guard = UR::Context::AutoUnloadPool->create();

Creates a Pool object.  All UR Objects loaded from the database during this
object's lifetime will get unloaded when the Pool goes out of scope.

=item delete

  $guard->delete();

Invalidates the Pool object.  No objects are unloaded.  When the Pool later
goes out of scope, no objects will be unloaded.

=back

=head1 SEE ALSO

UR::Object, UR::Context

=cut
