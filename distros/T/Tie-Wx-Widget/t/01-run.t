#!usr/bin/perl
use strict;
use warnings;
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' } # making local lib favoured

package TestApp;
our @ISA = 'Wx::App';

use Test::More tests => 37;
use Test::Exception;
use Test::Warn;

use Wx;
use Tie::Wx::Widget 'die_mode';

sub OnInit {
	my $app = shift;
	my $module = 'Tie::Wx::Widget';
	my ($old_txt, $new_txt, $old_nr, $new_nr) = qw/fabulous frequency 10 20/;
	my $cmsg = 'with the right error message';
	my $frame = Wx::Frame->new( undef, &Wx::wxDEFAULT, "$module testing app" );
	my $b = Wx::Button->new( $frame, -1, 'reach me',[10, 10],[75,-1] );
	my $t = Wx::TextCtrl->new( $frame, -1, $old_txt,[10, 50], [75,30] );
	my $s1 = Wx::Slider->new( $frame, -1, $old_nr, 1, 100,[10, 90], [75,30]);
	my $s2 = Wx::Slider->new( $frame, -1, $old_nr, 1, 100,[10,130], [75,30]);
	my $s = Wx::BoxSizer->new( &Wx::wxVERTICAL );

	# die when input is not correct
	dies_ok   { tie my $tb, $module, '' } 'dies when tying an empty value';
	throws_ok { tie my $tb, $module, '' } qr/ isn't even a referece,/, $cmsg;
	dies_ok   { tie my $tb, $module,  2 } 'dies when tying a simple value';
	throws_ok { tie my $tb, $module,  2 } qr/ isn't even a referece,/, $cmsg;
	dies_ok   { tie my $tb, $module, {} } 'dies when tying a hashref';
	throws_ok { tie my $tb, $module, {} } qr/ isn't even an object,/, $cmsg;
	dies_ok   { tie my $tb, $module, $s } 'dies when tying a wx object thats not a widget';
	throws_ok { tie my $tb, $module, $s } qr/ is no Wx widget/, $cmsg;
	dies_ok   { tie my $tb, $module, $b } 'dies when tying widgets without getter or setter';
	throws_ok { tie my $tb, $module, $b } qr/ has no method:/,  $cmsg;
	dies_ok   { tie my $tb, $module, $t, {} } 'dies when tying with STORE callback thats not a coderef';
	throws_ok { tie my $tb, $module, $t, {} } qr/no coderef as STORE callback/,  $cmsg;
	dies_ok   { tie my $tb, $module, $t, sub {}, {} } 'dies when tying with FETCH callback thats not a coderef';
	throws_ok { tie my $tb, $module, $t, sub {}, {} } qr/no coderef as FETCH callback/,  $cmsg;

	lives_ok  { tie my $tb, $module, MySlider->new($frame) } 'can handle derived widgets';

	# switch die and warn mode
	my $tbb;
	Tie::Wx::Widget::warn_mode();
	warning_like {tie $tbb, $module, ''} qr/ isn't even a referece,/, 'warn mode works correctly';
	is (tied $tbb, undef, 'really didn\'t tie in warn mode with bad input');
	Tie::Wx::Widget::die_mode();
	dies_ok { tie my $tb, $module, '' } 'die mode works too';

	# basic API
	my $tt;
	is (ref tie( $tt, $module, $t), $module, 'tie works');
	is (ref tied $tt, $module, 'tied works');
	is ($tt, $old_txt, 'FETCH works');
	$tt = $new_txt;
	is ($tt, $new_txt, 'STORE works');
	$tt = {};
	is ($tt, $new_txt, 'reference values won\'t stored');
	is (untie $tt, 1, 'untie works');
	is (tied $tt, undef, 'really untied');

	# callbacks
	my $tslider;
	my $tied = tie $tslider, $module, $s1,
				sub { $_[0]->SetValue($_[1]); $s2->SetRange(1, $_[1]) },
				sub { $s2->SetValue( $_[0]->GetValue ) };
	my $dummy = $tslider;
	is ($s2->GetValue, $old_nr, 'FETCH callback worked');
	$tslider = $new_nr;
	is ($s2->GetMax, $new_nr, 'STORE callback worked');

	# internal API
	$t->SetValue($old_txt);
	my $tref = tie( $tt, $module, $t);
	is ($tref->FETCH, $old_txt, 'FETCH as a method works');
	$tref->STORE($new_txt);
	is ($tt, $new_txt, 'STORE as a method works');
	$tref = tie( $tt, $module, $t, sub {$new_txt}, sub {$old_txt});
	is ($tref->FETCH, $old_txt, 'FETCH callback as a method works');
	is ($tref->STORE, $new_txt, 'STORE callback as a method works');
	is ($tref->{'widget'}, $t, 'get the internal Wx widget object');
	is ($tref->{'w'}, $t, 'alternative shortcut key works too');
	is (&{$tref->{'fetch'}}(), $old_txt, 'get the FETCH callback');
	is (&{$tref->{'store'}}(), $new_txt, 'get the STORE callback');
	lives_ok { $tref->UNTIE } 'UNTIE can be called'; # but has no effect
	lives_ok { $tref->DESTROY } 'DESTROY can be called'; # but has no effect

	# shut the app down after 10 millseconds
	Wx::Timer->new( $frame, 1000 )->Start( '10', 1 );
	Wx::Event::EVT_TIMER( $frame, 1000 , sub { $app->ExitMainLoop } );

	1;
}

package MySlider;
our @ISA = 'Wx::Slider';
sub new { $_[0]->SUPER::new( $_[1], -1, 2, 1, 3 ) }

package main;
TestApp->new->MainLoop;

exit(0);