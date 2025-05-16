use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use URN::OASIS::SAML2 qw(:nameid);
my %nameids = (
                unspecified                 => 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified',
                emailAddress                => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
                X509SubjectName             => 'urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName',
                WindowsDomainQualifiedName  => 'urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName',
                kerberos                    => 'urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos',
                entity                      => 'urn:oasis:names:tc:SAML:2.0:nameid-format:entity',
                persistent                  => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                transient                   => 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
            );

is(NAMEID_UNSPECIFIED, $nameids{unspecified}, "unspecified nameid matches");
is(NAMEID_EMAIL, $nameids{emailAddress}, "emailAddress nameid matches");
is(NAMEID_X509_SUBJECT_NAME, $nameids{X509SubjectName}, "X509SubjectName nameid matches");
is(NAMEID_WINDOWS_DOMAIN_QUALIFIED_NAME, $nameids{WindowsDomainQualifiedName}, "WindowsDomainQualifiedName nameid matches");
is(NAMEID_KERBEROS, $nameids{kerberos}, "kerberos nameid matches");
is(NAMEID_ENTITY, $nameids{entity}, "entity nameid matches");
is(NAMEID_PERSISTENT, $nameids{persistent}, "persistent nameid matches");
is(NAMEID_TRANSIENT, $nameids{transient}, "transient nameid matches");
done_testing;
