#!/usr/bin/perl -w

# Text::TemplateLite example:
# Calling one external template to generate English "nth" text
# (1st, 2nd, 3rd, 4th, ...) and another to display template engine
# statistics; also uses four-way join

use strict;
use Text::TemplateLite;
use Text::TemplateLite::Standard;	# The standard function library

# Instantiate some template engines
my $en_nth = Text::TemplateLite->new;
my $stats = Text::TemplateLite->new;
my $tpl = Text::TemplateLite->new;

# Register all the standard library functions
Text::TemplateLite::Standard::register($_, ':all')
  foreach ($en_nth, $stats, $tpl);

# A template to return English "nth" (1st, 2nd, 3rd, 4th, ...)
$en_nth->set(q{<</* pass "n" in $1 */
    $=('_n', %($1, 10), '_nn', %($1, 100))
    $1 ??(&&(>=($_nn, 4), <=($_nn, 20)), 'th', /* not 11st, 12nd, 13rd */
    =($_n, 1), 'st', =($_n, 2), 'nd', =($_n, 3), 'rd', 'th')>>});

# A template to print total steps executed
$stats->set(q{<<
    $=('stats', 'Steps executed: ' +($total_steps))
    x('-', len($stats)) nl $stats >>});

# "These are the 1st, 2nd, 3rd, 4th, ..., and 24th external template calls."
$tpl->register('en_nth', $en_nth);
$tpl->set(q{These are the <<$=('n', 1) $;;('', ', ', ', ', ', and ',
    *?(en_nth(1, $n) $=('n', +($n, 1)), <=($n, 24)))
    >> external template calls.});

# Use another template to format the steps used to generate the above
my $rnd = $tpl->new_renderer();
print $rnd->render->result, "\n",
  $stats->render($rnd->stats)->result, "\n";
