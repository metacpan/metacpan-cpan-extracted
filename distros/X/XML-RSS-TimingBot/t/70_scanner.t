
require 5;
use strict;
use Test;
use File::Spec;
my %rss2dat;
BEGIN {
  my $here;
  my $pwd = File::Spec->curdir();
  {
    foreach my $h ( # Places to look:
      File::Spec->catdir($pwd, 't', 'corpus'),
      File::Spec->catdir($pwd, 'corpus'),
      $pwd,
    ) {
      if( -e File::Spec->catdir($h, 'w3.txt') ) {
        $here = $h;
        last;
      }
    }
    die "I can't find my corpus!" unless $here;
  }
  
  opendir IN, $here or die "Can't open $here : $!\nAborting";
  my %files = map { File::Spec->catdir($here, $_) => 1} readdir(IN);
  closedir(IN);
  
  foreach my $rss (sort keys %files) {
    my $dat = $rss;
    $dat =~ s/\.dat$/\.txt/s or next;
    $rss2dat{$rss} = $dat if $files{$dat};
    #print " $rss => $dat\n";
  }
  plan 'tests' => (1 + keys %rss2dat);
  print "# Corpus found in path \"$here\"\n";
}


#sub XML::RSS::TimingBot::DEBUG(){3}
use XML::RSS::TimingBot;

print "# Using XML::RSS::TimingBot v$XML::RSS::TimingBot::VERSION\n";
ok 1;
print "# Hi, I'm ", __FILE__, " and I'll be your hellbeast for tonight...\n";


# - - - - And now a brief interlude, to define our mock class - - - -

{
  package MockyMockTiming;
  sub new { my $x = shift; return bless {@_}, ref($x)||$x }
  sub AUTOLOAD {
    my $it = shift @_;
    my $m = ($MockyMockTiming::AUTOLOAD =~ m/([^:]+)$/s ) ? $1 : $MockyMockTiming::AUTOLOAD;
    ref $it or die "$m is only an object method";
    ( $it->can($m) || die "$it can't do $m ?!?!?" )->( $it, @_ );
    # A brilliant cascade of cause-and-effect!
    # Isn't the Universe an amazing place?  I wouldn't live anywhere else!
  }
  sub can {  # Khaaaaaaaaaaaaaaaaaaannnnn!
    my $m = $_[1];
    return \&new if $m eq 'new';
    return sub {
      my $it = shift;
      return $it->{$m} unless @_; # get
      return($it->{$m} = join "|", @_);    # set
    };
  }
}

# - - - - And a bit of framework - - - -

my $ua = XML::RSS::TimingBot->new || die "What, no user-agent?"; # sanity
sub j { my $h = $_[0]; return "{" .
  join("|", map "$_=$$h{$_}", sort keys %$h). "}"  }
sub js { # Join on results of having Scanned
  my $in = $_[0];
  my $m = MockyMockTiming->new();
  $ua->_scan_xml_timing(\$in, $m);
  j($m);
}

# - - - - And we're back! - - - -
print "# OK, now scanning...\n";

foreach my $rss (sort keys %rss2dat) {
  my $dat = $rss2dat{$rss};
  unless(open DAT, $dat) {
    print "# Can't read-open $dat : $!\n"; ok 0; next;
  }
  my %dat;
  while(<DAT>) { s/[\n\r]+//s; $dat{$1} = $2 if m/^(.*?)=(.+)$/s }
  close(DAT);
  
  unless(open RSS, $rss) {
    print "# Can't read-open $rss : $!\n"; ok 0; next;
  }
  
  my $rss_data; { local $/; $rss_data = <RSS>; close(RSS); }
  $rss_data =~ s/<!--.*?-->//sg; # kill XML comments
  print "# Comparing $rss and $dat\n";
  ok js($rss_data), j(\%dat);
}

print "# Done!  Byebye from ", __FILE__, "\n";

