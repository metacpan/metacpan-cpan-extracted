package NewSpirit;

$VERSION  = "0.01";

use strict;
use Carp;
use NewSpirit::Passwd;
use NewSpirit::Session;
use NewSpirit::LKFile;
use NewSpirit::DataFile;
use Time::Local;
use FileHandle;
use File::Basename;
use File::Copy;
use File::Find;
use File::Path;

my %MONTH = (
	"01" => "Jan",
	"02" => "Feb",
	"03" => "Mar",
	"04" => "Apr",
	"05" => "May",
	"06" => "Jun",
	"07" => "Jul",
	"08" => "Aug",
	"09" => "Sep",
	"10" => "Oct",
	"11" => "Nov",
	"12" => "Dec"
);

sub crypt_credentials {
	my ($username, $password) = @_;
	
	my $credentials = "$username:$password";
	for ( my $i=0; $i < length($credentials); ++$i ) {
		substr($credentials,$i,1) =
			chr(ord(substr($credentials,$i,1))+3);
	}
	
	return $credentials;
}

sub decrypt_credentials {
	my ($credentials) = @_;

	for ( my $i=0; $i < length($credentials); ++$i ) {
		substr($credentials,$i,1) =
			chr(ord(substr($credentials,$i,1))-3);
	}
	
	my ($username, $password) = split (/:/, $credentials, 2);
	
	return ($username, $password);
}

sub check_session_and_init_request {
	my $q = shift;
	
	my ($window, $username);

	my $project     = $q->param('project');
	my $ticket      = $q->param('ticket');
	my $credentials = $q->param('credentials');
	
	my ($username, $password);

	my $sh;
	if ( $ticket eq '' and $credentials ne '' ) {
		# on the fly login via newspirit command line client
		my $ph = new NewSpirit::Passwd ($q);
		($username, $password) = decrypt_credentials($credentials);
		if ( $ph->check_password ($username, $password) ) {
			$ph = undef;	# unlock passwd
			$sh = new NewSpirit::Session;
			$ticket  = $sh->create ($q->remote_addr(), $username);
			$q->param('ticket',$ticket);
		}
		
		#
	} else {
		$sh = new NewSpirit::Session;
	}
	
	eval { ($username, $window) = $sh->check ($ticket, $q->remote_addr) };
	my $error = $@;

	if ( $q->param('window') ) {
		$window = 1;
	}

	if ( not $error ) {
		if ( $project ) {
			$sh = undef; # unlock session (prevents deadlock)
			my $ph = new NewSpirit::Passwd ($q);
			if ( not $ph->check_project_access($username, $project) ) {
				$error = "You have no access on this project!";
			}
			$ph = undef; # unlock passwd

			# create session object again
			$sh = NewSpirit::Session->new;
			$sh->check ($ticket, $q->remote_addr());
		}
	}

	if ( $error ) {
		print <<__HTML;
<html>
<head><title>$CFG::window_title</title></head>
<body bgcolor="$CFG::BG_COLOR">
$CFG::FONT
<b>Your user session is invalid. Please <a target="NEWSPIRIT" href="$CFG::admin_url">login</a> again.</b>
</FONT>
</body>
</html>
__HTML
		exit;
	}
	
	$q->param('username', $username);
	$q->param('window', $window);

	read_user_config($username);

	return $sh;
}

sub remove_on_the_fly_session {
	my ($q) = @_;
	return if not $q->param('credentials');
	
	delete_session($q);
	
	1;
}

sub clone_session {
	my ($q, $window) = @_;

	# ok, session data should be copied from our actual session,
	# so we add our ticket to the $sh->create call.

	my $sh = new NewSpirit::Session;
	my $ticket = $sh->create (
		$q->remote_addr(),
		$q->param('username'),
		$q->param('ticket'),
		$window
	);
	$sh = undef;
	
	# update the ticket in query object
	$q->param('ticket', $ticket);

	1;
}

sub print_error {
	my ($err) = @_;
	
	print "</td></tr></table>\n";
	print "</td></tr></table>\n";
	print "</td></tr></table>\n";
	print "</td></tr></table>\n";
	print "</td></tr></table>\n";
	print "<P>$CFG::FONT<B>Internal Error</B></font><P><PRE>$err</PRE>\n";
}

sub blank_page {
	print <<__HTML;
<html>
<head><title>$CFG::window_title</title></head>
<body bgcolor="$CFG::BG_COLOR">
</body>
</html>
__HTML
}

