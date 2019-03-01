package Win32::Backup::Robocopy;

use 5.014;
use strict;
use warnings;
use Time::Piece;
use Carp;
use File::Spec;
use File::Path qw(make_path);
use JSON::PP; # only this support sort_by(custom_func)
use Capture::Tiny qw(capture);
use Algorithm::Cron;

our $VERSION = 15;

sub new {
	my $class = shift;
	my %arg = _default_new_params( @_ );
	# conf  config configuration aliases
	$arg{conf}//= $arg{config} // $arg{configuration};	
	# JOB mode: it just check for a configuration
	# parameter passed in and returns.
	# the $bkp object will be a mere container of jobs
	if ( $arg{conf} ){
			$arg{conf} = File::Spec->file_name_is_absolute( $arg{conf} ) ?
				$arg{conf} 									:
				File::Spec->rel2abs( $arg{conf} ) ;
			my $jobs = _load_conf( $arg{conf} );
			return bless {
				conf 		=> $arg{conf} ,
				jobs 		=> $jobs // [],
				verbose 	=> $arg{verbose},
			}, $class;	
	}
	# RUN mode: the $bkp object will contains a serie
	# of defaults used by $bkp->run invocations
	%arg = _verify_args(%arg);
	return bless {
				name 		=> $arg{name},
				src			=> $arg{src},
				dst 		=> $arg{dst},
				history 	=> $arg{history} // 0,
				verbose 	=> $arg{verbose} // 0,
				waitdrive	=> $arg{waitdrive} // 0,
	}, $class;
}

sub run	{
	my $self = shift;
	my %opt = _default_run_params(@_);
	# explicit verbose passed overwrite the $bkp object property
	local $self->{verbose} = $opt{verbose} if exists $opt{verbose};
	# leave if we are running under JOB mode
	if ( $self->{jobs} and ref $self->{jobs} eq 'ARRAY' ){
		croak "No direct run invocation permitted while running in JOB mode!\n".
				"Perahps you intended to call runjobs?\n".
				"See the docs of ".__PACKAGE__." about different modes of instantiation\n";
		return undef;
	}
	# we are in RUN mode: continue..
	my $src = $self->{src};
	my $dst = File::Spec->file_name_is_absolute( $self->{dst} ) ?
				$self->{dst}									:
				File::Spec->rel2abs( $self->{dst} ) ;
	$dst = File::Spec->catdir( $dst, $self->{name} );
	# modify destination if history = 1
	my $date_folder;
	if ( $self->{history} ){
		# is now an object from Time::Piece
		my $tnow = localtime; 
		$date_folder = join 'T', $tnow->ymd, $tnow->hms('-');
		$dst =  File::Spec->catdir( $dst, $date_folder );		
	}
	# some verbose output
	if ( $self->{verbose} ){
		print "backup SRC: [$src]\n",
				"backup DST: [$dst]\n"
	}
	# check the directories structure
	make_path( $dst, { 
						verbose => $self->{verbose},
						error => \my $filepatherror
	} );
	# Note that if no errors are encountered, $err will reference an empty array. 
	# This means that $err will always end up TRUE; so you need to test @$err to 
	# determine if errors occurred. (File::Path doc(s|et))
	# croak if errors, but check them twice:
	if (@$filepatherror){
		# dump first error received by File::Path
		carp "Folder creation errors: ".( join ' ', each %{$$filepatherror[0]} );
		# check if the, possibly remote, drive is present
		my @dirs = File::Spec->splitdir( $dst );
		unless ( -d $dirs[0] ){
			if ( $self->{waitdrive} ){
					$self->_waitdrive( $dirs[0] );
					return;
			}
			else { croak ("destination drive $dirs[0] is not accessible!") }
		}
		croak "Error in directory creation!"
	}
	# extra parameters to pass to robocopy 
	my @extra =  ref $opt{extraparam} eq 'ARRAY' 	?
					@{ $opt{extraparam} }			:
					split /\s+/, $opt{extraparam} // ''	;	
	my @cmdargs = grep { defined $_ } 
						# parameters managed by new
						$src, $dst,
						# parameters managed by run
						$opt{files},
						( $opt{subfolders} ? '/S' : undef ),
						( $opt{emptysubfolders} ? '/E' : undef ),
						( $opt{archive} ? '/A' : undef ),
						( $opt{archiveremove} ? '/M' : undef ),
						( $opt{retries} ? "/R:$opt{retries}" : "/R:0" ),
						( $opt{wait} ? "/W:$opt{wait}" : "/W:0" ),
						# extra parameters for robocopy
						@extra;
	my ($stdout, $stderr, $exit, $exitstr) = $self->_wrap_robocpy( @cmdargs );
	# verbosity
	if ( $self->{verbose} ){
		print "STDOUT: $stdout\n" if $self->{verbose} > 1;
		print "STDERR: $stderr\n" if $self->{verbose} > 1;
		print "EXIT  : $exit\n"   if $self->{verbose} > 1;
		print "robocopy.exe exit description: $exitstr\n";		
	}
	return $stdout, $stderr, $exit, $exitstr, $date_folder;
}

sub job {
	my $self = shift;
	# check if we are running under the correct JOB mode
	unless ( $self->{ jobs } and ref $self->{ jobs } eq 'ARRAY'){
		croak "No job invocation permitted while running in RUN mode!\n".
				"See the docs of ".__PACKAGE__." about different modes of instantiation\n";
		return undef;
	}
	# use defaults as for run method if not specified otherwise
	my %opt = _verify_args(@_);
	%opt = _default_new_params( %opt );	
	%opt = _default_run_params( %opt );
	# explicit verbose passed overwrite the $bkp object property
	local $self->{verbose} = $opt{verbose} if exists $opt{verbose};
	# intialize first_time_run to 0
	$opt{ first_time_run } //= 0;
	# delete entries that must only be set internally
	delete $opt{ next_time };
	delete $opt{ next_time_descr };
	# check the cron option to be present
	croak "job method needs a crontab like string!" unless $opt{ cron };
	# get the cron onject
	my $cron = _get_cron( $opt{ cron } );		
	my $jobconf =
	# a job configuration is an hash of parameters..
		{
			# ..made of backup object parameters..
			( map{ $_ => $self->{$_} }qw(name src dst history) ),
			# ..and other parameters passed in via @_
			# and checked for defaults as we do for run method..
			%opt
		}      
	;
	# ..and the cron scheduling
	# depending if first_time_run is set..
	if ( $$jobconf{ first_time_run } ){
					$$jobconf{ next_time } = 0;
					$$jobconf{ first_time_run } = 0;
					$$jobconf{ next_time_descr } = '--AS SOON AS POSSIBLE--';
	}
	# or not
	else{ 
			$$jobconf{ next_time } = $cron->next_time(time);

			# using CORE::localtime because of Time::Piece
			# "This module replaces the standard localtime and gmtime functions with
			# implementations that return objects."
			# And in this way they cannot be serialized in JSON
			$$jobconf{ next_time_descr } = scalar CORE::localtime($cron->next_time(time));	
	}	
	# JSON for the job 
	my $json = JSON::PP->new->utf8->pretty->canonical;
	$json->canonical(1);
	$json->sort_by( \&_ordered_json );
	push @{ $self->{jobs} }, $jobconf;
	# verbosity
	if ( $self->{verbose} > 2 ){
		print "added the following job:\n";
		print $json->encode( $jobconf );
	}
	# clean the main object of other (now unwanted) properties
	$self->_write_conf;
	map{ delete $self->{$_} }qw( name src dst history verbose );
}

