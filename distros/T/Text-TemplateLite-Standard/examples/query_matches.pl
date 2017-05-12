#!/usr/bin/perl -w

# Text::TemplateLite example:
# How you might choose to display the number of results for a search
# (using "no" through "ten" for 0-10, or the number for > 10)...
#
# Your search returned no matches.
# Your search returned one match:
# Your search returned two matches:
# ...
# Your search returned 11 matches:

use strict;
use Text::TemplateLite;
use Text::TemplateLite::Standard;	# The standard function library

my $tpl = Text::TemplateLite->new;
my $rnd = $tpl->new_renderer;

# Register all the standard library functions
Text::TemplateLite::Standard::register($tpl, ':all');

# Generate the template
$tpl->set(q{Your search returned <<
  ??(>($matches,10),$matches, /* >10: use the number */
  $/(sp, "no one two three four five six seven eight nine ten", $matches))
  /* <10: pluck word from list */ sp
  ??(=($matches,0),'matches.',=($matches,1),'match:','matches:')
  /* singular or plural, followed by . or : */>>});

foreach my $i (0..11) {
    print $tpl->render({ matches => $i })->result, "\n";
}
