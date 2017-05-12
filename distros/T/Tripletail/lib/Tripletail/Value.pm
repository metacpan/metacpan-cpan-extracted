# -----------------------------------------------------------------------------
# Tripletail::Value - 値の検証や変換
# -----------------------------------------------------------------------------
package Tripletail::Value;
use strict;
use warnings;
use Tripletail;
use Unicode::Japanese ();

#---------------------------------- 正規表現

my $atext = qr{[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}\~]+};
my $dotString = qr{[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}\~\.]*};
my $pcmailexp = qr{^
	((?:
	  (?:$atext(?:\.?$atext)*) # Dot-string
	 |
	  (?:"(\\[\x20-\x7f]|[\x21\x23-\x5b\x5d-\x7e])+")   # Quoted-string
	)) # Local-part
	\@
	([\w\-]+(?:\.[\w\-]+)+) # Domain-part
\z}x;
my $mobilemailexp = qr{^
	((?:
	  (?:$dotString) # Dot-string
	 |
	  (?:"(\\[\x20-\x7f]|[\x21\x23-\x5b\x5d-\x7e])+")   # Quoted-string
	)) # Local-part
	\@
	([\w\-]+(?:\.[\w\-]+)+) # Domain-part
\z}x;

my $re_hira = qr/\xe3(?:\x81[\x81-\xbf]|\x82[\x80-\x93]|\x83\xbc)/; # xa-mi,mu-n,ー
my $re_kata = qr/\xe3(?:\x82[\xa1-\xbf]|\x83[\x80-\xb3]|\x83\xbc)/; # xa-ta,da-n,ー
my $re_char = qr/[\x00-\x7f]|[\xc0-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf]{2}|[\xf0-\xf7][\x80-\xbf]{3}|[\xf8-\xfb][\x80-\xbf]{4}|[\xfc-\xfd][\x80-\xbf]{5}/;
my $re_widenum = qr/\xef\xbc[\x90-\x99]/;

my $re_ipv4_addr = qr{^
    (?: :: (?:f{4}:)? )?
	(
	    (?: 0* (?: 2[0-4]\d  |
				   25[0-5]   |
				   [01]?\d\d |
				   \d)
			    \.){3}
		0*
		(?: 2[0-4]\d   |
			25[0-5]    |
			[01]?\d\d  |
			\d)
	)
$}ix;

# IPv4 射影 IPv6 アドレス は未サポート
my $re_ipv6_addr = qr{^
    [:a-fA-F0-9]{2,39}
$}x;

# ドメイン
my $re_domain = do {

    my $letter = qr{
        [a-zA-Z]
    }x;

    my $letter_digit = qr{
        [a-zA-Z0-9]
    }x;

    my $letter_digit_hyphen = qr{
        [a-zA-Z0-9\-]
    }x;

    # RFC ではラベルの先頭に数字が来る事を禁止しているが、実際にはそのようなドメ
    # インが存在する。
    my $label = qr{
        ${letter_digit} # RFC としてはここは ${letter} が正しい。
        (?:
            ${letter_digit_hyphen} {0,61} # ラベルは1文字以上63文字以内。
            ${letter_digit}
        )?
    }x;
    
    my $domain = qr{^
        $label (?: \. $label)*
    $}x;

    $domain;
};

my @MOBILE_AGENTS = (
    # [正規表現, UniJP の文字コード名]
    
    [qr/^DoCoMo/i    , 'sjis-imode'],
    [qr/^ASTEL/i     , 'sjis-doti' ],
    [qr/^Vodafone/i  , 'utf8-jsky' ],
    [qr/^Vemulator/i , 'utf8-jsky' ],
    [qr/^SoftBank/i  , 'utf8-jsky' ],
    [qr/^Semulator/i , 'utf8-jsky' ],
    [qr/^MOT-/i      , 'utf8-jsky' ],
    [qr/^J-PHONE/i   , 'sjis-jsky' ],
    [qr/^J-EMULATOR/i, 'sjis-jsky' ],
    
    # Softbank端末かつUP.Browserを含むものもあるのでSoftbankの後に判別すること
    [qr/UP\.Browser/i, 'sjis-au'   ],
   );

# 日付時刻

# 区切り文字
my $DEFAULT_DATE_DELIM = '-';
my $DEFAULT_TIME_DELIM = ':';

# フォーマット
my $YYYYMMDD = 'YYYYMMDD';
my $HHMMSS = 'HHMMSS';
my $YYYYMMDDHHMMSS = 'YYYYMMDD HHMMSS';
my $YYYYMMDDHMS = 'YYYYMMDD HMS';
my $YMDHHMMSS = 'YMD HHMMSS';
my $YMD = 'YMD';
my $HMS = 'HMS';
my $YMDHMS = 'YMD HMS';

my $DEFAULT_DATE_FORMAT = $YYYYMMDD;
my $DEFAULT_TIME_FORMAT = $HHMMSS;
my $DEFAULT_DATETIME_FORMAT = $YYYYMMDDHHMMSS;

1;

#---------------------------------- 一般

sub _new {
	my $class = shift;
	my $this = bless {} => $class;

	$this->{value} = undef;

	if(@_) {
		$this->set(@_);
	}

	$this;
}

sub set {
	my $this = shift;
	my $value = shift;

	if(ref($value)) {
		die __PACKAGE__."#set: arg[1] is a reference. [$value] (第1引数がリファレンスです)\n";
	}

	$this->{value} = $value;
	$this;
}

sub get {
	my $this = shift;

	$this->{value};
}

#---------------------------------- set系

sub setDate {
	my $this = shift;
	my $year = shift;
	my $mon = shift;
	my $day = shift;

	if($this->_isExistentDay($year, $mon, $day)) {
		$this->{value} = sprintf '%04d-%02d-%02d', $year, $mon, $day;
	} else {
		$this->{value} = undef;
	}

	$this;
}

sub setDateTime {
	my $this = shift;
	my $year = shift;
	my $mon = shift;
	my $day = shift;
	my $hour = shift;
	my $min = shift || 0;
	my $sec = shift || 0;

	if($this->_isExistentDay($year, $mon, $day)
	&& $this->_isExistentTime($hour, $min, $sec)) {
		$this->{value} = sprintf(
			'%04d-%02d-%02d %02d:%02d:%02d',
			$year, $mon, $day,
			$hour, $min, $sec,
		);
	} else {
		$this->{value} = undef;
	}

	$this;
}

sub setTime {
	my $this = shift;
	my $hour = shift;
	my $min = shift || 0;
	my $sec = shift || 0;

	if($this->_isExistentTime($hour, $min, $sec)) {
		$this->{value} = sprintf '%02d:%02d:%02d', $hour, $min, $sec;
	} else {
		$this->{value} = undef;
	}

	$this;
}

#---------------------------------- get系

sub getLen {
	my $this = shift;

	length $this->{value};
}

sub getSjisLen {
	my $this = shift;

	length Unicode::Japanese->new($this->{value})->sjis;
}

sub getCharLen {
	my $this = shift;

	my @chars = grep {defined && length} split /($re_char)/, $this->{value};
	scalar @chars;
}

sub getAge {
	my $this = shift;
	my $date = shift;

	my @from = $this->_parseDate($this->{value});
	my @to = do {
		if(defined($date)) {
			$this->_parseDate($date);
		} else {
			my @lt = localtime;
			$lt[5] += 1900;
			$lt[4]++;
			@lt[5, 4, 3];
		}
	};

	if(!@to || !$this->_isExistentDay(@to)) {
		return undef;
	}

	my $age = $to[0] - $from[0];
	if($to[1] < $from[1] || ($to[1] == $from[1] && $to[2] < $from[2])) {
		$age--;
	}
	$age;
}

