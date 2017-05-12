# -----------------------------------------------------------------------------
# Tripletail::DateTime - 日付と時刻を扱う
# -----------------------------------------------------------------------------
package Tripletail::DateTime;
use strict;
use warnings;
use Tripletail;
use Tripletail::DateTime::JPHoliday;

our @WDAY_NAME = qw(Sun Mon Tue Wed Thu Fri Sat);

our @WDAY_NAME_LONG = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);

our @J_WDAY_NAME = qw(日 月 火 水 木 金 土);

our @MONTH_NAME = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

our @J_MONTH_NAME = qw(睦月 如月 弥生 卯月 皐月 水無月 文月 葉月 長月 神無月 霜月 師走);

our @ANIMAL_NAME = ('子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥');

our @MONTH_NAME_LONG = qw(January February March April May June July
                      August September October November December);

our %HOLIDAY = (
		'01-01' => '元旦',
		'02-11' => '建国記念日',
		'04-29' => 'みどりの日',
		'05-03' => '憲法記念日',
		'05-05' => 'こどもの日',
		'11-03' => '文化の日',
		'11-23' => '勤労感謝の日',
		'12-23' => '天皇誕生日'
	);

our @JP_YEARS = (
		 [1868,  9,  8, '明治'], # 開始西暦, 開始月, 開始日, 年号
		 [1912,  7, 30, '大正'],
		 [1926, 12, 25, '昭和'],
		 [1989,  1,  8, '平成'],
		);

our %TZ_TABLE = (
		"gmt"       =>   0,          # Greenwich Mean
		"ut"        =>   0, # Universal (Coordinated)
		"utc"       =>   0,
		"wet"       =>   0, # Western European
		"wat"       =>  -1*3600, # West Africa
		"at"        =>  -2*3600, # Azores
		"ast"       =>  -4*3600, # Atlantic Standard
		"est"       =>  -5*3600, # Eastern Standard
		"cst"       =>  -6*3600, # Central Standard
		"mst"       =>  -7*3600, # Mountain Standard
		"pst"       =>  -8*3600, # Pacific Standard
		"yst"       =>  -9*3600, # Yukon Standard
		"hst"       => -10*3600, # Hawaii Standard
		"cat"       => -10*3600, # Central Alaska
		"ahst"      => -10*3600, # Alaska-Hawaii Standard
		"nt"        => -11*3600, # Nome
		"idlw"      => -12*3600, # International Date Line West
		"cet"       =>  +1*3600, # Central European
		"met"       =>  +1*3600, # Middle European
		"mewt"      =>  +1*3600, # Middle European Winter
		"swt"       =>  +1*3600, # Swedish Winter
		"fwt"       =>  +1*3600, # French Winter
		"eet"       =>  +2*3600, # Eastern Europe, USSR Zone 1
		"bt"        =>  +3*3600, # Baghdad, USSR Zone 2
		"zp4"       =>  +4*3600, # USSR Zone 3
		"zp5"       =>  +5*3600, # USSR Zone 4
		"ist"       =>  +5*3600+1800, # Indian Standard
		"zp6"       =>  +6*3600, # USSR Zone 5
		"wast"      =>  +7*3600, # West Australian Standard
		"cct"       =>  +8*3600, # China Coast, USSR Zone 7
		"jst"       =>  +9*3600, # Japan Standard, USSR Zone 8
		"east"      => +10*3600, # Eastern Australian Standard
		"gst"       => +10*3600, # Guam Standard, USSR Zone 9
		"nzt"       => +12*3600, # New Zealand
		"nzst"      => +12*3600, # New Zealand Standard
		"idle"      => +12*3600, # International Date Line East
	);
our %TZ_TABLE_OFF = reverse(%TZ_TABLE);

our %TZ_TABLE_DST = (
		 "adt"  =>   -3*3600, # Atlantic Daylight
		 "edt"  =>   -4*3600, # Eastern Daylight
		 "cdt"  =>   -5*3600, # Central Daylight
		 "mdt"  =>   -6*3600, # Mountain Daylight
		 "pdt"  =>   -7*3600, # Pacific Daylight
		 "ydt"  =>   -8*3600, # Yukon Daylight
		 "hdt"  =>   -9*3600, # Hawaii Daylight
		 "bst"  =>   +1*3600, # British Summer
		 "mest" =>   +2*3600, # Middle European Summer
		 "sst"  =>   +2*3600, # Swedish Summer
		 "fst"  =>   +2*3600, # French Summer
		 "wadt" =>   +8*3600, # West Australian Daylight
		 "eadt" =>  +11*3600, # Eastern Australian Daylight
		 "nzdt" =>  +13*3600, # New Zealand Daylight
		);
our %TZ_TABLE_DST_OFF = reverse(%TZ_TABLE_DST);

our %RFC822_TZ_TABLE = (
		Y   => 12*3600,
		N   =>  1*3600,
		GMT =>       0,
		UT  =>       0,
		Z   =>       0,
		A   => -1*3600,
		EDT => -4*3600,
		EST => -5*3600,
		CST => -6*3600,
		MST => -7*3600,
		PST => -8*3600,
		M   =>-12*3600,
	);
our %RFC822_TZ_TABLE_OFF = reverse %RFC822_TZ_TABLE;

sub __a2h (@) {
	my $i = 0;
	map { $_ => ++$i } @_;
}

sub __a2r (@) {
	local($_);
	$_ = join '|', @_;
	qr/$_/;
}

sub __a2r_i (@) {
	local($_);
	$_ = join '|', @_;
	qr/$_/i;
}

my %MONTH_HASH = __a2h @MONTH_NAME;
my %MONTH_LONG_HASH = __a2h @MONTH_NAME_LONG;
my %J_MONTH_HASH = __a2h @J_MONTH_NAME;
my %WDAY_HASH = __a2h @WDAY_NAME;
my %WDAT_LONG_HASH = __a2h @WDAY_NAME_LONG;

