# Win32::Script - System administrator`s library
#           - for login and application startup scripts, etc
#
# makarow and demed
# ..., 18/02/99 13:04
#
package Win32::Script;
require	5.000;
require	Exporter;
use	Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.58';
@ISA = qw(Exporter);
@EXPORT = qw(CPTranslate Die Echo FileACL FileCompare FileCopy FileCRC FileCwd FileDelete FileDigest FileEdit FileFind FileGlob FileHandle FileIni FileLnk FileMkDir FileNameMax FileNameMin FileRead FileSize FileSpace FileTrack FileWrite FTPCmd GUIMsg NetUse OLECreate OLEGet OLEIn OrArgs Pause Platform Print Registry Run RunInf RunKbd SMTPSend StrTime UserEnvInit UserPath WMIService WScript);
@EXPORT_OK = qw(FileLog TrAnsi2Oem TrOem2Ansi Try(@) TryHdr);
%EXPORT_TAGS = ('ALL'=>[@EXPORT,@EXPORT_OK],'OVER'=>[]);

use vars qw($Interact $GUI $Echo $ErrorDie $Error $Print $Language %WScript);
$Interact	=1;	# interaction with user; no: 0
$GUI		=1;	# use GUI interaction instead of terminal
$Echo		=1;	# set echo on
$ErrorDie	=0;	# die on errors: 1
$Error		='';	# error result
$FileLog	='';	# log file name (LOG handle) for Echo, Print, errors...
$Print		='';	# external print routine hardlink
$Language	='';	# language of user interaction, may be '' or 'ru'
%WScript	=();	# Windows Script Host objects

# FileHandle(\*STDOUT,sub{$| =1});
# FileHandle(\*STDERR,sub{$| =1});

1;

sub Try (@);

sub import {
 if (grep /^:OVER$/,@_) {
	my $lst =(grep /^:ALL$/, @_) ? $EXPORT_TAGS{ALL} : \@EXPORT;
	foreach my $elem (@$lst) {
		my $sym =caller(1) .'::' .$elem; undef(&$sym);
	}
 }
 $_[0]->export_to_level(1, @_);
}


###
sub CPTranslate {
 my ($f,$t,@s) =@_; 
 foreach my $v ($f, $t) {
	if	($v =~/oem|866/i)	{$v ='ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôúõöùûü†°¢£§•Ò¶ß®©™´¨≠ÆØ‡·‚„‰ÂÊÁËÈÏÎÍÌÓÔ'}
	elsif	($v =~/ansi|1251/i)	{$v ='¿¡¬√ƒ≈®∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸ‹€⁄›ﬁﬂ‡·‚„‰Â∏ÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ˜¯˘¸˚˙˝˛ˇ'}
	elsif	($v =~/koi/i)		{$v ='·‚˜Á‰Â≥ˆ˙ÈÍÎÏÌÓÔÚÛÙıÊË„˛˚˝¯˘ˇ¸‡Ò¡¬◊«ƒ≈£÷⁄… ÀÃÕŒœ–“”‘’∆»√ﬁ€›ÿŸﬂ‹¿—'}
	elsif	($v =~/8859-5/i)	{$v ='∞±≤≥¥µ°∂∑∏π∫ªºΩæø¿¡¬√ƒ≈∆«»…ÃÀ ÕŒœ–—“”‘’Ò÷◊ÿŸ⁄€‹›ﬁﬂ‡·‚„‰ÂÊÁËÈÏÎÍÌÓÔ'}
 }
 map {eval("~tr/$f/$t/")} @s;
 @s >1 ? @s : $s[0];
}
sub TrOem2Ansi {CPTranslate('oem','ansi',@_)}
sub TrAnsi2Oem {CPTranslate('ansi','oem',@_)}

###
sub Die {
 my @txt = @_ ? @_ : $@;
 GUIMsg(($Language =~/ru/i ?'Œ¯Ë·Í‡' :'Error')
	, eval('${^ENCODING}') ? @txt : CPTranslate('oem','ansi',@txt)) 
	if $Interact && $GUI && !$^S;
 $! =1 if !$!;
 croak(join(' ',@txt))
}

###
sub Echo { !$Echo || Print(@_)}

###
sub FileACL {
Try eval { local $ErrorDie =2;
 my $opt =($_[0] =~/^\-/i ? shift : '');
 my $file=shift;
 my $sub =(ref($_[0]) eq 'CODE' ? shift : undef);
 my %acl =@_;
 if (!$sub && !grep {$_ !~/^(full|change|read)$/i} values(%acl)) {
	my @c;
	push @c, '/E' if $opt =~/\+/; push @c, '/T' if $opt =~/r/i;
	push @c, ('/G', map {(index($_,' ') >=0 ?"\"$_\"" :$_) .':' .uc(substr($acl{$_},0,1))} sort(keys(%acl)));
	push @c, sub{print("Y\n")} if $opt !~/\+/ && %acl;
	return !grep {!Run('cacls.exe',"\"$_\"",'/C',@c)} FileGlob($file);
 }
 Echo('FileACL',$opt,$file,CPTranslate('ansi','oem',@_));
 $sub =sub{1} if !$sub;
 my (%acd, %acf);
 eval('use Win32::FileSecurity');
 foreach my $k (keys(%acl)) {
	if    (ref($acl{$k}))		{$acd{$k} =Win32::FileSecurity::MakeMask(@$acl{$k}->[0]); $acf{$k} =Win32::FileSecurity::MakeMask(@$acl{$k}->[1])}
	elsif ($acl{$k} =~/full/i)	{$acd{$k} =Win32::FileSecurity::MakeMask(qw(FULL GENERIC_ALL)); $acf{$k} =Win32::FileSecurity::MakeMask(qw(FULL))}
	elsif ($acl{$k} =~/change/i)	{$acd{$k} =Win32::FileSecurity::MakeMask(qw(CHANGE GENERIC_WRITE GENERIC_READ GENERIC_EXECUTE)); $acf{$k} =Win32::FileSecurity::MakeMask(qw(CHANGE))}
	elsif ($acl{$k} =~/add&read/i)	{$acd{$k} =Win32::FileSecurity::MakeMask(qw(ADD GENERIC_READ GENERIC_EXECUTE)); $acf{$k} =Win32::FileSecurity::MakeMask(qw(READ))}
	elsif ($acl{$k} =~/add&list/i)	{$acd{$k} =Win32::FileSecurity::MakeMask(qw(ADD READ STANDARD_RIGHTS_READ STANDARD_RIGHTS_WRITE STANDARD_RIGHTS_EXECUTE READ_CONTROL SYNCHRONIZE))}
	# in doubt^
	elsif ($acl{$k} =~/add/i)	{$acd{$k} =Win32::FileSecurity::MakeMask(qw(STANDARD_RIGHTS_READ STANDARD_RIGHTS_WRITE STANDARD_RIGHTS_EXECUTE READ_CONTROL SYNCHRONIZE))}
	# in very doubt^
	elsif ($acl{$k} =~/read/i)	{$acd{$k} =Win32::FileSecurity::MakeMask(qw(READ GENERIC_READ GENERIC_EXECUTE)); $acf{$k} =Win32::FileSecurity::MakeMask(qw(READ))}
	elsif ($acl{$k} =~/list/i)	{$acd{$k} =Win32::FileSecurity::MakeMask(qw(READ_CONTROL SYNCHRONIZE STANDARD_RIGHTS_READ STANDARD_RIGHTS_WRITE STANDARD_RIGHTS_EXECUTE READ))}
	# in doubt^
 };
 FileFind($file
	,sub{	print STDOUT "$_\n" if $Echo;
		if	(!&$sub(@_)) {}
		elsif	($_[0]->[2] & 0040000) {
			if	(!scalar(%acd))	{eval{my %h; Win32::FileSecurity::Get($_,\%h); foreach my $k (sort(keys(%h))){my @s; Win32::FileSecurity::EnumerateRights($h{$k},\@s); Echo($k,'=>',@s)}}}
			elsif	($opt =~/\+/i)	{eval{my %h; Win32::FileSecurity::Get($_,\%h); foreach my $k (keys(%acd)){$h{$k}=$acd{$k}}; Win32::FileSecurity::Set($_,\%h)}}
			else	{eval{Win32::FileSecurity::Set($_,\%acd)}}
			$_[0]->[2] =0 if $opt !~/r/i;
		}
		else {
			if	(!scalar(%acf))	{eval{my %h; Win32::FileSecurity::Get($_,\%h); foreach my $k (sort(keys(%h))){my @s; Win32::FileSecurity::EnumerateRights($h{$k},\@s); Echo($k,'=>',@s)}}}
			elsif	($opt =~/\+/i)	{eval{my %h; Win32::FileSecurity::Get($_,\%h); foreach my $k (keys(%acf)){$h{$k}=$acf{$k}}; Win32::FileSecurity::Set($_,\%h)}}
			else	{eval{Win32::FileSecurity::Set($_,\%acf)}}
		}})
},0}

