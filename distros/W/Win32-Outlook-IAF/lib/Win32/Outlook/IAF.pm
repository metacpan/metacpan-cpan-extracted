package Win32::Outlook::IAF;

use warnings;
use strict;

require Exporter;
use Carp;

use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);


$VERSION='0.96';
@ISA=qw(Exporter);
@EXPORT=qw();


# export enum constants
my %const;
use constant +{%const=(
	# ConnectionType enums
	IAF_CT_LAN		=> 0,
	IAF_CT_DIALER		=> 1,
	IAF_CT_DIALUP		=> 2,
	IAF_CT_IE_DEFAULT	=> 3,
	# AuthMethod enums
	IAF_AM_NONE		=> 0,
	IAF_AM_SPA		=> 1,
	IAF_AM_USE_INCOMING	=> 2,
	IAF_AM_PLAIN		=> 3,
	# NNTP PostingFormat enums
	IAF_PF_USE_OPTIONS	=> 0,
	IAF_PF_PLAIN		=> 1,
	IAF_PF_HTML		=> 2,
)};
push(@EXPORT,keys %const);


use constant {
	HEADER			=> "\x66\x4D\x41\x49\x00\x00\x05\x00\x01\x00\x00\x00",
	PASSWORD_SEED		=> "\x75\x18\x15\x14",
	PASSWORD_HEADER		=> "\x01\x01",
	MAX_FIELD_LENGTH	=> 4096,
};


# field value regexes
my $bool_re=qr/^[01]$/;		# boolean
my $num_re=qr/^\d+$/;		# numeric
my $regkey_re=qr/^[0-9a-z]*$/i;	# registry key

my $iaf_ct_re=qr/^[${\IAF_CT_LAN}-${\IAF_CT_IE_DEFAULT}]$/;
my $iaf_am_re=qr/^[${\IAF_AM_NONE}-${\IAF_AM_PLAIN}]$/;
my $iaf_pf_re=qr/^[${\IAF_PF_USE_OPTIONS}-${\IAF_PF_HTML}]$/;

# field binary formats
my $ulong_le_fmt='V'; # an unsigned long in portable little-endian order
my $nullstr_fmt='Z*'; # a null terminated string