sub runjobs{
	my $self = shift;
	# check if we are running under the correct JOB mode
	unless ( $self->{ jobs } and ref $self->{ jobs } eq 'ARRAY'){
		croak "No runjob invocation permitted with empty queue nor while running in RUN mode!\n".
				"See the docs of ".__PACKAGE__." about different modes of instantiation\n";
		return undef;
	}
	# accept a range instead of all jobs
	my $range = ( @_ ? (join ',',@_) : undef) // join '..',0,$#{ $self->{ jobs }};
	my @range = _validrange( $range );
	foreach my $job( @{ $self->{ jobs } }[@range] ){
		local $self->{verbose} = $job->{ verbose } if exists $job->{ verbose };
		if ( $self->{ verbose } ){
			print "considering job [$job->{ name }]\n";
		}
		if ( time > $job->{ next_time } ){
			print "executing job [$job->{ name }]\n";
			# create a bkp object using values from the job
			# no need to use new because it's check will append
			# 'name' to destination a second time
			# and all parameters are already validated
			my $bkp = bless{
				name 		=> $job->{name},
				src			=> $job->{src},
				dst 		=> $job->{dst},
				history 	=> $job->{history} // 0,
				verbose 	=> $job->{verbose} // 0,
				waitdrive	=> $job->{waitdrive} // 0,
			},ref $self;
			
			$bkp->run( 
				archive => $job->{archive},
                archiveremove => $job->{archiveremove},
				subfolders => $job->{subfolders},
				emptysubfolders => $job->{emptysubfolders},
				files => $job->{files},			
			);
			# updating next_time* in the job
			my $cron = _get_cron( $job->{ cron } );
			$job->{ next_time } = $cron->next_time(time);
			
			# using CORE::localtime because of Time::Piece
			# "This module replaces the standard localtime and gmtime functions with
			# implementations that return objects."
			# And in this way they cannot be serialized in JSON
			$job->{ next_time_descr } = scalar CORE::localtime($cron->next_time(time));
			# write configuration
			$self->_write_conf;
		}
		# job not to be executed
		else {
			print "is not time to execute [$job->{ name }] (next time will be $job->{ next_time_descr })\n" if $self->{ verbose } or $job->{ verbose };
		}
	}	
}

sub listjobs{
	my $self = shift;
	my %arg = @_;
	$arg{format} //= 'compact';
	$arg{fields} //= [qw( name src dst files history cron next_time next_time_descr
							first_time_run archive archiveremove subfolders emptysubfolders
							retries wait
							 waitdrive verbose )];
							
	unless ( wantarray ){ return scalar @{$self->{jobs}} }
	my @res;
	my $count = 0;
	my $long = 1 if $arg{format} eq 'long';
	
	foreach my $job ( @{$self->{jobs}} ){
	
		push @res,  ( $long ? "JOB $count:\n" : '').
					join ' ',map{ 
									($long ? "\t" : '').
									"$_ = $job->{$_}".
									($long ? "\n" : '')
					
					} @{$arg{fields}};
	$count++;	
	}
	return @res;
}

sub restore{
	my $self = shift;
	my %arg = _default_restore_params(@_);
	for ( 'from', 'to' ){
		croak "restore need a $_ param!" unless $arg{$_};
	}
	map { $_ =  File::Spec->file_name_is_absolute( $_ ) ?
				$_ 										:
				File::Spec->rel2abs( $_ ) ;
	} $arg{from}, $arg{to};
	# checks against deep recursion
	_is_safe( $arg{from}, $arg{to} );
	# check source directory
	croak "'from' parameter points to a non existing directory!" unless -d $arg{from};
	# check and create destination directory
	make_path( $arg{to} ) unless -d $arg{to};
	# check verbose to be a number
	if ( exists $arg{verbose} and $arg{verbose} =~ /\D/ ){
		croak "'verbose' parameter must be a number";
	}
	# explicit verbose passed overwrite the $bkp object property
	local $self->{verbose} = $arg{verbose} if exists $arg{verbose};
	# check the upto parameter
	if ( $arg{upto} ){
			$arg{upto} = _validate_upto( $arg{upto} );
	}
	# check the extraparam parameter
	my @extra =  ref $arg{extraparam} eq 'ARRAY' 	?
					@{ $arg{extraparam} }			:
					split /\s+/, $arg{extraparam} // ''	;
	my @robo_params = grep { defined $_ } 
						# parameters as in run
						$arg{files},
						( $arg{subfolders} ? '/S' : undef ),
						( $arg{emptysubfolders} ? '/E' : undef ),
						( $arg{archive} ? '/A' : undef ),
						( $arg{archiveremove} ? '/M' : undef ),
						( $arg{retries} ? "/R:$arg{retries}" : "/R:0" ),
						( $arg{wait} ? "/W:$arg{wait}" : "/W:0" ),
						# extra parameters for robocopy
						@extra;
	# build parameters to ROBOCOPY using some default and extraparam
	# check if it is a restore from a history backup
	opendir my $dirh, $arg{from} or croak "unable to open dir [$arg{from}] to read";
	my $is_history = 1;
	my @time_dirs;
	while (my $it = readdir($dirh) ){
		next if $it =~/^\.\.?$/;
		if ( 	-d File::Spec->catdir($arg{from},$it) 
				and 
				$it =~/^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}$/ ){			
			push @time_dirs, $it;
		}
		else{
			$is_history = 0;
			undef @time_dirs;
			last;		
		}
	}
	close $dirh;
	# to hold return value:
	# $ret will be an anonymous array with an entry for each operation done
	# represented as anonymous hash with fields: stdout, stderr, exit and exitstring
	# [
	#   	# operation 0
	#   { stdout => $stdout, stderr => $stderr, exit => $exit, exitstr => $exitstr}
	#   	# operation 1
	#   { stdout => $stdout, stderr => $stderr, exit => $exit, exitstr => $exitstr}
	#   	# operation 2..
	# ]
	my $ret = [];
	# HISTORY restore
	if ( $is_history ){
		print "retore type: HISTORY\n" if $self->{verbose};
		foreach my $src (sort @time_dirs){
			# check if directory name exceeds 'upto' param
			if ( $arg{upto} ){
				(my $sanitized_src = $src ) =~ s/T(\d{2})[\-:](\d{2})[\-:](\d{2})$/T$1:$2:$3/; 
				my $current = Time::Piece->strptime ($sanitized_src, '%Y-%m-%dT%H:%M:%S')->epoch;
				if ( $current > $arg{upto} ){
				print "[$src] and following folders skipped because newer than: ".
							(scalar gmtime( $arg{upto} ))."\n" if $self->{verbose};
					last;
				}
			}
			$src = File::Spec->catdir($arg{from},$src);
			print "restoring from [$src]\n" if $arg{verbose};
			my @cmdargs = ( $src, $arg{to}, @robo_params );
			my ($stdout, $stderr, $exit, $exitstr) = $self->_wrap_robocpy( @cmdargs );
			# verbosity
			if ( $self->{verbose} > 1 ){
				print "STDOUT: $stdout\n" if $self->{verbose} > 1;
				print "STDERR: $stderr\n" if $self->{verbose} > 1;
				print "EXIT  : $exit\n"   if $self->{verbose} > 1;
				print "robocopy.exe exit description: $exitstr\n";		
			}
			push @$ret, {
						stdout => $stdout, stderr => $stderr,
						exit => $exit, exitstr => $exitstr
			};		
		}		
	}
	# NORMAL (non history) restore
	else{
		my @cmdargs = ( $arg{from}, $arg{to}, @robo_params );
		my ($stdout, $stderr, $exit, $exitstr) = $self->_wrap_robocpy( @cmdargs );
		# verbosity
		if ( $self->{verbose} > 1 ){
			print "STDOUT: $stdout\n" if $self->{verbose} > 1;
			print "STDERR: $stderr\n" if $self->{verbose} > 1;
			print "EXIT  : $exit\n"   if $self->{verbose} > 1;
			print "robocopy.exe exit description: $exitstr\n";		
		}
		push @$ret, {
						stdout => $stdout, stderr => $stderr,
						exit => $exit, exitstr => $exitstr
					};		
	}
	return $ret;
}
##################################################################
# not public subs
##################################################################

