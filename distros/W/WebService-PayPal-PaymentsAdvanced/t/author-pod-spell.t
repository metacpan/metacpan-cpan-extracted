
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::PodSpelling 2.007005
use Test::Spelling 0.12;
use Pod::Wordlist;


add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( bin lib ) );
__DATA__
AKA
AVS
Alders
Alders'
Andy
Authentication
Authorization
BAID
CORRELATIONID
Capture
Chelluri
ClassFor
Credit
CreditCard
Dave
Eilam
Eilam's
Error
Fowler
FromHTTP
FromRedirect
FromSilentPOST
Generic
Greg
HTTP
HasCreditCard
HasHTTPResponse
HasMessage
HasParams
HasPayPal
HasTender
HasTokens
HasTransactionTime
HasUA
Helper
HostedForm
Hunter
INSTANTIATION
IPVerification
Inc
Inquiry
Jack
Mark
Mateu
MaxMind
MaxMind's
Mocker
Mojo
Narsimham
ORIGID
Olaf
Oschwald
Oschwald's
PNREF
PPA
PayPal
Payflow
PayflowLink
PayflowPro
PaymentsAdvanced
RESPMSG
Response
Role
Rolsky
Rolsky's
SECURETOKEN
SECURETOKENID
Sale
SecureToken
SilentPOST
Storey
TRANSTIME
UserAgent
Void
WebService
William
ajack
app
apps
baid
bin
correlationid
drolsky
goschwald
iframe
lib
mark
mhunter
mock
nchelluri
oalders
olaf
param
params
payflow
plack
pnref
ppref
sandbox
settable
transtime
ua
website
wstorey
