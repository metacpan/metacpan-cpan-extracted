package Win32::MultiMedia::Mci::Consts;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

my %consts =
(
   BASE => [ qw (
      MM_MCINOTIFY MM_MCISIGNAL MCIERR_BASE MCI_STRING_OFFSET MCI_VD_OFFSET MCI_CD_OFFSET 
      MCI_WAVE_OFFSET MCI_SEQ_OFFSET 
   ) ],

   ERRORS => [ qw (
      MCIERR_INVALID_DEVICE_ID MCIERR_UNRECOGNIZED_KEYWORD MCIERR_UNRECOGNIZED_COMMAND MCIERR_HARDWARE 
      MCIERR_INVALID_DEVICE_NAME MCIERR_OUT_OF_MEMORY MCIERR_DEVICE_OPEN MCIERR_CANNOT_LOAD_DRIVER 
      MCIERR_MISSING_COMMAND_STRING MCIERR_PARAM_OVERFLOW MCIERR_MISSING_STRING_ARGUMENT MCIERR_BAD_INTEGER 
      MCIERR_PARSER_INTERNAL MCIERR_DRIVER_INTERNAL MCIERR_MISSING_PARAMETER MCIERR_UNSUPPORTED_FUNCTION 
      MCIERR_FILE_NOT_FOUND MCIERR_DEVICE_NOT_READY MCIERR_INTERNAL MCIERR_DRIVER MCIERR_CANNOT_USE_ALL 
      MCIERR_MULTIPLE MCIERR_EXTENSION_NOT_FOUND MCIERR_OUTOFRANGE MCIERR_FLAGS_NOT_COMPATIBLE MCIERR_FILE_NOT_SAVED 
      MCIERR_DEVICE_TYPE_REQUIRED MCIERR_DEVICE_LOCKED MCIERR_DUPLICATE_ALIAS MCIERR_BAD_CONSTANT 
      MCIERR_MUST_USE_SHAREABLE MCIERR_MISSING_DEVICE_NAME MCIERR_BAD_TIME_FORMAT MCIERR_NO_CLOSING_QUOTE 
      MCIERR_DUPLICATE_FLAGS MCIERR_INVALID_FILE MCIERR_NULL_PARAMETER_BLOCK MCIERR_UNNAMED_RESOURCE 
      MCIERR_NEW_REQUIRES_ALIAS MCIERR_NOTIFY_ON_AUTO_OPEN MCIERR_NO_ELEMENT_ALLOWED MCIERR_NONAPPLICABLE_FUNCTION 
      MCIERR_ILLEGAL_FOR_AUTO_OPEN MCIERR_FILENAME_REQUIRED MCIERR_EXTRA_CHARACTERS MCIERR_DEVICE_NOT_INSTALLED 
      MCIERR_GET_CD MCIERR_SET_CD MCIERR_SET_DRIVE MCIERR_DEVICE_LENGTH MCIERR_DEVICE_ORD_LENGTH MCIERR_NO_INTEGER 
      MCIERR_WAVE_OUTPUTSINUSE MCIERR_WAVE_SETOUTPUTINUSE MCIERR_WAVE_INPUTSINUSE MCIERR_WAVE_SETINPUTINUSE 
      MCIERR_WAVE_OUTPUTUNSPECIFIED MCIERR_WAVE_INPUTUNSPECIFIED MCIERR_WAVE_OUTPUTSUNSUITABLE 
      MCIERR_WAVE_SETOUTPUTUNSUITABLE MCIERR_WAVE_INPUTSUNSUITABLE MCIERR_WAVE_SETINPUTUNSUITABLE 
      MCIERR_SEQ_DIV_INCOMPATIBLE MCIERR_SEQ_PORT_INUSE MCIERR_SEQ_PORT_NONEXISTENT MCIERR_SEQ_PORT_MAPNODEVICE 
      MCIERR_SEQ_PORT_MISCERROR MCIERR_SEQ_TIMER MCIERR_SEQ_PORTUNSPECIFIED MCIERR_SEQ_NOMIDIPRESENT 
      MCIERR_NO_WINDOW MCIERR_CREATEWINDOW MCIERR_FILE_READ MCIERR_FILE_WRITE MCIERR_NO_IDENTITY 
      MCIERR_CUSTOM_DRIVER_BASE 
   ) ],
   
   MESSAGES => [ qw(
      MCI_OPEN MCI_CLOSE MCI_ESCAPE MCI_PLAY MCI_SEEK MCI_STOP MCI_PAUSE MCI_INFO MCI_GETDEVCAPS MCI_SPIN MCI_SET 
      MCI_STEP MCI_RECORD MCI_SYSINFO MCI_BREAK MCI_SAVE MCI_STATUS MCI_CUE MCI_REALIZE MCI_WINDOW MCI_PUT 
      MCI_WHERE MCI_FREEZE MCI_UNFREEZE MCI_LOAD MCI_CUT MCI_COPY MCI_PASTE MCI_UPDATE MCI_RESUME MCI_DELETE 
   ) ],
   
   DEVICES => [ qw (
      MCI_ALL_DEVICE_ID MCI_DEVTYPE_VCR MCI_DEVTYPE_VIDEODISC MCI_DEVTYPE_OVERLAY MCI_DEVTYPE_CD_AUDIO 
      MCI_DEVTYPE_DAT MCI_DEVTYPE_SCANNER MCI_DEVTYPE_ANIMATION MCI_DEVTYPE_DIGITAL_VIDEO MCI_DEVTYPE_OTHER 
      MCI_DEVTYPE_WAVEFORM_AUDIO MCI_DEVTYPE_SEQUENCER MCI_DEVTYPE_FIRST_USER 
   ) ],
   
   #return values for 'status mode' command
   SMODE => [ qw(
      MCI_MODE_NOT_READY MCI_MODE_STOP MCI_MODE_PLAY MCI_MODE_RECORD MCI_MODE_SEEK MCI_MODE_PAUSE MCI_MODE_OPEN 
   )],

   #time formats
   TIMEFORMATS => [ qw(
      MCI_FORMAT_MILLISECONDS MCI_FORMAT_HMS MCI_FORMAT_MSF MCI_FORMAT_FRAMES MCI_FORMAT_SMPTE_24 
      MCI_FORMAT_SMPTE_25 MCI_FORMAT_SMPTE_30 MCI_FORMAT_SMPTE_30DROP MCI_FORMAT_BYTES MCI_FORMAT_SAMPLES 
      MCI_FORMAT_TMSF MCI_NOTIFY_SUCCESSFUL MCI_NOTIFY_SUPERSEDED MCI_NOTIFY_ABORTED MCI_NOTIFY_FAILURE 
      MCI_NOTIFY MCI_WAIT MCI_FROM MCI_TO MCI_TRACK 
   )],

   #open flags
   OPENFLAGS => [ qw(
      MCI_OPEN_SHAREABLE MCI_OPEN_ELEMENT MCI_OPEN_ALIAS MCI_OPEN_ELEMENT_ID MCI_OPEN_TYPE_ID MCI_OPEN_TYPE 
   )],

   #seek flags
   SEEKFLAGS => [ qw (
      MCI_SEEK_TO_START MCI_SEEK_TO_END 
   )],

   #status flags
   STATUS => [qw (
      MCI_STATUS_ITEM MCI_STATUS_START MCI_STATUS_LENGTH MCI_STATUS_POSITION MCI_STATUS_NUMBER_OF_TRACKS MCI_STATUS_MODE 
      MCI_STATUS_MEDIA_PRESENT MCI_STATUS_TIME_FORMAT MCI_STATUS_READY MCI_STATUS_CURRENT_TRACK MCI_INFO_PRODUCT 
      MCI_INFO_FILE MCI_INFO_MEDIA_UPC MCI_INFO_MEDIA_IDENTITY MCI_INFO_NAME MCI_INFO_COPYRIGHT MCI_GETDEVCAPS_ITEM 
      MCI_GETDEVCAPS_CAN_RECORD MCI_GETDEVCAPS_HAS_AUDIO MCI_GETDEVCAPS_HAS_VIDEO MCI_GETDEVCAPS_DEVICE_TYPE 
      MCI_GETDEVCAPS_USES_FILES MCI_GETDEVCAPS_COMPOUND_DEVICE MCI_GETDEVCAPS_CAN_EJECT MCI_GETDEVCAPS_CAN_PLAY 
      MCI_GETDEVCAPS_CAN_SAVE MCI_SYSINFO_QUANTITY MCI_SYSINFO_OPEN MCI_SYSINFO_NAME MCI_SYSINFO_INSTALLNAME 
   )],

   #set flags
   SETFLAGS => [ qw(
      MCI_SET_DOOR_OPEN MCI_SET_DOOR_CLOSED MCI_SET_TIME_FORMAT MCI_SET_AUDIO MCI_SET_VIDEO MCI_SET_ON MCI_SET_OFF 
      MCI_SET_AUDIO_ALL MCI_SET_AUDIO_LEFT MCI_SET_AUDIO_RIGHT MCI_BREAK_KEY MCI_BREAK_HWND MCI_BREAK_OFF 
      MCI_RECORD_INSERT MCI_RECORD_OVERWRITE MCI_SAVE_FILE MCI_LOAD_FILE 
   )],

   #videodisc
   VDISCFLAGS => [ qw(
      MCI_VD_MODE_PARK MCI_VD_MEDIA_CLV MCI_VD_MEDIA_CAV MCI_VD_MEDIA_OTHER MCI_VD_FORMAT_TRACK MCI_VD_PLAY_REVERSE 
      MCI_VD_PLAY_FAST MCI_VD_PLAY_SPEED MCI_VD_PLAY_SCAN MCI_VD_PLAY_SLOW MCI_VD_SEEK_REVERSE MCI_VD_STATUS_SPEED 
      MCI_VD_STATUS_FORWARD MCI_VD_STATUS_MEDIA_TYPE MCI_VD_STATUS_SIDE MCI_VD_STATUS_DISC_SIZE MCI_VD_GETDEVCAPS_CLV 
      MCI_VD_GETDEVCAPS_CAV MCI_VD_SPIN_UP MCI_VD_SPIN_DOWN MCI_VD_GETDEVCAPS_CAN_REVERSE MCI_VD_GETDEVCAPS_FAST_RATE 
      MCI_VD_GETDEVCAPS_SLOW_RATE MCI_VD_GETDEVCAPS_NORMAL_RATE MCI_VD_STEP_FRAMES MCI_VD_STEP_REVERSE MCI_VD_ESCAPE_STRING 
   )],

   #cd flags
   CDFLAGS => [ qw (
      MCI_CDA_STATUS_TYPE_TRACK MCI_CDA_TRACK_AUDIO MCI_CDA_TRACK_OTHER 
   )],

   #wave
   WAVEFLAGS => [ qw (
      MCI_WAVE_PCM MCI_WAVE_MAPPER MCI_WAVE_OPEN_BUFFER MCI_WAVE_SET_FORMATTAG MCI_WAVE_SET_CHANNELS 
      MCI_WAVE_SET_SAMPLESPERSEC MCI_WAVE_SET_AVGBYTESPERSEC MCI_WAVE_SET_BLOCKALIGN MCI_WAVE_SET_BITSPERSAMPLE 
      MCI_WAVE_INPUT MCI_WAVE_OUTPUT MCI_WAVE_STATUS_FORMATTAG MCI_WAVE_STATUS_CHANNELS MCI_WAVE_STATUS_SAMPLESPERSEC 
      MCI_WAVE_STATUS_AVGBYTESPERSEC MCI_WAVE_STATUS_BLOCKALIGN MCI_WAVE_STATUS_BITSPERSAMPLE MCI_WAVE_STATUS_LEVEL 
      MCI_WAVE_SET_ANYINPUT MCI_WAVE_SET_ANYOUTPUT MCI_WAVE_GETDEVCAPS_INPUTS MCI_WAVE_GETDEVCAPS_OUTPUTS 
   )],

   #sequencer (MIDI)
   SEQFLAGS => [qw (
      MCI_SEQ_DIV_PPQN MCI_SEQ_DIV_SMPTE_24 MCI_SEQ_DIV_SMPTE_25 MCI_SEQ_DIV_SMPTE_30DROP MCI_SEQ_DIV_SMPTE_30 
      MCI_SEQ_FORMAT_SONGPTR MCI_SEQ_FILE MCI_SEQ_MIDI MCI_SEQ_SMPTE MCI_SEQ_NONE MCI_SEQ_MAPPER MCI_SEQ_STATUS_TEMPO 
      MCI_SEQ_STATUS_PORT MCI_SEQ_STATUS_SLAVE MCI_SEQ_STATUS_MASTER MCI_SEQ_STATUS_OFFSET MCI_SEQ_STATUS_DIVTYPE 
      MCI_SEQ_STATUS_NAME MCI_SEQ_STATUS_COPYRIGHT MCI_SEQ_SET_TEMPO MCI_SEQ_SET_PORT MCI_SEQ_SET_SLAVE MCI_SEQ_SET_MASTER 
      MCI_SEQ_SET_OFFSET MCI_ANIM_OPEN_WS MCI_ANIM_OPEN_PARENT MCI_ANIM_OPEN_NOSTATIC MCI_ANIM_PLAY_SPEED 
      MCI_ANIM_PLAY_REVERSE MCI_ANIM_PLAY_FAST MCI_ANIM_PLAY_SLOW MCI_ANIM_PLAY_SCAN MCI_ANIM_STEP_REVERSE
      MCI_ANIM_STEP_FRAMES MCI_ANIM_STATUS_SPEED MCI_ANIM_STATUS_FORWARD MCI_ANIM_STATUS_HWND MCI_ANIM_STATUS_HPAL 
      MCI_ANIM_STATUS_STRETCH MCI_ANIM_INFO_TEXT MCI_ANIM_GETDEVCAPS_CAN_REVERSE MCI_ANIM_GETDEVCAPS_FAST_RATE 
      MCI_ANIM_GETDEVCAPS_SLOW_RATE MCI_ANIM_GETDEVCAPS_NORMAL_RATE MCI_ANIM_GETDEVCAPS_PALETTES 
      MCI_ANIM_GETDEVCAPS_CAN_STRETCH MCI_ANIM_GETDEVCAPS_MAX_WINDOWS MCI_ANIM_REALIZE_NORM MCI_ANIM_REALIZE_BKGD 
      MCI_ANIM_WINDOW_HWND MCI_ANIM_WINDOW_STATE MCI_ANIM_WINDOW_TEXT MCI_ANIM_WINDOW_ENABLE_STRETCH 
      MCI_ANIM_WINDOW_DISABLE_STRETCH MCI_ANIM_WINDOW_DEFAULT MCI_ANIM_RECT MCI_ANIM_PUT_SOURCE MCI_ANIM_PUT_DESTINATION 
      MCI_ANIM_WHERE_SOURCE MCI_ANIM_WHERE_DESTINATION MCI_ANIM_UPDATE_HDC 
   )],

   #overlay device
   OVERLAYFLAGS => [ qw (
      MCI_OVLY_OPEN_WS MCI_OVLY_OPEN_PARENT MCI_OVLY_STATUS_HWND MCI_OVLY_STATUS_STRETCH MCI_OVLY_INFO_TEXT 
      MCI_OVLY_GETDEVCAPS_CAN_STRETCH MCI_OVLY_GETDEVCAPS_CAN_FREEZE MCI_OVLY_GETDEVCAPS_MAX_WINDOWS 
      MCI_OVLY_WINDOW_HWND MCI_OVLY_WINDOW_STATE MCI_OVLY_WINDOW_TEXT MCI_OVLY_WINDOW_ENABLE_STRETCH 
      MCI_OVLY_WINDOW_DISABLE_STRETCH MCI_OVLY_WINDOW_DEFAULT MCI_OVLY_RECT MCI_OVLY_PUT_SOURCE 
      MCI_OVLY_PUT_DESTINATION MCI_OVLY_PUT_FRAME MCI_OVLY_PUT_VIDEO MCI_OVLY_WHERE_SOURCE MCI_OVLY_WHERE_DESTINATION 
      MCI_OVLY_WHERE_FRAME MCI_OVLY_WHERE_VIDEO 
   )]
);