sub _wrap_robocpy{
	my $self = shift;
	my @cmdargs = @_;
	# set safest parameters always!!
	# /256 : Turn off very long path (> 256 characters) support
	# this is very risky if unset and can lead to deep directory
	# structure that the user cannot delete anymore.
	# /NP : No Progress - don’t display % copied.
	my @safest = qw( /256 /NP );
	# if ENV PERL_ROBOCOPY_EXE  is set PERL_ROBOCOPY_EXE will be used
	my $robocopy = 'robocopy.exe';
	if ( $ENV{PERL_ROBOCOPY_EXE} ){
		if (-e -s $ENV{PERL_ROBOCOPY_EXE} ){
			$robocopy = $ENV{PERL_ROBOCOPY_EXE};
		}
		else{
			carp "ENV var PERL_ROBOCOPY_EXE points to [$ENV{PERL_ROBOCOPY_EXE}] ",
				"but the program was not found or is empty!";
		}
	}
	# verbosity
	if ( $self->{verbose} ){
		print "executing [$robocopy ",(join ' ', @cmdargs, @safest),"]\n";
	}
	my ($stdout, $stderr, $exit) = capture {
		system( $robocopy, @cmdargs, @safest );
	};
	# !!
	$exit = $exit>>8;
	my $exitstr = _robocopy_exitstring($exit);
	return $stdout, $stderr, $exit, $exitstr;	
}

