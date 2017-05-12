
# $Id: coverage.t,v 1.4 2006-01-08 03:27:13 Daddy Exp $

use ExtUtils::testlib;
use Test::More no_plan;

use IO::Capture::Stderr;
my $oICE =  IO::Capture::Stderr->new;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Ebay') };

my $iDebug;
my $iDump = 0;

my $o = new WWW::Search('Ebay');
$o->{_debug} = 1;
$oICE->start;
# Trigger all the options-list handling:
$o->native_query('junk',
                   {
                    search_debug => 1,
                    search_parse_debug => 1,
                    foo => 'bar',
                    search_foo => undef,
                    baz => undef,
                   },
                );
$oICE->stop;
my $o1 = new WWW::Search('Ebay');
# Call native_query with no options:
$o1->native_query('junk');
# Do an actual search with debugging turned on:
$oICE->start;
$o1->native_query('star wars taco bell',
                    {
                     search_debug => 1,
                     search_parse_debug => 1,
                    },
                 );
$o1->next_result;
$oICE->stop;

exit 0;

__END__

