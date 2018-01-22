#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: dialog.t,v 1.13 2009/02/01 14:24:41 eserte Exp $
# Author: Slaven Rezic
#

use strict;

use Tk;
use Tk::PathEntry::Dialog qw(as_default);

BEGIN {

    if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

    if (!eval q{
	use Test;
	1;
    } || $ENV{BATCH}) {
	print "1..0 # skip tests only work in non-BATCH mode with installed Test module\n";
	CORE::exit;
    }

}

my $top = eval { new MainWindow };
if (!$top)  {
    print "1..0 # skip cannot create main window: $@\n";
    exit;
}

plan tests => 3;

$top->Message(-text => <<EOF)->pack;
Note:
No actual writes are performed in this test,
so you can always say "OK" or "Yes".
EOF

my $f3 = $top->PathEntryDialog->Show;
yc($f3);
ok(1);

my $f1 = $top->getOpenFile(-title => "File to open",
			   -initialdir => '.',
			   -defaultextension => "ignored",
			   -filetypes => [["ignored", "*"]],
			  );
yc($f1);
ok(1);

my $f2 = $top->getSaveFile(-title => "File to save",
			   -initialfile => "$0",
			   -defaultextension => "ignored",
			   -filetypes => [["ignored", "*"]],
			  );
yc($f2);
ok(1);

sub yc {
    my $c = shift;
    print STDERR "Your choice: ";
    if (!defined $c) {
	print STDERR "undefined";
    } else {
	print STDERR $c;
    }
    print STDERR "\n";
}

__END__
