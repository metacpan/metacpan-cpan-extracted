

use Test::More tests => 2;

BEGIN { use_ok('WWW::PagerDuty') };

	# Example key used from PagerDuty's public Documentation 
$service_key = 'e93facc04764012d7bfb002500d5d1a6', $incident_key = 'srv01/HTTP';

	# Incident key can be passed on Object Creation, or during a call to 'trigger' or 'resolve'
$pager_duty = new WWW::PagerDuty({service_key => $service_key, incident_key => $incident_key });

is(ref $pager_duty, "WWW::PagerDuty", "");

	# Description key must be passed, and must be a scalar
#	$result = $pager_duty->trigger({ description => '' });
#	$result = $pager_duty->resolve({ description => '' });

	# Details can be passed as a HASH reference, with arbritray keys/data
#	$result = $pager_duty->trigger({ description => '' , details => { occurrence => '2015-01-15' } });
#	$result = $pager_duty->resolve({ description => '' , details => { arbritrary_key => 'arbritrary_data' } });

	# Incident key passed to calls of Trigger/Resolve takes precedence over those passed during object creation
#	$result = $pager_duty->trigger({ incident_key => $incident_key, description => '' });
#	$result = $pager_duty->resolve({ incident_key => $incident_key, description => '' });
