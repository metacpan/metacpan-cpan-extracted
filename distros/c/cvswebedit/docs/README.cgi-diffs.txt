I was getting very confused as to whether I should be using CGI.pm or the CGI modules.
CGI.pm appears to be the older system, but CGI modules does not have as much functionality.

This file contains a recursive, side by side diff of the two releases.

At the bottom you'll notice that the only module file in common is Carp.pm, of which CGI.pm has the later 
version (1.10).

Only in CGI.pm-2.42: ANNOUNCE
Only in CGI.pm-2.42/CGI: Apache.pm
Only in CGI-modules-2.76/CGI: Base.pm
Only in CGI-modules-2.76/CGI: BasePlus.pm
Only in CGI.pm-2.42/CGI: CGI.pm
diff --side-by-side --ignore-all-space --recursive CGI.pm-2.42/CGI/Carp.pm CGI-modules-2.76/CGI/Carp.pm
package CGI::Carp;						package CGI::Carp;

=head1 NAME							=head1 NAME

B<CGI::Carp> - CGI routines for writing to the HTTPD (or othe	B<CGI::Carp> - CGI routines for writing to the HTTPD (or othe

=head1 SYNOPSIS							=head1 SYNOPSIS

    use CGI::Carp;						    use CGI::Carp;

    croak "We're outta here!";					    croak "We're outta here!";
    confess "It was my fault: $!";				    confess "It was my fault: $!";
    carp "It was your fault!";   				    carp "It was your fault!";   
    warn "I'm confused";					    warn "I'm confused";
    die  "I'm dying.\n";					    die  "I'm dying.\n";

=head1 DESCRIPTION						=head1 DESCRIPTION

CGI scripts have a nasty habit of leaving warning messages in	CGI scripts have a nasty habit of leaving warning messages in
logs that are neither time stamped nor fully identified.  Tra	logs that are neither time stamped nor fully identified.  Tra
the script that caused the error is a pain.  This fixes that.	the script that caused the error is a pain.  This fixes that.
the usual							the usual

    use Carp;							    use Carp;

with								with

    use CGI::Carp						    use CGI::Carp

And the standard warn(), die (), croak(), confess() and carp(	And the standard warn(), die (), croak(), confess() and carp(
will automagically be replaced with functions that write out 	will automagically be replaced with functions that write out 
time-stamped messages to the HTTP server error log.		time-stamped messages to the HTTP server error log.

For example:							For example:

   [Fri Nov 17 21:40:43 1995] test.pl: I'm confused at test.p	   [Fri Nov 17 21:40:43 1995] test.pl: I'm confused at test.p
   [Fri Nov 17 21:40:43 1995] test.pl: Got an error message: 	   [Fri Nov 17 21:40:43 1995] test.pl: Got an error message: 
   [Fri Nov 17 21:40:43 1995] test.pl: I'm dying.		   [Fri Nov 17 21:40:43 1995] test.pl: I'm dying.

=head1 REDIRECTING ERROR MESSAGES				=head1 REDIRECTING ERROR MESSAGES

By default, error messages are sent to STDERR.  Most HTTPD se	By default, error messages are sent to STDERR.  Most HTTPD se
direct STDERR to the server's error log.  Some applications m	direct STDERR to the server's error log.  Some applications m
to keep private error logs, distinct from the server's error 	to keep private error logs, distinct from the server's error 
they may wish to direct error messages to STDOUT so that the 	they may wish to direct error messages to STDOUT so that the 
will receive them.						will receive them.

The C<carpout()> function is provided for this purpose.  Sinc	The C<carpout()> function is provided for this purpose.  Sinc
carpout() is not exported by default, you must import it expl	carpout() is not exported by default, you must import it expl
saying								saying

   use CGI::Carp qw(carpout);					   use CGI::Carp qw(carpout);

The carpout() function requires one argument, which should be	The carpout() function requires one argument, which should be
reference to an open filehandle for writing errors.  It shoul	reference to an open filehandle for writing errors.  It shoul
called in a C<BEGIN> block at the top of the CGI application 	called in a C<BEGIN> block at the top of the CGI application 
compiler errors will be caught.  Example:			compiler errors will be caught.  Example:

   BEGIN {							   BEGIN {
     use CGI::Carp qw(carpout);					     use CGI::Carp qw(carpout);
     open(LOG, ">>/usr/local/cgi-logs/mycgi-log") or		     open(LOG, ">>/usr/local/cgi-logs/mycgi-log") or
       die("Unable to open mycgi-log: $!\n");			       die("Unable to open mycgi-log: $!\n");
     carpout(LOG);						     carpout(LOG);
   }								   }

carpout() does not handle file locking on the log for you at 	carpout() does not handle file locking on the log for you at 

The real STDERR is not closed -- it is moved to SAVEERR.  Som	The real STDERR is not closed -- it is moved to SAVEERR.  Som
servers, when dealing with CGI scripts, close their connectio	servers, when dealing with CGI scripts, close their connectio
browser when the script closes STDOUT and STDERR.  SAVEERR is	browser when the script closes STDOUT and STDERR.  SAVEERR is
prevent this from happening prematurely.			prevent this from happening prematurely.

You can pass filehandles to carpout() in a variety of ways.  	You can pass filehandles to carpout() in a variety of ways.  
way according to Tom Christiansen is to pass a reference to a	way according to Tom Christiansen is to pass a reference to a
GLOB:								GLOB:

    carpout(\*LOG);						    carpout(\*LOG);

This looks weird to mere mortals however, so the following sy	This looks weird to mere mortals however, so the following sy
accepted as well:						accepted as well:

    carpout(LOG);						    carpout(LOG);
    carpout(main::LOG);						    carpout(main::LOG);
    carpout(main'LOG);						    carpout(main'LOG);
    carpout(\LOG);						    carpout(\LOG);
    carpout(\'main::LOG');					    carpout(\'main::LOG');

    ... and so on						    ... and so on

FileHandle and other objects work as well.		      <
							      <
Use of carpout() is not great for performance, so it is recom	Use of carpout() is not great for performance, so it is recom
for debugging purposes or for moderate-use applications.  A f	for debugging purposes or for moderate-use applications.  A f
version of this module may delay redirecting STDERR until one	version of this module may delay redirecting STDERR until one
CGI::Carp methods is called to prevent the performance hit.	CGI::Carp methods is called to prevent the performance hit.

=head1 MAKING PERL ERRORS APPEAR IN THE BROWSER WINDOW		=head1 MAKING PERL ERRORS APPEAR IN THE BROWSER WINDOW

If you want to send fatal (die, confess) errors to the browse	If you want to send fatal (die, confess) errors to the browse
import the special "fatalsToBrowser" subroutine:		import the special "fatalsToBrowser" subroutine:

    use CGI::Carp qw(fatalsToBrowser);				    use CGI::Carp qw(fatalsToBrowser);
    die "Bad error here";					    die "Bad error here";

Fatal errors will now be echoed to the browser as well as to 	Fatal errors will now be echoed to the browser as well as to 
arranges to send a minimal HTTP header to the browser so that	arranges to send a minimal HTTP header to the browser so that
occur in the early compile phase will be seen.			occur in the early compile phase will be seen.
Nonfatal errors will still be directed to the log file only (	Nonfatal errors will still be directed to the log file only (
with carpout).							with carpout).

=head2 Changing the default message			      <
							      <
By default, the software error message is followed by a note  <
contact the Webmaster by e-mail with the time and date of the <
If this message is not to your liking, you can change it usin <
set_message() routine.  This is not imported by default; you  <
import it on the use() line:				      <
							      <
    use CGI::Carp qw(fatalsToBrowser set_message);	      <
    set_message("It's not a bug, it's a feature!");	      <
							      <
You may also pass in a code reference in order to create a cu <
error message.  At run time, your code will be called with th <
of the error message that caused the script to die.  Example: <
							      <
    use CGI::Carp qw(fatalsToBrowser set_message);	      <
    BEGIN {						      <
       sub handle_errors {				      <
          my $msg = shift;				      <
          print "<h1>Oh gosh</h1>";			      <
          print "Got an error: $msg";			      <
      }							      <
      set_message(\&handle_errors);			      <
    }							      <
							      <
In order to correctly intercept compile-time errors, you shou <
set_message() from within a BEGIN{} block.		      <
							      <
=head1 CHANGE LOG						=head1 CHANGE LOG

1.05 carpout() added and minor corrections by Marc Hedlund	1.05 carpout() added and minor corrections by Marc Hedlund
     <hedlund@best.com> on 11/26/95.				     <hedlund@best.com> on 11/26/95.

1.06 fatalsToBrowser() no longer aborts for fatal errors with	1.06 fatalsToBrowser() no longer aborts for fatal errors with
     eval() statements.						     eval() statements.

1.08 set_message() added and carpout() expanded to allow for  <
     objects.						      <
							      <
1.09 set_message() now allows users to pass a code REFERENCE  <
     really custom error messages.  croak and carp are now    <
     exported by default.  Thanks to Gunther Birznieks for th <
     patches.						      <
							      <
1.10 Patch from Chris Dean (ctdean@cogit.com) to allow 	      <
     module to run correctly under mod_perl.		      <
							      <
=head1 AUTHORS							=head1 AUTHORS

Lincoln D. Stein <lstein@genome.wi.mit.edu>.  Feel free to re	Lincoln D. Stein <lstein@genome.wi.mit.edu>.  Feel free to re
this under the Perl Artistic License.				this under the Perl Artistic License.


=head1 SEE ALSO							=head1 SEE ALSO

Carp, CGI::Base, CGI::BasePlus, CGI::Request, CGI::MiniSvr, C	Carp, CGI::Base, CGI::BasePlus, CGI::Request, CGI::MiniSvr, C
CGI::Response							CGI::Response

=cut								=cut

require 5.000;							require 5.000;
use Exporter;							use Exporter;
use Carp;							use Carp;

@ISA = qw(Exporter);						@ISA = qw(Exporter);
@EXPORT = qw(confess croak carp);				@EXPORT = qw(confess croak carp);
@EXPORT_OK = qw(carpout fatalsToBrowser wrap set_message);    |	@EXPORT_OK = qw(carpout fatalsToBrowser);

$main::SIG{__WARN__}=\&CGI::Carp::warn;				$main::SIG{__WARN__}=\&CGI::Carp::warn;
$main::SIG{__DIE__}=\&CGI::Carp::die;				$main::SIG{__DIE__}=\&CGI::Carp::die;
$CGI::Carp::VERSION = '1.10';				      |	$CGI::Carp::VERSION = '1.06';
$CGI::Carp::CUSTOM_MSG = undef;				      <

# fancy import routine detects and handles 'errorWrap' specia	# fancy import routine detects and handles 'errorWrap' specia
sub import {							sub import {
    my $pkg = shift;						    my $pkg = shift;
    my(%routines);						    my(%routines);
    grep($routines{$_}++,@_,@EXPORT);			      |	    grep($routines{$_}++,@_);
    $WRAP++ if $routines{'fatalsToBrowser'} || $routines{'wra |	    $WRAP++ if $routines{'fatalsToBrowser'};
    my($oldlevel) = $Exporter::ExportLevel;			    my($oldlevel) = $Exporter::ExportLevel;
    $Exporter::ExportLevel = 1;					    $Exporter::ExportLevel = 1;
    Exporter::import($pkg,keys %routines);			    Exporter::import($pkg,keys %routines);
    $Exporter::ExportLevel = $oldlevel;				    $Exporter::ExportLevel = $oldlevel;
}								}

# These are the originals					# These are the originals
sub realwarn { warn(@_); }					sub realwarn { warn(@_); }
sub realdie { die(@_); }					sub realdie { die(@_); }

sub id {							sub id {
    my $level = shift;						    my $level = shift;
    my($pack,$file,$line,$sub) = caller($level);		    my($pack,$file,$line,$sub) = caller($level);
    my($id) = $file=~m|([^/]+)$|;				    my($id) = $file=~m|([^/]+)$|;
    return ($file,$line,$id);					    return ($file,$line,$id);
}								}

sub stamp {							sub stamp {
    my $time = scalar(localtime);				    my $time = scalar(localtime);
    my $frame = 0;						    my $frame = 0;
    my ($id,$pack,$file);					    my ($id,$pack,$file);
    do {							    do {
	$id = $file;							$id = $file;
	($pack,$file) = caller($frame++);				($pack,$file) = caller($frame++);
    } until !$file;						    } until !$file;
    ($id) = $id=~m|([^/]+)$|;					    ($id) = $id=~m|([^/]+)$|;
    return "[$time] $id: ";					    return "[$time] $id: ";
}								}

sub warn {							sub warn {
    my $message = shift;					    my $message = shift;
    my($file,$line,$id) = id(1);				    my($file,$line,$id) = id(1);
    $message .= " at $file line $line.\n" unless $message=~/\	    $message .= " at $file line $line.\n" unless $message=~/\
    my $stamp = stamp;						    my $stamp = stamp;
    $message=~s/^/$stamp/gm;					    $message=~s/^/$stamp/gm;
    realwarn $message;						    realwarn $message;
}								}

# The mod_perl package Apache::Registry loads CGI programs by <
# eval.  These evals don't count when looking at the stack ba <
sub _longmess {						      <
    my $message = Carp::longmess();			      <
    my $mod_perl = ($ENV{'GATEWAY_INTERFACE'} 		      <
                    && $ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Per <
    $message =~ s,eval[^\n]+Apache/Registry\.pm.*,,s if $mod_ <
    return( $message );    				      <
}							      <
							      <
sub die {							sub die {
    my $message = shift;					    my $message = shift;
    my $time = scalar(localtime);				    my $time = scalar(localtime);
    my($file,$line,$id) = id(1);				    my($file,$line,$id) = id(1);
							      >	    return undef if $file=~/^\(eval/;
    $message .= " at $file line $line.\n" unless $message=~/\	    $message .= " at $file line $line.\n" unless $message=~/\
    &fatalsToBrowser($message) if $WRAP && _longmess() !~ /ev |	    &fatalsToBrowser($message) if $WRAP;
    my $stamp = stamp;						    my $stamp = stamp;
    $message=~s/^/$stamp/gm;					    $message=~s/^/$stamp/gm;
    realdie $message;						    realdie $message;
}								}

sub set_message {					      <
    $CGI::Carp::CUSTOM_MSG = shift;			      <
    return $CGI::Carp::CUSTOM_MSG;			      <
}							      <
							      <
# Avoid generating "subroutine redefined" warnings with the f	# Avoid generating "subroutine redefined" warnings with the f
# hack:								# hack:
{								{
    local $^W=0;						    local $^W=0;
    eval <<EOF;							    eval <<EOF;
sub confess { CGI::Carp::die Carp::longmess \@_; }		sub confess { CGI::Carp::die Carp::longmess \@_; }
sub croak { CGI::Carp::die Carp::shortmess \@_; }		sub croak { CGI::Carp::die Carp::shortmess \@_; }
sub carp { CGI::Carp::warn Carp::shortmess \@_; }		sub carp { CGI::Carp::warn Carp::shortmess \@_; }
EOF								EOF
    ;								    ;
}								}

# We have to be ready to accept a filehandle as a reference	# We have to be ready to accept a filehandle as a reference
# or a string.							# or a string.
sub carpout {							sub carpout {
    my($in) = @_;						    my($in) = @_;
    my($no) = fileno(to_filehandle($in));		      |	    $in = $$in if ref($in); # compatability with Marc's metho
    die "Invalid filehandle $in\n" unless defined $no;	      |	    my($no) = fileno($in);
							      >	    unless (defined($no)) {
							      >		my($package) = caller;
							      >		my($handle) = $in=~/[':]/ ? $in : "$package\:\:$in"; 
							      >		$no = fileno($handle);
							      >	    }
							      >	    die "Invalid filehandle $in\n" unless $no;
    								    
    open(SAVEERR, ">&STDERR");					    open(SAVEERR, ">&STDERR");
    open(STDERR, ">&$no") or 					    open(STDERR, ">&$no") or 
	( print SAVEERR "Unable to redirect STDERR: $!\n" and		( print SAVEERR "Unable to redirect STDERR: $!\n" and
}								}

# headers							# headers
sub fatalsToBrowser {						sub fatalsToBrowser {
    my($msg) = @_;						    my($msg) = @_;
    $msg=~s/>/&gt;/g;						    $msg=~s/>/&gt;/g;
    $msg=~s/</&lt;/g;						    $msg=~s/</&lt;/g;
    $msg=~s/&/&amp;/g;					      <
    $msg=~s/\"/&quot;/g;				      <
    my($wm) = $ENV{SERVER_ADMIN} ? 			      <
	qq[the webmaster (<a href="mailto:$ENV{SERVER_ADMIN}" <
	"this site's webmaster";			      <
    my ($outer_message) = <<END;			      <
For help, please send mail to $wm, giving this error message  <
and the time and date of the error.			      <
END							      <
    ;							      <
    print STDOUT "Content-type: text/html\n\n";			    print STDOUT "Content-type: text/html\n\n";
							      <
    if ($CUSTOM_MSG) {					      <
	if (ref($CUSTOM_MSG) eq 'CODE') {		      <
	    &$CUSTOM_MSG($msg); # nicer to perl 5.003 users   <
	    return;					      <
	} else {					      <
	    $outer_message = $CUSTOM_MSG;		      <
	}						      <
    }							      <
    							      <
    print STDOUT <<END;						    print STDOUT <<END;
<H1>Software error:</H1>					<H1>Software error:</H1>
<CODE>$msg</CODE>						<CODE>$msg</CODE>
<P>								<P>
$outer_message;						      |	Please send mail to this site's webmaster for help.
END								END
    ;							      <
}							      <
							      <
# Cut and paste from CGI.pm so that we don't have the overhea <
# always loading the entire CGI module.			      <
sub to_filehandle {					      <
    my $thingy = shift;					      <
    return undef unless $thingy;			      <
    return $thingy if UNIVERSAL::isa($thingy,'GLOB');	      <
    return $thingy if UNIVERSAL::isa($thingy,'FileHandle');   <
    if (!ref($thingy)) {				      <
	my $caller = 1;					      <
	while (my $package = caller($caller++)) {	      <
	    my($tmp) = $thingy=~/[\':]/ ? $thingy : "$package <
	    return $tmp if defined(fileno($tmp));	      <
	}						      <
    }							      <
    return undef;					      <
}								}

1;								1;
Only in CGI.pm-2.42/CGI: Cookie.pm
Only in CGI.pm-2.42/CGI: Fast.pm
Only in CGI-modules-2.76/CGI: Form.pm
Only in CGI-modules-2.76/CGI: MiniSvr.pm
Only in CGI.pm-2.42/CGI: Push.pm
Only in CGI-modules-2.76/CGI: Request.pm
Only in CGI.pm-2.42/CGI: Switch.pm
Only in CGI-modules-2.76/CGI: test.pl
Only in CGI.pm-2.42: CGI.man
diff --side-by-side --ignore-all-space --recursive CGI.pm-2.42/MANIFEST CGI-modules-2.76/MANIFEST
ANNOUNCE						      |	CGI/Base.pm
CGI.man							      |	CGI/BasePlus.pm
CGI.pm							      <
CGI/Carp.pm							CGI/Carp.pm
CGI/Fast.pm						      |	CGI/Form.pm
CGI/Push.pm						      |	CGI/MiniSvr.pm
CGI/Apache.pm						      |	CGI/Request.pm
CGI/Switch.pm						      |	CGI/test.pl
CGI/Cookie.pm						      <
MANIFEST						      <
Makefile.PL							Makefile.PL
							      >	MANIFEST
README								README
cgi-lib_porting.html					      |	doc/Base.pm.html
cgi_docs.html						      |	doc/BasePlus.pm.html
examples/WORLD_WRITABLE/18.157.1.253.sav		      |	doc/Carp.pm.html
examples/caution.xbm					      |	doc/Form.pm.html
examples/clickable_image.cgi				      |	doc/MiniSvr.pm.html
examples/cookie.cgi					      |	doc/Request.pm.html
examples/crash.cgi					      <
examples/customize.cgi					      <
examples/diff_upload.cgi				      <
examples/dna.small.gif					      <
examples/file_upload.cgi				      <
examples/frameset.cgi					      <
examples/index.html					      <
examples/internal_links.cgi				      <
examples/javascript.cgi					      <
examples/make_links.pl					      <
examples/monty.cgi					      <
examples/multiple_forms.cgi				      <
examples/nph-clock.cgi					      <
examples/nph-multipart.cgi				      <
examples/popup.cgi					      <
examples/save_state.cgi					      <
examples/tryit.cgi					      <
examples/wilogo.gif					      <
t/form.t						      <
t/function.t						      <
t/html.t						      <
t/request.t						      <
diff --side-by-side --ignore-all-space --recursive CGI.pm-2.42/Makefile.PL CGI-modules-2.76/Makefile.PL
use ExtUtils::MakeMaker;					use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influen <
# the contents of the Makefile that is written.		      <
WriteMakefile(							WriteMakefile(
    'INSTALLDIRS' => 'perl',				      |		NAME => "CGI",
    'NAME'	=> 'CGI',				      |		DISTNAME => "CGI-modules",
    'DISTNAME'  => 'CGI.pm',				      |		VERSION => "2.76",
    'VERSION_FROM'   => 'CGI.pm',			      |	        linkext => { LINKTYPE => '' },
    'linkext'   => { LINKTYPE=>'' },	# no link needed      |	        dist => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
    'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz', <
	            'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'}  <
);								);
diff --side-by-side --ignore-all-space --recursive CGI.pm-2.42/README CGI-modules-2.76/README
WHAT IS THIS?						      |	These are the CGI:: modules for perl5, for use in writing CGI
							      >	In addition to this package, you will also need the URI::Unes
							      >	class, which is part of the libwww-perl package.  It can be o
							      >	at any of the following CPAN archives:
							      >
							      >	      ftp://ftp.cis.ufl.edu/pub/perl/CPAN/ 
							      >	      ftp://ftp.cs.ruu.nl/pub/PERL/CPAN/ 
							      >	      ftp://ftp.delphi.com/pub/mirrors/packages/perl/CPAN/ 
							      >	      ftp://ftp.funet.fi/pub/languages/perl/CPAN/ 
							      >	      ftp://ftp.is.co.za/programming/perl/CPAN/ 
							      >	      ftp://ftp.pasteur.fr/pub/Perl/CPAN/ 
							      >	      ftp://ftp.sterling.com/programming/languages/perl/ 
							      >	      ftp://janus.sedl.org/pub/mirrors/CPAN/ 
							      >	      ftp://orpheu.ci.uminho.pt/pub/lang/perl/ 

This is CGI.pm 2.42, an easy-to-use Perl5 library for writing |	To install these modules, cd to the directory that this READM
Wide Web CGI scripts.					      |	in and type the following:

HOW DO I INSTALL IT?					      <
							      <
To install this module, cd to the directory that contains thi <
file and type the following:				      <
							      <
   perl Makefile.PL							perl Makefile.PL
   make									make
   make test						      <
   make install								make install

If this doesn't work for you, try:			      |	Documentation for these modules is part of the files themselv
							      |	the pod (Plain Old Documentation) format, and can be read usi
   cp CGI.pm /usr/local/lib/perl5			      |	pod2man and pod2html programs that come with perl5.001.  To c
							      >	them into manual page format, type something like the followi

If you have trouble installing CGI.pm because you have insuff |		pod2man Base.pm > Base.man
access privileges to add to the perl library directory, you c <
use CGI.pm.  See the docs for details.			      <

WHAT SYSTEMS DOES IT WORK WITH?				      |	To convert them into html format, type:

This module works with NT, Windows, Macintosh, OS/2 and VMS s |		pod2html *.pm
although it hasn't been tested as extensively as it should be <
the docs for notes on your particular platform.		      <

WHERE IS THE DOCUMENTATION?				      |	(pod2html automatically creates a file named *.pm.html)

You'll find very verbose documentation in the file cgi_docs.h |	For your convenience, html-ized documentation is already inst
located in the top level directory.  			      |	the doc/ subdirectory.

Terser documentation is found in POD (plain old documentation |	Online documentation of these modules as well as related modu
CGI.pm itself.  When you install CGI, the MakeMaker program w |	as the earlier CGI.pm module)  can be found at:
automatically install the manual pages for you (on Unix syste <
"man CGI").						      <

WHERE ARE THE EXAMPLES?					      |		http://www.genome.wi.mit.edu/ftp/pub/software/WWW/CGI

A collection of examples demonstrating various CGI features a |	Many examples of CGI scripts of various degrees of complexity
techniques are in the directory "examples".  Many more exampl |	found at:
scripts of various degrees of complexity can be found at:     <

   http://www.genome.wi.mit.edu/WWW/examples/Ch9/			http://www.genome.wi.mit.edu/WWW/examples/Ch9/

WHERE IS THE ONLINE DOCUMENTATION?			      |	NEW IN VERSION 2.76, April 5, 1997:
							      <
Online documentation of for CGI.pm, and notifications of new  <
can be found at:					      <
							      <
   http://www.genome.wi.mit.edu/ftp/pub/software/WWW/	      <

A copy of this documentation can be found in the package in t |	- Fixes for perl5.004.
cgi_docs.html.						      |	- File upload more reliable.

WHERE CAN I LEARN MORE?					      <
							      <
I have written a book about CGI.pm called "The Official Guide <
Programming with CGI.pm" which was published by John Wiley &  <
May 1998.  If you like CGI.pm, you'll love this book.	      <
							      <
Have fun, and let me know how it turns out!		      <
							      <
Lincoln D. Stein						Lincoln D. Stein
lstein@cshl.org						      |	lstein@genome.wi.mit.edu
							      <
Only in CGI.pm-2.42: cgi-lib_porting.html
Only in CGI.pm-2.42: cgi_docs.html
Only in CGI-modules-2.76: doc
Only in CGI.pm-2.42: examples
Only in CGI.pm-2.42: t