sub read_user_config {
	my ($username) = @_;
	
	my $filename = "$CFG::user_conf_dir/$username.conf";
	
	return if not -f $filename;

	my $lf = new NewSpirit::LKFile ($filename);
	my $data = $lf->read;

	{
		no strict;
		eval $$data;
		croak "error reading user config '$filename': $@" if $@;
	}
	
	1;
}

sub get_project_info {
	my ($project) = @_;
	
	my $filename = "$CFG::project_conf_dir/$project.conf";
	
	my $df = new NewSpirit::DataFile ($filename);
	
	return $df->read;
}

sub start_page {
	my %par = @_;
	$par{title} ||= $CFG::window_title;
	$par{bgcolor} ||= $CFG::BG_COLOR;
	$par{marginheight} ||= 1;
	$par{marginwidth} ||= 1;

	my $head;
	if ( $par{link_style} eq 'plain' ) {
		$head .= q|<style type="text/css">A:visited,A:link,A:|.
			 q|active{text-decoration:none}</style>|;
	}
	
	print <<__HTML;
<html>
<head>
  <title>$par{title}</title>
  $head
</head>
<body bgcolor="$par{bgcolor}" link="$CFG::LINK_COLOR"
      alink="$CFG::ALINK_COLOR" vlink="$CFG::VLINK_COLOR"
      text="$CFG::TEXT_COLOR" marginheight="$par{marginheight}"
      marginwidth="$par{marginwidth}">
__HTML
}

sub end_page {
	print <<__HTML;
</body>
</html>
__HTML
}

sub open_session_file {
	my ($ticket) = @_;
	
	return new NewSpirit::LKDB ("$CFG::session_dir/$ticket");
}

sub js_open_window {
	my $q = shift;

	my $ticket = $q->param('ticket');
	my $r = int(rand(10000));
	my $rand_window_name = "WIN$ticket$r";

	print <<__HTML;
<SCRIPT LANGUAGE="JavaScript">
  function open_window (url, name, sizex, sizey, posx, posy, return_obj, with_status_bar) {
    if ( name == null ) {
      var r = Math.floor(Math.random()*100000);
      name = 'WIN$ticket'+r;
    }

    var geometry = '';
    
    if ( sizex > 0 ) {
      geometry=",width="+sizex+",height="+sizey;
    }

    if ( posx > 0 ) {
      geometry = geometry + ',screenX='+posx + ',screenY='+posy;
    }

    var window_options;
    if ( ! with_status_bar ) {
        window_options =
        'toolbar=no,location=no,directories=no,status=no,menubar=no,'+
        'resizable=yes,scrollbars=yes';
    } else {
        window_options =
        'toolbar=yes,location=yes,directories=yes,status=yes,menubar=yes,'+
        'resizable=yes,scrollbars=yes';
    }
    window_options += geometry;

    // we open the window without URL, maybe it exists already
    var w = window.open (
        url,
        name,
	window_options
    );

    w.focus();
  
    if ( return_obj ) {
      return w;
    }
    return;

    // the code beyond is actually disabled...

    // does the window have a location.href? If so, it was already
    // existant and we will not modify its geometry

    alert ('window name='+name);

    if ( w.document.location.href == '' ) {
      if ( sizex > 0 ) {
        w.outerWidth = sizex;
	w.outerHeight = sizey;
      }
      if ( posx > 0 ) {
        w.pageXOffset = posx;
	w.pageYOffset = posy;
      }
    }

    if ( url != '' ) {
      w.document.location.href = url;
    }

    w.focus();
  
    if ( return_obj ) {
      return w;
    }
  }
</SCRIPT>
__HTML
}

sub get_timestamp {
        my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);

        ++$mon;

        $mon = "0".$mon if $mon < 10;
        $mday = "0".$mday if $mday < 10;
        $hour = "0".$hour if $hour <10;
        $min = "0".$min if $min < 10;
        $sec = "0".$sec if $sec < 10;

	$year += ($year < 97) ? 2000 : 1900;

	return "$year.$mon.$mday-$hour:$min:$sec";
}

sub timestamp2time {
	my ($timestamp) = @_;
	
	# never tested this routine!!!!
	
	return timelocal (reverse(split(/[-:.]/,$timestamp)));
}

sub format_timestamp {
	my ($timestamp) = @_;

	$timestamp =~ /^(\d+)\.(\d+)\.(\d+)-(\d+):(\d+):(\d+)$/;
	my $day = $3;
	my $date = $MONTH{$2}." $1 - $4:$5:$6";
	$day =~ s/^0//;	
	$date = "$day $date";
	$date =~ s/\s/&nbsp;/g;
	
	return $date;
}

sub strip_exception {
	my ($exception) = @_;
	
	$exception =~ s! at /.*!!;
	
	return $exception;
}

