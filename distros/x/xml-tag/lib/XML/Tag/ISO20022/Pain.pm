package XML::Tag::ISO20022::Pain; 
use Exporter 'import';
use XML::Tag;
BEGIN {
    our @EXPORT = qw<
GrpHdr
MsgId
CstmrDrctDbtInitn
CstmrCdtTrfInitn
AdrLine
AmdmntInd
AmdmntInfDtls
BIC
Cd
Cd0rPrtry
Cdtr
CdtrAcct
CdtrAgt
CdtrReflnf
CdtrSchmeId
ChrgBr
CreDtTm
CtgyPurp
CtrlSum
Ctry
Dbtr
DbtrAcct
DbtrAgt
DrctDbtTx
DrctDbtTxInf
DtOfSgntr
EndToEndId
FinInstnId
IBAN
Id 
InitgPty
LclInstrm
InstdAmt
MndtId
MndtRltdInf
NbOfTxs
Nm
OrgId
OrgnlCdtrAgt
OrgnlCdtrAgtAcct
OrgnlCdtrSchmeId
OrgnlDbtr
OrgnlDbtrAcct
OrgnlDbtrAgt
OrgnlMndtId
Othr
PmtInf
PmtInfId
PmtId
PmtMtd
PmtTpInf
Prtry
PrvtId
PstlAdr
Purp
Ref
ReqdColltnDt
RmtInf
SchmeNm
SeqTp
Strd
SvcLvl
Tp
UltmtCdtr
UltmtDbtr
Ustrd
 
OrgnlDbtrAgtAcct
OrgnlFnlColltnDt
OrgnlFrqcy
ElctrncSgntr
FrstColltnDt
FnlColltnDt
Frqcy

>;
    ns '' => @EXPORT;
};

sub Document (&) {
    '<?xml version="1.0" encoding="UTF-8"?><Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.008.001.02" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
    , (shift)->()
    , '</Document>'
} 

sub Document4 (&) {
    '<?xml version="1.0" encoding="UTF-8"?><Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.008.001.04" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
    , (shift)->()
    , '</Document>'
}

1;
