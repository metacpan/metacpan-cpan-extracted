package Alternative::NameSpace::Ext::TestExt;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.02";

use base qw( Tk::AppWindow::BaseClasses::Extension );

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);


	return $self;
}

1;
 