sub dump {
	eval {
		require "Data/Dumper.pm";
		print STDERR "$0 $$\n", Data::Dumper::Dumper (@_), "\n";
		croak "called from";
	};
	$@ =~ s/from at/from/;
	print STDERR $@;
}

sub dump_html {
	require "Data/Dumper.pm";
	print "<pre>", Data::Dumper::Dumper(@_), "</pre><p>\n";
}

sub std_header {
	my %par = @_;
	
	my $page_title   = $par{page_title};
	my $close        = $par{close};
	my $window_title = $par{window_title};
	
	$window_title ||= $page_title;
	
	NewSpirit::start_page (
		title => $window_title,
		marginwidth => 5,
		marginheight => 5,
		link_style => 'plain'
	);
	
	print <<__HTML;
<table BORDER=0 BGCOLOR="$CFG::TABLE_FRAME_COLOR"
       CELLSPACING=0 CELLPADDING=1 WIDTH="100%">
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
  <tr><td>
    $CFG::FONT_BIG<b>$page_title</b></FONT>
  </td>
__HTML
	if ( $close ) {
		print <<__HTML;
  <td valign="center" align="right">
    $CFG::FONT<b>
    <a href="javascript:window.close()">CLOSE WINDOW</a>
    </b></FONT>
  </td>
__HTML
	}
	
	print <<__HTML;  
  </tr>
  </table>
  </td></tr>
</table>
<p>
__HTML
}

sub delete_lock {
	my $q = shift;

	my $project = $q->param('project');

	return 1 if not $project;
	
	my $project_info = get_project_info ($project);

	my $lock = new NewSpirit::Lock (
		project_meta_dir  => "$project_info->{root_dir}/meta",
		username          => $q->param('username'),
		ticket            => $q->param('ticket')
	);
	$lock->delete;

	1;
}

sub delete_session {
	my $q = shift;
	
	my $sh = new NewSpirit::Session;
	$sh->delete ($q->param('ticket'));
	$sh = undef;

	1;
}

sub filename_glob {
	my %par = @_;
	
	my $dir      = $par{dir};
	my $regex    = $par{regex};

	my $dh = new FileHandle;
	opendir $dh, $dir or 
	    die ("Can't open directory '$dir'");
	my @filenames = map "$dir/$_", grep /$regex/, readdir $dh;
	closedir $dh;
	
	return \@filenames;
}

sub copy_tree {
	my %par = @_;
	
	my $from_dir = $par{from_dir};
	my $to_dir   = $par{to_dir};
	my $verbose  = $par{verbose};
	my $filter   = $par{filter};

#	print "from_dir='$from_dir'<br>\n";
#	print "to_dir='$to_dir'<p>\n";

	# content of $from_dir will be copied inside $to_dir
	# missing paths will be created!
	
	my $cnt = 1;	# counter for verbosity
	
	find (
		sub {
			my $dir  = $File::Find::dir;
			my $file = $_;

			my $from_file = "$dir/$file";
			$dir =~ s!^$from_dir!!;	# make relative
			$dir =~ s!/$!!;
			my $to_file   = "$to_dir/$dir/$file";

			return if $file eq '.';
			return if $filter and $file !~ /$filter/;

			if ( $verbose ) {
				--$cnt;
				if ( $cnt == 0 ) {
					print "copying...<br>\n";
					print "<script>self.window.scroll(0,5000000)</script>\n";
					print "<script>self.window.scroll(0,5000000)</script>\n";
					$cnt = 50;
				}
			}

			if ( $filter ) {
				# if filtering is on, it may happen, that
				# the base directory does not exist. So
				# we may need to do a mkpath here.
				my $to_dir = dirname $to_file;
				if ( not -d $to_dir ) {
					my $from_dir = dirname $from_file;
					my $dir_mode = (stat($from_dir))[2];
					mkpath ([$to_dir], 0, $dir_mode)
						or croak "can't create dir '$to_dir': $!";
				}
			}

			my @stat = stat($from_file);
			my $mode  = $stat[2];
			my $atime = $stat[8];
			my $mtime = $stat[9];

			if ( -d $from_file ) {
				# Ok, this is a directory.
				# create $target_dir, if not existent yet
				if ( not -d $to_file ) {
					mkpath ([$to_file], 0, $mode)
						or croak "can't create dir '$to_file': $!";
				}
			} else {
				# This is a file: copy it.
				copy ($from_file, $to_file)
					or croak "can't copy file '$from_file' to '$to_file': $!";
			}

			# set filemode, atime and mtime
			chmod $mode, $to_file;
			utime $atime, $mtime, $to_file;
		},
		$from_dir
	);

}

1;