sub getRegexp {
	my $this = shift;
	my $type = shift;
	
	if(!defined($type)) {
		die __PACKAGE__."#getRegexp: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($type)) {
		die __PACKAGE__."#getRegexp: arg[1] is a reference. [$type] (第1引数がリファレンスです)\n";
	}

	my $regexp;

	$type = lc($type);
	if($type eq 'hira') {
		$regexp = $re_hira;
	} elsif($type eq 'kata') {
		$regexp = $re_kata;
	} elsif($type eq 'numbernarrow') {
		$regexp = qr{\d};
	} elsif($type eq 'numberwide') {
		$regexp = $re_widenum;
	} else {
		die __PACKAGE__."#getRegexp: arg[1] is an invalid type. [$type] (指定された正規表現は存在しません)\n";
	}
	
	$regexp;
}

#---------------------------------- is系
sub isEmpty {
	my $this = shift;

	not length $this->{value};
}

sub isWhitespace {
	# 半角/全角スペース、タブのみで構成されているなら1。
	# 空文字列やundefならundef。
	my $this = shift;

	if(length($this->{value})) {
		$this->{value} =~ /\A(?:\s|　)+\z/ ? 1 : undef;
	} else {
		undef;
	}
}

sub isBlank {
	my $this = shift;

	if($this->isEmpty || $this->isWhitespace) {
		1;
	} else {
		undef;
	}
}

sub isPrintableAscii {
	my $this = shift;

	if(length($this->{value})) {
		$this->{value} =~ /\A[\x20-\x7e]*\z/ ? 1 : undef;
	} else {
		undef;
	}

}

sub isWide {
	my $this = shift;

	if(length($this->{value})) {
	
		my $sjisvalue = $TL->charconv($this->{value}, 'UTF-8' => 'Shift_JIS');
		
		my $re_char = '[\x81-\x9f\xe0-\xef\xfa-\xfc][\x40-\x7e\x80-\xfc]|[\xa1-\xdf]|[\x00-\x7f]';
		
		my @chars = grep {defined && length} split /($re_char)/, $sjisvalue;
		
		!grep { length($_) == 1 } @chars;
	} else {
		undef;
	}
}