%EXPORT_TAGS = ( %consts, ALL =>[map( @$_,values(%consts))]);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
   
);
Exporter::export_tags('ERRORS');
Exporter::export_ok_tags(qw (BASE ERRORS MESSAGES DEVICES SMODE 
   TIMEFORMATS OPENFLAGS SEEKFLAGS STATUS SETFLAGS VDISCFLAGS CDFLAGS 
   WAVEFLAGS SEQFLAGS OVERLAYFLAGS) ); 


$VERSION = '0.01';

use strict;

   use constant MM_MCINOTIFY                    => 0x3B9;
   use constant MM_MCISIGNAL                    => 0x3CB;
   use constant MCIERR_BASE                     => 256;
   use constant MCI_STRING_OFFSET               => 512;
   use constant MCI_VD_OFFSET                   => 1024;
   use constant MCI_CD_OFFSET                   => 1088;
   use constant MCI_WAVE_OFFSET                 => 1152;
   use constant MCI_SEQ_OFFSET                  => 1216;

#MCI errors
   use constant MCIERR_INVALID_DEVICE_ID        => (MCIERR_BASE + 1);
   use constant MCIERR_UNRECOGNIZED_KEYWORD     => (MCIERR_BASE + 3);
   use constant MCIERR_UNRECOGNIZED_COMMAND     => (MCIERR_BASE + 5);
   use constant MCIERR_HARDWARE                 => (MCIERR_BASE + 6);
   use constant MCIERR_INVALID_DEVICE_NAME      => (MCIERR_BASE + 7);
   use constant MCIERR_OUT_OF_MEMORY            => (MCIERR_BASE + 8);
   use constant MCIERR_DEVICE_OPEN              => (MCIERR_BASE + 9);
   use constant MCIERR_CANNOT_LOAD_DRIVER       => (MCIERR_BASE + 10);
   use constant MCIERR_MISSING_COMMAND_STRING   => (MCIERR_BASE + 11);
   use constant MCIERR_PARAM_OVERFLOW           => (MCIERR_BASE + 12);
   use constant MCIERR_MISSING_STRING_ARGUMENT  => (MCIERR_BASE + 13);
   use constant MCIERR_BAD_INTEGER              => (MCIERR_BASE + 14);
   use constant MCIERR_PARSER_INTERNAL          => (MCIERR_BASE + 15);
   use constant MCIERR_DRIVER_INTERNAL          => (MCIERR_BASE + 16);
   use constant MCIERR_MISSING_PARAMETER        => (MCIERR_BASE + 17);
   use constant MCIERR_UNSUPPORTED_FUNCTION     => (MCIERR_BASE + 18);
   use constant MCIERR_FILE_NOT_FOUND           => (MCIERR_BASE + 19);
   use constant MCIERR_DEVICE_NOT_READY         => (MCIERR_BASE + 20);
   use constant MCIERR_INTERNAL                 => (MCIERR_BASE + 21);
   use constant MCIERR_DRIVER                   => (MCIERR_BASE + 22);
   use constant MCIERR_CANNOT_USE_ALL           => (MCIERR_BASE + 23);
   use constant MCIERR_MULTIPLE                 => (MCIERR_BASE + 24);
   use constant MCIERR_EXTENSION_NOT_FOUND      => (MCIERR_BASE + 25);
   use constant MCIERR_OUTOFRANGE               => (MCIERR_BASE + 26);
   use constant MCIERR_FLAGS_NOT_COMPATIBLE     => (MCIERR_BASE + 28);
   use constant MCIERR_FILE_NOT_SAVED           => (MCIERR_BASE + 30);
   use constant MCIERR_DEVICE_TYPE_REQUIRED     => (MCIERR_BASE + 31);
   use constant MCIERR_DEVICE_LOCKED            => (MCIERR_BASE + 32);
   use constant MCIERR_DUPLICATE_ALIAS          => (MCIERR_BASE + 33);
   use constant MCIERR_BAD_CONSTANT             => (MCIERR_BASE + 34);
   use constant MCIERR_MUST_USE_SHAREABLE       => (MCIERR_BASE + 35);
   use constant MCIERR_MISSING_DEVICE_NAME      => (MCIERR_BASE + 36);
   use constant MCIERR_BAD_TIME_FORMAT          => (MCIERR_BASE + 37);
   use constant MCIERR_NO_CLOSING_QUOTE         => (MCIERR_BASE + 38);
   use constant MCIERR_DUPLICATE_FLAGS          => (MCIERR_BASE + 39);
   use constant MCIERR_INVALID_FILE             => (MCIERR_BASE + 40);
   use constant MCIERR_NULL_PARAMETER_BLOCK     => (MCIERR_BASE + 41);
   use constant MCIERR_UNNAMED_RESOURCE         => (MCIERR_BASE + 42);
   use constant MCIERR_NEW_REQUIRES_ALIAS       => (MCIERR_BASE + 43);
   use constant MCIERR_NOTIFY_ON_AUTO_OPEN      => (MCIERR_BASE + 44);
   use constant MCIERR_NO_ELEMENT_ALLOWED       => (MCIERR_BASE + 45);
   use constant MCIERR_NONAPPLICABLE_FUNCTION   => (MCIERR_BASE + 46);
   use constant MCIERR_ILLEGAL_FOR_AUTO_OPEN    => (MCIERR_BASE + 47);
   use constant MCIERR_FILENAME_REQUIRED        => (MCIERR_BASE + 48);
   use constant MCIERR_EXTRA_CHARACTERS         => (MCIERR_BASE + 49);
   use constant MCIERR_DEVICE_NOT_INSTALLED     => (MCIERR_BASE + 50);
   use constant MCIERR_GET_CD                   => (MCIERR_BASE + 51);
   use constant MCIERR_SET_CD                   => (MCIERR_BASE + 52);
   use constant MCIERR_SET_DRIVE                => (MCIERR_BASE + 53);
   use constant MCIERR_DEVICE_LENGTH            => (MCIERR_BASE + 54);
   use constant MCIERR_DEVICE_ORD_LENGTH        => (MCIERR_BASE + 55);
   use constant MCIERR_NO_INTEGER               => (MCIERR_BASE + 56);
   use constant MCIERR_WAVE_OUTPUTSINUSE        => (MCIERR_BASE + 64);
   use constant MCIERR_WAVE_SETOUTPUTINUSE      => (MCIERR_BASE + 65);
   use constant MCIERR_WAVE_INPUTSINUSE         => (MCIERR_BASE + 66);
   use constant MCIERR_WAVE_SETINPUTINUSE       => (MCIERR_BASE + 67);
   use constant MCIERR_WAVE_OUTPUTUNSPECIFIED   => (MCIERR_BASE + 68);
   use constant MCIERR_WAVE_INPUTUNSPECIFIED    => (MCIERR_BASE + 69);
   use constant MCIERR_WAVE_OUTPUTSUNSUITABLE   => (MCIERR_BASE + 70);
   use constant MCIERR_WAVE_SETOUTPUTUNSUITABLE => (MCIERR_BASE + 71);
   use constant MCIERR_WAVE_INPUTSUNSUITABLE    => (MCIERR_BASE + 72);
   use constant MCIERR_WAVE_SETINPUTUNSUITABLE  => (MCIERR_BASE + 73);
   use constant MCIERR_SEQ_DIV_INCOMPATIBLE     => (MCIERR_BASE + 80);
   use constant MCIERR_SEQ_PORT_INUSE           => (MCIERR_BASE + 81);
   use constant MCIERR_SEQ_PORT_NONEXISTENT     => (MCIERR_BASE + 82);
   use constant MCIERR_SEQ_PORT_MAPNODEVICE     => (MCIERR_BASE + 83);
   use constant MCIERR_SEQ_PORT_MISCERROR       => (MCIERR_BASE + 84);
   use constant MCIERR_SEQ_TIMER                => (MCIERR_BASE + 85);
   use constant MCIERR_SEQ_PORTUNSPECIFIED      => (MCIERR_BASE + 86);
   use constant MCIERR_SEQ_NOMIDIPRESENT        => (MCIERR_BASE + 87);
   use constant MCIERR_NO_WINDOW                => (MCIERR_BASE + 90);
   use constant MCIERR_CREATEWINDOW             => (MCIERR_BASE + 91);
   use constant MCIERR_FILE_READ                => (MCIERR_BASE + 92);
   use constant MCIERR_FILE_WRITE               => (MCIERR_BASE + 93);
   use constant MCIERR_NO_IDENTITY              => (MCIERR_BASE + 94);
   use constant MCIERR_CUSTOM_DRIVER_BASE       => (MCIERR_BASE + 256);

