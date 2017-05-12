# -*-Perl-*-
#	$Id: Makefile.PL,v 1.15 2010/03/28 08:15:42 mpeppler Exp $
require 5.002;
use ExtUtils::MakeMaker;
use Config;

use strict;

require './util/config.pl';

my $sattr = &config();
my $written_pwd_file = 'PWD';

configPwd();

my $linktype = defined($$sattr{LINKTYPE}) ? $$sattr{LINKTYPE} : 'dynamic';

#if($Config{lns}) {
#    system("cd CTlib; $Config{lns} ../pod/sybperl.pod CTlib.pod") if(!-e 'CTlib/CTlib.pod');
#    system("cd DBlib; $Config{lns} ../pod/sybperl.pod DBlib.pod") if(!-e 'DBlib/DBlib.pod');
#}
    


foreach (@INC) {
    next if(/site_perl/);
    next if(/blib/);
    if(-d "$_/Sybase") {
	warn <<"MSG_EOF";
*** WARNING ***
An installed copy of the Sybase modules found in $_
This can cause a version conflict as this version installs in
    $Config{installprivlib}/site_perl
which comes later in Perl $]'s include directory list.

You may need to manually remove these older Sybase directories if
sybperl $sattr->{VERSION} does not run correctly.

One way to do so would be to run the following command
    mv $_/Sybase $_/Sybase.old

MSG_EOF
#'	
    }
}

WriteMakefile('DISTNAME' => "sybperl",
	      'NAME' => 'Sybase',
	      'VERSION' => $$sattr{VERSION},
	      'dist' => {'TARFLAGS' => "cvf", 'COMPRESS' => "gzip"},
	      'clean' => { FILES => $written_pwd_file },
	      'LINKTYPE' => $linktype,
	      'XSPROTOARG' => '-prototypes',
	      ($] >= 5.005 ?
	       (ABSTRACT   => 'Sybase API modules',
		AUTHOR     => 'Michael Peppler (mpeppler@peppler.org)') : ()),
	      ($] >= 5.005 && $^O eq 'MSWin32' && 
	       $Config{archname} =~ /-object\b/i ? (CAPI => 'TRUE') :()),
              'MAN3PODS' => { 'pod/sybperl.pod' => 'blib/man3/sybperl.3' }
	      );



sub MY::libscan
{
    my($self, $path) = @_;
    return '' if $path =~ m:/SCCS|CVS|RCS|.svn/:;
    $path;
}

sub configPwd {
    open(IN, "PWD.factory") || die "Can't open PWD.factory: $!";
    my %pwd;
    while(<IN>) {
	chomp;
	next if(/^\s*\#/);
	next if(/^\s*$/);
	my ($key, $val) = split(/=/, $_);
	$pwd{$key} = $val || "undef";
    }
    close(IN);
    select(STDOUT); $| = 1;

    print "The sybperl modules need access to a Sybase server to run the tests.\n";
    print "To clear an entry please enter 'undef'\n";
    print "Sybase server to use (default: $pwd{SRV}): ";
    $pwd{SRV} = getAns(0) || $pwd{SRV};
    print "User ID to log in to Sybase (default: $pwd{UID}): ";
    $pwd{UID} = getAns(0) || $pwd{UID};
    print "Password (default: $pwd{PWD}): ";
    $pwd{PWD} = getAns(1) || $pwd{PWD};
    print "Sybase database to use on $pwd{SRV} (default: $pwd{DB}): ";
    $pwd{DB} = getAns(0) || $pwd{DB};

    warn "\n* Writing login information, including password, to file $written_pwd_file.\n\n";
    # Create the file non-readable by anyone else.
    my $old_umask;
    unless($^O =~ /MSWin32/) {
	$old_umask = umask(077);
	warn "cannot umask(): $!" unless defined($old_umask);
    }
    open(OUT, ">$written_pwd_file") || die "Can't open $written_pwd_file: $!";
    unless($^O =~ /MSWin32/) {
	umask($old_umask) != 077 && warn "strange return from umask()";
    }
    print OUT <<EOF;
# This file contains optional login id, passwd and server info for the test
# programs:
# You probably don't want to have it lying around after you've made
# sure that everything works OK.

EOF
    foreach (keys %pwd) {
	$pwd{$_} = '' if $pwd{$_} eq 'undef';
	print OUT "$_=$pwd{$_}\n";
    }
    close(OUT);
}

sub getAns {
    my $flag = shift;

    if($flag && -t) {
	eval {
	    require Term::ReadKey;
	    Term::ReadKey::ReadMode('noecho');
	};
    }
    my $ans = <STDIN>;
    if($flag && -t) {
	eval {
	    Term::ReadKey::ReadMode('normal');	# reset terminal
	};
    }
    $ans =~ s/^\s+//;
    $ans =~ s/\s+$//;

    return $ans;
}

    
