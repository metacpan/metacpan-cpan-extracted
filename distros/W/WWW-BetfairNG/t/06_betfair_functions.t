#!/usr/bin/perl
use strict;
use warnings;
use Net::Ping;
use Test::More;
use WWW::BetfairNG;

my $username = '';
my $password = '';
my $certfile = '';
my $keyfile  = '';
my $app_key  = '';
my $params   = {};

# Check if we were asked to run these tests
unless ( $ENV{BF_LIVE_TEST} ) {
  plan(skip_all => "Live tests not requested");
}


my $continue = 1;
my $p = Net::Ping->new('tcp');
$p->port_number('80');
$continue = 0 unless $p->ping('www.bbc.co.uk');
$p->close();

plan( skip_all => "No internet connection found") unless $continue;

print STDERR <<EOF


============================================================================
NOTE:  These tests require a connection to the internet and will communicate
with the online gambling site 'Betfair'. They also require login credentials
(username and password)  for an active, funded Betfair account. NO BETS WILL
BE PLACED, but  all  functionality  which does not involve placing live bets
or altering account details will be tested.  To skip these tests, just enter
a blank username or password.
============================================================================

EOF
;

INPUT: {
  print STDERR "\nUsername: ";
  chomp($username = <STDIN>);
  unless ($username){
    $continue = 0;
    last INPUT;
  }
  print STDERR "Password: ";
  chomp($password = <STDIN>);
  print STDERR "\n";
  unless ($password){
    $continue = 0;
    last INPUT;
  }
  print STDERR "\nIf you wish to test SSL certificate login, please enter the path to\n";
  print STDERR "your certificate (.crt) and key (.key) files. (The certificate must\n";
  print STDERR "already be registered with  Betfair). If you leave this blank, only\n";
  print STDERR "non-certificate (interactive) login will be tested.\n\n";
  print STDERR "Path to SSL client cert file: ";
  chomp($certfile = <STDIN>);
  unless ($certfile){
    last INPUT;
  }
  print STDERR "Path to SSL client  key file: ";
  chomp($keyfile = <STDIN>);
}


