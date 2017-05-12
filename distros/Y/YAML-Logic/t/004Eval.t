######################################################################
# Test suite for YAML::Logic
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use YAML::Logic;
use Test::More qw(no_plan);
use Data::Dumper;
use Log::Log4perl qw(:easy);
use File::Temp qw(tempfile);

my($fh, $file) = tempfile(UNLINK => 1);

#Log::Log4perl->easy_init($INFO);

my $logic = YAML::Logic->new();

$logic->{safe}->reval("unlink('$file')");

ok(-f $file, "reval blocks disallowed actions");

ok(! $logic->{safe}->reval("print `cat '/etc/passwd'`"), 
    "reval blocks disallowed actions");

ok($logic->{safe}->reval("1+1"), 
    "reval allows arithmetic");

ok($logic->{safe}->reval("'foo' =~ /foo/"), 
    "reval allows regex matches");

use utf8;

ok($logic->{safe}->reval("'überfooüber' =~ /foo/"), 
    "reval allows utf8");