sub _validate_upto{
	my $time = shift;
	unless (  	
					# a time from epoch
					$time =~ /^\d+$/  				or
					# a valid string
					$time =~ /^\d{4}-\d{2}-\d{2}T\d{2}[\-:]\d{2}[\-:]\d{2}$/ or
					# a DateTime::Tiny object
					ref $time eq 'DateTime::Tiny' 	or
					# a DateTime object
					ref $time eq 'DateTime'				
			){
				croak "parameter 'upto' must be: seconds since epoch or a ".
						"string in the form: YYYY-MM-DDTHH-MM-SS or ".
						"a DateTime::Tiny object or a DateTime object!";
	}
	# it is a time string of seconds since epoch, let's hope..
	if ( $time =~ /^\d+$/ ){
		return $time;
	}
	# it is a string similar to ISO 8601 
	# but possible '-' instead of ':' between hours, minutes and seconds
	elsif ( $time =~ /^\d{4}-\d{2}-\d{2}T\d{2}[\-:]\d{2}[\-:]\d{2}$/ ){
		$time =~ s/T(\d{2})[\-:](\d{2})[\-:](\d{2})$/T$1:$2:$3/;
		return Time::Piece->strptime ($time, '%Y-%m-%dT%H:%M:%S')->epoch;		
	}
	# is a DateTime::Tiny object
	elsif ( ref $time eq 'DateTime::Tiny' ){
		return $time->DateTime->epoch;
	}
	# is a DateTime object
	elsif ( ref $time eq 'DateTime' ){
		return $time->epoch;
	}
	# uch!
	else { croak "Error in 'upto' parameter conversion to epoch!"}
}
sub _robocopy_exitstring{
	my $exit = shift;
	#$exit = $exit>>8;
	my %exit_code = (
		0   =>  'No errors occurred, and no copying was done. '.
				'The source and destination directory trees are completely synchronized.',
		1   =>  'One or more files were copied successfully (that is, new files have arrived).',
		2   =>  'Some Extra files or directories were detected. No files were copied. '.
				'Examine the output log for details.',
		4   =>  'Some Mismatched files or directories were detected. '.
				'Examine the output log. Housekeeping might be required.',
		8   =>  'Some files or directories could not be copied '.
				'(copy errors occurred and the retry limit was exceeded). '.
				'Check these errors further.',
		16  =>  'Serious error. Robocopy did not copy any files. '.
				'Either a usage error or an error due to insufficient access privileges '.
				'on the source or destination directories.'
	);
	my $exitstr = '';
	foreach my $code(sort {$a<=>$b} keys %exit_code){
		if ( $exit == 0){
			$exitstr .= $exit_code{0};
			last;
		}
		$exitstr .= ' '.$exit_code{$code} if ($exit & $code);
	}
	return $exitstr;	
}
sub _validrange {
	my $range = shift;
	$range =~ s/\s//g;
	my @range;
	# allowed only . , \d \s
	croak 'invalid range ['.$range.'] (allowed only [\s.,\d])!' if $range =~ /[^\s,.\d]/;
	# not allowed a lone .
	croak 'invalid range ['.$range.'] (single .)!' if $range =~ /(?<!\.)\.(?!\.)/;
	# not allowed more than 2 .
	croak 'invalid range ['.$range.'] (more than 2 .)!' if $range =~ /\.{3}/;
	# $1 > $2 like in 25..7
	 if ($range =~ /[^.]\.\.[^.]/){
		foreach my $match ( $range=~/(\d+\.\.\d+)/g ){
			$match=~/(\d+)\.\.(\d+)/;
			croak "$1 > $2 in range [$range]" if $1 > $2;
		}
	}
	@range = eval ($range);
	my %single = map{ $_ => 1} @range;
	@range = sort{ $a <=> $b } keys %single;
	#print "RANGE:@range\n";
	return @range;
}
sub _waitdrive{
	my $self = shift;
	my $drive = shift;
	print 	"\nBackup of:     $self->{src}\n".
			"To:              $self->{dst}\n".
			"Waiting for drive $drive to be available..\n".
			"(press ENTER when $drive is connected or CTRL-C to terminate the program)\n";
	my $input = <STDIN>;
	$self->run();
}
sub _load_conf{ 
	my $file = shift;
	return [] unless -e -r -f $file;
	# READ the configuration 
	my $json = JSON::PP->new->utf8->pretty->canonical;
	open my $fh, '<', $file or croak "unable to read $file";
	my $lines;
	{
		local $/ = '';
		$lines = <$fh>;
	}
	close $fh or croak "impossible to close $file";
	my $data;
	{ 
		local $@;
		eval { $data = $json->decode( $lines ) };
		croak "malformed json in $file!\nJSON error:\n[$@]\n" if $@;
	}
	croak "not an ARRAY ref retrieved from $file as conteainer for jobs! wrong configuration" 
			unless ref $data eq 'ARRAY';
	my @check = qw( name src dst files history cron next_time next_time_descr first_time_run archive
				archiveremove subfolders emptysubfolders verbose waitdrive wait retries);
	my $count = 1;
	foreach my $job ( @$data ){
		croak "not a HASH ref retrieved from $file for job $count! wrong configuration" 
			unless ref $job eq 'HASH';
		map { 
				croak "field [$_] not present in the job $count retrieved from $file" 
				unless exists $job->{ $_ } 
		} @check;
		carp "unexpected elements in job $count  retrieved from $file" if keys %$job > @check;
		$count++;
	}
	return $data;
}
sub _write_conf{
	my $self = shift;
	my $json = JSON::PP->new->utf8->pretty->canonical;
	$json->sort_by( \&_ordered_json );
	# verbosity
	if ( $self->{ verbose } and -e $self->{ conf } ){
		print "overwriting configuration file $self->{ conf }\n";
	}
	open my $fh, '>', $self->{ conf } 
			or croak "unable to write configuration to [$self->{ conf }]";
	print $fh $json->encode( $self->{ jobs } );
	close $fh or croak "unable to close configuration file [$self->{ conf }]";
	# verbosity
	if ( $self->{verbose} > 2 ){
		print "resulting configuration:\n";
		print $json->encode(  $self->{ jobs } );
	}
	# verbosity
	print "wrote configuration file $self->{ conf }\n" if $self->{ verbose };
}
sub _get_cron{
	my $crontab = shift;
	my $cron;
	# a safe scope for $@ 
	{  
		local $@;
		eval { 
				$cron = Algorithm::Cron->new(
												base => 'local',
												crontab => $crontab 
											)
		} or croak "specify a valid cron entry as cron parameter!\n".
					"\tAlgorithm::Cron error is: $@";			
	} 
	# end of safe scope for $@	
	return $cron;
}
sub _ordered_json{
	my %order = (
									# USED IN:
			name 			=> 0, 	# new
			src				=> 1, 	# new
			dst				=> 2, 	# new
			files			=> 3, 	# run
			history			=> 4, 	# new
			
			cron			=> 5, 	# job
			next_time		=> 6, 	# job RO
			next_time_descr	=> 7, 	# job RO
			first_time_run	=> 8, 	# job
			
			archive			=> 9, 	# run
			archiveremove	=> 10,	# run
			subfolders		=> 11,	# run
			emptysubfolders	=> 12,	# run
			
			retries  		=> 13,	# run
			wait 			=> 14,	# run			
			waitdrive 		=> 15,	# new
			verbose			=> 16,	# new
	);
	($order{$JSON::PP::a} // 99) <=> ($order{$JSON::PP::b} // 99)
}
sub _default_new_params{
	my %opt = @_;
	$opt{history} //= 0;
	$opt{verbose} //= 0;
	$opt{waitdrive} //= 0;
	return %opt;
}
sub _default_run_params{
	my %opt = @_;
	# process received options
	# file options
	$opt{files} //= '*.*',	
	# source options
	# /S : Copy Subfolders.
	$opt{subfolders} //= 1;
	# /E : Copy Subfolders, including Empty Subfolders.
	$opt{emptysubfolders} //= 1;
	# /A : Copy only files with the Archive attribute set.
	$opt{archive} //= 0;
	# /M : like /A, but remove Archive attribute from source files.
	$opt{archiveremove} //= 1;
	# /R:n : Number of Retries on failed copies - default is 1 million. 
	$opt{retries} //= 0;
	#  /W:n : Wait time between retries - default is 30 seconds.
	$opt{wait} //= 0;
	return %opt;
}
sub _default_restore_params{
	my %opt = @_;
	# process received options
	# file options
	$opt{files} //= '*.*',	
	# source options
	# /S : Copy Subfolders.
	$opt{subfolders} //= 1;
	# /E : Copy Subfolders, including Empty Subfolders.
	$opt{emptysubfolders} //= 1;
	# /A : Copy only files with the Archive attribute set.
	$opt{archive} //= 0;
	# /M : like /A, but remove Archive attribute from source files.
	# THIS IS THE ONLY DIFFERENCE WITH _default_run_params
	# IE ARCHIVE BIT IS NOT LOOKED FOR NOR REMOVED
	$opt{archiveremove} //= 0;
	# /R:n : Number of Retries on failed copies - default is 1 million. 
	$opt{retries} //= 0;
	#  /W:n : Wait time between retries - default is 30 seconds.
	$opt{wait} //= 0;
	return %opt;
}
sub _verify_args{
	my %arg = @_;
	croak "backup need a name!" unless $arg{name};
	$arg{src} //= $arg{source};
	croak "backup need a source!" unless $arg{src};
	$arg{dst} //= $arg{destination} // '.';
	map { $_ =  File::Spec->rel2abs( $_ ) } $arg{src}, $arg{dst};
	carp "backup source [$arg{src}] does not exists!".
			"(this is only a warning)" unless -d $arg{src};
	# checks against deep recursion
	_is_safe( $arg{src}, $arg{dst} );
	return %arg;	
}

sub _is_safe{
	my( $src, $dst ) = @_;
	# these checks are here to prevent deep recursive copy
	# possibly leading to unrecoverable directory structure
	# this is enforced even if the /256 switch is added to
	# every robocopy call.
	# GIVEN:
	# E:\
	# └───path
	#		  conf.txt
    #	
	# GOOD BUT INUTILE:
	# robocopy.exe E:\path E:\path *.* /E /NP /W:0  /R:0 /256
	# gives:
	# E:\
	# └───path
	#		  conf.txt
	#
	# NOT SO GOOD:
	# 1) robocopy.exe E:\path E:\path\BKP *.* /E /NP /W:0  /R:0
	# gives:
	# E:\
	# └───path
	#	  │   conf.txt
	#	  │
	#	  └───BKP
	#		  │   conf.txt
	#		  │
	#		  └───BKP
	#			  conf.txt
	#
	# BAD (DEEP RECURSION)
	# 1) robocopy.exe E:\path E:\path\BKP\ANOTHER_LEVEL *.* /E /NP /W:0  /R:0 /256
	# 2) robocopy.exe E:\path E:\path\BKP\ANOTHER_LEVEL\____AND_ANOTHER *.* /E /NP /W:0  /R:0 /256
	if ( $dst =~ /^\Q$src\E$/i ){
		carp "SRC and DST are equal! This might be not what you intended."
	}
	elsif ( $dst =~ /^\Q$src\E./i ){
		croak "DST [$dst] is under SRC [$src]!\n".
				"this is will lead to a recursive copy of of SRC, or at least ".
				"to an unexpected or unwanted directory structure."
	}
	else{ return }	
}
1;

__DATA__

=head1 NAME

Win32::Backup::Robocopy - a simple backup solution using robocopy

=cut

=head1 SYNOPSIS

    use Win32::Backup::Robocopy;

    # RUN mode 
    my $bkp = Win32::Backup::Robocopy->new(
            name 	=> 'my_perl_archive',       # mandatory       
            source	=> 'c:\scripts',            # mandatory
            destination	=> 'x:\backup',         # '.' if not specified
            history	=> 1,                         
    );
    my( $stdout, $stderr, $exit, $exitstr, $createdfolder ) = $bkp->run();

	
    # JOB mode 
    my $bkp = Win32::Backup::Robocopy->new( configuration => './backup_conf.json' );
    $bkp->job( 	
                name => 'my_backup_name',         # mandatory          
                src  =>'./a_folder',              # mandatory
                dst  => 'y:/',                    # '.' if not specified				
                history => 1,			
                cron => '0 0 25 12 *',            # mandatory             
                first_time_run => 1,                
    );
    $bkp->runjobs;     



=head1 DESCRIPTION

This module is a wrapper around C<robocopy.exe> and try to make it's behaviour as simple as possible
using a serie of sane defaults while letting you the possibility to leverage the C<robocopy.exe>
invocation in your own way.

The module offers two modes of being used: the RUN mode and the JOB mode. In the RUN mode a backup object created via C<new> is a_folder
single backup intended to be run using the C<run> method. In the JOB mode the object is a container of scheduled jobs filled reading
a JSON configuration file and/or using the C<job> method. C<runjobs> is then used to cycle the job list and see if some job has to be run.

In the RUN mode, if not C<history> is specified as true, the  backup object (using the C<run> method) will copy all files to one folder, named
as the name of the backup (the mandatory C<name> parameter used while creating the object). All successive
invocation of the backup will write into the same destination folder.

    # RUN mode with all files to the same folder
    use Win32::Backup::Robocopy;

    my $bkp = Win32::Backup::Robocopy->new(
            name 	=> 'my_perl_archive',       # mandatory
            source	=> 'x:\scripts'             # mandatory
    );
	
    my( $stdout, $stderr, $exit, $exitstr ) = $bkp->run();
	
If you instead specify the C<history> parameter as true during construction, then inside the main 
destination folder ( always named using the C<name> ) there will be one folder for each run of the backup
named using a timestamp like C<2022-04-12T09-02-36> 

    # RUN mode with history folders in destination
    my $bkp = Win32::Backup::Robocopy->new(
            name 	=> 'my_perl_archive',       # mandatory
            source	=> 'x:\scripts',            # mandatory
            history	=> 1                        # optional
    );
	
    my( $stdout, $stderr, $exit, $exitstr, $createdfolder ) = $bkp->run();

The second mode is the JOB one. In this mode you must only specify a C<config> parameter during the object instantiation. You can
add different jobs to the queue or load them from a configuration file. Configuration file is read and written in JSON.
Then you just call C<runjobs> method to process them all.
The JOB mode adds the possibility of scheduling jobs using C<crontab> like strings (using L<Algorithm::Cron> under the hoods). 


    # JOB mode - loading jobs from configuration file

    my $bkp = Win32::Backup::Robocopy->new( configuration => './my_conf.json' ); # mandatory configuration file

    $bkp->runjobs;
	
You can add jobs to the queue using the C<job> method. This method will accepts all parameters and assumes all defaults of the C<new> method in the RUN mode and of the C<run> method of the RUN mode. 
In addition the C<job> method wants a crontab like entry to have the job run only when needed. You can also specify C<first_time_run> to 1 to have the job run a first time without checking the cron scheduling, ie at the first invocation of C<runjobs>

    # JOB mode - adding  jobs 
	
    my $bkp = Win32::Backup::Robocopy->new( configuration => './my_conf.json' ); # mandatory configuration file
    

    $bkp->job( 	
                name=>'my_backup_name',         # mandatory as per new
                src=>'./a_folder',              # mandatory as per new
                history=>1,                     # optional as per new
				
                cron=>'0 0 25 12 *',            # job specific, mandatory
                first_time_run=>1               # job specific, optional
    );

    # add more jobs..
	
    $bkp->runjobs;              


	
	
=head2 IMPORTANT: used executable and robocopy.exe used defaults

This module needs a valid copy of C<robocopy.exe> to be present in the system and to be available in the C<PATH>

Alternatively a full path of an alternate copy of the C<robocopy.exe> executable can be specified using the C<ENV> variable C<PERL_ROBOCOPY_EXE> and in this case it will be given precedence over the copy present in the system.

Unfortunately C<robocopy.exe> was distributed over the years in many different versions and with doubious version numbers. Notably version C<5.1.2600.26> named C<XP026> is bugged: it returns a success errorlevel even when it fails.

Because of the above the current module will try to spot the position and the version of C<robocopy.exe> and the build of the module will fail if no version are found or a bugged version is the only available.


The C<robocopy.exe> program is full of options. This module is aimed to facilitate the backup task and so it assumes some defaults. Every call to C<robocopy.exe> made by C<run> and C<runjobs> if nothing is specified will result in:


    robocopy.exe SOURCE DESTINATION *.* /S /E /M /R:0 /W:0 /NP /256 

	
Apart from source and destination, first six parameters can be modified during the C<run> call (see below the method description for details). 
Last two switches will be present anyway: C</NP> eliminates the progress bar that can show the copied percentage and that it is not useful as the module will collect all the output from the command.

More important is the C</256> switch that disable the discutible feature permitting C<robocopy> to create folders with more than 256 characters in the path (the OS has a treshold of 260). 
Without this switch, an eventual erroneous invocation can lead to a folder structure very difficult to remove because the explorer subsystem is not even able to remove nor rename it.

Even specialized tools can fail ( booting Linux live distro and good old C<rm -rf> can help though ;). Even if other checks in the module are to prevent these bad results the switch will be always present.

By other hand, if nothing is specified, every call of the C<restore> method will result in:

    robocopy.exe SOURCE DESTINATION *.* /S /E /R:0 /W:0 /NP /256 
	
with the only but important difference in respect to archive bit that are not looked for nor reset ( no C</M> switch passed ).

Please note that C<robocopy.exe> will use by default C</COPY:DAT> ie will copy data, attributes and timestamp.

=head2 about verbosity

Verbosity of the module can vary from C<0> (default value, no outptut at all) to C<2> giving lot of informations and dumping jobs and configuration. 
The C<verbose> parameter can be set in the main backup object during the construction made by C<new>  and in this case will be inherited by all other methods. But C<run> C<job> C<runjobs> and C<restore> methods can be feed too with a C<verbose> parameter that will be in use only during the call.

=head1 METHODS (RUN mode)

=head2 new

As already stated C<new> only needs two mandatory parameters: C<name> ( the name of the backup governing the destination folder name too) and C<source> ( you can use also the abbreviated C<src> form ) that specify what you intend to backup. 
The C<new> method will emit a warning if the source for the backup does not exists but do not exit the program: this can be useful to spot a typo leaving to you if that is the right thing (maybe you want to backup a remote folder not available at the moment).

If you do not specify a C<destination> ( or the abbreviated form C<dst> ) you'll have backup folders created inside the current directory, ie the module assumes C<destination> to be C<'.'> unless specified.
During the object construction C<destination> will be crafted using the provided path and the C<name> you used for the backup.

If your current running program is in the C<c:/scripts> directory the following invocation

    my $bkp = Win32::Backup::Robocopy->new(
            name 	=> 'my_perl_archive',       
            source	=> 'x:\perl_stuff',            
    );

will produces a C<destination> equal to C<c:/scripts/my_perl_archive> and here will be backed up your files.

By other hand:

    my $bkp = Win32::Backup::Robocopy->new(
            name 	=> 'my_perl_archive',       
            source	=> 'x:\scripts',            
            destination => 'Z:\backups'
    );

will produces a C<destination> equal to C<Z:/backups/my_perl_archive>


All paths and filenames passed in during costruction will be checked to be absolute and if needed made absolute using L<File::Spec> so you can be quite sure the rigth thing will be done with relative paths.

The C<new> method does not do any check against destination folders existence; it merely prepare folder names to be used by C<run>

The module provides a mechanism to spot unavailable destination drive and ask the user to connect it. 
If you specify C<waitdrive =E<gt> 1> during the object construction then the program will not die when the drive specified as destination is not present. Instead it opens a prompt asking the user to connect the appropriate drive to continue. The deafult value of C<waitdrive> is 0 ie. the program will die if the drive is unavailable and creation of the destination folder impossible.

To wait for the drive is useful in case of backups with destination, let's say, an USB drive: see the L</"backup to external drive"> example.

Overview of parameters accepted by C<new> and their defaults:


=over 

=item 

C<name> mandatory. Will be used to create the destination folder appended to C<dest>

=item 

C<source> or C<src> mandatory. 


=item 

C<destination> or C<dst> defaults to C<'./'> 


=item 

C<history> defaults to 0 meaning all invocation of the backup will write to the same folder or folder with timestamp if 1

=item 

C<waitdrive> defaults to 0 stopping the program if destination drive does not exists, asking the user if 1

=item 

C<verbose> defaults to 0 governs the amount of output emitted by the program


=back




=head2 run

This method will effectively run the backup. It checks needed folder for existence and try to create them using L<File::Path> and will croak if error are encountered.
If C<run> is invoked without any optional parameter C<run> will assume some default options to pass to the C<robocopy> system call:

=over 

=item 

C<files> defaults to C<*.*>  robocopy will assume all file unless specified: the module passes it explicitly (see below)

=item 

C<archive> defaults to 0 and will set the C</A> if 1 ( copy only files with the archive attribute set ) robocopy switch

=item 

C<archiveremove> defaults to 1 and will set the C</M> ( like C</A>, but remove archive attribute from source files ) robocopy switch

=item 

C<subfolders> defaults to 1 and will set the C</S> if 1 ( copy subfolders ) robocopy switch

=item 

C<emptysubfolders> defaults to 1 and will set the C</E> ( copy subfolders, including empty subfolders ) robocopy switch

=item 

C<retries> defaults to 0 and will set the C</R:0> or N if specified (number of retries on error on file) robocopy switch

=item 

C<wait> defaults to 0 and will set the C</W:0> or N if specified (seconds between retries) robocopy switch

=item 

C<extraparam> defaults to undef and can be used to pass any valid option to robocopy (see below)

=back

So if you dont want empty subfolders to be backed up you can run:

	$bkp->run( emptysufolders => 0 )
	
Pay attention modifying C<archive> and C<archiveremove> parameters: infact this is the basic machanism of the backup: on MSWin32 OSs whenever a file is created or modified the archive bit is set. This module with it's defualts values of C<archive> and C<archiveremove> will backup only new or modified files and will unset the archive bit in the original file.

The C<run> method effectively executes the C<robocopy.exe> system call using L<Capture::Tiny> C<capture> method.
The C<run> method returns four elements: 1) the output emitted by the system call, 2) the error stream eventually produced, 3) the exit code of the call ( first three elements provided by L<Capture::Tiny> ) and 4) the text relative to the exit code. A fifth returned value will be present if the backup has C<history =E<gt> 1> and it's value will be the name of the folder with timestamp just created.

	my( $stdout, $stderr, $exit, $exitstr ) = $bkp->run();
	
	# or in case of history backup:
	# my( $stdout, $stderr, $exit, $exitstr, $createdfolder ) = $bkp->run();
	
	# an exit code of 7 or less is a success
	if ( $exit < 8 ){
		print "backup successful: $exitstr\n";
	}
	else{ print "some problem occurred\n",
                "OUTPUT: $stdout\n",
                "ERROR: $stderr\n",
                "EXIT: $exit\n",
                "EXITSTRING: $existr\n";				
	}
	
