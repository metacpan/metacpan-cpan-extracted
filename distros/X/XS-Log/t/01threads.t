use strict; use warnings; use Test::More; use File::Temp qw(tempdir); use threads; use XS::Log qw(:all);
my $dir=tempdir(CLEANUP=>1); my $file="$dir/thread.log";
ok(openLog($file,{level=>LOG_LEVEL_DEBUG,targets=>LOG_TARGET_FILE,flush_immediately=>1,show_timestamp=>0,show_log_level=>0}), 'open');
my @t=map { my $id=$_; threads->create(sub { printInf("T%d-%d\n",$id,$_ ) for 1..100 }) } 1..4;
$_->join for @t; closeLog(); ok(-s $file > 0,'thread log written'); done_testing;