sub isPassword {
	my $this = shift;
	
	if(!defined($this->{value})) {
		return undef;
	}

	if(!$this->isPrintableAscii() )
	{
		return undef;
	}

	my $deftypes = ['alpha', 'ALPHA', 'digit', 'symbol'];
	my $matcher = {
		alpha  => qr/[a-z]/,
		ALPHA  => qr/[A-Z]/,
		digit  => qr/[0-9]/,
		symbol => qr/[\x21-\x2f\x3a-\x40\x5b-\x60\x7b-\x7e]/,
		# ! " # $ % & ' ( ) * + ' - . /
		# : ; < = > ? @   [ \ ] ^ _ `  { | } ~
	};
	my $tokens = @_ ? [@_] : $deftypes;
	my $tmp = $this->{value};
	foreach my $token (@$tokens)
	{
		my $re = $matcher->{$token};
		if( !$re && ref($token) eq 'ARRAY' )
		{
			$re = join('|', @$token);
		}
		$re or die __PACKAGE__."#isPassword: invalid argument. [$token] (無効な値です)\n";
		if( $tmp !~ s/$re//g )
		{
			return undef;
		}
	}
	1; # accepted.
}

sub isZipCode {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ /\A\d{3}-\d{4}\z/ ? 1 : undef;
}

sub isTelNumber {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ /\A\d[\d-]+\d\z/ ? 1 : undef;
}

sub isEmail {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ /$pcmailexp/ ? 1 : undef;
}

sub isMobileEmail {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ /$mobilemailexp/ ? 1 : undef;
}

sub isInteger {
	my $this = shift;
	my $min = shift;
	my $max = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	if($this->{value} =~ m/\A-?\d+\z/) {
		if(defined($min)) {
			$this->{value} >= $min or return undef;
		}
		if(defined($max)) {
			$this->{value} <= $max or return undef;
		}

		1;
	} else {
		undef;
	}
}

sub isReal {
	my $this = shift;
	my $min = shift;
	my $max = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	if($this->{value} =~ m/\A-?\d+(?:\.\d+)?\z/) {
		if(defined($min)) {
			$this->{value} >= $min or return undef;
		}
		if(defined($max)) {
			$this->{value} <= $max or return undef;
		}

		1;
	} else {
		undef;
	}
}

sub isHira {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ m/\A$re_hira+\z/ ? 1 : undef;
}

sub isKata {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ m/\A$re_kata+\z/ ? 1 : undef;
}

sub isExistentDay {
	# YYYY-MM-DD この日が存在するなら1
	my $this = shift;
	my %option = @_;

	for my $key (keys %option) {
		if($key !~ /^format|date_delim|date_delim_optional$/) {
			die __PACKAGE__."#isExistentDay: invalid argument. [$key] (引数名の $key はサポートされていません)\n";
		}
	}

	$option{format} = exists $option{format} ? $option{format} : $DEFAULT_DATE_FORMAT;
	if($option{format} !~ /^$YYYYMMDD|$YMD$/o) {
		die __PACKAGE__."#isExistentDateTime: invalid argument. [$option{format}] (formatの $option{format} はサポートされていません)\n";
	}

	if(exists $option{date_delim} && exists $option{date_delim_optional}) {
		die __PACKAGE__."#isExistentDay: invalid argument. (date_delim/date_delim_optionalを同時に指定する事はできません)\n";
	}

	if($option{format} ne $YYYYMMDD && exists $option{date_delim_optional}) {
		die __PACKAGE__."#isExistentDay: invalid argument. [$option{format}] ([YYYYMMDD]以外ではoptionalパラメータを指定できません)\n";
	}

	if(!defined($this->{value})) {
		return undef;
	}

	my @date = $this->_parseDate(_get_parse_param($this->{value}, \%option));
	if(!@date || !$this->_isExistentDay(@date)) {
		return undef;
	}

	1;
}

sub isExistentTime {
	# HH:mm:ss この時間が存在するなら1
	my $this = shift;
	my %option = @_;

	for my $key (keys %option) {
		if($key !~ /^format|time_delim|time_delim_optional$/) {
			die __PACKAGE__."#isExistentTime: invalid argument. [$key] (引数名の $key はサポートされていません)\n";
		}
	}

	$option{format} = exists $option{format} ? $option{format} : $DEFAULT_TIME_FORMAT;
	if($option{format} !~ /^$HHMMSS|$HMS$/o) {
		die __PACKAGE__."#isExistentTime: invalid argument. [$option{format}] (formatの $option{format} はサポートされていません)\n";
	}

	if(exists $option{time_delim} && exists $option{time_delim_optional}) {
		die __PACKAGE__."#isExistentTime: invalid argument. (time_delim/time_delim_optionalを同時に指定する事はできません)\n";
	}

	if($option{format} ne $HHMMSS && exists $option{time_delim_optional}) {
		die __PACKAGE__."#isExistentTime: invalid argument. [$option{format}] ([HHMMSS]以外ではoptionalパラメータを指定できません)\n";
	}

	if(!defined($this->{value})) {
		return undef;
	}

	my @time = $this->_parseTime(_get_parse_param($this->{value}, \%option));
	if(!@time || !$this->_isExistentTime(@time)) {
		return undef;
	}

	1;
}

sub isExistentDateTime {
	# YYYY-MM-DD HH:mm:ss この日時が存在するなら1
	my $this = shift;
	my %option = @_;

	for my $key (keys %option) {
		if($key !~ /^format|date_delim|date_delim_optional|time_delim|time_delim_optional$/) {
			die __PACKAGE__."#isExistentDateTime: invalid argument. [$key] (引数名の $key はサポートされていません)\n";
		}
	}

	$option{format} = exists $option{format} ? $option{format} : $DEFAULT_DATETIME_FORMAT;
	if($option{format} !~ /^$YYYYMMDDHHMMSS|$YYYYMMDDHMS|$YMDHHMMSS|$YMDHMS$/o) {
		die __PACKAGE__."#isExistentDateTime: invalid argument. [$option{format}] (formatの $option{format} はサポートされていません)\n";
	}
	
	if((exists $option{date_delim} && exists $option{date_delim_optional}) || (exists $option{time_delim} && exists $option{time_delim_optional})) {
		die __PACKAGE__."#isExistentDateTime: invalid argument. (date_delim/date_delim_optional又はtime_delim/time_delim_optionalを同時に指定する事はできません)\n";
	}

	if($option{format} ne $YYYYMMDDHHMMSS && (exists $option{date_delim_optional} || exists $option{time_delim_optional})) {
		die __PACKAGE__."#isExistentDateTime: invalid argument. [$option{format}] ([YYYYMMDD HHMMSS]以外ではoptionalパラメータを指定できません)\n";
	}

	if(!defined($this->{value})) {
		return undef;
	}

	my @datetime = $this->_parseDateTime(_get_parse_param($this->{value}, \%option));
	if(!@datetime || !$this->_isExistentDateTime(@datetime)) {
		return undef;
	}

	1;
}

sub isGif {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ /\AGIF8[79]a/ ? 1 : undef;
}

sub isJpeg {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ /\A\xFF\xD8/ ? 1 : undef;
}

sub isPng {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ /\A\x89PNG\x0D\x0A\x1A\x0A/ ? 1 : undef;
}

sub isHttpUrl {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ m!\Ahttp://! ? 1 : undef;
}

sub isHttpsUrl {
	my $this = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	$this->{value} =~ m!\Ahttps://! ? 1 : undef;
}

sub isLen {
	my $this = shift;
	my $min = shift;
	my $max = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	my $len = $this->getLen;

	if(defined($min)) {
		$len >= $min or return undef;
	}
	if(defined($max)) {
		$len <= $max or return undef;
	}

	1;
}

sub isSjisLen {
	my $this = shift;
	my $min = shift;
	my $max = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	my $len = $this->getSjisLen;

	if(defined($min)) {
		$len >= $min or return undef;
	}
	if(defined($max)) {
		$len <= $max or return undef;
	}

	1;
}

sub isCharLen {
	my $this = shift;
	my $min = shift;
	my $max = shift;

	if(!defined($this->{value})) {
		return undef;
	}

	my $len = $this->getCharLen;

	if(defined($min)) {
		$len >= $min or return undef;
	}
	if(defined($max)) {
		$len <= $max or return undef;
	}

	1;
}

sub isPortable {
	# 機種依存文字を含んでいないなら1
	my $this = shift;
	my $str  = $this->{value};

	if(!defined($this->{value})) {
		return undef;
	}

	my $unijp = Unicode::Japanese->new;
	
	my @chars = grep {defined && length} split /($re_char)/, $this->{value};
	
	# 機種依存文字
	my $dep_regex 
		= '\xED[\x40-\xFF]|\xEE[\x00-\xFC]'              # NEC選定IBM拡張文字(89-92区)
		. '|[\xFA\xFB][\x40-\xFF]|\xFC[\x40-\x4B]'     # IBM拡張文字(115-119区)
		. '|[\x85-\x87][\x40-\xFF]|\x88[\x40-\x9E]'    # 特殊文字エリア
		. '|[\xF0-\xF8][\x40-\xFF]|\xF9[\x40-\xFC]'    # JIS外字エリア
		. '|\xEA[\xA5-\xFF]|[\xEB-\xFB][\x40-\xFF]|\xFC[\x40-\xFC]' # MAC外字及び縦組用
		. '|\x81[\xBE\xBF\xDA\xDB\xDF\xE0\xE3\xE6\xE7]'; # JIS領域外の13区の記号
	
	# SJIS
	foreach my $str (@chars) {
		my $str_sjis = $unijp->set($str, 'utf8')->sjis;
		return undef if($str_sjis =~ m/\A(?:$dep_regex)\z/o);
	}
	
	# Unicodeのプライベート領域判定（U+E000～U+F8FF、U+F0000～U+10FFFF）
	foreach my $str (@chars) {
		my $str_ucs4 = $unijp->set($str, 'utf8')->ucs4;
		return undef if($str_ucs4 =~ m/\A\x00\x00[\xe0-\xf8][\x00-\xff]\z/o);
		return undef if($str_ucs4 =~ m/\A\x00[\x0f-\x10][\x00-\xff][\x00-\xff]\z/o);
	}
	
	return 1;
}

sub isPcPortable {
	# 携帯絵文字を含んでいないなら1
	my $this = shift;
	my $str  = $this->{value};

	if(!defined($this->{value})) {
		return undef;
	}

	my $unijp = Unicode::Japanese->new;
	
	my @chars = grep {defined && length} split /($re_char)/, $this->{value};
	
	# Unicodeのプライベート領域判定（U+FE000～U+FFFFF）
	foreach my $str (@chars) {
		my $str_ucs4 = $unijp->set($str, 'utf8')->ucs4;
		return undef if($str_ucs4 =~ m/\A\x00\x0f[\xe0-\xff][\x00-\xff]\z/o);
	}
	
	
	return 1;
}

sub isDomainName {
    my $this = shift;

    if (defined $this->{value}) {
        return
          length($this->{value}) <= 255 &&
          $this->{value} =~ m/$re_domain/o;
    }
    else {
        return;
    }
}

sub isIpAddress {
	my $this = shift;
	my $checkmask = shift;
	my $checkip  = $this->{value};

	if(!defined($this->{value})) {
		return undef;
	}
	
	if(!defined($checkmask)) {
		return undef;
	} elsif(ref($checkmask)) {
		return undef;
	}

	my @masks = split /\s+/, $checkmask;
	
	my @ip = $this->_parse_addr($checkip);

	if(@ip != 4 && @ip != 16) {
		# パース失敗
		return undef;
	} else {
		foreach my $mask (@masks) {
			my $bits;
			if($mask =~ s!/(\d+)$!!) {
				$bits = $1;
			}

			my @mask = $this->_parse_addr($mask);
			if(@mask != 4 and @mask != 16) {
				# パース失敗
				return undef;
			}

			if(@mask != @ip) {
				# IPバージョン違い
				next;
			}

			# ビット数が指定されたなかった場合は /32 または /128 と見做す。
			defined $bits or
			  $bits = (@mask == 4 ? 32 : 128);

			if($this->_ip_match(\@ip, \@mask, $bits)) {
				# マッチした
				return 1;
			}
		}

		# どれにもマッチしなかった。
		return undef;
	}
}

sub isDateString {
    my $this   = shift;
    my $format = shift;

    if (!defined $this->{value}) {
        return;
    }

    eval {
        local $SIG{__DIE__} = 'DEFAULT';
        $TL->newDateTime->parseFormat($format, $this->{value});
    };
    if (my $err = $@) {
        # 良くないが、他に方法が無い。
        if ($err =~ m/does not match to/) {
            return;
        }
        else {
            die $@;
        }
    }
    else {
        return 1;
    }
}

sub isChar
{
  my $this = shift;

  if( !@_ )
  {
    die __PACKAGE__."#isChar, no arguments specified. (引数が指定されていません)\n";
  }

  my @chars;
  foreach my $i (1..@_)
  {
    my $val = $_[$i-1];
    if( !defined($val) )
    {
      die __PACKAGE__."#isChar, arg[$i] is not defined. (第$i引数が指定されていません)\n";
    }
    if( ref($val) )
    {
      if( ref($val) ne 'ARRAY' )
      {
        die __PACKAGE__."#isChar, arg[$i] is not array-ref. (第$i引数は配列リファレンスではありません)\n";
      }
      push(@chars, $val);
    }else
    {
      our $MAPS ||= {
        digit      => [0..9],
        loweralpha => ['a'..'z'],
        upperalpha => ['A'..'Z'],
        alpha      => ['a'..'z', 'A'..'Z'],
        '-'        => ['-'],
        '_'        => ['_'],
      };
      foreach my $name (map{lc($_)} split(/[\s,]+/, $val))
      {
        my $list = $MAPS->{$name};
        if( !$list )
        {
          die __PACKAGE__."#isChar, invalid name [$name]. (無効な値です [$name])\n";
        }
        push(@chars, $list);
      }
    }
  }

  if( !defined($this->{value}) )
  {
    # undefined is not acceptable.
    return;
  }

  if( $this->{value} eq '' )
  {
    # empty is not acceptable.
    return;
  }

  foreach my $ch (split(//, $this->{value}))
  {
    my $accepted;
    foreach my $list (@chars)
    {
      if( grep { $_ eq $ch } @$list )
      {
        $accepted = 1;
        last;
      }
    }
    if( !$accepted )
    {
      # rejected.
      return undef;
    }
  }

  # all accepted.
  return 1;
}

#---------------------------------- conv系
sub convHira {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}
	
	my $unijp = Unicode::Japanese->new($this->{value});
	$this->{value} = $unijp->kata2hira->get;

	$this;
}

sub convKata {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my $unijp = Unicode::Japanese->new($this->{value});
	$this->{value} = $unijp->hira2kata->get;

	$this;
}

sub convNumber {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my $unijp = Unicode::Japanese->new($this->{value});
	$this->{value} = $unijp->z2hNum->get;

	$this;
}

sub convNarrow {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my $unijp = Unicode::Japanese->new($this->{value});
	$this->{value} = $unijp->z2h->get;

	$this;
}

sub convWide {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my $unijp = Unicode::Japanese->new($this->{value});
	$this->{value} = $unijp->h2z->get;

	$this;
}

sub convKanaNarrow {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my $unijp = Unicode::Japanese->new($this->{value});
	$this->{value} = $unijp->z2hKana->get;

	$this;
}

sub convKanaWide {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my $unijp = Unicode::Japanese->new($this->{value});
	$this->{value} = $unijp->h2zKana->get;

	$this;
}

sub convComma {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	$this->{value} =~ s/\G((?:^[-+])?\d{1,3})(?=(?:\d\d\d)+(?!\d))/$1,/g;

	$this;
}

sub convLF {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	$this->{value} =~ s/\r\n/\n/g;
	$this->{value} =~ s/\r/\n/g;

	$this;
}

sub convBR {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	$this->{value} =~ s/\r\n/\n/g;
	$this->{value} =~ s/\r/\n/g;
	$this->{value} =~ s/\n/<BR>\n/g;

	$this;
}

#---------------------------------- force系
sub forceHira {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}
	
	$this->{value} = join('', $this->{value}=~/($re_hira+)/go);
	$this;
}

sub forceKata {
	# forceHiraの逆
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}
	
	$this->{value} = join('', $this->{value}=~/($re_kata+)/go);
	$this;
}