Read about C<robocopy.exe> exit codes L<here|https://ss64.com/nt/robocopy-exit.html>

C<robocopy.exe> accepts, after source and destination, a third parameter in the form of a list of files or wildcard.
C<robocopy.exe> assumes this to be C<*.*> unless specified but the present module passes it always explicitly to let you to modify it at your will. To backup just C<*.pl> files invoke C<run> as follow:

    $bkp->run( files => '*.pl');  

You can read more about Windows wildcards L<here|https://ss64.com/nt/syntax-wildcards.html>	

C<robocopy.exe> accepts a lot of parameters and the present module just plays around a handfull of them, but you can pass any desired parameter using C<extraparam> so if you need to have all destination files to be readonly you 
can profit the C</A+:[RASHCNET]> robocopy option:

    $bkp->run( extraparam => '/A+:R');

C<extraparam> accepts both a string or an array reference.	

Read about all parameters accepted by C<robocopy.exe> L<here|https://ss64.com/nt/robocopy.html>

=cut


=head1 METHODS (JOB mode)

=head2 new

The only mandatory parameter needed by C<new> is C<conf> (or C<config> or C<configuration>) while in JOB mode. 
The value passed will be transformed into an absolute path and if the file exists and is readable and it contains a valid JSON datastructure, the configuration is loaded and the job queue filled accordingly.

