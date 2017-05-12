#!/usr/bin/perl
eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 8

use Getopt::Std;
use File::Basename;
use DBI;
use XML::Parser;
use XML::Writer;

use blx::xsdsql::ut::ut qw(nvl ev);
use blx::xsdsql::xsd_parser;
use blx::xsdsql::schema_repository;
use blx::xsdsql::connection;
use blx::xsdsql::xml;

my %Opt=();


use constant {
		COMMON_HELP1 =>
q(
	-d - set the debug mode
	-c <connstr> - connect string to database - the default is the value of the env var DB_CONNECT_STRING
		otherwise is an error
		the form is  [<output_namespace>::]<dbtype>:<user>/<password>@<dbname>[:hostname[:port]][;<attribute>[,<attribute>...]
		<output_namespace>::<dbtype> - see the output of namespaces command 
			the default for <output_namespace> is 'sql'
		<dbname> - database name 
		<hostname> - remote host name or ip address 
		<port> - remote host port
		<attribute> - extra attribute
		Examples: 
			sql::pg:user/pwd@mydb:127.0.0.1;RaiseError => 1,AutoCommit => 0,pg_enable_utf8 => 1
			sql::mysql:user/pwd@mydb:127.0.0.1;RaiseError => 1,AutoCommit => 0,mysql_enable_utf8 => 1
			sql::oracle:user/pwd@orcl:neutrino:1522;RaiseError => 1,AutoCommit => 0
			sql::DBM:dbm_mldbm=Storable;RaiseError => 1,f_dir=> q(/tmp)
	-t <c|r> - issue a commit or rollback at the end  (default commit)
	-i ignore errors (return 0 if exists errors)
)
		,COMMON_OPTIONS1 => 'hdc:t:i' 
		,	HELP_ORDER	=> [qw(
						instruction
						namespaces 
						catalog_names 
						xml_names
						drop_repository
						create_repository
						drop_catalog
						create_catalog
						drop_catalog_views
						create_catalog_views
						store_xml
						put_xml
						exec
					)]
};

my %Help=(
	instruction		=> {
		options => ''
		,s		=> 
					q[
						instruction
							execute perl instruction
					
					
					]
					
	}
	,namespaces => {
		options => ''
		,s		=> 
					q[
						namespaces
							display on stdout the namespaces (type+db) implemented (Ex: sql::pg)
					]
	}
	,catalog_names	=> { 
		options => ''
		,s		=> 
					q(
						catalog_names <options>
							display on stdout the schema catalogs stored into repository		
						<options>
						%opt
					)					
	}
	,xml_names		=> {
		options		=> ''
		,s			=> 
					q(
						xml_names <options> [<catalog_name>..]
							display on stdout the xml names stored into repository
						<options>
							%opt
						<arguments>
							<catalog_name> - a name unique into the repository 
											if is not specify display the objects names of all catalogs 
					)
	
	}
	,drop_catalog	=>	{
		options	=> 'S'
		,s		=>
					q(
						drop_catalog <options> <catalog_name>....
							drop the objects associated to a catalog
						<options>
							%opt
							-S - not drop objects but emit on stdout the sql commands
						<arguments>
							<catalog_name> - a name unique into the repository
					)
	}
	,drop_repository	=> {
		options	=> 'S'
		,s		=>
					q[
						drop_repository <options>
							drop the entire repository (dictionary and catalog objects)
						<options>
							%opt
							-S - not drop objects but emit on stdout the sql commands
					]
	}
	,drop_catalog_views			=> {
		options	=> 'S'
		,s		=>
					q(
						drop_catalog_views <options> <catalog_name>...
							drop the views associated to <catalog_name>
						<options>
							%opt
							-S - not drop objects but emit on stdout the sql commands
						<arguments>
							<catalog_name> - a name unique into the repository
					)	
	}
	,create_repository	=> {
		options	=> 'S'
		,s		=> 
					q(
						create_repository <options>
							create repository objects (dictionary)
						<options>
							%opt
							-S - not create objects but emit on stdout the sql commands
					)
	}
	,create_catalog	=> {
		options	=> 'So:'
		,s		=> 
					q(
						create_catalog <options> <catalog_name> <schema_file>
							create the objects associated to a catalog and populate the dictionaries with the <schema_file> 
						<options>
							%opt
							-S - not create objects but emit on stdout the sql commands
							-o <name>=<value>[,<name>=<value>...]
								set extra params - valid names are:
									TABLE_PREFIX		- set the prefix for the tables name (default T<auto sequence number>_)
									VIEW_PREFIX			- set the prefix for views name (default V<auto sequence_number>_)
									NO_FLAT_GROUPS		- no flat the columns of table groups with maxoccurs <= 1 into the ref table
									FORCE_NAMESPACE	    - force the namespace of the schema (valid only if the schema is in the global namespace)
						<arguments>
							<catalog_name> - a name unique into the repository
							<schema_file>  - a file name with contains an xsd schema
				)
	}
	,create_catalog_views	=> {
		options	=> 'Sg:o:'
		,s		=> 
					q(
						create_catalog_views <options> <catalog_name> 
							create the views associated to <catalog_name>
						<options>
							%opt
							-S - not create objects but emit on stdout the sql commands
							-g <table_name>|<xpath_name>[,<table_name>|<xpath_name>...] - generate view starting only from <table_name> (default all tables)
								if the first <table_name>|<xpath_name> begin with comma then <table_name>|<xpath_name> (without comma) is a file name containing a list of <table_name>|<xpath_name>
								the xpath_name must be absolute (starting with /)
							-o <name>=<value>[,<name>=<value>...]
								set extra params - valid names are:
									VIEWS_FROM_LEVEL   - set the start level for generate create/drop the views (the start level is 0 and is the default)
									MAX_VIEW_COLUMNS   -  produce view code only for views with columns number <= <max_view_columns>
										-1 is a system limit (database depend)
										0 is no limit (the default)
									MAX_VIEW_JOINS      -  produce view code only for views with join number <=  <max_view_joins>
										-1 is a system limit (database depend)
										0 is no limit (the default)

						<arguments>
							<catalog_name> - a name unique into the repository
				)
	}
	,store_xml => {
		options	=> 'b:a:'
		,s		=> q[
						store_xml <options> <catalog_name> <name>|<xml_file> <name> ...
							store xml_file into repository
						<options>
							%opt
							-b - set the execute prefix for db objects (Ex.   'scott.' in oracle)
							-a - set the execute suffix for db objects (Ex: '@dblink' in oracle)         
						<arguments>
							<catalog_name>	- a name unique into the repository
							<xml_file>		- a valid xml_file to schemas correspondig <catalog_name>
												if is not specify the <xml_file> is the standard input
							<name>			- a unique name into catalog associated to <xml_file>
					]
	}
	,put_xml	=> {
		options	=> 'rb:a:1x:Ho:'
		,s		=> q[
						put_xml <options> <catalog_name> <name>...
							emit to stdout an xml associated to <name>
							if <name> is specify many the result is an xml concatenation
						<options>
							%opt
							-r - delete <name> after the write
							-b - set the execute prefix for db objects (Ex.   'scott.' in oracle)
							-a - set the execute suffix for db objects (Ex: '@dblink' in oracle)         
							-H - not write header and footer of the xml file
							-1 - test tables row count after a delete 
									this option can be set  only if 'r' option is set
							-x - force the root_tag params in form name=value,...
							-o <filename> - not emit on stdout but on <file_name>
						<arguments>
							<catalog_name>	- a name unique into the repository
							<name>			- a unique name into catalog
					]  
	}
	,exec		=> {
		options	=> COMMON_OPTIONS1.'e:'
		,s		=> q(
						exec <options> [<file_name>]
							execute commands from <file_name>
						<options>
							%opt
							e <prompt> - echo on stderr the <prompt> and command before the execution
						<arguments>
							<file_name> - command file - if it's not specify stdin is assumed
					)
	}	
);

sub argv_parser;

my %CMD=();	
%CMD=(
	instruction    => sub {
		my ($opt,@args)=@_;
		my $cmd=join(" ",@args);
		print STDERR "execute perl instruction '$cmd'\n" if $opt->{d};
		local $@;
		eval($cmd); ## no critic
		if ($@) {
			print STDERR "$@\n";
			return $opt->{i} ? 0 : 1;
		}
		return 0;
	}
	,namespaces => sub {
		my ($opt,@args)=@_;
		print STDERR "(W) namespaces: the argument of this commmad are ignored\n" if scalar(@args);
		print join("\n",blx::xsdsql::schema_repository::get_namespaces),"\n";
		return 0;
	}
	,catalog_names => sub {
		my ($opt,@args)=@_;
		print STDERR "(W) catalog_names: the argument of this commmad are ignored\n" if scalar(@args);
		my $cats=$opt->{repo}->get_catalog_names;
		unless(defined $cats) {
			print STDERR "the repository is not installed\n";
			return $opt->{i} ? 0 : 1;
		}
		for my $name(@$cats) {
			print $name,"\n";
		}
		return 0;
	}
	,xml_names => sub {
		my ($opt,@args)=@_;
		unless ($opt->{repo}->is_repository_installed) {
			print STDERR "the repository is not installed\n";
			return $opt->{i} ? 0 : 1;
		}

		if (scalar(@args)) {
			for my $cat(@args) {
				if (defined (my $catalog=$opt->{repo}->get_catalog($cat))) {				
					for my $r($catalog->get_xml_stored) {
						print join(',',@$r),"\n";
					}
				}
				else {
					print STDERR "$cat: catalog not existent into repository\n";
				}
			}
		}
		else {
			for my $cat($opt->{repo}->get_all_catalogs) {
				for my $r($cat->get_xml_names) {
					print join(',',@$r),"\n";
				}
			}			
		}
		return 0;			
	}
	,drop_repository => sub {
		my ($opt,@args)=@_;
		print STDERR "(W) drop_repository: the argument of this commmad are ignored\n" if scalar(@args);
		if (!$opt->{S} &&  !$opt->{repo}->is_repository_installed) {
			print STDERR "the repository is not installed\n";
			return $opt->{i} ? 0 : 1;
		}
		my $fd=$opt->{S} ? *STDOUT : undef;
		$opt->{repo}->drop_repository(FD => $fd);
		return 0;
	}
	,create_repository => sub {
		my ($opt,@args)=@_;
		print STDERR "(W) create_repository: the argument of this commmad are ignored\n" if scalar(@args);
		if (!$opt->{S} &&  $opt->{repo}->is_repository_installed) {
			print STDERR "the repository is already installed\n";
			return $opt->{i} ? 0 : 1;
		}
		my $fd=$opt->{S} ? *STDOUT : undef;
		$opt->{repo}->create_repository(FD => $fd);
		return 0;
	}
	,drop_catalog => sub {
		my ($opt,@args)=@_;
		my $cats=$opt->{repo}->get_catalog_names;
		unless (defined $cats) {
			print STDERR "the repository is not installed\n";
			return $opt->{i} ? 0 : 1;
		}
		unless (scalar(@args)) {
			print STDERR "no catalog names specify\n";
			return 0;
		}
		my $msgerr=": catalog name not found into repository\n";
		my %cat=map { ($_,undef) } @$cats;
		my @cats=grep(defined $_,map { exists $cat{$_} ? $_ : do { print STDERR "$_$msgerr";undef}} @args);
		my $fd=$opt->{S} ? *STDOUT : undef;
		for my $c(@cats) {
			unless (defined $opt->{repo}->drop_catalog($c,FD => $fd)) {
				if (scalar(keys %cat) == 1) {
					return $opt->{i} ? 0 : 1;
				}
			}
		}
		return 0;
	}
	,create_catalog => sub {
		my ($opt,@args)=@_;
		my $cats=$opt->{repo}->get_catalog_names;
		unless(defined $cats) {
			print STDERR "the repository is not installed\n";
			return $opt->{i} ? 0 : 1;
		}
		if (scalar(@args) == 0) {
			print STDERR "missing <catalog_name> and <schema_file> arguments\n";
			return 1;
		}
		if (scalar(@args) == 1) {
			print STDERR "missing <schema_file> argument\n";
			return 1;
		}
		
		if (scalar(@args) > 3) {
			print STDERR "too many arguments\n";
			return 1;
		}
		
		my ($catalog_name,$schema_file)=@args;
		unless (length($catalog_name)) {
			print STDERR "<catalog_name> must be at length > 0\n";
			return 1;	
		}
		unless (length($schema_file)) {
			print STDERR "<schema_file> must be at length > 0\n";
			return 1;	
		}
				
		my %extra_params=();
		
		if (defined $opt->{o}) {
			my @o=split(',',$opt->{o});
			for my $o(@o) {
				my($k,$v)=$o=~/^([^=]+)=(.+)$/;
				if (defined $k) {
					if (grep($k eq $_,(qw(TABLE_PREFIX VIEW_PREFIX NO_FLAT_GROUPS FORCE_NAMESPACE)))) {
						$extra_params{$k}=$v;
					}
					else {
						print STDERR $opt->{o}.": the key $k in option 'o' is not know\n";
						return 1;
					}
				}
				else {
					print STDERR $opt->{o}.": invalid value for 'o' options\n";
					return 1;				
				}
			}
		}
				
		$extra_params{TABLE_PREFIX}='T'.sprintf("%03d",scalar(@$cats) + 1)
			unless defined $extra_params{TABLE_PREFIX};
		$extra_params{VIEW_PREFIX}='V'.sprintf("%03d",scalar(@$cats) + 1)
			unless defined $extra_params{VIEW_PREFIX};
		$extra_params{NO_FLAT_GROUPS}=0 unless defined $extra_params{NO_FLAT_GROUPS};
		local $_;
		SWITCH:
		for ($extra_params{NO_FLAT_GROUPS}) {
			/^(yes|y|1)$/ && do { $extra_params{NO_FLAT_GROUPS}=1; last SWITCH};
			/^(no|n|0)$/ && do { $extra_params{NO_FLAT_GROUPS}=0; last SWITCH};
			print STDERR $extra_params{NO_FLAT_GROUPS}.": the value of the key NO_FLAT_GROUPS into 'o' option is not valid\n";
			return 1;
		}
		my $parser= blx::xsdsql::xsd_parser->new(
			OUTPUT_NAMESPACE 	=> $opt->{output_namespace}
			,DB_NAMESPACE		=> $opt->{db_namespace}
		);
		my $schema=$parser->parsefile($schema_file,%extra_params);
		my $fd=$opt->{S} ? *STDOUT : undef;
		unless($opt->{repo}->create_catalog($catalog_name,$schema,FD => $fd)) {
			print STDERR "$catalog_name: already exist in the repository\n";
			return $opt->{i} ? 0 : 1;
		}
		return 0;
	}
	,drop_catalog_views => sub {
		my ($opt,@args)=@_;
		my $cats=$opt->{repo}->get_catalog_names;
		unless(defined $cats) {
			print STDERR "the repository is not installed\n";
			return $opt->{i} ? 0 : 1;
		}
		unless (scalar(@args)) {
			print STDERR "no catalog names specify\n";
			return 0;
		}
		my $msgerr=": catalog name not found into repository\n";

		my %cat=map { ($_,undef) } @$cats;
		my @cats=grep(defined $_,map { exists $cat{$_} ? $_ : do { print STDERR "$_$msgerr";undef}} @args);
		my $fd=$opt->{S} ? *STDOUT : undef;
		for my $c(@cats) {
			my $catalog=$opt->{repo}->get_catalog($c);
			unless (defined $catalog) {
				print STDERR $c,$msgerr;
				if (scalar(keys %cat) == 1) {
					return $opt->{i} ? 0 : 1;
				}			
			}
			unless (defined $catalog->drop_views(FD => $fd)) {
				print STDERR $c,$msgerr;
				if (scalar(keys %cat) == 1) {
					return $opt->{i} ? 0 : 1;
				}
			}
		}
		return 0;	
	}
	,create_catalog_views => sub {
		my ($opt,@args)=@_;
		my $cats=$opt->{repo}->get_catalog_names;
		unless(defined $cats) {
			print STDERR "the repository is not installed\n";
			return 1;
		}
		unless ($opt->{repo}->is_support_views) {
			print STDERR "database not support complex views\n";
			return $opt->{i} ? 0 : 1;
		}
		
		unless (scalar(@args)) {
			print STDERR "no catalog names specify\n";
			return 0;
		}
		my $msgerr=": catalog name not found into repository\n";
		my %cat=map { ($_,undef) } @$cats;
		my @cats=grep(defined $_,map { exists $cat{$_} ? $_ : do { print STDERR "$_$msgerr";undef}} @args);

		if (defined (my $t=$opt->{g})) {
			if ($t=~/^,(.*)$/) {  # is a file name
				if (open(my $fd,'<',$1)) {
					my @lines=grep(!/^\s*$/,
						map {  
							my $v=$_;
							$v=~s/^\s*//; 
							$v=~s/\s*$//; 
							my $l=$v=~/^\s*#/ ? '' : $v;
							$l;  
						} <$fd>);
					$Opt{g}=\@lines;
					close $fd;
				}
				else {
					print STDERR "$1: $!\n";
					exit 1;
				}
			}
			else {
				$opt->{g}=[split(",",$t)];
			}
		}
		
		if (defined $opt->{o}) {
			my %h=();
			for my $e(split(",",$opt->{o})) {
				my ($name,$value)=$e=~/^([^=]+)=(.*)$/;
				unless (defined $name) {
					print STDERR $Opt{o},": option o is invalid - valid is <name>=<value>[,<name>=<value>...]\n";
					exit 1;
				}
				$h{$name}=$value;
			}
			my $o_keys= [ qw(MAX_VIEW_COLUMNS MAX_VIEW_JOINS VIEWS_FROM_LEVEL) ];
			for my $k(keys %h) {
				unless (grep($_ eq $k,@$o_keys)) {
					print STDERR "$k: key on 'o' option is not valid - valid keys are ",join(',',@$o_keys),"\n";
					exit 1;
				}
			}
			$opt->{o}=\%h;
		}
		else {
			$opt->{o}={};
		}
		
		
		my $fd=$opt->{S} ? *STDOUT : undef;
		for my $c(@cats) {
			my $catalog=$opt->{repo}->get_catalog($c);
			unless (defined $catalog) {
				print STDERR "$c: catalog not exist in the repository\n";
				return $opt->{i} ? 0 : 1;			
			}
			unless($catalog->create_views(
				 FD 				=> $fd
				,TABLES_FILTER		=> $opt->{g}
				,%{$opt->{o}}				
			)) {
				print STDERR "$c: catalog not exist in the repository\n";
				return $opt->{i} ? 0 : 1;
			}
		}
		return 0;
	}
	,store_xml	=> sub {
		my ($opt,@args)=@_;
		
		my $cats=$opt->{repo}->get_catalog_names;
		unless(defined $cats) {
			print STDERR "the repository is not installed\n";
			return $opt->{i} ? 0 : 1;
		}
		
		if (scalar(@args) == 0) {
			print STDERR "missing <catalog_name> argument\n";
			return 1;
		}
		my $catalog_name=shift @args;
		if (scalar(@args) == 0) {
			print STDERR "missing <name> or <xml_file> <name> argument\n";
			return 1;
		}
		unshift @args,'-' if scalar(@args) == 1;
		if (scalar(@args) % 2 != 0) {
			print STDERR "argument number is not pair\n";
			return 1;
		}
		
		my %args=@args;
		my %names=();
		my %fd=();
		my $err=0;
		my $stdin=undef;
		for my $file_name(keys %args) {
			my $name=$args{$file_name};
			if (length($file_name) == 0) {
				print STDERR "file_name at 0 length not allowed\n";
				$err++;
			}
			if (length($name) == 0) {
				print STDERR "name associated at file_name '$file_name' at 0 length not allowed\n";
				$err++;
			}
			if (defined (my $f=$names{$name})) {
				print STDERR "$name: this name is already associated at file_name '$f'\n";
				$err++;
			}
			else {
				$names{$name}=$file_name;
			}
			if ($file_name eq '-') {
				if (defined $stdin) {
					print STDERR "multiply stdin are not allowed\n";
					$err++;
				}
				else {
					$stdin=$file_name;
					$fd{$name}=*STDIN;
				}
			}
			else {
				unless (-e $file_name) {
					print STDERR "$file_name: no such file_name\n";
					$err++;
				}
				if (-d $file_name) {
					print STDERR "$file_name: is a directory\n";
					$err++;
				}
				unless (-r $file_name) {
					print STDERR "$file_name: is not readable\n";
					$err++;
				}
				if (open(my $fd,'<',$file_name)) {
					$fd{$name}=$fd;
				}
				else {
					print STDERR "$file_name: $!\n";
					$err++;
				}
			}
		}
		
		if ($err) {
			for my $fd(values %fd) {
				close $fd unless $fd eq *STDERR;
			}
			return 1;
		}
		
		my $catalog=$opt->{repo}->get_catalog($catalog_name);
		
		unless (defined $catalog) {
			print STDERR "$catalog_name: catalog not exist in the repository\n";
			for my $fd(values %fd) {
				close $fd unless $fd eq *STDERR;
			}
			return $opt->{i} ? 0 : 1;
		}

		my $catalog_xml=$catalog->get_catalog_xml(
			EXECUTE_OBJECTS_PREFIX		=> $opt->{b} 
			,EXECUTE_OBJECTS_SUFFIX		=> $opt->{a} 
		);
		
		$err=0;
		while(scalar(@args)) {
			my $file_name=shift @args;
			my $name=shift @args;
			my $fd=$fd{$name};
			
			my $id=$catalog_xml->store_xml(
				XML_NAME 			=>  $name
				,FD					=>  $fd
			);
			delete $fd{$name};
			close $fd unless $fd eq *STDIN;
			unless (defined $id) {
				print STDERR "$name: name already existent\n";
				$err++;
			}			
		}
		if ($err) {
			return $opt->{i} ? 0 : 1;
		}
		return 0;		
	}
	,put_xml => sub {
		my ($opt,@args)=@_;
		if ($opt->{1} && !$opt->{r}) {
			print STDERR "for test the delete the option 'r' must be set\n";
			return 1;
		}
		if (scalar(@args) == 0) {
			print STDERR "missing <catalog_name> argument\n";
			return 1;
		}
		unless($opt->{repo}->is_repository_installed) {
			print STDERR "the repository is not installed\n";
			return $opt->{i} ? 0 : 1;
		}
		my $catalog_name=shift @args;
		
		my $catalog=$opt->{repo}->get_catalog($catalog_name);
		
		unless (defined $catalog) {
			print STDERR "$catalog_name: catalog not exist in the repository\n";
			return 1;
		}
		if (scalar(@args) == 0) {
			print STDERR "missing <name>  argument\n";
			return 1;
		}
		if (defined $opt->{x}) {
			my @h=();
			for my $e(split(",",$opt->{x})) {
				my ($name,$value)=$e=~/^([^=]+)=(.*)$/;
				unless (defined $name) {
					print STDERR $Opt{x},": option x is invalid - valid is <name>=<value>[,<name>=<value>...]\n";
					return 1;
				}
				$value=~s/^"([^"]+)"$/$1/;
				push @h,($name,$value);
			}
			$opt->{x}=\@h;
		}

		my $catalog_xml=$catalog->get_catalog_xml(
			WRITER => XML::Writer->new(
						DATA_INDENT => 4
						,DATA_MODE => 1
						,NAMESPACES => 0
						,UNSAFE    => 1
			)
			,EXECUTE_OBJECTS_PREFIX		=> $opt->{b} 
			,EXECUTE_OBJECTS_SUFFIX		=> $opt->{a} 
		);
				
		my ($count_rows,$loop_table_childs,$test_delete)=();
		if ($opt->{1}) { # test delete 
			$count_rows=sub {
				my ($t,$pcount,%params)=@_;
				my $table_name=$t->get_sql_name;
				my $sql="select count(*) from $table_name";
				my $sth=$params{CONN}->prepare($sql) || die "prepare failed\n";
				$sth->execute || die "execute failed\n";
				my $row=$sth->fetchrow_arrayref || die "fetchrow_arrayref failed\n";
				my $c=$row->[0];
				$sth->finish;
				if ($c > 0) {
					print STDERR "table '$table_name'  contains $c rows\n";
					$$pcount++;
				}
				return;
			};

			$loop_table_childs=sub {
				my ($t,$pcount,%params)=@_;
				$count_rows->($t,$pcount,%params);
				for my $child($t->get_child_tables) {
					$loop_table_childs->($child,$pcount,%params);
				}
				return;
			};

			$test_delete=sub {
				my ($schema,$pcount,%params)=@_;						
				for my $t($opt->{repo}->get_dtd_tables) {
					$loop_table_childs->($t,$pcount,%params);
				}
				for my $k(qw(XML_CATALOG XML_ENCODING)) {
					my $t=$opt->{repo}->get_table_from_type(TYPE => $k);
					$loop_table_childs->($t,$pcount,%params);		
				}
				my %types=$schema->get_types_name;
				for my $t(values %types) {
					$loop_table_childs->($t,$pcount,%params);		
				}
				my $root_table=$schema->get_root_table;
				$loop_table_childs->($root_table,$pcount,%params);
				for my $child($schema->get_childs_schema) {
					$test_delete->($child->{SCHEMA},$pcount,%params);
				}
				return;
			};
		}

		if (defined (my $outfile=delete $opt->{o})) {
			if ($outfile eq '-') {
				$opt->{o}=*STDOUT;
			}
			else {
				unless(open($opt->{o},'>',$outfile)) {
					print STDERR $opt->{o}." open error: $!\n";
					return 1;
				}
			}
		}
		else {
			$opt->{o}=*STDOUT;
		}		
		
		for my $i(0..scalar(@args) - 1) {
			my $name=$args[$i];
			my $id=$catalog_xml->put_xml(
					XML_NAME			=> $name
					,NO_WRITE_HEADER	=> $opt->{H} ? 1 : $i ? 1 : 0
					,NO_WRITE_FOOTER	=> $opt->{H} ? 1 : $i == scalar(@args) - 1 ? 0 : 1
					,FD					=> $opt->{o}
					,ROOT_TAG_PARAMS	=> $opt->{x}
					,DELETE				=> $opt->{r}
			);
			unless (defined $id) {
				print STDERR "$name: not found into repository\n";
				close $opt->{o} unless $opt->{o} eq *STDOUT;
				return $opt->{i} ? 0 : 1;
			}
			
			if ($opt->{1}) {
				print STDERR "test delete... \n" if $opt->{d};
				my $count=0;
				my $schema=$catalog->get_attrs_value(qw(SCHEMA));
				$test_delete->($schema,\$count,CONN => $opt->{conn});
				if ($count > 0) {
					print STDERR "delete test failed - $count tables has rows\n";
					close $opt->{o} unless $opt->{o} eq *STDOUT;
					return 1;
				}
			}
		}
		if ($opt->{r}) {
			for my $i(0..scalar(@args) - 1) {
				my $name=$args[$i];
				print STDERR "$name: delete from the repository\n";
			}
		}
		close $opt->{o} unless $opt->{o} eq *STDOUT;
		return 0;
	}

	,exec => sub {
		my ($opt,@args)=@_;
		my $file_name=shift @args;
		if (scalar(@args)) {
			print STDERR "(W) extra arguments are ignored\n"; 
		}
		$file_name=undef if defined $file_name && $file_name eq '-';
		my $fd=undef;
		if (defined $file_name) {
			unless (open($fd,'<',$file_name)) {
				print STDERR "$file_name: $!\n";
				return 1;
			}
		}
		else {
			$fd=*STDIN;
		}
		
		my @cmds=grep($_ ne 'exec',@{&HELP_ORDER});
		while(<$fd>) {
			@ARGV=argv_parser($_);
			my $cmd_str=defined $opt->{e} ? join(' ',@ARGV) : undef;
			my $cmd=shift @ARGV;
			unless (defined $cmd) {
				print STDERR "no command specify\n";
				print STDERR  "\tvalid <cmd> is any of ".join("|",@cmds),"\n";
				return 1 unless $opt->{i};
				next;
			}
			if (!grep($cmd eq $_,@cmds)) {
				print STDERR "$cmd: invalid command\n";
				print STDERR  "\tvalid <cmd> is any of ".join("|",@cmds),"\n";
				return 1 unless $opt->{i};
				next;
			}
			my $pcmd=$CMD{$cmd};
			unless (defined $pcmd) {
				print STDERR "$cmd: the command is not implemented\n";
				return 1 unless $opt->{i};
				next;
			}
			my $stroptions=$cmd eq 'namespaces' ? '' : COMMON_OPTIONS1.($Help{$cmd}->{options});
			my %opt=();
			unless (getopts ($stroptions,\%opt)) {
				print STDERR "invalid option or option not set - use h options for help\n";
				return 1;
			}
			if ($opt{h}) {
				my $text=$Help{$cmd}->{s};
				my $ch=COMMON_HELP1;
				$text=~s/\%opt/$ch/;
				print STDOUT join("\n",map {
							my $v=$_;
							$v=~s/^\t{6}//; 
							$v=~s/\t/    /g; 
							$v} grep(!/^\s*$/,split("\n",$text))),"\n";
				return 0;
			}
			for my $k(keys %$opt) { #merge opt
				$opt{$k}=$opt->{$k};
			}
			print STDERR $opt->{e},$cmd_str,"\n" if $opt->{e};
			my $rc=$pcmd->(\%opt,@ARGV);
			if ($rc) {
				return $rc unless $opt->{i};
				next;
			}
		}
		return 0;
	}
);

