my ($s) = $_[0];
my ($fmt) = $_[1] || 'dd-MON-rr';

$err = '';
$rtnTime = '';

my (@timevals) = localtime($s);

foreach my $f (qw(month mon Month Mon MONTH MON))
{
	$fmt =~ s/($f)/&{$f}($1)/eg;
	last  if ($err)	;
}
foreach my $f (qw(ddd dd yyyy yy hh24 hh mi mm sssss ss rm rr))
{
	$fmt =~ s/($f)/&{$f}($1)/egi;
	last  if ($err)	;
}

$fmt =~ s/\b(a)([\.m]?)\b/&a($1).$2/egi;

$fmt =~ s/([0\$BSCL]*)([9D\.\,GV]+)(\s*CR|PR|EEEE)/&fmt9($1,$2,$3)/eg;

$rtnTime = $fmt;


sub fmt9
{
	my ($pre, $val, $suf) = (@_);
	my $l = length($val) + 1;
	my $dec;
	$dec = length($1)  if ($val =~ /[\.DV](\d+)/i);
	my $fmtstr = '%';
	$fmtstr .= $l;
	$fmtstr .= '.'.$dec  if ($dec);
	if ($suf =~ /(E)EEE/i)
	{
		$fmtstr .= $1;
	}
	else
	{
		$fmtstr .= 'f';
	}
	my $t = sprintf($fmtstr, $s);
	$t =~ s/\s(\S)/\$$1/  if ($pre =~ /[C\$]/i);
	$t =~ s/(\s)([^\s\-])/$1\+$2/  if ($pre =~ /S/i);
	$t =~ s/[0\.\,]/ /g  if ($pre =~ /B/i && $t =~ /^[\s0\.\+\-\,]+$/);
	$t =~ s/([\d\.\+\-]+)/
		my ($one) = $1;
		$one *= 10 ** $dec;
		$one;
	/e  if ($val =~ /V/i);
	if ($suf =~ /(\s*cr)/i)
	{
		my ($one) = $1;
		$t =~ s/\-(\S+)/$1$one/;
	}
	elsif ($suf =~ /pr/i)
	{
		$t =~ s/(\-)(\S+)(\s?)/\<$2\>/;
		$t =~ s/\$\</\<\$/;
	}
	return $t;
}

sub month
{
	my @months = (
			'january  ', 'february ', 'march    ', 'april    ',
			'may      ', 'june     ', 'july     ', 'august   ',
			'september', 'october  ', 'november ', 'december ');

	return $months[$timevals[4]];
}

sub Month
{
	my @months = (
			'January  ', 'February ', 'March    ', 'April    ',
			'May      ', 'June     ', 'July     ', 'August   ',
			'September', 'October  ', 'November ', 'December ');

	my $indx = shift;
	return $months[$timevals[4]];
}

sub MONTH
{
	my @months = (
			'JANUARY  ', 'FEBRUARY ', 'MARCH    ', 'APRIL    ',
			'MAY      ', 'JUNE     ', 'JULY     ', 'AUGUST   ',
			'SEPTEMBER', 'OCTOBER  ', 'NOVEMBER ', 'DECEMBER ');

	my $indx = shift;
	return $months[$timevals[4]];
}

sub mon
{
	my @months = ('jan', 'feb', 'mar', 'apr', 'may', 'jun', 
			'jul', 'aug', 'sep', 'oct', 'nov', 'dec');

	my $indx = shift;
	return $months[$timevals[4]];
}

sub Mon
{
	my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
			'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

	my $indx = shift;
	return $months[$timevals[4]];
}

sub MON
{
	my @months = ('JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
			'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC');

	my $indx = shift;
	return $months[$timevals[4]];
}

sub rm
{
	my @months = ('i', 'ii', 'iii', 'iv', 'v', 'vi', 
			'vii', 'viii', 'ix', 'x', 'xi', 'xii');

	my $indx = shift;
	return $months[$timevals[4]];
}

sub mm
{
	my ($t) = $timevals[4] + 1;
	$t = '0' . $t  if ($t < 10);
	return $t;
}

sub yyyy
{
	return $timevals[5] + 1900;
}

sub yy
{
	return &rr;
}

sub rr
{
	my ($t) = $timevals[5];
	$t -= 100  if ($t >= 100);
	$t = '0' . $t  if ($t < 10);
	return $t;
}

#sub ddd
#{
#	return $mday;
#}

sub dd
{
	my ($t) = $timevals[3];
	$t = '0' . $t  if ($t < 10);
	return $t;
}

sub hh24
{
	my ($t) = $timevals[2];
	$t = '0' . $t  if ($t < 10);
	return $t;
}

sub hh
{
	my ($t) = $timevals[2];
	$t -= 12  if ($t >= 13);
	$t += 12  unless ($t);
	$t = '0' . $t  if ($t < 10);
	return $t;
}

sub a
{
	my ($t) = $timevals[2];
	return 'a'  if ($t < 12);
	return 'p';
}

sub mi
{
	my ($t) = $timevals[1];
	$t = '0' . $t  if ($t < 10);
	return $t;
}

sub sssss
{
	return (($timevals[2]*3600) + ($timevals[1]*60) + $timevals[0]);
}

sub ss
{
	my ($t) = $timevals[0];
	$t = '0' . $t  if ($t < 10);
	return $t;
}

sub ddd
{
	my ($t) = $timevals[7] + 1;
	$t = '0' . $t  if ($t < 10);
	return $t;
}

1