###
sub FileCompare {
 my $opt =($_[0] =~/^\-/i ? shift : ''); 
 my $ret =eval("use File::Compare; compare(\@_)");
 if ($@ || $ret <0) {TryEnd(($Language =~/ru/i ?'ç•„§†Á≠Æ ·‡†¢≠•≠®•' :'Failure')." compare(" .join(', ',@_) ."): $!"); 0}
 else {$ret}
}

###
sub FileCopy {
Try eval { local $ErrorDie =2;
 my $opt =$_[0] =~/^-/i ?shift :''; $opt =~s/-//g;
 # 'd'irectory or 'f'ile hint; 'r'ecurse subdirectories, 'i'gnore errors
 my ($src,$dst) =@_; if ($^O eq 'MSWin32') {$src =~tr/\//\\/; $dst =~tr/\//\\/}
 if ($^O ne 'dos' && $] >=5.006 && $src !~/[?*]/ && $dst !~/[?*]/ && -s $src <2*1024*1024 && !-d $src 
	&& (-e $dst ||($opt !~/d/ && $dst =~/(.+)[\\\/][^\\\/]+$/ ? -d $1 : 0))) {
	$dst .=($dst =~/[\\\/]$/ ? '' : $^O eq 'MSWin32' ? '\\' : '/') .($src =~/[\\\/]([^\\\/]+)$/ ? $1 : $src) if -d $dst;
	Echo("CopyFile('$src', '$dst')");
	((-f $dst ?unlink($dst) :1) && ($^O eq 'MSWin32' ?Win32::CopyFile($src, $dst, 1) :eval("use File::Copy; File::Copy::copy('$src','$dst')")))
	||croak("CopyFile('$src','$dst')->$!")
 }
 elsif ($^O =~/MSWin32|dos/) {
	$opt .='Z' .((eval{(Win32::GetOSVersion())[1]} ||eval('use Win32::TieRegistry; $$Registry{\'LMachine\\Software\\Microsoft\\Windows NT\\CurrentVersion\\\\CurrentVersion\'}') ||0) >=5 ?'Y' :'')
		if ($ENV{OS}||'') =~/Windows_NT/i;
	my $rsp =($opt =~/d/i ? 'D' : $opt =~/f/i ? 'F' : '');
	$opt =~s/(r)/SE/i; $opt =~s/(i)/C/i; $opt =~s/[fd]//ig; $opt =~s/(.{1})/\/$1/gi;
	my @cmd =('xcopy',"/H/R/K/Q$opt","\"$src\"","\"$dst\"");
	push @cmd, sub{print($rsp)} if $rsp && ($ENV{OS} && $ENV{OS}=~/windows_nt/i ? !-e $dst : !-d $dst);
	Run(@cmd)
 }
 else {
	$opt =~ tr/fd//; $opt ="-${opt}p"; $opt =~ tr/ri/Rf/; Run('cp', $opt, @_)
 }
},0}

###
sub FileCRC {
Try eval { local $ErrorDie =2;
 my $opt =($_[0] =~/^\-/i ? shift : ''); 
 my ($file) =@_;
 my $bufsze =64*1024;
 my $buff;
 my $crc =0;
 local *IN;
 eval("use Compress::Zlib");
 open(IN, "<$file") || croak(($Language =~/ru/i ?'é‚™‡Î‚®•' :'Opening') ." '<$file': $!");
 binmode(IN);
 while (!eof(IN)) {
	defined(read(IN, $buff, $bufsze)) || croak(($Language =~/ru/i ?'ó‚•≠®•' :'Reading')." '<$file': $!");
	$crc = $opt =~/\-a? ?adler/i ? adler32($buff,$crc) : crc32($buff,$crc);
 }
 close(IN) || croak(($Language =~/ru/i ?'á†™‡Î‚®•' :'Closing')." '<$file': $!");
 $crc;
},0}

###
sub FileCwd {
 eval('use Cwd; getcwd()')
}

###
sub FileDelete {
Try eval { local $ErrorDie =2;
 Echo('FileDelete',@_);
 my $opt =$_[0] =~/^\-/ || $_[0] eq '' ? shift : '';
 my $ret =1;
 foreach my $par (@_) {
	foreach my $elem (FileGlob($par)) {
		if (-d $elem) {                 # '-r' - recurse subdirectories
			if ($opt =~/r/i && !FileDelete($opt,"$elem/*")) {
				$ret =0
			}
			elsif (!rmdir($elem)) {
				$ret =0;
				$opt =~/i/i || croak(($Language =~/ru/i ?'ì§†´•≠®•' :'Deleting')." FileDelete('$elem'): $!");
			}
		}
		elsif (-f $elem && !unlink($elem)) {
			$ret =0;
			$opt =~/i/i || croak(($Language =~/ru/i ?'ì§†´•≠®•' :'Deleting')." FileDelete('$elem'): $!");
		}
	}
 }
 $ret
},0}

###
sub FileDigest {
Try eval { local $ErrorDie =2;
 my $m = substr($_[0] =~/^-/i ? shift : '-MD5', 1);
 FileHandle($_[0],sub{eval("use Digest::${m};Digest::${m}->new->addfile(*HANDLE)->hexdigest")})
},0}

###
sub FileEdit {
Try eval { local $ErrorDie =2;
 Echo("FileEdit",@_);
 my $opt    = $_[0] =~/^-/i ? shift : '-i';
 my $file   = shift;
 my $fileto = @_ >1 ? shift : ''; if($fileto =~/^-/i) {$opt =$opt .$fileto; $fileto =''};
 my $sub    = shift;
 my $mtd    = $opt =~/^\-i/i ? 1 : 0;
 my ($sct,@v) =('','','','');
 local $_;

 if	($opt =~/^\-i$/i) {	# '-i' - default, in memory inplace edit
	my @dta;
	$mtd =0;
	foreach my $row (FileRead($file)) {
		$_ =$row;
		$sct =$1 if /^\s*[\[]([^\]]*)/;
		&{$sub}($sct, @v); # &{$sub}($sct, @v);
		$mtd =1 if !defined($_) || $_ ne $row;
		push(@dta, $_) if defined($_);
	}
	return(!$mtd || FileWrite($file, @dta));
 }
 elsif ($opt =~/^-m$/i) {	# '-m' - multiline edit in memory
	$fileto = $_ =FileRead($file);
	&{$sub}($sct, @v); # &{$sub}($sct, @v);
	return(($fileto eq $_) || FileWrite($file, $_));
 }
				# '-i ext' or 'from, to'
 $fileto ="$file.$1" if $opt =~/^\-i\s*(.*)/i;
 if (!-f $file && -f $fileto) {
	Echo("copy", $fileto, $file);
	eval ("use File::Copy");
	File::Copy::copy ($fileto, $file) || croak(($Language =~/ru/i ?'äÆØ®‡Æ¢†≠®•' :'Copying')." '$fileto'->'$file': $!");
 }
 local (*IN, *OUT);
 open(IN, "<$file")    || croak(($Language =~/ru/i ?'é‚™‡Î‚®•' :'Opening')." '<$file': $!");
 open(OUT, ">$fileto") || croak(($Language =~/ru/i ?'é‚™‡Î‚®•' :'Opening')." '>$fileto': $!");
 while (!eof(IN)) {
	defined($_ =<IN>) || croak("ó‚•≠®• '<$file': $!");
	chomp;
	$sct =$1 if /^\s*[\[]([^\]]*)/;
	&{$sub}(@v); # &{$sub}($sct, @v);
	!defined($_) || print(OUT $_,"\n") || croak(($Language =~/ru/i ?'á†Ø®·Ï' :'Writing')." '>$fileto': $!");
 }
 close(IN)  || croak(($Language =~/ru/i ?'á†™‡Î‚®•' :'Closing')." '<$file': $!");
 close(OUT) || croak(($Language =~/ru/i ?'á†™‡Î‚®•' :'Closing')." '>$fileto': $!");
 !$mtd || rename($fileto, $file) || croak(($Language =~/ru/i ?'è•‡•®¨•≠Æ¢†≠®•' :'Renaming')." '$file'->'$fileto': $!");
 1;
},0}