If, by other hand, the file does not exists,  C<new> does not complain, assuming the queue of jobs to be filled soon using the C<job> method described below.


=head2 job

    $bkp->job( 
        name => 'documents',
        src  => 'e:\me\docs',
        dst  => 'x:\my_backups'		
        cron => '0 0 25 12 *',
    );


This method will push job in the queue. It accepts all parameters of the C<new> and the C<run> methods described in RUN mode above.
Infact a job, when run, will instantiate a new backup object and will run it via the C<run> method.

In addition it must be feed with a valid crontab like string via the C<cron> parameter with a value something like, for example, C<'15 14 1 * *'> to setup the schedule for this job to the first day of the month at 14:15

You can specify the optional parameter C<first_time_run =E<gt> 1> to have the job scheduled as soon as possible. Then, after the first time the job will run following the schedule given by the C<cron> parameter.

Everytime a job is added, the configuration file will be updated accordingly.

If the C<verbose> option is passed in during the C<job> call (or if it is inherited by the main backup object) informations are displayed. With C<verbose> set to C<2> each job added is dumped and the resulting configuration will be also printed. 


=head2 runjobs

This is the method used to cycle the job queue to see if something has to be run. If so the job is run and the configuration file is immediately updated with the correct time for the next execution.

The C<runjobs> method without any parameter will check all jobs in order to see if is time to run them. Optionally you can pass to it a range or a string representing a range to just process selected jobs:

    $bkp->runjobs(0..1,5);
    # or the same in the string form
    $bkp->runjobs('0..1,5');


