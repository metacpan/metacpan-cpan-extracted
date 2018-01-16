package Udev::FFI::Functions;

use strict;
use warnings;

our (@ISA, @EXPORT_OK, %EXPORT_TAGS);

require Exporter;
@ISA = qw(Exporter);

use IPC::Cmd qw(can_run);

use FFI::Platypus;
use FFI::CheckLib;


use constant {
    UDEVADM_LOCATIONS => [
        '/bin/udevadm',
        '/sbin/udevadm'
    ]
};



my $FUNCTIONS = {
    # struct udev *udev_new(void);
    'udev_new' => {
        ffi_data => [ [], 'opaque' ]
    },

    # struct udev *udev_ref(struct udev *udev);
    'udev_ref' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev *udev_unref(struct udev *udev);
    'udev_unref' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # access to libudev generated lists ====================================

    # struct udev_list_entry *udev_list_entry_get_next(struct udev_list_entry *list_entry);
    'udev_list_entry_get_next' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_list_entry *udev_list_entry_get_by_name(struct udev_list_entry *list_entry, const char *name);
    'udev_list_entry_get_by_name' => {
        ffi_data => [ ['opaque', 'string'], 'opaque']
    },

    # const char *udev_list_entry_get_name(struct udev_list_entry *list_entry);
    'udev_list_entry_get_name' => {
        ffi_data => [ ['opaque'], 'string' ]
    },

    # const char *udev_list_entry_get_value(struct udev_list_entry *list_entry);
    'udev_list_entry_get_value' => {
        ffi_data => [ ['opaque'], 'string' ]
    },


    # udev_device ==========================================================

    # struct udev_device *udev_device_ref(struct udev_device *udev_device);
    'udev_device_ref' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_device *udev_device_unref(struct udev_device *udev_device);
    'udev_device_unref' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev *udev_device_get_udev(struct udev_device *udev_device);
    'udev_device_get_udev' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_device *udev_device_new_from_syspath(struct udev *udev, const char *syspath);
    'udev_device_new_from_syspath' => {
        ffi_data => [ ['opaque', 'string'], 'opaque' ]
    },

    # struct udev_device *udev_device_new_from_devnum(struct udev *udev, char type, dev_t devnum);
    'udev_device_new_from_devnum' => {
        ffi_data => [ ['opaque', 'signed char', 'uint64_t'], 'opaque' ]
    },

    # struct udev_device *udev_device_new_from_subsystem_sysname(struct udev *udev, const char *subsystem, const char *sysname);
    'udev_device_new_from_subsystem_sysname' => {
        ffi_data => [ ['opaque', 'string', 'string'], 'opaque' ]
    },

    # struct udev_device *udev_device_new_from_device_id(struct udev *udev, const char *id);
    'udev_device_new_from_device_id' => {
        ffi_data => [ ['opaque', 'string'], 'opaque' ],
        since    => 189
    },

    # struct udev_device *udev_device_new_from_environment(struct udev *udev);
    'udev_device_new_from_environment' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_device *udev_device_get_parent(struct udev_device *udev_device);
    'udev_device_get_parent' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_device *udev_device_get_parent_with_subsystem_devtype(struct udev_device *udev_device,
    #     const char *subsystem, const char *devtype);
    'udev_device_get_parent_with_subsystem_devtype' => {
        ffi_data => [ ['opaque', 'string', 'string'], 'opaque' ]
    },

    # retrieve device properties

    # const char *udev_device_get_devpath(struct udev_device *udev_device);
    'udev_device_get_devpath'  => {
        ffi_data => [ ['opaque'], 'string' ]
    },

    # const char *udev_device_get_subsystem(struct udev_device *udev_device);
    'udev_device_get_subsystem' => {
        ffi_data => [ ['opaque'], 'string' ]
    },

    # const char *udev_device_get_devtype(struct udev_device *udev_device);
    'udev_device_get_devtype' => {
        ffi_data => [ ['opaque'], 'string' ]
    },

    # const char *udev_device_get_syspath(struct udev_device *udev_device);
    'udev_device_get_syspath' => {
        ffi_data => [ ['opaque'], 'string' ]
    },

    # const char *udev_device_get_sysname(struct udev_device *udev_device);
    'udev_device_get_sysname' => {
        ffi_data => [ ['opaque'], 'string' ]
    },

    # const char *udev_device_get_sysnum(struct udev_device *udev_device);
    'udev_device_get_sysnum' => {
        ffi_data => [ ['opaque'], 'string' ]
    },

    # const char *udev_device_get_devnode(struct udev_device *udev_device);
    'udev_device_get_devnode' => {
        ffi_data => [ ['opaque'], 'string' ]
    },

    #int udev_device_get_is_initialized(struct udev_device *udev_device);
    'udev_device_get_is_initialized' => {
        ffi_data => [ ['opaque'], 'int' ]
    },

    # struct udev_list_entry *udev_device_get_devlinks_list_entry(struct udev_device *udev_device);
    'udev_device_get_devlinks_list_entry' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_list_entry *udev_device_get_properties_list_entry(struct udev_device *udev_device);
    'udev_device_get_properties_list_entry' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_list_entry *udev_device_get_tags_list_entry(struct udev_device *udev_device);
    'udev_device_get_tags_list_entry' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_list_entry *udev_device_get_sysattr_list_entry(struct udev_device *udev_device);
    'udev_device_get_sysattr_list_entry' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    #const char *udev_device_get_property_value(struct udev_device *udev_device, const char *key);
    'udev_device_get_property_value' => {
        ffi_data => [ ['opaque', 'string'], 'string' ]
    },

    #const char *udev_device_get_driver(struct udev_device *udev_device);
    'udev_device_get_driver' => {
        ffi_data => [ ['opaque'], 'string' ]
    },

    # dev_t udev_device_get_devnum(struct udev_device *udev_device);
    'udev_device_get_devnum' => {
        ffi_data => [ ['opaque'], 'uint64_t' ]
    },

    #const char *udev_device_get_action(struct udev_device *udev_device);
    'udev_device_get_action' => {
        ffi_data => [ ['opaque'], 'string' ]
    },

    #unsigned long long int udev_device_get_seqnum(struct udev_device *udev_device);
    'udev_device_get_seqnum' => {
        ffi_data => [ ['opaque'], 'unsigned long long' ]
    },

    #unsigned long long int udev_device_get_usec_since_initialized(struct udev_device *udev_device);
    'udev_device_get_usec_since_initialized' => {
        ffi_data => [ ['opaque'], 'unsigned long long' ]
    },

    #const char *udev_device_get_sysattr_value(struct udev_device *udev_device, const char *sysattr);
    'udev_device_get_sysattr_value' => {
        ffi_data => [ ['opaque', 'string'], 'string' ]
    },

    #int udev_device_set_sysattr_value(struct udev_device *udev_device, const char *sysattr, char *value);
    'udev_device_set_sysattr_value' => {
        ffi_data => [ ['opaque', 'string', 'string'], 'int' ],
        since    => 199
    },

    #int udev_device_has_tag(struct udev_device *udev_device, const char *tag);
    'udev_device_has_tag' => {
        ffi_data => [ ['opaque', 'string'], 'int' ]
    },


    # udev_monitor =========================================================

    # access to kernel uevents and udev events

    # struct udev_monitor *udev_monitor_ref(struct udev_monitor *udev_monitor);
    'udev_monitor_ref' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_monitor *udev_monitor_unref(struct udev_monitor *udev_monitor);
    'udev_monitor_unref' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev *udev_monitor_get_udev(struct udev_monitor *udev_monitor);
    'udev_monitor_get_udev' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    #kernel and udev generated events over netlink

    # struct udev_monitor *udev_monitor_new_from_netlink(struct udev *udev, const char *name);
    'udev_monitor_new_from_netlink' => {
        ffi_data => [ ['opaque', 'string'], 'opaque' ]
    },

    # bind socket

    # int udev_monitor_enable_receiving(struct udev_monitor *udev_monitor);
    'udev_monitor_enable_receiving' => {
        ffi_data => [ ['opaque'], 'int' ]
    },

    # int udev_monitor_set_receive_buffer_size(struct udev_monitor *udev_monitor, int size);
    'udev_monitor_set_receive_buffer_size' => {
        ffi_data => [ ['opaque', 'int'], 'int' ]
    },

    # int udev_monitor_get_fd(struct udev_monitor *udev_monitor);
    'udev_monitor_get_fd' => {
        ffi_data => [ ['opaque'], 'int' ]
    },

    # struct udev_device *udev_monitor_receive_device(struct udev_monitor *udev_monitor);
    'udev_monitor_receive_device' => {
        ffi_data => [ ['opaque'], 'opaque']
    },

    # n-kernel socket filters to select messages that get delivered to a listener

    # int udev_monitor_filter_add_match_subsystem_devtype(struct udev_monitor *udev_monitor,
    #     const char *subsystem, const char *devtype);
    'udev_monitor_filter_add_match_subsystem_devtype' => {
        ffi_data => [ ['opaque', 'string', 'string'], 'int' ]
    },

    # int udev_monitor_filter_add_match_tag(struct udev_monitor *udev_monitor, const char *tag);
    'udev_monitor_filter_add_match_tag' => {
        ffi_data => [ ['opaque', 'string'], 'int' ]
    },

    # int udev_monitor_filter_update(struct udev_monitor *udev_monitor);
    'udev_monitor_filter_update' => {
        ffi_data => [ ['opaque'], 'int' ]
    },

    # int udev_monitor_filter_remove(struct udev_monitor *udev_monitor);
    'udev_monitor_filter_remove' => {
        ffi_data => [ ['opaque'], 'int' ]
    },


    # udev_enumerate =======================================================

    # search sysfs for specific devices and provide a sorted list

    # struct udev_enumerate *udev_enumerate_ref(struct udev_enumerate *udev_enumerate);
    'udev_enumerate_ref' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_enumerate *udev_enumerate_unref(struct udev_enumerate *udev_enumerate);
    'udev_enumerate_unref' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev *udev_enumerate_get_udev(struct udev_enumerate *udev_enumerate);
    'udev_enumerate_get_udev' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # struct udev_enumerate *udev_enumerate_new(struct udev *udev);
    'udev_enumerate_new' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    },

    # device properties filter

    # int udev_enumerate_add_match_subsystem(struct udev_enumerate *udev_enumerate, const char *subsystem);
    'udev_enumerate_add_match_subsystem' => {
        ffi_data => [ ['opaque', 'string'], 'int' ]
    },

    # int udev_enumerate_add_nomatch_subsystem(struct udev_enumerate *udev_enumerate, const char *subsystem);
    'udev_enumerate_add_nomatch_subsystem' => {
        ffi_data => [ ['opaque', 'string'], 'int' ]
    },

    # int udev_enumerate_add_match_sysattr(struct udev_enumerate *udev_enumerate, const char *sysattr, const char *value);
    'udev_enumerate_add_match_sysattr' => {
        ffi_data => [ ['opaque', 'string', 'string'], 'int' ]
    },

    # int udev_enumerate_add_nomatch_sysattr(struct udev_enumerate *udev_enumerate, const char *sysattr, const char *value);
    'udev_enumerate_add_nomatch_sysattr' => {
        ffi_data => [ ['opaque', 'string', 'string'], 'int' ]
    },

    # int udev_enumerate_add_match_property(struct udev_enumerate *udev_enumerate, const char *property, const char *value);
    'udev_enumerate_add_match_property' => {
        ffi_data => [ ['opaque', 'string', 'string'], 'int' ]
    },

    # int udev_enumerate_add_match_sysname(struct udev_enumerate *udev_enumerate, const char *sysname);
    'udev_enumerate_add_match_sysname' => {
        ffi_data => [ ['opaque', 'string'], 'int' ]
    },

    # int udev_enumerate_add_match_tag(struct udev_enumerate *udev_enumerate, const char *tag);
    'udev_enumerate_add_match_tag' => {
        ffi_data => [ ['opaque', 'string'], 'int' ]
    },

    # int udev_enumerate_add_match_parent(struct udev_enumerate *udev_enumerate, struct udev_device *parent);
    'udev_enumerate_add_match_parent' => {
        ffi_data => [ ['opaque', 'opaque'], 'int' ]
    },

    # int udev_enumerate_add_match_is_initialized(struct udev_enumerate *udev_enumerate);
    'udev_enumerate_add_match_is_initialized' => {
        ffi_data => [ ['opaque'], 'int' ]
    },

    # int udev_enumerate_add_syspath(struct udev_enumerate *udev_enumerate, const char *syspath);
    'udev_enumerate_add_syspath' => {
        ffi_data => [ ['opaque', 'string'], 'int' ]
    },

    # run enumeration with active filters

    # int udev_enumerate_scan_devices(struct udev_enumerate *udev_enumerate);
    'udev_enumerate_scan_devices' => {
        ffi_data => [ ['opaque'], 'int' ]
    },

    # int udev_enumerate_scan_subsystems(struct udev_enumerate *udev_enumerate);
    'udev_enumerate_scan_subsystems' => {
        ffi_data => [ ['opaque'], 'int' ]
    },

    # return device list

    # struct udev_list_entry *udev_enumerate_get_list_entry(struct udev_enumerate *udev_enumerate);
    'udev_enumerate_get_list_entry' => {
        ffi_data => [ ['opaque'], 'opaque' ]
    }
};