#MCI messages
   use constant MCI_OPEN                        => 0x0803;
   use constant MCI_CLOSE                       => 0x0804;
   use constant MCI_ESCAPE                      => 0x0805;
   use constant MCI_PLAY                        => 0x0806;
   use constant MCI_SEEK                        => 0x0807;
   use constant MCI_STOP                        => 0x0808;
   use constant MCI_PAUSE                       => 0x0809;
   use constant MCI_INFO                        => 0x080A;
   use constant MCI_GETDEVCAPS                  => 0x080B;
   use constant MCI_SPIN                        => 0x080C;
   use constant MCI_SET                         => 0x080D;
   use constant MCI_STEP                        => 0x080E;
   use constant MCI_RECORD                      => 0x080F;
   use constant MCI_SYSINFO                     => 0x0810;
   use constant MCI_BREAK                       => 0x0811;
   use constant MCI_SAVE                        => 0x0813;
   use constant MCI_STATUS                      => 0x0814;
   use constant MCI_CUE                         => 0x0830;
   use constant MCI_REALIZE                     => 0x0840;
   use constant MCI_WINDOW                      => 0x0841;
   use constant MCI_PUT                         => 0x0842;
   use constant MCI_WHERE                       => 0x0843;
   use constant MCI_FREEZE                      => 0x0844;
   use constant MCI_UNFREEZE                    => 0x0845;
   use constant MCI_LOAD                        => 0x0850;
   use constant MCI_CUT                         => 0x0851;
   use constant MCI_COPY                        => 0x0852;
   use constant MCI_PASTE                       => 0x0853;
   use constant MCI_UPDATE                      => 0x0854;
   use constant MCI_RESUME                      => 0x0855;
   use constant MCI_DELETE                      => 0x0856;

