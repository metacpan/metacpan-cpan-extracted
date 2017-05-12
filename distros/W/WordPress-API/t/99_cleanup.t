use Test::Simple 'no_plan';
for(qw(./t/out.yml)){
   unlink $_;
}
ok(1, 'cleanup complete');
