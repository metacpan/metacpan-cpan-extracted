#!/usr/bin/perl -w
use strict;
use Test::More tests => 1;

use File::Find;
my @warnings;
BEGIN {
    $SIG{__WARN__} = sub {
        push @warnings, @_;
    };
};

use Data::Dumper;
#BEGIN { diag $INC{"File/Find.pm"}; };
use Test::Without::Module qw(File::Find);

#BEGIN { diag $INC{"File/Find.pm"}; };
no Test::Without::Module qw(File::Find);
#diag $INC{"File/Find.pm"};

require File::Find;
# diag Dumper \%INC;

is_deeply "@warnings", "", "No warnings were issued upon re-allowing a module";

__END__
