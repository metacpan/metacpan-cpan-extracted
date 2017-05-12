#!/usr/bin/perl -w

use lib qw(blib/lib);
use strict;

use Tie::Concurrent;
use GDBM_File;
use Storable;
use MLDBM qw(GDBM_File Storable);

my $file="torture.gdbm";

my $n=2;
my %data;
tie %data, 'Tie::Concurrent', {
            READER=>['MLDBM', $file, GDBM_READER, 0660], 
            WRITER=>['MLDBM', $file, GDBM_WRCREAT, 0660]
        };

die "Can't tie" unless tied %data;


my $word=$ARGV[0]||'hello';
$data{$$}={};

for(0..9) {
    my $q=$data{$$};
    $q->{$_}=$word;
    $data{$$}=$q;
    sleep 1;
    next if $_ < 1;
    print "$$: $data{$$}->{$_-1}\n";
}


