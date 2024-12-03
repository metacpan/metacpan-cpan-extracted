use strict;
use warnings;
use File::Spec::Functions qw( catdir catfile updir );
use FindBin               qw( $Bin );
use lib               catdir( $Bin, updir, 'lib' );

use Test::More;

BEGIN {
   $ENV{AUTHOR_TESTING}
      or plan skip_all => 'POD spelling test only for developers';
}

use English qw( -no_match_vars );

eval "use Test::Spelling";

$EVAL_ERROR and plan skip_all => 'Test::Spelling required but not installed';

my $checker = has_working_spellchecker(); # Aspell is prefered

if ($checker) { warn "Check using ${checker}\n" }
else { plan skip_all => 'No OS spell checkers found' }

add_stopwords( <DATA> );

all_pod_files_spelling_ok();

done_testing();

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:

__DATA__
BUILDARGS
BottomLeft
BottomRight
CSRF
CSV
DBIC
DBIxClass
DBIxClassResultSet
DQUOTE
EOL
HTML::StateTable
Iterable
JS
NUL
Renderer
ResultObject
ResultRole
ResultSet
SERIALISERS
SPC
Stateful
TopLeft
UnknownView
chartable
csv
divs
downloader
flanigan
initialiser
instantiation
js
merchantability
mouseover
peter
redis
renderer
reorderable
resultset
resultsets
serialisable
serialiser
sortable
sql
statetable
SVG

