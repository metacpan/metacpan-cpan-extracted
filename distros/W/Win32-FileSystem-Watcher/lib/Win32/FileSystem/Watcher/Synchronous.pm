package Win32::FileSystem::Watcher::Synchronous;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter Win32::FileSystem::Watcher::SimpleAccessors);

use Win32 qw();
use Win32::API;
use Win32::FileSystem::Watcher::Change;
use Win32::FileSystem::Watcher::Constants;
use Encode qw(decode);
use Win32::FileSystem::Watcher::SimpleAccessors;
use Carp;

our @EXPORT =
  (keys %{&FILE_NOTIFICATION_CONSTANTS}, keys %{&FILE_ACTION_CONSTANTS});

my $API = _register_api_functions();

__PACKAGE__->accessor('path');
__PACKAGE__->accessor('notify_filter');
__PACKAGE__->accessor('watch_sub_tree');
__PACKAGE__->accessor('dir_handle');
__PACKAGE__->accessor('notification_handler');

sub new {
    my $pkg = shift;
    croak 'no path' unless defined $_[0];
    my $self = {
        path           => shift,
        notify_filter  => FILE_NOTIFY_ALL,
        watch_sub_tree => 1,
        @_,
    };
    bless $self, $pkg;
    return $self;
}

sub get_results {
    my $self = shift;

    if ( !defined $self->dir_handle ) {
        $self->_ask_for_next_change;
        $self->_wait_for_changes(INFINITE);

        $self->dir_handle( _create_file( $self->path ) );
    }
    return $self->_get_results();
}

sub DESTROY {
    my $self = shift;

    if ( defined $self->notification_handler ) {
        my $result = $API->{find_close_change_notification}->Call( $self->notification_handler );
        if ($result == 0) {
            _win32_croak('')
        }
        $self->notification_handler(undef);
    }
    if ( defined $self->dir_handle ) {
        my $result = $API->{close_handle}->Call( $self->dir_handle );
        if ($result == 0) {
            _win32_croak('')
        }
        $self->dir_handle(undef);
    }
}

sub _register_api_functions {
    my %api = (
        find_first_change_notification => Win32::API->new( 'kernel32', 'FindFirstChangeNotification', 'PLN',      'L' ),
        find_next_change_notification  => Win32::API->new( 'kernel32', 'FindNextChangeNotification',  'I',        'I' ),
        find_close_change_notification => Win32::API->new( 'kernel32', 'FindCloseChangeNotification', 'I',        'I' ),
        wait_for_single_object         => Win32::API->new( 'kernel32', 'WaitForSingleObject',         'LN',       'L' ),
        read_directory_changes_w       => Win32::API->new( 'kernel32', 'ReadDirectoryChangesW',       'NPNINPPP', 'I' ),
        create_file                    => Win32::API->new( 'kernel32', 'CreateFileA',                 'PNNPNNN',  'N' ),
        close_handle                   => Win32::API->new( 'kernel32', 'CloseHandle',                 'I',        'I' ),

    );

    foreach my $function ( keys %api ) {
        if ( !defined $api{$function} ) {
            croak qq{Cannot find the win32 function "$function".};
        }
    }
    return \%api;
}

sub _get_results {
    my $self = shift;

    my $bytes_returned = pack( "L", 0 );
    my $buffer_len     = 1024;
    my $buffer         = "    " x $buffer_len;
    my $result =
      $API->{read_directory_changes_w}
      ->Call( $self->dir_handle, $buffer, $buffer_len, $self->watch_sub_tree, $self->notify_filter, $bytes_returned, NULL, NULL );
    $bytes_returned = unpack( "L", $bytes_returned );

    my @results = ();
    if ( $bytes_returned > 0 ) {
        while (1) {
            my ( $offset, $action, $fnlen ) = unpack( "LLL", $buffer );
            my ( undef, undef, undef, $fn ) = unpack( "LLLa$fnlen", $buffer );
            push @results, Win32::FileSystem::Watcher::Change->new( $action, _add_backslash($self->path) . decode( "UTF-16LE", $fn ) );
            last if $offset == 0;
            $buffer = substr( $buffer, $offset );
        }
    }
    return @results;
}

# Waits until we have a result.
sub _wait_for_changes {
    my ( $self, $millis ) = @_;
    my $event = $API->{wait_for_single_object}->Call( $self->notification_handler, $millis );

    if ( $event == WAIT_FAILED ) {
        _win32_croak('wait_for_single_object failed.');
    }
}

sub _ask_for_next_change {
    my $self = shift;
    if ( !defined $self->notification_handler ) {
        $self->notification_handler(
            $API->{find_first_change_notification}->Call( $self->path, $self->watch_sub_tree, $self->notify_filter ) );
    } else {
        if ( $API->{find_next_change_notification}->Call( $self->notification_handler ) == 0 ) {
            $self->notification_handler(undef);
            _win32_croak('Error while invoking a win32 directory function.');
        }
    }
    if ( !_is_good_handle( $self->notification_handler ) ) {
        $self->notification_handler(undef);
        _win32_croak('Error while invoking a win32 directory function');
    }
}

sub _create_file {
    my $path       = shift;
    my $dir_handle = $API->{create_file}->Call( $path, FILE_LIST_DIRECTORY, FILE_SHARE_READ | FILE_SHARE_DELETE,
        NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL );
    if ( !_is_good_handle($dir_handle) ) {
        croak 'Error while invoking a directory function';
    }
    return $dir_handle;
}

sub _is_good_handle {
    my $handle = shift;
    defined $handle && $handle != INVALID_HANDLE_VALUE;
}

sub _win32_croak {
    croak( shift() . " - " . Win32::FormatMessage( Win32::GetLastError() ) );
}

sub _add_backslash {
    my $s = shift;
    
    if ($s =~ m[\\$]) {
       return $s; 
    } else {
        return $s ."\\";
    }
}

1;
