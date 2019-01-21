use strict;
use warnings;
use WebService::DailyConnect;
use Term::Clui qw( ask ask_password );
use Path::Tiny qw( path );

my $user = ask("email:");
my $pass = ask_password("pass :");

my $dc = WebService::DailyConnect->new;
$dc->login($user, $pass) || die "bad email/pass";

my $user_info = $dc->user_info;

foreach my $kid (@{ $dc->user_info->{myKids} })
{
  my $kid_id = $kid->{Id};
  my $name   = lc $kid->{Name};
  foreach my $photo_id (map { $_->{Photo} || () } @{ $dc->kid_status($kid_id)->{list} })
  {
    my $dest = path("~/Pictures/dc/$name-$photo_id.jpg");
    next if -f $dest;
    print "new photo: $dest\n";
    $dest->parent->mkpath;
    $dc->photo($photo_id, $dest);
  }
}
