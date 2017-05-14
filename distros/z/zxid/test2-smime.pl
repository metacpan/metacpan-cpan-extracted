#!/usr/bin/perl
# 10.10.1999, Sampo Kellomaki <sampo@iki.fi>
#
# Test SMIMEUtil module

use Data::Dumper;
use SMIMEUtil;

$foo = SMIMEUtil::base64(1, "foo bar bash", 12);
print $foo, '-->', SMIMEUtil::base64(0, $foo, length($foo));

$r = rand;
print SMIMEUtil::smime_init("rand.txt", $r, length($r)), "\n";
print SMIMEUtil::smime_get_errors(), "\n";
print SMIMEUtil::smime_hex("abc", 3), "\n";
print SMIMEUtil::smime_dotted_hex("abc", 3), "\n";

$data = "abasasdasdsadsadsadsadsadsadsadasdsadc";
$md = SMIMEUtil::smime_md5($data);
print SMIMEUtil::smime_hex($md, length($md)), "\n";

$req = <<REQ
-----BEGIN CERTIFICATE REQUEST-----
MIIB4DCCAUkCAQAwgZAxCzAJBgNVBAYTAlBUMScwJQYDVQQKEx5Vbml2ZXJzaWRh
ZGUgVGVjbmljYSBkZSBMaXNib2ExHzAdBgNVBAsTFklTVCwgZW5nZW5oYXJpYSBz
b2NpYWwxFzAVBgNVBAMTDlNpbWFvIEZlcnJlaXJhMR4wHAYJKoZIhvcNAQkBFg90
ZXN0QGlzdC51dGwucHQwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALT4cW6F
9GLLFW/Xal1pmZqTUSR1v/8CIwAh/2iYOLOINhqIgkyxLouSmnpLvX/q14XPKmLi
BJ8AUED0HDxOLId5Nf2Akl9g+7y95tjBsQ9s/KwYKi+HfUEEAz8vK014X5XiKwyw
urclQsb6xYj8lFq4xiBP92FRJWl37PlttsObAgMBAAGgDzANBgNVBA0xBhMEdDEw
ADANBgkqhkiG9w0BAQQFAAOBgQB1fH+BKnqi3WXWL61NfkLY3ZhFvyhiuM95pihT
3/HnKZsaoMLWWurSG7qzTZY0kZPGkbtHOfLqgf5tWVdeNcR7OAiUrz3xGvKlOfer
LYDjzZLvDHO18U+Ihq6J/HPM+rcnqc5ZhmiS7Dj2AoWJg0Ol8wMnRjh6V+sQN9gw
9Vd0HA==
-----END CERTIFICATE REQUEST-----
REQ
    ;

print SMIMEUtil::smime_get_req_name($req), "\n";
print SMIMEUtil::smime_get_req_attr($req);
print SMIMEUtil::smime_get_req_modulus($req), "\n";
print SMIMEUtil::smime_get_req_hash($req), "\n";