SKIP: {
  skip "these tests will not be performed", 1 unless $continue;
  # Create Object w/o attributes
  ok(my $bf = WWW::BetfairNG->new(),   'CREATE New $bf Object');
  # Try non-interactive login first
 SKIP: {
    $keyfile = '' unless (-e $certfile and -e $keyfile);
    skip "requires SSL certificate", 1 unless $keyfile;
    is($bf->ssl_cert($certfile), $certfile,                   "Set SSL cert file");
    is($bf->ssl_key($keyfile),   $keyfile,                    "Set SSL key file");
    ok($bf->login({username=>$username,password=>$password}), "Log in");
    ok($bf->logout(),                                         "Log out");
  }
  ok(my $logged_in = $bf->interactiveLogin({username=>$username,password=>$password}),
                                                              "Log in");
 SKIP: {
    skip $bf->error, 1 unless $logged_in;
    $bf->createDeveloperAppKeys($username);
    ok($bf->getDeveloperAppKeys(),                            "Get Keys");
    foreach my $version (@{$bf->response->[0]{appVersions}}) {
      if ($version->{delayData}) {
	$app_key = $version->{applicationKey};
      }
    }
    is($bf->app_key($app_key),      $app_key,                 "Set app key");
    ok($bf->keepAlive(),                                      "keepAlive");
    is($bf->response->{token},      $bf->session,             "Check session token");


    $params->{filter} = {};
    ok($bf->listCompetitions($params),                        "listCompetitions");
    for my $comp (0..@{$bf->response} - 1) {
      ok(exists $bf->response->[$comp]->{marketCount},        "marketCount");
      ok(exists $bf->response->[$comp]->{competitionRegion},  "competitionRegion");
      ok(exists $bf->response->[$comp]->{competition},        "competition");
      ok(exists $bf->response->[$comp]->{competition}->{id},  "competition{id}");
      ok(exists $bf->response->[$comp]->{competition}->{name},"competition{name}");
    }
    ok($bf->listCountries($params),                           "listCountries");
    for my $ctry (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$ctry]->{marketCount},        "marketCount");
      ok(exists $bf->response->[$ctry]->{countryCode},        "countryCode");
    }
    $params = {};
    ok($bf->listCurrentOrders($params),                       "listCurrentOrders");
    ok(exists $bf->response->{currentOrders},                 "currentOrders");
    ok(exists $bf->response->{moreAvailable},                 "moreAvailable");
    for my $order (0..@{$bf->response->{currentOrders}}-1){
      my $record = $bf->response->{currentOrders}->[$order];
      ok(exists $record->{betId},          	              "betId");
      ok(exists $record->{marketId},       	              "marketId");
      ok(exists $record->{selectionId},    	              "selectionId");
      ok(exists $record->{handicap},       	              "handicap");
      ok(exists $record->{priceSize},      	              "priceSize");
      ok(exists $record->{bspLiability},   	              "bspLiability");
      ok(exists $record->{side},           	              "side");
      ok(exists $record->{status},         	              "status");
      ok(exists $record->{persistenceType},	              "persistenceType");
      ok(exists $record->{orderType},      	              "orderType");
      ok(exists $record->{placedDate},     	              "placedDate");
      # Take out 'matchedDate' test - fails if there are existing unmatched bets
      #     ok(exists $record->{matchedDate},    	              "matchedDate");
    }
    $params->{betStatus} = 'SETTLED';
    ok($bf->listClearedOrders($params),                       "listClearedOrders");
    # No 'required' fields in ClearedOrdersSummary
    ok(exists $bf->response->{clearedOrders},                 "clearedOrders");
    ok(exists $bf->response->{moreAvailable},                 "moreAvailable");
    $params = {filter => {}};
    ok($bf->listEvents($params),                              "listEvents");
    for my $event (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$event]->{marketCount},       "marketCount");
      ok(exists $bf->response->[$event]->{event},             "event");
      ok(exists $bf->response->[$event]->{event}->{name},     "event{name}");
      ok(exists $bf->response->[$event]->{event}->{id},       "event{id}");
      ok(exists $bf->response->[$event]->{event}->{timezone}, "event{timezone}");
      ok(exists $bf->response->[$event]->{event}->{openDate}, "event{openDate}");
    }
    $params = {filter => {}};
    ok($bf->listEventTypes($params),                           "listEventTypes");
    for my $type (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$type]->{marketCount},         "marketCount");
      ok(exists $bf->response->[$type]->{eventType},           "event");
      ok(exists $bf->response->[$type]->{eventType}->{name},   "event{name}");
      ok(exists $bf->response->[$type]->{eventType}->{id},     "event{id}");
    }
    my $start_time = time() + 86400; # one day from now in seconds
    my ($sec,$min,$hour,$mday,$month,$year) = gmtime($start_time);
    $year  += 1900;
    $month += 1;
    my $start_time_ISO = sprintf("%04s", $year )."-";
    $start_time_ISO   .= sprintf("%02s", $month)."-";
    $start_time_ISO   .= sprintf("%02s", $mday )."T";
    $start_time_ISO   .= sprintf("%02s", $hour ).":";
    $start_time_ISO   .= sprintf("%02s", $min  )."Z";
    $params = {filter => {}};
    $params->{maxResults}       = '1';
    $params->{marketProjection} = ['RUNNER_DESCRIPTION'];
    $params->{marketStartTime}  = {from => $start_time_ISO};
    ok($bf->listMarketCatalogue($params),                      "listMarketCatalogue");
    for my $market (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$market]->{marketName},        "marketName");
      ok(exists $bf->response->[$market]->{marketId},          "marketId");
      ok(exists $bf->response->[$market]->{totalMatched},      "totalMatched");
      ok(exists $bf->response->[$market]->{runners},           "runners");
      foreach my $runner (@{$bf->response->[$market]->{runners}}) {
	ok(exists $runner->{selectionId},                      "selectionId");
	ok(exists $runner->{runnerName},                       "runnerName");
	ok(exists $runner->{handicap},                         "handicap");
	ok(exists $runner->{sortPriority},                     "sortPriority");
      }
    }
    # Concentrate on the first and last runners in the first market
    my $market_id     = $bf->response->[0]->{marketId};
    my $runners       = $bf->response->[0]->{runners};
    $params = {marketIds => [$market_id]};
    $params->{priceProjection} = {priceData => ['EX_BEST_OFFERS']};
    ok($bf->listMarketBook($params),                            "listMarketBook");
    for my $market (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$market]->{marketId},             "marketId");
      ok(exists $bf->response->[$market]->{isMarketDataDelayed},  "isMarketDataDelayed");
      ok(exists $bf->response->[$market]->{status},               "status");
      ok(exists $bf->response->[$market]->{betDelay},             "betDelay");
      ok(exists $bf->response->[$market]->{bspReconciled},        "bspReconciled");
      ok(exists $bf->response->[$market]->{complete},             "complete");
      ok(exists $bf->response->[$market]->{inplay},               "inplay");
      ok(exists $bf->response->[$market]->{numberOfWinners},      "numberOfWinners");
      ok(exists $bf->response->[$market]->{numberOfRunners},      "numberOfRunners");
      ok(exists $bf->response->[$market]->{numberOfActiveRunners},"numberOfActiveRunners");
      #     ok(exists $bf->response->[$market]->{lastMatchTime},        "lastMatchTime");
      ok(exists $bf->response->[$market]->{totalMatched},         "totalMatched");
      ok(exists $bf->response->[$market]->{totalAvailable},       "totalAvailable");
      ok(exists $bf->response->[$market]->{crossMatching},        "crossMatching");
      ok(exists $bf->response->[$market]->{runnersVoidable},      "runnersVoidable");
      ok(exists $bf->response->[$market]->{version},              "version");
      ok(exists $bf->response->[$market]->{runners},              "runners");
      foreach my $runner (@{$bf->response->[$market]->{runners}}) {
	ok(exists $runner->{selectionId},                      "selectionId");
	ok(exists $runner->{handicap},                         "handicap");
	ok(exists $runner->{status},                           "status");
	#       ok(exists $runner->{adjustmentFactor},                 "adjustmentFactor");
	ok(exists $runner->{ex},                               "exchange");
      }
    }
    # New call 'listRunnerBook' introduced on 2017-03-28 so it's tested here on 1st horse
    # It returns an array of MarketBook so the tests are the same as for 'listMarketBook'
    my $selection_id = $runners->[0]->{selectionId};
    $params = {marketId => $market_id, selectionId => $selection_id};
    $params->{priceProjection} = {priceData => ['EX_BEST_OFFERS']};
    ok($bf->listRunnerBook($params),                            "listRunnerBook");
    for my $market (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$market]->{marketId},             "marketId");
      ok(exists $bf->response->[$market]->{isMarketDataDelayed},  "isMarketDataDelayed");
      ok(exists $bf->response->[$market]->{status},               "status");
      ok(exists $bf->response->[$market]->{betDelay},             "betDelay");
      ok(exists $bf->response->[$market]->{bspReconciled},        "bspReconciled");
      ok(exists $bf->response->[$market]->{complete},             "complete");
      ok(exists $bf->response->[$market]->{inplay},               "inplay");
      ok(exists $bf->response->[$market]->{numberOfWinners},      "numberOfWinners");
      ok(exists $bf->response->[$market]->{numberOfRunners},      "numberOfRunners");
      ok(exists $bf->response->[$market]->{numberOfActiveRunners},"numberOfActiveRunners");
      #     ok(exists $bf->response->[$market]->{lastMatchTime},        "lastMatchTime");
      ok(exists $bf->response->[$market]->{totalMatched},         "totalMatched");
      ok(exists $bf->response->[$market]->{totalAvailable},       "totalAvailable");
      ok(exists $bf->response->[$market]->{crossMatching},        "crossMatching");
      ok(exists $bf->response->[$market]->{runnersVoidable},      "runnersVoidable");
      ok(exists $bf->response->[$market]->{version},              "version");
      ok(exists $bf->response->[$market]->{runners},              "runners");
      foreach my $runner (@{$bf->response->[$market]->{runners}}) {
	ok(exists $runner->{selectionId},                      "selectionId");
	ok(exists $runner->{handicap},                         "handicap");
	ok(exists $runner->{status},                           "status");
	#       ok(exists $runner->{adjustmentFactor},                 "adjustmentFactor");
	ok(exists $runner->{ex},                               "exchange");
      }
    }
    $params = {};
    $params->{marketId} = $market_id;
    my $instructions = [];
    for (0,-1) {
      my $instruction = {handicap => '0', side => 'BACK', orderType => 'LIMIT'};
      $instruction->{limitOrder} = {size => '0.01', persistenceType => 'LAPSE'};
      $instruction->{selectionId} = qq/$runners->[$_]->{selectionId}/;
      $instruction->{limitOrder}->{price} = "10";
      push @$instructions, $instruction;
    }
    $params->{instructions} = $instructions;
    ok(!$bf->placeOrders($params),                              "placeOrders");
    is($bf->error,         'FAILURE : BET_ACTION_ERROR',     "Bet Action Error");
    $params = {};
    $params->{marketId} = $market_id;
    $params->{instructions} = [{betId => '6666666', newPrice => '9'}];
    ok(!$bf->replaceOrders($params),                            "replaceOrders");
    is($bf->error,         'FAILURE : BET_ACTION_ERROR',     "Bet Action Error");
    $params->{instructions} = [{betId => '6666666', newPersistenceType => 'LAPSE'}];
    ok(!$bf->updateOrders($params),                             "updateOrders");
    is($bf->error,         'FAILURE : BET_ACTION_ERROR',    "Bet Action Error");
    $params = {marketIds => [$market_id]};
    ok($bf->listMarketProfitAndLoss($params),                   "listMarketProfitAndLoss");
    for my $market (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$market]->{marketId},           "marketId");
      ok(exists $bf->response->[$market]->{profitAndLosses},    "profitAndLosses");
      foreach my $runner (@{$bf->response->[$market]->{profitAndLosses}}) {
	ok(exists $runner->{selectionId},                       "selectionId");
	ok(exists $runner->{ifWin},                             "ifWin");
      }
    }
    $params = {filter => {}};
    ok($bf->listMarketTypes($params),                           "listMarketTypes");
    for my $type (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$type]->{marketType},           "marketType");
      ok(exists $bf->response->[$type]->{marketCount},          "marketCount");
    }
    $params->{granularity} = 'DAYS';
    ok($bf->listTimeRanges($params),                            "listTimeRanges");
    for my $range (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$range]->{timeRange},           "timeRange");
      ok(exists $bf->response->[$range]->{marketCount},         "marketCount");
      ok(exists $bf->response->[$range]->{timeRange}->{from},   "timeRange{from}");
      ok(exists $bf->response->[$range]->{timeRange}->{to},     "timeRange{to}");
    }
    $params = {filter => {}};
    ok($bf->listVenues($params),                                "listVenues");
    for my $venue (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$venue]->{venue},               "venue");
      ok(exists $bf->response->[$venue]->{marketCount},         "marketCount");
    }
    # createDeveloperAppKeys NOT TESTED (getDeveloperAppKeys tested at start of script)
    ok($bf->getAccountDetails(),                              "getAccountDetails");
    ok(exists $bf->response->{currencyCode},    		"currencyCode");
    ok(exists $bf->response->{firstName},     	        "firstName");
    ok(exists $bf->response->{lastName},      	        "lastName");
    ok(exists $bf->response->{localeCode},    	        "localeCode");
    ok(exists $bf->response->{region},        	        "region");
    ok(exists $bf->response->{timezone},      	        "timezone");
    ok(exists $bf->response->{discountRate},  	        "discountRate");
    ok(exists $bf->response->{pointsBalance}, 	        "pointsBalance");
    ok($bf->getAccountFunds(),                                "getAccountFunds");
    ok(exists $bf->response->{availableToBetBalance}, 	"availableToBetBalance");
    ok(exists $bf->response->{exposure},              	"exposure");
    ok(exists $bf->response->{retainedCommission},    	"retainedCommission");
    ok(exists $bf->response->{exposureLimit},         	"exposureLimit");
    ok(exists $bf->response->{discountRate},          	"discountRate");
    ok(exists $bf->response->{pointsBalance},         	"pointsBalance");
    $params = {recordCount => 5};
    ok($bf->getAccountStatement($params),                     "getAccountStatement");
    ok(exists $bf->response->{moreAvailable},                 "moreAvailable");
    ok(exists $bf->response->{accountStatement},              "accountStatement");
    for my $item (@{$bf->response->{accountStatement}}) {
      ok(exists $item->{refId},                               "refId");
      ok(exists $item->{itemDate},       	  	        "itemDate");
      ok(exists $item->{amount},         	  	        "amount");
      ok(exists $item->{balance},        	  	        "balance");
      ok(exists $item->{itemClass},      	  	        "itemClass");
      ok(exists $item->{itemClassData},  	  	        "itemClassData");
      ok(exists $item->{legacyData},     	  	        "legacyData");
    }
    $params = {fromCurrency => 'GBP'};
    ok($bf->listCurrencyRates($params),                       "listCurrencyRates");
    for my $item (0..@{$bf->response}-1) {
      ok(exists $bf->response->[$item]->{currencyCode},       "currencyCode");
      ok(exists $bf->response->[$item]->{rate},               "rate");
    }

  # Won't test transferFunds - on very dodgy ground moving other people's money
    # Won't do the whole navigation menu, just Horse Racing RACES and child markets
    # Changed timeout on navigationMenu because it was failing at 5 seconds, so call
    # the method a few times to make sure it's fixed.
    for (1..3) {
      ok($bf->navigationMenu(),                                 "navigation Menu");
    }
    is($bf->response->{id},       '0',                          "id = '0'");
    is($bf->response->{name},     'ROOT',                       "name = 'ROOT'");
    is($bf->response->{type},     'GROUP',                      "type = GROUP");
    ok(exists $bf->response->{children},                        "children");
    foreach my $event_type (@{$bf->response->{children}}) {
      ok(exists $event_type->{id},                              "id");
      ok(exists $event_type->{name},                            "name");
      is($event_type->{type},     'EVENT_TYPE',                 "type = 'EVENT_TYPE'");
      ok(exists $event_type->{children},                        "children");
      if ($event_type->{id} eq '7') {    # Horse Racing
	is($event_type->{name},           'Horse Racing',       "name = 'Horse Racing'");
	foreach my $child (@{$event_type->{children}}) {
	  if ($child->{type} eq 'RACE') {
	    ok(exists $child->{id},                             "id");
	    ok(exists $child->{name},                           "name");
	    ok(exists $child->{startTime},                      "startTime");
	    my $startTime = $child->{startTime};
	    ok(exists $child->{venue},                          "venue");
	    ok(exists $child->{children},                       "children");
	    foreach my $market (@{$child->{children}}) {
	      ok(exists $market->{id},                          "id");
	      ok(exists $market->{exchangeId},                  "exchangeId");
	      ok(exists $market->{name},                        "name");
	      is($market->{type},        'MARKET',              "type = 'MARKET'");
	      is($market->{marketStartTime}, $startTime,        "Start times agree");
	    }
	  }
	}
      }
    }
    # Heartbeat
    ok($bf->heartbeat({preferredTimeoutSeconds => 0}),          "heartbeat");
    is($bf->response->{result}->{actionPerformed}, 'NONE',    	"actionPerformed");
    is($bf->response->{result}->{actualTimeoutSeconds},  0,    	"actualTimeout");
    # Race Details
    ok($bf->listRaceDetails(),                                  "listRaceDetails");
    for my $race (@{$bf->response->{result}}) {
      ok(exists $race->{meetingId},                             "meetingId");
      ok(exists $race->{raceId},                                "raceId");
      ok(exists $race->{raceStatus},                            "raceStatus");
      ok(exists $race->{lastUpdated},                           "lastUpdated");
      ok(exists $race->{responseCode},                          "responseCode");
    }
    ok($bf->listRaceDetails({raceIds => [$bf->response->{result}->[0]->{raceId}]}),
                                                                "listRaceDetails");
    for my $race (@{$bf->response->{result}}) {
      ok(exists $race->{meetingId},                             "meetingId");
      ok(exists $race->{raceId},                                "raceId");
      ok(exists $race->{raceStatus},                            "raceStatus");
      ok(exists $race->{lastUpdated},                           "lastUpdated");
      ok(exists $race->{responseCode},                          "responseCode");
    }
    ok($bf->logout(),                                           "Log out");  }
}
done_testing();
