#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp 'tempdir';
use Path::Class 'dir','file';

BEGIN {
    use_ok ( 'meon::Web::TimelineEntry' ) or exit;
}

my $tmp_dir = tempdir( CLEANUP => 1 );
my $timeline_01 = dir($tmp_dir, 'timeline01');
$timeline_01->mkpath;

exit main();

sub main {
    my $entry = create_new_timelineentry();
    return 0;
}

sub create_new_timelineentry {
    my $entry = meon::Web::TimelineEntry->new(
        timeline_dir => $timeline_01,
        title => 'some title',
        intro => 'This will be quite a long description that may be shortened for summary timeline listing afterwards.',
        author => 'tester',
        text => 'and here comes the short body text',
    );
    $entry->create;
    like($entry->file, qr{^$timeline_01/\d+/\d+/[^/]+\.xml$}, 'entry file created');
    eq_or_diff(mangle_created(scalar $entry->file->slurp),new_entry_xml_01(),'check generated file');
}

sub mangle_created {
    my $xml = shift;
    $xml =~ s{<w:created>.+?</w:created>}{<w:created>CREATED</w:created>}xms;
    return $xml;
}

sub new_entry_xml_01 {
    return q{<?xml version="1.0" encoding="UTF-8"?>
<page xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns="http://web.meon.eu/" xmlns:w="http://web.meon.eu/">

<meta>
    <title>some title</title>
    <form>
        <owner-only/>
        <process>Delete</process>
        <redirect>../../</redirect>
    </form>
</meta>

<content><div xmlns="http://www.w3.org/1999/xhtml">

<w:timeline-entry category="news">
    <w:created>CREATED</w:created>
    <w:author>tester</w:author>
    <w:title>some title</w:title>
    <w:intro>This will be quite a long description that may be shortened for summary timeline listing afterwards.</w:intro>
    <w:text>and here comes the short body text</w:text>
    <w:timeline class="comments">
    </w:timeline>
</w:timeline-entry>

<div class="delete-confirmation"><w:form copy-id="form-delete"/></div>
</div></content>

</page>
};
}
