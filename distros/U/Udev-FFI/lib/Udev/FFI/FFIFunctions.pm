package Udev::FFI::FFIFunctions;

use strict;
use warnings;


our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
udev_new
udev_ref
udev_unref
udev_list_entry_get_next
udev_list_entry_get_by_name
udev_list_entry_get_name
udev_list_entry_get_value
udev_device_ref
udev_device_unref
udev_device_get_udev
udev_device_new_from_syspath
udev_device_new_from_devnum
udev_device_new_from_subsystem_sysname
udev_device_new_from_device_id
udev_device_new_from_environment
udev_device_get_parent
udev_device_get_parent_with_subsystem_devtype
udev_device_get_devpath
udev_device_get_subsystem
udev_device_get_devtype
udev_device_get_syspath
udev_device_get_sysname
udev_device_get_sysnum
udev_device_get_devnode
udev_device_get_is_initialized
udev_device_get_devlinks_list_entry
udev_device_get_properties_list_entry
udev_device_get_tags_list_entry
udev_device_get_sysattr_list_entry
udev_device_get_property_value
udev_device_get_driver
udev_device_get_devnum
udev_device_get_action
udev_device_get_seqnum
udev_device_get_usec_since_initialized
udev_device_get_sysattr_value
udev_device_set_sysattr_value
udev_device_has_tag
udev_monitor_ref
udev_monitor_unref
udev_monitor_get_udev
udev_monitor_new_from_netlink
udev_monitor_enable_receiving
udev_monitor_set_receive_buffer_size
udev_monitor_get_fd
udev_monitor_receive_device
udev_monitor_filter_add_match_subsystem_devtype
udev_monitor_filter_add_match_tag
udev_monitor_filter_update
udev_monitor_filter_remove
udev_enumerate_ref
udev_enumerate_unref
udev_enumerate_get_udev
udev_enumerate_new
udev_enumerate_add_match_subsystem
udev_enumerate_add_nomatch_subsystem
udev_enumerate_add_match_sysattr
udev_enumerate_add_nomatch_sysattr
udev_enumerate_add_match_property
udev_enumerate_add_match_sysname
udev_enumerate_add_match_tag
udev_enumerate_add_match_parent
udev_enumerate_add_match_is_initialized
udev_enumerate_add_syspath
udev_enumerate_scan_devices
udev_enumerate_scan_subsystems
udev_enumerate_get_list_entry

get_entries
);


use FFI::Platypus;
use FFI::CheckLib;



my $ffi;



sub get_entries {
    my $entry = shift;

    if(wantarray) {
        my @a = ();

        if(defined($entry)) {
            push @a, udev_list_entry_get_name($entry)
                while defined($entry = udev_list_entry_get_next($entry));
        }

        return @a;
    }


    my %h = ();

    if(defined($entry)) {
        $h{ udev_list_entry_get_name($entry) } = udev_list_entry_get_value($entry)
            while defined($entry = udev_list_entry_get_next($entry));
    }

    return \%h;
}