#MCI devices
   use constant MCI_ALL_DEVICE_ID               => ((MCIDEVICEID)-1);
   use constant MCI_DEVTYPE_VCR                 => 513 ;
   use constant MCI_DEVTYPE_VIDEODISC           => 514 ;
   use constant MCI_DEVTYPE_OVERLAY             => 515 ;
   use constant MCI_DEVTYPE_CD_AUDIO            => 516 ;
   use constant MCI_DEVTYPE_DAT                 => 517 ;
   use constant MCI_DEVTYPE_SCANNER             => 518 ;
   use constant MCI_DEVTYPE_ANIMATION           => 519 ;
   use constant MCI_DEVTYPE_DIGITAL_VIDEO       => 520 ;
   use constant MCI_DEVTYPE_OTHER               => 521 ;
   use constant MCI_DEVTYPE_WAVEFORM_AUDIO      => 522 ;
   use constant MCI_DEVTYPE_SEQUENCER           => 523 ;


   use constant MCI_DEVTYPE_FIRST_USER          => 0x1000;

#return values for 'status mode' command
   use constant MCI_MODE_NOT_READY              => (MCI_STRING_OFFSET + 12);
   use constant MCI_MODE_STOP                   => (MCI_STRING_OFFSET + 13);
   use constant MCI_MODE_PLAY                   => (MCI_STRING_OFFSET + 14);
   use constant MCI_MODE_RECORD                 => (MCI_STRING_OFFSET + 15);
   use constant MCI_MODE_SEEK                   => (MCI_STRING_OFFSET + 16);
   use constant MCI_MODE_PAUSE                  => (MCI_STRING_OFFSET + 17);
   use constant MCI_MODE_OPEN                   => (MCI_STRING_OFFSET + 18);

