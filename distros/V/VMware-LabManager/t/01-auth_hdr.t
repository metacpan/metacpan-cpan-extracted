use strict;
use warnings;

use Test::More tests => 5;
use VMware::LabManager;

my $lm = VMware::LabManager->new('aivaturi','passwd','lm.acme.com', 'org');
my $auth_hdr = $lm->get_auth_header();

ok($auth_hdr->isa('SOAP::Header'), "auth_hdr is a right class" );
is(($auth_hdr->value)->{username}, 'aivaturi', "Testing returned username");
is(($auth_hdr->value)->{password}, 'passwd', "Testing returned password");
is(($auth_hdr->value)->{organizationname}, 'org', "Testing returned organization name");
is(($auth_hdr->attr)->{xmlns}, 'http://vmware.com/labmanager', "Testing returned xmlns");