my $re_2year = qr/\d{2}/;
my $re_4year = qr/\d{4}/;
my $re_2month = qr/0[1-9]|1[0-2]/;
my $re_2day = qr/0[1-9]|[12][0-9]|3[01]/;
my $re_2hms = qr/[0-5][0-9]/;
my $re_anydelim = qr/[ !@#$%^&*\-_+=|\\~`:;"',.\?\/]/;

my $re_1month = qr/0?[1-9]|1[0-2]/;
my $re_1day = qr/0?[1-9]|[12][0-9]|3[01]/;
my $re_1hms = qr/0?[0-9]|[1-5][0-9]/;

my $re_hms = qr/($re_2hms):($re_2hms):($re_2hms)/;

my $re_generic_ymd = qr/($re_4year)$re_anydelim?($re_2month)$re_anydelim?($re_2day)/;
my $re_generic_hms = qr/($re_2hms)$re_anydelim?($re_2hms)$re_anydelim?($re_2hms)/;
my $re_generic_ymdhms = qr/$re_generic_ymd\s*$re_generic_hms/;

my $re_fuzzy_generic_ymd = qr/($re_4year)$re_anydelim($re_1month)$re_anydelim($re_1day)/;
my $re_fuzzy_generic_hms = qr/($re_1hms)$re_anydelim($re_1hms)$re_anydelim($re_1hms)/;
my $re_fuzzy_generic_ymdhms = qr/$re_fuzzy_generic_ymd\s*$re_fuzzy_generic_hms/;

my $re_wdy = __a2r @WDAY_NAME;
my $re_wdy_long = __a2r @WDAY_NAME_LONG;
my $re_month = __a2r @MONTH_NAME;
my $re_month_long = __a2r @MONTH_NAME_LONG;
my $re_j_wday = __a2r @J_WDAY_NAME;
my $re_j_month = __a2r @J_MONTH_NAME;
my $re_tz_name = __a2r_i(keys(%TZ_TABLE), keys(%TZ_TABLE_DST));
my $re_jp_year_name = __a2r(map {$_->[3]} @JP_YEARS);
my $re_animal_name = __a2r @ANIMAL_NAME;

my $re_w3c_tz = qr/Z|[+\-]\d{2}:\d{2}/;
my $re_hex_byte = qr/(?:[0-9a-f]){2}/;

my $re_rfc822_tz = do {
	my $r = __a2r keys(%RFC822_TZ_TABLE);
	$r .= '|' . qr/[+\-]\d{4}/;
	$r;
};

my $re_ampm = qr/[ap]\.?m\.?/i;
my $re_j_ampm = qr/午前|午後/;

my $re_date_cmd = qr/$re_wdy ($re_month) ($re_2day) $re_hms (\S+) ($re_4year)/;
my $re_apache_access = qr!($re_2day)/($re_month)/($re_4year):$re_hms (\S+)!;
my $re_apache_error = qr/$re_wdy ($re_month) ($re_2day) $re_hms ($re_4year)/;
my $re_apache_index = qr/($re_2day)-($re_month)-($re_4year) $re_hms/;
my $re_rfc_822 = qr/$re_wdy, ($re_2day) ($re_month) (\d{2}|\d{4}) $re_hms ($re_rfc822_tz)/;
# TODO: ↑「($re_month)」の前後の空白等は、rfc822では確かに空白だが、
#         rfc2822ではFWSになっているので、その辺を直すべきかもしれない
#         (しかし下手にいじると問題になるかも)
my $re_rfc_850 = qr/$re_wdy, ($re_2day)-($re_month)-(\d{2}|\d{4}) $re_hms ($re_rfc822_tz)/;

1;

sub _new {
	my $pkg = shift;
	my $this = bless {} => $pkg;

	$this->{jd} = undef; # ユリウス日 (小数)
	$this->{tz} = undef; # UTCとの時差 (整数、秒)

	$this->{greg_cache} = undef;

	$this->set(@_);
	$this;
}

sub clone {
	my $this = shift;

	bless { %$this } => ref($this);
}

sub set {
	my $this = shift;
	my $val = shift;

	if(ref($val))
	{
		if( !Tripletail::_isa($val, ref($this)) ) {
			die __PACKAGE__."#set: arg[1] is a reference. (第1引数がリファレンスです)\n";
		}
		$val = $val->toStr();
	}

	if(!$val) {
		# 現在の時刻に設定
		$this->setTimeZone;
		$this->setEpoch(time);
		return $this;
	}

	if(!$this->{tz}) {
		$this->setTimeZone;
	}

	my $greg = {
		month => 1,
		day => 1,
		hour => 0,
		min  => 0,
		sec  => 0,
		tz   => $this->{tz},
	};

	if($val =~ m/^$re_generic_ymdhms$/o or $val =~ m/^$re_fuzzy_generic_ymdhms$/) {
		$greg->{year} = $1;
		$greg->{mon} = $2;
		$greg->{day} = $3;
		$greg->{hour} = $4;
		$greg->{min} = $5;
		$greg->{sec} = $6;
	} elsif($val =~ m/^$re_generic_ymd$/o or $val =~ m/^$re_fuzzy_generic_ymd$/) {
		$greg->{year} = $1;
		$greg->{mon} = $2;
		$greg->{day} = $3;
	} elsif($val =~ m/^$re_date_cmd$/o) {
		$greg->{mon} = $MONTH_HASH{$1};
		$greg->{day} = $2;
		$greg->{hour} = $3;
		$greg->{min} = $4;
		$greg->{sec} = $5;
		$greg->{tz} = $this->__getTZByName($6);
		$greg->{year} = $7;

		defined $greg->{tz} or die __PACKAGE__."#set: unknown timezone: $6 (不正なタイムゾーンです)\n";
	} elsif($val =~ m/^$re_apache_access$/o) {
		$greg->{day} = $1;
		$greg->{mon} = $MONTH_HASH{$2};
		$greg->{year} = $3;
		$greg->{hour} = $4;
		$greg->{min} = $5;
		$greg->{sec} = $6;
		$greg->{tz} = $this->__parseRFC822TimeZone($7);
	} elsif($val =~ m/^$re_apache_error$/o) {
		$greg->{mon} = $MONTH_HASH{$1};
		$greg->{day} = $2;
		$greg->{hour} = $3;
		$greg->{min} = $4;
		$greg->{sec} = $5;
		$greg->{year} = $6;
	} elsif($val =~ m/^$re_apache_index$/o) {
		$greg->{day} = $1;
		$greg->{mon} = $MONTH_HASH{$2};
		$greg->{year} = $3;
		$greg->{hour} = $4;
		$greg->{min} = $5;
		$greg->{sec} = $6;
	} elsif($val =~ m/^$re_rfc_822$/o || $val =~ m/^$re_rfc_850$/o) {
		$greg->{day} = $1;
		$greg->{mon} = $MONTH_HASH{$2};
		$greg->{year} = $this->__widenYearOf2Cols($3);
		$greg->{hour} = $4;
		$greg->{min} = $5;
		$greg->{sec} = $6;
		$greg->{tz} = $this->__parseRFC822TimeZone($7);
	} elsif($val =~ m/^($re_4year)$/o
	|| $val =~ m/^($re_4year)-($re_2month)$/o
	|| $val =~ m/^($re_4year)-($re_2month)-($re_2day)$/o
	|| $val =~ m/^($re_4year)-($re_2month)-($re_2day)T($re_2hms):($re_2hms)($re_w3c_tz)$/o
	|| $val =~ m/^($re_4year)-($re_2month)-($re_2day)T($re_2hms):($re_2hms):($re_2hms)($re_w3c_tz)$/o
	|| $val =~ m/^($re_4year)-($re_2month)-($re_2day)T($re_2hms):($re_2hms):($re_2hms)\.\d+($re_w3c_tz)$/o) {
		$greg->{year} = $1;
		$greg->{mon} = $2 || 1;
		$greg->{day} = $3 || 1;
		$greg->{hour} = $4 || 0;
		$greg->{min} = $5 || 0;
		if($6) {
			if($7) {
				$greg->{sec} = $6 || 0;
				$greg->{tz} = $this->__parseW3CTimeZone($7);
			} else {
				$greg->{tz} = $this->__parseW3CTimeZone($6);
			}
		}
	} else {
		die __PACKAGE__."#set: failed to parse the date: $val (不正な日付形式です)\n";
	}

	$this->setJulianDay($this->__getJulian($greg));
	$this;
}

sub setEpoch {
	my $this = shift;
	my $epoch = shift;

	if(!defined($epoch)) {
		die __PACKAGE__."#setEpoch: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($epoch)) {
		die __PACKAGE__."#setEpoch: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($epoch !~ m/^-?\d+$/) {
		die __PACKAGE__."#setEpoch: arg[1] is not a number. (第1引数が数字ではありません)\n";
	}

	$this->setJulianDay($this->__getJulianOfEpoch + $epoch / 86400);
	$this;
}

sub setJulianDay {
	my $this = shift;
	my $jd = shift;

	if(!defined($jd)) {
		die __PACKAGE__."#setJulianDay: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($jd)) {
		die __PACKAGE__."#setJulianDay: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($jd !~ m/^-?[\d\.]+$/) {
		die __PACKAGE__."#setJulianDay: arg[1] is not a number. (第1引数が数字ではありません)\n";
	}

	$this->{jd} = $jd;
	$this->{greg_cache} = undef;
	$this;
}

sub setYear {
	my $this = shift;
	my $year = shift;

	if(!defined($year)) {
		die __PACKAGE__."#setYear: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($year)) {
		die __PACKAGE__."#setYear: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($year !~ m/^-?\d+$/) {
		die __PACKAGE__."#setYear: arg[1] is not a number. (第1引数が数字ではありません)\n";
	}

	my $greg = $this->__getGregorian();
	$greg->{year} = $year;
	$this->setJulianDay($this->__getJulian($greg));
}

sub setMonth {
	my $this = shift;
	my $mon = shift;

	if(!defined($mon)) {
		die __PACKAGE__."#setMonth: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($mon)) {
		die __PACKAGE__."#setMonth: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($mon !~ m/^-?\d+$/) {
		die __PACKAGE__."#setMonth: arg[1] is not a number. (第1引数が数字ではありません)\n";
	} elsif($mon == 0) {
		die __PACKAGE__."#setMonth: arg[1] == 0. (月が0です)\n";
	} elsif($mon >= 13) {
		die __PACKAGE__."#setMonth: arg[1] >= 13. (月が13以上です)\n";
	} elsif($mon <= -13) {
		die __PACKAGE__."#setMonth: arg[1] <= -13. (月が-13以下です)\n";
	}

	if($mon < 0) {
		$mon += 13;
	}

	my $greg = $this->__getGregorian();
	$this->setJulianDay($this->addMonth($mon - $greg->{mon})->getJulianDay);
}

sub setDay {
	my $this = shift;
	my $day = shift;

	if(!defined($day)) {
		die __PACKAGE__."#setDay: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($day)) {
		die __PACKAGE__."#setDay: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($day !~ m/^-?\d+$/) {
		die __PACKAGE__."#setDay: arg[1] is not a number. (第1引数が数字ではありません)\n";
	} elsif($day == 0) {
		die __PACKAGE__."#setDay: arg[1] == 0. (日が0です)\n";
	}

	my $greg = $this->__getGregorian();

	my $last = $this->__lastDayOfMonth;
	if($day > $last) {
		die sprintf(__PACKAGE__."#setDay: %04d-%02d-%02d does not exist. (%04d-%02d-%02dの日付は存在しません\n",
			$greg->{year}, $greg->{mon}, $day,
			$greg->{year}, $greg->{mon}, $day);
	} elsif($day < -1 * $last) {
		die sprintf(__PACKAGE__."#setDay: %04d-%02d-%02d does not exist. (%04d-%02d-%02dの日付は存在しません)\n",
			$greg->{year}, $greg->{mon}, $day + $last + 1,
			$greg->{year}, $greg->{mon}, $day + $last + 1);
	}

	if($day < 0) {
		$day += $last + 1;
	}

	$this->setJulianDay($this->addDay($day - $greg->{day})->getJulianDay);
}

sub setHour {
	my $this = shift;
	my $hour = shift;

	if(!defined($hour)) {
		die __PACKAGE__."#setHour: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($hour)) {
		die __PACKAGE__."#setHour: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($hour !~ m/^-?\d+$/) {
		die __PACKAGE__."#setHour: arg[1] is not a number. (第1引数が数字ではありません)\n";
	} elsif($hour >= 24) {
		die __PACKAGE__."#setHour: arg[1] >= 24. (第1引数が24以上です)\n";
	} elsif($hour <= -24) {
		die __PACKAGE__."#setHour: arg[1] <= -24. (第1引数が-24以下です)\n";
	}

	if($hour < 0) {
		$hour += 24;
	}

	my $greg = $this->__getGregorian();
	$this->setJulianDay($this->addHour($hour - $greg->{hour})->getJulianDay);
}

sub setMinute {
	my $this = shift;
	my $min = shift;

	if(!defined($min)) {
		die __PACKAGE__."#setMinute: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($min)) {
		die __PACKAGE__."#setMinute: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($min !~ m/^-?\d+$/) {
		die __PACKAGE__."#setMinute: arg[1] is not a number. (第1引数が数字ではありません)\n";
	} elsif($min >= 60) {
		die __PACKAGE__."#setHour: arg[1] >= 60. (第1引数が60以上です)\n";
	} elsif($min <= -60) {
		die __PACKAGE__."#setHour: arg[1] <= -60. (第1引数が-60以下です)\n";
	}

	if($min < 0) {
		$min += 60;
	}

	my $greg = $this->__getGregorian();
	$this->setJulianDay($this->addMinute($min - $greg->{min})->getJulianDay);
}

sub setSecond {
	my $this = shift;
	my $sec = shift;

	if(!defined($sec)) {
		die __PACKAGE__."#setSecond: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($sec)) {
		die __PACKAGE__."#setSecond: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($sec !~ m/^-?\d+$/) {
		die __PACKAGE__."#setSecond: arg[1] is not a number. (第1引数が数字ではありません)\n";
	} elsif($sec >= 60) {
		die __PACKAGE__."#setSecond: arg[1] >= 60. (第1引数が60以上です)\n";
	} elsif($sec <= -60) {
		die __PACKAGE__."#setSecond: arg[1] <= -60. (第1引数が-60以下です)\n";
	}

	if($sec < 0) {
		$sec += 60;
	}

	my $greg = $this->__getGregorian();
	$this->setJulianDay($this->addSecond($sec - $greg->{sec})->getJulianDay);
}

sub setTimeZone {
	my $this = shift;
	my $tz = shift;

	local($_);

	if(ref($tz)) {
		die __PACKAGE__."#setTimeZone: arg[1] is a reference. (第1引数がリファレンスです)\n";
	}

	if(!defined($tz)) {
		# localtimeとgmtimeの差から計算
		my @local = localtime(0);
		my @gmt = gmtime(0);

		$this->{tz} =
			($local[0] - $gmt[0]) +
			($local[1] - $gmt[1]) * 60 +
			($local[2] - $gmt[2]) * 3600;
	} elsif(defined($_ = $this->__getTZByName($tz))) {
		$this->{tz} = $_;
	} elsif($tz =~ m/^([+\-])(\d{2})(?::)?(\d{2})$/) {
		$this->{tz} = ($1 eq '-' ? -1 : 1) * ($2 * 3600 + $3 * 60);
	} elsif($tz =~ m/^-?\d+$/) {
		$this->{tz} = $tz * 3600;
	} else {
		die __PACKAGE__."#setTimeZone: unrecognized TimeZone: $tz (認識できないタイムゾーンです)\n";
	}

	$this->{greg_cache} = undef;
	$this;
}

sub getEpoch {
	my $this = shift;

	my $jep = $this->__getJulianOfEpoch;
	
	my $epoch = ($this->{jd} - $jep) * 86400;
	int($epoch + ($epoch >= 0 ? 0.5 : -0.5));
}

sub getJulianDay {
	my $this = shift;

	$this->{jd};
}

sub getYear {
	my $this = shift;
	$this->__getGregorian()->{year};
}

sub getMonth {
	my $this = shift;
	$this->__getGregorian()->{mon};
}

sub getDay {
	my $this = shift;
	$this->__getGregorian()->{day};
}

sub getHour {
	my $this = shift;
	$this->__getGregorian()->{hour};
}

sub getMinute {
	my $this = shift;
	$this->__getGregorian()->{min};
}

sub getSecond {
	my $this = shift;
	$this->__getGregorian()->{sec};
}

sub getWday {
	my $this = shift;
	$this->__getGregorian()->{wday};
}

sub getTimeZone {
	my $this = shift;

	$this->{tz} / 3600;
}

sub getAnimal {
	my $this = shift;
	($this->getYear - 4) % 12;
}

sub getAllHolidays {
	my $this = shift;

	my $table = $Tripletail::DateTime::JPHoliday::HOLIDAY{sprintf '%04d', $this->getYear};
	$table ? { %$table } : {};		
}

sub isHoliday {
	my $this = shift;
	my $type = shift;
	
	$type = 0 if(!defined($type));

	if($type == 1) {
		return 1 if($this->getWday == 0 || defined($this->getHolidayName));
	} elsif($type == 2) {
		return 1 if(defined($this->getHolidayName));
	} else {
		return 1 if($this->getWday == 0 || $this->getWday == 6 || defined($this->getHolidayName));
	}

	undef;
}

sub isLeapYear {
	my $this = shift;
	my $greg = $this->__getGregorian();

	(($greg->{year} % 4 == 0
		&& $greg->{year} % 100 != 0
		|| $greg->{year} % 400 == 0 ) ? 1 : undef);
}

sub getHolidayName {
	my $this = shift;

	local($_);

	my $holidays = $this->getAllHolidays;
	my $key = sprintf '%02d-%02d', $this->getMonth, $this->getDay;

	if($_ = $holidays->{$key}) {
		$_;
	} else {
		undef;
	}
}

sub getCalendar {
	my $this = shift;
	my $year = $this->getYear;
	my $mon = $this->getMonth;

	my $dt = $this->clone;
	my @calendar;
	foreach my $d (1 .. $dt->__lastDayOfMonth) {
		$dt->setDay($d);
		push @calendar, $dt->clone;
	}
	\@calendar;
}

sub getCalendarMatrix {
	my $this = shift;

	my $opt = {
		type => 'normal',
		begin => 'sun',
	};
	my $arg = ref($_[0]) ? shift : {@_};
	foreach my $key (keys %$arg) {
		$key =~ s/^-//; # key is copied.
		$opt->{$key} = $arg->{$key};
	}

	my $begin = {
		qw(sun 0 mon 1 tue 2 wed 3 thu 4 fri 5 sat 6)
	}->{lc($opt->{begin})};
	if( !defined($begin) )
	{
		die __PACKAGE__."#getCalendarMatrix: opt[begin] is invalid: $_ (beginが指定が不正です)\n";
	}

	if($opt->{type} ne 'normal' && $opt->{type} ne 'fixed') {
		die __PACKAGE__."#getCalendarMatrix: opt[type] is invalid: $opt->{type} (typeの指定が不正です)\n";
	}

	my $this_month_1st = $this->clone->setDay(1);
	
	my $start_day;
	{
		my $daysback = ($this_month_1st->getWday()+7 - $begin)%7;
		$start_day = $this_month_1st->clone()->addDay(-$daysback);
	}
	
	my $weeks;
	if( $opt->{type} eq 'fixed' )
	{
		$weeks = 6;
	}else
	{
		my $end_day = $start_day->clone()->addDay(6*7);
		my $daysback = $end_day->getDay()-1;
		$weeks = 6 - int($daysback/7);
	}
	my $day = $start_day->clone();
	my $matrix = [];
	foreach (1..$weeks)
	{
		my @week;
		foreach(0..6)
		{
			push(@week, $day->clone());
			$day->addDay(1);
		}
		push(@$matrix, \@week);
	}

	$matrix;
}

sub minusSecond {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#minusSecond: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);

	my $span = ($dt_base->{jd} - $dt_sub->{jd});
	my $day = int($span);
	my $f = $span - $day;
	my $hour = int($f * 24);
	my $min = int(($f * 24 - $hour) * 60);
	my $sec = ($f * 24 * 60 - $hour * 60 - $min) * 60;
	$sec = int($sec + ($sec >= 0 ? 0.5 : -0.5));

	$sec + $min * 60 + $hour * 3600 + $day * 86400;
}

sub spanSecond {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#minusSecond: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	$this->minusSecond(@_);
}

sub minusMinute {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#minusMinute: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);
	
	$dt_base->setSecond(0);
	$dt_sub->setSecond(0);
	
	my $span = ($dt_base->{jd} - $dt_sub->{jd});
	my $day = int($span);
	my $f = $span - $day;
	my $hour = int($f * 24);
	my $min = int(($f * 24 - $hour) * 60);
	my $sec = ($f * 24 * 60 - $hour * 60 - $min) * 60;
	$sec = int($sec + ($sec >= 0 ? 0.5 : -0.5));

	if($sec >= 60) {
		$min++;
	} elsif($sec <= -60) {
		$min-- ;
	}

	$min + $hour * 60 + $day * 1440;
}

sub spanMinute {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#spanMinute: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);

	my $span = ($dt_base->{jd} - $dt_sub->{jd});
	my $day = int($span);
	my $f = $span - $day;
	my $hour = int($f * 24);
	my $min = int(($f * 24 - $hour) * 60);
	my $sec = ($f * 24 * 60 - $hour * 60 - $min) * 60;
	$sec = int($sec + ($sec >= 0 ? 0.5 : -0.5));

	if($sec >= 60) {
		$min++;
	} elsif($sec <= -60) {
		$min-- ;
	}

	$min + $hour * 60 + $day * 1440;
}

sub minusHour {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#minusHour: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);

	$dt_base->setSecond(0);
	$dt_base->setMinute(0);
	$dt_sub->setSecond(0);
	$dt_sub->setMinute(0);

	my $span = ($dt_base->{jd} - $dt_sub->{jd});
	my $day = int($span);
	my $f = $span - $day;
	my $hour = int($f * 24);
	my $min = int(($f * 24 - $hour) * 60);
	my $sec = ($f * 24 * 60 - $hour * 60 - $min) * 60;
	$sec = int($sec + ($sec >= 0 ? 0.5 : -0.5));

	if($sec >= 60) {
		$min++;
	} elsif($sec <= -60) {
		$min-- ;
	}
	if($min >= 60) {
		$hour++;
	} elsif($min <= -60) {
		$hour-- ;
	}

	$hour + $day * 24;
}

sub spanHour {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#spanHour: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);

	my $span = ($dt_base->{jd} - $dt_sub->{jd});
	my $day = int($span);
	my $f = $span - $day;
	my $hour = int($f * 24);
	my $min = int(($f * 24 - $hour) * 60);
	my $sec = ($f * 24 * 60 - $hour * 60 - $min) * 60;
	$sec = int($sec + ($sec >= 0 ? 0.5 : -0.5));

	if($sec >= 60) {
		$min++;
	} elsif($sec <= -60) {
		$min-- ;
	}
	if($min >= 60) {
		$hour++;
	} elsif($min <= -60) {
		$hour-- ;
	}

	$hour + $day * 24;
}

sub spanDay {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#spanDay: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);

	my $span = ($dt_base->{jd} - $dt_sub->{jd});
	my $day = int($span);
	my $f = $span - $day;
	my $hour = int($f * 24);
	my $min = int(($f * 24 - $hour) * 60);
	my $sec = ($f * 24 * 60 - $hour * 60 - $min) * 60;
	$sec = int($sec + ($sec >= 0 ? 0.5 : -0.5));

	if($sec >= 60) {
		$min++;
	} elsif($sec <= -60) {
		$min-- ;
	}
	if($min >= 60) {
		$hour++;
	} elsif($min <= -60) {
		$hour-- ;
	}
	if($hour >= 24) {
		$day++;
	} elsif($hour <= -24) {
		$day-- ;
	}

	$day;
}

sub _prepare_biop
{
	my $this = shift;
	my @values;
	if( @_==0 )
	{
		return;
	}elsif( @_==1 )
	{
		# $val1->method($val2);
		@values = ($this,$_[0]);
	}else
	{
		# $x->method($val1, $val2);
		@values = ($_[0],$_[1]);
	}
	foreach my $val (@values)
	{
		if( ref($val) && Tripletail::_isa($val, ref($this)) )
		{
			$val = $val->clone();
		}else
		{
			$val = $this->clone()->set($val);
		}
	}
	@values;
}

sub minusDay {
	my $this = shift;
	
	if( @_==0 )
	{
		die __PACKAGE__."#minusDay: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);
	
	$dt_base->setSecond(0);
	$dt_base->setMinute(0);
	$dt_base->setHour(0);
	$dt_sub->setSecond(0);
	$dt_sub->setMinute(0);
	$dt_sub->setHour(0);

	my $span = ($dt_base->{jd} - $dt_sub->{jd});
	my $day = int($span);
	my $f = $span - $day;
	my $hour = int($f * 24);
	my $min = int(($f * 24 - $hour) * 60);
	my $sec = ($f * 24 * 60 - $hour * 60 - $min) * 60;
	$sec = int($sec + ($sec >= 0 ? 0.5 : -0.5));

	if($sec >= 60) {
		$min++;
	} elsif($sec <= -60) {
		$min-- ;
	}
	if($min >= 60) {
		$hour++;
	} elsif($min <= -60) {
		$hour-- ;
	}
	if($hour >= 24) {
		$day++;
	} elsif($hour <= -24) {
		$day-- ;
	}

	$day;
}

sub spanMonth {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#spanMonth: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);

	my $reverse;
	if($dt_base->{jd} < $dt_sub->{jd}){
		$reverse = 1;
		($dt_base, $dt_sub) = ($dt_sub, $dt_base);
	}

	my $greg1 = $dt_base->__getGregorian();
	my $greg2 = $dt_sub->__getGregorian();

	my $spanmon = ($greg1->{year} - $greg2->{year}) * 12 + ($greg1->{mon} - $greg2->{mon});

	if(sprintf('%02d%02d%02d%02d',$greg1->{day},$greg1->{hour},$greg1->{min},$greg1->{sec})
	   < sprintf('%02d%02d%02d%02d',$greg2->{day},$greg2->{hour},$greg2->{min},$greg2->{sec})) {
		 $spanmon--;
	}
	
	$spanmon = 0 - $spanmon if(defined($reverse));
	
	$spanmon;
}

sub minusMonth {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#minusMonth: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);

	my $greg1 = $dt_base->__getGregorian();
	my $greg2 = $dt_sub->__getGregorian();

	($greg1->{year} - $greg2->{year}) * 12 + ($greg1->{mon} - $greg2->{mon});
}

sub spanYear {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#spanYear: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);

	my $reverse;
	if($dt_base->{jd} < $dt_sub->{jd}){
		$reverse = 1;
		($dt_base,$dt_sub) = ($dt_sub,$dt_base);
	}

	my $greg1 = $dt_base->__getGregorian();
	my $greg2 = $dt_sub->__getGregorian();

	my $spanyear = $greg1->{year} - $greg2->{year};

	if(sprintf('%02d%02d%02d%02d%02d',$greg1->{mon},$greg1->{day},$greg1->{hour},$greg1->{min},$greg1->{sec})
	  < sprintf('%02d%02d%02d%02d%02d',$greg2->{mon},$greg2->{day},$greg2->{hour},$greg2->{min},$greg2->{sec})) {
		 $spanyear--;
	}
	
	$spanyear = 0 - $spanyear if(defined($reverse));
	
	$spanyear;
}

sub minusYear {
	my $this = shift;
	if( @_==0 )
	{
		die __PACKAGE__."#minusYear: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	my ($dt_base, $dt_sub) = $this->_prepare_biop(@_);

	my $greg1 = $dt_base->__getGregorian();
	my $greg2 = $dt_sub->__getGregorian();

	($greg1->{year} - $greg2->{year});
}

sub addSecond {
	my $this = shift;
	my $sec = shift;

	if(!defined($sec)) {
		die __PACKAGE__."#addSecond: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($sec)) {
		die __PACKAGE__."#addSecond: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($sec !~ m/^-?\d+$/) {
		die __PACKAGE__."#addSecond: arg[1] is not a number. (第1引数が数字ではありません)\n";
	}

	$this->setJulianDay($this->{jd} + $sec / 86400);
}

sub addMinute {
	my $this = shift;
	my $min = shift;

	if(!defined($min)) {
		die __PACKAGE__."#addMinute: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($min)) {
		die __PACKAGE__."#addMinute: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($min !~ m/^-?\d+$/) {
		die __PACKAGE__."#addMinute: arg[1] is not a number. (第1引数が数字ではありません)\n";
	}

	$this->setJulianDay($this->{jd} + $min / 1440);
}

sub addHour {
	my $this = shift;
	my $hour = shift;

	if(!defined($hour)) {
		die __PACKAGE__."#addHour: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($hour)) {
		die __PACKAGE__."#addHour: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($hour !~ m/^-?\d+$/) {
		die __PACKAGE__."#addHour: arg[1] is not a number. (第1引数が数字ではありません)\n";
	}

	$this->setJulianDay($this->{jd} + $hour / 24);
}

sub addDay {
	my $this = shift;
	my $day = shift;

	if(!defined($day)) {
		die __PACKAGE__."#addDay: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($day)) {
		die __PACKAGE__."#addDay: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($day !~ m/^-?\d+$/) {
		die __PACKAGE__."#addDay: arg[1] is not a number. (第1引数が数字ではありません)\n";
	}

	$this->setJulianDay($this->{jd} + $day);
}

sub addMonth {
	my $this = shift;
	my $mon = shift;
	my $greg = { %{$this->__getGregorian()} };

	if(!defined($mon)) {
		die __PACKAGE__."#addMonth: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($mon)) {
		die __PACKAGE__."#addMonth: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($mon !~ m/^-?\d+$/) {
		die __PACKAGE__."#addMonth: arg[1] is not a number. (第1引数が数字ではありません)\n";
	}

	$greg->{mon} += $mon;
	if($greg->{mon} < 1) {
		while($greg->{mon} < 1) {
			$greg->{year}--;
			$greg->{mon} += 12;
		}
	} elsif($greg->{mon} > 12) {
		$greg->{year} += int($greg->{mon} / 12);
		$greg->{mon} = ($greg->{mon} % 12 == 0 ? 12 : $greg->{mon} % 12);
	}
	my $tmp = $this->clone->setJulianDay($this->__getJulian({%$greg, day => 1}));
	my $last = $tmp->__lastDayOfMonth;
	if ($greg->{day} > $last) {
	$greg->{day} = $last;
	}
	$this->setJulianDay($this->__getJulian($greg));
}

sub addYear {
	my $this = shift;
	my $year = shift;
	my $greg = { %{$this->__getGregorian()} };

	if(!defined($year)) {
		die __PACKAGE__."#addYear: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($year)) {
		die __PACKAGE__."#addYear: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($year !~ m/^-?\d+$/) {
		die __PACKAGE__."#addYear: arg[1] is not a number. (第1引数が数字ではありません)\n";
	}

	$greg->{year} += $year;

	my $tmp = $this->clone->setJulianDay($this->__getJulian({%$greg, day => 1}));
	my $last = $tmp->__lastDayOfMonth;
	if($greg->{day} > $last) {
		$greg->{day} = $last;
	}
	$this->setJulianDay($this->__getJulian($greg));
}

sub nextDay {
	my $this = shift;
	$this->addDay(1);
}

sub prevDay {
	my $this = shift;
	$this->addDay(-1);
}

sub firstDay {
	my $this = shift;
	$this->setDay(1);
}

sub lastDay {
	my $this = shift;
	$this->setDay(-1);
}

sub addBusinessDay {
	my $this = shift;
	my $day = shift;
	my $type = shift;

	if(!defined($day)) {
		die __PACKAGE__."#addBusinessDay: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($day)) {
		die __PACKAGE__."#addBusinessDay: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($day !~ m/^-?\d+$/) {
		die __PACKAGE__."#addBusinessDay: arg[1] is not a number. (第1引数が数字ではありません)\n";
	}

	$this->addDay($day);
	while($this->isHoliday($type)) {
		$this->nextDay;
	}

	$this;
}

sub toStr {
	my $this = shift;
	my $format = shift || 'mysql';

	if($format eq 'mysql') {
		$this->strFormat('%Y-%m-%d %H:%M:%S');
	} elsif($format eq 'rfc822') {
		$this->strFormat('%a, %d %b %Y %H:%M:%S %z');
	} elsif($format eq 'rfc850') {
		$this->strFormat('%a, %d-%b-%Y %H:%M:%S %z');
	} elsif($format eq 'w3c') {
		$this->strFormat('%Y-%m-%dT%H:%M:%S%_z');
	} else {
		die __PACKAGE__."#toStr: unsupported format type: $format (サポートしていないフォーマットが指定されました)\n";
	}
}

sub strFormat {
	my $this = shift;
	my $format = shift;

	local($_);

	$format =~ s/%%/\0PERCENT\0/g;

	$format =~ s/%a/$WDAY_NAME[$this->getWday]/eg;
	$format =~ s/%A/$WDAY_NAME_LONG[$this->getWday]/eg;
	$format =~ s/%J/$J_WDAY_NAME[$this->getWday]/eg;

	$format =~ s/%b/$MONTH_NAME[$this->getMonth - 1]/eg;
	$format =~ s/%B/$MONTH_NAME_LONG[$this->getMonth - 1]/eg;
	$format =~ s/%_B/$J_MONTH_NAME[$this->getMonth - 1]/eg;

	$format =~ s/%d/sprintf '%02d', $this->getDay/eg;
	$format =~ s/%_d/$this->getDay/eg;

	$format =~ s/%m/sprintf '%02d', $this->getMonth/eg;
	$format =~ s/%_m/$this->getMonth/eg;

	$format =~ s/%w/$this->getWday/eg;

	$format =~ s/%y/substr sprintf('%04d', $this->getYear), 2, 2/eg;
	$format =~ s/%Y/sprintf '%04d', $this->getYear/eg;
	$format =~ s/%_Y/$this->__getJPYear/eg;

	$format =~ s/%H/sprintf '%02d', $this->getHour/eg;
	$format =~ s/%_H/$this->getHour/eg;
	$format =~ s/%I/sprintf '%02d', $this->getHour % 12/eg;
	$format =~ s/%_I/$this->getHour % 12/eg;

	my $ampm = sub {
		my $noon = $this->clone->setHour(12)->setMinute(0)->setSecond(0);
		($this->spanSecond($noon) >= 0) ? $_[1] : $_[0];
	};
	$format =~ s/%P/$ampm->('a.m.', 'p.m.')/eg;
	$format =~ s/%_P/$ampm->('午前', '午後')/eg;

	$format =~ s/%M/sprintf '%02d', $this->getMinute/eg;
	$format =~ s/%_M/$this->getMinute/eg;

	$format =~ s/%S/sprintf '%02d', $this->getSecond/eg;
	$format =~ s/%_S/sprintf $this->getSecond/eg;

	$format =~ s/%E/$ANIMAL_NAME[$this->getAnimal]/eg;

	$format =~ s/%z/$this->__getRFC822TimeZone($this->{tz})/eg;
	$format =~ s/%_z/$this->__getW3CTimeZone($this->{tz})/eg;
	$format =~ s/%Z/$_ = $this->__getTZNameBySec($this->{tz}); defined($_) ? uc : ''/eg;

	$format =~ s/%T/sprintf '%02d:%02d:%02d', $this->getHour, $this->getMinute, $this->getSecond/eg;

	$format =~ s/\0PERCENT\0/%/g;
	$format;
}

sub parseFormat {
	my $this = shift;
	my $format = shift;
	my $str = shift;

	if(!defined($format)) {
		die __PACKAGE__."#parseFormat: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($format)) {
		die __PACKAGE__."#parseFormat: arg[1] is a reference. (第1引数がリファレンスです)\n";
	}

	if(!defined($str)) {
		die __PACKAGE__."#parseFormat: arg[2] is not defined. (第2引数が指定されていません)\n";
	} elsif(ref($str)) {
		die __PACKAGE__."#parseFormat: arg[2] is a reference. (第2引数がリファレンスです)\n";
	}

	my $f = $format;
	my $regex = '';
	my @parse; # [フォーマット文字, パーサ関数], ...
	while (length $f) {
		if($f =~ s/^([^%]+)//) {
			$regex .= "\Q$1\E";
		} elsif($f =~ s/^%a//) {
			$regex .= $re_wdy;
		} elsif($f =~ s/^%A//) {
			$regex .= $re_wdy_long;
		} elsif($f =~ s/^%J//) {
			$regex .= $re_j_wday;
		} elsif($f =~ s/^%b//) {
			$regex .= "($re_month)";
			push @parse, [b => sub { $MONTH_HASH{$_[0]} }];
		} elsif($f =~ s/^%B//) {
			$regex .= "($re_month_long)";
			push @parse, [B => sub { $MONTH_LONG_HASH{$_[0]} }];
		} elsif($f =~ s/^%_B//) {
			$regex .= "($re_j_month)";
			push @parse, [_B => sub { $J_MONTH_HASH{$_[0]} }];
		} elsif($f =~ s/^%d//) {
			$regex .= "($re_2day)";
			push @parse, ['d'];
		} elsif($f =~ s/^%_d//) {
			$regex .= "($re_1day)";
			push @parse, ['_d'];
		} elsif($f =~ s/^%m//) {
			$regex .= "($re_2month)";
			push @parse, ['m'];
		} elsif($f =~ s/^%_m//) {
			$regex .= "($re_1month)";
			push @parse, ['_m'];
		} elsif($f =~ s/^%w//) {
			$regex .= "[0-6]";
		} elsif($f =~ s/^%y//) {
			$regex .= "($re_2year)";
			push @parse, ['y' => sub {
				$this->__widenYearOf2Cols($_[0]);
			}];
		} elsif($f =~ s/^%Y//) {
			$regex .= "($re_4year)";
			push @parse, ['Y'];
		} elsif($f =~ s/^%_Y//) {
			$regex .= qr/(\D+(?:\d+|元)年)/;
			push @parse, [_Y => sub {
				$this->__parseJPYear($_[0]);
			}];
		} elsif($f =~ s/^%H//) {
			$regex .= "($re_2hms)";
			push @parse, ['H'];
		} elsif($f =~ s/^%_H//) {
			$regex .= "($re_1hms)";
			push @parse, ['_H'];
		} elsif($f =~ s/^%I//) {
			$regex .= "($re_2hms)";
			push @parse, ['I'];
		} elsif($f =~ s/^%_I//) {
			$regex .= "($re_1hms)";
			push @parse, ['_I'];
		} elsif($f =~ s/^%P//) {
			$regex .= "($re_ampm)";
			push @parse, [P => sub {
				($_[0] =~ m/^a/i) ? 0 : 1;
			}];
		} elsif($f =~ s/^%_P//) {
			$regex .= "($re_j_ampm)";
			push @parse, [_P => sub {
				$_[0] eq '午前' ? 0 : 1;
			}];
		} elsif($f =~ s/^%M//) {
			$regex .= "($re_2hms)";
			push @parse, ['M'];
		} elsif($f =~ s/^%_M//) {
			$regex .= "($re_1hms)";
			push @parse, ['_M'];
		} elsif($f =~ s/^%S//) {
			$regex .= "($re_2hms)";
			push @parse, ['S'];
		} elsif($f =~ s/^%_S//) {
			$regex .= "($re_1hms)";
			push @parse, ['_S'];
		} elsif($f =~ s/^%E//) {
			$regex .= $re_animal_name;
		} elsif($f =~ s/^%z//) {
			$regex .= "($re_rfc822_tz)";
			push @parse, [z => sub {
				$this->__parseRFC822TimeZone($_[0]);
			}];
		} elsif($f =~ s/^%_z//) {
			$regex .= "($re_w3c_tz)";
			push @parse, [_z => sub {
				$this->__parseW3CTimeZone($_[0]);
			}];
		} elsif($f =~ s/^%Z//) {
			$regex .= "($re_tz_name)";
			push @parse, [Z => sub {
				$this->__getTZByName($_[0]);
			}];
		} elsif($f =~ s/^%T//) {
			$regex .= "($re_2hms:$re_2hms:$re_2hms)";
			push @parse, [T => sub {
				$_[0] =~ m/$re_hms/;
				($1, $2, $3);
			}];
		} elsif($f =~ s/^%%//) {
			$regex .= '\%';
		} else {
			die __PACKAGE__."#parseFormat: failed to parse format: $f (フォーマットの指定が不正です)\n";
		}
	}

	# フォーマット文字列に求められる制約は以下の通り:
	#   年が得られなければならない。
	#   情報の重複があってはならない。(年を二つなど)
	#   12hourとampmは常にセットで。
	my %group = (
		year => [qw(y Y _Y)],
		mon  => [qw(b B _B m _m)],
		day  => [qw(d _d)],
		hour => [qw(H _H)],
		min  => [qw(M _M)],
		sec  => [qw(S _S)],
		tz   => [qw(z _z Z)],

		'12hour' => [qw(I _I)],
		ampm   => [qw(P _P)],
	);
	my %rev_group = do {
		my %ret;
		while(my ($key, $value) = each %group) {
			$ret{$_} = $key foreach @$value;
		}
		%ret;
	};

	my %occur;
	my $check_dup = sub {
		my $group = shift;
		if($occur{$group}++) {
			my $err = {year => 'year',
				mon  => 'month',
				day  => 'day',
				hour => 'hour',
				min  => 'minute',
				sec  => 'second',
				tz   => 'timezone'}->{$group};
			die __PACKAGE__."#parseFormat: the format has multiple ${err}s. (複数の${err}が指定されています)\n";
		}
	};
	foreach my $ent (@parse) {
		if($ent->[0] eq 'T') {
			$check_dup->('hour');
			$check_dup->('min');
			$check_dup->('sec');
		} else {
			$check_dup->($rev_group{$ent->[0]});
		}
	}

	# hourが在る時には ampm は在っても無視され、12hour が在ればdie。
	# hourが無くampm/12hourの内どちらか片方のみが在ればdie。
	if($occur{hour}) {
		if($occur{'12hour'}) {
			die __PACKAGE__."#parseFormat: the format has both of 24-hour and 12-hour. (24時間表記の時と12時間表記の時の両方が指定されています)\n";
		}
	} else {
		if($occur{ampm} xor $occur{'12hour'}) {
			die __PACKAGE__."#parseFormat: the format has only one-half of 12-hour and AM/PM. (12時間表記の時とAM/PMの両方が必要です)\n";
		}
	}

	if(!$occur{year}) {
		die __PACKAGE__."#parseFormat: the format does not have any years. (フォーマットに年の指定が必要です)\n";
	}

	my @matched = ($str =~ m/^$regex$/m);
	if(!@matched) {
		die __PACKAGE__."#parseFormat: arg[2] does not match to arg[1]. (指定されたフォーマットに一致しません)\n";
	}

	if(@matched != @parse) {
		die __PACKAGE__."#parseFormat: internal error: generated regex must be invalid. (内部エラー:生成された正規表現が不正です)\n";
	}

	my $greg = {
		mon  => 1,
		day  => 1,
		hour => 0,
		min  => 0,
		sec  => 0,
		tz   => $this->{tz},

		'12hour' => undef,
		ampm   => undef, # AM => 0, PM => 1
	};
	for(my $i = 0; $i < @parse; $i++) {
		my $ent = $parse[$i];
		my $matched = $matched[$i];

		if($ent->[0] eq 'T') {
			@$greg{qw(hour min sec)} = $ent->[1]->($matched);
		} else {
			my $group = $rev_group{$ent->[0]};
			if($ent->[1]) {
				$greg->{$group} = $ent->[1]->($matched);
			} else {
				$greg->{$group} = $matched;
			}
		}
	}

	if(defined($greg->{'12hour'}) && defined($greg->{ampm})) {
		$greg->{hour} = $greg->{ampm} * 12 + $greg->{'12hour'};
	}

	$this->setJulianDay($this->__getJulian($greg));
	$this->{tz} = $greg->{tz};
}

sub __getRFC822TimeZone {
	my $this = shift;
	my $tz = shift;

	local($_);

	if($_ = $RFC822_TZ_TABLE_OFF{$tz}) {
		$_;
	} else {
		sprintf('%s%02d%02d',
			$tz < 0 ? '-' : '+',
			int($tz / 3600),
			int(($tz - int($tz / 3600) * 3600) / 60)
		);
	}
}

sub __parseRFC822TimeZone {
	my $this = shift;
	my $str = shift;

	local($_);

	if(defined($_ = $RFC822_TZ_TABLE{$str})) {
		$_;
	} elsif($str =~ m/^([+\-])(\d{2})(\d{2})$/) {
		($1 eq '-' ? -1 : 1) * ($2 * 3600 + $3 * 60);
	} else {
		die __PACKAGE__.": failed to parse RFC822 TimeZone: $str (RFC822タイムゾーンの解析に失敗しました)\n";
	}
}

sub __parseW3CTimeZone {
	my $this = shift;
	my $str = shift;

	if($str eq 'Z') {
		0;
	} elsif($str =~ m/^([+\-])(\d{2}):(\d{2})$/) {
		($1 eq '-' ? -1 : 1) * ($2 * 3600 + $3 * 60);
	} else {
		die __PACKAGE__.": failed to parse W3C TimeZone: $str (W3Cタイムゾーンの解析に失敗しました)\n";
	}
}

sub __getW3CTimeZone {
	my $this = shift;
	my $tz = shift;

	local($_);

	$_ = $tz;
	if($_ == 0) {
		'Z';
	} else {
		sprintf('%s%02d:%02d',
			$tz < 0 ? '-' : '+',
			int($_ / 3600),
			int(($_ - int($_ / 3600) * 3600) / 60)
		);
	}
}

sub __getTZByName {
	my $this = shift;
	my $name = lc shift;

	local($_);

	if(defined($_ = $TZ_TABLE{$name})) {
		$_;
	} elsif(defined($_ = $TZ_TABLE_DST{$name})) {
		$_;
	} else {
		undef;
	}
}

sub __getTZNameBySec {
	my $this = shift;
	my $sec = shift;

	local($_);

	if($_ = $TZ_TABLE_OFF{$sec}) {
		$_;
	} elsif($_ = $TZ_TABLE_DST_OFF{$sec}) {
		$_;
	} else {
		undef;
	}
}

sub __widenYearOf2Cols {
	my $this = shift;
	my $year = shift;

	if($year < 100) {
		($year < 50 ? 2000 : 1900) + $year;
	} else {
		$year;
	}
}

sub __getJPYear {
	my $this = shift;

	my @sorted = sort {
		$b->[0] <=> $a->[0]
		} @JP_YEARS;

	foreach my $ent (@sorted) {
		my $d = $this->clone->set(sprintf '%04d-%02d-%02d', @$ent[0 .. 2]);

		if($this->spanDay($d) >= 0) {
			return sprintf('%s%s年',
				$ent->[3],
				$this->getYear == $d->getYear ?
				'元' : $this->getYear - $d->getYear + 1
			);
		}
	}
}

sub __parseJPYear {
	my $this = shift;
	my $str = shift;

	if($str =~ m/^($re_jp_year_name)(\d+|元)年$/) {
		foreach my $ent (@JP_YEARS) {
			if($ent->[3] eq $1) {
				if($2 eq '元') {
					return $ent->[0];
				} else {
					return $ent->[0] + $2 - 1;
				}
			}
		}
	}

	die __PACKAGE__.": failed to parse japanese year: $str (和暦の解析に失敗しました)\n";
}

sub __lastDayOfMonth {
	my $this = shift;
	my $want_obj = shift;

	my $make_obj = sub {
		my $greg = $this->__getGregorian();
		$greg->{day} = shift;
		
		$this->clone->setJulianDay(
			$this->__getJulian($greg));
	};

	if($this->isLeapYear && $this->getMonth == 2) {
		return $want_obj ? $make_obj->(29) : 29;
	}

	my @last_days = (31,28,31,30,31,30,31,31,30,31,30,31);
	my $d = $last_days[$this->getMonth - 1];
	$want_obj ? $make_obj->($d) : $d;
}

sub __getJulianOfEpoch {
	my $this = shift;

	my ($sec, $min, $hour, $day, $mon, $year) = gmtime(0);
	$year += 1900;
	$mon++;

	$this->__getJulian({
		year => $year,
		mon  => $mon,
		day  => $day,
		hour => $hour,
		min  => $min,
		sec  => $sec,
		tz   => 0,
	});
}

sub __getJulian {
	my $this = shift;
	my $greg = shift;

	if($greg->{mon} < 3) {
		$greg->{year}--;
		$greg->{mon} += 12;
	}

	my $jd = int($greg->{year} * 365.25) - int($greg->{year} / 100) + int($greg->{year} / 400);
	$jd += int(30.59 * ($greg->{mon} - 2));
	$jd += $greg->{day};
	$jd += $greg->{hour} / 24;
	$jd += $greg->{min} / 1440;
	$jd += $greg->{sec} / 86400;
	$jd += 1721088.5;
	$jd -= $greg->{tz} / 86400;
	$jd;
}

sub __getGregorian {
	my $this = shift;
	my $tz = shift || $this->{tz};

	local($_);

	if($_ = $this->{greg_cache}) {
		return $_;
	}

	my $greg = $this->{greg_cache} = {};

	my $jd = $this->{jd} + 0.5 + $tz / 86400;
	$greg->{wday} = int($jd + 1) % 7;

	my $z = int($jd);
	my $f = $jd - $z;
	my $aa= int(($z - 1867216.25) / 36524.25);
	my $a = int($z + 1 + $aa - int($aa / 4));
	my $b = $a + 1524;
	my $c = int(($b - 122.1) / 365.25);
	my $k = int(365.25 * $c);
	my $e = int(($b - $k) / 30.6001);

	$greg->{day} = int($b - $k - int(30.6001 * $e));
#	$greg->{day} = int($greg->{day} + ($greg->{day} >= 0 ? 0.5 : -0.5));

	if($e < 13.5) {
		$greg->{mon} = $e - 1;
	} else {
		$greg->{mon} = $e - 13;
	}

	if($greg->{mon} > 2.5) {
		$greg->{year} = $c - 4716;
	} else {
		$greg->{year} = $c - 4715;
	}

	$greg->{hour} = $f * 24;
	$greg->{hour} = int($greg->{hour});
	$greg->{min} = ($f * 24 - $greg->{hour}) * 60;
	$greg->{min} = int($greg->{min});
	$greg->{sec} = ($f * 24 * 60 - $greg->{hour} * 60 - $greg->{min}) * 60;
	$greg->{sec} = int($greg->{sec} + ($greg->{sec} >= 0 ? 0.5 : -0.5));

	# 計算誤差を補正
	if($greg->{sec} == 60) {
		$greg->{sec} = 0;
		$greg->{min}++;
	}
	if($greg->{min} == 60) {
		$greg->{min} = 0;
		$greg->{hour}++;
	}

	$greg->{tz} = $tz;
	$greg;
}

__END__

=encoding utf-8

=head1 NAME

Tripletail::DateTime - 日付と時刻

=head1 SYNOPSIS

  my $dt = $TL->newDateTime('2006-02-17 15:18:01');
  $dt->addDay(1);
  $dt->addSecond(-1);
  print $dt->toStr('rfc822'); # Fri, 18 Feb 2006 15:18:00 JST

=head1 DESCRIPTION

日付と時刻を扱うクラス。グレゴリオ歴にのみ対応している。精度は秒。
うるう秒や夏時間を考慮しない。

=head2 METHODS

=over 4

=item C<< $TL->newDateTime >>

  $dt = $TL->newDateTime;         # 現在時刻
  $dt = $TL->newDateTime($str);   # 文字列をパース

Tripletail::DateTime オブジェクトを生成。
二番目の形式では、文字列から日付や時刻をパースする。

存在しない日付が指定された場合は、それが自動的に補正される。
例えば次の 2 行は同じ結果になる。

  $dt = $TL->newDateTime('2000-04-31');
  $dt = $TL->newDateTime('2000-05-01');

但し、次の行はパースに失敗する。

  $dt = $TL->newDateTime('2000-99-99'); # 正しい形式に沿っていない

パースに失敗した場合はdieする。時刻が与えられない場合は 0 時 0 分 0秒
に設定され、タイムゾーンが与えらない場合は localtime と gmtime の差か
ら求めた値が設定される。パースできる形式は次の通り。

=over 8

=item B<< 一般 >>

 YYYY-MM-DD
 YYYY-MM-DD HH:MM:SS

ハイフンやコロンは別の記号であっても良く、何も無くても良い。
例:

 YYYY@MM@DD
 YYYY/MM/DD HH.MM.SS
 YYYYMMDD
 YYYYMMDDHHMMSS

また、記号がある場合は次のように月、日、時、分、秒は一桁であっても良い。

 YYYY-M-D
 YYYY/M/D H:M:S

=item B<< date コマンド >>

 Wdy Mon DD HH:MM:SS TIMEZONE YYYY
 (Fri Feb 17 11:24:41 JST 2006)

=item B<< Apache access_log >>

 DD/Mon/YYYY:HH:MM:SS +TTTT
 (17/Feb/2006:11:24:41 +0900)

=item B<< Apache error_log >>

 Wdy Mon DD HH:MM:SS YYYY
 (Fri Feb 17 11:24:41 2006)

=item B<< Apache directory index >>

 DD-Mon-YYYY HH:MM:SS

=item B<< RFC 822 >>

 Wdy, DD Mon YY HH:MM:SS TIMEZONE
 (Fri, 17 Feb 06 11:24:41 +0900)

 Wdy, DD Mon YYYY HH:MM:SS TIMEZONE
 (Fri, 17 Feb 2006 11:24:41 +0900)

=item B<< RFC 850 >>

 Wdy, DD-Mon-YY HH:MM:SS TIMEZONE
 (Fri, 17-Feb-06 11:24:41 +0900)

 Wdy, DD-Mon-YYYY HH:MM:SS TIMEZONE
 (Fri, 17-Feb-2006 11:24:41 +0900)

=item B<< W3C Date and Time >>

 YYYY
 YYYY-MM
 YYYY-MM-DD
 YYYY-MM-DDTHH:MMTzd (2006-02-17T11:40+09:00)
 YYYY-MM-DDTHH:MM:SSTzd (2006-02-17T11:40:10+09:00)
 YYYY-MM-DDTHH:MM:SS.sTzd (2006-02-17T11:40:10.45+09:00)

ここで Tzd とはタイムゾーン指定であり、+hh:mm / -hh:mm / 'Z' の何れか
の形式で表される。Z は UTC を表す。例:

 2006-02-17T11:40:10Z

最後の形式の .s は時刻の端数を表すものであるが、このクラスの精度は秒で
あるので、端数はパース後に切り捨てられる。

=back

=item C<< clone >>

  $dt2 = $dt->clone;

DateTimeオブジェクトを複製して返す。

=item C<< set >>

  $dt->set;
  $dt->set($str);

引数はコンストラクタと同じ。

=item C<< setEpoch >>

  $dt->setEpoch($epoch);

エポックからの秒数を設定する。このクラスでエポックとは gmtime(0) の返
す日付と時刻を云う。負の値を与えた場合は、エポック以前の日付/時刻に設
定される。

=item C<< setJulianDay >>

  $dt->setJulianDay($julian);

ユリウス日を設定する。小数で指定された場合は、その値から時刻を求める。

=item C<< setYear >>

  $dt->setYear(2006);

年を設定する。引数は、現在設定されているタイムゾーンでの値として解釈さ
れる。

=item C<< setMonth >>

  $dt->setMonth(1);

月を設定する。負の値 n を与えた場合は、最大値(setMonthの場合は12) + 1
+ n が与えられたものと見なす。例えば setMonth(-1) は setMonth(12) に等
しい。

引数が0または13以上である場合、及び-13以下である場合は die する。

また、月を変更する事により日が存在する範囲から外れた場合は、日が最終日
に設定される。例えば1月31日で setMonth(4) すると4月30日になる。

=item C<< setDay >>

=item C<< setHour >>

=item C<< setMinute >>

=item C<< setSecond >>

setMonth と同様。負の値を与えた場合等の動作も setMonth に準じる。

=item C<< setTimeZone >>

  $dt->setTimeZone();         # localtimeとgmtimeの差から計算
  $dt->setTimeZone(9);        # +09:00 に設定
  $dt->setTimeZone('+0900');  # +09:00 に設定 (RFC 822)
  $dt->setTimeZone('+09:00'); # +09:00 に設定 (W3C)
  $dt->setTimeZone('gmt');    # +00:00 に設定

タイムゾーンを設定する。タイムゾーンを変更すると、絶対時間であるエポッ
ク秒やユリウス日は変化しないが、getSecond等で返される日付や時刻等が変
化する。

=item C<< getEpoch >>

  $epoch = $dt->getEpoch;

エポック秒を返す。エポック以前の日付と時刻では負の値が返る。

=item C<< getJulianDay >>

  $julian = $dt->getJulianDay;

ユリウス日を小数で返す。

=item C<< getYear >>

  $year = $dt->getYear;

年を返す。現在設定されているタイムゾーンでの値が返される。

=item C<< getMonth >>

  $mon = $dt->getMonth;       # 数値 1-12 で返す。

月を返す。

=item C<< getDay >>

=item C<< getHour >>

=item C<< getMinute >>

=item C<< getSecond >>

getYearと同様。

=item C<< getWday >>

  $wday = $dt->getWday;       # 数値 0-6 で返す。0が日曜、1が月曜である。

曜日を返す。数値 0-6 で返す。0が日曜、1が月曜である。

=item C<< getTimeZone >>

  $tz = $dt->getTimeZone();         # 時間で返す

タイムゾーンを時間単位で返す。端数がある場合は小数で返る。

=item C<< getAnimal >>

  $animal = $dt->getAnimal;      # 数値 0-11 を返す

この年の十二支を返す。0: 子, 1: 丑, ... 11: 亥

=item C<< getAllHolidays >>

  $hash = $dt->getAllHolidays;

この年にある日本の祝祭日を返す。返される値は、キーが MM-DD 形式の日付、
値が祝祭日名のハッシュである。

=item C<< isHoliday >>

  $bool = $dt->isHoliday($type);

この日が特定の日であれば 1 を、そうでなければ undef を返す。

特定の日とは以下の通り。

$typeが0の場合、土日及び日本の祝祭日。

$typeが1の場合、日及び日本の祝祭日。

$typeが2の場合、日本の祝祭日。

デフォルトは0。

=item C<< getHolidayName >>

  $str = $dt->getHolidayName;

この日が祝祭日であればその名前を、そうでなければ undef を返す。

=item C<< isLeapYear >>

この年がうるう年であれば 1 を、そうでなければ undef を返す。

=item C<< getCalendar >>

  $array = $dt->getCalendar;

この月の日数分の DateTime オブジェクトが入った配列を返す。

=item C<< getCalendarMatrix >>

  $matrix = $dt->getCalendarMatrix(\$option);

この月のカレンダーを二次元配列で返す。
引数は次の通り:

=over 8

=item C<< type >>

'normal' または 'fixed' の2種類。fixed にすると常に６週分を返す.

=item C<< begin >>

'sun' または 'mon' の2種類。sun なら週が日曜から始まり、mon なら月曜。
デフォルトは sun 。

=back

戻り値はカレンダーの一行分の DateTime オブジェクトの配列を1ヶ月分格納した配列。

=item C<< spanSecond >>

  $seconds = $dt->spanSecond($dt2);
  $seconds = $dt->spanSecond($dt1,$dt2);

引数との秒数の差を計算し、結果を整数で返す。
引数が2つ指定された場合は、引数同士の差を計算する。

spanは、実際の期間を、指定された単位で計算する。
spanDay で1日が返った場合は、2つの日付の間に24時間の間隔があることを示す。

spanMonth / Year の場合、それ以下の日部分の大小や年部分の大小を比較して、マイナス１すべきか判断する。
秒数を平均的な１月の長さや１年の長さで割って求めているわけではない。（年齢計算等に利用できる）

例：spanMonthの場合（2006年1月1日00時00分00秒と2005年12月31日00時00分00秒の場合、0が返る）

引数が DateTime オブジェクトだった場合はそのオブジェクトと比較し、
それ以外の場合は引数をそのまま $TL->newDateTime に渡して生成した
オブジェクトと比較する。

返される値は ($dt) - ($dt2) もしくは、($dt1) - ($dt2)であり、引数が過去ならば結果は正になる。

=item C<< spanMinute >>

=item C<< spanHour >>

=item C<< spanDay >>

=item C<< spanMonth >>

=item C<< spanYear >>

spanSecond と同様。

=item C<< minusSecond >>

  $seconds = $dt->minusSecond($dt2);
  $seconds = $dt->minusSecond($dt1,$dt2);

引数との秒数の差を計算し、結果を整数で返す。
引数が2つ指定された場合は、引数同士の差を計算する。

minusは、指定された単位部分の差を計算する。
minusDayであれば、時・分・秒の部分を無視し、
年月日のみで差を計算し、その差が何日分かを返す。

例：minsMonthの場合（2006年1月1日と2005年12月31日の場合、1が返る）

引数が DateTime オブジェク
トだった場合はそのオブジェクトと比較し、それ以外の場合は引数をそのまま 
$TL->newDateTime に渡して生成したオブジェクトと比較する。

返される値は ($dt) - ($dt2) もしくは、($dt1) - ($dt2)であり、引数が過去ならば結果は負になる。

=item C<< minusMinute >>

=item C<< minusHour >>

=item C<< minusDay >>

=item C<< minusMonth >>

=item C<< minusYear >>

minusSecond と同様。

=item C<< addSecond >>

  $dt->addSecond($sec);

$sec 秒後の時刻にする。

=item C<< addMinute >>

=item C<< addHour >>

=item C<< addDay >>

addSecond と同様。

=item C<< addMonth >>

addSecond と同様だが、もし変更前の日が変更後の年/月に存在しないもので
あったら、日はその月の最後の日に変更される。

=item C<< addYear >>

addMonth と同様。

=item C<< addBusinessDay >>

  $dt->addBusinessDay($day,$type);

$day 営業日後にする。
お盆や年末年始などは考慮しない。

例としては、12月31日で、$dayに1を指定した場合、翌年の1月2日になる。
（2日が振替休日の場合、3日になる）

休業日は$typeで決定する。

$typeが0の場合、土日及び日本の祝祭日。

$typeが1の場合、日及び日本の祝祭日。

$typeが2の場合、日本の祝祭日。

を休業日として営業日を判定する。

デフォルトは0。

=item C<< nextDay >>

次の日にする。

=item C<< prevDay >>

前の日にする。

=item C<< firstDay >>

その月の最初の日にする。

=item C<< lastDay >>

その月の最後の日にする。

=item C<< toStr >>

  $str = $dt->toStr('mysql');  # YYYY-MM-DD HH:MM:SS の形式で返す。
  $str = $dt->toStr('rfc822'); # rfc822 形式で返す。
  $str = $dt->toStr('rfc850'); # rfc850 形式で返す。
  $str = $dt->toStr('w3c');    # W3c Date and Time の形式で返す。
  $str = $dt->toStr;           # mysql と同じ。

文字列で表した日付と時刻を返す。

=item C<< strFormat >>

  $str = $dt->strFormat('%Y 年 %m 月 %d 日 (%J) %H 時 %M 分');

指定されたフォーマットに従って文字列化したものを返す。

=over 8

=item C<< %a >>

短縮された曜日の名前 (Sun - Sat)

=item C<< %A >>

完全な曜日の名前 (Sunday - Saturday)

=item C<< %J >>

日本語での曜日の名前 (日 - 土)

=item C<< %b >>

短縮された月の名前 (Jan - Dec)

=item C<< %B >>

完全な月の名前 (January - December)

=item C<< %_B >>

日本語での月の名前 (睦月 - 師走)

=item C<< %d >>

日を2桁で表現 (01 - 31)

=item C<< %_d >>

日 (1 - 31)

=item C<< %m >>

月を2桁で表現 (01-12)

=item C<< %_m >>

月 (1-12)

=item C<< %w >>

曜日を10進数で表現。0 - 6 で、日曜が 0 、月曜が 1 。

=item C<< %y >>

年を下2桁で表現 (00 - 99)

=item C<< %Y >>

年を4桁で表現

=item C<< %_Y >>

年を和暦で表現。 (平成11年 等)

和暦の定義されていない範囲では空文字列。

=item C<< %H >>

時を24時間表記で2桁で表現 (00-23)

=item C<< %_H >>

時を24時間表記で表現 (0-23)

=item C<< %I >>

時を12時間表記で2桁で表現 (00-11)

=item C<< %_I >>

時を12時間表記で表現 (0-11)

=item C<< %P >>

時刻が午前なら 'a.m.', 午後なら 'p.m.' に置換する。
24時間表記での0時0分は午前とし、12時0分は午後とする。

このパターンが parseFormat で使われる時は、大文字と小文字は無視され、
ピリオドの有無も無視される。例えば 'AM', 'A.M.', 'a.M' はいずれも午前
としてパースされる。

=item C<< %_P >>

時刻が午前なら '午前', 午後なら '午後' に置換する。

=item C<< %M >>

分を2桁で表現 (00-59)

=item C<< %_M >>

分 (0-59)

=item C<< %S >>

秒を2桁で表現 (00-59)

=item C<< %_S >>

秒 (0-59)

=item C<< %E >>

十二支を表す文字 (子 - 亥)

=item C<< %z >>

RFC 822 形式に於けるタイムゾーン。JSTの場合は '+0900' になる。

=item C<< %_z >>

W3C Date and Time 形式に於けるタイムゾーン。JSTの場合は '+09:00' になる。

=item C<< %Z >>

タイムゾーンを表す名称。存在しない場合は空文字列になる。

=item C<< %T >>

'%H:%M:%S' のフォーマットで返される文字列

=item C<< %% >>

'%' という文字

=back

=item C<< parseFormat >>

  $dt->parseFormat('%Y %d %m', '2006 01 13');

指定されたフォーマットを用いて日付と時刻の文字列をパースする。フォーマッ
ト文字は strFormat のものと同一。フォーマット文字列から年を得
る事が出来ない場合や、パースに失敗した場合は、die する。

また、常に空白または0による桁揃えの有無、全角半角は無視して解析する。

12時間表記の時間である %I と %_I と、午前または午後を表す %P と %_P は、
用いられる際には必ず両方用いられなければならない。いずれか片方だけでは
正確な時刻が判らない為。

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=back

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