#time formats
   use constant MCI_FORMAT_MILLISECONDS         => 0;
   use constant MCI_FORMAT_HMS                  => 1;
   use constant MCI_FORMAT_MSF                  => 2;
   use constant MCI_FORMAT_FRAMES               => 3;
   use constant MCI_FORMAT_SMPTE_24             => 4;
   use constant MCI_FORMAT_SMPTE_25             => 5;
   use constant MCI_FORMAT_SMPTE_30             => 6;
   use constant MCI_FORMAT_SMPTE_30DROP         => 7;
   use constant MCI_FORMAT_BYTES                => 8;
   use constant MCI_FORMAT_SAMPLES              => 9;
   use constant MCI_FORMAT_TMSF                 => 10;

   use constant MCI_NOTIFY_SUCCESSFUL           => 0x0001;
   use constant MCI_NOTIFY_SUPERSEDED           => 0x0002;
   use constant MCI_NOTIFY_ABORTED              => 0x0004;
   use constant MCI_NOTIFY_FAILURE              => 0x0008;

   use constant MCI_NOTIFY                      => 0x00000001;
   use constant MCI_WAIT                        => 0x00000002;
   use constant MCI_FROM                        => 0x00000004;

   use constant MCI_TO                          => 0x00000008;
   use constant MCI_TRACK                       => 0x00000010;

