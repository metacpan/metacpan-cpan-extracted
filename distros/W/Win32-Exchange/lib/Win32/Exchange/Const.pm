package Win32::Exchange::Const;

use strict;
use vars qw(@ISA @EXPORT);

use Exporter;

@ISA = qw(Exporter);
@EXPORT      = qw(ADS_ACEFLAG_INHERIT_ACE
		  ADS_ACETYPE_ACCESS_ALLOWED
		  ADS_FAST_BIND
		  ADS_NO_AUTHENTICATION
		  ADS_PROMPT_CREDENTIALS
		  ADS_READONLY_SERVER
		  ADS_RIGHT_DS_CREATE_CHILD
		  ADS_RIGHT_EXCH_MAIL_RECEIVE_AS
		  ADS_RIGHT_EXCH_MAIL_SEND_AS
		  ADS_RIGHT_EXCH_MODIFY_USER_ATT
		  ADS_SECURE_AUTHENTICATION
		  ADS_SERVER_BIND
		  ADS_SID_ACTIVE_DIRECTORY_PATH
		  ADS_SID_HEXSTRING
		  ADS_SID_RAW
		  ADS_SID_SAM
		  ADS_SID_SDDL
		  ADS_SID_SID_BINDING
		  ADS_SID_UPN
		  ADS_SID_WINNT_PATH
		  ADS_USE_DELEGATION
		  ADS_USE_ENCRYPTION
		  ADS_USE_SEALING
		  ADS_USE_SIGNING
		  ADS_USE_SSL
		  adModeReadWrite
                 );

use constant ADS_ACEFLAG_INHERIT_ACE => 0x2;
use constant ADS_ACETYPE_ACCESS_ALLOWED => 0x00;
use constant ADS_FAST_BIND => 0x20;
use constant ADS_NO_AUTHENTICATION => 0x10;
use constant ADS_PROMPT_CREDENTIALS => 0x8;
use constant ADS_READONLY_SERVER => 0x4;
use constant ADS_RIGHT_DS_CREATE_CHILD => 0x1;
use constant ADS_RIGHT_EXCH_MAIL_RECEIVE_AS => 0x10;
use constant ADS_RIGHT_EXCH_MAIL_SEND_AS => 0x08;
use constant ADS_RIGHT_EXCH_MODIFY_USER_ATT => 0x02;
use constant ADS_SECURE_AUTHENTICATION => 0x1;
use constant ADS_SERVER_BIND => 0x200;
use constant ADS_SID_ACTIVE_DIRECTORY_PATH => 0x6;
use constant ADS_SID_HEXSTRING => 0x1;
use constant ADS_SID_RAW => 0x0;
use constant ADS_SID_SAM => 0x2;
use constant ADS_SID_SDDL => 0x4;
use constant ADS_SID_SID_BINDING => 0x7;
use constant ADS_SID_UPN => 0x3;
use constant ADS_SID_WINNT_PATH => 0x5;
use constant ADS_USE_DELEGATION => 0x100;
use constant ADS_USE_ENCRYPTION => 0x2;
use constant ADS_USE_SEALING => 0x80;
use constant ADS_USE_SIGNING => 0x40;
use constant ADS_USE_SSL => 0x2;
use constant adModeReadWrite => 3;

1;
