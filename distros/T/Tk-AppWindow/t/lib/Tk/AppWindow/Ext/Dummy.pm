package Tk::AppWindow::Ext::Dummy;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Extension );

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);


	return $self;
}

1;
 
