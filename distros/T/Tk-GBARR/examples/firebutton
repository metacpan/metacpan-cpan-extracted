# Button with "repeat" effect.
#!/usr/local/bin/perl -w
use strict;
use Tk;
use Tk::FireButton;

my $i = 0;

my $mw = Tk::MainWindow->new();
my $fb = $mw->FireButton(
		-text=>'Fire',
		-command=>sub{$i++;}
		)->pack;
my $l = $mw->Label(-textvariable=>\$i)->pack(qw/-padx 10 -pady 6/);

Tk::MainLoop;
__END__
