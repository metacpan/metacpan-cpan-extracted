package oEdtk::tuiEdtk;

use strict;

BEGIN {
	use Exporter;
	use vars qw($VERSION @ISA @EXPORT);    # @EXPORT_OK %EXPORT_TAGS);
	use warnings;
	use Term::ReadKey;
	use oEdtk::trackEdtk qw(env_Var_Completion);

	$VERSION = 2.1126;
	@ISA     = qw(Exporter);
	@EXPORT  = qw(
		clear_Screen	start_Screen	stop_Screen
		admin_Screen 	not_Configured
	);

	#		@EXPORT_OK	= qw(
	#						)
}

sub clear_Screen() {
	my $command = "clear";    # default
	if ( $^O eq "MSWin32" ) {
		$command = "cls";
	}
	else {
		# TODO test...
		warn "INFO OS $^O, tuiEdtk::clear_Screen awaiting feedback\n";
	}

	system($command) == 0
		or warn "INFO OS $^O system command $command failed: $?";

	return 1;
}

sub admin_Screen {
	&clear_Screen();
	my $wait = 10 * $ENV{EDTK_WAITRUN};
	print STDOUT <<"EOF";

	oEtdk Simple Administration 
	______________________________________

Select Option 
	<I> show edtk init file
	<C> version control utility
	<D> deliveries				(planned)
	<Q> quit

Choose an option by typing associated letter
(wait ${wait}s or press any key to stop).
EOF

	my $key = &readKey_Wait($wait);
	$key ||= "";

	if ( $key =~ /i/i ) {
		&show_INIEDTK();
		&admin_Screen();

	}
	elsif ( $key =~ /c/i ) {
		print " -> Choice = $key\n";
		&VCS_Screen();

	}
	elsif ( $key =~ /d/i ) {
		print " -> Choice = $key\n";
		&delivery_Screen();

	}
	elsif ( $key =~ /a/i ) {
		print " -> Choice = $key\n";
	}

	warn "INFO: -END- \n";

	exit 1;
	1;
}

