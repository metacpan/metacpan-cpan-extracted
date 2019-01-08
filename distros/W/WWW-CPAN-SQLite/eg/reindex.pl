#!/usr/bin/env perl

use strict;
use warnings;

use FindBin::Real;

use lib 'lib', '../lib', FindBin::Real::Bin() . '/lib', FindBin::Real::Bin() . '/../lib';

use CPAN::SQLite::Index;
use File::Copy;
use File::Spec;
use WWW::CPAN::SQLite;

$CPAN::FrontEnd ||= 'CPAN::Shell';
use CPAN::Debug;
use CPAN::Shell;

local $ENV{'CPAN_SQLITE_NO_LOG_FILES'} = 1;

my $app = WWW::CPAN::SQLite->new();

my $tmp = File::Spec->catfile($app->{'static_dir'}, 'tmp');

my $index = CPAN::SQLite::Index->new(
    'setup'     => 1,
    'db_name'   => 'cpan_sqlite_' . time . '.sqlite',
    'db_dir'    => $tmp,
    'log_dir'   => $tmp,
    'keep_sources_where' => $tmp,
    'CPAN'      => $tmp,
    'update_indices' => 1,
    'urllist'   => [
        'http://cpan.trouchelle.com/',
        'http://www.cpan.org/',
    ],
);


my @old_files;

# Remove old files or create the directory
if (opendir my $DIR, $index->{'db_dir'}) {
    @old_files = map { File::Spec->catfile($index->{'db_dir'}, $_) } grep { m!\.sqlite! } readdir $DIR;
    closedir $DIR;
} else {
    mkdir $index->{'db_dir'};
}

if (opendir my $DIR, $app->{'static_dir'}) {
    push @old_files, map { File::Spec->catfile($app->{'static_dir'}, $_) } grep { m!\.sqlite! } readdir $DIR;
    closedir $DIR;
} else {
    mkdir $app->{'static_dir'};
}

$index->index();

if (opendir my $DIR, $index->{'db_dir'}) {
    my @files = sort { $b cmp $a } grep { m!\.sqlite! } readdir $DIR;
    while (my $file = shift @files) {
        my $path = File::Spec->catfile($index->{'db_dir'}, $file);
        if (-s $path) {
            File::Copy::move($path, File::Spec->catfile($app->{'static_dir'}, $file));
            last;
        }
    }
}

unlink @old_files;

if (opendir my $DIR, $index->{'db_dir'}) {
    @old_files = map { File::Spec->catfile($index->{'db_dir'}, $_) } grep { m!\.sqlite! } readdir $DIR;
    closedir $DIR;
} else {
    mkdir $index->{'db_dir'};
}


1;