@EXPORT_OK = ( keys(%$FUNCTIONS), qw(get_entries));

%EXPORT_TAGS = (
    'all' => \@EXPORT_OK
);


my $init = 0;



sub udev_version {
    my $full_path = can_run('udevadm');

    if(!defined $full_path) {
        for(@{ +UDEVADM_LOCATIONS }) {
            if(-f) {
                $full_path = $_;
                last;
            }
        }
    }

    if(!defined $full_path) {
        $@ = "Can't find `udevadm` utility";
        return undef;
    }


    {
        local $SIG{__WARN__} = sub {}; # silence shell output if error

        if(open my $ph, '-|', $full_path, '--version') {
            my $out = <$ph>;

            if(defined($out) && $out =~ /^(\d+)\s*$/) {
                return $1;
            }

            $@ = "Can't get udev version from `udevadm` utility";
            return undef;
        }
    }

    $@ = "Can't run `udevadm` utility";
    return undef;
}



my $_function_not_attach = sub {
    my $udev_version = udev_version();

    die "Function '".$_[0]."' not attached from udev library\n".
        "`udevadm` version: ".(defined($udev_version) ?$udev_version :'unknown')."\n";
};



sub get_entries {
    my $entry = shift;

    if(wantarray) {
        my @a = ();

        while(defined($entry)) {
            push @a, udev_list_entry_get_name($entry);
            $entry = udev_list_entry_get_next($entry);
        }

        return @a;
    }


    my %h = ();

    while(defined($entry)) {
        $h{ udev_list_entry_get_name($entry) } = udev_list_entry_get_value($entry);
        $entry = udev_list_entry_get_next($entry);
    }

    return \%h;
}



