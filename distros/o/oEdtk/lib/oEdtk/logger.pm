package oEdtk::logger;

BEGIN {
		use Exporter   ();
		use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK);

		$VERSION     =1.0323;
		@ISA         = qw(Exporter);
		@EXPORT      = qw(logger);
		@EXPORT_OK   = qw($LOGGERLEVEL);

		use POSIX qw(strftime);
	}

	$LOGGERLEVEL =4;

	sub logger($$;$){
		# APPEL : &logger($messLevel, $logMess[, $modificateur]);
		# pour logger les erreurs bloquantes tout en utilisant la méthode die :
		# open (IN, "<$nomfichier") or die &logger($NOK, "impossible d'ouvrir <$nomfichier>");
	
		# LOGGERLEVEL definit la sensibilite de la log (attention : l\'option verbose peut le modifier)
		# 8-> Debug complet, 7-> Information, 6-> Contexte, 5-> Suivi, 4-> Warning, \$NOK-> Erreur
		# $. est le numero de ligne courant sur le filehandle courant
		# $! valeur courante errno
		# $0 nom du script perl
	
		my ($messLevel, $logMess, $modificateur) =@_;
		my $fileHandle	=0;
		my $FD=$!;
		$FD =~s/(Bad)\s(file\sdescriptor)/$1 or No $2/io;
		$modificateur	||=0;   # valeur  par defaut
		$logMess		||="";
		$LOGGERLEVEL	+=$modificateur;
	
		if ($messLevel <= $LOGGERLEVEL) {
			$fileHandle	+=$. if $.;
			my $now =strftime "%Y-%m-%d %H:%M:%S", localtime; # %j quantieme ?
			print STDERR "\> $now | $messLevel |$FD| $logMess | FH-$fileHandle | PID-$$ ";
			print STDERR "| PRG-$0" if ($messLevel <=5);
			print STDERR "\n";
		}
	
	return $logMess, "\n";
	}

END {}
return 1;