sub argv_parser {
	my $line=join('',grep(defined $_,@_));
	my @args=();
	my $quote=undef;
	my $str='';
	my @l=split('',$line);
	for my $i(0..scalar(@l) - 1) {
		my $c=$l[$i];
		if (defined $quote) {
			if ($c eq $quote) {
				my $succ=$i == scalar(@l) - 1 ? undef : $l[$i + 1];
				$quote=undef;
				$c='' if defined $succ && $succ!~/^\s$/;
			}
			$str.=$c;
		}
		else {
			if ($c  eq "'" || $c eq '"') {
				my $pred=$i == 0 ? undef : $l[$i - 1];
				$quote=$c;
				$c='' if defined $pred && $pred!~/^\s$/;
				$str.=$c;
			}
			elsif ($c =~/^\s$/) {
				if (length($str)) {
					my $ch=substr($str,0,1);
					if ($ch eq  "'" || $ch eq '"') {
						$str=substr($str,1);
						$str=substr($str,0,length($str) - 1) if length($str) && substr($str,-1,1) eq $ch;
					}
					push @args,$str;
					$str='';
				}
			}
			else {
				$str.=$c;
			}
		}
	}
	if (length($str)) {
		my $ch=substr($str,0,1);
		if ($ch eq  "'" || $ch eq '"') {
			$str=substr($str,1);
			$str=substr($str,0,length($str) - 1) if length($str) && substr($str,-1,1) eq $ch;
		}
		push @args,$str;
	}
	return @args;
}

