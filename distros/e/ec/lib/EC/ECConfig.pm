package EC::ECConfig;

use EC::Utilities;
use Tk::Dialog;

$VERSION=0.11;

                     # Default option settings when config file not found
my $defaults =       # config file; see ~/.ec/.ecconfig for description
  {                  # of each option and valid parameters
   maildomain => 'localhost',
   debug => 0,
   verbose => 0,
   smtpport => 25,
   usesendmail => 0,
   useqmail => 0,
   useexim => 0,
   sendmailprog => '/usr/sbin/sendmail',
   sendmailsetfrom => 0,
   qmailinjectpath => '',
   sigfile => '.signature',
   usesig => 1,
   mailspooldir => '/var/spool/mail',
   maildir => "$ENV{HOME}/Mail",
   qmailbox => "Mailbox",
   incomingdir => 'incoming',
   trashdir => 'trash',
   helpfile => 'EC/ec.help',
   trashdays => 2,
   pollinterval => 600000,
   senderwidth => 40,
   datewidth => 20,
   fccfile => '',
   quotestring => '> ',
   senderlen => 25,
   datelen => 21,
   weekdayindate => 1,
   sortfield => 1,
   sortdescending => 0,
   servertimeout => 10,
   headerview => 'brief',
   ccsender => 1,
   browser => '',
   timezone => '-0400',
   gmtoutgoing => 0,
   xterm => 'xterm',
   offline => '',
   };

sub new {
  ($cfgfilename) = @_;
  my $self = readconfig ($cfgfilename);
  bless $self, 'EC::Config';
  return $self;
}

sub readconfig {
  my ($file) = @_;
  my ($l, @tmpfolders, @cfgfile,$topmaildir);
  @cfgfile = content ($file);
  my %userconfig;
  foreach $l (@cfgfile) {
    if( $l !~ /^\#/) {
      my ($opt, $val) = ($l =~ /^(\S+)\s(.*)$/);
      $val =~ s/[\'\"]//g;
      if( $opt =~ /folder/ ) {
	push @tmpfolders, ($val);
      } elsif ( $opt =~ /filter/ ) {
	push @{$userconfig{'filter'}}, ($val);
      } else {
	$userconfig{$opt} = $val;
      }
      print "config: $opt = ".$userconfig{$opt}."\n" if $debug;
    }
  }
  push @{$userconfig{'folder'}}, ($userconfig{incomingdir});
  push @{$userconfig{'folder'}}, ($userconfig{trashdir});
  push @{$userconfig{'folder'}}, ($_)  foreach( @tmpfolders );
  foreach my $k ( keys %$defaults ) {
    if (! exists $userconfig{$k}) {
      print "Using default value ".$defaults -> {$k}." for $k\n." if $debug;
      $userconfig{$k} = $defaults -> {$k};
    }
  }
  if( ! $cfgfile[0] ) {
    print "Could not open $cfgfilename: using defaults.\n".
	"Refer to the file README for installation instructions.\n";
    foreach (keys %{$defaults}) {
      $userconfig{$_} = $defaults -> {$_};
      print "config: $_ = ".$userconfig{$_}." from defaults\n" if $debug;
    }
  }
  $userconfig{maildir} = expand_path ($userconfig{maildir});
  verify_path ($userconfig{maildir});
  $userconfig{'helpfile'} = $ENV{HOME}.'/'.$userconfig{'helpfile'};
  $userconfig{'sigfile'} = $ENV{HOME}.'/'.$userconfig{'sigfile'};
  foreach( @{$userconfig{folder}} ) {
    $_ = $userconfig{maildir}.'/'.$_;
    verify_path ($_);
  }
  $userconfig{'incomingdir'} =
    $userconfig{maildir} .'/'.$userconfig{'incomingdir'};
  verify_path ($userconfig{incomingdir});
  $userconfig{'trashdir'}
    = $userconfig{maildir} .'/'.$userconfig{'trashdir'};
  verify_path ($userconfig{trashdir});
  $textfont = $userconfig{'textfont'};
  $headerfont = $userconfig{'headerfont'};
  $menufont = $userconfig{'menufont'};
  return \%userconfig;
}

sub direrrortext {
    return "The program could not locate your $ENV{HOME}./ec\n".
	"configuration directory.  Should I create one now?"
}

1;