sub forceNumber {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}
	
	$this->{value} = join('', $this->{value}=~/(\d+)/go);
	$this;
}

sub forceMin {
	my $this = shift;
	my $min = shift;
	my $val = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	if(!defined($min)) {
		die __PACKAGE__."#forceMin: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($min)) {
		die __PACKAGE__."#forceMin: arg[1] is a reference. [$min] (第1引数がリファレンスです)\n";
	}

	$this->forceNumber;
	if($this->{value} < $min) {
		$this->{value} = $val;
	}

	$this;
}

sub forceMax {
	my $this = shift;
	my $max = shift;
	my $val = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	if(!defined($max)) {
		die __PACKAGE__."#forceMax: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($max)) {
		die __PACKAGE__."#forceMax: arg[1] is a reference. [$max] (第1引数がリファレンスです)\n";
	}

	$this->forceNumber;
	if($this->{value} > $max) {
		$this->{value} = $val;
	}

	$this;
}

sub forceMaxLen {
	my $this = shift;
	my $maxlen = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	if(length($this->{value}) > $maxlen) {
		substr($this->{value}, $maxlen) = '';
	}

	$this;
}

sub forceMaxUtf8Len {
	my $this = shift;
	my $maxlen = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	if(length($this->{value}) > $maxlen) {
		# $maxlenバイトに入りきるまで一文字ずつ入れていく

		my @chars = split /($re_char)/, $this->{value};
		$this->{value} = '';
		my $current_len = 0;

		foreach my $c (@chars) {
			if($current_len + length($c) <= $maxlen) {
				$this->{value} .= $c;
				$current_len += length($c);
			} else {
				# これ以上入らない
				last;
			}
		}
	}

	$this;
}

sub forceMaxSjisLen {
	my $this = shift;
	my $maxlen = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my $unijp = Unicode::Japanese->new;

	if(length($unijp->set($this->{value})->sjis) > $maxlen) {
		# $maxlenバイトに入りきるまで一文字ずつ入れていく

		my @chars = split /($re_char)/, $this->{value};
		$this->{value} = '';
		my $current_len = 0;

		foreach my $c (@chars) {
			my $sjis_c = $unijp->set($c)->sjis;

			if($current_len + length($sjis_c) <= $maxlen) {
				$this->{value} .= $c;
				$current_len += length($sjis_c);
			} else {
				# これ以上入らない
				last;
			}
		}
	}

	$this;
}

sub forceMaxCharLen {
	my $this = shift;
	my $maxlen = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my @chars = grep {defined && length} split /($re_char)/, $this->{value};
	if(@chars > $maxlen) {
		splice @chars, $maxlen;
		$this->{value} = join '', @chars;
	}

	$this;
}

sub forcePortable {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}
	
	my $v = $TL->newValue;
	my $newval = '';
	my @chars = grep {defined && length} split /($re_char)/, $this->{value};
	foreach my $ch (@chars) {
		if($v->set($ch)->isPortable) {
			$newval .= $ch;
		}
	}
	
	$this->{value} = $newval;
	$this;
}

sub forcePcPortable {
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}
	
	my $v = $TL->newValue;
	my $newval = '';
	my @chars = grep {defined && length} split /($re_char)/, $this->{value};
	foreach my $ch (@chars) {
		if($v->set($ch)->isPcPortable) {
			$newval .= $ch;
		}
	}
	
	$this->{value} = $newval;
	$this;
}


