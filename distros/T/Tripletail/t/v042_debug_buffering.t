#! perl -w

use strict;
use warnings;

use Test::More tests =>
  + 6 + 1
  + 6 + 1
  + 6 + 2
;
use lib '.';
require t::make_ini;

our $CONTENT1 = "</head>\n";
our $CONTENT2 = "TEST\n";
our $CONTENT  = $CONTENT1 . $CONTENT2;

&test01_disabled;            # 6 + 1.
&test02_enabled_and_none;    # 6 + 1.
&test03_enabled_and_single;  # 6 + 2.

sub test01_disabled
{
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
			},
			Debug => {
			},
		},
		method => 'GET',
		param  => {},
		timed_result => 1,
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->print($CONTENT1);
				sleep(3);
				$TL->print($CONTENT2);
			});
		},
	});
	SKIP:{
		ok($ret->is_success, "[disabled] fetch") or skip("[disabled] fetch failed", 3);
		ok($ret->{content}, "[disabled] has content");

		my @times;
		$ret->{content} =~ s{^((\d+):|)}{
			$1 or die "no time on line";
			push(@times, $2);
			'';
		}egm;
		is($ret->{content}, $CONTENT, "[disabled] content is not changed");
		ok($times[0], "[disabled] has time[0]");
		ok($times[1], "[disabled] has time[1]");
		my $diff = $times[1] - $times[0];
		cmp_ok($diff, '>=', 2, "[disabled] no buffering (time[1]-time[0] >= 2)");

		my @matches = $ret->{content} =~ /(.*<script.*)/g;
		is(@matches, 0, "[disabled] no <script> appears");
	}
}

sub test02_enabled_and_none
{
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
			},
			Debug => {
				enable_debug => 1,
			},
		},
		method => 'GET',
		param  => {},
		timed_result => 1,
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->print($CONTENT1);
				sleep(3);
				$TL->print($CONTENT2);
			});
		},
	});
	SKIP:{
		ok($ret->is_success, "[enabled.none] fetch") or skip("[enabled.none] fetch failed", 3);
		ok($ret->{content}, "[enabled.none] has content");

		my @times;
		$ret->{content} =~ s{^((\d+):|)}{
			$1 or die "no time on line";
			push(@times, $2);
			'';
		}egm;
		is($ret->{content}, $CONTENT, "[enabled.none] content is not changed");
		ok($times[0], "[enabled.none] has time[0]");
		ok($times[1], "[enabled.none] has time[1]");
		my $diff = $times[1] - $times[0];
		cmp_ok($diff, '>=', 2, "[enabled.none] no buffering (time[1]-time[0] >= 2)");

		my @matches = $ret->{content} =~ /(.*<script.*)/g;
		is(@matches, 0, "[enabled.none] no <script> appears");
	}
}

sub test03_enabled_and_single
{
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
			},
			Debug => {
				enable_debug => 1,
				popup_type   => 'single',
			},
		},
		method => 'GET',
		param  => {},
		timed_result => 1,
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->print($CONTENT1);
				sleep(3);
				$TL->print($CONTENT2);
			});
		},
	});
	SKIP:{
		ok($ret->is_success, "[enabled.single] fetch") or skip("[enabled.single] fetch failed", 3);
		ok($ret->{content}, "[enabled.single] has content");

		my @times;
		$ret->{content} =~ s{^((\d+):|)}{
			$1 or die "no time on line";
			push(@times, $2);
			'';
		}egm;
		isnt($ret->{content}, $CONTENT, "[enabled.single] content is changed");
		ok($times[0], "[enabled.single] has time[0]");
		ok($times[1], "[enabled.single] has time[1]");
		my $diff = $times[1] - $times[0];
		is($diff, 0, "[enabled.single] with buffering (time[1]-time[0] == 0)");

		my @matches = $ret->{content} =~ /(.*<script.*)/g;
		is(@matches, 2, "[enabled.single] <script> appears twice (one for tag, another in text).");
		like($ret->{content}, qr{^\s*<script type="text/javascript">.*</script>\s*\Q$CONTENT}s, "[enabled.single] <script> before content.");
	}
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
