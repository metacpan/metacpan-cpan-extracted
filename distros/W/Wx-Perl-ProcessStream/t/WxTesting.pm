#############################################################################
## Name:        t/WxTesting.pm
## Purpose:     helper functions
## Author:      Mark Dootson
## Created:     20070326
## Copyright:   Based on the Wx distribution test helper which is 
##              (c) 2005,2006,2007 Mattia Barbon and is available in the 
##              wxPerl distribution.
##              This code is copyright (c) 2007 Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package WxTesting::Handler;
use strict;
use Wx;
use base qw(Wx::EvtHandler);
use Wx::Event qw(EVT_TIMER);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );
	EVT_TIMER( $self, -1, \&OnTimer );
	return $self;
}

sub OnTimer {
	# run once when app starts
	my $frame = Wx::wxTheApp()->GetTopWindow;
	$frame->RunTests();
	$frame->Destroy;
	Wx::WakeUpIdle;
}

package WxTesting::Frame;
use strict;
use Wx;
use base qw( Wx::Frame );

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );
	
	# start the test run timer
    $self->{_testtimer} = Wx::Timer->new( WxTesting::Handler->new );
	$self->{_testtimer}->Start( 800, 1 );
	
	return $self;	
}

sub RunTests {
	my $self = shift;
	die 'RunTests must be overridden in test script';
}

sub TestAppTimeOut {
	my $self = shift;
	$self->Destroy;
}

sub Destroy {
    my $self = shift;
    $self->SUPER::Destroy;
    $self->{_testtimer}->Destroy;
    Wx::wxTheApp()->ExitMainLoop;
    Wx::WakeUpIdle();
}

package WxTesting::App;

use base qw( Wx::App );

my $framesub;

sub new {
	my $class = shift;
	my ( $frameclass ) = @_;
	$framesub = sub { $frameclass; };
	my $self = $class->SUPER::new();
	$self->SetExitOnFrameDelete(1);
	return $self;
}

sub OnInit {
	my $self = shift;
	my $frameclass = &$framesub;
	my $mainwindow = $frameclass->new(undef, -1, 'Wx Testing Frame');
	$self->SetTopWindow($mainwindow);
	#$mainwindow->Show(1);
	return 1;
}

package WxTesting;

use strict;
use Wx;
require Exporter;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw( app_from_wxtesting_frame );
				 
sub app_from_wxtesting_frame {
	my ( $frameclass ) = @_;
	my $app = WxTesting::App->new( $frameclass );
	return $app;
}

1;
__END__

