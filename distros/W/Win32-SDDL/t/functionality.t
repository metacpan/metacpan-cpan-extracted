use strict;
use warnings;
use Test::More tests => 3;

use Win32::SDDL;

ok ( my $sddl = Win32::SDDL->new('service'), 'create a SDDL object for service SDDLs' );

ok ( $sddl->Import( 'D:(A;;CCLCSWLOCRRC;;;AU)' ), 'import SDDL string  D:(A;;CCLCSWLOCRRC;;;AU)');

is_deeply( $sddl->{ACL}[0],
                {
                      'ObjectType' => '',
                      'Flags' => [],
                      'Type' => 'ACCESS_ALLOWED',
                      'AccessMask' => [
                                        'Query Configuration',
                                        'Query State',
                                        'Enumerate Dependencies',
                                        'Interrogate',
                                        'User Defined',
                                        'Read Control'
                                      ],
                      '_perms' => 'CCLCSWLOCRRC',
                      '_flags' => '',
                      'InheritedObjectType' => '',
                      'Trustee' => 'Authenticated Users'
                }
          , 'processing of D:(A;;CCLCSWLOCRRC;;;AU) gave the expected ACL structure'  )  ;

