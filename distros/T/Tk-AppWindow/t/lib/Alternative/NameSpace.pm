package Alternative::NameSpace;

=head1 DESCRIPTION

This is for testing only. Yes, you read me, for TESTING. Didn't you hear me say? TESTING! TESTING! TESTING!

=cut

use strict;
use warnings;
use Carp;

use base qw(Tk::Derived Tk::AppWindow);
Construct Tk::Widget 'NameSpace';

sub Populate {
	my ($self,$args) = @_;

	$self->geometry('800x600+150+150');

	my %opts = (
		-extensions => [qw[Art Daemons ToolBar StatusBar MenuBar SideBars Selector Settings Plugins]],
		-namespace => 'Alternative::NameSpace',

	);
	for (keys %opts) {
		$args->{$_} = $opts{$_}
	}
	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
}

1;
