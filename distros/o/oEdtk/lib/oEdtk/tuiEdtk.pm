package oEdtk::tuiEdtk ;

BEGIN {
		use Exporter;
		use vars 				qw($VERSION @ISA @EXPORT); # @EXPORT_OK %EXPORT_TAGS);
		use strict;
		use warnings;
		use Term::ReadKey;
		use oEdtk::trackEdtk	qw(env_Var_Completion);

		$VERSION		= 0.0032;
		@ISA			= qw(Exporter);
		@EXPORT		= qw(
						clear_Screen	start_Screen	stop_Screen
						admin_Screen 	not_Configured
						);
#		@EXPORT_OK	= qw(
#						)
	}


sub clear_Screen(){
	my $command="clear"; # par défaut
	if ($^O eq "MSWin32"){
		$command="cls";
	} else {
		# tester...
		warn "INFO OS $^O, tuiEdtk::clear_Screen en attente retour d'expérience\n";
	}

	system($command) == 0
         or warn "INFO OS $^O system command $command failed: $?";

return 1;
}

sub admin_Screen {
	&clear_Screen();
	my $wait =10*$ENV{EDTK_WAITRUN};
	print STDOUT << "EOF";

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

	my $key =&readKey_Wait($wait);
	$key ||="";

	if 		($key =~/i/i) {
		&show_INIEDTK();
		&admin_Screen();

	} elsif	($key =~/c/i) {
		print " -> Choice = $key\n";
		&VCS_Screen();

	} elsif	($key =~/d/i) {
		print " -> Choice = $key\n";
		&delivery_Screen();

	} elsif	($key =~/a/i) {
		print " -> Choice = $key\n";
	}

	warn "INFO : -END- \n";

exit 1;	
1;
}

