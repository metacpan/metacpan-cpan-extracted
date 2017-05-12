use strict;
use warnings;
use Time::Piece;
use Text::CSV;
use Win32::OLE;
use Win32::ADRecurse qw[recurse];

$|=1;

my $csv = Text::CSV->new();

recurse(
  sub {
    my $adspath = shift;
    my $class = shift;
    return unless $class eq 'user';
    my $user = Win32::OLE->GetObject($adspath);
    return unless $user;
    $user->GetInfo;
    return if $user->{userAccountControl} & 0x0002; # skip disabled accounts
    my $when = '';
    eval {
      my $t = Time::Piece->strptime( $user->{whenCreated}, "%m/%d/%Y %I:%M:%S %p" );
      $when = $t->strftime( '%Y/%m/%d %H:%M:%S' );
    };
    my $last = '';
    eval {
      $last = time2str("%Y/%m/%d %T", msqtime2perl( $user->{lastLogonTimestamp} ) );
    };
    $csv->combine( ( map { s/\n/ /g; s/[^[:print:]]+//g; $_ } map { $user->{$_} || '' }
      qw(sAMAccountName givenName initials sn displayName mail employeeID
         title department company physicalDeliveryOfficeName streetAddress l postalCode) ), $last, $when )
      and print $csv->string(), "\n";
  },
);

exit 0;

sub msqtime2perl { # MicroSoft QuadTime to Perl
  my $foo = shift;
  my ($high,$low) = map { $foo->{ $_ } } qw(HighPart LowPart);
  return unless $high and $low;
  return ((unpack("L",pack("L",$low)) + (unpack("L",pack("L",$high)) *
    (2 ** 32))) / 10000000) - 11644473600;
}
