#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Hash::AsObject;
use Test::MockObject;
use POE;
use Directory::Scratch;

use ok "Verby::Action::BuildTool";

my $temp = Directory::Scratch->new;

my $makefile_pl = $temp->touch("Makefile.PL", <<'FOO');
#!/usr/bin/perl

use strict;
use warnings;

my $file = "Makefile";

unlink $file if -f $file;

open my $fh, ">", $file or die "$!";

print $fh, "moosen\n";

close $fh;

FOO

my $now = time;

utime( $now - 10, $now - 10, $makefile_pl ); 

my $a = Verby::Action::BuildTool->new;

my $logger = Test::MockObject->new;
$logger->set_true($_) for qw(info debug);
$logger->mock( log_and_die => sub { warn "$_[1]"; die "$_[1]"; } );

my $c = Hash::AsObject->new;
$c->workdir($temp->base);
$c->logger( $logger );

ok( !$temp->exists("Makefile"), "makefile doesn't exist" );

ok( !$a->verify($c), "makefile updated when not existing" );
$a->do( $c );
$poe_kernel->run;

ok( my $makefile = $temp->exists("Makefile"), "makefile now exists");

utime( $now - 5, $now - 5, $makefile );

ok( $a->verify($c), "makefile not updated if not necessary" );

utime( $now - 2, $now - 2, $makefile_pl );

ok( !$a->verify($c), "makefile updated when necessary" );
$a->do( $c );
$poe_kernel->run;

ok( $a->verify($c), "makefile now up to date" );

