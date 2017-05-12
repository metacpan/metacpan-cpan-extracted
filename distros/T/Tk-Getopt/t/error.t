#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: error.t,v 1.2 2008/02/08 22:30:43 eserte Exp $
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Tk;
	use Test::More;
	use File::Temp qw(tempfile);
	1;
    }) {
	print "1..0 # skip: no Tk, File::Temp and/or Test::More module\n";
	exit;
    }

    if ($^O eq 'MSWin32') {
	print "1..0 # skip: Does not work under MSWin32, probably\n";
	exit;
    }
}

use Tk::Getopt;

plan tests => 4;

my($fh, $file) = tempfile(UNLINK => 1);
chmod 0000, $file;

my %options;
my $opt = Tk::Getopt->new(-opttable => [['test','=s','default']],
			  -options  => \%options,
			  -filename => $file,
			  -useerrordialog => 1,
			 );
eval { $opt->save_options };
my($err) = $@ =~ /^(.*)/;
ok($@, "Found error <$err>");

SKIP: {
    my $mw = eval { tkinit };
    skip("Cannot create MainWindow", 3)
	if !$mw;
    $mw->geometry('+10+10'); # for twm

    eval { $opt->save_options };
    ok($@, "Called within eval, still no window");

    $mw->after(300, sub { fire_dialog_button($mw) });
    $opt->save_options;
    pass("Dialog destroyed, hopefully");

    my $opt_editor = $opt->option_editor($mw, -buttons => [qw/oksave cancel/]);
    $mw->after(300, sub {
		   my $button;
		   my $abort = 0;
		   $mw->Walk(sub {
				 my $w = shift;
				 return if $abort;
				 if ($w->isa("Tk::Button") && $w->cget(-text) =~ /ok/i) {
				     $button = $w;
				     $abort = 1;
				 }
			     });
		   if ($button) {
		       $mw->after(100, sub { fire_dialog_button($mw) });
		       $button->invoke;
		   } else {
		       warn "No ok button found";
		   }
	       });

    $mw->after(700, sub { $mw->destroy });
    MainLoop();

    pass("Dialog from oksave button destroyed, hopefully");
}

sub fire_dialog_button {
    my($mw) = @_;
    my $button;
    my $abort = 0;
    $mw->Walk
	(sub {
	     my($w) = @_;
	     return if $abort;
	     if ($w->isa("Tk::Dialog")) {
		 my $abort2 = 0;
		 $w->Walk
		     (sub {
			  return if $abort2;
			  if ($_[0]->isa("Tk::Button")) {
			      $button = $_[0];
			      $abort2 = 1;
			  }
		      });
		 $abort = 1;
	     }
	 });
    if ($button) {
	$button->invoke;
    } else {
	diag "No dialog button found and clicked on";
    }
}

__END__