sub get_dbconn_cs {
	my ($connstr,%params)=@_;
	$connstr=$ENV{DB_CONNECT_STRING} unless defined $connstr;
	unless (defined $connstr) {
		print STDERR "no connection string specify - set the option 'c' or define the env var DB_CONNECT_STRING\n";
		return ();
	}

	my $connection=blx::xsdsql::connection->new;
	unless ($connection->do_connection_list($connstr)) {
		print STDERR $connection->get_last_error,"\n";
		return ();
	}
	my @a=$connection->get_connection_list;
	return ( { 
				OUTPUT_NAMESPACE => $connection->get_output_namespace
				,DB_NAMESPACE	 => $connection->get_db_namespace
			 },@a
	);
}


#### main #####


unless (getopts ('h',\%Opt)) {
	print STDERR "invalid option or option not set - user h options for help\n";
	exit 1;
}


if ($Opt{h}) {
	my $pn=basename($0);
	for my $cmd(@{&HELP_ORDER}) {
		my $text=$Help{$cmd}->{s};
		my $ch=COMMON_HELP1;
		$text=~s/\%opt/$ch/;
		print STDOUT $pn.' '.join("\n",map {
								my $v=$_;
								$v=~s/^\t{6}//; 
								$v=~s/\t/    /g; 
								$v } grep(!/^\s*$/,split("\n",$text)));
		print STDOUT "\n\n";
	}
	exit 0;
}
	