sub show_INIEDTK() {
	# en fonction de HOSTNAME déterminer l'éditeur par défaut
	my $wait =10*$ENV{EDTK_WAITRUN};
	my $iniedtk=$ENV{EDTK_INIEDTK};
	env_Var_Completion($iniedtk);

	my @args	=("more", $iniedtk);
	eval {
		system(@args);
	};

	if ($?){
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	&readKey_Wait($wait);
1;
}


sub start_Screen(){
 	&clear_Screen();

	print STDOUT << "EOF";

	Lanceur application $ENV{EDTK_PRGNAME}
	______________________________________
	
Lancement auto dans $ENV{EDTK_WAITRUN}s, ou taper <enter>.
Parametres :
 application  $ENV{EDTK_PRGNAME}
 data         $ENV{EDTK_FDATAIN}.$ENV{EDTK_EXT_DATA}
 output       $ENV{EDTK_FDATAOUT}
 temp         $ENV{EDTK_DIR_APPTMP}

Options :
	<1> Run: $ENV{EDTK_PRGNAME}.$ENV{EDTK_EXT_PERL} 
	<A> Administration

Pour modifier une option, taper sa valeur ou <enter> par defaut.
EOF
	my $key =&readKey_Wait();
	$key ||="";

	if 	($key  =~/a/i) {
		&admin_Screen();
	} elsif	($key =~/\d+/) {
		print " -> Choice = run $ENV{EDTK_PRGNAME}\n";
	}

print "\n";

return 1;
}

sub stop_Screen (){
	print "\nPause, hit <enter> to exit or <w> to watch Doc result...\n";
	my $key =&readKey_Wait($ENV{EDTK_WAITRUN}*100) || "";
	my $arg ="$ENV{EDTK_FDATAOUT}.".$ENV{EDTK_EXT_DEFAULT};

	if	($key =~/W/i and $arg) {

		env_Var_Completion($arg);

		warn "$arg...\n";
		eval {
			system($arg);
		};
	} else {
	
	}	
		
1;
}

sub readKey_Wait(;$){
	my $key;
	my $wait_time=shift;
	$wait_time ||=$ENV{EDTK_WAITRUN};
	$wait_time ||=1;

	ReadMode('raw');
	$key = ReadKey($wait_time);
	ReadMode ('restore');

return $key;
}

sub not_Configured() {
	my $wait =10*$ENV{EDTK_WAITRUN};

SCREEN: {
	print STDOUT << "EOF";

	Function not configured 
	______________________________________

Repository	$ENV{EDTK_VCS_LOCATION}
Branch		$ENV{EDTK_DIR_BASE}
Application	$ENV{EDTK_PRGNAME}


	<Q> quit

EOF

	my $key =&readKey_Wait($wait);
	$key ||="";
}

exit 1;	
1;
}


sub VCS_Screen {
	if ($ENV{EDTK_VCS_LOCATION} eq "") {not_Configured();}

	my $wait =10*$ENV{EDTK_WAITRUN};
	
SCREEN: {
	&clear_Screen();
	print STDOUT << "EOF";

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

	my $key =&readKey_Wait($wait);
	$key ||="";
#	print " -> Choice = $key\n";
	
	if		($key =~/S/i) {
		&VCS_log();

	} elsif	($key =~/A/i) {
		&VCS_add();

	} elsif 	($key =~/C/i) {
		&VCS_commit();

	} elsif	($key =~/U/i) {
		&VCS_update();

	} elsif	($key =~/T/i) {
		&VCS_to();

	} elsif	($key =~/W/i) {
		&VCS_missing();

	} elsif	($key =~/M/i) {
		&VCS_merge();
		&readKey_Wait();

	} elsif	($key =~/F/i) {
		print "planned...";
	} elsif	($key =~/L/i) {
		print "planned...";
	} elsif	($key =~/B/i) {
		&admin_Screen();
	} elsif	($key =~/Q/i) {
		&clear_Screen();
		exit 1;
	}

redo SCREEN; }

exit 1;	
1;
}


sub VCS_merge() {
	my $loc	=$ENV{EDTK_DIR_BASE};
	env_Var_Completion($loc);
	chdir $loc;

	print "Merging... ";
	my @args	=("bzr", "merge", $loc);

	eval {
		system(@args);
	};

	if ($?){
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}
1;
}

sub VCS_commit(;$) {
	my $comment=shift;
	$comment||="";
	
	# potentiellement problème de localisation de la branch, si execution en dehors de la branche
	my $base	=$ENV{EDTK_DIR_BASE};
	env_Var_Completion($base);
	chdir $base;

	my @args	=("bzr", "commit");
	if ($comment ne "") { push (@args, "-m $comment");}

	eval {
		system(@args);
	};

	if ($?){
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	#&VCS_merge();
	&readKey_Wait();
1;
}

sub VCS_missing() {
	# potentiellement problème de localisation de la branch, si execution en dehors de la branche
	my $other_branch	=$ENV{EDTK_VCS_LOCATION};
	env_Var_Completion($other_branch);
	my $base			=$ENV{EDTK_DIR_BASE};
	env_Var_Completion($base);
	chdir $base;

	my @args	=("bzr", "missing", $other_branch);

	eval {
		system(@args);
	};

	if ($?){
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	&readKey_Wait();
1;
}


sub VCS_add() {
	my $wait =10*$ENV{EDTK_WAITRUN};

	# potentiellement problème de localisation de la branch, si execution en dehors de la branche
	my $base	=$ENV{EDTK_DIR_BASE};
	env_Var_Completion($base);
	chdir $base;

	my @args	=("bzr", "add", "--dry-run");

	eval {
		system(@args);
	};

	if ($?){
		return $?;

	} else {
		print "Enter <Y>es if you confirm action (wait ${wait}s) :\n";
		my $key =&readKey_Wait($wait);
		$key ||="";
	
		if 		($key =~/y/i) {
			print " -> bzr add confirmed\n";
		} else {
			print "Canceled\n";
			&readKey_Wait();
			return 0;
		}
		
		@args	=("bzr", "add");	
		eval {
			system(@args);
		};
	
		if ($?){
			return $?;
		}
		print "Screen refresh";
	}
	&readKey_Wait();
1;
}


sub VCS_update() {
	#&VCS_merge();

	# potentiellement problème de localisation de la branch, si execution en dehors de la branche
	my $base	=$ENV{EDTK_DIR_BASE};
	env_Var_Completion($base);
	chdir $base;

	my @args	=("bzr", "pull");
	eval {
		system(@args);
	};

	if ($?){
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	&readKey_Wait();
1;
}

sub VCS_to() {
	&VCS_merge();

	my $cmd	="cd $ENV{EDTK_DIR_BASE}";
	env_Var_Completion($cmd);
	system($cmd);

	my $base	=$ENV{EDTK_DIR_BASE};
	env_Var_Completion($base);
	chdir $base;

	my @args	=("bzr", "push");
	eval {
		system(@args);
	};

	if ($?){
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

	&readKey_Wait();
1;
}


sub VCS_log() {
	my $loc	=$ENV{EDTK_DIR_BASE};
	env_Var_Completion($loc);
	
	# à faire : sélectionner qlog ou glog en fonction de l'environnement
	my @args	=("bzr", "qlog", $loc);

	eval {
		system(@args);
	};

	if ($?){
		print "Screen refresh";
		&readKey_Wait();
		return $?;
	}

sub VCS_rename() {
	my $wait =10*$ENV{EDTK_WAITRUN};

	my $base	=$ENV{EDTK_DIR_BASE};
	my $oldname=$ENV{EDTK_DIR_SCRIPT}."\\".$ENV{EDTK_PRGNAME};
	my $newname=$ENV{EDTK_DIR_SCRIPT}."\\".$ENV{EDTK_PRGNAME};
	my @extension;
	
	push (@extension, $ENV{EDTK_EXT_PERL});
	push (@extension, $ENV{EDTK_EXT_COMSET});
	push (@extension, $ENV{EDTK_EXT_LATEX});

	env_Var_Completion($oldname);
	env_Var_Completion($newname);
	env_Var_Completion($base);
	chdir $base;

	foreach my $ext (@extension) {
		my @args	=("bzr", "move", "$oldname.$ext", "$newname.$ext", "--quiet");	
		eval {
			system(@args);
		};

		if ($?){
			return $?;
		}
	}
	&readKey_Wait();
1;
}


sub delivery_Screen {
	if ($ENV{EDTK_PRGNAME} eq "" or $ENV{EDTK_DIR_BASE} eq "") {not_Configured();}

	my $wait =10*$ENV{EDTK_WAITRUN};

SCREEN: {
	&clear_Screen();
	print STDOUT << "EOF";

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

	my $key =&readKey_Wait($wait);
	$key ||="";
	
	if		($key =~/A/i) {
		&VCS_rename();
		&VCS_commit ("move $ENV{EDTK_PRGNAME} to $ENV{EDTK_PRGNAME}");

	} elsif	($key =~/P/i) {
		print "planned...";
		#&VCS_commit();

	} elsif	($key =~/B/i) {
		&admin_Screen();
	} elsif	($key =~/Q/i) {
		&clear_Screen();
		exit 1;
	}

redo SCREEN; }

exit 1;	
1;
}

1;
}


END {}
1;

# CETTE MÉTHODE DE COMMENTAIRE EST INTERESSANTE MAIS POLLUE POD

# =begin comment

# http://perl.enstimac.fr/DocFr/perldiag.html

# http://perl.enstimac.fr/DocFr/perlfaq8.html
# Comment lire simplement une touche sans attendre un appui sur ``entrée'' ?

# 	use HotKey;
# 	$key = readkey();

# Utilisez la directive diagnostics qui transforme les messages d'erreurs normaux de perl en un discours un peu plus long sur le sujet.
# 	use diagnostics;

#   BEGIN {
#     $SIG{__WARN__} = sub{ print STDERR "Perl: ", @_; };
#     $SIG{__DIE__}  = sub{ print STDERR "Perl: ", @_; exit 1};
#   }



# Comment gérer mon propre répertoire de modules/bibliothèques ?
# Lorsque vous fabriquez les modules, utilisez les options PREFIX et LIB à la phase de génération de Makefiles :
#     perl Makefile.PL PREFIX=/mydir/perl LIB=/mydir/perl/lib

# puis, ou bien positionnez la variable d'environnement PERL5LIB avant de lancer les scripts utilisant ces modules/bibliothèques (voir la page de manuel perlrun), ou bien utilisez :
#    use lib '/mydir/perl/lib';

# =end comment


#perl -d:ptkdb