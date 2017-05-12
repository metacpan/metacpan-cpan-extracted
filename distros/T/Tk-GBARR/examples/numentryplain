# Entry for entering numeric values, plain version.
#!/usr/local/bin/perl -w
use strict;
use Tk;
use Tk::NumEntryPlain;

my $mw = Tk::MainWindow->new;

my $nume = $mw->NumEntryPlain(-command => sub { print "Value = ",@_,"\n" });

$nume->pack(-side => 'top', -fill => 'x');

$nume = $mw->NumEntryPlain(
		-minvalue => 10,
		-maxvalue => 100,
		-defaultvalue => -2,
		-command => sub { print "Value = ",@_,"\n" }
);

$nume->pack(-side => 'top', -fill => 'x');

Tk::MainLoop;
__END__
