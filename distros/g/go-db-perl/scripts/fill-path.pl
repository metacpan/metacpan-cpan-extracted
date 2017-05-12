#!/usr/local/bin/perl -w

use strict;

use GO::Parser;
use GO::AppHandle;
use Data::Stag;
use Getopt::Long;

if ($ARGV[0] =~ /^\-h/) {
    system("perldoc $0");
    exit;
}
my $apph = GO::AppHandle->connect(\@ARGV);


my $errf;
my $replace;
my $append;
my $fill_count;
my $fill_path;
my $no_fill_path;
my $no_optimize;
my $no_clear_cache;
my $add_root;
my $ev;
my $handler_class = 'godb';

my $fmt_arg = "";
if ($ARGV[0] =~ /^\-format/) {
    shift @ARGV;
    $fmt_arg = "-p " . shift @ARGV;
}

# parse global arguments
my @args = ();
while (@ARGV) {
    my $arg = shift @ARGV;
    if ($arg =~ /^\-e$/ || $arg =~ /^\-error$/) {
        $errf = shift @ARGV;
        next;
    }
    push(@args, $arg);
}

# send XML errors to STDERR by default
my $errhandler = Data::Stag->getformathandler('xml');
if ($errf) {
    $errhandler->file($errf);
}
else {
    $errhandler->fh(\*STDERR);
}

my $generic_parser = new GO::Parser ({handler=>$handler_class});
$generic_parser->errhandler($errhandler);


eval {
    $apph->fill_count_table;
};
if ($@) {
    $generic_parser->err(msg=>"(FAO Developers: Error making counts: $@");
}

print "\nDone!\n";
exit 0;

