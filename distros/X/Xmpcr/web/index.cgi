#!/opt/links/perl -w

use strict;
use CGI;
use HTML::Template;
use Audio::Xmpcr;


# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#                                configuration
my $nethost="localhost";               # where xmpcrd is running
my $templatedir="/w3/xm/template";     # web template storage
my $iceaddr="http://your.host.here:port", # icecast address
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

my $q=new CGI;
my $cmd=$q->param("cmd") || "";
my($ctr)=(0);
print $q->header;

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#                          try to load the module
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
my $radio;
eval {
	$radio=new Audio::Xmpcr(NETHOST => $nethost,LOCKER => "web-interface");
};
my $t=new HTML::Template(filename => "$templatedir/index.tmpl");
if (! $radio) {
	# no daemon?
	my $t=new HTML::Template(filename => "$templatedir/nodaemon.tmpl");
	print $t->output;
	exit(0);
}
my %stat=$radio->status;

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#                          execute commands
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
if ($cmd eq "change") {
	$_=$radio->setchannel($q->param("channel") || 1)
			and bail("Can't change channel: $_");
} elsif ($cmd eq "on" or $cmd eq "off") {
	$_=$radio->power($cmd)
			and bail("Can't change power: $_");
}
%stat=$radio->status; # refresh

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#                          generate the display screen
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
my($genrerow,$lastgenre,$row)=([],"",[]);
if ($stat{POWER} eq "on") {
	map {
		my($cnum,$cname,$cat,$sn,$art);
		if ($_->{CAT} ne $lastgenre and scalar @{ $row }) {
			push(@{ $genrerow },{
				GENRE => $lastgenre,
				NUMROWS => scalar @{ $row }+1, # add in the category column
				ROW => $row,
			});
			$row=[];
		}
		$lastgenre=$_->{CAT};

		$_->{BGCOLOR}=($ctr++%2==1) ? "#d7f7f5" : "#d7d7f7";
		delete $_->{CAT};
		push(@{ $row },$_);
	} $radio->list;
	push(@{ $genrerow },{ GENRE => $lastgenre, NUMROWS => scalar @{ $row }+1, 
				ROW => $row, }) if scalar @{ $row };   # get the last one
	$t->param(GENREROW => $genrerow);
}

$t->param(
	CURCHANNAME => $stat{NAME},
	CURCHANNUM => $stat{NUM},
	CURPOWER => $stat{POWER},
	NEWPOWER => $stat{POWER} eq "on" ? "off" : "on",
	CURCAT => $stat{CAT},
	CURART => $stat{ARTIST},
	CURSONG => $stat{SONG},
	SIGNAL => $stat{ANTENNA} || "&nbsp;",
	ICEADDR => $iceaddr,
	LOCKER => $stat{LOCKER},
);
print $t->output;
exit(0);

sub bail {
  my($msg)=@_;
	print "<h1>Error</h1><p>$msg</p>\n";
	exit(0);
}
