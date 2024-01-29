package oEdtk::logger;

BEGIN {
		use Exporter   ();
		use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK); #backward compatibility for Perls under 5.6 

		$VERSION     =1.6051;
		@ISA         = qw(Exporter);
		@EXPORT      = qw(logger);
		@EXPORT_OK   = qw($LOGGERLEVEL $WARN2LOGGER);

		use strict;
		use warnings;
		use Data::Dumper qw(Dumper);
		use POSIX qw(strftime);
	}


	$LOGGERLEVEL =4; # default log level
	$WARN2LOGGER =0; # by default do not turn warn messsages to logger

	my %hLEVEL = ( U => 8, D => 7, I => 6, P => 5, W => 4, A => 3, C => 0, E => -1);
	my %hLABEL = ( 8 => '8-USER-', 7 => '7-DEBUG', 6 => '6-INFO-' , 5 => '5-PARSE' , 4 => '4-WARN-' , 3 => '3-ALERT' , 2 => '2-ALERT' , 1 => '1-ALERT' , 0 => '0-CRITC' , -1 => '-1 ERROR');

	sub logger($$;$){
		# APPEL : &logger($messLevel, $logMess[, $MODIFY]);
		# APPEL : &logger($messLevel, $logMess[, 2]); # increase LOGGERLEVEL
		# APPEL : &logger($messLevel, $logMess[, Warn]); # set LOGGERLEVEL to Warn

		# pour logger les erreurs bloquantes tout en utilisant la méthode die :
		# open (IN, "<$nomfichier") or die &logger($NOK, "impossible d'ouvrir <$nomfichier>");
	
		# LOGGERLEVEL definit la sensibilite de la log (attention : l\'option MODIFY peut le modifier)
		# 8-> Debug (all), 7-> Information, 6-> Context, 5-> Suivi/Follow, 4-> Warning, \$NOK-> Error
		# $. est le numero de ligne courant sur le filehandle courant
		# $! valeur courante errno
		# $0 nom du script perl

		my ($messLevel, $logMess, $MODIFY) =@_;
		my $fileHandle	=0;
		#my $FD=$!;
		#$FD =~s/(Bad)\s(file\sdescriptor)/$1 or No $2/io;
		$MODIFY	//=0;   # valeur  par defaut, à partir de la 5.10 //= remplace ||= 
		$logMess//="";
		chomp ($logMess);
		my $now =strftime "%Y-%m-%d %H:%M:%S", localtime; # %j quantieme ?

		#warn  "LOGGER - MODIFY $MODIFY - @{[%hLEVEL]} => Dump : ". Dumper \%hLEVEL;
		# PID :
		# cat /proc/sys/kernel/pid_max
		# The default value for this file, 32768, results in the same range of PIDs as on earlier kernels. On 32-bit platforms, 32768 is the maximum value for pid_max. On 64-bit systems, pid_max can be set to any value up to 2^22 (PID_MAX_LIMIT, approximately 4 million)
		# alias sys_guid='sudo /sbin/blkid | grep "$(df -h / | sed -n 2p | cut -d" " -f1):" | grep -o "UUID=\"[^\"]*\" " | sed "s/UUID=\"//;s/\"//"'
		
		if ($MODIFY =~m/^\-{0,1}[1-4]$/ ) {
			$LOGGERLEVEL +=$MODIFY;
			print STDERR " \>$now|$hLABEL{6}|PID-$$| LOGGERLEVEL set to $hLABEL{$LOGGERLEVEL}|FH-$fileHandle \n";

		} elsif ($MODIFY =~m/^([UDIPW])/) {
				$LOGGERLEVEL = $hLEVEL{$1};
				print STDERR " \>$now|$hLABEL{6}|PID-$$| LOGGERLEVEL set to $hLABEL{$LOGGERLEVEL} ($MODIFY)|FH-$fileHandle \n";

#		} elsif ($MODIFY !~m/\d/ && $MODIFY !~m/^([UDIPW])/) {
		} elsif ($MODIFY !~m/^([0UDIPW])/) {
				print STDERR " \>$now|$hLABEL{6}|PID-$$| logger - unknown modificator ($MODIFY)|FH-$fileHandle \n";
				print STDERR " \>$now|$hLABEL{6}|PID-$$| logger - use : 8 => '8-USER-', 7 => '7-DEBUG', 6 => '6-INFO-' , 5 => '5-PARSE' , 4 => '4-WARN-' , 3/1 => '3-ALERT',  0 => '0-CRITC' , -1 => '-1 ERROR' |$FD|FH-$fileHandle \n";
		}

		$fileHandle	+=$. if $.;
		my $loggerMessage = " \>$now|$hLABEL{$messLevel}|PID-$$| $logMess|FH-$fileHandle";
		$loggerMessage .= "|PRG $0" if ($messLevel <=5);
		$loggerMessage =~ s/\s+/ /g;

		if ($messLevel <= 4) {
			warn "$loggerMessage\n";
		} elsif ($messLevel <= $LOGGERLEVEL) {
			print STDERR "$loggerMessage\n";
		}
	
	return $loggerMessage, "\n";
	}

END {}
return 1;