sub load_lib {
    unless(defined($ffi)) {
        my $libudev = find_lib(
            lib => 'udev'
        );
        if(!$libudev) {
            return 0;
        }

        $ffi = FFI::Platypus->new;
        $ffi->lib($libudev);


        if(8 != $ffi->sizeof('dev_t')) {
            #TODO only 2 dev_t funct return undef and set $@
            return 0;
        }


        # struct udev *udev_new(void);
        $ffi->attach('udev_new'   => []         => 'opaque');

        # struct udev *udev_ref(struct udev *udev);
        $ffi->attach('udev_ref'   => ['opaque'] => 'opaque');

        # struct udev *udev_unref(struct udev *udev);
        $ffi->attach('udev_unref' => ['opaque'] => 'opaque');


        # access to libudev generated lists ====================================

        # struct udev_list_entry *udev_list_entry_get_next(struct udev_list_entry *list_entry);
        $ffi->attach('udev_list_entry_get_next'    => ['opaque'] => 'opaque');

        # struct udev_list_entry *udev_list_entry_get_by_name(struct udev_list_entry *list_entry, const char *name);
        $ffi->attach('udev_list_entry_get_by_name' => ['opaque', 'string'] => 'opaque');

        # const char *udev_list_entry_get_name(struct udev_list_entry *list_entry);
        $ffi->attach('udev_list_entry_get_name'    => ['opaque'] => 'string');

        # const char *udev_list_entry_get_value(struct udev_list_entry *list_entry);
        $ffi->attach('udev_list_entry_get_value'   => ['opaque'] => 'string');


        # udev_device ==========================================================

        # struct udev_device *udev_device_ref(struct udev_device *udev_device);
        $ffi->attach('udev_device_ref'      => ['opaque'] => 'opaque');

        # struct udev_device *udev_device_unref(struct udev_device *udev_device);
        $ffi->attach('udev_device_unref'    => ['opaque'] => 'opaque');

        # struct udev *udev_device_get_udev(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_udev' => ['opaque'] => 'opaque');

        # struct udev_device *udev_device_new_from_syspath(struct udev *udev, const char *syspath);
        $ffi->attach('udev_device_new_from_syspath' => ['opaque', 'string'] => 'opaque');

        # struct udev_device *udev_device_new_from_devnum(struct udev *udev, char type, dev_t devnum);
        $ffi->attach('udev_device_new_from_devnum' => ['opaque', 'signed char', 'uint64_t'] => 'opaque');

        # struct udev_device *udev_device_new_from_subsystem_sysname(struct udev *udev, const char *subsystem, const char *sysname);
        $ffi->attach('udev_device_new_from_subsystem_sysname' => ['opaque', 'string', 'string'] => 'opaque');

        # libudev >= 189
        # struct udev_device *udev_device_new_from_device_id(struct udev *udev, const char *id);
        $ffi->attach('udev_device_new_from_device_id' => ['opaque', 'string'] => 'opaque');

        # struct udev_device *udev_device_new_from_environment(struct udev *udev);
        $ffi->attach('udev_device_new_from_environment' => ['opaque'] => 'opaque');

        # struct udev_device *udev_device_get_parent(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_parent' => ['opaque'] => 'opaque');

        # struct udev_device *udev_device_get_parent_with_subsystem_devtype(struct udev_device *udev_device,
            # const char *subsystem, const char *devtype);
        $ffi->attach('udev_device_get_parent_with_subsystem_devtype' => ['opaque', 'string', 'string'] => 'opaque');

        # retrieve device properties

        # const char *udev_device_get_devpath(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_devpath'       => ['opaque'] => 'string');

        # const char *udev_device_get_subsystem(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_subsystem'     => ['opaque'] => 'string');

        # const char *udev_device_get_devtype(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_devtype'       => ['opaque'] => 'string');

        # const char *udev_device_get_syspath(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_syspath'       => ['opaque'] => 'string');

        # const char *udev_device_get_sysname(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_sysname'        => ['opaque'] => 'string');

        # const char *udev_device_get_sysnum(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_sysnum'         => ['opaque'] => 'string');

        # const char *udev_device_get_devnode(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_devnode'        => ['opaque'] => 'string');

        #int udev_device_get_is_initialized(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_is_initialized' => ['opaque'] => 'int');

        # struct udev_list_entry *udev_device_get_devlinks_list_entry(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_devlinks_list_entry'   => ['opaque'] => 'opaque');

        # struct udev_list_entry *udev_device_get_properties_list_entry(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_properties_list_entry' => ['opaque'] => 'opaque');

        # struct udev_list_entry *udev_device_get_tags_list_entry(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_tags_list_entry'       => ['opaque'] => 'opaque');

        # struct udev_list_entry *udev_device_get_sysattr_list_entry(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_sysattr_list_entry'    => ['opaque'] => 'opaque');

        #const char *udev_device_get_property_value(struct udev_device *udev_device, const char *key);
        $ffi->attach('udev_device_get_property_value' => ['opaque', 'string'] => 'string');

        #const char *udev_device_get_driver(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_driver' => ['opaque'] => 'string');

        # dev_t udev_device_get_devnum(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_devnum' => ['opaque'] => 'uint64_t');

        #const char *udev_device_get_action(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_action' => ['opaque'] => 'string');

        #unsigned long long int udev_device_get_seqnum(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_seqnum' => ['opaque'] => 'unsigned long long');

        #unsigned long long int udev_device_get_usec_since_initialized(struct udev_device *udev_device);
        $ffi->attach('udev_device_get_usec_since_initialized' => ['opaque'] => 'unsigned long long');

        #const char *udev_device_get_sysattr_value(struct udev_device *udev_device, const char *sysattr);
        $ffi->attach('udev_device_get_sysattr_value' => ['opaque', 'string'] => 'string');

        #int udev_device_set_sysattr_value(struct udev_device *udev_device, const char *sysattr, char *value);
        $ffi->attach('udev_device_set_sysattr_value' => ['opaque', 'string', 'string'] => 'int');

        #int udev_device_has_tag(struct udev_device *udev_device, const char *tag);
        $ffi->attach('udev_device_has_tag' => ['opaque', 'string'] => 'int');


        # udev_monitor =========================================================

        # access to kernel uevents and udev events

        # struct udev_monitor *udev_monitor_ref(struct udev_monitor *udev_monitor);
        $ffi->attach('udev_monitor_ref'              => ['opaque'] => 'opaque');

        # struct udev_monitor *udev_monitor_unref(struct udev_monitor *udev_monitor);
        $ffi->attach('udev_monitor_unref'            => ['opaque'] => 'opaque');

        # struct udev *udev_monitor_get_udev(struct udev_monitor *udev_monitor);
        $ffi->attach('udev_monitor_get_udev'         => ['opaque'] => 'opaque');

        #kernel and udev generated events over netlink

        # struct udev_monitor *udev_monitor_new_from_netlink(struct udev *udev, const char *name);
        $ffi->attach('udev_monitor_new_from_netlink' => ['opaque', 'string'] => 'opaque');

        # bind socket

        # int udev_monitor_enable_receiving(struct udev_monitor *udev_monitor);
        $ffi->attach('udev_monitor_enable_receiving'        => ['opaque'] => 'int');

        # int udev_monitor_set_receive_buffer_size(struct udev_monitor *udev_monitor, int size);
        $ffi->attach('udev_monitor_set_receive_buffer_size' => ['opaque', 'int'] => 'int');

        # int udev_monitor_get_fd(struct udev_monitor *udev_monitor);
        $ffi->attach('udev_monitor_get_fd'                  => ['opaque'] => 'int');

        # struct udev_device *udev_monitor_receive_device(struct udev_monitor *udev_monitor);
        $ffi->attach('udev_monitor_receive_device'          => ['opaque'] => 'opaque');

        # n-kernel socket filters to select messages that get delivered to a listener

        # int udev_monitor_filter_add_match_subsystem_devtype(struct udev_monitor *udev_monitor,
        #     const char *subsystem, const char *devtype);
        $ffi->attach('udev_monitor_filter_add_match_subsystem_devtype' => ['opaque', 'string', 'string'] => 'int');

        # int udev_monitor_filter_add_match_tag(struct udev_monitor *udev_monitor, const char *tag);
        $ffi->attach('udev_monitor_filter_add_match_tag'               => ['opaque', 'string'] => 'int');

        # int udev_monitor_filter_update(struct udev_monitor *udev_monitor);
        $ffi->attach('udev_monitor_filter_update'                      => ['opaque'] => 'int');

        # int udev_monitor_filter_remove(struct udev_monitor *udev_monitor);
        $ffi->attach('udev_monitor_filter_remove'                      => ['opaque'] => 'int');


        # udev_enumerate =======================================================

        # search sysfs for specific devices and provide a sorted list

        # struct udev_enumerate *udev_enumerate_ref(struct udev_enumerate *udev_enumerate);
        $ffi->attach('udev_enumerate_ref'      => ['opaque'] => 'opaque');

        # struct udev_enumerate *udev_enumerate_unref(struct udev_enumerate *udev_enumerate);
        $ffi->attach('udev_enumerate_unref'    => ['opaque'] => 'opaque');

        # struct udev *udev_enumerate_get_udev(struct udev_enumerate *udev_enumerate);
        $ffi->attach('udev_enumerate_get_udev' => ['opaque'] => 'opaque');

        # struct udev_enumerate *udev_enumerate_new(struct udev *udev);
        $ffi->attach('udev_enumerate_new'      => ['opaque'] => 'opaque');

        # device properties filter */

        # int udev_enumerate_add_match_subsystem(struct udev_enumerate *udev_enumerate, const char *subsystem);
        $ffi->attach('udev_enumerate_add_match_subsystem'      => ['opaque', 'string'] => 'int');

        # int udev_enumerate_add_nomatch_subsystem(struct udev_enumerate *udev_enumerate, const char *subsystem);
        $ffi->attach('udev_enumerate_add_nomatch_subsystem'    => ['opaque', 'string'] => 'int');

        # int udev_enumerate_add_match_sysattr(struct udev_enumerate *udev_enumerate, const char *sysattr, const char *value);
        $ffi->attach('udev_enumerate_add_match_sysattr'        => ['opaque', 'string', 'string'] => 'int');

        # int udev_enumerate_add_nomatch_sysattr(struct udev_enumerate *udev_enumerate, const char *sysattr, const char *value);
        $ffi->attach('udev_enumerate_add_nomatch_sysattr'      => ['opaque', 'string', 'string'] => 'int');

        # int udev_enumerate_add_match_property(struct udev_enumerate *udev_enumerate, const char *property, const char *value);
        $ffi->attach('udev_enumerate_add_match_property'       => ['opaque', 'string', 'string'] => 'int');

        # int udev_enumerate_add_match_sysname(struct udev_enumerate *udev_enumerate, const char *sysname);
        $ffi->attach('udev_enumerate_add_match_sysname'        => ['opaque', 'string'] => 'int');

        # int udev_enumerate_add_match_tag(struct udev_enumerate *udev_enumerate, const char *tag);
        $ffi->attach('udev_enumerate_add_match_tag'            => ['opaque', 'string'] => 'int');

        # int udev_enumerate_add_match_parent(struct udev_enumerate *udev_enumerate, struct udev_device *parent);
        $ffi->attach('udev_enumerate_add_match_parent'         => ['opaque', 'opaque'] => 'int');

        # int udev_enumerate_add_match_is_initialized(struct udev_enumerate *udev_enumerate);
        $ffi->attach('udev_enumerate_add_match_is_initialized' => ['opaque'] => 'int');

        # int udev_enumerate_add_syspath(struct udev_enumerate *udev_enumerate, const char *syspath);
        $ffi->attach('udev_enumerate_add_syspath'              => ['opaque', 'string'] => 'int');

        # run enumeration with active filters */

        # int udev_enumerate_scan_devices(struct udev_enumerate *udev_enumerate);
        $ffi->attach('udev_enumerate_scan_devices'    => ['opaque'] => 'int');

        # int udev_enumerate_scan_subsystems(struct udev_enumerate *udev_enumerate);
        $ffi->attach('udev_enumerate_scan_subsystems' => ['opaque'] => 'int');

        # return device list */

        # struct udev_list_entry *udev_enumerate_get_list_entry(struct udev_enumerate *udev_enumerate);
        $ffi->attach('udev_enumerate_get_list_entry' => ['opaque'] => 'opaque');

    }

    return 1;
}



1;