unless (scalar(@ARGV)) {
	my $pn=basename($0);
	print STDERR "use $pn -h or $pn <command> -h  for help\n";
	print STDERR  "\t<cmd> is any of ".join("|",@{&HELP_ORDER}),"\n";
	exit 1;
}

my $cmd=shift @ARGV;
unless (defined $cmd) {
	print STDERR "no command specify\n";
	print STDERR  "\tvalid <cmd> is any of ".join("|",@{&HELP_ORDER}),"\n";
	exit 1;
}

if (!grep($cmd eq $_,@{&HELP_ORDER})) {
	print STDERR "$cmd: invalid command\n";
	print STDERR  "\tvalid <cmd> is any of ".join("|",@{&HELP_ORDER}),"\n";
	exit 1;
}

my $pcmd=$CMD{$cmd};
unless (defined $pcmd) {
	print STDERR "$cmd: the command is not know\n";
	exit 1;
}
my $stroptions=$cmd eq 'namespaces' ? '' : COMMON_OPTIONS1.($Help{$cmd}->{options});
unless (getopts ($stroptions,\%Opt)) {
	print STDERR "invalid option or option not set - use h options for help\n";
	exit 1;
}
if ($Opt{h}) {
	my $text=$Help{$cmd}->{s};
	my $ch=COMMON_HELP1;
	$text=~s/\%opt/$ch/;
	print STDOUT join("\n",map {
							my $v=$_;
							$v=~s/^\t{6}//; 
							$v=~s/\t/    /g; 
							$v } grep(!/^\s*$/,split("\n",$text))),"\n";
	exit 0;
}

