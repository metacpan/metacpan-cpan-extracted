# Simple demo for Tk::FmtEntry
# (c)2010 by Steve Roscio.
# This program is free software, you can redistribute it and/or modify it
#  under the same terms as Perl itself.

use strict;
use Tk;
use Tk::FmtEntry; 

my $mw = new MainWindow(-title => "Tk::FmtEntry Demo");
my $fe  = $mw->FmtEntry(-formatcommand => \&demo_formatter)->pack;
my $fcmd = $fe->cget('-formatcommand');
print "FmtEntry is $fe, fcmd=$fcmd\n";
$fe->focus;
MainLoop;
exit 0;

sub demo_formatter {
    my ($old, $i) = @_;

    my $new = uc $old;
    my $j = $i;

    return ($new, $j);
}