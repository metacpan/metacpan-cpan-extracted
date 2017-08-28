use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $libs = $ENV{USB_LIBUSB_LIB};
if (not defined $libs) {
    $libs = `pkg-config --libs libusb-1.0`;
}

my $inc = $ENV{USB_LIBUSB_INCLUDE};
if (not defined $inc) {
    $inc = `pkg-config --cflags-only-I libusb-1.0`;
}

if (not defined $libs or not defined $inc) {
    die <<"EOF"
Did not find include or library path for libusb 1.0.
See section INSTALLATION in the module documentation.
EOF
        
}

WriteMakefile(
    NAME              => 'USB::LibUSB',
    VERSION_FROM      => 'lib/USB/LibUSB.pm', # finds $VERSION
    MIN_PERL_VERSION => "5.008003",
    PREREQ_PM => {
        "Moo" => 0,
        "AutoLoader" => 0,
        "Carp" => 0,
        "Exporter" => 0,
        "XSLoader" => 0,
        "strict" => 0,
        "warnings" => 0
    },
    TEST_REQUIRES => {
        "Test::More" => 0
    },
    ABSTRACT_FROM     => 'lib/USB/LibUSB.pm', # retrieve abstract from module
    AUTHOR            =>
    'Simon Reinhardt <simon.reinhardt@stud.uni-regensburg.de>',
    LICENSE           => 'perl',
    LIBS              => [$libs], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => $inc, # e.g., '-I. -I/usr/include/other'
    CCFLAGS           => '-Wall -std=gnu99',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage => 'http://www.labmeasurement.de',
            repository => {
                type => 'git',
                url => 'git://github.com/lab-measurement/USB-LibUSB.git',
                web => 'https://github.com/lab-measurement/USB-LibUSB',
            },
            x_MailingList => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-measurement-users',
            x_IRC => 'irc://chat.freenode.net/#labmeasurement',
        }
    }
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(LIBUSBX_API_VERSION LIBUSB_API_VERSION
		 LIBUSB_BT_CONTAINER_ID_SIZE
		 LIBUSB_BT_SS_USB_DEVICE_CAPABILITY_SIZE
		 LIBUSB_BT_USB_2_0_EXTENSION_SIZE
		 LIBUSB_CONTROL_SETUP_SIZE LIBUSB_DT_BOS_MAX_SIZE
		 LIBUSB_DT_BOS_SIZE LIBUSB_DT_CONFIG_SIZE
		 LIBUSB_DT_DEVICE_CAPABILITY_SIZE LIBUSB_DT_DEVICE_SIZE
		 LIBUSB_DT_ENDPOINT_AUDIO_SIZE LIBUSB_DT_ENDPOINT_SIZE
		 LIBUSB_DT_HUB_NONVAR_SIZE LIBUSB_DT_INTERFACE_SIZE
		 LIBUSB_DT_SS_ENDPOINT_COMPANION_SIZE
		 LIBUSB_ENDPOINT_ADDRESS_MASK LIBUSB_ENDPOINT_DIR_MASK
		 LIBUSB_ERROR_COUNT LIBUSB_HOTPLUG_MATCH_ANY
		 LIBUSB_ISO_SYNC_TYPE_MASK LIBUSB_ISO_USAGE_TYPE_MASK
		 LIBUSB_TRANSFER_TYPE_MASK),
              {name=>"LIBUSB_BM_LPM_SUPPORT", macro=>"1"},
              {name=>"LIBUSB_BM_LTM_SUPPORT", macro=>"1"},
              {name=>"LIBUSB_BT_CONTAINER_ID", macro=>"1"},
              {name=>"LIBUSB_BT_SS_USB_DEVICE_CAPABILITY", macro=>"1"},
              {name=>"LIBUSB_BT_USB_2_0_EXTENSION", macro=>"1"},
              {name=>"LIBUSB_BT_WIRELESS_USB_DEVICE_CAPABILITY", macro=>"1"},
              {name=>"LIBUSB_CAP_HAS_CAPABILITY", macro=>"1"},
              {name=>"LIBUSB_CAP_HAS_HID_ACCESS", macro=>"1"},
              {name=>"LIBUSB_CAP_HAS_HOTPLUG", macro=>"1"},
              {name=>"LIBUSB_CAP_SUPPORTS_DETACH_KERNEL_DRIVER", macro=>"1"},
              {name=>"LIBUSB_CLASS_APPLICATION", macro=>"1"},
              {name=>"LIBUSB_CLASS_AUDIO", macro=>"1"},
              {name=>"LIBUSB_CLASS_COMM", macro=>"1"},
              {name=>"LIBUSB_CLASS_CONTENT_SECURITY", macro=>"1"},
              {name=>"LIBUSB_CLASS_DATA", macro=>"1"},
              {name=>"LIBUSB_CLASS_DIAGNOSTIC_DEVICE", macro=>"1"},
              {name=>"LIBUSB_CLASS_HID", macro=>"1"},
              {name=>"LIBUSB_CLASS_HUB", macro=>"1"},
              {name=>"LIBUSB_CLASS_IMAGE", macro=>"1"},
              {name=>"LIBUSB_CLASS_MASS_STORAGE", macro=>"1"},
              {name=>"LIBUSB_CLASS_PERSONAL_HEALTHCARE", macro=>"1"},
              {name=>"LIBUSB_CLASS_PER_INTERFACE", macro=>"1"},
              {name=>"LIBUSB_CLASS_PHYSICAL", macro=>"1"},
              {name=>"LIBUSB_CLASS_PRINTER", macro=>"1"},
              {name=>"LIBUSB_CLASS_PTP", macro=>"1"},
              {name=>"LIBUSB_CLASS_SMART_CARD", macro=>"1"},
              {name=>"LIBUSB_CLASS_VENDOR_SPEC", macro=>"1"},
              {name=>"LIBUSB_CLASS_VIDEO", macro=>"1"},
              {name=>"LIBUSB_CLASS_WIRELESS", macro=>"1"},
              {name=>"LIBUSB_DT_BOS", macro=>"1"},
              {name=>"LIBUSB_DT_CONFIG", macro=>"1"},
              {name=>"LIBUSB_DT_DEVICE", macro=>"1"},
              {name=>"LIBUSB_DT_DEVICE_CAPABILITY", macro=>"1"},
              {name=>"LIBUSB_DT_ENDPOINT", macro=>"1"},
              {name=>"LIBUSB_DT_HID", macro=>"1"},
              {name=>"LIBUSB_DT_HUB", macro=>"1"},
              {name=>"LIBUSB_DT_INTERFACE", macro=>"1"},
              {name=>"LIBUSB_DT_PHYSICAL", macro=>"1"},
              {name=>"LIBUSB_DT_REPORT", macro=>"1"},
              {name=>"LIBUSB_DT_SS_ENDPOINT_COMPANION", macro=>"1"},
              {name=>"LIBUSB_DT_STRING", macro=>"1"},
              {name=>"LIBUSB_DT_SUPERSPEED_HUB", macro=>"1"},
              {name=>"LIBUSB_ENDPOINT_IN", macro=>"1"},
              {name=>"LIBUSB_ENDPOINT_OUT", macro=>"1"},
              {name=>"LIBUSB_ERROR_ACCESS", macro=>"1"},
              {name=>"LIBUSB_ERROR_BUSY", macro=>"1"},
              {name=>"LIBUSB_ERROR_INTERRUPTED", macro=>"1"},
              {name=>"LIBUSB_ERROR_INVALID_PARAM", macro=>"1"},
              {name=>"LIBUSB_ERROR_IO", macro=>"1"},
              {name=>"LIBUSB_ERROR_NOT_FOUND", macro=>"1"},
              {name=>"LIBUSB_ERROR_NOT_SUPPORTED", macro=>"1"},
              {name=>"LIBUSB_ERROR_NO_DEVICE", macro=>"1"},
              {name=>"LIBUSB_ERROR_NO_MEM", macro=>"1"},
              {name=>"LIBUSB_ERROR_OTHER", macro=>"1"},
              {name=>"LIBUSB_ERROR_OVERFLOW", macro=>"1"},
              {name=>"LIBUSB_ERROR_PIPE", macro=>"1"},
              {name=>"LIBUSB_ERROR_TIMEOUT", macro=>"1"},
              {name=>"LIBUSB_FULL_SPEED_OPERATION", macro=>"1"},
              {name=>"LIBUSB_HIGH_SPEED_OPERATION", macro=>"1"},
              {name=>"LIBUSB_HOTPLUG_ENUMERATE", macro=>"1"},
              {name=>"LIBUSB_HOTPLUG_EVENT_DEVICE_ARRIVED", macro=>"1"},
              {name=>"LIBUSB_HOTPLUG_EVENT_DEVICE_LEFT", macro=>"1"},
              {name=>"LIBUSB_ISO_SYNC_TYPE_ADAPTIVE", macro=>"1"},
              {name=>"LIBUSB_ISO_SYNC_TYPE_ASYNC", macro=>"1"},
              {name=>"LIBUSB_ISO_SYNC_TYPE_NONE", macro=>"1"},
              {name=>"LIBUSB_ISO_SYNC_TYPE_SYNC", macro=>"1"},
              {name=>"LIBUSB_ISO_USAGE_TYPE_DATA", macro=>"1"},
              {name=>"LIBUSB_ISO_USAGE_TYPE_FEEDBACK", macro=>"1"},
              {name=>"LIBUSB_ISO_USAGE_TYPE_IMPLICIT", macro=>"1"},
              {name=>"LIBUSB_LOG_LEVEL_DEBUG", macro=>"1"},
              {name=>"LIBUSB_LOG_LEVEL_ERROR", macro=>"1"},
              {name=>"LIBUSB_LOG_LEVEL_INFO", macro=>"1"},
              {name=>"LIBUSB_LOG_LEVEL_NONE", macro=>"1"},
              {name=>"LIBUSB_LOG_LEVEL_WARNING", macro=>"1"},
              {name=>"LIBUSB_LOW_SPEED_OPERATION", macro=>"1"},
              {name=>"LIBUSB_RECIPIENT_DEVICE", macro=>"1"},
              {name=>"LIBUSB_RECIPIENT_ENDPOINT", macro=>"1"},
              {name=>"LIBUSB_RECIPIENT_INTERFACE", macro=>"1"},
              {name=>"LIBUSB_RECIPIENT_OTHER", macro=>"1"},
              {name=>"LIBUSB_REQUEST_CLEAR_FEATURE", macro=>"1"},
              {name=>"LIBUSB_REQUEST_GET_CONFIGURATION", macro=>"1"},
              {name=>"LIBUSB_REQUEST_GET_DESCRIPTOR", macro=>"1"},
              {name=>"LIBUSB_REQUEST_GET_INTERFACE", macro=>"1"},
              {name=>"LIBUSB_REQUEST_GET_STATUS", macro=>"1"},
              {name=>"LIBUSB_REQUEST_SET_ADDRESS", macro=>"1"},
              {name=>"LIBUSB_REQUEST_SET_CONFIGURATION", macro=>"1"},
              {name=>"LIBUSB_REQUEST_SET_DESCRIPTOR", macro=>"1"},
              {name=>"LIBUSB_REQUEST_SET_FEATURE", macro=>"1"},
              {name=>"LIBUSB_REQUEST_SET_INTERFACE", macro=>"1"},
              {name=>"LIBUSB_REQUEST_SET_SEL", macro=>"1"},
              {name=>"LIBUSB_REQUEST_SYNCH_FRAME", macro=>"1"},
              {name=>"LIBUSB_REQUEST_TYPE_CLASS", macro=>"1"},
              {name=>"LIBUSB_REQUEST_TYPE_RESERVED", macro=>"1"},
              {name=>"LIBUSB_REQUEST_TYPE_STANDARD", macro=>"1"},
              {name=>"LIBUSB_REQUEST_TYPE_VENDOR", macro=>"1"},
              {name=>"LIBUSB_SET_ISOCH_DELAY", macro=>"1"},
              {name=>"LIBUSB_SPEED_FULL", macro=>"1"},
              {name=>"LIBUSB_SPEED_HIGH", macro=>"1"},
              {name=>"LIBUSB_SPEED_LOW", macro=>"1"},
              {name=>"LIBUSB_SPEED_SUPER", macro=>"1"},
              {name=>"LIBUSB_SPEED_UNKNOWN", macro=>"1"},
              {name=>"LIBUSB_SUCCESS", macro=>"1"},
              {name=>"LIBUSB_SUPER_SPEED_OPERATION", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_ADD_ZERO_PACKET", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_CANCELLED", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_COMPLETED", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_ERROR", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_FREE_BUFFER", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_FREE_TRANSFER", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_NO_DEVICE", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_OVERFLOW", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_SHORT_NOT_OK", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_STALL", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_TIMED_OUT", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_TYPE_BULK", macro=>"1"},
               # added in 1.0.19
               # {name=>"LIBUSB_TRANSFER_TYPE_BULK_STREAM", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_TYPE_CONTROL", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_TYPE_INTERRUPT", macro=>"1"},
              {name=>"LIBUSB_TRANSFER_TYPE_ISOCHRONOUS", macro=>"1"});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'USB::LibUSB::XS',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
