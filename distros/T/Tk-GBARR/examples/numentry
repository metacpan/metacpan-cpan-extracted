# Entry for entering numeric values.
#!/usr/local/bin/perl -w
use strict;
use Tk;
use Tk::NumEntry;
use strict;

my $mw = Tk::MainWindow->new;

my $nume = $mw->NumEntry( -command => sub { print "Value = ",@_,"\n" });

$nume->pack(-side => 'top', -fill => 'x');

$nume = $mw->NumEntry(
		-minvalue => 10,
		-maxvalue => 100,
		-defaultvalue => -2,
		-command => sub { print "Value = ",@_,"\n" }
);

$nume->pack(-side => 'top', -fill => 'x');

$nume = $mw->NumEntry(
		-readonly => 1,
);

$nume->pack(-side => 'top', -fill => 'x');

Tk::MainLoop;
__END__
