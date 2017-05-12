package TotalCmd::FSPlugin;

require Exporter;

@ISA = qw(Exporter);

our $VERSION = 0.03;

our @EXPORT = (
 INVALID_HANDLE_VALUE,
 FS_FILE_OK,
 FS_FILE_EXISTS,
 FS_FILE_NOTFOUND,
 FS_FILE_READERROR,
 FS_FILE_WRITEERROR,
 FS_FILE_USERABORT,
 FS_FILE_NOTSUPPORTED,
 FS_FILE_EXISTSRESUMEALLOWED,
 FS_EXEC_OK,
 FS_EXEC_ERROR,
 FS_EXEC_YOURSELF,
 FS_EXEC_SYMLINK,
 FS_COPYFLAGS_OVERWRITE,
 FS_COPYFLAGS_RESUME,
 FS_COPYFLAGS_MOVE,
 FS_COPYFLAGS_EXISTS_SAMECASE,
 FS_COPYFLAGS_EXISTS_DIFFERENTCASE,
 RT_Other,
 RT_UserName,
 RT_Password,
 RT_Account,
 RT_UserNameFirewall,
 RT_PasswordFirewall,
 RT_TargetDir,
 RT_URL,
 RT_MsgOK,
 RT_MsgYesNo,
 RT_MsgOKCancel,
 MSGTYPE_CONNECT,
 MSGTYPE_DISCONNECT,
 MSGTYPE_DETAILS,
 MSGTYPE_TRANSFERCOMPLETE,
 MSGTYPE_CONNECTCOMPLETE,
 MSGTYPE_IMPORTANTERROR,
 MSGTYPE_OPERATIONCOMPLETE,
 FS_STATUS_START,
 FS_STATUS_END ,
 FS_STATUS_OP_LIST ,
 FS_STATUS_OP_GET_SINGLE,
 FS_STATUS_OP_GET_MULTI,
 FS_STATUS_OP_PUT_SINGLE,
 FS_STATUS_OP_PUT_MULTI,
 FS_STATUS_OP_RENMOV_SINGLE,
 FS_STATUS_OP_RENMOV_MULTI,
 FS_STATUS_OP_DELETE ,
 FS_STATUS_OP_ATTRIB ,
 FS_STATUS_OP_MKDIR ,
 FS_STATUS_OP_EXEC ,
 FS_STATUS_OP_CALCSIZE ,
 FS_STATUS_OP_SEARCH,
 FS_STATUS_OP_SEARCH_TEXT ,
 FS_STATUS_OP_SYNC_SEARCH ,
 FS_STATUS_OP_SYNC_GET ,
 FS_STATUS_OP_SYNC_PUT ,
 FS_STATUS_OP_SYNC_DELETE ,
 FS_ICONFLAG_SMALL ,
 FS_ICONFLAG_BACKGROUND ,
 FS_ICON_USEDEFAULT ,
 FS_ICON_EXTRACTED ,
 FS_ICON_EXTRACTED_DESTROY ,
 FS_ICON_DELAYED ,
);

our @EXPORT_OK = (
);

use constant INVALID_HANDLE_VALUE => -1;

use constant FS_FILE_OK => 0;
use constant FS_FILE_EXISTS => 1;
use constant FS_FILE_NOTFOUND => 2;
use constant FS_FILE_READERROR => 3;
use constant FS_FILE_WRITEERROR => 4;
use constant FS_FILE_USERABORT => 5;
use constant FS_FILE_NOTSUPPORTED => 6;
use constant FS_FILE_EXISTSRESUMEALLOWED => 7;

use constant FS_EXEC_OK => 0;
use constant FS_EXEC_ERROR => 1;
use constant FS_EXEC_YOURSELF => -1;
use constant FS_EXEC_SYMLINK => -2;

use constant FS_COPYFLAGS_OVERWRITE => 1;
use constant FS_COPYFLAGS_RESUME => 2;
use constant FS_COPYFLAGS_MOVE => 4;
use constant FS_COPYFLAGS_EXISTS_SAMECASE => 8;
use constant FS_COPYFLAGS_EXISTS_DIFFERENTCASE => 16;
 
# flags for tRequestProc
use constant RT_Other => 0;
use constant RT_UserName => 1;
use constant RT_Password => 2;
use constant RT_Account => 3;
use constant RT_UserNameFirewall => 4;
use constant RT_PasswordFirewall => 5;
use constant RT_TargetDir => 6;
use constant RT_URL => 7;
use constant RT_MsgOK => 8;
use constant RT_MsgYesNo => 9;
use constant RT_MsgOKCancel => 10;

# flags for tLogProc
use constant MSGTYPE_CONNECT => 1;
use constant MSGTYPE_DISCONNECT => 2;
use constant MSGTYPE_DETAILS => 3;
use constant MSGTYPE_TRANSFERCOMPLETE => 4;
use constant MSGTYPE_CONNECTCOMPLETE => 5;
use constant MSGTYPE_IMPORTANTERROR => 6;
use constant MSGTYPE_OPERATIONCOMPLETE => 7;

# flags for FsStatusInfo
use constant FS_STATUS_START => 0;
use constant FS_STATUS_END => 1;

use constant FS_STATUS_OP_LIST => 1;
use constant FS_STATUS_OP_GET_SINGLE => 2;
use constant FS_STATUS_OP_GET_MULTI => 3;
use constant FS_STATUS_OP_PUT_SINGLE => 4;
use constant FS_STATUS_OP_PUT_MULTI => 5;
use constant FS_STATUS_OP_RENMOV_SINGLE => 6;
use constant FS_STATUS_OP_RENMOV_MULTI => 7;
use constant FS_STATUS_OP_DELETE => 8;
use constant FS_STATUS_OP_ATTRIB => 9;
use constant FS_STATUS_OP_MKDIR => 10;
use constant FS_STATUS_OP_EXEC => 11;
use constant FS_STATUS_OP_CALCSIZE => 12;
use constant FS_STATUS_OP_SEARCH => 13;
use constant FS_STATUS_OP_SEARCH_TEXT => 14;
use constant FS_STATUS_OP_SYNC_SEARCH => 15;
use constant FS_STATUS_OP_SYNC_GET => 16;
use constant FS_STATUS_OP_SYNC_PUT => 17;
use constant FS_STATUS_OP_SYNC_DELETE => 18;


use constant FS_ICONFLAG_SMALL => 1;
use constant FS_ICONFLAG_BACKGROUND => 2;

use constant FS_ICON_USEDEFAULT => 0;
use constant FS_ICON_EXTRACTED => 1;
use constant FS_ICON_EXTRACTED_DESTROY => 2;
use constant FS_ICON_DELAYED => 3;



1;
__END__

=head1 NAME

TotalCmd::FSPlugin - Helper module for writing FS plugins for Total Commander 

=head1 SYNOPSIS

  use TotalCmd::FSPlugin;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for TotalCmd::FSPlugin, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

E. E. Ogloblin, E<lt>ogloblin@mail.ruE<gt>

=head1 SEE ALSO

L<perl>.

=cut