require DBI;

package DBD::WTSprite;

use strict;
#use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw($VERSION $err $errstr $state $sqlstate $drh $i $j $dbcnt);

#require Exporter;

#@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
#@EXPORT = qw(
	
#);
$VERSION = '0.30';

# Preloaded methods go here.(WEBTOOLS)
$DBD::WTSprite::WTSprite_global_db_handler = 0;
%DBD::WTSprite::WTSprite_global_MAX_VAL = ();

$err = 0;	# holds error code   for DBI::err
$errstr = '';	# holds error string for DBI::errstr
$sqlstate = '';
$drh = undef;	# holds driver handle once initialised

sub driver{
    return $drh if $drh;
    my($class, $attr) = @_;

    $class .= "::dr";

    # not a 'my' since we use it above to prevent multiple drivers
    $drh = DBI::_new_drh($class, { 'Name' => 'Sprite',
				   'Version' => $VERSION,
				   'Err'    => \$DBD::WTSprite::err,
				   'Errstr' => \$DBD::WTSprite::errstr,
				   'State' => \$DBD::WTSprite::state,
				   'Attribution' => 'DBD::WTSprite by Shishir Gurdavaram & Jim Turner',
				 });
    $drh;
}

sub DESTROY   #ADDED 20001108
{
}

#sub AUTOLOAD {
#	print "***** AUTOLOAD CALLED! *****\n";
#}

1;


package DBD::WTSprite::dr; # ====== DRIVER ======
use strict;
use vars qw($imp_data_size);

$DBD::WTSprite::dr::imp_data_size = 0;