#---------------------------------- その他

sub trimWhitespace {
	# 文字列前後の半角/全角スペース、タブを削除
	my $this = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	$this->{value} =~ s/\A(?:\s|　)+//;
	$this->{value} =~ s/(?:\s|　)+\z//;

	$this;
}

sub countWords {
	my $this = shift;

	my @words = split /(?:\s|　)+/, $this->{value};
	scalar @words;
}

sub strCut {
	my $this = shift;
	my $charanum = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my $v = $TL->newValue;
	
	my $value = $this->{value};
	my @output;

	while(length($value)) {
		$v->{value} = $value;
		my $temp = $v->forceMaxCharLen($charanum)->get;
		$value = substr($value,length($temp));
		push(@output,$temp);
	}

	@output;
}

sub strCutSjis {
	my $this = shift;
	my $charanum = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my $v = $TL->newValue;
	
	my $value = $this->{value};
	my @output;

	while(length($value)) {
		$v->{value} = $value;
		my $temp = $v->forceMaxSjisLen($charanum)->get;
		$value = substr($value,length($temp));
		push(@output,$temp);
	}

	@output;
}

sub strCutUtf8 {
	my $this = shift;
	my $charanum = shift;

	if(!defined($this->{value})) {
		return $this;
	}

	my $v = $TL->newValue;
	
	my $value = $this->{value};
	my @output;

	while(length($value)) {
		$v->{value} = $value;
		my $temp = $v->forceMaxUtf8Len($charanum)->get;
		$value = substr($value,length($temp));
		push(@output,$temp);
	}

	@output;
}

