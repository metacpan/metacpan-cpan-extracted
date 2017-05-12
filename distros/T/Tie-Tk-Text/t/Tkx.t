#===============================================================================
# Tkx.t
# Test suite wrapper for Tkx
#===============================================================================
use strict;

use FindBin;
use File::Spec::Functions qw'catfile';
use Test::More;
use Tie::Tk::Text;

use vars qw($w);  # C<my $w> wouldn't be visible in C<do 'file'>

if (eval { require Tkx }) {
	my $file = catfile($FindBin::Bin, 'Tie-Tk-Text.pl');
	my $mw   = Tkx::widget->new('.');

	$w = $mw->new_text();
	do $file;
}
else {
	plan skip_all => 'Tkx not installed';
}