sub connect {
    my($drh, $dbname, $dbuser, $dbpswd, $attr, $old_driver, $connect_meth) = @_;
    my($port);
    my($cWarn, $i, $j);
    # Avoid warnings for undefined values
    $dbuser ||= '';
    $dbpswd ||= '';
    %DBD::WTSprite::WTSprite_global_MAX_VAL = (); # (WEBTOOLS)
    # create a 'blank' dbh
    my($privateattr) = {
		'Name' => $dbname,
		'user' => $dbuser,
		'dbpswd' => $dbpswd
    };
    #if (!defined($this = DBI::_new_dbh($drh, {
    my $this = DBI::_new_dbh($drh, {
    		'Name' => $dbname,
    		'USER' => $dbuser,
    		'CURRENT_USER' => $dbuser,
    });
    
    # Call Sprite Connect function
    # and populate internal handle data.
	if ($this)   #ADDED 20010226 TO FIX BAD ERROR MESSAGE HANDLING IF INVALID UN/PW ENTERED.
	{
		$ENV{SPRITE_HOME} ||= '';
		unless (open(DBFILE, "<$ENV{SPRITE_HOME}/${dbname}.sdb"))
		{
			unless (open(DBFILE, "<${dbname}.sdb"))
			{
				unless (open(DBFILE, "<$ENV{HOME}/${dbname}.sdb"))
				{
					DBI::set_err($drh, -1, "No such database ($dbname)!");
					return undef;
				}
			}
		}
		my (@dbinputs) = <DBFILE>;
		foreach $i (0..$#dbinputs)
		{
			chomp ($dbinputs[$i]);
		}
		my ($inputcnt) = $#dbinputs;
		my ($dfltattrs, %dfltattr);
		for ($i=0;$i<=$inputcnt;$i+=5)  #SHIFT OFF LINES UNTIL RIGHT USER FOUND.
		{
			last  if ($dbinputs[1] eq $dbuser);
			if ($dbinputs[1] =~ s/^$dbuser\:(.*)/$dbuser/)
			{
				$dfltattrs = $1;
				eval "\%dfltattr = ($dfltattrs)";
				foreach my $j (keys %dfltattr)
				{
					$attr->{$j} = $dfltattr{$j};
				}
				last;
			}
			for ($j=0;$j<=4;$j++)
			{
				shift (@dbinputs);
			}
		}
		if ($dbinputs[1] eq $dbuser)
		{
			#if ($dbinputs[2] eq crypt($dbpswd, substr($dbuser,0,2)))
			my ($crypted);
			eval { $crypted = crypt($dbpswd, substr($dbuser,0,2)); };
			if ($dbinputs[2] eq $crypted || $@ =~ /excessive paranoia/)
			{
				++$DBD::WTSprite::dbcnt;
				$this->STORE('sprite_dbname',$dbname);
				$this->STORE('sprite_dbuser',$dbuser);
				$this->STORE('sprite_dbpswd',$dbpswd);
				close (DBFILE);
				#$this->STORE('sprite_autocommit',0);  #CHGD TO NEXT 20010912.
				$this->STORE('sprite_autocommit',($attr->{AutoCommit} || 0));
				$this->STORE('sprite_SpritesOpen',{});
				my ($t) = $dbinputs[0];
				$t =~ s#(.*)/.*#$1#;
				if ($dbinputs[0] =~ /(.*)(\..*)/)
				{
					$this->STORE('sprite_dbdir', $t);
					$this->STORE('sprite_dbext', $2);
				}
				else
				{
					$this->STORE('sprite_dbdir', $dbinputs[0]);
					$this->STORE('sprite_dbext', '.stb');
				}
				for (my $i=0;$i<=$#dbinputs;$i++)
				{
					$dbinputs[$i] =~ /^(.*)$/;
					$dbinputs[$i] = $1;
				}
				$this->STORE('sprite_dbfdelim', eval("return(\"$dbinputs[3]\");") || '::');
				$this->STORE('sprite_dbrdelim', eval("return(\"$dbinputs[4]\");") || "\n");
				$this->STORE('sprite_attrhref', $attr);
				$this->STORE('AutoCommit', ($attr->{AutoCommit} || 0));

				#NOTE:  "PrintError" and "AutoCommit" are ON by DEFAULT!
				#I KNOW OF NO WAY TO DETECT WHETHER AUTOCOMMIT IS SET BY 
				#DEFAULT OR BY USER IN "AutoCommit => 1", THEREFORE I CAN'T 
				#FORCE THE DEFAULT TO ZERO.  JWT
                                $DBD::WTSprite::WTSprite_global_db_handler = $this; # (WEBTOOLS)
				return $this;
			}
		}
	}
	close (DBFILE);
	DBI::set_err($drh, -1, "Invalid username/password!");
	return undef;
}

sub data_sources
{
	my ($self) = shift;

	my (@dsources) = ();
	my $path;
	if (defined $ENV{SPRITE_HOME})
	{
		$path = "$ENV{SPRITE_HOME}/*.sdb";
		my $code = "while (my \$i = <$path>)\n";
		$code .= <<'END_CODE';
		{
			chomp ($i);
			push (@dsources,"DBI:WTSprite:$1")  if ($i =~ m#([^\/\.]+)\.sdb$#);
		}
END_CODE
		eval $code;
		$code =~ s/\.sdb([\>\$])/\.SDB$1/g;   #HANDLE WINDOWSEY FILENAMES :(
		eval $code;
	}
	$path = '*.sdb';
	my $code = "while (my \$i = <$path>)\n";
	$code .= <<'END_CODE';
	{
		chomp ($i);
		push (@dsources,"DBI:WTSprite:$1")  if ($i =~ m#([^\/\.]+)\.sdb$#);
	}
END_CODE
	eval $code;
	$code =~ s/\.sdb([\>\$])/\.SDB$1/g;   #HANDLE WINDOWSEY FILENAMES :(
	eval $code;
	unless (@dsources)
	{
		if (defined $ENV{HOME})
		{
			$path = "$ENV{HOME}/*.sdb";
			my $code = "while (my \$i = <$path>)\n";
			$code .= <<'END_CODE';
			{
				chomp ($i);
				push (@dsources,"DBI:WTSprite:$1")  if ($i =~ m#([^\/\.]+)\.sdb$#);
			}
END_CODE
			eval $code;
			$code =~ s/\.sdb([\>\$])/\.SDB$1/g;   #HANDLE WINDOWSEY FILENAMES :(
			eval $code;
		}
	}
	return (@dsources);
}

sub DESTROY
{
    my($drh) = shift;
    
	if ($drh->FETCH('AutoCommit') == 1)
	{
		$drh->STORE('AutoCommit',0);
		$drh->rollback();                #COMMIT IT IF AUTOCOMMIT ON!
		$drh->STORE('AutoCommit',1);
	}
	$drh = undef;
}

sub disconnect_all
{
}

sub admin {                 #I HAVE NO IDEA WHAT THIS DOES!
    my($drh) = shift;
    my($command) = shift;

    my($dbname) = ($command eq 'createdb'  ||  $command eq 'dropdb') ?
			shift : '';
    my($host, $port) = DBD::WTSprite->_OdbcParseHost(shift(@_) || '');
    my($user) = shift || '';
    my($password) = shift || '';

    $drh->func(undef, $command,
	       $dbname || '',
	       $host || '',
	       $port || '',
	       $user, $password, '_admin_internal');
}

1;


package DBD::WTSprite::db; # ====== DATABASE ======
use strict;
use WTJSprite;

$DBD::WTSprite::db::imp_data_size = 0;
use vars qw($imp_data_size);

sub prepare
{
	my ($resptr, $sqlstr, $attribs) = @_;
	local ($_);
	#$sqlstr =~ s/\n/ /g;  #REMOVED 20011107.
	
	DBI::set_err($resptr, 0, '');
	
	my $csr = DBI::_new_sth($resptr, {
		'Statement' => $sqlstr,
	});

	$csr->STORE('sprite_fetchcnt', 0);
	$csr->STORE('sprite_reslinev','');
	#$sqlstr =~ /(into|from|update|table) \s*(\w+)/gi;  #CHANGED 20000831 TO NEXT LINE!
	$sqlstr =~ /(into|from|update|table|sequence)\s+(\w+)/is;
	my ($spritefid) = $2;
	unless ($spritefid)   #NEXT 5 ADDED 20000831!
	{
		DBI::set_err($resptr, -1, "Prepare:(bad sql) Must specify a table name!");
		return undef;
	}
	$spritefid =~ tr/A-Z/a-z/  unless ($resptr->{sprite_attrhref}->{CaseTableNames});
	$csr->STORE('sprite_spritefid', $spritefid);

	#CHECK TO SEE IF A PREVIOUSLY-CLOSED SPRITE OBJECT EXISTS FOR THIS TABLE.
	#IF SET, THE "RECYCLE" OPTION TELLS SPRITE NOT TO RELOAD THE TABLE DATA.
	#THIS IS USEFUL TO SAVE TIME AND MEMORY FOR APPS DOING MULTIPLE 
	#TRANSACTIONS ON SEVERAL LARGE TABLES.
	#RELOADING IS NECESSARY, HOWEVER, IF ANOTHER USER CAN CHANGE THE 
	#DATA SINCE YOUR LAST COMMIT, SO RECYCLE IS OFF BY DEFAULT!
	#THE SPRITE HANDLE AND ALL IT'S BASIC CONFIGURATION IS RECYCLED REGARDLESS.
	
	my ($myspriteref);
	if (ref($resptr->{'sprite_SpritesOpen'}) && ref($resptr->{'sprite_SpritesOpen'}->{$spritefid}))
	{
		$myspriteref = ${$resptr->{'sprite_SpritesOpen'}->{$spritefid}};
		$csr->STORE('sprite_spritedb', ${$resptr->{'sprite_SpritesOpen'}->{$spritefid}});
		$myspriteref->{TYPE} = undef;
		$myspriteref->{NAME} = undef;
		$myspriteref->{PRECISION} = undef;
		$myspriteref->{SCALE} = undef;
	}
	else   #CREATE A NEW SPRITE OBJECT.
	{
		$myspriteref = new WTJSprite(%{$resptr->{sprite_attrhref}});
		unless ($myspriteref)
		{
			DBI::set_err($resptr, -1, "Unable to create WTJSprite handle ($@)!");
			return undef;
		}
		$csr->STORE('sprite_spritedb', $myspriteref);
		my ($openhash) = $resptr->FETCH('sprite_SpritesOpen');
		$openhash->{$spritefid} = \$myspriteref;
		$myspriteref->set_delimiter("-read",$resptr->FETCH('sprite_dbfdelim'));
		$myspriteref->set_delimiter("-write",$resptr->FETCH('sprite_dbfdelim'));
		$myspriteref->set_delimiter("-record",$resptr->FETCH('sprite_dbrdelim'));
		$myspriteref->set_db_dir($resptr->FETCH('sprite_dbdir'));
		$myspriteref->set_db_ext($resptr->FETCH('sprite_dbext'));
		#$myspriteref->set_os("Unix");
		#$myspriteref->{CaseTableNames} = $resptr->{sprite_attrhref}->{CaseTableNames};
		#ABOVE CHANGED TO BELOW(1 LINE) 20001010!
		$myspriteref->{CaseTableNames} = $resptr->{sprite_attrhref}->{sprite_CaseTableNames};
		$myspriteref->{StrictCharComp} = $resptr->{sprite_attrhref}->{sprite_StrictCharComp};
		#DON'T NEED!#$myspriteref->{Crypt} = $resptr->{sprite_attrhref}->{sprite_Crypt};  #ADDED 20020109.
		$myspriteref->{sprite_forcereplace} = $resptr->{sprite_attrhref}->{sprite_forcereplace};  #ADDED 20010912.
		$myspriteref->{dbuser} = $resptr->FETCH('sprite_dbuser');  #ADDED 20011026.
	}
	$myspriteref->{LongTruncOk} = $resptr->FETCH('LongTruncOk');
	my ($silent) = $resptr->FETCH('PrintError');
	$myspriteref->{silent} = ($silent ? 0 : 1);   #ADDED 20000103 TO SUPPRESS "OOPS" MSG ON WEBSITES!

	#SET UP STMT. PARAMETERS.
	
	$csr->STORE('sprite_params', []);
	#$sqlstr =~ s/([\'\"])([^$1]*?)\?([^$1]*?$1)/$1$2\x02\^2jSpR1tE\x02$3/g;  #PROTECT ? IN QUOTES (DATA)!
	#PREV. LINE CHGD TO NEXT 5 20010312 TO FIX!
	$sqlstr =~ s/([\'\"])([^\1]*?)\1/
			my ($quote) = $1;
			my ($str) = $2;
			$str =~ s|\?|\x02\^2jSpR1tE\x02|gs;   #PROTECT COMMAS IN QUOTES.
			"$quote$str$quote"/egs;
	my $num_of_params = ($sqlstr =~ tr/\?//);
	$sqlstr =~ s/\x02\^2jSpR1tE\x02/\?/gs;
	$csr->STORE('NUM_OF_PARAMS', $num_of_params);	
    return ($csr);
}

sub commit
{
	my ($dB) = shift;
	if ($dB->FETCH('AutoCommit') && $dB->FETCH('Warn'))
	{
		warn ('Commit ineffective while AutoCommit is ON!');
		return 1;
	}
	my ($commitResult) = 1;  #ADDED 20000103

	foreach (keys %{$dB->{sprite_SpritesOpen}})
	{
		next  unless (defined($dB->{'sprite_SpritesOpen'}->{$_}));
		next  if (/^(USER|ALL)_TABLES$/i);
		$commitResult = ${$dB->{'sprite_SpritesOpen'}->{$_}}->commit($_);
		return undef  if (!defined($commitResult) || $commitResult <= 0);
	}
	return 1;
}

sub rollback
{
	my ($dB) = shift;

	if (!shift && $dB->FETCH('AutoCommit') && $dB->FETCH('Warn'))
	{
		warn ('Rollback ineffective while AutoCommit is ON!');
		return 1;
	}
	
	foreach (keys %{$dB->{sprite_SpritesOpen}})
	{
		next  unless (defined($dB->{'sprite_SpritesOpen'}->{$_}));
		next  if (/^(USER|ALL)_TABLES$/i);
		${$dB->{'sprite_SpritesOpen'}->{$_}}->rollback($_);
	}
	return 1;
}

sub STORE
{
	my($dbh, $attr, $val) = @_;
	if ($attr eq 'AutoCommit')
	{
		# AutoCommit is currently the only standard attribute we have
		# to consider.

		$dbh->commit()  if ($val == 1 && !$dbh->FETCH('AutoCommit'));
		$dbh->{AutoCommit} = $val;
		return 1;
	}
	if ($attr =~ /^sprite/)
	{
		# Handle only our private attributes here
		# Note that we could trigger arbitrary actions.
		# Ideally we should catch unknown attributes.
		$dbh->{$attr} = $val; # Yes, we are allowed to do this,
		return 1;             # but only for our private attributes
	}
	# Else pass up to DBI to handle for us
	$dbh->SUPER::STORE($attr, $val);
}

sub FETCH
{
	my($dbh, $attr) = @_;
	if ($attr eq 'AutoCommit') { return $dbh->{AutoCommit}; }
	if ($attr =~ /^sprite_/)
	{
		# Handle only our private attributes here
		# Note that we could trigger arbitrary actions.
		return $dbh->{$attr}; # Yes, we are allowed to do this,
			# but only for our private attributes
		return $dbh->{$attr};
	}
	# Else pass up to DBI to handle
	$dbh->SUPER::FETCH($attr);
}

sub disconnect
{
	my ($db) = shift;
	
	DBI::set_err($db, 0, '');
	return (1);   #20000114: MAKE WORK LIKE DBI!
}

sub do
{
	my ($dB, $sqlstr, $attr, @bind_values) = @_;
	my ($csr) = $dB->prepare($sqlstr, $attr) or return undef;

	DBI::set_err($dB, 0, '');
	
	#my $retval = $csr->execute(@bind_values) || undef;
	return ($csr->execute(@bind_values) || undef);
}

sub table_info
{
	my($dbh) = @_;		# XXX add qualification
	my $sth = $dbh->prepare('select TABLE_NAME from USER_TABLES') 
			or return undef;
	$sth->execute or return undef;
	$sth;
}

sub type_info_all  #ADDED 20010312, BORROWED FROM "Oracle.pm".
{
	my ($dbh) = @_;
	my $names =
	{
		TYPE_NAME		=> 0,
				DATA_TYPE		=> 1,
				COLUMN_SIZE		=> 2,
				LITERAL_PREFIX	=> 3,
				LITERAL_SUFFIX	=> 4,
				CREATE_PARAMS		=> 5,
				NULLABLE		=> 6,
				CASE_SENSITIVE	=> 7,
				SEARCHABLE		=> 8,
				UNSIGNED_ATTRIBUTE	=> 9,
				FIXED_PREC_SCALE	=>10,
				AUTO_UNIQUE_VALUE	=>11,
				LOCAL_TYPE_NAME	=>12,
				MINIMUM_SCALE		=>13,
				MAXIMUM_SCALE		=>14,
	}
	;
	# Based on the values from Oracle 8.0.4 ODBC driver
	my $ti = [
	$names,
			[ 'LONG RAW', -4, '2147483647', '\'', '\'', undef, 1, '0', '0',
			undef, '0', undef, undef, undef, undef
	],
			[ 'RAW', -3, 255, '\'', '\'', 'max length', 1, '0', 3,
			undef, '0', undef, undef, undef, undef
	],
			[ 'LONG', -1, '2147483647', '\'', '\'', undef, 1, 1, '0',
			undef, '0', undef, undef, undef, undef
	],
			[ 'CHAR', 1, 255, '\'', '\'', 'max length', 1, 1, 3,
			undef, '0', '0', undef, undef, undef
	],
			[ 'NUMBER', 3, 38, undef, undef, 'precision,scale', 1, '0', 3,
			'0', '0', '0', undef, '0', 38
	],
			[ 'AUTONUMBER', 4, 38, undef, undef, 'precision,scale', 1, '0', 3,
			'0', '0', '0', undef, '0', 38
	],
			[ 'DOUBLE', 8, 15, undef, undef, undef, 1, '0', 3,
			'0', '0', '0', undef, undef, undef
	],
			[ 'DATE', 11, 19, '\'', '\'', undef, 1, '0', 3,
			undef, '0', '0', undef, '0', '0'
			],
			[ 'VARCHAR2', 12, 2000, '\'', '\'', 'max length', 1, 1, 3,
			undef, '0', '0', undef, undef, undef
	]
	];
	return $ti;
}
sub tables   #CONVENIENCE METHOD FOR FETCHING LIST OF TABLES IN THE DATABASE.
{
	my($dbh) = @_;		# XXX add qualification

	my $sth = $dbh->table_info();
	
	return undef  unless ($sth);
	
	my ($row, @tables);
	
	while ($row = $sth->fetchrow_arrayref())
	{
		push (@tables, $row->[0]);
	}
	$sth->finish();
	return undef  unless ($#tables >= 0);
	return (@tables);
}

sub rows
{
	return $DBI::rows;
}

sub DESTROY   #ADDED 20001108 
{
    my($drh) = shift;
    
	if ($drh->FETCH('AutoCommit') == 1)
	{
		$drh->STORE('AutoCommit',0);
		$drh->rollback();                #COMMIT IT IF AUTOCOMMIT ON!
		$drh->STORE('AutoCommit',1);
	}
	$drh = undef;
}

1;


package DBD::WTSprite::st; # ====== STATEMENT ======
use strict;

my (%typehash) = (
	'LONG RAW' => -4,
	'RAW' => -3,
	'LONG' => -1, 
	'CHAR' => 1,
	'NUMBER' => 3,
	'AUTONUMBER' => 4,
	'DOUBLE' => 8,
	'DATE' => 11,
	'VARCHAR' => 12,
	'VARCHAR2' => 12,
	'BOOLEAN' => -7,    #ADDED 20000308!
	'BLOB'	=> 113,     #ADDED 20020110!
	'MEMO'	=> -1,      #ADDED 20020110!
);

$DBD::WTSprite::st::imp_data_size = 0;
use vars qw($imp_data_size *fetch);

sub bind_param
{
	my($sth, $pNum, $val, $attr) = @_;
	my $type = (ref $attr) ? $attr->{TYPE} : $attr;

	if ($type)
	{
		my $dbh = $sth->{Database};
		$val = $dbh->quote($val, $type);
		$val =~ s/^\'//;
		$val =~ s/\'$//;
	}
	my $params = $sth->FETCH('sprite_params');
	$params->[$pNum-1] = $val;

	#${$sth->{bindvars}}[($pNum-1)] = $val;   #FOR SPRITE. #REMOVED 20010312 (LVALUE NOT FOUND ANYWHERE ELSE).

	$sth->STORE('sprite_params', $params);
	return 1;
}

sub execute
{
    my ($sth, @bind_values) = @_;

    my $params = (@bind_values) ?
        \@bind_values : $sth->FETCH('sprite_params');

	for (my $i=0;$i<=$#{$params};$i++)  #ADDED 20000303  FIX QUOTE PROBLEM WITH BINDS.
	{
		$params->[$i] =~ s/\'/\'\'/g;
	}

    my $numParam = $sth->FETCH('NUM_OF_PARAMS');

    if ($params && scalar(@$params) != $numParam)  #CHECK FOR RIGHT # PARAMS.
    {
		DBI::set_err($sth, (scalar(@$params)-$numParam), 
				"..execute: Wrong number of bind variables (".(scalar(@$params)-$numParam)." too many!)");
		return undef;
    }
    my $sqlstr = $sth->{'Statement'};

	#NEXT 8 LINES ADDED 20010911 TO FIX BUG WHEN QUOTED VALUES CONTAIN "?"s.
    $sqlstr =~ s/\\\'/\x02\^3jSpR1tE\x02/gs;      #PROTECT ESCAPED DOUBLE-QUOTES.
    $sqlstr =~ s/\'\'/\x02\^4jSpR1tE\x02/gs;      #PROTECT DOUBLED DOUBLE-QUOTES.
	$sqlstr =~ s/\'([^\']*?)\'/
			my ($str) = $1;
			$str =~ s|\?|\x02\^2jSpR1tE\x02|gs;   #PROTECT QUESTION-MARKS WITHIN QUOTES.
			"'$str'"/egs;
	$sqlstr =~ s/\x02\^4jSpR1tE\x02/\'\'/gs;      #UNPROTECT DOUBLED DOUBLE-QUOTES.
	$sqlstr =~ s/\x02\^3jSpR1tE\x02/\\\'/gs;      #UNPROTECT ESCAPED DOUBLE-QUOTES.

	#CONVERT REMAINING QUESTION-MARKS TO BOUND VALUES.

    for (my $i = 0;  $i < $numParam;  $i++)
    {
		$params->[$i] =~ s/\?/\x02\^2jSpR1tE\x02/gs;   #ADDED 20001023 TO FIX BUG WHEN PARAMETER OTHER THAN LAST CONTAINS A "?"!
        $sqlstr =~ s/\?/"'".$params->[$i]."'"/es;
    }
	$sqlstr =~ s/\x02\^2jSpR1tE\x02/\?/gs;     #ADDED 20001023! - UNPROTECT PROTECTED "?"s.
	my ($spriteref) = $sth->FETCH('sprite_spritedb');

	#CALL WTJSprite TO DO THE SQL!

	my (@resv) = $spriteref->sql($sqlstr);
	#!!! HANDLE SPRITE ERRORS HERE (SEE SPRITE.PM)!!!
	my ($retval) = undef;
	if ($#resv < 0)          #GENERAL ERROR!
	{
		DBI::set_err($sth, ($spriteref->{lasterror} || -601), 
				($spriteref->{lastmsg} || 'Unknown Error!'));
		return $retval;
	}
	elsif ($resv[0])         #NORMAL ACTION IF NON SELECT OR >0 ROWS SELECTED.
	{
		$retval = $resv[0];
		my $dB = $sth->{Database};
		if ($dB->FETCH('AutoCommit') == 1 && $sth->FETCH('Statement') !~ /^\s*select/i)
		{
			$retval = undef  unless ($spriteref->commit());  #ADDED 20010911 TO MAKE AUTOCOMMIT WORK (OOPS :(  )
			#$dB->STORE('AutoCommit',1);  #COMMIT DONE HERE!
		}
	}
	else                     #SELECT SELECTED ZERO RECORDS.
	{
		$resv[0] = $spriteref->{lastmsg};
		DBI::set_err($sth, ($spriteref->{lasterror} || -402), 
				($spriteref->{lastmsg} || 'No matching records found/modified!'));
		#$retval = 'OK';
		$retval = '0E0';
	}
	
	#EVERYTHING WORKED, SO SAVE SPRITE RESULT (# ROWS) AND FETCH FIELD INFO.

	 if ($retval)
	 {
		$sth->{'driver_rows'} = $retval; # number of rows
		$sth->{'sprite_rows'} = $retval; # number of rows
		$sth->STORE('sprite_rows', $retval);
		$sth->STORE('driver_rows', $retval);
	 }
	 else
	 {
		$sth->{'driver_rows'} = 0; # number of rows
		$sth->{'sprite_rows'} = 0; # number of rows
		$sth->STORE('sprite_rows', 0);
		$sth->STORE('driver_rows', 0);
	 }

    #### NOTE #### IF THIS FAILS, IT PROBABLY NEEDS TO BE "sprite_rows"?
    
	shift @resv;   #REMOVE 1ST COLUMN FROM DATA RETURNED (THE SPRITE RESULT).

	my @l = split(/,/,$spriteref->{use_fields});
    $sth->STORE('NUM_OF_FIELDS',($#l+1));
	unless ($spriteref->{TYPE})
	{
		@{$spriteref->{NAME}} = @l;
		for my $i (0..$#l)
		{
			${$spriteref->{TYPE}}[$i] = $typehash{${$spriteref->{types}}{$l[$i]}};
			${$spriteref->{PRECISION}}[$i] = ${$spriteref->{lengths}}{$l[$i]};
			${$spriteref->{SCALE}}[$i] = ${$spriteref->{scales}}{$l[$i]};
			${$spriteref->{NULLABLE}}[$i] = 1;
		}
	}

	#TRANSFER SPRITE'S FIELD DATA TO DBI.
		
    $sth->{'driver_data'} = \@resv;
    $sth->STORE('sprite_data', \@resv);
    #$sth->STORE('sprite_rows', ($#resv+1)); # number of rows
	$sth->{'TYPE'} = \@{$spriteref->{TYPE}};
	$sth->{'NAME'} = \@{$spriteref->{NAME}};
	$sth->{'PRECISION'} = \@{$spriteref->{PRECISION}};
	$sth->{'SCALE'} = \@{$spriteref->{SCALE}};
	$sth->{'NULLABLE'} = \@{$spriteref->{NULLABLE}};
    $sth->STORE('sprite_resv',\@resv);
    return $retval  if ($retval);
    return '0E0'  if (defined $retval);
    return undef;
}

sub fetchrow_arrayref
{
	my($sth) = @_;
	my $data = $sth->FETCH('driver_data');
	my $row = shift @$data;

	return undef  if (!$row);
	my ($longreadlen) = $sth->{Database}->FETCH('LongReadLen');
	if ($longreadlen > 0)
	{
		if ($sth->FETCH('ChopBlanks'))
		{
			for (my $i=0;$i<=$#{$row};$i++)
			{
				if (${$sth->{TYPE}}[$i] < 0)  #LONG, LONG RAW, etc.
				{
					my ($t) = substr($row->[$i],0,$longreadlen);
					return undef  unless (($row->[$i] eq $t) || $sth->{Database}->FETCH('LongTruncOk'));
					$row->[$i] = $t;
				}
			}
			map { $_ =~ s/\s+$//; } @$row;
		}
	}
	else
	{
		if ($sth->FETCH('ChopBlanks'))
		{
			map { $_ =~ s/\s+$//; } @$row;
		}
	}
	
	return $sth->_set_fbav($row);
}

*fetch = \&fetchrow_arrayref; # required alias for fetchrow_arrayref
sub rows
{
	my($sth) = @_;
	return $sth->FETCH('driver_rows') or $sth->FETCH('sprite_rows');
}
#### NOTE #### IF THIS FAILS, IT PROBABLY NEEDS TO BE "sprite_rows"?


sub STORE
{
	my($dbh, $attr, $val) = @_;
	if ($attr eq 'AutoCommit')
	{
		# AutoCommit is currently the only standard attribute we have
		# to consider.
		#if (!$val) { die "Can't disable AutoCommit"; }

		$dbh->{AutoCommit} = $val;
		return 1;
	}
	if ($attr =~ /^sprite/)
	{
		# Handle only our private attributes here
		# Note that we could trigger arbitrary actions.
		# Ideally we should catch unknown attributes.
		$dbh->{$attr} = $val; # Yes, we are allowed to do this,
		return 1;             # but only for our private attributes
	}
	# Else pass up to DBI to handle for us
	eval {$dbh->SUPER::STORE($attr, $val);};
}

sub FETCH
{
	my($dbh, $attr) = @_;
	if ($attr eq 'AutoCommit') { return $dbh->{AutoCommit}; }
	if ($attr =~ /^sprite_/)
	{
		# Handle only our private attributes here
		# Note that we could trigger arbitrary actions.
		return $dbh->{$attr}; # Yes, we are allowed to do this,
			# but only for our private attributes
		return $dbh->{$attr};
	}
	# Else pass up to DBI to handle
	$dbh->SUPER::FETCH($attr);
}

sub DESTROY   #ADDED 20010221
{
}

1;

package DBD::WTSprite; # ====== HAD TO HAVE TO PREVENT MAKE ERROR! ======

1;

__END__

=head1 NAME

     DBD::WTSprite - Perl extension for DBI, providing database emmulation via flat files.  

=head1 AUTHOR

    This module is Copyright (C) 2000 by

		Jim Turner
		
        Email: jim.turner@lmco.com

    All rights reserved.

    You may distribute this module under the terms of either the GNU General
    Public License or the Artistic License, as specified in the Perl README
    file.

	WTJSprite.pm is a derived work by Jim Turner from Sprite.pm, a module 
	written and copyrighted (c) 1995-1998, by Shishir Gurdavaram 
	(shishir@ora.com).

=head1 SYNOPSIS

     use DBI;
     $dbh = DBI->connect("DBI:WTSprite:spritedb",'user','password')
         or die "Cannot connect: " . $DBI::errstr;
     $sth = $dbh->prepare("CREATE TABLE a (id INTEGER, name CHAR(10))")
         or die "Cannot prepare: " . $dbh->errstr();
     $sth->execute() or die "Cannot execute: " . $sth->errstr();
     $sth->finish();
     $dbh->disconnect();

=head1 DESCRIPTION

DBD::WTSprite is a DBI extension module adding database emulation via flat-files 
to Perl's database-independent database interface.  Unlike other DBD::modules, 
DBD::WTSprite does not require you to purchase or obtain a database.  Every 
thing you need to prototype database-independent applications using Perl and 
DBI are included here.  You will, however, probably wish to obtain a real 
database, such as "mysql", for your production and larger data needs.  This 
is because emulating databases and SQL with flat text files gets very slow as 
the size of your "database" grows to a non-trivial size (a few dozen records 
or so per table).  

DBD::WTSprite is built upon an old Perl module called "Sprite", written by 
Shishir Gurdavaram.  This code was used as a starting point.  It was completly 
reworked and many new features were added, producing a module called 
"WTJSprite.pm" (Jim Turner's Sprite).  This was then merged in to DBI::DBD to 
produce what you are installing now.  (DBD::WTSprite).  WTJSprite.pm is included 
in this module as a separate file, and is required.

Many thanks go to Mr. Gurdavaram.

The main advantage of DBD::WTSprite is the ability to develop and test 
prototype applications on personal machines (or other machines which do not 
have an Oracle licence or some other "mainstream" database) before releasing 
them on "production" machines which do have a "real" database.  This can all 
be done with minimal or no changes to your Perl code.

Another advantage of DBD::WTSprite is that you can use Perl's regular 
expressions to search through your data.  Maybe, someday, more "real" 
databases will include this feature too!

DBD::WTSprite provides the ability to emulate basic database tables
and SQL calls via flat-files.  The primary use envisioned
for this to permit website developers who can not afford
to purchase an Oracle licence to prototype and develop Perl 
applications on their own equipment for later hosting at 
larger customer sites where Oracle is used.  :-)

DBD::WTSprite attempts to do things in as database-independent manner as possible, 
but where differences occurr, WTJSprite most closely emmulates Oracle, for 
example "sequences/autonumbering".  WTJSprite uses tiny one-line text files 
called "sequence files" (.seq).  and "seq_file_name.NEXTVAL" function to 
insert into autonumbered fields.  The reason for this is that the Author 
works in an Oracle shop and wrote this module to allow himself to work on 
code on his PC, and machines which did not have Oracle on them, since 
obtaining Oracle licences was sometimes time-consuming.

DBD::WTSprite is similar to DBD::CSV, but differs in the following ways:  

	1) It creates and works on true "databases" with user-ids and passwords, 
	2) The	database author specifies the field delimiters, record delimiters, 
	user, password, table file path, AND extension for each database. 
	3) Transactions (commits and rollbacks) are fully supported! 
	4) Autonumbering and user-defined functions are supported.
	5) You don't need any other modules or databases.  (NO prerequisites 
	except Perl 5 and the DBI module!
	6) Quotes are not used around data.
	7) It is not necessary to call the "$dbh->quote()" method all the time 
	in your sql.
	8) NULL is handled as an empty string.
	9) Users can "register" their own data-conversion functions for use in
	sql.  See "fn_register" method below.

=head1 INSTALLATION

    Installing this module (and the prerequisites from above) is quite
    simple. You just fetch the archive, extract it with

        gzip -cd DBD-Sprite-0.1000.tar.gz | tar xf -

    (this is for Unix users, Windows users would prefer WinZip or something
    similar) and then enter the following:

        cd DBD-Sprite-#.###
        perl Makefile.PL
        make
        make test

    If any tests fail, let me know. Otherwise go on with

        make install

    Note that you almost definitely need root or administrator permissions.
    If you don't have them, read the ExtUtils::MakeMaker man page for
    details on installing in your own directories. the ExtUtils::MakeMaker
    manpage.

	NOTE:  You may also need to copy "makesdb.pl" to /usr/local/bin or 
	somewhere in your path.

=head1 GETTING STARTED:

	1) cd to where you wish to store your database.
	2) run makesdb.pl to create your database, ie.
	
		Database name: mydb
		Database user: me
		User password: mypassword
		Database path: .
		Table file extension (default .stb): 
		Record delimiter (default \n): 
		Field delimiter (default ::): 

		This will create a new database text file (mydb.sdb) in the current 
		directory.  This ascii file contains the information you enterred 
		above.  To add additional user-spaces, simply rerun makesdb.pl with 
		"mydb" as your database name, and enter additional users (name, 
		password, path, extension, and delimiters).  For an example, after 
		running "make test", look at the file "test.sdb".		
		
		When connecting to a Sprite database, Sprite will look in the current 
		directory, then, if specified, the path in the SPRITE_HOME environment 
		variable.

		The database name, user, and password are used in the "db->connect()" 
		method described below.  The "database path" is where your tables will 
		be created and reside.  Table files are ascii text files which will 
		have, by default, the extension ".stb" (Sprite table).  By default, 
		each record will be written to a single line (separated by \n -- 
		Windows users should probably use "\r\n").  Each field datum will be 
		written without quotes separated by the "field delimiter (default: 
		double-colon).  The first line of the table file consists of the 
		a field name, an equal ("=") sign, an asterisk if it is a key field, 
		then the datatype and size.  This information is included for each 
		field and separated by the field separator.  For an example, after 
		running "make test", look at the file "testtable.stb".		

	3) write your script to use DBI, ie:
	
		#!/usr/bin/perl
		use DBI;
		
		$dbh = DBI->connect('DBI:WTSprite:mydb','me','mypassword') || 
				die "Could not connect (".$DBI->err.':'.$DBI->errstr.")!";
		...
		#CREATE A TABLE, INSERT SOME RECORDS, HAVE SOME FUN!
		
	4) get your application working.
	
	5) rehost your application on a "production" machine and change "Sprite" 
	to a DBI driver for a "real" database!

=head1 CREATING AND DROPPING TABLES

    You can create and drop tables with commands like the following:

        $dbh->do("CREATE TABLE $table (id INTEGER, name CHAR(64))");
        $dbh->do("DROP TABLE $table");

    Note that currently only the column names will be stored and no other
    data. Thus all other information including column type (INTEGER or
    CHAR(x), for example), column attributes (NOT NULL, PRIMARY KEY, ...)
    will silently be discarded. This may change in a later release.

    A drop just removes the file without any warning.

    See the DBI(3) manpage for more details.

    Table names cannot be arbitrary, due to restrictions of the SQL syntax.
    I recommend that table names are valid SQL identifiers: The first
    character is alphabetic, followed by an arbitrary number of alphanumeric
    characters. If you want to use other files, the file names must start
    with '/', './' or '../' and they must not contain white space.

=head1 INSERTING, FETCHING AND MODIFYING DATA

    The following examples insert some data in a table and fetch it back:
    First all data in the string:

        $dbh->do("INSERT INTO $table VALUES (1, 'foobar')");

    Note the use of the quote method for escaping the word 'foobar'. Any
    string must be escaped, even if it doesn't contain binary data.

    Next an example using parameters:

        $dbh->do("INSERT INTO $table VALUES (?, ?)", undef,
                 2, "It's a string!");

    To retrieve data, you can use the following:

        my($query) = "SELECT * FROM $table WHERE id > 1 ORDER BY id";
        my($sth) = $dbh->prepare($query);
        $sth->execute();
        while (my $row = $sth->fetchrow_hashref) {
            print("Found result row: id = ", $row->{'id'},
                  ", name = ", $row->{'name'});
        }
        $sth->finish();

    Again, column binding works: The same example again.

        my($query) = "SELECT * FROM $table WHERE id > 1 ORDER BY id";
        my($sth) = $dbh->prepare($query);
        $sth->execute();
        my($id, $name);
        $sth->bind_columns(undef, \$id, \$name);
        while ($sth->fetch) {
            print("Found result row: id = $id, name = $name\n");
        }
        $sth->finish();

    Of course you can even use input parameters. Here's the same example for
    the third time:

        my($query) = "SELECT * FROM $table WHERE id = ?";
        my($sth) = $dbh->prepare($query);
        $sth->bind_columns(undef, \$id, \$name);
        for (my($i) = 1;  $i <= 2;   $i++) {
            $sth->execute($id);
            if ($sth->fetch) {
                print("Found result row: id = $id, name = $name\n");
            }
            $sth->finish();
        }

    See the DBI(3) manpage for details on these methods. See the
    SQL::Statement(3) manpage for details on the WHERE clause.

    Data rows are modified with the UPDATE statement:

        $dbh->do("UPDATE $table SET id = 3 WHERE id = 1");

    Likewise you use the DELETE statement for removing rows:

        $dbh->do("DELETE FROM $table WHERE id > 1");

I<fn_register>

Method takes 2 arguments:  Function name and optionally, a
package name (default is "main").

		$dbh->fn_register ('myfn','mypackage');
  
-or-

		use WTJSprite;
		WTJSprite::fn_register ('myfn',__PACKAGE__);

Then, you could say in sql:

	insert into mytable values (myfn(?))
	
and bind some value to "?", which is passed to "myfn", and the return-value 
is inserted into the database.  You could also say (without binding):

	insert into mytable values (myfn('mystring'))
	
-or (if the function takes a number)-

	select field1, field2 from mytable where field3 = myfn(123) 
	
I<Return Value>

	None

=head1 ERROR HANDLING

    In the above examples we have never cared about return codes. Of course,
    this cannot be recommended. Instead we should have written (for
    example):

        my($query) = "SELECT * FROM $table WHERE id = ?";
        my($sth) = $dbh->prepare($query)
            or die "prepare: " . $dbh->errstr();
        $sth->bind_columns(undef, \$id, \$name)
            or die "bind_columns: " . $dbh->errstr();
        for (my($i) = 1;  $i <= 2;   $i++) {
            $sth->execute($id)
                or die "execute: " . $dbh->errstr();
            if ($sth->fetch) {
                print("Found result row: id = $id, name = $name\n");
            }
        }
        $sth->finish($id)
            or die "finish: " . $dbh->errstr();

    Obviously this is tedious. Fortunately we have DBI's *RaiseError*
    attribute:

        $dbh->{'RaiseError'} = 1;
        $@ = '';
        eval {
            my($query) = "SELECT * FROM $table WHERE id = ?";
            my($sth) = $dbh->prepare($query);
            $sth->bind_columns(undef, \$id, \$name);
            for (my($i) = 1;  $i <= 2;   $i++) {
                $sth->execute($id);
                if ($sth->fetch) {
                    print("Found result row: id = $id, name = $name\n");
                }
            }
            $sth->finish($id);
        };
        if ($@) { die "SQL database error: $@"; }

    This is not only shorter, it even works when using DBI methods within
    subroutines.

=head1 METADATA

    The following attributes are handled by DBI itself and not by DBD::File,
    thus they should all work as expected:  I have only used the last 3.

        Active
        ActiveKids
        CachedKids
        CompatMode             (Not used)
        InactiveDestroy
        Kids
        PrintError
        RaiseError
        Warn

    The following DBI attributes are handled by DBD::WTSprite:

    AutoCommit
        Works

    ChopBlanks
        Should Work

    NUM_OF_FIELDS
        Valid after `$sth->execute'

    NUM_OF_PARAMS
        Valid after `$sth->prepare'

    NAME
        Valid after `$sth->execute'; undef for Non-Select statements.

    NULLABLE
        Not really working. Always returns an array ref of one's, as
        DBD::WTSprite always allows NULL (handled as an empty string). 
        Valid after `$sth->execute'.
        
    PRECISION
   		Works
   		
    SCALE
		Works

    LongReadLen
    		Should work

    LongTruncOk
    		Works

    These attributes and methods are not supported:

        bind_param_inout
        CursorName


    In addition to the DBI attributes, you can use the following dbh
    attributes.  These attributes are read-only after "connect".

    sprite_dbdir
    		Path to tables for database.
    		
	sprite_dbext
		File extension used on table files in the database.
		
	sprite_dbuser
		Current database user.
		
	sprite_dbfdelim
		Field delimiter string in use for the database.
		
	sprite_dbrdelim
		Record delimiter string in use for the database.


	The following are environment variables specifically recognized by Sprite.

	SPRITE_HOME
		Environment variable specifying a path to search for Sprite 
		databases (*.sdb) files.


	The following are Sprite-specific options which can be set when connecting.

	sprite_CaseTableNames
		By default, table names are case-insensitive (as they are in Oracle), 
		to make table names case-sensitive (as in MySql), so that one could 
		have two separate tables such as "test" and "TEST", set this option 
		to 1.

	sprite_StrictCharComp  (NEW!)
		CHAR fields are always right-padded with spaces to fill out 
		the field.  Old (pre 5.17) Sprite behaviour was to require the 
		padding be included in literals used for testing equality in 
		"where" clauses. 	I discovered that Oracle and some other databases 
		do not require this when testing DBIx-Recordset, so Sprite will 
		automatically right-pad literals when testing for equality.  
		To disable this and force the old behavior, set this option to 1.

	
=head1 DRIVER PRIVATE METHODS

    DBI->data_sources()
        The `data_sources' method returns a list of "databases" (.sdb files) 
        found in the current directory and, if specified, the path in 
        the SPRITE_HOME environment variable.
        
    $dbh->tables()
        This method returns a list of table names specified in the current 
        database.
        Example:

            my($dbh) = DBI->connect("DBI:WTSprite:mydatabase",'me','mypswd');
            my(@list) = $dbh->func('tables');

	WTJSprite::fn_register ('myfn',__PACKAGE__);
		This method takes the name of a user-defined data-conversion function 
		for use in SQL commands.  Your function can optionally take arguments, 
		but should return a single number or string.  Unless your function 
		is defined in package "main", you must also specify the package name 
		or "__PACKAGE__" for the current package.  For an example, see the 
		section "INSERTING, FETCHING AND MODIFYING DATA" above or (WTJSprite(3)).
		
=head1 OTHER SUPPORTING UTILITIES

	makesdb.pl
		This utility lets you build new Sprite databases and later add 
		additional user-spaces to them.  Simply cd to the directory where 
		you wish to create / modify a database, and run.  It prompts as 
		follows:
		
		Database name: Enter a 1-word name for your database.
		Database user: Enter a 1-word user-name.
		User password: Enter a 1-word password for this user.
		Database path: Enter a path (no trailing backslash) to store tables.
		Table file extension (default .stb): 
		Record delimiter (default \n): 
		Field delimiter (default ::): 

		The last 6 prompts repeat until you do not enter another user-name 
		allowing you to set up multiple users in a single database.  Each 
		"user" can have it's own separate tables by specifying different 
		paths, file-extensions, password, and delimiters!  You can invoke 
		"makesdb.pl" on an existing database to add new users.  You can 
		edit it with vi to remove users, delete the 5 lines starting with 
		the path for that user.  The file is all text, except for the 
		password, which is encrypted for your protection!
		
=head1 RESTRICTIONS

	Although DBD::WTSprite supports the following datatypes:
		NUMBER FLOAT DOUBLE INT INTEGER NUM CHAR VARCHAR VARCHAR2 
		DATE LONG BLOB and MEMO, there are really only 3 basic datatypes 
		(NUMBER, CHAR, and VARCHAR).  This is because Perl treates 
		everything as simple strings.  The first 5 are all treated as "numbers" 
		by Perl for sorting purposes and the rest as strings.  This is seen 
		when sorting, ie NUMERIC types sort as 1,5,10,40,200, whereas 
		STRING types sort these as 1,10,200,40,5.  CHAR fields are right-
		padded with spaces when stored.  LONG-type fields are subject to 
		truncation by the "LongReadLen" attribute value.

	DBD::WTSprite works with the tieDBI module, if "Sprite => 1" lines are added 
	to the "%CAN_BIND" and "%CAN_BINDSELECT" hashes.  This should not be 
	necessary, and I will investigate when I have time.
	
=head1 TODO
    Extensions of DBD::WTSprite

    Joins
        The current version of the module works with single table SELECTs
        only.  This will be a trick, since the underlying statement object 
        in WTJSprite is bound to a single file, I have some ideas and am 
        starting to seriously look into this.  Stay tuned!

	Additional Oracle-ish functions built-in.  The currently-supported ones 
		are "SYSTIME", "NUM", and "NULL".  "NUM" does nothing, "NULL" returns 
		an empty string.  My first will probably be "TO_DATE".
	
	Whatever Mr. Gurdavaram might wish to add.
	
=head1 KNOWN BUGS
    *       The module is using flock() internally. However, this function is
            not available on platforms. Using flock() is disabled on MacOS
            and Windows 95: There's no locking at all (perhaps not so
            important on these operating systems, as they are for single
            users anyways).


=head1 SEE ALSO

	WTJSprite(3), DBI(3), perl(1)

=cut