###
sub FileFind {
Try eval { local $ErrorDie =2;
 my $opt =($_[0] =~/^\-/i ? shift : '');
 my ($sub, $i, $ret) =(0,0,0);
 local ($_, $result) if $opt !~/-\$/i;
 $opt =$opt ."-\$"   if $opt !~/-\$/i;
 foreach my $dir (@_) {
	$i++;
	if ((!$sub || ref($dir)) && ref($_[$#_]) && $i <=$#_) {
		foreach my $elem (@_[$i..$#_]){if(ref($elem)){$sub =$elem; last}};
		next if ref($dir)
	}
	elsif (ref($dir)) {
		$sub =$dir; next
	}
	my $fs;
	foreach my $elem ($opt =~/[^!]*i/i ?eval{FileGlob($dir)} :FileGlob($dir)) {
		$_ =$elem;
		my @stat =stat($elem);
		my @nme  =(/^(.*)[\/\\]([^\/\\]+)$/ ? ($1,$2) : ('',''));
		if (@stat ==0 && ($opt =~/[^!]*i/i || ($^O eq 'MSWin32' && $elem =~/[\?]/i))) {next}	# bug in stat!
		elsif (@stat ==0) {croak(($Language =~/ru/i ?'ç•„§†Á•≠' :'Failure')." stat('$elem'): $!"); undef($_); return(0)}
		elsif ($stat[2] & 0120000 && $opt =~/!.*s/i) {next} # symlink
		elsif (!defined($fs)) {$fs =$stat[2]}
		elsif ($fs !=$stat[2] && $opt =~/!.*m/i)  {next}	# mountpoint?
		if ($stat[2] & 0040000 && $opt =~/!.*l/i) {		# finddepth
			$ret +=FileFind($opt, "$elem/*", $sub); defined($_) || return(0);
			$_ =$elem;
		}
		if ($stat[2] & 0040000 && $opt =~/!.*d/i) {}	# exclude dirs
		elsif (&$sub(\@stat,@nme,$result)) {$ret +=1};	# $_[3] - optional result
		defined($_) || return(0);			# error stop: undef($_)
		if ($stat[2] & 0040000 && $opt !~/!.*[rl]/i) {	# no recurse, $_[0]->[2] =0
			$ret +=FileFind($opt, "$elem/*", $sub); defined($_) || return(0);
		}
	}
 }
 defined($result) ? $result : $ret
},0}

###
sub FileGlob {
 $^O eq 'MSWin32' ? FileDosGlob(@_) : glob(@_)
}

###
sub FileDosGlob {
 my @ret;
 Try eval { local $ErrorDie =2;
	if (-e $_[0]) {
		push @ret, $_[0];
	}
	else {
		my $msk =($_[0] =~/([^\/\\]+)$/i ? $1 : '');
		my $pth =substr($_[0],0,-length($msk));
		$msk =~s/\*\.\*/*/g;
		$msk =~s:(\(\)[].+^\-\${}[|]):\\$1:g;
		$msk =~s/\*/.*/g;
		$msk =~s/\?/.?/g;
		local (*DIR, $_); opendir(DIR, $pth eq '' ? './' : $pth) || croak(($Language =~/ru/i ?'é‚™‡Î‚®• ™†‚†´Æ£†' :'Opening directory')." '$pth': $!");
		# print "FileGlob: '$pth' : '$msk'\n";
		while(defined($_ =readdir(DIR))) {
			next if $_ eq '.' || $_ eq '..' || $_ !~/^$msk$/i;
			push @ret, "${pth}$_";
		}
		closedir(DIR) || croak(($Language =~/ru/i ?'á†™‡Î‚®• ™†‚†´Æ£†' :'Closing directory')." '$pth': $!");
	}
 }, undef;
 @ret;
}

###
sub FileHandle {
Try eval { local $ErrorDie =2;
 my ($file,$sub)=@_;
 my $hdl =select();
 my $ret;
 if (ref($file) || ref(\$file) eq 'GLOB') {select(*$file); $ret =&$sub($hdl); select($hdl)}
 else {
	my $c =(caller(1) ? caller(1) .'::' : '');
	local *{"${c}HANDLE"}; open("${c}HANDLE", $file) || croak(($Language =~/ru/i ?'é‚™‡Î‚®•' :'Opening')." '$file': $!");
	select ("${c}HANDLE"); $ret =&$sub($hdl); select($hdl);
	close  ("${c}HANDLE") || croak(($Language =~/ru/i ?'á†™‡Î‚®•' :'Closing')." '$file': $!");
 }
 $ret;
},''}

###
sub FileIni {
Try eval { local $ErrorDie =2;
 my $opt    =$_[0] =~/^-/i ? shift : '';
 my $file   =shift;
 Echo("FileIni",$opt,$file);
 my @ini    =FileRead($file);
 my ($sct, $nme, $val, $op);
 my ($isct, $inme, $iins, $val1) =(-1);
 my $mod    =0;

 # Return hash with ini-file data:
 if (scalar(@_)<=0) {
	my %dta;
	foreach my $row (@ini) {
		$row =~/^\s*(.*?)\s*$/; $row =$1;
		if ($row =~/^[\[]/i) {$sct =$row; $dta{$sct}={}}
		elsif ($row =~/^[;]/i)  {}
		else {$row =~/^([^\=]*?)\s*=\s*(.*)/i; $dta{$sct}->{$1}=$2;}
	}
	return(\%dta);
 }

 # Edit ini-file with @_ entries:
 #      '[section]'    ,  ';comment'    , [data,value]    or
 #     ['[section]',op], [';comment',op], [data,value,op]
 # op: '+'set (default), '-'del, ';'comment, 'i'nitial vaue, 'o'ptional value
 foreach my $row (@_) {   
   if    ((ref($row) ? $$row[0] : $row) =~/^\s*[\[]/i) {
         $sct =ref($row) ? $$row[0] : $row; $nme =undef; $val =undef;
         $op  =ref($row) ? $$row[1] || '+' : '+';
         $isct=-1;
         for(my $i =0; $i <=$#ini; $i++) {
           next if !$ini[$i];
           if ($ini[$i]=~/^\s*\Q$sct\E\s*$/i) {$isct =$i; last};
         }
         # print "$sct : $isct : ".($isct==-1 ? "" : $ini[$isct])."\n";
         if    ($op =~/[\+i]/i && $isct ==-1) {$mod =1; push(@ini, $sct); $isct =$#ini}
         elsif ($isct ==-1)                   {}
         elsif ($op =~/[\;]/i) {
               $mod =1; $ini[$isct] =';' .$ini[$isct];
               for(my $i =$isct+1; $i <=$#ini && $ini[$i] !~/^\s*[\[]/i; $i++) {
                 $ini[$i] =';' .$ini[$i]
               }
         }
         elsif ($op =~/[\-]/i) {
               $mod =1; undef($ini[$isct]);
               for(my $i =$isct+1; $i <=$#ini && $ini[$i] !~/^\s*[\[]/i; $i++) {
                 undef($ini[$i])
               }
         }
   }
   elsif ((ref($row) ? $$row[0] : $row) =~/^\s*[\;]/i) {
         $nme =ref($row) ? $$row[0] : $row; $val =undef;
         $op  =ref($row) ? $$row[1] || '+' : '+';
         $inme=-1; $iins =$#ini +1;
         for(my $i =$isct+1; $i <=$#ini; $i++) {
           next if !$ini[$i];
           if ($ini[$i] =~/^\s*[\[]/i) {$iins =$i; last}
           if ($ini[$i]=~/^\s*\Q$nme\E\s*$/i) {$inme =$i; last}
         }
         if    ($op =~/[\-]/i && $inme !=-1) {$mod =1; undef($ini[$inme])}
         elsif ($op =~/[\+]/i && $inme ==-1) {$mod =1; splice(@ini, $iins, 0, $nme)}
   }
   else {
         $nme =$$row[0]; $val =$$row[1];
         $op  =$$row[2] || (!defined($$row[1]) ? '-' : '+');
         $inme=-1; $iins =$#ini +1; $val1='';
         for(my $i =$isct+1; $i <=$#ini; $i++) {
           next if !$ini[$i];
           if ($ini[$i] =~/^\s*[\[]/i) {$iins =$i; last}
           if ($ini[$i]=~/^\s*\Q$nme\E\s*=/i) 
              {$inme =$i; $val1 =$1 if $ini[$i]=~/=\s*(.*?)\s*$/i; last}
         }
         # print "$nme=>$val : [$inme..$iins] : $val1\n";
         if    ($op =~/[\+i]/i  && $inme ==-1)  {$mod =1; splice(@ini, $iins, 0, "$nme=$val")}
         elsif ($inme ==-1)                     {}
         elsif ($op =~/[;]/i)                   {$mod =1; $ini[$inme] =';'.$ini[$inme]}
         elsif ($op =~/[\-]/i)                  {$mod =1; undef($ini[$inme])}
         elsif ($op =~/[\+o]/ && $val ne $val1) {$mod =1; $ini[$inme] ="$nme=$val"}
   }
 }
 !$mod || FileWrite($file,@ini);
},0}


###
sub FileLnk {
Try eval { local $ErrorDie =2;
 eval('use Win32::Shortcut');
 my $opt =(@_ && $_[0] =~/^-/i ? shift : '');
 my $f   =@_ ? shift : undef;
    $f   =$f .'.lnk' if defined($f) && $f !~/\./i;
 if (defined($f) && $opt =~/[mda]/i) {$f =UserPath($opt =~/a/i ?'all' :'', $opt =~/d/i ?'Desktop' :'Start Menu') .'/' .$f};
 return Win32::Shortcut->new($f) if !@_;
 Echo('FileLnk',$opt,$f,@_);
 my $l =Win32::Shortcut->new($opt =~/c/i ? undef : $f);
 if (ref($_[0])) {
	foreach my $k (keys(%{$_[0]})) {
		my $m =($k =~/path|targ/i ? 'Path'
			:$k =~/arg/i      ? 'Arguments'
			:$k =~/work|dir/i ? 'WorkingDirectory'
			:$k =~/desc|dsc/i ? 'Description'
			:$k =~/show/i     ? 'ShowCmd'
			:$k =~/hot/i      ? 'Hotkey'
			:$k =~/i.*l/i     ? 'IconLocation'
			:$k =~/i.*n/i     ? 'IconNumber'
			:$k);
		$l->{$m} =$_[0]->{$k};
	}
 }
 else { # $l->Set(@_)
	$l->{'Path'} =$_[0] if defined($_[0]);
	$l->{'Arguments'} =$_[1] if defined($_[1]);
	$l->{'WorkingDirectory'} =$_[2] if defined($_[2]);
	$l->{'Description'} =$_[3] if defined($_[3]);
	$l->{'ShowCmd'} =$_[4] if defined($_[4]);
	$l->{'Hotkey'} =$_[5] if defined($_[5]);
	$l->{'IconLocation'} =$_[6] if defined($_[6]);
	$l->{'IconNumber'} =$_[7] if defined($_[7]);
 }
 $l->Save($f)
},''}

###
sub FileLog {
Try eval {
 return $FileLog if !@_;
 return (close(LOG),$FileLog ='') if @_ && !defined($_[0]) && $FileLog ne '';
 open(LOG, ">>$_[0]") || croak(($Language =~/ru/i ?'é‚™‡Î‚®•' :'Opening')." '>>$_[0]': $!");
 $SIG{__WARN__} =sub{Print(@_)};
 $SIG{__DIE__}  =sub{!defined($^S) || $^S ? die(@_) : Print(@_)};
 $FileLog =$_[0];
},''}

###
sub FileMkDir {
Try eval { local $ErrorDie =2;
 my ($dir, $mask) =@_;
 Echo('mkdir', @_);
 mkdir($dir, $mask || 0777) || croak(($Language =~/ru/i ?'ëÆß§†≠®•' :'Creating').' '.join(', ',@_) .": $!");
},0}

###
sub FileNameMax {
 my ($dir, $sub) =@_;
 my ($max, $nme) =(undef,'');
 local $_;
 eval { local $ErrorDie =2;
	foreach my $elem (FileGlob($dir =~/[\?\*]/ ? $dir : "$dir/*")) {
		next if !$elem || -d $elem;
		my $nmb =($sub	? &$sub($elem, ($_ =$elem =~/([^\\\/]+)$/i ? $1 :''), ($elem =~/([\d]+)[^\\\/]*$/ ? $1 : undef))
				: ($elem =~/([\d]+)[^\\\/]*$/ ? $1 : undef));
		if (defined($nmb) && (!$max || $max <$nmb)) {$max =$nmb; $nme =$elem};
	}
 }; if ($@) {$max =undef; $nme =''; TryEnd()}
 wantarray ? ($nme, $max) : $max;
}

###
sub FileNameMin {
 my ($dir, $sub) =@_;
 my ($min, $nme) =(undef,'');
 local $_;
 eval { local $ErrorDie =2;
	foreach my $elem (FileGlob($dir =~/[\?\*]/ ? $dir : "$dir/*")) {
		next if !$elem || -d $elem || $elem !~/([\d]+)[^\\\/]*$/;
		my $nmb =($sub	? &$sub($elem, ($_ =$elem =~/([^\\\/]+)$/i ? $1 :''), ($elem =~/([\d]+)[^\\\/]*$/ ? $1 : undef))
				: ($elem =~/([\d]+)[^\\\/]*$/ ? $1 : undef));
		if (defined($nmb) && (!$min || $min >$nmb)) {$min =$nmb; $nme =$elem;}
	}
 }; if ($@) {$min =undef; $nme =''; TryEnd()}
 wantarray ? ($nme, $min) : $nme;
}

###
sub FileRead {
 my $opt =($_[0] =~/^\-/i ? shift : ''); # 'a'rray, 's'calar, 'b'inary
    $opt =$opt .'a' if $opt !~/[asb]/i && wantarray;
 my ($file, $sub) =@_;
 my ($row, @rez);
 local *IN;
 eval { local $ErrorDie =2;
  open(IN, "<$file") || croak(($Language =~/ru/i ?'é‚™‡Î‚®•' :'Opening')." '<$file': $!");
  if    ($sub) {
	$row  =1;
	local $_;
	while (!eof(IN)) {
		defined($_ =<IN>) || croak(($Language =~/ru/i ?'ó‚•≠®•' :'Reading')." '<$file': $!");
		chomp;
		$opt=~/a/i	? &$sub() && push(@rez,$_)
				: &$sub();
	}
  }
  elsif ($opt=~/a/i) {
	while (!eof(IN)) {
		defined($row =<IN>) || croak(($Language =~/ru/i ?'ó‚•≠®•' :'Reading')." '<$file': $!");
		chomp($row);
		push (@rez, $row);
	}
  }
  else {
	binmode(IN) if $opt =~/b/i;
	defined(read(IN, $row, -s $file)) || croak(($Language =~/ru/i ?'ó‚•≠®•' :'Reading')." '<$file': $!");
  }
  close(IN) || croak(($Language =~/ru/i ?'á†™‡Î‚®•' :'Closing')." '<$file': $!");
 }; if ($@) {@rez =(); $row =''; TryEnd()}
 $opt=~/a/i ? @rez : $row
}

###
sub FileSize {
 my $opt =($_[0] =~/^\-/i ? shift : '-i');
 my $file=shift;
 my $sub =(ref($_[0]) ? shift : sub{1});
 FileFind($opt,$file, sub{$_[3] +=$_[0]->[7] if &$sub(@_)})
}

###
sub FileSpace {
Try eval { local $ErrorDie =2;
 my $disk =$_[0] || "c:\\";
 my $sze;
 if ($^O eq 'MSWin32') { 
	if (eval('use Win32::API; 1')) {
		my ($f, $sc, $sb, $nf, $nt) =(undef,"\0"x8,"\0"x8,"\0"x8,"\0"x8);
		return unpack('L',substr($nf,4)) *(1+0xFFFFFFFF) +unpack('L',substr($nf,0,4)) # unpack('Q',$nf)
			if 1 && ($f =new Win32::API('kernel32', 'GetDiskFreeSpaceEx', [qw(P P P P)], 'N'))
			&&  $f->Call("$disk\0",$sc,$sb,$nf);
		return unpack('L',$sc) *unpack('L',$sb) *unpack('L',$nf)
			if ($f =new Win32::API('kernel32', 'GetDiskFreeSpace', [qw(P P P P P)], 'N'))
			&&  $f->Call("$disk\0",$sc,$sb,$nf,$nt);
	}
	$sze =`\%COMSPEC\% /c dir $disk`=~/([\d\.\xFF, ]+)[\D]*$/i ? $1 : ''
 }
 else {
	$sze  =`df -k` =~/^$disk +([\d]+)/im ? $1 : ''
 }
 $sze =~ s/[\xFF, ]//g;
 $sze eq '' && croak("FileSpace($disk) -> $?)");
 $sze
},0}

###
sub FileTrack {
Try eval { local $ErrorDie =2;
 my $opt =($_[0] =~/^\-/i ? shift : '-'); 
 my ($src,$dst,$sub) =@_;
 my $lvl =1;
 my $chg ='';
 local ($_, %dbm, *TRACK) if $opt !~/-\$/i;
 if ($opt !~/-\$/i) {
	Echo('FileTrack',$opt,@_);
	$opt =$opt ."-\$";
	dbmopen(%dbm, "$dst/FileTrack", 0666)
	&& open(TRACK,">>$dst/FileTrack.log") || croak(($Language =~/ru/i ?'é‚™‡Î‚®•' :'Opening')." '$dst/FileTrack': $!");
	$dst =$dst ."/" .StrTime('yyyy-mm-dd_hh_mm_ss');
	$sub =sub{1} if !$sub;
	$lvl =0;
 }
 foreach (FileGlob("$src/*")) {
	my @stat =stat;
	my @nme  =(/^(.*)[\/\\]([^\/\\]+)$/ ? ($1,$2) : ('',''));
	if    (@stat ==0 && ($opt =~/[^!i]*i/i || ($^O eq 'MSWin32' && /[\?]/i)))  {next} # bug in stat!
	elsif (@stat ==0) {croak(($Language =~/ru/i ?'ç•„§†Á•≠' :'Failure')." stat('$_'): $!"); undef($_)}
	elsif ($stat[2] & 0040000 && $opt =~/!.*d/i) {}
	elsif (!&$sub(\@stat,@nme))  {next}
	elsif (!defined($_))         {return('')}  # err stop: undef($_)
	my $crc =$stat[2] & 0040000 || $opt !~/[^!]*t/i ? 0 : FileCRC($_);
	my $tst =!$dbm{$_}	? 'I'
		:$dbm{$_} !~/^([\d]+)\t([\d]+)$/  ? '?'
		:$1 != $stat[9] && $opt !~/!.*t/i ? 'U'
		:$2 != $crc                       ? 'C'
		:undef;
	if ($tst) {
		if    (($opt =~/!.*c/i) || ($stat[2] & 0040000)) {} # bug in win95 xcopy!
		elsif (eval {FileCopy('-d',$_,$dst)}) {}
		elsif ($opt =~/[^!i]*i/i) {next}
		else  {croak('FileTrack(' .join(', ',@_) ."): $@")}
		$chg =1;
		print TRACK StrTime(), "\t$tst\t$_\t",StrTime($stat[9]),"\t$crc\t$dst/$nme[1]\n";
		$dbm{$_} =$stat[9] ."\t" .$crc;
	}
	if ($stat[2] & 0040000 && $opt !~/!.*r/i) { # no recurse: $_[0]->[2] =0
		$chg =FileTrack($opt, "$src/$nme[1]", "$dst/$nme[1]", $sub) || $chg;
		defined($_) || return(0);
	}
 }
 if (!$lvl) {
	foreach (keys(%dbm)) {
		next if -e $_;
		my ($tme,$crc) =$dbm{$_} !~/^([\d]+)\t([\d]+)$/ ? (0,0) : ($1,$2);
		print TRACK StrTime(), "\tD\t$_\t",StrTime($tme),"\t$crc\n";
		delete($dbm{$_});
	}
	dbmclose(%dbm)
	&& close(TRACK) || croak(($Language =~/ru/i ?'á†™‡Î‚®•' :'Closing')." '$dst/FileTrack': $!");
	return(-d $dst ? $dst : '') if $chg;
 }
 $chg
}, ''}

###
sub FileWrite {
Try eval { local $ErrorDie =2;
 my $opt  =($_[0] =~/^\-/i ? shift : ''); # 'b'inary
 my $file =shift;
 Echo("FileWrite",$file);
 local *OUT;
 open(OUT, ">$file") || croak(($Language =~/ru/i ?'é‚™‡Î‚®•' :'Opening')." '>$file': $!");
 if ($opt=~/b/i) {
	binmode(OUT);
	print(OUT @_) || croak(($Language =~/ru/i ?'á†Ø®·Ï' :'Writing')." '>$file': $!");
 }
 else {
	foreach my $row (@_) {
		!defined($row) || print(OUT $row, "\n") || croak(($Language =~/ru/i ?'á†Ø®·Ï' :'Writing')." '>$file': $!");
	}
 }
 close(OUT) || croak(($Language =~/ru/i ?'á†™‡Î‚®•' :'Closing')." '>$file': $!");
},0}

###
sub FTPCmd {
 my ($host,$usr,$passwd,$cmd);
 if (ref($_[0])) {
	foreach my $k (keys(%{$_[0]})) {
		if    ($k =~/^-*(host|srv|s$)/i)   {$host   =$_[0]->{$k}}
		elsif ($k =~/^-*(user|usr|u$)/i)   {$usr    =$_[0]->{$k}}
		elsif ($k =~/^-*(passwd|psw|p$)/i) {$passwd =$_[0]->{$k}}
	}
	shift;
 }
 else {
	($host,$usr,$passwd,$cmd)=(shift,shift,shift,shift)
 }
 Echo('FTPCmd',$host,$usr,$cmd,@_);
 eval { local $ErrorDie =2;
	my $ftp =eval("use Net::FTP; Net::FTP->new(\$host);") || croak("FTP $host: $@");
	$ftp->login($usr, $passwd) || ($ftp->close, croak("FTP '${usr}\@${host}': $@"));
	if ($cmd =~/^ascii|bin|ebcdic|byte/) {
		$cmd =~s/^bin$/binary/;
		eval("\$ftp->$cmd") || ($ftp->close, croak("FTP ${usr}\@${host} $cmd: $@"));
		$cmd =shift;
	}
	my @ret = ref($cmd) eq 'CODE' ? &$cmd($ftp) : eval("\$ftp->$cmd(\@_)");
	$ftp->close;
	($cmd =~/dir|ls/ ? $@ : !$ret[0]) && croak("FTP ${usr}\@${host} $cmd(".join(', ',@_)."): $@");
 }; if ($@) {@ret =(); TryEnd()}
 $cmd =~/dir|ls/ ? @ret : $ret[0];
}

###
sub GUIMsg {
Try eval { local $ErrorDie =2;
 my $title = @_ >1 ? shift : '';
 return(0) if !$Interact;
 if (!$GUI) {map {Echo($_)} CPTranslate('ansi','oem',@_); return(Pause())};
 my $eu =($] >=5.008) && !eval('${^ENCODING}') ? eval('use POSIX; POSIX::setlocale(POSIX::LC_CTYPE)=~/\\.([^.]+)$/ ? "cp$1" : undef') : undef;
 $eu && eval("use encoding $eu, STDIN=>undef, STDOUT=>undef");
 eval("use strict; use Tk");
 my $main  = new MainWindow (-title => $title);
 $main->Label(-text => "\n" .join("\n", @_) ."\n"
		,-font => "System"
		)->pack(-fill => 'x');
 $main->Button(-text => ($Language =~/ru/i ?'«‡Í˚Ú¸' :'Close')
		,-font => 'System'
		,-command => sub{$main->destroy}
		)->pack->focus();
 $main->bind('Tk::Button','<Key-Return>'
		,sub{my $r =$main->focusCurrent->cget('-command'); 
			$r =~/array/i ? &{$$r[0]} : &$r });
 $main->bind('<Key-Escape>',sub{$main->destroy});
 $main->bind('<FocusOut>',sub{$main->focusForce});
 $main->grabGlobal;
 $main->focusForce;
 $main->update();
 $main->geometry('+'.int(($main->screenwidth() -$main->width())/2.2) 
		.'+'.int(($main->screenheight() -$main->height())/2.2));
 $eu && eval("no encoding");
 eval("MainLoop()");
},0}

###
sub NetUse {
Try eval { local $ErrorDie =2;
 my ($d)=@_;
 if (!$_[1] || $_[1] =~/^\/d/i) {eval {`net use $d /delete`}; return(1)}
 elsif (!$ENV{OS} || $ENV{OS} =~/Windows_95/i) {return(Run('net','use',@_,'/Yes'))}
 elsif ( $ENV{OS} && $ENV{OS} =~/Windows_NT/i) {
	Echo('net','use',@_); my $r =$_[1];
	if (0 && $d =~/^\w:*$/i && WScript('Network')) {WScript('Network')->RemoveNetworkDrive($d); $r =WScript('Network')->MapNetworkDrive(@_) ? 0 : Win32::OLE->LastError}
	else {eval {`net use $d /delete & net use $d $r 2>&1`}; $r =$?>>8}
	croak(join(' ','net','use',@_).": $r") if $r; return(!$r)
 }
 else {eval {`net use $d /delete`}; Run('net','use',@_)}
},0}

###
sub OLECreate {
Try eval { local $ErrorDie =2;
 eval('use Win32::OLE');
 Win32::OLE->new(@_) ||croak('OLECreate(' .join(' ',@_) .') -> ' .Win32::OLE->LastError());
},undef}

###
sub OLEGet {
Try eval { local $ErrorDie =2;
 eval('use Win32::OLE');
 Win32::OLE->GetObject(@_) ||croak('OLEGet(' .join(' ',@_) .') -> ' .Win32::OLE->LastError());
},undef}

###
sub OLEIn {
 eval('use Win32::OLE'); Win32::OLE::in(ref($_[0]) ? $_[0] : (OLEGet(@_)||OLECreate(@_)));
}

###
sub OrArgs {
 my $s =ref($_[0]) ? shift 
	:index($_[0], '-') ==0 ? eval('sub{' .shift(@_) .' $_}')
	:eval('sub{' .shift(@_) .'($_)}');
 local $_;
 foreach (@_) {return $_ if &$s($_)};
 undef
}

###
sub Pause {
Try eval { local $ErrorDie =2;
 if (@_) {print(join(' ',@_))}
 else    {print(($Language =~/ru/i ?'ç†¶¨®‚•' :'Press')." 'Enter'...")}
 return('') if !$Interact;
 my $r =<STDIN>;
 chomp($r); $r
},''}

###
sub Platform {
Try eval { local $ErrorDie =2;
 if    ($_[0] =~/^os$/i) {
	$ENV{OS}
	? $ENV{OS} 
	: $^O eq 'MSWin32'
	? eval('use Win32::TieRegistry; my $v =$$Registry{\'LMachine\\Software\\Microsoft\\Windows\\CurrentVersion\\\\Version\'}; $v =~s/ /_/ig; $v') || 'Windows_95'
	: $^O  # 'Dos'
 }
 elsif ($_[0] =~/^osname$/i) {
	($^O eq 'MSWin32'
	? eval('use Win32::TieRegistry;$$Registry{\'LMachine\\Software\\Microsoft\\Windows\\CurrentVersion\\\\Version\'}') ||''
	: '')
		|| (`\%COMSPEC\% /c ver` =~/\n*([^\n]+)\n*/i ? $1 : '')
		|| $ENV{OS} || $^O
 }
 elsif ($_[0] =~/^win32$/i) {
	$^O eq 'MSWin32' ? ($ENV{windir} || Platform('windir')) : ''
 }
 elsif ($_[0] =~/^ver/i) {
	my $v =
	($^O eq 'MSWin32'
	? eval('use Win32::TieRegistry; my $v =
		($$Registry{\'LMachine\\Software\\Microsoft\\Windows\\CurrentVersion\\\\VersionNumber\'} || $$Registry{\'LMachine\\Software\\Microsoft\\Windows NT\\CurrentVersion\\\\CurrentVersion\'} || \'\')
		.".".
		($$Registry{\'LMachine\\Software\\Microsoft\\Windows\\CurrentVersion\\\\SubVersionNumber\'} || $$Registry{\'LMachine\\Software\\Microsoft\\Windows NT\\CurrentVersion\\\\CurrentBuildNumber\'} || \'\')
		; $v =~s/ //ig; $v')
	: '')
	|| (`\%COMSPEC\% /c ver` =~/(Version|•‡·®Ô)\s*([^ \]]+)/im ? $2 : '');
	(@_ >1 ? [split(/\./,$v)]->[$_[1]] ||'' : $v);
 }
 elsif ($_[0] =~/^(patch)/i) {
	$^O eq 'MSWin32'
	? eval('use Win32::TieRegistry; $$Registry{\'LMachine\\Software\\Microsoft\\Windows\\CurrentVersion\\\\CSDVersion\'} || $$Registry{\'LMachine\\Software\\Microsoft\\Windows NT\\CurrentVersion\\\\CSDVersion\'}') || ''
	: ''
 }
 elsif ($_[0] =~/^lang$/i) {
	`\%COMSPEC\% /c dir c:\\` =~/·¢Æ°Æ§≠Æ$/i ? 'ru' : '';
 }
 elsif ($_[0] =~/^prodid$/i) {
	$^O eq 'MSWin32'
	? eval('use Win32::TieRegistry;$$Registry{\'LMachine\\Software\\Microsoft\\Windows\\CurrentVersion\\\\ProductId\'} || $$Registry{\'LMachine\\Software\\Microsoft\\Windows NT\\CurrentVersion\\\\ProductId\'}') || ''
	: ''
 }
 elsif ($_[0] =~/^name$/i) {
	$ENV{COMPUTERNAME}
	? lc($ENV{COMPUTERNAME})
	: $^O eq 'MSWin32'
	? eval{Win32::NodeName()} ||lc(eval('use Win32::TieRegistry; $$Registry{\'LMachine\\\\System\\\\CurrentControlSet\\\\Control\\\\ComputerName\\\\ComputerName\\\\\\\\ComputerName\'}'))
	: `net config` =~/(Computer name|äÆ¨ØÏÓ‚•‡)\s*\\*([^ ]+)$/im 
	? lc($2)
	: Platform('host');
 }
 elsif ($_[0] =~/^hostdomain$/i) { # [gethostbyname('')]->[0] =~/[^\.]*\.(.*)/ ? $1 : ''
	eval('use Net::Domain;Net::Domain::hostdomain')
 }
 elsif ($_[0] =~/^host$/i) { # [gethostbyname('')]->[0]
	my $r =eval('use Sys::Hostname;hostname');
	index($r,'.') <0 ? ($r .'.' .eval('use Net::Domain;Net::Domain::hostdomain')) : $r
 }
 elsif ($_[0] =~/^domain|userdomain$/i) {
	$ENV{USERDOMAIN} || ($^O eq 'MSWin32' ? Win32::DomainName() :'')
 }
 elsif ($_[0] =~/^user$/i) {
	getlogin()
	||($^O eq 'MSWin32' ? eval{Win32::LoginName()}
				|| lc(eval("use Win32::TieRegistry; \$\$Registry{'LMachine\\\\System\\\\CurrentControlSet\\\\Control\\\\\\\\Current User'}"))
				|| (`net config` =~/(User name|èÆ´ÏßÆ¢†‚•´Ï)\s*([^ ]+)$/im ? $2 : '')
		: '') 
	||$ENV{USERNAME} ||$ENV{LOGNAME} ||''
 }
 elsif ($_[0] =~/^windir$/i) {
	return $ENV{windir} if $ENV{windir};
	return '' if $^O ne 'MSWin32';
	eval('use Win32::TieRegistry'); 
	$Registry->{'LMachine\\Software\\Microsoft\\Windows NT\\CurrentVersion\\\\SystemRoot'}
	|| $Registry->{'LMachine\\Software\\Microsoft\\Windows\\CurrentVersion\\\\SystemRoot'};
 }
 else {''}
},''}

###
sub Print { 
 if ($Print) {&$Print(@_)}
 else { print(join(' ',@_), "\n");
	print LOG join(' ',StrTime(),@_), "\n" if $FileLog;
 }
}

###
sub Registry {
Try eval { local $ErrorDie =2;
 my $opt =($_[0] =~/^\-/i ? shift : '');
 my $dlm =$opt =~/\-([\|\/\\])/ ? $1 : '\\';
 my $key =shift;
 eval("use Win32::TieRegistry; \$Registry->Delimiter(\$dlm)");
 return ($$Registry{$key}) if @_ ==0;
 my ($type)=@_ >1 ? shift : '';
 return(delete($$Registry{$key})) if @_ >0 && !defined($_[0]);
 my ($val) =@_;
 if ($type && $type !~/^REG_/i && $val =~/^REG_/i) {$val =$type; $type =$_[0]};
 my ($k, $h, $n);
 $k   =rindex($key,"$dlm$dlm");
 if ($k<0) {$k =rindex($key,$dlm); $n =substr($key, $k +1)}
 else      {$n =substr($key, $k +2)}
 $key =substr($key, 0, $k);
 $k   =$key;
 while(!ref($$Registry{$k})) { # while(!$$Registry{$k})) {
	$h ={substr($k, rindex($k,$dlm)+1)=>($h ? $h : {})};
	$k = substr($k, 0, rindex($k,$dlm));
 }
 $$Registry{$k} =$h if $h;
 if ($type)	{$$Registry{$key}->SetValue($n,$val,$type)}
 else		{$$Registry{$key .$dlm .$dlm .$n} =$val}
},''}

###
sub Run {
Try eval { local $ErrorDie =2;
 Echo(@_);  
 if (ref($_[$#_]) eq 'CODE') {
	my $sub =pop;
	local (*OUT, *OLDIN);
	open(OLDIN,'<&STDIN') && pipe(STDIN,OUT) || croak(join(' ',@_) ." : $?");
	FileHandle(\*OUT, sub{$|=1; &$sub()});
	system(@_);
	close(OUT); open(STDIN,'<&OLDIN');
 }
 else {
	system(@_)
 }
 my $r =$?>>8; #($?>>8 || $!);
 croak(join(' ',@_).": $r") if $r;
 !$r
},0}

###
sub RunInf {
Try eval { local $ErrorDie =2;
 my ($f, $s, $b) =@_;
 $s ="DefaultInstall" if !defined($s);
 $b =128 if !defined($b);
 eval("use Win32::TieRegistry");
 my $cmd =$Registry->{"Classes\\inffile\\shell\\Install\\command\\\\"} || 'rundll32.exe setupx.dll,InstallHinfSection DefaultInstall 132 %1';
 $cmd =~s/%SystemRoot%/$ENV{windir}/ if $ENV{windir};
 $cmd =~s/ DefaultInstall / $s /i;
 $cmd =~s/ 132 / $b /i;
 $cmd =~s/%1/$f/i;
 $cmd
},0}

###
sub RunKbd {
Try eval { local $ErrorDie =2;
  eval("use Win32::GuiTest");
  my ($wt,$ws,$kt,$ks) =(60,'',1);
  if    (!defined($_[0]))   {shift; $ws=shift}
  elsif ($_[0] =~/^[\d]+$/) {($wt,$ws) =(shift,shift)}
  else                      {$ws =shift}
  if    (!@_)   {}
  elsif (@_ <2) {$ks =shift}
  else          {($kt,$ks) =(shift,shift)}
  Echo(CPTranslate('ansi','oem','RunKbd',$wt,"'$ws'",$kt,"'" .($ks||'') ."'"));
  if ($ws ne '') {
	my @wnd; 
	for (my $i =0; $i <$wt; $i++) {
		local $^W =0;
		@wnd =();
		@wnd =eval {Win32::GuiTest::FindWindowLike(undef,$ws)};
		last if ((!defined($ks) || $ks ne '') ? @wnd : !@wnd);
		print "." if $Echo && $Interact;
		sleep(1);
	}
	if    ( @wnd && defined($ks) && $ks eq '') {Echo('.timeout'); return 0}
	elsif (!@wnd && defined($ks) && $ks eq '') {Echo('.ok'); return 1}
	elsif ( @wnd >1) {croak("RunKbd: several windows like '" .CPTranslate('ansi','oem',"$ws': " .join("',",map {"$_:'" .Win32::GuiTest::GetWindowText($_)} @wnd)) ."'")}
	elsif (!@wnd)	 {croak("RunKbd: not found " .CPTranslate('ansi','oem',"'$ws'"))};
	Win32::GuiTest::SetFocus($wnd[0]);
	Echo('. ' .$wnd[0] .":'" .CPTranslate('ansi','oem',Win32::GuiTest::GetWindowText($wnd[0])) ."'");
	if (!defined($ks)) {return $wnd[0]}
  }
  sleep($kt);
  !defined($ks) || $ks eq '' || Win32::GuiTest::SendKeys($ks) || 1;
},0}

###
sub SMTPSend {
Try eval { local $ErrorDie =2;
 my $host =shift;
 my $from =$_[0] !~/:/ ? shift : undef;
 my $to   =ref($_[0])  ? shift : undef;
 foreach my $r (@_) {last if $from && $to;
	if	(ref($r))  {$to =$r; $r ='To:'.join(',',@$r)}
	elsif	(!$from && $r=~/^(from|sender):(.*)/i)	{$from =$2}
	elsif	(!$to   && $r=~/^to:(.*)/i)		{$to   =[split /,/,$1]}
 }
 Echo('SMTPSend',"$host, $from -> ".join(',',@$to));
 my $smtp =eval("use Net::SMTP; Net::SMTP->new(\$host)"); 
 $@     && croak($@);
 !$smtp && croak("SMTP Host $host");
 $smtp->mail($from) ||croak("SMTP From: $from");
 $smtp->to(@$to) ||croak("SMTP To: ".join(', ',@$to));
 $smtp->data(join("\n",@_)) ||croak("SMTP Data");
 $smtp->dataend() ||croak("SMTP DataEnd");
 $smtp->quit;
 1
},0}

###
sub StrTime { 
 my $msk =@_ ==0 || $_[0] =~/^\d+$/i ? ($Language =~/ru/i ? 'dd.mm.yy hh:mm:ss' : 'yyyy-mm-dd hh:mm:ss') : shift;
    $msk ='yyyymmddhhmmss' if !$msk;
 my @tme =@_ ==0 ? localtime(time) : @_ ==1 ? localtime($_[0]) : @_;
 $msk =~s/yyyy/sprintf('%04u',$tme[5] +1900)/ie;
 $tme[5] >=100	? $msk =~s/yy/sprintf('%04u',$tme[5] +1900)/ie
		: $msk =~s/yy/sprintf('%02u',$tme[5])/ie;
 $msk =~s/mm/sprintf('%02u',$tme[4]+1)/e;
 $msk =~s/dd/sprintf('%02u',$tme[3])/ie;
 $msk =~s/hh/sprintf('%02u',$tme[2])/ie;
 $msk =~s/mm/sprintf('%02u',$tme[1])/ie;
 $msk =~s/ss/sprintf('%02u',$tme[0])/ie;
 $msk
}

###
sub Try (@) {
 my $ret;
 local ($TrySubject, $TryStage) =('','');
 { local $ErrorDie =2;
	$ret = @_ >1 && ref($_[0]) eq 'CODE' ? eval {&{$_[0]}} : $_[0];
 }
 if   (!$@) {$ret} 
 else {
	my $err =$@ =$Error =$TrySubject .($TryStage eq '' ? '' : ": $TryStage:\n") .$@;
	$ret =ref($_[$#_]) eq 'CODE' ? &{$_[$#_]}() : $_[$#_]; 
	$@ ="$err\n$@" unless $@ eq $err;
	if ($ErrorDie) {$^S || $ErrorDie ==2 ? die($err) : Die($err)}
	elsif ($Echo && ref($_[$#_]) ne 'CODE') {warn("Error: $@")}
	$ret
 }
}

###
sub TryEnd {
 return(0) if !$@ && !@_;
 my $ert =@_;
 my $err =$Error =(@_ ? join(' ',@_) : $@);
 if ($ErrorDie) {$^S || $ErrorDie ==2 ? ($ert ? croak($err) : die($err)) : Die($err)}
 elsif  ($Echo) {$err ="Error: $err"; ($ert ? carp($err) : warn($err))}
 0
}

###
sub TryHdr {
 $TrySubject =$_[0] if defined($_[0]);
 $TryStage   =$_[1] if defined($_[1]);
 $Echo && Print($TrySubject.($TryStage ne '' ? ": $TryStage" : $TryStage)."...");
 ''
}

###
sub UserEnvInit {
Try eval { local $ErrorDie =2;
 return(0) if $^O ne 'MSWin32';
 my $opt =shift || 'nh'; $opt ='nhy' if $opt =~/^y$/i;
 my $os  =Platform('os');

 if ($opt =~/n/i && (lc($os) ne 'windows_nt')){
	foreach my $e (['OS'=>$os],['COMPUTERNAME'=>Platform('name')],['USERNAME'=>Platform('user')]) {
		(!$ENV{$e->[0]} || $opt =~/y/i)  
		&& ($ENV{$e->[0]} =$e->[1])
		&& Run('winset',$e->[0] .'=' .$e->[1])
    }
 }
 return($ENV{USERNAME}) if $opt !~/h/i;

 $os =lc($os);
 my $d = OrArgs('-d',@_,'c:\\Home') ||return(0);
 my $u = $ENV{USERNAME} ||Platform('user');
 my $du= $d .'\\' .ucfirst(lc($u));
 my $dw= OrArgs('-d',"$d\\Work",$d);
 if (!-d $du) {
	FileMkDir($du, 0700) ||return(0);
	if ($os eq 'windows_nt') {
		Run('cacls',$du,'/E','/C','/P',"$ENV{USERDOMAIN}\\$u:F");
		eval('use Win32::FileSecurity');
		my %acl; Win32::FileSecurity::Get($du,\%acl);
		foreach my $k (keys(%acl)) {
		if ($k !~/\\($u|System|—»—“≈Ã¿|Administrator|¿‰ÏËÌËÒÚ‡ÚÓ)/i) 
			{Run('cacls',$du,'/E','/C','/R','"'.($k =~/ [^\\]*\\(.*)/ ? $1 : $k).'"')}
		}
	}
 }
 my $pu= $ENV{USERPROFILE} ||UserPath();
    $pu= eval{Win32::GetShortPathName($pu)} ||$pu;
 return(1) if $opt !~/y/i && (lc($ENV{HOME}||'?') eq lc($pu));
 my $ru='CUser\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\\\\';
 my $rp=$os ne 'windows_nt' && !Registry('LMachine\\Network\\Logon\\\\UserProfiles') ? $dw : $du;
 Registry($ru .'Personal',$rp);
 Registry($ru .'My Pictures',$rp .'\\My Pictures');
 $pu =~s/[\\]/\//g if $os eq 'windows_nt';
 foreach my $e (['HOME'=>$pu], ['HOMEDOCS'=>$rp]) {
	next if lc($ENV{$e->[0]}||'?') eq lc($e->[1]);
	$ENV{$e->[0]} =$e->[1];
	if   ($os eq 'windows_nt'){Run('setx',$e->[0],$e->[1])}
	else {Run('winset',$e->[0] .'=' .$e->[1])}
 }
 1;
},0}

###
sub UserPath {
Try eval { local $ErrorDie =2;
 my ($u,$pd) =($_[0]||'', $_[1]||'');
 if ($^O ne 'MSWin32') {($ENV{HOME} || '') .($pd ? '/' .$pd :'')}
 else {
    my %syn =('application data'=>'AppData'
		,'home'=>'Personal'
		,'start menu\\programs'=>'Programs'
		,'start menu/programs'=>'Programs'
		,'start menu\\programs\\startup'=>'Startup'
		,'start menu/programs/startup'=>'Startup');
	$pd =$syn{lc($pd)} ||$pd;
	eval 'use Win32::TieRegistry';
	my $ha ='LMachine\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders\\\\Common ';
	my $hu =($u =~/^\.*default$/i 
		? 'Users\\.DEFAULT\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders\\\\'
		: 'CUser\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders\\\\');
	my $e  =(!defined($pd) || $pd eq '') ? ($pd ='Desktop') : 0;
	my $r  =($u =~/^all$/i 
		? $Registry->{$ha .$pd} ||$Registry->{$hu .$pd}
		: $Registry->{$hu .$pd}
			|| ($u =~/^\.*default$/i && lc($pd) eq 'start menu' 
				? $Registry->{$hu .($e =$pd ='Programs')} : '')
			|| $Registry->{$ha .$pd});
	$r =~s/\s*$//i;
	!$e ? $r : $r =~/^(.*)[\\\/][^\\\/]*$/i ? $1 : '';
 }
},''}

###
sub WMIService {
Try eval { local $ErrorDie =2;
 my $h =OLECreate('WbemScripting.SWbemLocator');
 $h->ConnectServer(@_)
},undef}

###
sub WScript {
Try eval { local $ErrorDie =2;
 my $u =!defined($_[0]) ? shift : 1;
 my $n =shift;
 return($WScript{$n}) if $u && exists($WScript{$n});
 $WScript{$n} =undef  if $u;
 my $o =OLECreate(($n eq 'FSO' ? 'Scripting.FileSystemObject' : "WScript.$n"), @_);
 $u ? ($WScript{$n} =$o) : $o;
},undef}