$pubcrt = <<CERT;
-----BEGIN CERTIFICATE-----
MIIC6zCCAlSgAwIBAgIBADANBgkqhkiG9w0BAQQFADBcMQswCQYDVQQGEwJQVDEM
MAoGA1UEChMDVVRMMQwwCgYDVQQLEwNJU1QxFDASBgNVBAMTC0pvcmdlIEFsdmVz
MRswGQYJKoZIhvcNAQkBFgx0MTdAdGVzdC5jb20wHhcNOTkxMDEwMTI1NDMwWhcN
MDAxMDA5MTI1NDMwWjBcMQswCQYDVQQGEwJQVDEMMAoGA1UEChMDVVRMMQwwCgYD
VQQLEwNJU1QxFDASBgNVBAMTC0pvcmdlIEFsdmVzMRswGQYJKoZIhvcNAQkBFgx0
MTdAdGVzdC5jb20wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAOq1xmjzxEqT
P37MO5SOvomZsQgemk0QcdIFDhtGWH8GkyzLwjLjod05MXBnEmAg7iL22tDo/Nt0
/s2FGG5Lggp2lrlBUlDJfFbMP9eFT1A/1EJzMtUAhwHfdY1OBwtXP+bgV8sellbd
H6VA1+duGIiAlgP0Y5Lj+ILJHc0cq33NAgMBAAGjgbwwgbkwDwYDVR0TBAgwBgEB
/wIBAzARBglghkgBhvhCAQEEBAMCAPcwCwYDVR0PBAQDAgH+MIGFBglghkgBhvhC
AQ0EeBZ2U2VsZiBzaWduZWQgY2VydCBmb3IgdGVtcG9yYXJ5IHNpZ25pbmcgaW4g
TUNUIHByb2plY3QuIENvbnRhY3QgU2FtcG8gS2VsbG9tYWtpIDxzYW1wb0Bpa2ku
Zmk+IGZvciBmdXJ0aGVyIGluZm9ybWF0aW9uLjANBgkqhkiG9w0BAQQFAAOBgQCa
GZ3JNH5UIyipRFqeNLyO8Ye85jIK6R7qKJDmS1qjVJ2fjqVarvVo3ZfbLHBqg3UT
yiU9e3J1em7MaCZD8Kx/YpN3R8dZnd5F7pynxtEypjWAQLM87PbyaVAJdv/jcSaw
n9LiLt7ZMTpeQCgd2x8VYC4LXQ/l2lbtdMS0QoAmrg==
-----END CERTIFICATE-----
CERT
    ;

$sig = <<SIG
Content-type: application/x-pkcs7-mime; name="smime.p7m"
Content-transfer-encoding: base64
Content-Disposition: attachment; filename="smime.p7m"

MIAGCSqGSIb3DQEHAqCAMIIEPQIBATEJMAcGBSsOAwIaMIAGCSqGSIb3DQEHAaCA
BIICrkNvbnRlbnQtdHlwZTogdGV4dC9wbGFpbg0KDQpET0NfSUQ9MTIxMzEyNDMy
NQ0KRE9DX01ENV9IQVNIPTFFM0Y4OTFBMUUzRjg5MUExRTNGODkxQTFFM0Y4OTFB
DQpET0NfU1RBVFVTPTAwMTogZGVjaWZyYWRvIE9LLCBhY2VpdGUgcGFyYSBmaWxh
IGRlIHByb2Nlc3NhbWVudG8NCkRPQ19BQ0NFUFRfVElNRVNUQU1QPTE5OTkxMDEy
MTYwMzEyDQoNClJlY2libw0KDQpGb2kgYWNlaXRlLCBwZWxhIHNpc3RlbWEgU2Fw
aWVucywgcGFyYSBwcm9jZXNzYW1lbnRvIG8gZG9jdW1lbnRvIGN1amENCmNvbnRl
dWRvIOkgc3VtbWFyaXphZG8gZW0gRE9DX01ENV9IQVNILiBPIGRvY3VtZW50byBm
b2kgYXRyaWJ1aWRvIG8NCm76bWVybyBkZSBwcm9jZXNzYW1lbnRvIGluZGljYWRv
IHBlbG8gRE9DX0lELiBBIGRhdGEg6SBob3JhIGRlDQpyZWNlcOfjbyBz428gaW5k
aWNhZG9zIHBlbG8gRE9DX0FDQ0VQVF9USU1FU1RBTVAsIGlzdG8g6SAxMiBkZSBP
dXR1YnJvDQpkZSAxOTk5LCAxNjowMzoxMi4NCg0KRXN0ZSByZWNpYm8gc2VydmUg
Y29tbyBwcm92YSBkZSBlbnRyZWdhIGRlIGRvY3VtZW50byBwYXJhIGNvbmN1cnNv
IFhYWCwgdW1hDQp2ZXogcXVlIG8gRE9DX0FDQ0VQVF9USU1FU1RBTVAg6SBhbnRl
cmlvciBhbyBob3JhIGRvIGZlY2hvIHD6YmxpY2Fkby4NCg0KLS0gTyBFc2NyaXbj
byBFbGVjdHLzbmljbyAtLQ0KAAAAADGCAWYwggFiAgEBMGEwXDELMAkGA1UEBhMC
UFQxDDAKBgNVBAoTA1VUTDEMMAoGA1UECxMDSVNUMRQwEgYDVQQDEwtKb3JnZSBB
bHZlczEbMBkGCSqGSIb3DQEJARYMdDE3QHRlc3QuY29tAgEAMAkGBSsOAwIaBQCg
XTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw05OTEw
MTIwNTUxMjlaMCMGCSqGSIb3DQEJBDEWBBT6eHDBAtDrb2tEQ0bO3jmsTbwpTDAN
BgkqhkiG9w0BAQEFAASBgHdpDYfmbzyk9f/A2UuTEEAPwbBbvMmLtlcrcF56t40T
sHCtL7AQBsaFuVdPDe1Ih5Qn0bmfW8Rheqi3mOplC6s/qrf+1gUyptJZHn6Q3Vog
t8xQzu7DUMUgSXNLoGk+P3txbwWfqZ6bWOoTvuuxgPDfiEjd+yKPshTODDNUffDI
AAAAAA==
SIG
    ;