sub init {
    return 1 if $init;


    my ($libudev) = find_lib(
        lib => 'udev'
    );
    if(!$libudev) {
        $@ = "Can't find udev library";
        return 0;
    }

    my $udev_version = udev_version() || 0;

    my $ffi = FFI::Platypus->new;
    $ffi->lib($libudev);

    if(8 != (my $sizeof_dev_t = $ffi->sizeof('dev_t'))) {
        $@ = "sizeof(dev_t) != 8 on your OS (sizeof(dev_t) == $sizeof_dev_t). Please report this to the author";
        return 0;
    }

    for my $funct (keys %$FUNCTIONS) {
        eval {
            # attach locks the function and the FFI::Platypus instance into memory permanently,
            # since there is no way to deallocate an xsub
            $ffi->attach($funct => $FUNCTIONS->{$funct}{ffi_data}[0] => $FUNCTIONS->{$funct}{ffi_data}[1]);
        };
        if($@) {
            if(!exists($FUNCTIONS->{$funct}{since}) || $udev_version >= $FUNCTIONS->{$funct}{since}) {
                $@ = $1
                    if $@ =~ m{^(.*)\s+at\s.*line\s\d+.}xms;

                $@ = "Can't attach '$funct' function from udev library: $@";
                return 0;
            }

            no strict 'refs';
            *$funct = sub { $_function_not_attach->($funct) };
        }

        # function attached
        delete $FUNCTIONS->{$funct};
    }

    return ++$init;
}



1;