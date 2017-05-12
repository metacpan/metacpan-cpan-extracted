
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/eNom.pm',
    'lib/WWW/eNom.pm',
    'lib/WWW/eNom/Contact.pm',
    'lib/WWW/eNom/Domain.pm',
    'lib/WWW/eNom/DomainAvailability.pm',
    'lib/WWW/eNom/DomainRequest/Registration.pm',
    'lib/WWW/eNom/DomainRequest/Transfer.pm',
    'lib/WWW/eNom/DomainTransfer.pm',
    'lib/WWW/eNom/IRTPDetail.pm',
    'lib/WWW/eNom/PhoneNumber.pm',
    'lib/WWW/eNom/PrivateNameServer.pm',
    'lib/WWW/eNom/Role/Command.pm',
    'lib/WWW/eNom/Role/Command/Contact.pm',
    'lib/WWW/eNom/Role/Command/Domain.pm',
    'lib/WWW/eNom/Role/Command/Domain/Availability.pm',
    'lib/WWW/eNom/Role/Command/Domain/PrivateNameServer.pm',
    'lib/WWW/eNom/Role/Command/Domain/Registration.pm',
    'lib/WWW/eNom/Role/Command/Domain/Transfer.pm',
    'lib/WWW/eNom/Role/Command/Raw.pm',
    'lib/WWW/eNom/Role/Command/Service.pm',
    'lib/WWW/eNom/Role/ParseDomain.pm',
    'lib/WWW/eNom/Types.pm'
);

notabs_ok($_) foreach @files;
done_testing;
