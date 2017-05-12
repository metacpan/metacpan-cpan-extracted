package Win32::ADO;
use strict;

BEGIN {
	use Exporter ();
	use vars		qw( @ISA @EXPORT @EXPORT_OK $VERSION );
	@ISA		=	qw(Exporter);
	@EXPORT_OK	=	qw(CheckDBErrors QuoteString);
	@EXPORT		=	qw(	adOpenForwardOnly
						adOpenKeyset
						adOpenDynamic
						adOpenStatic
						adHoldRecords
						adMovePrevious
						adAddNew
						adDelete
						adUpdate
						adBookmark
						adApproxPosition
						adUpdateBatch
						adResync
						adLockReadOnly
						adLockPessimistic
						adLockOptimistic
						adLockBatchOptimistic
						adUseClient
						adUseServer
						adUseClientBatch
						adEmpty
						adTinyInt
						adSmallInt
						adInteger
						adBigInt
						adUnsignedTinyInt
						adUnsignedSmallInt
						adUnsignedInt
						adUnsignedBigInt
						adSingle
						adDouble
						adCurrency
						adDecimal
						adNumeric
						adBoolean
						adError
						adUserDefined
						adVariant
						adIDispatch
						adIUnknown
						adGUID
						adDate
						adDBDate
						adDBTime
						adDBTimeStamp
						adBSTR
						adChar
						adVarChar
						adLongVarChar
						adWChar
						adVarWChar
						adLongVarWChar
						adBinary
						adVarBinary
						adLongVarBinary
						adPromptAlways
						adPromptComplete
						adPromptCompleteRequired
						adPromptNever
						adModeUnknown
						adModeRead
						adModeWrite
						adModeReadWrite
						adModeShareDenyRead
						adModeShareDenyWrite
						adModeShareExclusive
						adModeShareDenyNone
						adXactUnspecified
						adXactChaos
						adXactReadUncommitted
						adXactBrowse
						adXactCursorStability
						adXactReadCommitted
						adXactRepeatableRead
						adXactSerializable
						adXactIsolated
						adXactPollAsync
						adXactPollSyncPhaseOne
						adXactCommitRetaining
						adXactAbortRetaining
						adXactAbortAsync
						adFldBookmark
						adFldMayDefer
						adFldUpdatable
						adFldUnknownUpdatable
						adFldFixed
						adFldIsNullable
						adFldMayBeNull
						adFldLong
						adFldRowID
						adFldRowVersion
						adFldCacheDeferred
						adEditNone
						adEditInProgress
						adEditAdd
						adRecOK
						adRecNew
						adRecModified
						adRecDeleted
						adRecUnmodified
						adRecInvalid
						adRecMultipleChanges
						adRecPendingChanges
						adRecCanceled
						adRecCantRelease
						adRecConcurrencyViolation
						adRecIntegrityViolation
						adRecMaxChangesExceeded
						adRecObjectOpen
						adRecOutOfMemory
						adRecPermissionDenied
						adRecSchemaViolation
						adRecDBDeleted
						adGetRowsRest
						adPosUnknown
						adPosBOF
						adPosEOF
						adAffectCurrent
						adAffectGroup
						adAffectAll
						adFilterNone
						adFilterPendingRecords
						adFilterAffectedRecords
						adFilterFetchedRecords
						adPropNotSupported
						adPropRequired
						adPropOptional
						adPropRead
						adPropWrite
						adErrInvalidArgument
						adErrNoCurrentRecord
						adErrIllegalOperation
						adErrInTransaction
						adErrFeatureNotAvailable
						adErrItemNotFound
						adErrObjectNotSet
						adErrDataConversion
						adErrObjectClosed
						adErrObjectOpen
						adErrProviderNotFound
						adErrBoundToCommand
						adParamSigned
						adParamNullable
						adParamLong
						adParamUnknown
						adParamInput
						adParamOutput
						adParamInputOutput
						adParamReturnValue
						adCmdUnknown
						adCmdText
						adCmdTable
						adCmdStoredProc
						);
	$VERSION = '0.03';
}

##---- CursorTypeEnum Values ----
sub adOpenForwardOnly { 0 }
sub adOpenKeyset { 1 }
sub adOpenDynamic { 2 }
sub adOpenStatic { 3 }