if (grep($cmd eq $_,qw(namespaces instruction))) {
	exit $pcmd->(\%Opt,@ARGV);
}

$Opt{t}='c' unless defined $Opt{t};
if ($Opt{t} ne 'c' && $Opt{t} ne 'r') {
	print STDERR $Opt{t}.": invalid value for option 't' - corrected values are 'c' or 'r'\n";
	exit 1;
}
my ($ns,@conn)=get_dbconn_cs($Opt{c});
exit 1 unless defined $ns;
$Opt{output_namespace}=$ns->{OUTPUT_NAMESPACE};
$Opt{db_namespace}=$ns->{DB_NAMESPACE};


$Opt{conn}=eval { DBI->connect(@conn) };
if ($@ || !defined $Opt{conn}) {
	print STDERR $@ if $@;
	print STDERR "connection failed\n";
	exit 1;
}

$Opt{repo}=blx::xsdsql::schema_repository->new(
		DB_CONN 			=> $Opt{conn}
		,OUTPUT_NAMESPACE	=> $Opt{output_namespace}
		,DB_NAMESPACE		=> $Opt{db_namespace}
		,DEBUG				=> $Opt{d}
);

my $rc=eval { $pcmd->(\%Opt,@ARGV); };
if ($@) {
	print STDERR $@;
	$rc=127;
}

unless ($Opt{conn}->{AutoCommit}) {
	$Opt{t}='r' if $rc;

	if ($Opt{t} eq 'c') {
		$Opt{conn}->commit
	}
	else {
		print STDERR "(W) ROOLBACK issued\n";
		$Opt{conn}->rollback;
	}
}

$Opt{conn}->disconnect;
exit $rc;
__END__

=head1 NAME xml_repo.pl

=cut


=head1 VERSION

0.10.0

=cut



=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL

=cut



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>


=cut


=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