=head2 listjobs

With C<listjobs> you can list all jobs currently present in the configuration. In scalar context it just returns the number of jobs while in list context it returns the list of jobs.

In the list form you have the possibility to define the format used to represent the job with the C<format> parameter: if it is C<short> (and is the default value) each job will be represented on his own line. By other hand  with C<format =E<gt> 'long'> a more fancy multiline string will be printed for each job.

You can also specify a list of fields you want to show instead to have them all present, passing an array reference as value of the C<fields> parameter.

    # sclar context
    my $jobcount = $bkp->listjobs;
    print "there are $jobcont jobs configured";

    # list context: all fields returned in compact mode
    print "$_\n" for $bkp->listjobs;

    # output:
    name = job1 src = x:\path1 dst = F:\bkp\job1 files =  ...(all other fields and values following)
    name = job2 src = y:\path2 dst = F:\bkp\job2 files =  ...

    # list context: some field returned in compact mode
    print "$_\n" for $bkp->listjobs(fields => [qw(name src next_time_descr)]);

    # output:
    name = job1 src = x:\path1 next_time_descr = Tue Jan  1 00:05:00 2019
    name = job2 src = y:\path2 next_time_descr = Mon Apr  1 00:03:00 2019

    # list context, long format just some field
    print "$_\n" for $bkp->listjobs( format=>'long', fields => [qw(name src next_time_descr)]);

    # output:
    JOB 0:
            name = job1
            src = x:\path1
            next_time_descr = Tue Jan  1 00:05:00 2019

    JOB 1:
            name = job2
            src = x:\path2
            next_time_descr = Mon Apr  1 00:03:00 2019


			
			
=head1 RESTORE

=head2 restore

The module provides a method to restore from a backup to a given destination. It is just
a copy of all files and directories found in a given source directory, to a  given destination (that will be created if it does not already exists).

This method just needs two parameters: C<from> and C<to> like in:

    $bkp->restore(  
                    from => 'X:/external/scripts_bkp' , 
                    to 	 => 'D:/local/scripts' 
    );

The C<restore> method will accept all parameter concerning C<robocopy> options as the C<run> method does, with the only important difference about archive bit: the default is to ignore it.

=over 

=item 

C<files> defaults to C<*.*>  robocopy will assume all file unless specified: the module passes it explicitly (see below)

=item 

C<archive> defaults to 0 and will set the C</A> if 1 ( copy only files with the archive attribute set ) robocopy switch

=item 

C<archiveremove> defaults to 0 (the only difference in respect of the run method) and will set the C</M> ( like C</A>, but remove archive attribute ) robocopy switch

=item 

C<subfolders> defaults to 1 and will set the C</S> if 1 ( copy subfolders ) robocopy switch

=item 

C<emptysubfolders> defaults to 1 and will set the C</E> ( copy subfolders, including empty subfolders ) robocopy switch

=item 

C<retries> defaults to 0 and will set the C</R:0> or N if specified (number of retries on error on file) robocopy switch

=item 

C<wait> defaults to 0 and will set the C</W:0> or N if specified (seconds between retries) robocopy switch

=item 

C<extraparam> defaults to undef and can be used to pass any valid option to robocopy (see run method)

=back

	
=head2 history restore

When each folder contained in the given source to restore has a name as given by a C<history> backup, eg. like C<2022-04-12T09-02-36> and the folder used as source to restore contains only  folders and no other object at all, then, if these conditions are met, each folder will be used as source starting from the older one to the newer one.

This behaviour permits a restore to a point in time using the C<upto> parameter in the C<restore> call. 

Let's say you have backed up some folder with an C<history> backup and now you have the following folders:

	2019-01-04T20-29-10
	2019-01-05T20-29-10
	2019-01-06T20-29-10
	2019-01-07T20-29-10
	
all contained in C<X:\external\photos> and you discover that the day 7 of January at 14:00 all your pictures got corrupted ( so the last backup contains a lot of invalid files ) you can restore only pictures up to the January 6 using:

    $bkp->restore(  
                    from => 'X:\external\photos', 
                    to => 'C:\PICS\restore_up_to_january_6',
                    upto => '2019-01-06T20-29-10',					
    );
	
and you'll have restored only the photos backed up in the firsts three folder and not in the fourth one.

The C<upto> parameter can be: 1) a string as used to create folders by history backups, like in the above example C<2019-01-06T20-29-10> or 2) a string as created by L<DateTime::Tiny> C<as_string> method (ISO 8601) ie C<2019-01-06T20:29:10> or 3) seconds since epoch like C<1546806550> or 4) a L<DateTime::Tiny> object or 5) a L<DateTime> object.


Pay attention to what is said in the L<DateTime::Tiny> documentation about time zones and locale: in other words the conversion will be using C<gmtime> and not C<localtime> see the following example to demonstrate it:

    use DateTime::Tiny;
    my $epoch = DateTime::Tiny->from_string('2019-01-06T20:29:10')->DateTime->epoch; 
    say 'epoch:     ',$epoch; 
    say 'localtime: ',scalar localtime($epoch); 
    say 'gmtime:    ',scalar gmtime($epoch);

    # output

    epoch:     1546806550
    localtime: Sun Jan  6 21:29:10 2019
    gmtime:    Sun Jan  6 20:29:10 2019


The C<restore> method will execute a C<robocopy.exe> call with defaut arguments C<'*.*', '/S', '/E', '/NP' '/256'> but you can pass other ones using the C<extraparam> parameter being it a string or an array reference with a list of valid C<robocopy.exe> parameters.

Both history and normal restore can output more informations if C<verbose> is set in the main backup object or if it is passed in directly during the C<restore> method call.

=head2 returned value 

The return value of a C<restore> call will be an anonymous array with an element for each operation done by the method. If it was a simple restore the array will hold just one element but
if it was a history restore each operation (using a different folder as source) will push an 
element in the array. These array elements are anonymoous hashes with four keys:  C<stdout>, C<stderr>, C<exit> and C<exitstring> of each operation respectively.


=head1 CONFIGURATION FILE

While in C<JOB> mode if the configutaion file passed during object contruction contains valid data, such data will be imported into the main ojbect. 
Each new job added using the C<job> method will be added too and the configuration will be wrote accordingly. This will speed up the backup setup but can also lead in duplicate jobs: see L</"on demand backup in job mode"> example to see how deal with this.

The configuration file holds JSON data into an array each element of the array being a job, contained in a hash.
Writing to the configuration file done by the present module will maintain the job hash ordered using L<JSON::PP>

    my $bkp = Win32::Backup::Robocopy->new(conf=>'bkpconfig.json'); 
	
    $bkp->job( src => '.', dst => 'x:/dest', name => 'first', cron => '* 4 * * *' ); 
	
    
	
