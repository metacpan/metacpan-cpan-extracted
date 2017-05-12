#!/usr/local/ymir/perl/bin/perl
# -----------------------------------------------------------------------------
# Tripletail::DateTime::JPHoliday を生成
# -----------------------------------------------------------------------------
use strict;
use warnings;
use Cwd;
use File::Path;

our $HOLIDAYDATA;

BEGIN {
	if (!-e getcwd . "/lib/Tripletail.pm") {
		print "$0: please run this script at the same directory as Makefile.PL.\n";
		exit 1;
	}

	# Tripletail::DateTime::JPHoliday が既に読まれた事にする。
	eval q{
		package Tripletail::DateTime::JPHoliday;
		our %HOLIDAY = ();
	};
	$INC{'Tripletail/DateTime/JPHoliday.pm'} = 'Imitated by jpholiday.pl';
}

use lib 'lib';
use Tripletail qw(/dev/null);

$/ = undef;
my $t = $TL->newTemplate->setTemplate(<DATA>);

sub entry ($$;$$) {
	my $dt;
	my $name;
	
	if (@_ == 2) {
		$dt = shift;
		$name = shift;
	}
	else {
		my $year = shift;
		my $month = shift;
		my $day   = shift;
		$name  = shift;

		$dt = $TL->newDateTime
		  ->setYear($year)->setMonth($month)->setDay($day);
	}
	#祝日法は1948年7月20日～有効
	if($dt->getYear >= 1949 || ($dt->getYear == 1948 && $dt->getMonth >= 7 && $dt->getDay >= 20)) {
		my $year = sprintf('%02d', $dt->getYear);
		my $month = sprintf('%02d', $dt->getMonth);
		my $day = sprintf('%02d', $dt->getDay);
		$HOLIDAYDATA->{$year}{$month}{$day} = $name;
	}
}


sub expand_national_holiday ($$) {
	my $dt = shift;
	my $olddt = shift;

	return if(!defined($olddt));
	# 国民の休日判定
	if ($dt->getYear >= 1986) {
		if($dt->spanDay($olddt) == 2) {
			$olddt->nextDay;
			my $year = sprintf('%02d', $olddt->getYear);
			my $month = sprintf('%02d', $olddt->getMonth);
			my $day = sprintf('%02d', $olddt->getDay);
			if(!(exists($HOLIDAYDATA->{$year}{$month}{$day})) && $olddt->getWday != 0) {
				$HOLIDAYDATA->{$year}{$month}{$day} = '国民の休日';
				$t->node('year')->node('entry')->add(
					month => $month,
					day   => $day,
					name  => '国民の休日',
				);
			}
		}
	}
}

sub expand_substitute_holiday ($) {
	my $dt = shift;
	
	# 振替休日
	if ($dt->getYear >= 2007) {
		#2007年から最初の祝日では無い日が振替休日になる
		if ($dt->getWday == 0) {
			while(1) {
				$dt->nextDay;
				my $year = sprintf('%02d', $dt->getYear);
				my $month = sprintf('%02d', $dt->getMonth);
				my $day = sprintf('%02d', $dt->getDay);
				if(!(exists($HOLIDAYDATA->{$year}{$month}{$day})) && $dt->getWday != 0) {
					$HOLIDAYDATA->{$year}{$month}{$day} = '振替休日';
					$t->node('year')->node('entry')->add(
						month => $month,
						day   => $day,
						name  => '振替休日',
					);
					last;
				}
			}
		}
	} elsif ($dt->getYear >= 1974) {
		if ($dt->getWday == 0) {
			$dt->nextDay;
			my $year = sprintf('%02d', $dt->getYear);
			my $month = sprintf('%02d', $dt->getMonth);
			my $day = sprintf('%02d', $dt->getDay);
			if(!exists($HOLIDAYDATA->{$year}{$month}{$day})) {
				$HOLIDAYDATA->{$year}{$month}{$day} = '振替休日';
				$t->node('year')->node('entry')->add(
					month => $month,
					day   => $day,
					name  => '振替休日',
				);
			}
		}
	}

}

sub expand_equinox_day ($) {
	my $year = shift;

	my $spring_tmp;
	my $spring_year_tmp;
	my $autumn_tmp;
	my $year_tmp;

	if($year <= 1899) {
		$spring_tmp = 19.8277;
		$autumn_tmp = 22.2588;
		$year_tmp = 1983;
	} elsif($year <= 1979) {
		$spring_tmp = 20.8357;
		$autumn_tmp = 23.2588;
		$year_tmp = 1983;
	} elsif($year <= 2099) {
		$spring_tmp = 20.8431;
		$autumn_tmp = 23.2488;
		$year_tmp = 1980;
	} elsif($year <= 2150) {
		$spring_tmp = 21.8510;
		$autumn_tmp = 24.2488;
		$year_tmp = 1980;
	} else {
		return;
	}

	my $spring = int($spring_tmp +
		0.242194 * ($year - 1980) -
		int(($year - $year_tmp) / 4));

	my $autumn = int($autumn_tmp +
		0.242194 * ($year - 1980) -
		int(($year - $year_tmp) / 4));

	entry $year, 3, $spring, '春分の日';
	entry $year, 9, $autumn, '秋分の日';
}

