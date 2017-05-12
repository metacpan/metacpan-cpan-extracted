use strict;
use Test::More tests=>6;
use Test::NoWarnings;

BEGIN { use_ok 'Unicode::Stringprep' }
BEGIN { use_ok 'Unicode::Stringprep::Unassigned' }
BEGIN { use_ok 'Unicode::Stringprep::Mapping' }
BEGIN { use_ok 'Unicode::Stringprep::Prohibited' }
BEGIN { use_ok 'Unicode::Stringprep::BiDi' }