##---- CursorOptionEnum Values ----
sub adHoldRecords { 0x00000100 }
sub adMovePrevious { 0x00000200 }
sub adAddNew { 0x01000400 }
sub adDelete { 0x01000800 }
sub adUpdate { 0x01008000 }
sub adBookmark { 0x00002000 }
sub adApproxPosition { 0x00004000 }
sub adUpdateBatch { 0x00010000 }
sub adResync { 0x00020000 }

##---- LockTypeEnum Values ----
sub adLockReadOnly { 1 }
sub adLockPessimistic { 2 }
sub adLockOptimistic { 3 }
sub adLockBatchOptimistic { 4 }

##---- CursorLocationEnum Values ----
sub adUseClient { 1 }
sub adUseServer { 2 }
sub adUseClientBatch { 3 }

##---- DataTypeEnum Values ----
sub adEmpty { 0 }
sub adTinyInt { 16 }
sub adSmallInt { 2 }
sub adInteger { 3 }
sub adBigInt { 20 }
sub adUnsignedTinyInt { 17 }
sub adUnsignedSmallInt { 18 }
sub adUnsignedInt { 19 }
sub adUnsignedBigInt { 21 }
sub adSingle { 4 }
sub adDouble { 5 }
sub adCurrency { 6 }
sub adDecimal { 14 }
sub adNumeric { 131 }
sub adBoolean { 11 }
sub adError { 10 }
sub adUserDefined { 132 }
sub adVariant { 12 }
sub adIDispatch { 9 }
sub adIUnknown { 13 }
sub adGUID { 72 }
sub adDate { 7 }
sub adDBDate { 133 }
sub adDBTime { 134 }
sub adDBTimeStamp { 135 }
sub adBSTR { 8 }
sub adChar { 129 }
sub adVarChar { 200 }
sub adLongVarChar { 201 }
sub adWChar { 130 }
sub adVarWChar { 202 }
sub adLongVarWChar { 203 }
sub adBinary { 128 }
sub adVarBinary { 204 }
sub adLongVarBinary { 205 }

##---- ConnectPromptEnum Values ----
sub adPromptAlways { 1 }
sub adPromptComplete { 2 }
sub adPromptCompleteRequired { 3 }
sub adPromptNever { 4 }

##---- ConnectModeEnum Values ----
sub adModeUnknown { 0 }
sub adModeRead { 1 }
sub adModeWrite { 2 }
sub adModeReadWrite { 3 }
sub adModeShareDenyRead { 4 }
sub adModeShareDenyWrite { 8 }
sub adModeShareExclusive { 0xc }
sub adModeShareDenyNone { 0x10 }

##---- IsolationLevelEnum Values ----
sub adXactUnspecified { 0xffffffff }
sub adXactChaos { 0x00000010 }
sub adXactReadUncommitted { 0x00000100 }
sub adXactBrowse { 0x00000100 }
sub adXactCursorStability { 0x00001000 }
sub adXactReadCommitted { 0x00001000 }
sub adXactRepeatableRead { 0x00010000 }
sub adXactSerializable { 0x00100000 }
sub adXactIsolated { 0x00100000 }

##---- XactAttributeEnum Values ----
sub adXactPollAsync { 2 }
sub adXactPollSyncPhaseOne { 4 }
sub adXactCommitRetaining { 0x00020000 }
sub adXactAbortRetaining { 0x00040000 }
sub adXactAbortAsync { 0x00080000 }

##---- FieldAttributeEnum Values ----
sub adFldBookmark { 0x00000001 }
sub adFldMayDefer { 0x00000002 }
sub adFldUpdatable { 0x00000004 }
sub adFldUnknownUpdatable { 0x00000008 }
sub adFldFixed { 0x00000010 }
sub adFldIsNullable { 0x00000020 }
sub adFldMayBeNull { 0x00000040 }
sub adFldLong { 0x00000080 }
sub adFldRowID { 0x00000100 }
sub adFldRowVersion { 0x00000200 }
sub adFldCacheDeferred { 0x00001000 }

##---- EditModeEnum Values ----
sub adEditNone { 0x0000 }
sub adEditInProgress { 0x0001 }
sub adEditAdd { 0x0002 }