#open flags
   use constant MCI_OPEN_SHAREABLE              => 0x00000100;
   use constant MCI_OPEN_ELEMENT                => 0x00000200;
   use constant MCI_OPEN_ALIAS                  => 0x00000400;
   use constant MCI_OPEN_ELEMENT_ID             => 0x00000800;
   use constant MCI_OPEN_TYPE_ID                => 0x00001000;
   use constant MCI_OPEN_TYPE                   => 0x00002000;

#seek flags
   use constant MCI_SEEK_TO_START               => 0x00000100;
   use constant MCI_SEEK_TO_END                 => 0x00000200;

#status flags
   use constant MCI_STATUS_ITEM                 => 0x00000100;
   use constant MCI_STATUS_START                => 0x00000200;
   use constant MCI_STATUS_LENGTH               => 0x00000001;
   use constant MCI_STATUS_POSITION             => 0x00000002;
   use constant MCI_STATUS_NUMBER_OF_TRACKS     => 0x00000003;
   use constant MCI_STATUS_MODE                 => 0x00000004;
   use constant MCI_STATUS_MEDIA_PRESENT        => 0x00000005;
   use constant MCI_STATUS_TIME_FORMAT          => 0x00000006;
   use constant MCI_STATUS_READY                => 0x00000007;
   use constant MCI_STATUS_CURRENT_TRACK        => 0x00000008;

   use constant MCI_INFO_PRODUCT                => 0x00000100;
   use constant MCI_INFO_FILE                   => 0x00000200;
   use constant MCI_INFO_MEDIA_UPC              => 0x00000400;
   use constant MCI_INFO_MEDIA_IDENTITY         => 0x00000800;
   use constant MCI_INFO_NAME                   => 0x00001000;
   use constant MCI_INFO_COPYRIGHT              => 0x00002000;
   use constant MCI_GETDEVCAPS_ITEM             => 0x00000100;
   use constant MCI_GETDEVCAPS_CAN_RECORD       => 0x00000001;
   use constant MCI_GETDEVCAPS_HAS_AUDIO        => 0x00000002;
   use constant MCI_GETDEVCAPS_HAS_VIDEO        => 0x00000003;
   use constant MCI_GETDEVCAPS_DEVICE_TYPE      => 0x00000004;
   use constant MCI_GETDEVCAPS_USES_FILES       => 0x00000005;
   use constant MCI_GETDEVCAPS_COMPOUND_DEVICE  => 0x00000006;
   use constant MCI_GETDEVCAPS_CAN_EJECT        => 0x00000007;
   use constant MCI_GETDEVCAPS_CAN_PLAY         => 0x00000008;
   use constant MCI_GETDEVCAPS_CAN_SAVE         => 0x00000009;
   use constant MCI_SYSINFO_QUANTITY            => 0x00000100;
   use constant MCI_SYSINFO_OPEN                => 0x00000200;
   use constant MCI_SYSINFO_NAME                => 0x00000400;
   use constant MCI_SYSINFO_INSTALLNAME         => 0x00000800;

#set flags
   use constant MCI_SET_DOOR_OPEN               => 0x00000100;
   use constant MCI_SET_DOOR_CLOSED             => 0x00000200;
   use constant MCI_SET_TIME_FORMAT             => 0x00000400;
   use constant MCI_SET_AUDIO                   => 0x00000800;
   use constant MCI_SET_VIDEO                   => 0x00001000;
   use constant MCI_SET_ON                      => 0x00002000;
   use constant MCI_SET_OFF                     => 0x00004000;
   use constant MCI_SET_AUDIO_ALL               => 0x00000000;
   use constant MCI_SET_AUDIO_LEFT              => 0x00000001;
   use constant MCI_SET_AUDIO_RIGHT             => 0x00000002;

   use constant MCI_BREAK_KEY                   => 0x00000100;
   use constant MCI_BREAK_HWND                  => 0x00000200;
   use constant MCI_BREAK_OFF                   => 0x00000400;
   use constant MCI_RECORD_INSERT               => 0x00000100;
   use constant MCI_RECORD_OVERWRITE            => 0x00000200;
   use constant MCI_SAVE_FILE                   => 0x00000100;
   use constant MCI_LOAD_FILE                   => 0x00000100;