Will produce the following configuration:


  [
     {
      "name" : "first",
      "src" : "D:\\path\\stuff_to_backup",
      "dst" : "X:\\dest\\first",
      "files" : "*.*",
      "history" : 0,
      "cron" : "* 4 * * *",
      "next_time" : 1543546800,
      "next_time_descr" : "Fri Nov 30 04:00:00 2018",
      "first_time_run" : 0,
      "archive" : 0,
      "archiveremove" : 1,
      "subfolders" : 1,
      "emptysubfolders" : 1,
      "retries" : 0,
      "wait" : 0,
      "waitdrive" : 0,
      "verbose" : 0
     }
  ]

you can freely add and modify by hand the configuration file, paying attention to the C<next_time> and C<next_time_descr> entries that are respectively seconds since epoch for the next scheduled run and the human readable form of the previous entry.
Note that C<next_time_descr> is just a label and does not affect the effective running time.

=head1 EXAMPLES

=head2 a simple case

You can use an on the fly backup, for example, if you load a configurtion file and you modify it but you are not sure the whole process will be successful:

    use strict;
    use warnings;
    use Win32::Backup::Robocopy;
    
    # the following will backup into x:\conf_bkp
    # ie the destination plus the name of the backup
    my $bkp = Win32::Backup::Robocopy->new(
            name        => 'conf_bkp',       
            source      => 'c:\path\to\conf',
            destination => 'x:\',
    );

    my( $stdout, $stderr, $exit, $exitstr ) = $bkp->run( archiveremove => 0 );
        
    if ( $exit < 8 ){
        print "backup of configuration OK: $exitstr\n";
    }

    # something goes wrong: need to restore the original configuration

    print "starting restore:\n";
	
    $bkp->restore(  
            from => 'x:\conf_bkp',  # the name of backup appended
            to => 'c:\path\to\conf',             # to the backup destination
            verbose => 2,
    );

In the above example we pass to restore C<verbose> with the value of C<2> to have printed out many details of the restore operation.

Pay attention to the C<run> call: we used C<archiveremove =E<gt> 0> and it also use the default C<archive =E<gt> 0> and this will means that we are not looking at all to the archive bit of the file, nor we remove it: this setting will always copy the file. Defaults are set to backup only modified and new files.	

=head2 maintain more copies

If you instead have a program running monthly, which modify a configuration file you can use the C<history> backup type to have more copies of the same file, one for each run of your monthly task. Now we use C<verbose> with value of C<1> inside the C<run> method call:

    my $bkp = Win32::Backup::Robocopy->new(
            name        => 'conf_bkp',       
            source      => 'c:\path\to\conf',
            destination => 'x:/',
            history     => 1,
    );

    my( $stdout, $stderr, $exit, $exitstr ) = $bkp->run( verbose => 1);
        
    if ( $exit < 8 ){
        print "\nbackup of configuration OK\n";
    }

And this will add following lines to your program:

    backup SRC: [c:\path\to\conf]
    backup DST: [x:\conf_bkp\2019-01-11T23-11-09]
    mkdir x:\conf_bkp\2019-01-11T23-11-09
    executing [robocopy.exe c:\path\to\conf x:\conf_bkp\2019-01-11T23-11-09 *.* /S /E /M /R:0 /W:0 /256 /NP]
    robocopy.exe exit description:  One or more files were copied successfully (that is, new files have arrived).
    
    backup of configuration OK

If your program run monthly you'll have under C<conf_bkp> the following folders:

    2019-01-11T23-11-09
    2019-02-11T23-11-09
    2019-03-11T23-11-09
    2019-04-11T23-11-09
    ..

	
=head2 backup to external drive

The C<waitdrive> option is useful when dealing with network shares or external drives. Infact the module will check if the drive is not present and will ask to connect before proceding:

    my $bkp=Win32::Backup::Robocopy->new( 
                                          name => 'test', 
                                          src  => '.',
                                          dst  => 'H:/bkp',     # drive H: is unplagged
                                          waitdrive => 1         # force asking the user
    ); 
	
    $bkp->run();
	
    # output:
	
    Backup of:     D:\my_current\dir
    To:            H:\bkp\test
    Waiting for drive H: to be available..
    (press ENTER when H: is connected or CTRL-C to terminate the program)
	
    # I press enter before plugging the drive..
	
    Backup of:     D:\my_current\dir
    To:            H:\bkp\test
    Waiting for drive H: to be available..
    (press ENTER when H: is connected or CTRL-C to terminate the program)

    # I plug the external hard disk that receive the H: letter, then  I press ENTER
    # the backup runs OK

With C<waitdrive> set to 0 instead the above program dies complaining about directory creation errors and C<destination drive H: is not accessible!>	


=head2 on demand backup in job mode

The C<JOB> mode is mainly intended to implement scheduled backups using the C<cron> like mechanism. But, if it is the need, you can have backups run only on demand using a C<cron> string of five asterisks C<* * * * *> and using C<listjobs> and C<runjobs> to ask the user if they want to run the backup:


    use Win32::Backup::Robocopy;
    my $bkp = Win32::Backup::Robocopy->new( config => './my_bkp.json' );

    # configuration made in previous runs is already populated
    # so check if we need to specify jobs

    if ( 0 == $bkp->listjobs ){
        
        print "adding jobs..\n";
        
        # a first job for 'documents'
        $bkp->job(  
            name=>'documents', 
            src=> 'c:\DOCS',
            dst  => "x:\\",
            cron =>'* * * * *',
            first_time_run => 1, # or during the current minute will be skipped
        );
				
        # a second job for 'scripts'
        $bkp->job(  
            name=>'SCRIPTS', 
            src=> 'c:\perl\scripts',
            dst  => 'x:\\',
            cron=>'* * * * *',
            first_time_run => 1, # see above: cron works on minutes!
        );
    }
    else{ print scalar $bkp->listjobs, " jobs retrieved from configuration file..\n"}
    
    # iterate over jobs
    my $job_num = 0;
    foreach my $descr( $bkp->listjobs( format=>'long', fields => [qw(name src dst)]) ){

        print $descr;
        print "do you want to execute JOB $job_num? [y|n]\n\n";
        my $input = <STDIN>;
        if ( $input =~/^y/i ){
            $bkp->runjobs( $job_num );
        }
        $job_num++;
    }


=head1 AUTHOR

LorenzoTa, C<< <lorenzo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-win32-backup-robocopy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Backup-Robocopy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

Main support site for this module is L<perlmonks.org|https://www.perlmonks.org>
You can find documentation for this module with the perldoc command.

    perldoc Win32::Backup::Robocopy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-Backup-Robocopy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-Backup-Robocopy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-Backup-Robocopy>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-Backup-Robocopy/>

=back


=head1 ACKNOWLEDGEMENTS

This software, as all my works, would be impossible without the continuous support and incitement of the L<perlmonks.org|https://www.perlmonks.org>
community

=head1 LICENSE AND COPYRIGHT

Copyright 2018 LorenzoTa.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