print "------- verify sig\n";
$res = SMIMEUtil::smime_verify_signature($pubcrt, $sig, '', 0), "\n";
print Dumper($res);

$mime = "Content-type: text/plain\r\n\r\nfoo";

$id = <<KEY_AND_CERT;
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,1D7ADC69F74A221B

oaEYtg5HRsEJ6nuA6Y97u66udgxzgB9qcPMkOantl0yH3kQoih9DKJhu5tUmeSXE
PN4P7O/1K0JMuwEzRm6HKiyPQZaXzdG+Mgpg6WhkaeVOFREmBSjweHGf4vMd8NLn
e8exKvhHeJTOM6gM78KJZ8KYqNOe3IHH49Eoq4WTfPQHi9FCT4aujjSy32ctkeHZ
LJnnHXaW5gjTfRmOML2HpJ6y6uzmT2FomQA9mrtR+Q1WLq4ms54ESaC5x5286qBh
XnqMZFclTEcnyv3O95X0ZxG5IXwZtBWZy018TxryxqAhAhcl87k6fPRwaRsJi6zD
/Vzr7VI7Wu9rNtxvQNBqvWqGH8KF80qPmUiNnUSE+kk+jiR5PylDLM90DfLRHElI
E8nGvqUk3bgLujeYR/89Mx9s4orSMbWmPUROFKTA+8p9Ni2wDutIyotYGI6e+amu
D38N/+NaKPn2OZfDvZUnDJ5bakYAuSX8M8QtP8B99m1ul2zLUL23a5hcKxS9DiyJ
vI80V3ingIGLIR+kk/waEVpRaPuPn/wtqOKVlt0g8977LyNFOisEWxLwEafQA9w3
9wVt5JzRowZWI33dq3lza368seJVMPtmZ5u+fFrWKEy+wLnfThdgdrs97ruJOTxM
w6kkEjsKzXyWKJqXEPy/vEWDJRBQHmX0s8ENC6N7+yeS0Z3dppD/uuqO8NCX0nUk
dNAldivL2vBBf/jDscyePyP1/FmkbRj+Uw22H1ApO2GXTEgez1E6h8kQ9wXZtVvn
8VOsXj6nT+M8rNpHmu33WwkKl6jr0g+W/BUiQTgUsKYjxtPcncjQKg==
-----END RSA PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIIC6zCCAlSgAwIBAgIBADANBgkqhkiG9w0BAQQFADBcMQswCQYDVQQGEwJQVDEM
MAoGA1UEChMDVVRMMQwwCgYDVQQLEwNJU1QxFDASBgNVBAMTC0pvcmdlIEFsdmVz
MRswGQYJKoZIhvcNAQkBFgx0MTdAdGVzdC5jb20wHhcNOTkxMDEwMTI1NDMwWhcN
MDAxMDA5MTI1NDMwWjBcMQswCQYDVQQGEwJQVDEMMAoGA1UEChMDVVRMMQwwCgYD
VQQLEwNJU1QxFDASBgNVBAMTC0pvcmdlIEFsdmVzMRswGQYJKoZIhvcNAQkBFgx0
MTdAdGVzdC5jb20wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAOq1xmjzxEqT
P37MO5SOvomZsQgemk0QcdIFDhtGWH8GkyzLwjLjod05MXBnEmAg7iL22tDo/Nt0
/s2FGG5Lggp2lrlBUlDJfFbMP9eFT1A/1EJzMtUAhwHfdY1OBwtXP+bgV8sellbd
H6VA1+duGIiAlgP0Y5Lj+ILJHc0cq33NAgMBAAGjgbwwgbkwDwYDVR0TBAgwBgEB
/wIBAzARBglghkgBhvhCAQEEBAMCAPcwCwYDVR0PBAQDAgH+MIGFBglghkgBhvhC
AQ0EeBZ2U2VsZiBzaWduZWQgY2VydCBmb3IgdGVtcG9yYXJ5IHNpZ25pbmcgaW4g
TUNUIHByb2plY3QuIENvbnRhY3QgU2FtcG8gS2VsbG9tYWtpIDxzYW1wb0Bpa2ku
Zmk+IGZvciBmdXJ0aGVyIGluZm9ybWF0aW9uLjANBgkqhkiG9w0BAQQFAAOBgQCa
GZ3JNH5UIyipRFqeNLyO8Ye85jIK6R7qKJDmS1qjVJ2fjqVarvVo3ZfbLHBqg3UT
yiU9e3J1em7MaCZD8Kx/YpN3R8dZnd5F7pynxtEypjWAQLM87PbyaVAJdv/jcSaw
n9LiLt7ZMTpeQCgd2x8VYC4LXQ/l2lbtdMS0QoAmrg==
-----END CERTIFICATE-----
KEY_AND_CERT
    ;

