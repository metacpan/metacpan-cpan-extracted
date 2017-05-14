package Time::Convert;

my $VERSION = 0.5;
print("=" x 56 . "\n   Time::Convert (Version: $VERSION) - Matthew Fenton 2005\n" . "=" x 56 . "\n");

sub new {
        my $class = shift;

        my $Time = {
			'time' => time
		   };
        bless($Time, $class);
        return $Time;
}

sub ConvertSecs {
	my $Time = shift;
	my $sec  = shift;

	return "$sec seconds" if($sec < 60);

	my $min = $sec / 60, $sec %= 60;
	$min = int($min);
	return "$min minutes and $sec seconds." if($min < 60);

	my $hrs = $min / 60, $min %= 60;
	$hrs = int($hrs);
	return "$hrs hours, $min minutes and $sec seconds." if($hrs < 24);

	my $days = $hrs / 24, $hrs %= 24;
	$days = int($days);
	return "$days days, $hrs hours, $min minutes and $sec seconds." if($days < 365);

	my $years = $days / 365, $days %= 365;
	$years = int($years);
	return "$years years, $days days, $hrs hours, $min minutes and $sec seconds.";
}

=head1 NAME

	Time::Convert - Interface to converting unix seconds to years, days, hours and minutes.

=cut

=head1 SYNOPSIS

	use Time::Convert;
	my $convert = new Time::Convert;

=cut

=head1 EXAMPLE

	use Time::Convert;
	my $convert = new Time::Convert;
	   $REPLY   = $convert->ConvertSecs(time);
	print($REPLY);

=cut