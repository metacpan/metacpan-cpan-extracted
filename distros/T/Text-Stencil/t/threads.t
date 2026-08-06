use strict;
use warnings;
use Config;
use Test::More;

BEGIN {
    plan skip_all => 'perl not built with ithreads' unless $Config{useithreads};
}

use threads;
use Text::Stencil;

# The compiled template is a malloc'd C struct addressed by a raw pointer in
# the blessed IV.  Without CLONE_SKIP, creating a thread while an object was
# alive duplicated that pointer into the child interpreter and the process
# aborted with "free(): invalid pointer" -- the object did not even have to
# be used in the thread.

my $s = Text::Stencil->new(row => '{0:int}-{1:html}', separator => ',');
is $s->render([[1, '<a>'], [2, '<b>']]), '1-&lt;a&gt;,2-&lt;b&gt;', 'parent renders';

my $t = threads->create(sub { 42 });
is $t->join, 42, 'a thread that never touches the object survives';

my @workers = map {
    my $n = $_;
    threads->create(sub {
        # each thread makes its own object, as the docs require
        Text::Stencil->new(row => '{0:int}')->render([[$n]]);
    });
} 1 .. 3;
is join(',', map { $_->join } @workers), '1,2,3', 'worker threads render independently';

is $s->render([[9, '<z>']]), '9-&lt;z&gt;', 'parent object still usable after joins';

is +(Text::Stencil->can('CLONE_SKIP') ? Text::Stencil->CLONE_SKIP : 0), 1,
    'CLONE_SKIP is in place';

done_testing;
