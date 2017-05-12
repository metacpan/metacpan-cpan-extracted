#===============================================================================
# Tcl-Tk.t
# Test suite wrapper for Tcl::Tk
#===============================================================================
use strict;

use FindBin;
use File::Spec::Functions qw'catfile';
use Test::More;
use Tie::Tk::Text;

use vars qw($w);  # C<my $w> wouldn't be visible in C<do 'file'>

if (eval { require Tcl::Tk }) {
	my $file = catfile($FindBin::Bin, 'Tie-Tk-Text.pl');
	my $mw   = Tcl::Tk->new->mainwindow();

	$w = $mw->Text();
	do $file;
}
else {
	plan skip_all => 'Tcl::Tk not installed';
}