sub show_INIEDTK() {

	# determine the default editor based on HOSTNAME
	my $wait    = 10 * $ENV{EDTK_WAITRUN};
	my $iniedtk = $ENV{EDTK_INIEDTK};
	env_Var_Completion($iniedtk);

	my @args = ( "more", $iniedtk );
	eval { system(@args); };

	if ($?) {
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	&readKey_Wait($wait);
	1;
}

sub start_Screen() {
	&clear_Screen();

	print STDOUT <<"EOF";

	Application launcher $ENV{EDTK_PRGNAME}
	______________________________________
	
Auto start in $ENV{EDTK_WAITRUN}s, or press <enter>.
Parameters :
 application  $ENV{EDTK_PRGNAME}
 data         $ENV{EDTK_FDATAIN}.$ENV{EDTK_EXT_DATA}
 output       $ENV{EDTK_FDATAOUT}
 temp         $ENV{EDTK_DIR_APPTMP}

Options :
	<1> Run: $ENV{EDTK_PRGNAME}.$ENV{EDTK_EXT_PERL} 
	<A> Administration

To change an option, type its value or <enter> for the default.
EOF
	my $key = &readKey_Wait();
	$key ||= "";

	if ( $key =~ /a/i ) {
		&admin_Screen();
	}
	elsif ( $key =~ /\d+/ ) {
		print " -> Choice = run $ENV{EDTK_PRGNAME}\n";
	}

	print "\n";

	return 1;
}

sub stop_Screen () {
	print "\nPause, hit <enter> to exit or <w> to watch Doc result...\n";
	my $key = &readKey_Wait( $ENV{EDTK_WAITRUN} * 100 ) || "";
	my $arg = "$ENV{EDTK_FDATAOUT}." . $ENV{EDTK_EXT_DEFAULT};

	if ( $key =~ /W/i and $arg ) {

		env_Var_Completion($arg);

		warn "$arg...\n";
		eval { system($arg); };
	}
	else {

	}

	1;
}

sub readKey_Wait {
	my $key;
	my $wait_time = shift;
	$wait_time ||= $ENV{EDTK_WAITRUN};
	$wait_time ||= 1;

	ReadMode('raw');
	$key = ReadKey($wait_time);
	ReadMode('restore');

	return $key;
}

sub not_Configured() {
	my $wait = 10 * $ENV{EDTK_WAITRUN};

SCREEN: {
		print STDOUT <<"EOF";

	Function not configured 
	______________________________________

Repository	$ENV{EDTK_VCS_LOCATION}
Branch		$ENV{EDTK_DIR_BASE}
Application	$ENV{EDTK_PRGNAME}


	<Q> quit

EOF

		my $key = &readKey_Wait($wait);
		$key ||= "";
	}

	exit 1;
	1;
}

sub VCS_Screen {
	if ( $ENV{EDTK_VCS_LOCATION} eq "" ) { not_Configured(); }

	my $wait = 10 * $ENV{EDTK_WAITRUN};

SCREEN: {
		&clear_Screen();
		print STDOUT <<"EOF";

	Version Control 
	______________________________________

Repository	$ENV{EDTK_VCS_LOCATION}
Branch		$ENV{EDTK_DIR_BASE}

	<S> show branch log		(log)
	<A> add files into branch	(test - add)
	<C> commit branch changes	(commit)
	<T> send To repository		(push)
	<W> missing between branch/rep	(missing)
	<U> update local branch		(pull)
	<M> merge local branch		(merge)
	<F> build branch From repository(planned - branch)
	<L> build local VCS		(planned - init)

	<B> back	<Q> quit

Choose an option by typing associated letter.
EOF

		my $key = &readKey_Wait($wait);
		$key ||= "";

		#	print " -> Choice = $key\n";

		if ( $key =~ /S/i ) {
			&VCS_log();

		}
		elsif ( $key =~ /A/i ) {
			&VCS_add();

		}
		elsif ( $key =~ /C/i ) {
			&VCS_commit();

		}
		elsif ( $key =~ /U/i ) {
			&VCS_update();

		}
		elsif ( $key =~ /T/i ) {
			&VCS_to();

		}
		elsif ( $key =~ /W/i ) {
			&VCS_missing();

		}
		elsif ( $key =~ /M/i ) {
			&VCS_merge();
			&readKey_Wait();

		}
		elsif ( $key =~ /F/i ) {
			print "planned...";
		}
		elsif ( $key =~ /L/i ) {
			print "planned...";
		}
		elsif ( $key =~ /B/i ) {
			&admin_Screen();
		}
		elsif ( $key =~ /Q/i ) {
			&clear_Screen();
			exit 1;
		}

		redo SCREEN;
	}

	exit 1;
	1;
}

sub VCS_merge() {
	my $loc = $ENV{EDTK_DIR_BASE};
	env_Var_Completion($loc);
	chdir $loc;

	print "Merging... ";
	my @args = ( "bzr", "merge", $loc );

	eval { system(@args); };

	if ($?) {
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}
	1;
}

sub VCS_commit {
	my $comment = shift;
	$comment ||= "";

	# potential branch location problem if run outside the branch
	my $base = $ENV{EDTK_DIR_BASE};
	env_Var_Completion($base);
	chdir $base;

	my @args = ( "bzr", "commit" );
	if ( $comment ne "" ) { push( @args, "-m $comment" ); }

	eval { system(@args); };

	if ($?) {
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	#&VCS_merge();
	&readKey_Wait();
	1;
}

sub VCS_missing() {

	# potential branch location problem if run outside the branch
	my $other_branch = $ENV{EDTK_VCS_LOCATION};
	env_Var_Completion($other_branch);
	my $base = $ENV{EDTK_DIR_BASE};
	env_Var_Completion($base);
	chdir $base;

	my @args = ( "bzr", "missing", $other_branch );

	eval { system(@args); };

	if ($?) {
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	&readKey_Wait();
	1;
}

sub VCS_add() {
	my $wait = 10 * $ENV{EDTK_WAITRUN};

	# potential branch location problem if run outside the branch
	my $base = $ENV{EDTK_DIR_BASE};
	env_Var_Completion($base);
	chdir $base;

	my @args = ( "bzr", "add", "--dry-run" );

	eval { system(@args); };

	if ($?) {
		return $?;

	}
	else {
		print "Enter <Y>es if you confirm action (wait ${wait}s) :\n";
		my $key = &readKey_Wait($wait);
		$key ||= "";

		if ( $key =~ /y/i ) {
			print " -> bzr add confirmed\n";
		}
		else {
			print "Canceled\n";
			&readKey_Wait();
			return 0;
		}

		@args = ( "bzr", "add" );
		eval { system(@args); };

		if ($?) {
			return $?;
		}
		print "Screen refresh";
	}
	&readKey_Wait();
	1;
}

sub VCS_update() {

	#&VCS_merge();

	# potential branch location problem if run outside the branch
	my $base = $ENV{EDTK_DIR_BASE};
	env_Var_Completion($base);
	chdir $base;

	my @args = ( "bzr", "pull" );
	eval { system(@args); };

	if ($?) {
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	&readKey_Wait();
	1;
}

sub VCS_to() {
	&VCS_merge();

	my $cmd = "cd $ENV{EDTK_DIR_BASE}";
	env_Var_Completion($cmd);
	system($cmd);

	my $base = $ENV{EDTK_DIR_BASE};
	env_Var_Completion($base);
	chdir $base;

	my @args = ( "bzr", "push" );
	eval { system(@args); };

	if ($?) {
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	&readKey_Wait();
	1;
}

sub VCS_log() {
	my $loc = $ENV{EDTK_DIR_BASE};
	env_Var_Completion($loc);

	# TODO: select qlog or glog depending on the environment
	my @args = ( "bzr", "qlog", $loc );

	eval { system(@args); };

	if ($?) {
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	1;
}

sub VCS_rename() {
	my $wait = 10 * $ENV{EDTK_WAITRUN};

	my $base    = $ENV{EDTK_DIR_BASE};
	my $oldname = $ENV{EDTK_DIR_SCRIPT} . "\\" . $ENV{EDTK_PRGNAME};
	my $newname = $ENV{EDTK_DIR_SCRIPT} . "\\" . $ENV{EDTK_PRGNAME};
	my @extension;

	push( @extension, $ENV{EDTK_EXT_PERL} );
	push( @extension, $ENV{EDTK_EXT_LATEX} );

	env_Var_Completion($oldname);
	env_Var_Completion($newname);
	env_Var_Completion($base);
	chdir $base;

	foreach my $ext (@extension) {
		my @args = ( "bzr", "move", "$oldname.$ext", "$newname.$ext", "--quiet" );
		eval { system(@args); };

		if ($?) {
			return $?;
		}
	}
	&readKey_Wait();
	1;
}

sub delivery_Screen {
	if ( $ENV{EDTK_PRGNAME} eq "" or $ENV{EDTK_DIR_BASE} eq "" ) { not_Configured(); }

	my $wait = 10 * $ENV{EDTK_WAITRUN};

SCREEN: {
		&clear_Screen();
		print STDOUT <<"EOF";

Deliveries 
______________________________________

Repository	$ENV{EDTK_VCS_LOCATION}
Branch		$ENV{EDTK_DIR_BASE}
Application	$ENV{EDTK_PRGNAME}


<A> moving from development to tests for Approval : 
	from $ENV{EDTK_PRGNAME} to $ENV{EDTK_PRGNAME}

<P> delivering approved applications to Production : (planned)
	from $ENV{EDTK_PRGNAME} to $ENV{EDTK_PRGNAME}

<B> back	<Q> quit

Choose an option by typing associated letter.
EOF

		my $key = &readKey_Wait($wait);
		$key ||= "";

		if ( $key =~ /A/i ) {
			&VCS_rename();
			&VCS_commit("move $ENV{EDTK_PRGNAME} to $ENV{EDTK_PRGNAME}");

		}
		elsif ( $key =~ /P/i ) {
			print "planned...";

			#&VCS_commit();

		}
		elsif ( $key =~ /B/i ) {
			&admin_Screen();
		}
		elsif ( $key =~ /Q/i ) {
			&clear_Screen();
			exit 1;
		}

		redo SCREEN;
	}

	exit 1;
	1;
}

END { }
1;

# THIS COMMENTING METHOD IS INTERESTING BUT POLLUTES POD

# =begin comment

# http://perl.enstimac.fr/DocFr/perldiag.html

# http://perl.enstimac.fr/DocFr/perlfaq8.html
# How to read a key without waiting for a press on ``enter'' ?

# 	use HotKey;
# 	$key = readkey();

# Use the diagnostics pragma which turns normal Perl error messages into a longer discussion of the subject.
# 	use diagnostics;

#   BEGIN {
#     $SIG{__WARN__} = sub{ print STDERR "Perl: ", @_; };
#     $SIG{__DIE__}  = sub{ print STDERR "Perl: ", @_; exit 1};
#   }

# How to manage my own modules/libraries directory?
# When building modules, use the PREFIX and LIB options at the Makefile generation step:
#     perl Makefile.PL PREFIX=/mydir/perl LIB=/mydir/perl/lib

# then either set the PERL5LIB environment variable before running the scripts that use these modules/libraries (see the perlrun man page), or use:
#    use lib '/mydir/perl/lib';
#
# if the directory is not known in advance...
#    use FindBin qw($Bin);
#    use lib "$Bin/myPm";

# =end comment

#perl -d:ptkdb

=head1 NAME

oEdtk::tuiEdtk - simple terminal screens for the oEdtk launcher

=head1 SYNOPSIS

    use oEdtk::tuiEdtk;

    start_Screen();
    # ... run the application ...
    stop_Screen();

=head1 DESCRIPTION

Draws the simple terminal screens of the oEdtk command-line launcher: the start
screen, the administration menu and the exit pause. The screens are driven by the
C<EDTK_*> environment variables; key reads go through C<Term::ReadKey> and path
expansion through L<oEdtk::trackEdtk>.

=head1 FUNCTIONS

=head2 clear_Screen

    clear_Screen();

Clear the terminal with C<clear> on Unix or C<cls> on Windows.

=head2 start_Screen

    start_Screen();

Display the application launcher and read the user's choice.

=head2 stop_Screen

    stop_Screen();

Pause at the end of a run and, on request, open the produced document.

=head2 admin_Screen

    admin_Screen();

Display the simple administration menu and dispatch to the chosen action.

=head2 not_Configured

    not_Configured();

Display the "function not configured" screen and exit.

The following subs are internal helpers and are not part of the public API:
C<show_INIEDTK>, C<readKey_Wait>, C<delivery_Screen>, and the version-control
helpers C<VCS_Screen>, C<VCS_merge>, C<VCS_commit>, C<VCS_missing>, C<VCS_add>,
C<VCS_update>, C<VCS_to>, C<VCS_log> and C<VCS_rename>.

=head1 AUTHOR

The oEdtk team.

=cut
