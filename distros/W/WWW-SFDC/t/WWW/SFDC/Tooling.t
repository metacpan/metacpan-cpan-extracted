use 5.12.0;
use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;
use Config::Properties;

use_ok "WWW::SFDC::Tooling";


SKIP: { #only execute if creds provided

  my $options = Config::Properties
    ->new(file => "t/test.config")
    ->splitToTree() if -e "t/test.config";

  skip "No test credentials found in t/test.config", 3
    unless $options->{username}
    and $options->{password}
    and $options->{url};

  ok WWW::SFDC::Tooling->instance(creds => {
    username => $options->{username},
    password => $options->{password},
    url => $options->{url}
   }), 'can instantiate WWW::SFDC::Tooling';

  lives_ok { WWW::SFDC::Tooling->instance()->executeAnonymous("System.debug(1);") };

  lives_ok { WWW::SFDC::Tooling->instance()->query("SELECT DeveloperName FROM CustomObject") };

}


done_testing();