#videodisc
   use constant MCI_VD_MODE_PARK                => (MCI_VD_OFFSET + 1);
   use constant MCI_VD_MEDIA_CLV                => (MCI_VD_OFFSET + 2);
   use constant MCI_VD_MEDIA_CAV                => (MCI_VD_OFFSET + 3);
   use constant MCI_VD_MEDIA_OTHER              => (MCI_VD_OFFSET + 4);
   use constant MCI_VD_FORMAT_TRACK             => 0x4001;
   use constant MCI_VD_PLAY_REVERSE             => 0x00010000;
   use constant MCI_VD_PLAY_FAST                => 0x00020000;
   use constant MCI_VD_PLAY_SPEED               => 0x00040000;
   use constant MCI_VD_PLAY_SCAN                => 0x00080000;
   use constant MCI_VD_PLAY_SLOW                => 0x00100000;
   use constant MCI_VD_SEEK_REVERSE             => 0x00010000;
   use constant MCI_VD_STATUS_SPEED             => 0x00004002;
   use constant MCI_VD_STATUS_FORWARD           => 0x00004003;
   use constant MCI_VD_STATUS_MEDIA_TYPE        => 0x00004004;
   use constant MCI_VD_STATUS_SIDE              => 0x00004005;
   use constant MCI_VD_STATUS_DISC_SIZE         => 0x00004006;
   use constant MCI_VD_GETDEVCAPS_CLV           => 0x00010000;
   use constant MCI_VD_GETDEVCAPS_CAV           => 0x00020000;
   use constant MCI_VD_SPIN_UP                  => 0x00010000;
   use constant MCI_VD_SPIN_DOWN                => 0x00020000;
   use constant MCI_VD_GETDEVCAPS_CAN_REVERSE   => 0x00004002;
   use constant MCI_VD_GETDEVCAPS_FAST_RATE     => 0x00004003;
   use constant MCI_VD_GETDEVCAPS_SLOW_RATE     => 0x00004004;
   use constant MCI_VD_GETDEVCAPS_NORMAL_RATE   => 0x00004005;
   use constant MCI_VD_STEP_FRAMES              => 0x00010000;
   use constant MCI_VD_STEP_REVERSE             => 0x00020000;
   use constant MCI_VD_ESCAPE_STRING            => 0x00000100;


#cd flags
   use constant MCI_CDA_STATUS_TYPE_TRACK       => 0x00004001;
   use constant MCI_CDA_TRACK_AUDIO             => (MCI_CD_OFFSET + 0);
   use constant MCI_CDA_TRACK_OTHER             => (MCI_CD_OFFSET + 1);

#wave

   use constant MCI_WAVE_PCM                    => (MCI_WAVE_OFFSET + 0);
   use constant MCI_WAVE_MAPPER                 => (MCI_WAVE_OFFSET + 1);
   use constant MCI_WAVE_OPEN_BUFFER            => 0x00010000;
   use constant MCI_WAVE_SET_FORMATTAG          => 0x00010000;
   use constant MCI_WAVE_SET_CHANNELS           => 0x00020000;
   use constant MCI_WAVE_SET_SAMPLESPERSEC      => 0x00040000;
   use constant MCI_WAVE_SET_AVGBYTESPERSEC     => 0x00080000;
   use constant MCI_WAVE_SET_BLOCKALIGN         => 0x00100000;
   use constant MCI_WAVE_SET_BITSPERSAMPLE      => 0x00200000;
   use constant MCI_WAVE_INPUT                  => 0x00400000;
   use constant MCI_WAVE_OUTPUT                 => 0x00800000;
   use constant MCI_WAVE_STATUS_FORMATTAG       => 0x00004001;
   use constant MCI_WAVE_STATUS_CHANNELS        => 0x00004002;
   use constant MCI_WAVE_STATUS_SAMPLESPERSEC   => 0x00004003;
   use constant MCI_WAVE_STATUS_AVGBYTESPERSEC  => 0x00004004;
   use constant MCI_WAVE_STATUS_BLOCKALIGN      => 0x00004005;
   use constant MCI_WAVE_STATUS_BITSPERSAMPLE   => 0x00004006;
   use constant MCI_WAVE_STATUS_LEVEL           => 0x00004007;
   use constant MCI_WAVE_SET_ANYINPUT           => 0x04000000;
   use constant MCI_WAVE_SET_ANYOUTPUT          => 0x08000000;
   use constant MCI_WAVE_GETDEVCAPS_INPUTS      => 0x00004001;
   use constant MCI_WAVE_GETDEVCAPS_OUTPUTS     => 0x00004002;

