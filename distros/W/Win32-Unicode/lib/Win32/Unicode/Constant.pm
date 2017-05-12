package Win32::Unicode::Constant;

use strict;
use warnings;
use 5.008003;
use Exporter 'import';

our $VERSION = '0.38';
our @EXPORT = grep { !/import|BEGIN|EXPORT/ && Win32::Unicode::Constant->can($_) } keys %Win32::Unicode::Constant::;

use constant CYGWIN  => $^O eq 'cygwin';
use constant _32INT  => 4294967296;
use constant _S32INT => -4294967296;

sub NULL     () { "\x00" }
sub NULLP    () { [] }
sub MAX_PATH () { 520 }
sub BUFF     () { NULL x (MAX_PATH + 1) }
sub TRUE     () { 1 }
sub FALSE    () { 0 }
sub INFINITE () { 0xFFFFFFFF }

# console
sub STD_INPUT_HANDLE      () { -10 }
sub STD_OUTPUT_HANDLE     () { -11 }
sub STD_ERROR_HANDLE      () { -12 }
sub MAX_BUFFER_SIZE       () { 20000 }

# file attribute
sub FILE_ATTRIBUTE_READONLY            () { 0x00000001 }
sub FILE_ATTRIBUTE_HIDDEN              () { 0x00000002 }
sub FILE_ATTRIBUTE_SYSTEM              () { 0x00000004 }
sub FILE_ATTRIBUTE_DIRECTORY           () { 0x00000010 }
sub FILE_ATTRIBUTE_ARCHIVE             () { 0x00000020 }
sub FILE_ATTRIBUTE_NORMAL              () { 0x00000080 }
sub FILE_ATTRIBUTE_TEMPORARY           () { 0x00000100 }
sub FILE_ATTRIBUTE_COMPRESSED          () { 0x00000800 }
sub FILE_ATTRIBUTE_OFFLINE             () { 0x00001000 }
sub FILE_ATTRIBUTE_ENCRYPTED           () { 0x00004000 }
sub FILE_ATTRIBUTE_NOT_CONTENT_INDEXED () { 0x00002000 }
sub INVALID_VALUE                      () { -1 };

sub ERROR_NO_MORE_FILES  () { 18 }
sub INVALID_HANDLE_VALUE () { -1 }

# create file type
sub GENERIC_READ    () { 0x80000000 }
sub GENERIC_WRITE   () { 0x40000000 }
sub GENERIC_EXECUTE () { 0x20000000 }

# share mode
sub FILE_SHARE_READ   () { 0x00000001 }
sub FILE_SHARE_WRITE  () { 0x00000002 }
sub FILE_SHARE_DELETE () { 0x00000004 }

# file open type
sub CREATE_NEW        () { 1 }
sub CREATE_ALWAYS     () { 2 }
sub OPEN_EXISTING     () { 3 }
sub OPEN_ALWAYS       () { 4 }
sub TRUNCATE_EXISTING () { 5 }

# format message
#sub FORMAT_MESSAGE_ALLOCATE_BUFFER () { 0x00000100 }
#sub FORMAT_MESSAGE_ARGUMENT_ARRAY  () { 0x00002000 }
#sub FORMAT_MESSAGE_FROM_HMODULE    () { 0x00000800 }
#sub FORMAT_MESSAGE_FROM_STRING     () { 0x00000400 }
#sub FORMAT_MESSAGE_FROM_SYSTEM     () { 0x00001000 }
#sub FORMAT_MESSAGE_IGNORE_INSERTS  () { 0x00000200 }
#sub FORMAT_MESSAGE_MAX_WIDTH_MASK  () { 255 * 2 }

#sub LANG_NEUTRAL      () { 0x00 }
#sub SUBLANG_DEFAULT   () { 0x01 }
#sub LANG_USER_DEFAULT () { SUBLANG_DEFAULT << 10 | LANG_NEUTRAL }

# process priority
#sub NORMAL_PRIORITY_CLASS       () { 0x00000020 }
#sub IDLE_PRIORITY_CLASS         () { 0x00000040 }
#sub HIGH_PRIORITY_CLASS         () { 0x00000080 }
#sub REALTIME_PRIORITY_CLASS     () { 0x00000100 }
#sub BELOW_NORMAL_PRIORITY_CLASS () { 0x00004000 }
#sub ABOVE_NORMAL_PRIORITY_CLASS () { 0x00008000 }

# process flag
#sub DEBUG_PROCESS              () { 0x00000001 }
#sub DEBUG_ONLY_THIS_PROCESS    () { 0x00000002 }
#sub CREATE_SUSPENDED           () { 0x00000004 }
#sub DETACHED_PROCESS           () { 0x00000008 }
#sub CREATE_NEW_CONSOLE         () { 0x00000010 }
#sub CREATE_NEW_PROCESS_GROUPE  () { 0x00000200 }
#sub CREATE_UNICODE_ENVIRONMENT () { 0x00000400 }
#sub CREATE_SEPARATE_WOW_VDM    () { 0x00000800 }
#sub CREATE_SHARED_WOW_VDM      () { 0x00001000 }
#sub CREATE_FORCEDOS            () { 0x00002000 }
#sub CREATE_BREAKAWAY_FROM_JOB  () { 0x01000000 }
#sub CREATE_DEFAULT_ERROR_MODE  () { 0x04000000 }
#sub CREATE_NO_WINDOW           () { 0x08000000 }

# error code
sub NO_ERROR          () { 0x00000000 }
sub ERROR_FILE_EXISTS () { 0x00000050 }

1;
__END__
