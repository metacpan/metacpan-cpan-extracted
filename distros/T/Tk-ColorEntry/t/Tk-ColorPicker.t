use strict;
use warnings;
use Test::More tests => 42;
use Test::Tk;
use Tk;
require Tk::LabFrame;

BEGIN { use_ok('Tk::ColorPicker') };

createapp;

my $picker;
if (defined $app) {
	my $entry;
	my $frame = $app->Frame(
		-width => 200,
		-height => 100,
	)->pack(-fill => 'both');
	my $bframe = $frame->LabFrame(
		-label => 'History',
	)->pack(-fill => 'x');
	$bframe->Button(
		-text => 'Add',
		-command => sub {
			my $txt = $entry->get;
			$picker->HistoryAdd($txt);
		}
	)->pack(
		-side => 'left',
	);
	$bframe->Button(
		-text => 'Clear',
		-command => sub { $picker->HistoryReset }
	)->pack(
		-side => 'left',
	);
	my $var = '';
	my $lab = $frame->Label(
		-relief => 'sunken',
		-borderwidth => 2,
	)->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 2,
	);
	$entry = $frame->Entry(
		-textvariable => \$var,
	)->pack(
		-fill => 'both',
		-padx => 2,
		-pady => 2,
	);
	$picker = $frame->ColorPicker(
		-updatecall => sub {
			$var = shift;
			$lab->configure(-background => $picker->getHEX);
		},
		-depthselect => 1,
		-notationselect => 1,
		-historyfile => 't/colorentry_history',
	)->pack(
		-fill => 'both',
		-padx => 2,
		-pady => 2,
	);
	$entry->bind('<Key>', sub { $picker->put($entry->get) });
}

push @tests, (
	[ sub { return defined $picker }, 1, 'ColorPicker widget created' ],
	[ sub {
		my @rgb = $picker->hsv2rgb(0, 1, 1);
		return \@rgb
	}, [255, 0, 0], 'hsv2rgb 1' ],
	[ sub {
		my @rgb = $picker->hsv2rgb(120, 1, 1);
		return \@rgb
	}, [0, 255, 0], 'hsv2rgb 2' ],

	[ sub {
		$picker->put('cmy(1, 0, 1)');
		return $picker->getHEX;
	}, '#00FF00', 'put cmy' ],
	[ sub {
		$picker->put('cmy8(255, 0, 255)');
		return $picker->getHEX;
	}, '#00FF00', 'put cmyX' ],
	[ sub {
		$picker->put('#00FF00');
		return $picker->getHEX;
	}, '#00FF00', 'put hex' ],
	[ sub {
		$picker->put('hsv(120, 1, 1)');
		return $picker->getHEX;
	}, '#00FF00', 'put hsv' ],
	[ sub {
		$picker->put('rgb(0, 1, 0)');
		return $picker->getHEX;
	}, '#00FF00', 'put rgb' ],
	[ sub {
		$picker->put('rgb8(0, 255, 0)');
		return $picker->getHEX;
	}, '#00FF00', 'put rgbX' ],


	[ sub {
		return $picker->notationCMY('#FF00FF');
	}, 'cmy(0, 1, 0)', 'notationCMY' ],
	[ sub {
		return $picker->notationCMYx('#FF00FF');
	}, 'cmy8(0, 255, 0)', 'notationCMYx' ],
	[ sub {
		return $picker->notationHEX('#FF00FF');
	}, '#FF00FF', 'notationHEX' ],
	[ sub {
		return $picker->notationHSV('#FF00FF');
	}, 'hsv(300, 1, 0.996)', 'notationHSV' ],
	[ sub {
		return $picker->notationRGB('#FF00FF');
	}, 'rgb(1, 0, 1)', 'notationRGB' ],
	[ sub {
		return $picker->notationRGBx('#FF00FF');
	}, 'rgb8(255, 0, 255)', 'notationRGBx' ],

	[ sub {
		$picker->configure(-notation => 'cmy');
		return $picker->notationCurrent;
	}, 'cmy(1, 0, 1)', 'notationCurrent cmy' ],
	[ sub {
		$picker->configure(-notation => 'cmyX');
		return $picker->notationCurrent;
	}, 'cmy8(255, 0, 255)', 'notationCurrent cmyX' ],
	[ sub {
		$picker->configure(-notation => 'hex');
		return $picker->notationCurrent;
	}, '#00FF00', 'notationCurrent hex' ],
	[ sub {
		$picker->configure(-notation => 'hsv');
		return $picker->notationCurrent;
	}, 'hsv(120, 1, 0.996)', 'notationCurrent hsv' ],
	[ sub {
		$picker->configure(-notation => 'rgb');
		return $picker->notationCurrent;
	}, 'rgb(0, 1, 0)', 'notationCurrent rgb' ],
	[ sub {
		$picker->configure(-notation => 'rgbX');
		return $picker->notationCurrent;
	}, 'rgb8(0, 255, 0)', 'notationCurrent rgbX' ],

	[ sub {
		return $picker->convertCMY('cmy(0, 1, 0)');
	}, '#FF00FF', 'convertCMY' ],
	[ sub {
		return $picker->convertCMYx('cmy8(0, 255, 0)');
	}, '#FF00FF', 'convertCMYx' ],
	[ sub {
		return $picker->convertHEX('#FF00FF');
	}, '#FF00FF', 'convertHEX' ],
	[ sub {
		return $picker->convertHSV('hsv(300, 1, 1)');
	}, '#FF00FF', 'convertHSV' ],
	[ sub {
		return $picker->convertRGB('rgb(1, 0, 1)');
	}, '#FF00FF', 'convertRGB' ],
	[ sub {
		return $picker->convertRGBx('rgb8(255, 0, 255)');
	}, '#FF00FF', 'convertRGBx' ],

	[ sub {
		return $picker->validate('cmy(0, 1, 0)');
	}, 1, 'pass validate CMY' ],
	[ sub {
		return $picker->validate('cmy8(0, 255, 0)');
	}, 1, 'pass validate CMYx' ],
	[ sub {
		return $picker->validate('#FF00FF');
	}, 1, 'pass validate HEX' ],
	[ sub {
		return $picker->validate('hsv(300, 1, 1)');
	}, 1, 'pass validate HSV' ],
	[ sub {
		return $picker->validate('rgb(0, 1, 0)');
	}, 1, 'pass validate RGB' ],
	[ sub {
		return $picker->validate('rgb8(0, 255, 0)');
	}, 1, 'pass validate RGBx' ],

	[ sub {
		return $picker->validate('cmy(0, 1, 0)k');
	}, 0, 'fail validate CMY' ],
	[ sub {
		return $picker->validate('cmy8(0, 255, 0)k');
	}, 0, 'fail validate CMYx' ],
	[ sub {
		return $picker->validate('#FF00FFk');
	}, 0, 'fail validate HEX' ],
	[ sub {
		return $picker->validate('hsv(300, 1, 1)k');
	}, 0, 'fail validate HSV' ],
	[ sub {
		return $picker->validate('rgb(0, 1, 0)k');
	}, 0, 'fail validate RGB' ],
	[ sub {
		return $picker->validate('rgb8(0, 255, 0)k');
	}, 0, 'fail validate RGBx' ],



#	[ sub {
#		my @rgb = $picker->rgb2hsv(255, 0, 0);
#		return \@rgb
#	}, [0, 1, 1], 'hsv2rgb' ],
);


starttesting;