##---- RecordStatusEnum Values ----
sub adRecOK { 0x0000000 }
sub adRecNew { 0x0000001 }
sub adRecModified { 0x0000002 }
sub adRecDeleted { 0x0000004 }
sub adRecUnmodified { 0x0000008 }
sub adRecInvalid { 0x0000010 }
sub adRecMultipleChanges { 0x0000040 }
sub adRecPendingChanges { 0x0000080 }
sub adRecCanceled { 0x0000100 }
sub adRecCantRelease { 0x0000400 }
sub adRecConcurrencyViolation { 0x0000800 }
sub adRecIntegrityViolation { 0x0001000 }
sub adRecMaxChangesExceeded { 0x0002000 }
sub adRecObjectOpen { 0x0004000 }
sub adRecOutOfMemory { 0x0008000 }
sub adRecPermissionDenied { 0x0010000 }
sub adRecSchemaViolation { 0x0020000 }
sub adRecDBDeleted { 0x0040000 }

##---- GetRowsOptionEnum Values ----
sub adGetRowsRest { -1 }

##---- PositionEnum Values ----
sub adPosUnknown { -1 }
sub adPosBOF { -2 }
sub adPosEOF { -3 }

##---- AffectEnum Values ----
sub adAffectCurrent { 1 }
sub adAffectGroup { 2 }
sub adAffectAll { 3 }

##---- FilterGroupEnum Values ----
sub adFilterNone { 0 }
sub adFilterPendingRecords { 1 }
sub adFilterAffectedRecords { 2 }
sub adFilterFetchedRecords { 3 }

##---- PropertyAttributesEnum Values ----
sub adPropNotSupported { 0x0000 }
sub adPropRequired { 0x0001 }
sub adPropOptional { 0x0002 }
sub adPropRead { 0x0200 }
sub adPropWrite { 0x0400 }

##---- ErrorValueEnum Values ----
sub adErrInvalidArgument { 0xbb9 }
sub adErrNoCurrentRecord { 0xbcd }
sub adErrIllegalOperation { 0xc93 }
sub adErrInTransaction { 0xcae }
sub adErrFeatureNotAvailable { 0xcb3 }
sub adErrItemNotFound { 0xcc1 }
sub adErrObjectNotSet { 0xd5c }
sub adErrDataConversion { 0xd5d }
sub adErrObjectClosed { 0xe78 }
sub adErrObjectOpen { 0xe79 }
sub adErrProviderNotFound { 0xe7a }
sub adErrBoundToCommand { 0xe7b }

##---- ParameterAttributesEnum Values ----
sub adParamSigned { 0x0010 }
sub adParamNullable { 0x0040 }
sub adParamLong { 0x0080 }

##---- ParameterDirectionEnum Values ----
sub adParamUnknown { 0x0000 }
sub adParamInput { 0x0001 }
sub adParamOutput { 0x0002 }
sub adParamInputOutput { 0x0003 }
sub adParamReturnValue { 0x0004 }

##---- CommandTypeEnum Values ----
sub adCmdUnknown { 0 }
sub adCmdText { 0x0001 }
sub adCmdTable { 0x0002 }
sub adCmdStoredProc { 0x0004 }

sub QuoteString {
	my $sql = shift;
	$sql =~ s/\'/\'\'/g;
	return $sql;
}

sub CheckDBErrors {
	my $Conn = shift;
	my $arrayref = shift;
	my $Errors = $Conn->Errors();
	my $error;
	my $NumErrors = 0;
	foreach $error (in $Errors) {
		next if $error->{Number} == 0; # Skip warnings
		$NumErrors++;
		push @{$arrayref}, "Error: [" .
			$error->{Number} . "] " . $error->{Description} . "\n";
	}
	$Errors->Clear;
	return $NumErrors == 0 ? 1 : 0;
}

1;

__END__

=head1 NAME

Win32::ADO - ADO Constants and a couple of helper functions

=head1 SYNOPSIS

	use Win32::ADO qw/CheckDBErrors/;

=head1 DESCRIPTION

Not much to say. Simply provides all the ADO constants for your use, like in
VBScript (or JavaScript). This module is really deprecated in favour of
Win32::OLE::Const, and the proper ADO constants. Use that with the following
syntax:

	use Win32::OLE::Const;
	my $name = "Microsoft ActiveX Data Objects 2\\.0 Library";
	$ado_consts = Win32::OLE::Const->Load($name)
	|| die "Unable to load Win32::OLE::Const ``$name'' ".Win32::OLE->LastError;

And then use $ado_consts as a hash ref with the keys being the constant names.

Also contains CheckDBErrors, for doing ADO error checking. Pass it the
connection object and an empty array ref, as follows:

	CheckDBErrors($Conn, \@DBErrors) or die @DBErrors;

Have fun...

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=cut
