package OnSearch::WebLog; 

#$Id: WebLog.pm,v 1.1.1.1 2005/07/03 06:02:18 kiesling Exp $

use strict;
use warnings;
use Carp;

my $VERSION='$Revision: 1.1.1.1 $';

require Exporter;
require DynaLoader;
our (@ISA, @EXPORT, %EXPORT_TAGS);
@ISA = qw(Exporter DynaLoader);
@EXPORT = (qw/&clf/);

sub clf {
    my $priority = shift;
    my $fmt = shift;
    my (@args) = @_;
    my $pwd;

    my $cfg = OnSearch::AppConfig -> new;

    if (! $cfg->str ('WebLogDir')) {
	($pwd) = (`pwd` =~ /(.*)\n/);
	$cfg -> read_config ("$pwd/onsearch.cfg");
    }

    my $client = (($ENV{REMOTE_ADDR}) ? $ENV{REMOTE_ADDR} : 
		  $ENV{LOGNAME});
    # Not strictly conformant with CLF, but a lot less cluttered.

    no warnings;
    #
    # One or the other of these will be undefined, depending on
    # whether the script is being run under the Web server.
    # Avoid "uninitialized value" warning messages.
    #
    my $referer = (($ENV{HTTP_REFERER}) ? 'client' :
		   $ENV{SHELL});

    my $s = _clftime () . " [$priority] [$referer $client] " .
	(@args ? sprintf ($fmt, @args) : $fmt);
    use warnings;

    if ($cfg->str('WebLogDir')) {
	open LOG, 
	   ">>" . $cfg->str('WebLogDir') . '/onsearch.log'
              or warn "OnSearch clf: $!\n";
	my $oldfh = select LOG; $| = 1; select $oldfh;
        print LOG "$s\n";
        close LOG;
    } else {
	print STDERR "$s\n";
    }
}

sub _clftime {

    my @mnames = (qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/);
    my @dnames = (qw/Sun Mon Tue Wed Thu Fri Sat/);
    my @timeval = localtime (time);
    
    my $s = sprintf ("[%s %s %2d %02d:%02d:%02d %4d]",
		     $dnames[$timeval[6]],
		     $mnames[$timeval[4]],
		     $timeval[3],
		     $timeval[2],
		     $timeval[1],
		     $timeval[0],
		     $timeval[5] + 1900);
    return $s;
}

1;
