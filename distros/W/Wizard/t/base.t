# -*- perl -*-

use strict;

$| = 1;
$^W = 1;


my @modules = qw(Wizard
		 Wizard::HTML
		 Wizard::Shell
		 Wizard::Form
		 Wizard::Form::Shell
		 Wizard::Form::HTML
		 Wizard::State
		 Wizard::SaveAble
		 HTML::EP::Wizard
	         Wizard::Examples
	         Wizard::Examples::ISDN
		 Wizard::Examples::Apache
		 Wizard::Examples::Apache::Directory
		 Wizard::Examples::Apache::VirtualServer
		 Wizard::Examples::Apache::Host
		 Wizard::Examples::Apache::Server
		 Wizard::Examples::Apache::Config
		 Wizard::Elem::Data::Shell
		 Wizard::Elem::Data::HTML
		 Wizard::Elem::TextArea::HTML
		 Wizard::Elem::TextArea::Shell
		 Wizard::Elem::Select::HTML
		 Wizard::Elem::Select::Shell
		 Wizard::Elem::Title::HTML
		 Wizard::Elem::Title::Shell
		 Wizard::Elem::Text::HTML
		 Wizard::Elem::Text::Shell
		 Wizard::Elem::Link::Shell
		 Wizard::Elem::Link::HTML
		 Wizard::Elem::HTML
		 Wizard::Elem::Submit::HTML
		 Wizard::Elem::Submit::Shell
		 Wizard::Elem::Shell
		 Wizard::Elem::BR::Shell
		 Wizard::Elem::BR::HTML
		 Wizard::Elem::CheckBox::HTML
		 Wizard::Elem::CheckBox::Shell);


print "1..", scalar(@modules), "\n";

my $i = 0;
foreach my $m (@modules) {
    ++$i;
    eval "require $m";
    if ($@) {
	print STDERR "Error while loading $m:\n$@\n";
	print "not ok $i\n";
    } else {
	print "ok $i\n";
    }
}