#sequencer (MIDI)
   use constant MCI_SEQ_DIV_PPQN                => (0 + MCI_SEQ_OFFSET);
   use constant MCI_SEQ_DIV_SMPTE_24            => (1 + MCI_SEQ_OFFSET);
   use constant MCI_SEQ_DIV_SMPTE_25            => (2 + MCI_SEQ_OFFSET);
   use constant MCI_SEQ_DIV_SMPTE_30DROP        => (3 + MCI_SEQ_OFFSET);
   use constant MCI_SEQ_DIV_SMPTE_30            => (4 + MCI_SEQ_OFFSET);
   use constant MCI_SEQ_FORMAT_SONGPTR          => 0x4001;
   use constant MCI_SEQ_FILE                    => 0x4002;
   use constant MCI_SEQ_MIDI                    => 0x4003;
   use constant MCI_SEQ_SMPTE                   => 0x4004;
   use constant MCI_SEQ_NONE                    => 65533;
   use constant MCI_SEQ_MAPPER                  => 65535;
   use constant MCI_SEQ_STATUS_TEMPO            => 0x00004002;
   use constant MCI_SEQ_STATUS_PORT             => 0x00004003;
   use constant MCI_SEQ_STATUS_SLAVE            => 0x00004007;
   use constant MCI_SEQ_STATUS_MASTER           => 0x00004008;
   use constant MCI_SEQ_STATUS_OFFSET           => 0x00004009;
   use constant MCI_SEQ_STATUS_DIVTYPE          => 0x0000400A;
   use constant MCI_SEQ_STATUS_NAME             => 0x0000400B;
   use constant MCI_SEQ_STATUS_COPYRIGHT        => 0x0000400C;
   use constant MCI_SEQ_SET_TEMPO               => 0x00010000;
   use constant MCI_SEQ_SET_PORT                => 0x00020000;
   use constant MCI_SEQ_SET_SLAVE               => 0x00040000;
   use constant MCI_SEQ_SET_MASTER              => 0x00080000;
   use constant MCI_SEQ_SET_OFFSET              => 0x01000000;


   use constant MCI_ANIM_OPEN_WS                => 0x00010000;
   use constant MCI_ANIM_OPEN_PARENT            => 0x00020000;
   use constant MCI_ANIM_OPEN_NOSTATIC          => 0x00040000;
   use constant MCI_ANIM_PLAY_SPEED             => 0x00010000;
   use constant MCI_ANIM_PLAY_REVERSE           => 0x00020000;
   use constant MCI_ANIM_PLAY_FAST              => 0x00040000;
   use constant MCI_ANIM_PLAY_SLOW              => 0x00080000;
   use constant MCI_ANIM_PLAY_SCAN              => 0x00100000;
   use constant MCI_ANIM_STEP_REVERSE           => 0x00010000;
   use constant MCI_ANIM_STEP_FRAMES            => 0x00020000;
   use constant MCI_ANIM_STATUS_SPEED           => 0x00004001;
   use constant MCI_ANIM_STATUS_FORWARD         => 0x00004002;
   use constant MCI_ANIM_STATUS_HWND            => 0x00004003;
   use constant MCI_ANIM_STATUS_HPAL            => 0x00004004;
   use constant MCI_ANIM_STATUS_STRETCH         => 0x00004005;
   use constant MCI_ANIM_INFO_TEXT              => 0x00010000;
   use constant MCI_ANIM_GETDEVCAPS_CAN_REVERSE => 0x00004001;
   use constant MCI_ANIM_GETDEVCAPS_FAST_RATE   => 0x00004002;
   use constant MCI_ANIM_GETDEVCAPS_SLOW_RATE   => 0x00004003;
   use constant MCI_ANIM_GETDEVCAPS_NORMAL_RATE => 0x00004004;
   use constant MCI_ANIM_GETDEVCAPS_PALETTES    => 0x00004006;
   use constant MCI_ANIM_GETDEVCAPS_CAN_STRETCH => 0x00004007;
   use constant MCI_ANIM_GETDEVCAPS_MAX_WINDOWS => 0x00004008;
   use constant MCI_ANIM_REALIZE_NORM           => 0x00010000;
   use constant MCI_ANIM_REALIZE_BKGD           => 0x00020000;
   use constant MCI_ANIM_WINDOW_HWND            => 0x00010000;
   use constant MCI_ANIM_WINDOW_STATE           => 0x00040000;
   use constant MCI_ANIM_WINDOW_TEXT            => 0x00080000;
   use constant MCI_ANIM_WINDOW_ENABLE_STRETCH  => 0x00100000;
   use constant MCI_ANIM_WINDOW_DISABLE_STRETCH => 0x00200000;
   use constant MCI_ANIM_WINDOW_DEFAULT         => 0x00000000;
   use constant MCI_ANIM_RECT                   => 0x00010000;
   use constant MCI_ANIM_PUT_SOURCE             => 0x00020000;
   use constant MCI_ANIM_PUT_DESTINATION        => 0x00040000;
   use constant MCI_ANIM_WHERE_SOURCE           => 0x00020000;
   use constant MCI_ANIM_WHERE_DESTINATION      => 0x00040000;
   use constant MCI_ANIM_UPDATE_HDC             => 0x00020000;

#overlay device
   use constant MCI_OVLY_OPEN_WS                => 0x00010000;
   use constant MCI_OVLY_OPEN_PARENT            => 0x00020000;
   use constant MCI_OVLY_STATUS_HWND            => 0x00004001;
   use constant MCI_OVLY_STATUS_STRETCH         => 0x00004002;
   use constant MCI_OVLY_INFO_TEXT              => 0x00010000;
   use constant MCI_OVLY_GETDEVCAPS_CAN_STRETCH => 0x00004001;
   use constant MCI_OVLY_GETDEVCAPS_CAN_FREEZE  => 0x00004002;
   use constant MCI_OVLY_GETDEVCAPS_MAX_WINDOWS => 0x00004003;
   use constant MCI_OVLY_WINDOW_HWND            => 0x00010000;
   use constant MCI_OVLY_WINDOW_STATE           => 0x00040000;
   use constant MCI_OVLY_WINDOW_TEXT            => 0x00080000;
   use constant MCI_OVLY_WINDOW_ENABLE_STRETCH  => 0x00100000;
   use constant MCI_OVLY_WINDOW_DISABLE_STRETCH => 0x00200000;
   use constant MCI_OVLY_WINDOW_DEFAULT         => 0x00000000;
   use constant MCI_OVLY_RECT                   => 0x00010000;
   use constant MCI_OVLY_PUT_SOURCE             => 0x00020000;
   use constant MCI_OVLY_PUT_DESTINATION        => 0x00040000;
   use constant MCI_OVLY_PUT_FRAME              => 0x00080000;
   use constant MCI_OVLY_PUT_VIDEO              => 0x00100000;
   use constant MCI_OVLY_WHERE_SOURCE           => 0x00020000;
   use constant MCI_OVLY_WHERE_DESTINATION      => 0x00040000;
   use constant MCI_OVLY_WHERE_FRAME            => 0x00080000;
   use constant MCI_OVLY_WHERE_VIDEO            => 0x00100000;

1;
__END__
