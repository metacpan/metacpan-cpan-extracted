#!perl

use strict; use warnings;
use WWW::Google::DistanceMatrix;
use Test::More tests => 6;

eval { WWW::Google::DistanceMatrix->new(); };
like($@, qr/Missing required arguments: api_key/);

eval { WWW::Google::DistanceMatrix->new(api_key => 'API Key', avoid => 'tools'); };
like($@, qr/did not pass type constraint "Avoid"/);

eval { WWW::Google::DistanceMatrix->new(api_key => 'API Key', sensor => 'trrue'); };
like($@, qr/did not pass type constraint "TrueFalse"/);

eval { WWW::Google::DistanceMatrix->new(api_key => 'API Key', units => 'metricss'); };
like($@, qr/did not pass type constraint "Unit"/);

eval { WWW::Google::DistanceMatrix->new(api_key => 'API Key', mode => 'drivving'); };
like($@, qr/did not pass type constraint "Mode"/);

eval { WWW::Google::DistanceMatrix->new(api_key => 'API Key', language => 'enn'); };
like($@, qr/did not pass type constraint "Language"/);