sub expand_keichou ($) {
	my $year = shift;

	if ($year == 1959) {
		entry $year,  4, 10, '皇太子明仁親王の結婚の儀';
	}
	elsif ($year == 1989) {
		entry $year,  2, 24, '昭和天皇の大喪の礼';
	}
	elsif ($year == 1990) {
		entry $year, 11, 12, '即位礼正殿の儀';
	}
	elsif ($year == 1993) {
		entry $year,  6,  9, '皇太子徳仁親王の結婚の儀';
	}
}

sub expand_happy_monday ($) {
	my $year = shift;

	my $nth_monday = sub {
		# 与えられた日付以降の第 n 月曜を探す。
		my $d = shift;
		my $n = shift;
		my $count = 0;
		while($count < $n) {
			$d->nextDay;
			$count++ if($d->getWday == 1);
		}
		$d;
	};

	if($year >= 2000) {
		my $yeartemp = $year - 1;
		entry $nth_monday->(
			$TL->newDateTime("$yeartemp-12-31") => 2) => '成人の日';

		entry $nth_monday->(
			$TL->newDateTime("$year-09-30") => 2) => '体育の日';
	} else {
		entry $year,  1, 15, '成人の日';
		entry $year, 10, 10, '体育の日' if $year >= 1966;
	}

	if($year >= 2003) {
		entry $nth_monday->(
			$TL->newDateTime("$year-06-30") => 3) => '海の日';

		entry $nth_monday->(
			$TL->newDateTime("$year-08-31") => 3) => '敬老の日';
	} else {
		entry $year, 7, 20, '海の日' if $year >= 1996;
		entry $year, 9, 15, '敬老の日' if $year >= 1966;
	}
}

sub print_node ($) {
	my $year = shift;
	
	my $olddt;
	my $ytmp = $HOLIDAYDATA->{$year};
	foreach my $month (sort keys %$ytmp){
		my $mtmp = $ytmp->{$month};
		foreach my $day (sort keys %$mtmp){
			$t->node('year')->node('entry')->add(
				month => $month,
				day   => $day,
				name  => $HOLIDAYDATA->{$year}{$month}{$day},
			);

			#ここで振替休日と国民の休日を計算して出力する
			my $dt = $TL->newDateTime->setYear($year)->setMonth($month)->setDay($day);
			expand_substitute_holiday $dt;
			expand_national_holiday $dt, $olddt;
			$olddt = $dt;
		}
	}
}

sub expand_year ($) {
	my $year = shift;

	# 春分の日と秋分の日
	expand_equinox_day $year;

	# 皇室慶弔行事に伴う休日
	expand_keichou $year;

	# 毎年変化しない祝日
	entry $year,  1,  1, '元旦';
	
	if($year >= 1967) {
		entry $year,  2, 11, '建国記念日';
	}
	if ($year >= 2007) {
		entry $year,  4, 29, '昭和の日';
		entry $year,  5,  4, 'みどりの日';
	} elsif($year >= 1989) {
		entry $year,  4, 29, 'みどりの日';
	} else {
		# 昭和天皇
		entry $year,  4, 29, '天皇誕生日';
	}
	entry $year,  5,  3, '憲法記念日';
	entry $year,  5,  5, 'こどもの日';
	entry $year, 11,  3, '文化の日';
	entry $year, 11, 23, '勤労感謝の日';
	# 今上天皇
	if($year >= 1989) {
		entry $year, 12, 23, '天皇誕生日';
	}


	# その他
	expand_happy_monday $year;

	#node出力
	print_node $year;

	$t->node('year')->add(
		year => sprintf('%04d', $year),
	   );
}

sub expand () {
	my $dt = $TL->newDateTime;

	# 1948（祝日法施行・厳密には48年は）～+ 30 年分を計算。
	foreach (1948 .. ($dt->getYear + 30)) {
		expand_year $_;
	}
}

expand;

mkpath 'lib/Tripletail/DateTime', 1;
print "Writing lib/Tripletail/DateTime/JPHoliday.pm...\n";

open my $fh, '>', 'lib/Tripletail/DateTime/JPHoliday.pm' or die $!;
print $fh $t->toStr;

__END__
# -----------------------------------------------------------------------------
# このファイルは data/jpholiday.pl によって生成されています。
# 手動での修正はお止め下さい。
# -----------------------------------------------------------------------------
# This file has been generated by data/jpholiday.pl.
# Do not edit this by hand.
# -----------------------------------------------------------------------------
package Tripletail::DateTime::JPHoliday;
use strict;
use warnings;

1;

our %HOLIDAY = (
	<!begin:YEAR>
	  <&YEAR> => {
		  <!begin:ENTRY>'<&MONTH>-<&DAY>' => '<&NAME>', <!end:ENTRY>
		 },
	<!end:YEAR>
   );

__END__

=encoding utf-8

=head1 NAME

Tripletail::DateTime::JPHoliday - Holiday of Japan (ja)

=head1 NAME (ja)

Tripletail::DateTime::JPHoliday::JA - 日本の祝日

=head1 DESCRIPTION

L<Tripletail::DateTime> によって内部的に使用される。祝日法のみ対応。

=cut

