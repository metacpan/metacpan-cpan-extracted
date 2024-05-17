#package MyLabel;
#
#use strict;
#use warnings;
#
#use base qw(Tk::Derived Tk::Label);
#Construct Tk::Widget 'PluginsForm';
#
#sub Apply {
#	print "Apply\n";
#}
#
#package main;

package Tk::AppWindow::Ext::Dummy;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Extension );

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);


	return $self;
}

sub SettingsPage {
	my $self = shift;
	return (
		External2 => ['MyLabel', -text => "External2"],
	)
}

1;
 


