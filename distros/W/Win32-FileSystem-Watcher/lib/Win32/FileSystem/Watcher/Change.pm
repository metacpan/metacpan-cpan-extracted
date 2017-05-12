package Win32::FileSystem::Watcher::Change;
use strict;
use warnings;
use Carp;
use Win32::FileSystem::Watcher::Constants;

sub new {
    my ( $pkg, $action, $file_name ) = @_;
    unless ( defined($action) && defined($file_name) && $file_name ne '' ) {
        croak "need an action and a file name.";
    }
    unless ( defined action_id_to_name->($action) ) {
        croak "Invalid action ID.";
    }
    my $obj = \"$action $file_name";
    bless $obj, $pkg;
    return $obj;
}

sub file_name {
    ${ $_[0] } =~ m/^\d+ (.*)/ ? $1 : undef;
}

sub action_id {
    ${ $_[0] } =~ m/^(\d+)/ ? $1 : undef;
}

sub action_name {
    return action_id_to_name( $_[0]->action_id );
}

# Class, Static, Utility methods

{
    my $action_name_to_id = FILE_ACTION_CONSTANTS;
    my $action_id_to_name = _reverse_hashref($action_name_to_id);

    sub action_id_to_name {
        shift if ref( $_[0] );
        if ( exists $action_id_to_name->{ $_[0] } ) {
            return $action_id_to_name->{ $_[0] };
        } else {
            return undef;
        }
    }

    sub action_name_to_id {
        shift if ref( $_[0] );
        if ( exists $action_name_to_id->{ $_[0] } ) {
            return $action_name_to_id->{ $_[0] };
        } else {
            return undef;
        }
    }
}

sub _reverse_hashref {
    my $hash = shift;
    return { map { $hash->{$_} => $_ } keys %$hash };
}

1;