my %fields=(
	# name					# id		# binary format		# value regex	# callback
	'AccountName'			=>	[305464304,	$nullstr_fmt,							],
	'TemporaryAccount'		=>	[305595369,	$ulong_le_fmt,		$bool_re,				],
	'ConnectionType'		=>	[305726441,	$ulong_le_fmt,		$iaf_ct_re,				],
	'ConnectionName'		=>	[305791984,	$nullstr_fmt,							],
	'ConnectionFlags'		=>	[305857513,	$ulong_le_fmt,		$num_re,				],
	'AccountID'			=>	[305988592,	$nullstr_fmt,		$regkey_re,				],
	'BackupConnectionName'		=>	[306054128,	$nullstr_fmt,							],
	'MakeAvailableOffline'		=>	[306185193,	$ulong_le_fmt,		$bool_re,				],
	'ServerReadOnly'		=>	[306316277,	$ulong_le_fmt,		$bool_re,				],
	'IMAPServer'			=>	[311952368,	$nullstr_fmt,							],
	'IMAPUserName'			=>	[312017904,	$nullstr_fmt,							],
	'IMAPPassword'			=>	[312083446,	$nullstr_fmt,		'',		\&_iaf_password		],
	'IMAPAuthUseSPA'		=>	[312214517,	$ulong_le_fmt,		$bool_re,				],
	'IMAPPort'			=>	[312280041,	$ulong_le_fmt,		$num_re,				],
	'IMAPSecureConnection'		=>	[312345589,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool 		],
	'IMAPTimeout'			=>	[312411113,	$ulong_le_fmt,		$num_re,				],
	'IMAPRootFolder'		=>	[312476656,	$nullstr_fmt,							],
	'IMAPUseLSUB'			=>	[312673269,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool 		],
	'IMAPPolling'			=>	[312738805,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'IMAPFullList'			=>	[312804341,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'IMAPStoreSpecialFolders'	=>	[313000949,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'IMAPSentItemsFolder'		=>	[313066480,	$nullstr_fmt,							],
	'IMAPDraftsFolder'		=>	[313197552,	$nullstr_fmt,							],
	'IMAPPasswordPrompt'		=>	[313525237,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'IMAPDirty'			=>	[313590761,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'IMAPPollAllFolders'		=>	[313656309,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'HTTPServer'			=>	[321782768,	$nullstr_fmt,							],
	'HTTPUserName'			=>	[321848304,	$nullstr_fmt,							],
	'HTTPPassword'			=>	[321913846,	$nullstr_fmt,		'',		\&_iaf_password		],
	'HTTPPasswordPrompt'		=>	[321979381,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'HTTPAuthUseSPA'		=>	[322044905,	$ulong_le_fmt,		$bool_re,				],
	'HTTPFriendlyName'		=>	[322110448,	$nullstr_fmt,							],
	'DomainIsMSN'			=>	[322175989,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'HTTPPolling'			=>	[322241525,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'AdBarURL'			=>	[322307056,	$nullstr_fmt,							],
	'ShowAdBar'			=>	[322372597,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'MinPollingInterval'		=>	[322438135,	$ulong_le_fmt,		$num_re,				],
	'GotPollingInterval'		=>	[322503669,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'LastPolledTime'		=>	[322569207,	$ulong_le_fmt,		$num_re,				],
	'NNTPServer'			=>	[325059568,	$nullstr_fmt,							],
	'NNTPUserName'			=>	[325125104,	$nullstr_fmt,							],
	'NNTPPassword'			=>	[325190646,	$nullstr_fmt,		'',		\&_iaf_password		],
	'NNTPAuthMethod'		=>	[325321717,	$ulong_le_fmt,		$iaf_am_re,				],
	'NNTPPort'			=>	[325387241,	$ulong_le_fmt,		$num_re,				],
	'NNTPSecureConnection'		=>	[325452789,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'NNTPTimeout'			=>	[325518313,	$ulong_le_fmt,		$num_re,				],
	'NNTPDisplayName'		=>	[325583856,	$nullstr_fmt,							],
	'NNTPOrganizationName'		=>	[325649392,	$nullstr_fmt,							],
	'NNTPEmailAddress'		=>	[325714928,	$nullstr_fmt,							],
	'NNTPReplyToEmailAddress'	=>	[325780464,	$nullstr_fmt,							],
	'NNTPSplitMessages'		=>	[325846005,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'NNTPSplitMessageSize'		=>	[325911529,	$ulong_le_fmt,		$num_re,				],
	'NNTPUseGroupDescriptions'	=>	[325977077,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'NNTPPolling'			=>	[326108149,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'NNTPPostingFormat'		=>	[326173673,	$ulong_le_fmt,		$iaf_pf_re,				],
	'NNTPSignature'			=>	[326239216,	$nullstr_fmt,		$regkey_re,				],
	'NNTPPasswordPrompt'		=>	[326304757,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'POP3Server'			=>	[331613168,	$nullstr_fmt,							],
	'POP3UserName'			=>	[331678704,	$nullstr_fmt,							],
	'POP3Password'			=>	[331744246,	$nullstr_fmt,		'',		\&_iaf_password		],
	'POP3AuthUseSPA'		=>	[331875317,	$ulong_le_fmt,		$bool_re,				],
	'POP3Port'			=>	[331940841,	$ulong_le_fmt,		$num_re,				],
	'POP3SecureConnection'		=>	[332006389,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'POP3Timeout'			=>	[332071913,	$ulong_le_fmt,		$num_re,				],
	'POP3LeaveMailOnServer'		=>	[332137461,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'POP3RemoveWhenDeleted'		=>	[332202997,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'POP3RemoveWhenExpired'		=>	[332268533,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'POP3ExpireDays'		=>	[332334057,	$ulong_le_fmt,		$num_re,				],
	'POP3SkipAccount'		=>	[332399605,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'POP3PasswordPrompt'		=>	[332530677,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'SMTPServer'			=>	[338166768,	$nullstr_fmt,							],
	'SMTPUserName'			=>	[338232304,	$nullstr_fmt,							],
	'SMTPPassword'			=>	[338297846,	$nullstr_fmt,		'',		\&_iaf_password		],
	'SMTPAuthMethod'		=>	[338428905,	$ulong_le_fmt,		$iaf_am_re,				],
	'SMTPPort'			=>	[338494441,	$ulong_le_fmt,		$num_re,				],
	'SMTPSecureConnection'		=>	[338559989,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'SMTPTimeout'			=>	[338625513,	$ulong_le_fmt,		$num_re,				],
	'SMTPDisplayName'		=>	[338691056,	$nullstr_fmt,							],
	'SMTPOrganizationName'		=>	[338756592,	$nullstr_fmt,							],
	'SMTPEmailAddress'		=>	[338822128,	$nullstr_fmt,							],
	'SMTPReplyToEmailAddress'	=>	[338887664,	$nullstr_fmt,							],
	'SMTPSplitMessages'		=>	[338953205,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
	'SMTPSplitMessageSize'		=>	[339018729,	$ulong_le_fmt,		$num_re,				],
	'SMTPSignature'			=>	[339149808,	$nullstr_fmt,		$regkey_re,				],
	'SMTPPasswordPrompt'		=>	[339215349,	$ulong_le_fmt,		$bool_re,	\&_iaf_bool		],
);


sub new {
	my ($class,%args)=@_;
	my $self={};
	while (my ($field_name,$field_def)=each %fields) {
		next unless exists $args{$field_name};
		my $field=delete $args{$field_name};
		$field=$field_def->[3]->($field,'set') if $field_def->[3]; # call callback() as 'set'
		_check_field($field_name,$field);
		$self->{"_$field_name"}=$field;
	}
	confess('Unknown argument: '.(keys %args)[0]) if scalar keys %args;
	bless($self,$class);
	return $self;
}


sub AUTOLOAD {
	my ($self,$field)=($_[0],@_>1 && \$_[1]);
	confess('Not an object!') unless ref $self;
	my $field_name;
	($field_name=$AUTOLOAD)=~s/^.*:://; # trim package name
	return if $field_name eq 'DESTROY'; # let DESTROY fall through
	confess("Can't access '$field_name' field in $self") unless exists $fields{$field_name};
	my $field_def=$fields{$field_name};
	my $new_field;
	unless (ref $field) {		# get
		$new_field=$self->{"_$field_name"};
		$new_field=$field_def->[3]->($new_field,'get') if $field_def->[3]; # call callback() as 'get'
	} elsif (defined $$field) {	# set
		$new_field=$$field;
		$new_field=$field_def->[3]->($new_field,'set') if $field_def->[3]; # call callback() as 'set'
		_check_field($field_name,$new_field);
		$self->{"_$field_name"}=$new_field;
	} else {			# delete
		$new_field=$self->{"_$field_name"};
		$new_field=$field_def->[3]->($new_field,'delete') if $field_def->[3]; # call callback() as 'delete'
		delete $self->{"_$field_name"};
	}
	return $new_field;
}


# build a reverse hash for read/write/text operations
my %lookup=map {
	my $field_def=$fields{$_};
	# id			# name		# binary format		# value regex		# callback
	$field_def->[0],	[$_,		$field_def->[1],	$field_def->[2] || '',	$field_def->[3] || '']
} keys %fields;


sub read_iaf {
	my ($self,$data)=($_[0],@_>1 && \$_[1]);
	my $pos=0;
	my $len=length($$data);
	confess('Premature end of data while reading header') if $pos+length(HEADER)>$len;
	$pos+=length(HEADER); # read header
	# read fields
	while ($pos<$len) {
		confess('Premature end of data while reading field_id') if $pos+4>$len;
		my $field_id=unpack('V',substr($$data,$pos,4));
		$pos+=4;
		confess('Premature end of data while reading field_len') if $pos+4>$len;
		my $field_len=unpack('V',substr($$data,$pos,4));
		$pos+=4;
		confess('Premature end of data while reading field') if $pos+$field_len>$len;
		confess('Excessive field length: '.$field_len) if $field_len>MAX_FIELD_LENGTH;
		my $field=substr($$data,$pos,$field_len);
		$pos+=$field_len;
		confess('Unknown field: '.$field_id) unless exists $lookup{$field_id};
		my $field_def=$lookup{$field_id};
		$field=$field_def->[3]->($field,'read','packed') if $field_def->[3];	# call callback() as 'read packed'
		$field=unpack($field_def->[1],$field) if $field_def->[1];		# apply binary format
		$field=$field_def->[3]->($field,'read','unpacked') if $field_def->[3];	# call callback() as 'read unpacked'
		my $field_name=$field_def->[0];
		_check_field($field_name,$field);
		$self->{"_$field_name"}=$field;
	}
	return 1;
}


sub write_iaf {
	my ($self,$data)=($_[0],@_>1 && \$_[1]);
	$$data=HEADER; # write header
	# write fields
	while (my ($field_id,$field_def)=each %lookup) {
		my $field_name=$field_def->[0];
		next unless exists $self->{"_$field_name"};
		my $field=$self->{"_$field_name"};
		$field=$field_def->[3]->($field,'write','unpacked') if $field_def->[3];	# call callback() as 'write unpacked'
		$field=pack($field_def->[1],$field) if $field_def->[1];			# apply binary format
		$field=$field_def->[3]->($field,'write','packed') if $field_def->[3];	# call callback() as 'write packed'
		my $field_len=pack('V',length($field));
		$field_id=pack('V',$field_id);
		$$data.="$field_id$field_len$field";
	}
	return 1;
}


sub text_iaf {
	my ($self,$data,$delimiter)=($_[0],@_>1 && \$_[1],$_[2]);
	$delimiter||="\t"; # assume 'tab' delimiter
	$$data=''; # write header
	# write sorted fields (name value)
	foreach my $field_id (sort keys %lookup) {
		my $field_def=$lookup{$field_id};
		my $field_name=$field_def->[0];
		next unless exists $self->{"_$field_name"};
		my $field=$self->{"_$field_name"};
		$field=$field_def->[3]->($field,'text','') if $field_def->[3];	# call callback() as 'text'
		$$data.="$field_name$delimiter$field\n";
	}
	return 1;
}


sub _check_field {
	my ($field_name,$field)=($_[0],@_>1 && \$_[1]);
	my $field_def=$fields{$field_name};
	my $field_re=$field_def->[2] ? ref $field_def->[2] eq 'Regexp' ? $field_def->[2] : qr/$field_def->[2]/ : '';
	$$field!~$field_re && confess('Invalid field value: '.$$field) if $field_re;
}


# turn parameters into boolean 0/1 values
sub _iaf_bool {
	my ($value,$operation,$phase)=(@_>0 && \$_[0],$_[1],$_[2]);
	# this callback runs only during 'get' or 'set' operations
	return $$value unless $operation eq 'get' || $operation eq 'set';
	return $$value ? 1 : 0;
}


# encrypt/decrypt passwords
sub _iaf_password {
	my ($password,$operation,$phase)=(@_>0 && \$_[0],$_[1],$_[2]);
	# protect sensitive data
	return '********' if $operation eq 'text';
	# this callback runs only during 'read' or 'write' operations
	return $$password unless $operation eq 'read' || $operation eq 'write';
	# this callback operates only on 'packed' data
	return $$password unless $phase eq 'packed';
	my ($ret,$pos,$len)=('',0,length($$password));
	my $seed=PASSWORD_SEED;
	my $fill;
	if ($operation eq 'read') {
		confess('Premature end of data while reading password header') if $pos+length(PASSWORD_HEADER)>$len;
		$pos+=length(PASSWORD_HEADER);
		confess('Premature end of data while reading password_len') if $pos+4>$len;
		my $password_len=unpack('V',substr($$password,$pos,4));
		$pos+=4;
		confess('Malformed password record') if $pos+$password_len!=$len;
	} else {
		$ret=PASSWORD_HEADER;
		$ret.=pack('V',$len);
	}
	while ($pos<$len) {
		$fill=$pos+4>$len ? $pos+4-$len : 0;
		$seed=unpack('V',("\x00" x $fill).substr($seed,$fill));
		my $d=unpack('V',("\x00" x $fill).substr($$password,$pos,4-$fill));
		$pos+=4-$fill;
		$ret.=substr(pack('V',$d^$seed),$fill);
		$seed=pack('V',$operation eq 'read' ? $d^$seed : $d);
	}
	return $ret;
}

1; # End of Win32::Outlook::IAF

__DATA__

=head1 NAME

Win32::Outlook::IAF - Internet Account File (*.iaf) management for Outlook Express/2000.


=head1 VERSION

Version 0.96


=head1 SYNOPSIS

    use Win32::Outlook::IAF;

    my $iaf=new Win32::Outlook::IAF;

    my $src='MyAccount.iaf';

    local $/;
    open(INPUT,"<$src") || die "Can't open $src for reading: $!\n";
    binmode(INPUT);

    $iaf->read_iaf(<INPUT>);
    close(INPUT);

    # forgot your POP3 password?
    print $iaf->POP3Password();

    $iaf=new Win32::Outlook::IAF(
      IMAPServer => 'imap.example.com',
      IMAPUserName => 'user@example.com',
    );

    $iaf->IMAPSecureConnection(1);     # set boolean value
    $iaf->IMAPSecureConnection('yes'); # .. in another way

    $iaf->IMAPUserName(undef); # delete this field

    $iaf->SMTPAuthMethod(IAF_AM_USE_INCOMING); # handy constants

    $iaf->SMTPPort('hundred'); # dies (not a number)

    $iaf->NonExistent(); # dies (can't access nonexistent field)


=head1 DESCRIPTION

Allows to create SMTP, POP3, IMAP and HTTP email or NNTP news account configuration 
files, that can be imported by Microsoft Outlook Express/2000 clients.

Reverse operation is possible - all fields from such files can be decoded.


=head1 General Methods

=over 4

=item new([field => value])

Creates a new object and sets specified fields values.

=item read_iaf($buffer)

Reads binary data from the specified buffer and sets all decoded fields.

=item write_iaf($buffer)

Writes all fields as binary data into the specified buffer.

=item text_iaf($buffer[,$delimiter])

Writes 'name - value' pairs as text into the specified buffer.
Delimiter defaults to 'tab' character. Passwords are hidden with asterisks.

=back


=head1 Account Fields

=over 4

=item AccountName()

Account name displayed in list of accounts in Outlook or Outlook Express.

=item AccountID()

Unique ID of the account. Name of the registry key that stores the account settings.

=back


=head1 Connection Fields

=over 4

=item ConnectionType()

Connection type used by account. One of the L<IAF_CT_*|/"ConnectionType Values"> enumeration values.

=item ConnectionName()

Name of the dial-up account. This is used when ConnectionType() is set to L<IAF_CT_DIALUP|/"IAF_CT_DIALUP">.

=back


=head1 SMTP Fields

=over 4

=item SMTPServer()

SMTP server host name.

=item SMTPUserName()

User name used when connecting to SMTP server.

=item SMTPPassword()

Password used when connecting to SMTP server.

=item SMTPPasswordPrompt()

Prompt for password when logging on to SMTP server.

=item SMTPAuthMethod()

Authentication method required by SMTP server. One of the L<IAF_AM_*|"AuthMethod Values"> enumeration values.

=item SMTPPort()

SMTP server port.

=item SMTPSecureConnection()

Use secure connection (SSL) to the SMTP server.

=item SMTPTimeout()

Timeout in seconds for communication with SMTP server.

=item SMTPDisplayName()

Display name of the user. This is used as a name in 'From:' mail header.

=item SMTPOrganizationName()

Organization of the user. This is used in 'Organization:' mail header.

=item SMTPEmailAddress()

Sender email address. This is used as the email address in 'From:' mail header.

=item SMTPReplyToEmailAddress()

Reply To email address. This is used as the email address in 'Reply-To:' mail header.

=item SMTPSplitMessages()

Break apart messages.

=item SMTPSplitMessageSize()

Break apart messages larger than the size in KB.

=item SMTPSignature()

Registry key of the SMTP signature.

=back


=head1 POP3 Fields

=over 4

=item POP3Server()

POP3 server host name.

=item POP3UserName()

User name used when connecting to POP3 server.

=item POP3Password()

Password used when connecting to POP3 server.

=item POP3PasswordPrompt()

Prompt for password when logging on to POP3 server.

=item POP3AuthUseSPA()

Logon to POP3 server using Secure Password Authentication (SPA).

=item POP3Port()

POP3 server port.

=item POP3SecureConnection()

Use secure connection (SSL) to the POP3 server.

=item POP3Timeout()

Timeout in seconds for communication with POP3 server.

=item POP3LeaveMailOnServer()

Leave mail on POP3 server.

=item POP3RemoveWhenDeleted()

Remove messages from POP3 server when deleted from Deleted Items.

=item POP3RemoveWhenExpired()

Remove messages from POP3 server after a period of days.

=item POP3ExpireDays()

How many days to leave messages on POP3 server.

=item POP3SkipAccount()

Do not include this account when receiving mail or synchronizing.

=back


=head1 IMAP Fields

=over 4

=item IMAPServer()

IMAP server host name.

=item IMAPUserName()

User name used when connecting to IMAP server.

=item IMAPPassword()

Password used when connecting to IMAP server.

=item IMAPPasswordPrompt()

Prompt for password when connecting to IMAP server.

=item IMAPAuthUseSPA()

Logon to IMAP server using Secure Password Authentication (SPA).

=item IMAPPort()

IMAP server port.

=item IMAPSecureConnection()

Use secure connection (SSL) to the IMAP server.

=item IMAPTimeout()

Timeout in seconds for communication with IMAP server.

=item IMAPRootFolder()

Root folder path on IMAP server.

=item IMAPUseLSUB()

Use IMAP LSUB command.

=item IMAPPolling()

Include this account when receiving mail or synchronizing.

=item IMAPFullList()

=item IMAPStoreSpecialFolders()

Store special folders on IMAP server.

=item IMAPSentItemsFolder()

Sent Items folder path on IMAP server.

=item IMAPDraftsFolder()

Drafts folder path on IMAP server.

=item IMAPDirty()

=item IMAPPollAllFolders()

Check for new messages in all folders on IMAP server.

=back


=head1 HTTP Fields

=over 4

=item HTTPServer()

HTTPMail server url.

=item HTTPUserName()

User name used when connecting to HTTPMail server.

=item HTTPPassword()

Password used when connecting to HTTPMail server.

=item HTTPPasswordPrompt()

Prompt for password when connecting to HTTPMail server.

=item HTTPAuthUseSPA()

Logon to HTTPMail server using Secure Password Authentication (SPA).

=item HTTPFriendlyName()

=item HTTPPolling()

Include this account when receiving mail or synchronizing.

=back


=head1 NNTP Fields

=over 4

=item NNTPServer()

NNTP server host name.

=item NNTPUserName()

User name used when connecting to NNTP server.

=item NNTPPassword()

Password used when connecting to NNTP server.

=item NNTPPasswordPrompt()

Prompt for password when logging on to NNTP server.

=item NNTPAuthMethod()

Authentication method required by NNTP server. One of the L<IAF_AM_*|"AuthMethod Values"> enumeration values.

=item NNTPPort()

NNTP server port.

=item NNTPSecureConnection()

Use secure connection (SSL) to the NNTP server.

=item NNTPTimeout()

Timeout in seconds for communication with NNTP server.

=item NNTPDisplayName()

Display name of the user. This is used as a name in 'From:' message header.

=item NNTPOrganizationName()

Organization of the user. This is used in 'Organization:' message header.

=item NNTPEmailAddress()

Sender email address. This is used as the email address in 'From:' message header.

=item NNTPReplyToEmailAddress()

Reply To email address. This is used as the email address in 'Reply-To:' message header.

=item NNTPSplitMessages()

Break apart messages.

=item NNTPSplitMessageSize()

Break apart messages larger than the size in KB.

=item NNTPUseGroupDescriptions()

Use newsgroups descriptions when downloading newsgroups list from NNTP server.

=item NNTPPolling()

Include this account when receiving messages.

=item NNTPPostingFormat()

News posting format.

=item NNTPSignature()

Registry key of the NNTP signature.

=back


=head1 Misc Fields

=over 4

=item TemporaryAccount()

=item ConnectionFlags()

=item BackupConnectionName()

=item MakeAvailableOffline()

=item ServerReadOnly()

=item DomainIsMSN()

=item AdBarURL()

=item ShowAdBar()

=item MinPollingInterval()

=item GotPollingInterval()

=item LastPolledTime()

=back


=head1 Enumeration Values

=head2 ConnectionType Values

=over 4

=item IAF_CT_LAN

Connect using local network.

=item IAF_CT_DIALER

Connect using 3rd party dialer.

=item IAF_CT_DIALUP

Connect using dial-up account.

=item IAF_CT_IE_DEFAULT

Use IE connection setting.

=back


=head2 AuthMethod Values

=over 4

=item IAF_AM_NONE

SMTP server does not require authentication.

=item IAF_AM_SPA

Logon to SMTP server using name and Secure Password Authentication (SPA).

=item IAF_AM_USE_INCOMING

Logon to SMTP server using incoming mail server settings.

=item IAF_AM_PLAIN

Logon to SMTP server using name and plaintext password.

=back


=head2 PostingFormat Values

=over 4

=item IAF_PF_USE_OPTIONS

Use news sending format defined in program options.

=item IAF_PF_PLAIN

Ignore news sending format defined in program options and post using plain text.

=item IAF_PF_HTML

Ignore news sending format defined in program options and post using HTML.

=back


=head1 AUTHOR

Przemek Czerkas, C<< <pczerkas at gmail.com> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::Outlook::IAF

You can also look for information at:

=over 4


=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-Outlook-IAF>


=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-Outlook-IAF>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-Outlook-IAF>


=item * Search CPAN

L<http://search.cpan.org/dist/Win32-Outlook-IAF>

=back


=head1 BUGS

Please report any bugs or feature requests to C<bug-win32-outlook-iaf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Outlook-IAF>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2007 Przemek Czerkas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
