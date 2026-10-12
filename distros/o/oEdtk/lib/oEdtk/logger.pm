package oEdtk::logger;

BEGIN {
		use Exporter   ();
		use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK); #backward compatibility for Perls under 5.6 

		$VERSION     =2.1109;
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
		# CALL: &logger($messLevel, $logMess[, $MODIFY]);
		# CALL: &logger($messLevel, $logMess[, 2]); # increase LOGGERLEVEL
		# CALL: &logger($messLevel, $logMess[, Warn]); # set LOGGERLEVEL to Warn

		# to log blocking errors while using the die method:
		# open (IN, "<$nomfichier") or die &logger($NOK, "unable to open <$nomfichier>");
	
		# LOGGERLEVEL defines the log sensitivity (note: the MODIFY option can change it)
		# 8-> Debug (all), 7-> Information, 6-> Context, 5-> Follow, 4-> Warning, \$NOK-> Error
		# $. is the current line number on the current filehandle
		# $! current errno value
		# $0 perl script name

		my ($messLevel, $logMess, $MODIFY) =@_;
		my $fileHandle	=0;
		#my $FD=$!;
		#$FD =~s/(Bad)\s(file\sdescriptor)/$1 or No $2/io;
		$MODIFY	//=0;   # default value, from 5.10 //= replaces ||= 
		$logMess//="";
		chomp ($logMess);
		my $now =strftime "%Y-%m-%d %H:%M:%S", localtime; # %j day of year?

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