print "------- encrypt\n";
$enc = SMIMEUtil::smime_encrypt($pubcrt, $mime);
print $enc, "\n";

print "------- decrypt\n";
($len, $plain) = SMIMEUtil::smime_decrypt($id, 'secret', $enc);
print $plain, "\n";

$enc2 =<<ENC2;
Content-type: application/x-pkcs7-mime; name="smime.p7m"
Content-transfer-encoding: base64
Content-Disposition: attachment; filename="smime.p7m"

MIAGCSqGSIb3DQEHA6CAMIIBTgIBADGB+zCB+AIBADBhMFwxCzAJBgNVBAYTAlBU
MQwwCgYDVQQKEwNVVEwxDDAKBgNVBAsTA0lTVDEUMBIGA1UEAxMLSm9yZ2UgQWx2
ZXMxGzAZBgkqhkiG9w0BCQEWDHQxN0B0ZXN0LmNvbQIBADANBgkqhkiG9w0BAQEF
AASBgDld1yR7Ni9Hr7az4LuyJ9nNEbGD3pdHbZmE7UEM6odIr93rOcw4kXQscbfv
sloFJ2FdG3uB3YWby+JWwotEEwC68YEhWXUD1Vx2SZUXMgcJfoULJ0rIdXx4CLDV
D2zANqXbtEVM58WQ8ih1NMPRbg6MGCPH5PNSYrJ4GYplKYsFMEsGCSqGSIb3DQEH
BjAUBggqhkiG9w0DBwQIhoT5ut6S4JmAKJt3y00IQBvi6dPFdRfMSXmjOP83R5kg
/g2ZcaqAaeu7kRR2vlD1xB8AAAAA
ENC2
    ;

print "------- decrypt2\n";
($len, $plain) = SMIMEUtil::smime_decrypt($id, 'secret', $enc2);
print $plain, "\n";

print "-------- sign\n";
$s = SMIMEUtil::smime_sign($id, 'secret', $mime);
print $s, "\n";

print "-------- ... and verify\n";
$res = SMIMEUtil::smime_verify_signature($pubcrt,$s, '', 0), "\n";
print Dumper($res);

print "-------- clear sig\n";
$clear_sig = SMIMEUtil::smime_clear_sign($id, 'secret', $mime);
print $clear_sig, "\n";

print "-------- verify clear sig\n";

#$mime .= 'aa';
$res = SMIMEUtil::smime_verify_signature($pubcrt, $clear_sig,
					 $mime, length($mime)), "\n";

print Dumper($res);

print "Done.\n";

#EOF
