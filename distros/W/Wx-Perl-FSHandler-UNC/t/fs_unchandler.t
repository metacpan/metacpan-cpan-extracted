#!/usr/local/bin/perl -w
use strict;
use Test::More tests => 10;

SKIP: {
    eval "require Wx";
    skip "Requires Wx", 10 if $@;

    my $module = 'Wx::Perl::FSHandler::UNC';
    use_ok $module;
    ok $module->isa('Wx::FileSystemHandler'), '... isa Wx::FileSystemHandler';
    ok $INC{'IO/File.pm'}, '... uses IO::File';
    ok $INC{'Wx/FS.pm'}, '... uses Wx::FS';

    my $fs = $module->new();
    isa_ok $fs => $module;

    can_ok $module => 'CanOpen';
    ok $fs->CanOpen('\\\\localhost\\foo.txt'), '... accepts UNC filenames';
    ok !$fs->CanOpen('c:\\localhost\\foo.txt'), '... rejects a local file';
    ok !$fs->CanOpen('http://localhost/foo.txt'), '... rejects an http URI';

    can_ok $module => 'OpenFile';
}
