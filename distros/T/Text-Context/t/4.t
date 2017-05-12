use Text::Context;
use Test::More qw(no_plan);
# What if the terms aren't there are all?

my $tc = Text::Context->new("Re: Defect in XBD lround",
"+44 118 9508311 ext 2250", "+44 118 9500110", "josey");
is($#{[$tc->paras]}, -1, "... and it doesn't die");
