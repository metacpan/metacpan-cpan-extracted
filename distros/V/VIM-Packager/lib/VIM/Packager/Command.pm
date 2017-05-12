package VIM::Packager::Command;
use warnings;
use strict;
use base qw(App::CLI App::CLI::Command);
use Getopt::Long qw(:config no_ignore_case bundling);

$|++;

sub invoke {
    my ($pkg,$cmd,@args)=@_;
    local *ARGV = [ $cmd , @args ];
    my $ret = eval { $pkg->dispatch() };
    warn $@ if $@;
    return ($ret || 0);
}


1;
