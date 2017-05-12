#!perl

use strict;
use warnings;
use File::Temp;
use File::Spec;
use Text::Amuse::Compile::Utils qw/write_file/;
use Text::Amuse::Compile;
use Test::More;
use IO::Pipe;

if ($ENV{TEST_WITH_LATEX}) {
    plan tests => 6;
}
else {
    plan skip_all => 'PDF compilation needed';
}
my $wd = File::Temp->newdir;
my $muse_file = File::Spec->catfile($wd, 'test.muse');
write_file($muse_file, "#title Test fonts\n\nbla bla bla\n\n");

for (1,2) {
    my $c = Text::Amuse::Compile->new(pdf => 1, a4_pdf => 1);
    $c->compile($muse_file);
    ok (-f File::Spec->catfile($wd, 'test.pdf'), "PDF generated");
    ok (-f File::Spec->catfile($wd, 'test.a4.pdf'), "PDF generated");
}


my $pipe = IO::Pipe->new;
$pipe->reader('perl', '-e', 'print 0');
$pipe->autoflush(1);
my $found;
while (my $line = <$pipe>) {
    diag "Found $line";
    ok !$line, "Line is false, but read";
    $found++;
}
wait;
ok $found;

