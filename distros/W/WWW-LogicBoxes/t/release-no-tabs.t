
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
    'lib/WWW/LogicBoxes.pm',
    'lib/WWW/LogicBoxes/Contact.pm',
    'lib/WWW/LogicBoxes/Contact/CA.pm',
    'lib/WWW/LogicBoxes/Contact/CA/Agreement.pm',
    'lib/WWW/LogicBoxes/Contact/Factory.pm',
    'lib/WWW/LogicBoxes/Contact/US.pm',
    'lib/WWW/LogicBoxes/Customer.pm',
    'lib/WWW/LogicBoxes/Domain.pm',
    'lib/WWW/LogicBoxes/Domain/Factory.pm',
    'lib/WWW/LogicBoxes/DomainAvailability.pm',
    'lib/WWW/LogicBoxes/DomainRequest.pm',
    'lib/WWW/LogicBoxes/DomainRequest/Registration.pm',
    'lib/WWW/LogicBoxes/DomainRequest/Transfer.pm',
    'lib/WWW/LogicBoxes/DomainTransfer.pm',
    'lib/WWW/LogicBoxes/IRTPDetail.pm',
    'lib/WWW/LogicBoxes/PhoneNumber.pm',
    'lib/WWW/LogicBoxes/PrivateNameServer.pm',
    'lib/WWW/LogicBoxes/Role/Command.pm',
    'lib/WWW/LogicBoxes/Role/Command/Contact.pm',
    'lib/WWW/LogicBoxes/Role/Command/Customer.pm',
    'lib/WWW/LogicBoxes/Role/Command/Domain.pm',
    'lib/WWW/LogicBoxes/Role/Command/Domain/Availability.pm',
    'lib/WWW/LogicBoxes/Role/Command/Domain/PrivateNameServer.pm',
    'lib/WWW/LogicBoxes/Role/Command/Domain/Registration.pm',
    'lib/WWW/LogicBoxes/Role/Command/Domain/Transfer.pm',
    'lib/WWW/LogicBoxes/Role/Command/Raw.pm',
    'lib/WWW/LogicBoxes/Types.pm'
);

notabs_ok($_) foreach @files;
done_testing;