sub genRandomString {
	my $this = shift;
	my $length = shift;
	my $type = shift;

	if(!defined($length)) {
		die __PACKAGE__."#genRandomString: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($length)) {
		die __PACKAGE__."#genRandomString: arg[1] is a reference. [$length] (第1引数がリファレンスです)\n";
	}

	if(!defined($type)) {
		$type = ['std'];
	} elsif(ref($type) ne 'ARRAY') {
		die __PACKAGE__."#genRandomString: arg[2] is not an ARRAY Ref. (第2引数が配列のリファレンスではありません)\n";
	}

	my @str;
	foreach my $key (@$type) {
		if($key eq 'alpha') {
			push(@str,'a'..'z');
		} elsif($key eq 'ALPHA') {
			push(@str,'A'..'Z');
		} elsif($key eq 'num' || $key eq 'NUM') {
			push(@str,'0'..'9');
		} elsif($key eq 'std') {
			push(@str,
			     qw(    2 3 4 5 6 7 8  ),
			     qw(a   c d e f g h         m n   p   r   t u v w x y z),
			     qw(A B C D E F G H   J K L M N   P   R S T U V W X Y Z),
			    );
		} elsif($TL->newValue($key)->isCharLen(1,1)) {
			push(@str,$key);
		} else {
			die __PACKAGE__."#genRandomString: arg[2] [$key] is an invalid type. (第2引数の $key はサポートされていません)\n";
		}
	}
	
	if(!@str) {
		die __PACKAGE__."#genRandomString: arg[2] is not defined. (第2引数が指定されていません)\n";
	}
	
	my $password = '';
	for(1..$length) {
		$password .= $str[int(rand($#str+1))];
	}
	
	$password;
}

sub detectMobileAgent {
    my $this = shift;

    if (defined $this->{value}) {
        foreach my $candidate (@MOBILE_AGENTS) {
            if ($this->{value} =~ m/$candidate->[0]/) {
                return $candidate->[1];
            }
        }
    }

    return;
}

#---------------------------------- 内部メソッド

sub _isLeapYear {
	my $this = shift;
	my $y = shift;

	($y % 4 == 0 &&
		$y % 100 != 0) ||
			$y % 400 == 0;
}

sub _isExistentDay {
	my $this = shift;
	my $year = shift;
	my $mon = shift;
	my $day = shift;

	if($mon < 1 || $mon > 12) {
		return 0;
	}
	if($day < 1) {
		return 0;
	}

	my $maxday = do {
		if($this->_isLeapYear($year) && $mon == 2) {
			29;
		} else {
			[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$mon - 1];
		}
	};

	$day <= $maxday;
}

sub _isExistentTime {
	# うるう秒のチェックはしない。不規則に挿入されるので予期出来ない。
	my $this = shift;
	my $hour = shift;
	my $min = shift;
	my $sec = shift;

	$hour >= 0 && $hour <= 23 &&
		$min >= 0 && $min <= 59 &&
			$sec >= 0 && $sec <= 59;
}

sub _isExistentDateTime {
	my $this = shift;
	my $year = shift;
	my $mon = shift;
	my $day = shift;
	my $hour = shift;
	my $min = shift;
	my $sec = shift;
	
	if($this->_isExistentDay($year,$mon,$day) && $this->_isExistentTime($hour,$min,$sec)) {
		return 1;
	}
	
	return 0;
}

sub _parseDate {
	my $this = shift;
	my $str = shift;
	my $format = shift || $DEFAULT_DATE_FORMAT;
	my $option_param = shift;
	
	my $date_delim = _get_delim_regexp($option_param->{date}, $DEFAULT_DATE_DELIM);

	my $reg;
	if($format eq $YYYYMMDD) {
		$reg = qr{^(\d{4})$date_delim(\d{2})$date_delim(\d{2})$};
	}
	elsif($format eq $YMD) {
		$reg = qr{^(\d{2}|\d{4})$date_delim(\d{1,2})$date_delim(\d{1,2})$};
	}

	if($str =~ m!^$reg$!) {
		return ($1, $2, $3);
	} else {
		return ();
	}
}

sub _parseTime {
	my $this = shift;
	my $str = shift;
	my $format = shift || $DEFAULT_TIME_FORMAT;
	my $option_param = shift;

	my $time_delim = _get_delim_regexp($option_param->{time}, $DEFAULT_TIME_DELIM);

	my $reg;
	if($format eq $HHMMSS) {
		$reg = qr{^(\d{2})$time_delim(\d{2})$time_delim(\d{2})$};
	}
	elsif($format eq $HMS) {
		$reg = qr{^(\d{1,2})$time_delim(\d{1,2})$time_delim(\d{1,2})$};
	}

	if($str =~ m!^$reg$!) {
		return ($1, $2, $3);
	} else {
		return ();
	}
}

sub _parseDateTime {
	my $this = shift;
	my $str = shift;
	my $format = shift || $DEFAULT_DATETIME_FORMAT;
	my $option_param = shift;

	my $date_delim = _get_delim_regexp($option_param->{date}, $DEFAULT_DATE_DELIM);
	my $time_delim = _get_delim_regexp($option_param->{time}, $DEFAULT_TIME_DELIM);

	my $reg;
	if($format eq $YYYYMMDDHHMMSS) {
		$reg = qr{^(\d{4})$date_delim(\d{2})$date_delim(\d{2}) ?(\d{2})$time_delim(\d{2})$time_delim(\d{2})$};
	}
	elsif($format eq $YYYYMMDDHMS) {
		$reg = qr{^(\d{4})$date_delim(\d{2})$date_delim(\d{2}) ?(\d{1,2})$time_delim(\d{1,2})$time_delim(\d{1,2})$};
	}
	elsif($format eq $YMDHHMMSS) {
		$reg = qr{^(\d{2}|\d{4})$date_delim(\d{1,2})$date_delim(\d{1,2}) ?(\d{2})$time_delim(\d{2})$time_delim(\d{2})$};
	}
	elsif($format eq $YMDHMS) {
		$reg = qr{^(\d{2}|\d{4})$date_delim(\d{1,2})$date_delim(\d{1,2}) ?(\d{1,2})$time_delim(\d{1,2})$time_delim(\d{1,2})$};
	}

	if($str =~ m!$reg!) {
		return ($1, $2, $3, $4, $5, $6);
	} else {
		return ();
	}
}

sub _get_delim_regexp {
	my $param = shift;
	my $default = shift;
	
	if(defined $param) {
		my $delim_str = length($param->{delim}) > 0 ? '['.quotemeta($param->{delim}).']' : '';
		$delim_str = $param->{optional} ? $delim_str.'?' : $delim_str;
		$delim_str;
	}
	else {
		$default;
	}
}

sub _get_parse_param {
	my $str = shift;
	my $option = shift;

	my $format = $option->{format};

	my $option_param;
	if(exists $option->{date_delim}) {
		$option_param->{date}->{delim} = $option->{date_delim};
		$option_param->{date}->{optional} = 0;
	}
	elsif(exists $option->{date_delim_optional}) {
		$option_param->{date}->{delim} = $option->{date_delim_optional};
		$option_param->{date}->{optional} = 1;
	}
	else{
		$option_param->{date}->{delim} = $DEFAULT_DATE_DELIM;
	}

	if(exists $option->{time_delim}) {
		$option_param->{time}->{delim} = $option->{time_delim};
		$option_param->{time}->{optional} = 0;
	}
	elsif(exists $option->{time_delim_optional}) {
		$option_param->{time}->{delim} = $option->{time_delim_optional};
		$option_param->{time}->{optional} = 1;
	}
	else {
		$option_param->{time}->{delim} = $DEFAULT_TIME_DELIM;
	}

	# 区切り文字なしの場合は文字長は固定でなければいけない
	# 想定外の文字長の場合はデフォルトの区切り文字をセットする
	if(($option_param->{date}->{delim} eq '' || $option_param->{time}->{delim} eq '') && $option->{format} =~ /^$YMDHMS|$YYYYMMDDHMS|$YMDHHMMSS$/o && length($str) != 14) {
		$option_param->{date}->{delim} = $DEFAULT_DATE_DELIM;
		$option_param->{time}->{delim} = $DEFAULT_TIME_DELIM;
	}
	elsif($option_param->{date}->{delim} eq '' && $option->{format} eq $YMD && length($str) != 8) {
		$option_param->{date}->{delim} = $DEFAULT_DATE_DELIM;
	}
	elsif($option_param->{time}->{delim} eq '' && $option->{format} eq $HMS && length($str) != 6) {
		$option_param->{time}->{delim} = $DEFAULT_TIME_DELIM;
	}

	$str, $option->{format}, $option_param;
}

sub _parse_addr {
	my $this = shift;
	my $addr = shift;

	if($addr =~ m/$re_ipv4_addr/) {
		# IPv4
		$1 =~ m/\A(\d+)\.(\d+)\.(\d+)\.(\d+)\z/;
		($1, $2, $3, $4);
	} elsif($addr =~ m/$re_ipv6_addr/) {
		# IPv6
		my $word2bytes = sub {
			my $word = hex shift;
			(($word >> 8) & 0xff, $word & 0xff);
		};
		
		if($addr =~ /::/) {
			# 短縮形式を展開
			my ($left, $right) = split /::/, $addr;
			
			my @left = split /:/, $left;
			my @right = split /:/, $right;
			
			foreach(scalar @left .. 7 - scalar @right) {
				push @left, 0
			};
			
			map { $word2bytes->($_) } (@left, @right);
		} else {
			map { $word2bytes->($_) } split /:/, $addr;
		}
	} else {
		();
	}
}


sub _ip_match {
	my $this = shift;
	my $a = shift;
	my $b = shift;
	my $bits = shift;
	my $i = 0;

	# $bits == 0 ならば何の比較もせずに「一致」として判定。
	# $bits == 最大値 ならば完全一致するかどうかで判定。
	while($bits > 0) {
		if($bits >= 8) {
			$a->[$i] != $b->[$i]
			  and return 0;

			$bits -= 8;
		} else {
			# 上位 $bits ビットのみ比較
			(($a->[$i] >> (8 - $bits)) & (2 ** $bits - 1)) !=
			  (($b->[$i] >> (8 - $bits)) & (2 ** $bits - 1))
				and return 0;

			$bits = 0;
		}
		$i++;
	}
	
	1;
}

__END__

=encoding utf-8

=head1 NAME

Tripletail::Value - 値の検証や変換

=head1 SYNOPSIS

  my $value = $TL->newValue('null@example.org');
  
  if ($value->isEmail) {
      print $value->get . " is a valid email address.\n";
  }

  # ｎｕｌｌ＠ｅｘａｍｐｌｅ．ｏｒｇ を表示
  print $value->convWide->get . "\n";

=head1 DESCRIPTION

セットした値１つの形式をチェックし、または形式を矯正する。

値を文字列として扱う場合は、常に UTF-8 である事が前提となる。

=head2 METHODS

=head3 一般

=over 4

=item C<< $TL->newValue >>

  $val = $TL->newValue
  $val = $TL->newValue($value)

Tripletail::Value オブジェクトを作成。
引数があれば、その引数で set が実行される。

=item set

  $val->set($value)

値をセット。

=item get

  $value = $val->get

矯正後の値を取得。

=back


=head3 set系

=over 4

=item C<< setDate >>

  $val->setDate($year, $month, $day)

年月日を指定してYYYY-MM-DD形式でセットする。
日付として不正である場合はundefがセットされる。

=item C<< setDateTime >>

  $val->setDateTime($year, $month, $day, $hour, $min, $sec)

各値を指定して時刻をYYYY-MM-DD HH:MM:SS形式でセットする。
時刻として不正である場合はundefがセットされる。
$min、$secは省略でき、省略時は0が使用される。

=item C<< setTime >>

  $val->setTime($hour, $min, $sec)

各値を指定して時刻をHH:MM:SS形式でセットする。
範囲は00:00:00～23:59:59までで、時刻として正しくない場合はundefがセットされる。
$min、$secは省略でき、省略時は0が使用される。

=back


=head3 get系

=over 4

=item getLen

  $n_bytes = $val->getLen

バイト数を返す。

=item getSjisLen

  $n_bytes = $val->getSjisLen

Shift_Jisでのバイト数を返す。

=item getCharLen

  $n_chars = $val->getCharLen

文字数を返す。

=item getAge

  $age = $val->getAge
  $age = $val->getAge($date)

YYYY-MM-DD形式の値として、$date の日付での年齢を返す。省略可能。
日付の形式が間違っている場合はundefを返す。

デフォルトは現在の日付。

=item getRegexp

  $regexp = $val->getRegexp($type)

指定された$typeに対応する正規表現を返す。
対応する$typeは次の通り。

hira
ひらがなに対応する正規表現を返す。

kata
カタカナに対応する正規表現を返す。

numbernarrow
半角数字に対応する正規表現を返す。

numberwide
全角数字に対応する正規表現を返す。

=back


=head3 is系

=over 4

=item isEmpty

  $bool = $val->isEmpty

値が空（undefまたは0文字）なら1。
そうでなければundefを返す。

=item isWhitespace

  $bool = $val->isWhitespace

半角/全角スペース、タブのみで構成されていれば1。
そうでなければundefを返す。値が0文字やundefの場合もundefを返す。

=item isBlank

  $bool = $val->isBlank

値が空（undefまたは0文字）であるか、半角/全角スペース、タブのみで構成されていれば1。
そうでなければundefを返す。値が0文字やundefの場合もundefを返す。


=item isPrintableAscii

  $bool = $val->isPrintableAscii

文字列が制御コードを除くASCII文字のみで構成されているなら1。
そうでなければundefを返す。値が0文字やundefの場合もundefを返す。

=item isWide

  $bool = $val->isWide

文字列が全角文字のみで構成されているなら1。
そうでなければundefを返す。値が0文字やundefの場合もundefを返す。

=item isPassword

  $bool = $val->isPassword
  $bool = $val->isPassword(@spec)

文字列がC<isPrintableAscii>を満たして且つ指定された要素を含んでいれば真を,
そうでなければ偽を返す.

指定された文字以外が入っていることに関しては考慮しない.

C<@spec> に指定できるのは, C<alpha>, C<ALPHA>, C<digit>, C<symbol> の
いずれかの文字列若しくは文字を含んだ配列リファレンス.
指定しなかった場合のデフォルト値は, C<qw(alpha ALPHA digit symbol)> となる.

記号に含まれるものは以下の32文字.
(0.44以前では空白文字も含めた33文字でした)

     ! " # $ % & ' ( ) * + ' - . /
     : ; < = > ? @   [ \ ] ^ _ `  { | } ~


=item isZipCode

  $bool = $val->isZipCode

7桁の郵便番号（XXX-XXXX形式）なら1。
そうでなければundefを返す。

実在する郵便番号かどうかは確認しない。

=item isTelNumber

  $bool = $val->isTelNumber

電話番号（/^\d[\d-]+\d$/）なら1。
そうでなければundefを返す。

数字で始まり、数字で終わり、ハイフン(-)が一つ以上あり、その間が数字とハイフン(-)のみで構成されていれば電話番号とみなす。

=item isEmail

  $bool = $val->isEmail

メールアドレスとして正しい形式であれば1。
そうでなければundefを返す。

=item isMobileEmail

  $bool = $val->isMobileEmail

メールアドレスとして正しい形式であれば1。
そうでなければundefを返す。

但し携帯電話のメールアドレスでは、アカウント名の末尾にピリオドを含んでいる場合がある為、これも正しい形式であるとみなす。

携帯電話キャリアのドメイン名を判別するわけではないため、通常のメールアドレスも 1 を返す。

=item isInteger($min,$max)

  $bool = $val->isInteger
  $bool = $val->isInteger($min,$max)

整数で、かつ$min以上$max以下なら1。$mix,$maxは省略可能。
そうでなければundefを返す。
空もしくはundefの場合は、undefを返す。

デフォルトでは、最大最小のチェックは行わなず整数であれば1を返す。

=item isReal($min,$max)

  $bool = $val->isReal
  $bool = $val->isReal($min,$max)

整数もしくは小数で、かつ$min以上$max以下なら1。$mix,$maxは省略可能。
そうでなければundefを返す。
空もしくはundefの場合は、undefを返す。

デフォルトでは、最大最小のチェックは行わなず、整数もしくは小数であれば1を返す。

=item isHira

  $bool = $val->isHira

平仮名だけが含まれている場合は1。
そうでなければundefを返す。値が0文字やundefの場合もundefを返す。

=item isKata

  $bool = $val->isKata

片仮名だけが含まれている場合は1。
そうでなければundefを返す。値が0文字やundefの場合もundefを返す。

=item isExistentDay

  $bool = $val->isExistentDay
  $bool = $val->isExistentDay(format => 'YMD',date_delim => '-')
  $bool = $val->isExistentDay(date_delim_optional => '-')
  
YYYY-MM-DDで設定された日付が実在するものなら1。
そうでなければundefを返す。

引数を省略した場合はYYYY-MM-DDで設定された日付のみチェックする。

fomrat
日付フォーマットを指定する。省略可能。
省略時は'YYYYMMDD'が指定される。
'YYYYMMDD'
'YMD'

date_delim
日付区切り文字を指定する。区切り文字は複数指定可能。
省略時は-が指定される。

date_delim_optional
日付区切り文字を指定する。指定した区切り文字と区切り文字なしを対象とする。
formatは'YYYYMMDD'のみ指定可能。
date_delimと同時に指定する事は出来ない。
省略可能。

=item isExistentTime

  $bool = $val->isExistentTime
  $bool = $val->isExistentTime(format => 'HMS',time_delim => ':')
  $bool = $val->isExistentTime(time_delim_optional => ':')
  
HH:MM:SSで設定された時刻が実在するものなら1。
そうでなければundefを返す。

引数を省略した場合はHH:MM:SSで設定された時刻のみチェックする。

fomrat
時刻フォーマットを指定する。省略可能。
省略時は'HHMMSS'が指定される。
'HHMMSS'
'HMS'

time_delim
時刻区切り文字を指定する。区切り文字は複数指定可能。
省略時は:が指定される。

time_delim_optional
時刻区切り文字を指定する。指定した区切り文字と区切り文字なしを対象とする。
formatは'HHMMSS'のみ指定可能。
time_delimと同時に指定する事は出来ない。
省略可能。

=item isExistentDateTime

  $bool = $val->isExistentDateTime
  $bool = $val->isExistentDateTime(format => 'YMD HMS',date_delim => '-/',time_delim => ':')
  $bool = $val->isExistentDateTime(date_delim_optional => '-/',time_delim_optional => ':')
  
YYYY-MM-DD HH:MM:SSで設定された日付時刻が実在するものなら1。
そうでなければundefを返す。

引数を省略した場合はYYYY-MM-DD HH:MM:SSで設定された日付時刻のみチェックする。

fomrat
日付時刻フォーマットを指定する。省略可能。
省略時は'YYYYMMDD HHMMSS'が指定される。
'YYYYMMDD HHMMSS'
'YMD HHMMSS'
'YYYYMMDD HMS'
'YMD HMS'

date_delim
日付区切り文字を指定する。区切り文字は複数指定可能。
省略時は-が指定される。

time_delim
時刻区切り文字を指定する。区切り文字は複数指定可能。
省略時は:が指定される。

date_delim_optional
日付区切り文字を指定する。指定した区切り文字と区切り文字なしを対象とする。
formatは'YYYYMMDD HHMMSS'のみ指定可能。
date_delimと同時に指定する事は出来ない。
省略可能。

time_delim_optional
時刻区切り文字を指定する。指定した区切り文字と区切り文字なしを対象とする。
formatは'YYYYMMDD HHMMSS'のみ指定可能。
time_delimと同時に指定する事は出来ない。
省略可能。

=item isGif

  $bool = $val->isGif

=item isJpeg

  $bool = $val->isJpeg

=item isPng

  $bool = $val->isPng

それぞれの形式の画像なら1。
そうでなければundefを返す。

画像として厳密に正しい形式であるかどうかは確認しない。
( L<file(1)> 程度の判断のみ。)

=item isHttpUrl

  $bool = $val->isHttpUrl

"http://" で始まる文字列なら1。
そうでなければundefを返す。

=item isHttpsUrl

  $bool = $val->isHttpsUrl

"https://" で始まる文字列なら1。
そうでなければundefを返す。

=item isLen($min,$max)

  $bool = $val->isLen($min,$max)

バイト数の範囲が指定値以内かチェックする。$mix,$maxは省略可能。
範囲内であれば1、そうでなければundefを返す。

=item isSjisLen($min,$max)

  $bool = $val->isSjisLen($min,$max)

Shift-Jisでのバイト数の範囲が指定値以内かチェックする。$mix,$maxは省略可能。
範囲内であれば1、そうでなければundefを返す。

=item isCharLen($min,$max)

  $bool = $val->isCharLen($min,$max)

文字数の範囲が指定値以内かチェックする。$mix,$maxは省略可能。
範囲内であれば1、そうでなければundefを返す。

=item isPortable

  $bool = $val->isPortable

機種依存文字以外のみで構成されていれば1。
そうでなければ（機種依存文字を含んでいれば）undefを返す。

値が0文字やundefの場合は1を返す。

機種依存文字は、以下の文字を指す。

Shift_JISコード上でのNEC選定IBM拡張文字(89-92区)、IBM拡張文字(115-119区)、特殊文字エリア、JIS外字エリア、MAC外字及び縦組用、
JIS領域外の13区の記号。
Unicode上でのプライベート領域（U+E000～U+F8FF、U+F0000～U+10FFFF）。

携帯絵文字も機種依存文字に含まれる。（文字コード変換によってUnicode上でのプライベート領域にマップされる）

=item isPcPortable

  $bool = $val->isPcPortable

携帯絵文字以外で構成されていれば1。
そうでなければ（携帯絵文字を含んでいれば）undefを返す。

携帯絵文字は、文字コード変換によって Unicode上のプライベート領域（U+FF000～U+FFFFF）に
マップされます。この領域の文字があるかで判定を行います。

=item isDomainName

  $bool = $val->isDomainName

ドメイン名として正当であれば 1 を返し、そうでなければ undef を返す。

=item isIpAddress

  $bool = $val->isIpAddress($checkmask)

$checkmaskに対して、設定されたIPアドレスが一致すれば1。そうでなければundef。

$checkmaskは空白で区切って複数個指定する事が可能。

例：'10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 127.0.0.1 fe80::/10 ::1'。

=item isDateString

  $bool = $val->isDateString('%Y/%m/%d')

日付フォーマット文字列で指定された形式に沿っていれば1。そうでなければundef。
フォーマット文字列は
L<Tripletail::DateTime#strFormat|Tripletail::DateTime/"strFormat">
のものと同一である。

=item isChar

  $bool = $val->isChar($format)

 $format ::= 'digit' | 'alpha' | 'loweralpha' | 'upperalpha' | ARRAYREF of char

指定された文字のみで構成されていれば 1 、そうでなければ undef 。

空文字列に対しては undef を返す。

=back


=head3 conv系

=over 4

=item convHira

  $val->convHira

ひらがなに変換する。

=item convKata

  $val->convKata

カタカナに変換する。

=item convNumber

  $val->convNumber

半角数字に変換する。

=item convNarrow

  $val->convNarrow

全角文字を半角に変換する。

=item convWide

  $val->convWide

半角文字を全角に変換する。

=item convKanaNarrow

  $val->convKanaNarrow

全角カタカナを半角に変換する。

=item convKanaWide

  $val->convKanaWide

半角カタカナを全角に変換する。

=item convComma

  $val->convComma

半角数字を3桁区切りのカンマ表記に変換する。

=item convLF

  $val->convLF

改行コードを LF (\n) に変換する。

=item convBR

  $val->convBR

改行コードを <BR>\n に変換する。

=back


=head3 force系

=over 4

=item forceHira

  $val->forceHira

ひらがな以外の文字は削除。

=item forceKata

  $val->forceKata

カタカナ以外の文字は削除。

=item forceNumber

  $val->forceNumber

半角数字以外の文字は削除。

=item forceMin($max,$val)

  $val->forceMin($max,$val)

半角数字以外の文字を削除し、min未満なら$valをセットする。$val省略時はundefをセットする。

=item forceMax($max,$val)

  $val->forceMax($max,$val)

半角数字以外の文字を削除し、maxより大きければ$valをセットする。$val省略時はundefをセットする。

=item forceMaxLen($max)

  $val->forceMaxLen($max)

最大バイト数を指定。超える場合はそのバイト数までカットする。

=item forceMaxUtf8Len($max)

  $val->forceMaxUtf8Len($max)

UTF-8での最大バイト数を指定。
超える場合はそのバイト数以下まで
UTF-8の文字単位でカットする。

=item forceMaxSjisLen($max)

  $val->forceMaxSjisLen($max)

SJISでの最大バイト数を指定。超える場合はそのバイト数以下まで
SJISの文字単位でカットする。

=item forceMaxCharLen($max)

  $val->forceMaxCharLen($max)

最大文字数を指定。超える場合はその文字数以下までカットする。

=item forcePortable

  $val->forcePortable

機種依存文字を削除。（携帯絵文字も機種依存文字に含む）

詳しい判定条件は L</isPortable> メソッドを参照。

=item forcePcPortable

  $val->forcePcPortable

携帯絵文字を削除。

詳しい判定条件は L</isPcPortable> メソッドを参照。

=back


=head3 その他

=over 4

=item trimWhitespace

  $val->trimWhitespace

値の前後に付いている半角/全角スペース、タブを削除する。

=item countWords

全角/半角スペースで単語に区切った時の個数を返す。

=item strCut

  @str = $val->strCut($charanum)

指定された文字数で文字列を区切り、配列に格納する。

=item strCutSjis

  @str = $val->strCutSjis($charanum)

Shift_JISコードに変換した際に、指定されたバイト数以下になるように
文字列を区切り、配列に格納する。

=item strCutUtf8

  @str = $val->strCutUtf8($charanum)

UTF-8コードに変換した際に、指定されたバイト数以下になるように
文字列を区切り、配列に格納する。

=item genRandomString

  $randomstring = $val->genRandomString($length)
  $randomstring = $val->genRandomString($length, \@types)

C<$length> で指定された文字列長のランダムな文字列を生成する。
使用する文字の種類は配列リファレンスで指定する。
小文字アルファベット、大文字アルファベット、数値に関してはそれぞれ、
C<alpha>、C<ALPHA>、C<num> で指定が可能。

文字種を省略した時にデフォルトで使われる文字は以下の通り:

     2 3 4 5 6 7 8  
 a   c d e f g h         m n   p   r   t u v w x y z
 A B C D E F G H   J K L M N   P   R S T U V W X Y Z

=item detectMobileAgent

  $charset = $val->detectMobileAgent()

User-Agent 文字列から携帯電話の文字コード名を判別して返す。返される文字列は
'sjis-au' のような Unicode::Japanese の文字コード名になる。判別できなかった場合は
undef を返す。

判別に使われる規則は次の通り。

 UserAgent が
   DoCoMo     で始まる  → sjis-imode
   ASTEL      で始まる  → sjis-doti
   Vodafone   で始まる  → utf8-jsky
   Vemulator  で始まる  → utf8-jsky
   SoftBank   で始まる  → utf8-jsky
   Semulator  で始まる  → utf8-jsky
   MOT-       で始まる  → utf8-jsky
   J-PHONE    で始まる  → sjis-jsky
   J-EMULATOR で始まる  → sjis-jsky
   UP.Browser で始まる  → sjis-au

=back

=head1 SEE ALSO

L<Tripletail>

=head1 AUTHOR INFORMATION

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=cut
