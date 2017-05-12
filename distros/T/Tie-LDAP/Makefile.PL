# -*- mode: perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(PREREQ_PM    => { 'Net::LDAPapi' => 0 },
              NAME         => 'Tie::LDAP',
              VERSION_FROM => 'LDAP.pm',
              DIR          => ['Entry'],
);
