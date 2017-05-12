#!/usr/bin/env perl
use strict;
use warnings;
use curry::weak;
package Manager::Base;
sub new { my $class = shift; bless { @_ }, $class }
package FileManager;
use parent -norequire => 'Manager::Base';
package ClipboardManager;
use parent -norequire => 'Manager::Base';
package AppManager;
use parent -norequire => 'Manager::Base';
package main;
use Tickit::DSL;
use Try::Tiny;

my $fm = FileManager->new;
my $cm = ClipboardManager->new;
my $sys = AppManager->new;
vbox {
	menubar {
		submenu File => sub {
			menuitem Open  => $fm->curry::weak::open_dialog;
		};
		submenu Edit => sub {
			menuitem Copy  => $cm->curry::weak::copy_dialog;
			menuitem Cut   => $cm->curry::weak::cut_dialog;
			menuitem Paste => $cm->curry::weak::paste_dialog;
		};
		menuspacer;
		submenu Help => sub {
			menuitem About => $sys->curry::weak::about_dialog;
		};
	};
};
tickit->run;
