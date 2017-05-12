use Test::More tests => 7;
use Test::Exception;
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $d='tmp-td';
my $td1;

lives_ok { $td1 = MODULE->new($d) } "first unique lives";
dies_ok { MODULE->new($d) } "second unique dies";
dies_ok { $td1->create('.') } "Bogus file dies";

dies_ok { MODULE->new('README') } "Using plain file dies";

open my($fh), '>', $td1->path('opened');
dies_ok {$td1->create('opened')} "Create dies";
dies_ok {$td1->touch('opened')} "touch dies";
unlink $td1->path('opened');
