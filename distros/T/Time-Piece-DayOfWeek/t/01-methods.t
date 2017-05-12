use strict;
use warnings;

use Test::More tests => 14;                      # last test to print
use Time::Piece;
use Time::Seconds;
use Time::Piece::DayOfWeek;

my $tp = Time::Piece->strptime('December 13, 2010', '%B %d, %Y');

is 	($tp->is_monday,			1, 'is Monday'		);
is	(!$tp->is_tuesday,		1, 'not Tuesday'	);
is	(!$tp->is_wednesday,	1, 'not Wednesday');
is	(!$tp->is_thursday, 	1, 'not Thursday'	);
is	(!$tp->is_friday,			1, 'not Friday'		);
is	(!$tp->is_saturday, 	1, 'not Saturday'	);
is	(!$tp->is_sunday,			1, 'not Sunday'		);

$tp += ONE_DAY;

is  (!$tp->is_monday,     1, 'not Monday'   );
is  ( $tp->is_tuesday,    1, 'is Tuesday'		);
is  (!$tp->is_wednesday,  1, 'not Wednesday');
is  (!$tp->is_thursday,   1, 'not Thursday' );
is  (!$tp->is_friday,     1, 'not Friday'   );
is  (!$tp->is_saturday,   1, 'not Saturday' );
is  (!$tp->is_sunday,     1, 'not Sunday'   );

done_testing();


