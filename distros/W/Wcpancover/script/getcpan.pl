#!perl

use strict;
use warnings;


use lib qw(../lib);

my $job_entries = {};

my $CPANFILE = './cpanfile.txt';

my $PIDFILE = 'cpanfile.pid';

my $url = 'http://www.cpan.org/modules/01modules.index.html';

my $entries = {};

create_pid($PIDFILE);

#remove_file($CPANFILE);

#fetch_file($url, $CPANFILE);

my $config = {
  'db_connect' => [
      'dbi:SQLite:dbname=../wcpancover.db',
                            undef,
                            undef,
                            {
                             'sqlite_unicode' => 1
                            }  ],
  'db_schema' => 'Wcpancover::DB::Schema',
  'secret'    => 'app_secret'
};

########################################
my $schema_class = $config->{db_schema};
eval "require $schema_class"
  or die "Could not load Schema Class ($schema_class), $@";
my $db_connect = $config->{db_connect}
  or die "No DBI connection string provided";
my @db_connect = ref $db_connect ? @$db_connect : ($db_connect);

my $schema = $schema_class->connect(@db_connect)
  or die "Could not connect to $schema_class using $db_connect[0]";

open (my $fh, '<', $CPANFILE) or die "couldn't open $CPANFILE, $@";

my $found = 0;

use CPAN::ReleaseHistory 0.10;
my $history  = CPAN::ReleaseHistory->new();
my $iterator = $history->release_iterator();
while (my $release = $iterator->next_release) {
  #last if ($found > 500);
  $found++;
  my $name = $release->distinfo->distvname;
  my $dist = $release->distinfo->dist;
  my $version = $release->distinfo->version // '';
  my $author = $release->distinfo->cpanid;
  my $date   = $release->date;

  entry({
    author => $author,
    name   => $name,
    dist   => $dist,
    version  => $version . '',
    date   => $date,
  });
}

print STDERR 'records processed: ',$found,"\n";

if (0) {
my $rs = $schema->resultset('Package');
my $result =
  $schema->resultset('Package')->search(undef, {order_by => {-asc => 'name'}});


while (my $record = $result->next) {
  if (!exists $entries->{$record->name}) {
    $record->delete;
  }
}

}

remove_pid($PIDFILE);

sub entry {
  my ($entry) = @_;

  if (exists $entry->{name}) {
    $entries->{$entry->{name}}++;

    my $rs = $schema->resultset('Package');
    $rs->update_or_create($entry,{ key => 'name_UNIQUE' });
  }
}

sub create_pid {
  my $pidfile = shift;
  if (-f $pidfile) {
    open(LF, "<$pidfile") or die "unable to open $pidfile: $!";
    my $pid = <LF>;
    chomp $pid;

    close(LF);
    my @tmp = `ps --no-headers -p $pid | grep $pid`;

    if ($#tmp < 0) {
      print STDERR
        "PIDFILE exists, foreign pid not running $pid, removing PIDFILE", "\n";
      unlink($PIDFILE);

      print STDERR "Creating PID " . $$ . " (" . $PIDFILE . ")", "\n";
      open(L, ">$pidfile") or die "unable to create pidfile: $!";
      print L $$;
      close(L);

      return;
    }

    print STDERR "Allready running ($pid) ... exit", "\n";
    exit;
  }

  open(L, ">$pidfile") or die "unable to create pidfile: $!";
  print L $$;
  close(L);
}

sub remove_pid {
  my $pidfile = shift;
  print STDERR "Remove Pidfile (" . $pidfile . ")", "\n";
  unless (-f $pidfile) {
    return;
  }
  unlink($pidfile) or die "unable to delete pidfile: $!";
}

sub remove_file {
  my $xmlfile = shift;
  print STDERR "Remove cpanfile (" . $xmlfile . ")", "\n";
  unless (-f $xmlfile) {
    return;
  }
  unlink($xmlfile) or die "unable to delete $xmlfile: $!";
}

sub fetch_file {
  my ($url, $file) = @_;

  #my $command = '/usr/bin/wget';
  #my $outfile = "--output-document=$file";

  my $command = '/usr/bin/curl';
  my $outfile = "> $file";

  my @command = ($command, $url, $outfile);

  #print STDERR join(' ',@command),"\n";

  my $command_string = join(' ', @command);
  print STDERR $command_string, "\n";
  system($command_string);

  if ($? == -1) {
    #print STDERR "wget command failed: $!\n";
    #return 0;
    die "fetch file failed: $!";
  }
}

exit;

__END__


