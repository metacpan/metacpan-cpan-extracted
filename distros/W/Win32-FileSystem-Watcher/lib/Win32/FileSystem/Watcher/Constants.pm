package Win32::FileSystem::Watcher::Constants;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

sub FILE_NOTIFICATION_CONSTANTS {
    return {
        FILE_NOTIFY_CHANGE_FILE_NAME   => 0x00000001,
        FILE_NOTIFY_CHANGE_DIR_NAME    => 0x00000002,
        FILE_NOTIFY_CHANGE_ATTRIBUTES  => 0x00000004,
        FILE_NOTIFY_CHANGE_SIZE        => 0x00000008,
        FILE_NOTIFY_CHANGE_LAST_WRITE  => 0x00000010,
        FILE_NOTIFY_CHANGE_LAST_ACCESS => 0x00000020,
        FILE_NOTIFY_CHANGE_CREATION    => 0x00000040,
        FILE_NOTIFY_CHANGE_SECURITY    => 0x00000100,
        FILE_NOTIFY_ALL                => 0x17F,
    };
}

sub FILE_ACTION_CONSTANTS {
    return {
        FILE_ACTION_ADDED            => 0x00000001,
        FILE_ACTION_REMOVED          => 0x00000002,
        FILE_ACTION_MODIFIED         => 0x00000003,
        FILE_ACTION_RENAMED_OLD_NAME => 0x00000004,
        FILE_ACTION_RENAMED_NEW_NAME => 0x00000005,
    };
}

my $constants = {
    %{&FILE_NOTIFICATION_CONSTANTS},
    %{&FILE_ACTION_CONSTANTS},
    INVALID_HANDLE_VALUE => -1,
    INFINITE             => -1,
    NULL                 => 0,

    WAIT_FAILED   => -1,
    WAIT_OBJECT_0 => 0,
    WAIT_TIMEOUT  => 0x00000102,

    FILE_SHARE_READ   => 0x00000001,
    FILE_SHARE_WRITE  => 0x00000002,
    FILE_SHARE_DELETE => 0x00000004,

    OPEN_EXISTING              => 3,
    FILE_FLAG_BACKUP_SEMANTICS => 0x02000000,
    FILE_LIST_DIRECTORY        => 0x0001,
};

foreach ( keys %$constants ) {
    eval "use constant $_ => $constants->{$_};";
}

our @EXPORT = (
    keys %$constants,
    qw(	FILE_NOTIFICATION_CONSTANTS FILE_ACTION_CONSTANTS)
);

1;
