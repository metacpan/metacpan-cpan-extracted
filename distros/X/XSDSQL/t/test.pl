#!/usr/bin/perl

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use Getopt::Std;
use File::Spec::Functions;
use File::Basename;
use DBI;
use XML::Writer;


use blx::xsdsql::connection;
use blx::xsdsql::schema_repository;
use blx::xsdsql::xml;
use blx::xsdsql::ut::fake_ansicolor;


use constant {
	DIR_PREFIX				=> 'xml_'
	,STEP_FILE_PREFIX		=> '.step_'
	,CUST_PARAMS_FILE		=> 'custom_params'
	,PERL					=> $ENV{PERL} // 'perl'
};

my %Opt=();

sub abort {
	my $conn=shift;
	print STDERR join('',@_),"\n" if scalar(@_);
	if (defined $conn) {
		unless ($conn->{AutoCommit}) {
			print STDERR "(W) ROLLBACK issue for abort\n";
			$conn->rollback;
		}
		$conn->disconnect;
	}
	exit 1;
}

sub debug {
	my ($n,@l)=@_;
	$n='<undef>' unless defined $n; 
	print STDERR 'test (D ',$n,'): ',join(' ',grep(defined $_,@l)),"\n"; 
	undef;
}
sub count_rows {
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
}

sub loop_table_childs {
	my ($t,$pcount,%params)=@_;
	count_rows($t,$pcount,%params);
	for my $child($t->get_child_tables) {
		loop_table_childs($child,$pcount,%params);
	}
	return;
}

sub test_delete {
	my ($schema,$pcount,%params)=@_;
	
	for my $t($params{REPO}->get_dtd_tables) {
		loop_table_childs($t,$pcount,%params);
	}
	
	for my $k(qw(XML_CATALOG XML_ENCODING)) {
		my $t=$params{REPO}->get_table_from_type(TYPE => $k);
		loop_table_childs($t,$pcount,%params);		
	}

	my %types=$schema->get_types_name;
	for my $t(values %types) {
		loop_table_childs($t,$pcount,%params);		
	}
	
	my $root_table=$schema->get_root_table;
	loop_table_childs($root_table,$pcount,%params);
	
	for my $child($schema->get_childs_schema) {
		test_delete($child->{SCHEMA},$pcount,%params);
	}
	
	return;
}

sub get_xml_files {
	my %p=@_;
	my @xml=();
	if  (opendir(my $fd,$p{DIR})) {
		while(my $f=readdir($fd)) {
			next if $f=~/^\./;
			next if -d $f;
			next unless $f=~/\.xml$/i;
			if (defined (my $a=$p{ONLY_FILES})) {
				next unless grep($_ eq $f,@$a);
			}
			my $xml=catfile($p{DIR},$f);
			next unless -r $xml;
			my $cmd=$p{XML_VALIDATOR};
			my $schema=$p{SCHEMA_FILE};
			$cmd=~s/\%s/$schema/g;
			$cmd=~s/\%f/$xml/g;
			debug(__LINE__,$cmd) if $p{DEBUG};
			system($cmd);
			if ($?) {
				print STDERR "$f: not valid xml\n";
				closedir($fd);
				return;
			}
			push @xml,$f;
		}
		closedir($fd);
	}
	else {
		print STDERR " error open current directory\n";
		return; 
	}
	[sort @xml];
}

sub check_xml_file {
	my ($f,%p)=@_;
	my $cmd=$p{XML_VALIDATOR};
	my $schema_file=$p{SCHEMA_FILE};
	$cmd=~s/\%s/$schema_file/g;
	$cmd=~s/\%f/$f/g;
	debug(__LINE__,$cmd) if $p{DEBUG};
	system($cmd);
	return $? ? 0  : 1;
}

sub compare_xml_files {
	my ($f1,$f2,%p)=@_;
	my ($name)=$f1=~/^(.*)\.xml$/i;
	my $diff=$name.'.diff';
	system("cd '".$p{DIR}."' && xmldiff -c '$f1' '$f2' > '$diff'");
	my $rc=$?;
	if ($rc && !$p{OK_FOR_DIFF}) {
		print STDERR "'$f1' <--> '$f2' - the files are diff\n";
		return 1; 
	}
	elsif(!$rc && $p{OK_FOR_DIFF}) {
		print STDERR "'$f1' <--> '$f2' - the files are equal\n";
		return 1;
	}
	return 0;
}


sub get_root_tag_params {
	my %p=@_;
	my $tp=$p{ROOT_TAG_PARAMS};
	$tp=[ map {
				my $out=$_;
				SW: for ($out) {
							/^"(.*)"$/ && do { $out=$1; last SW; };
							/^'(.*)'$/ && do { $out=$1; last SW; };
							last;
					}
				$out;
			} split(/[,=]/,$tp)
	] if defined $tp;

	return $tp;
}

sub do_test {
	my (%p)=@_;
	my $step_file_prefix=STEP_FILE_PREFIX;
	if ($p{CLEAN}) {
		if (opendir(my $d,$p{DIR})) {
			while(my $f=readdir($d)) {
				next if -d $f;
				if ($f=~/\.(diff|tmp)$/i || $f=~/^$step_file_prefix/) {
					debug(__LINE__,"remove file $f") if $p{DEBUG};
					unless (unlink catfile($p{DIR},$f)) {
						print STDERR "(W) $f: cannot remove: $!\n";
					}
				}
			}
			closedir($d);
		}
		else {
			abort(undef,"cannot open current directory: $! \n");
		}
	}	
	return 0 if $p{NOT_EXECUTE};
	$p{SCHEMA_FILE}=catfile($p{DIR},$p{SCHEMA_FILE});
	unless (-r  $p{SCHEMA_FILE}) {
		print STDERR "(W) schema file not exist or not readable - directory skipped\n";
		return 0;
	}

	if ($p{USE_XML_REPO}) {
		my $xml_files=get_xml_files(%p);
		return 1 unless defined $xml_files;

		if (open(my $fd,"|-",$p{REPO})) {
			my $s=
					'create_catalog -o '
					.'"'
					.'TABLE_PREFIX='.$p{TABLE_PREFIX}
					.',VIEW_PREFIX='.$p{VIEW_PREFIX}
					.',NO_FLAT_GROUPS=0'
					.'" '
					.$p{CATALOG_NAME}
					.' '
					.$p{SCHEMA_FILE}
					."\n"
			;
			print $fd $s;
			for my $xml(@$xml_files) {
				my ($name)=$xml=~/^(.*)\.xml$/i;
				my $s=
						'store_xml '
						.$p{CATALOG_NAME}
						.' '
						.catfile($p{DIR},$xml)
						.' '
						.$name
						."\n";
				print $fd $s;
				my $tmpname=catfile($p{DIR},$name.'.tmp');
				$s="put_xml ";
				if (defined (my $r=$p{ROOT_TAG_PARAMS})) {
					$s.=" -x '$r' ";
				} 
				$s.="-o '$tmpname' ";
				$s.= " -1 -r " if $p{DELETE};
				$s.=$p{CATALOG_NAME}." $name\n";
				print $fd $s;
			}
			if ($p{TEST_VIEWS}) {
				print $fd "create_catalog_views -i ",$p{CATALOG_NAME},"\n";
			}
			close $fd;
			my $rc=$?;
			if ($rc) {
				print STDERR $p{REPO}.": command failed - rc $rc\n" ;
				return 1;
			}

			for my $xml(@$xml_files) {
				my ($name)=$xml=~/^(.*)\.xml$/i;
				my $tmpname=$name.'.tmp';
				unless(check_xml_file(catfile($p{DIR},$tmpname),%p)) {
					print STDERR "$tmpname: not valid xml\n";
					return 1;						
				}
				my $rc=compare_xml_files($xml,$tmpname,%p);
				return 1 if $rc && !$p{IGNORE_DIFF};
			}
		}
		else {
			print STDERR "can't run ".$p{REPO}."': $!\n";
			exit 1;
		}		
	}
	else {
		my $conn=$p{REPO}->get_attrs_value(qw(DB_CONN));
		if (defined (my $catalog=$p{REPO}->get_catalog($p{CATALOG_NAME}))) {
			$catalog->drop;
		}
		
		my $schema=$p{PARSER}->parsefile(
				$p{SCHEMA_FILE}
				,NO_FLAT_GROUPS		=> 0
				,TABLE_PREFIX		=> $p{TABLE_PREFIX}
				,VIEW_PREFIX  		=> $p{VIEW_PREFIX}
		);
		
		my $catalog=$p{REPO}->create_catalog($p{CATALOG_NAME},$schema);
		
		abort($conn,$p{CATALOG_NAME},": catalog already exist in the repository")
				unless defined $catalog;

				
		unless ($p{NOT_LOAD_SCHEMA}) {
			unless($catalog=$p{REPO}->get_catalog($p{CATALOG_NAME})) {
 				abort($conn,$p{CATALOG_NAME},": catalog not exist in the repository");
			}
		}
				
		my $catalog_xml=$catalog->get_catalog_xml(
			WRITER => XML::Writer->new(
						DATA_INDENT => 4
						,DATA_MODE => 1
						,NAMESPACES => 0
						,UNSAFE    => 1
			)
			,EXECUTE_OBJECTS_PREFIX		=> undef
			,EXECUTE_OBJECTS_SUFFIX		=> undef 
		);
		
		
		my $xml_files=get_xml_files(%p);
		return 1 unless defined $xml_files;

		my $root_tag_params=get_root_tag_params(ROOT_TAG_PARAMS => $p{ROOT_TAG_PARAMS});
		for my $xml(@$xml_files) {
			if (open(my $fd,'<',catfile($p{DIR},$xml))) {
				my ($name)=$xml=~/^(.*)\.xml$/i;
				my $id=$catalog_xml->store_xml(
					XML_NAME 			=>  $name
					,FD					=>  $fd
				);
				close($fd);
				abort($conn,$name,':already exist in repository') unless defined $id;
				my $tmpname=$name.'.tmp';
				if (open(my $fd,'>',catfile($p{DIR},$tmpname))) {
					$id=$catalog_xml->put_xml(
							XML_NAME			=> $name
							,NO_WRITE_HEADER	=> 0
							,NO_WRITE_FOOTER	=> 0
							,FD					=> $fd
							,ROOT_TAG_PARAMS	=> $root_tag_params
							,DELETE				=> $p{DELETE}
					);
					close $fd;
					abort($conn,$name,': not found into repository') unless defined $id;

					unless(check_xml_file(catfile($p{DIR},$tmpname),%p)) {
						print STDERR "$tmpname: not valid xml\n";
						return 1;						
					}

					my $rc=compare_xml_files($xml,$tmpname,%p);
					return 1 if $rc && !$p{IGNORE_DIFF};

					if ($p{DELETE} && !$rc && !$p{OK_FOR_DIFF}) {
						print STDERR "test delete... \n";
						my $count=0;
						test_delete($schema,\$count,CONN => $conn,REPO => $p{REPO});
						if ($count > 0) {
							print STDERR "delete test failed - $count tables has rows\n";
							return 1;
						}
					}
				}
				else {
					abort($conn,"$tmpname: open error");
				}
			}
			else {
				abort($conn,"$xml: open error");		
			}
		}
		if ($p{TEST_VIEWS}) {
			unless ($p{REPO}->is_support_views) {
				print STDERR "(W) database not support complex views - test views ignored\n";
			}
			else {
				print STDERR "test views\n";
				unless ($catalog->create_views) {
					print STDERR "create views failed\n";
					return 1;
				}
				else {
					print STDERR "test query views\n";
					my $binding=$p{REPO}->get_attrs_value(qw(BINDING));
					for my $r($catalog->get_object_names(TYPE => 'view')) {
						my $view_name=$r->[2];
						local $@;
						my $r=eval { $binding->query_from_view($view_name) };
						if (!$@ && defined $r) {
								#empty
						}
						else {
							print STDERR "query_from_view failed for view '$view_name'\n";
							print STDERR $@ if $p{DEBUG};
							return 1;
						}
					}
				}
			}
		}
	}	
	return 0;
}

sub give_tests {
	my @ot=();
	for my $a(@_) {
		if ($a=~/^\d+$/) {
			push @ot,$a;
		}
		elsif ($a=~/^(\d+)-(\d+)$/) {
			push @ot,($1..$2);
		}
		else {
			print STDERR "(W) $a: invalid test number - ignored\n";
		}
	}
	return @ot;
};

sub test_dirs {
	my ($dp,$dir)=@_;
	my @testdirs=();
	if  (opendir(my $fd,$dir)) {
		while(my $d=readdir($fd)) {
			next unless $d=~/^$dp(\d+)$/;
			next unless -d $d;
			push @testdirs,$1;
		}
		closedir($fd);
	}
	else {
		my $absdir=File::Spec->rel2abs($dir);
		print STDERR "(W) $absdir: $!\n";
	}
	my @a=sort @testdirs;;
	return @a;
};

sub get_dbconn_cs {
	my ($connstr,%params)=@_;
	unless (defined $connstr && length($connstr)) {
		print STDERR "no connection string specify - set the option 'c' or define the env var DB_CONNECT_STRING\n";
		return ();
	}
	my $conn=blx::xsdsql::connection->new;
	unless ($conn->do_connection_list($connstr)) {
		print STDERR $conn->get_last_error,"\n";
		return ();
	}
	my ($output_namespace,$db_namespace)=map { $conn->get_attrs_value($_) } (qw(OUTPUT_NAMESPACE DB_NAMESPACE));
	my @namespaces=blx::xsdsql::schema_repository::get_namespaces;
	my $namespace=$output_namespace.'::'.$db_namespace;
	unless (grep($namespace eq $_,@namespaces)) {
		print STDERR "$connstr: the namespace '$namespace' is not supported\n";
		print STDERR "the namespaces actually supported are: ",join(" ",map { "'".$_."'" } @namespaces),"\n";
		return ();
	}
	my @a=$conn->get_connection_list;
	return ( { 
				OUTPUT_NAMESPACE => $output_namespace
				,DB_NAMESPACE	 =>  $db_namespace
			 },@a
	);
}

sub get_message {
	my (%p)=@_;
	my @f=();
	if (open(my $fd,'<',catfile($p{DIR},'message.txt'))) {
		@f=<$fd>;		
		close $fd;
	} 
	else {
		my $name=readlink catfile($p{DIR},'schema.xsd');
		if ($name) {
			$name=~s/_/ /g;
			$name=~s/\.xsd$//i;
			push @f,$name."\n";	
		}
	}
	push @f,"\n"  unless scalar(@f);
	return wantarray ? @f : \@f;
}

sub get_schema_file{
	my $testdir=$_[0];
	my %schemas=();
	if (opendir(my $dd,$testdir)) {
		my @files=();
		while(my $f=readdir($dd)) {
			next unless $f=~/\.xsd$/;
			my $fullname=catfile($testdir,$f);
			next if -l $fullname;
			next if -d $fullname;
			next unless -r $fullname;
			push @files,$f;
		}
		closedir $dd;
		return @files if scalar(@files) < 2;
		for my $f(@files) {
			my $fullname=catfile($testdir,$f);
			if (open(my $fd,'<',$fullname)) {
				$schemas{$f}=1 unless exists $schemas{$f};
				while(<$fd>) {
					if (/<!--\s+ROOT_SCHEMA\s+/) {
						close $fd;
						return ($f);
					}
					$schemas{$1}=0 if /include\s+schemaLocation="([^"]+)"/;
					$schemas{$1}=0 if /import\s+.*\s+schemaLocation="([^"]+)"/;
				}
				close $fd;
			}
			else {
				print STDERR "$fullname: $!\n";
			}
		}
	}
	else {
		print STDERR "$testdir: $!\n"; 
	}
	grep($schemas{$_},keys %schemas);
}

###### main ####

unless (getopts ('hac:df:int:sv:xDFLTV',\%Opt)) {
	 print STDERR "invalid option or option not set\n";
	 exit 1;
}

if ($Opt{h}) {
	print STDOUT basename($0).
q{  [<options>] [<args>].. 
    exec battery test 
<options>: 
    -h  - this help
    -a - display the know namespaces and exit  
    -c <connstr> - connect string to database - the default is the value of the env var DB_CONNECT_STRING
        otherwise is an error
        the form is  [<output_namespace>::]<dbtype>:<user>/<password>@<dbname>[:hostname[:port]][;<attribute>[,<attribute>...]]
        <output_namespace>::<dbtype> - see the output with 'a' option set 
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
    -d  - debug mode
    -f   <filename>[,<filename>...] - include in test only file match <filename>
    -i  - incremental test
    -n  - continue after xml difference
    -t  <c|r|C|R> - transaction database mode ((c)ommit for single test, (r)ollback for single test,(C)ommit global,(R)ollback global) - default c
    -s  - stop on first error
    -v  <command> - use <command> for xml validation
            use %f for xml file tag and %s for schema (xsd) file tag
            the default is 'xmllint -schema %s %f'
    -x  - use xml_repo.pl for test
    -F  - do not drop the repository on the end of tests
    -L  - do not load from repository the schema
    -T  - clean temporary files in test + step files and not execute the test
    -V  - not test the views
    -D  - do not delete rows after write xml
arguments>:
    <testnumber>|<testnumber>-<testnumber>...
    if <testnumber> is not spec all tests can be executed
    if the test is OK the database is cleaned (see option -F)
}; 
    exit 0;
}

if (-t *STDERR) { ## no critic
	eval { require  Term::ANSIColor;Term::ANSIColor->import };

}

sub my_color {
	color @_;
}


if ($Opt{a}) {
	for my $k(qw(c f i n t s v x L F T V D)) {
		print STDERR  "(W) Option '$k' is ignored is active option 'a'\n" if delete $Opt{$k};
	}
	for my $s(blx::xsdsql::schema_repository::get_namespaces) {
			print $s,"\n";
	}
	exit 0;
}

if ($Opt{T}) {
	for my $k(qw(c f i n t s v x L V D)) {
		print STDERR  "(W) Option '$k' is ignored is active option 'T'\n" if delete $Opt{$k};
	}
	$Opt{F}=1;
}

if ($Opt{x}) {
	for my $k(qw(L t)) {
		print STDERR "(W) Option '$k' is ignored is active option 'x'\n" if delete $Opt{$k};
	}
}


$Opt{t}='c' unless defined $Opt{t};
abort(undef, $Opt{t},": bad value for option t") unless $Opt{t}=~/^(c|r)$/i;

my @onlytests=give_tests(@ARGV);

my @testdirs=grep (defined $_ && length($_),map  {  
		my $testnumber=$_;
		if (scalar(@ARGV)) {
			$testnumber=undef unless grep($_ == $testnumber,@onlytests);
		}
		$testnumber;
	}  test_dirs(DIR_PREFIX,File::Spec->curdir));

unless (scalar(@testdirs)) {
	print STDERR "(W) no test required\n";
	exit 0;
}

$Opt{NOT_EXECUTE}=1 if $Opt{T};
$Opt{F}=1 if $Opt{i};



unless ($Opt{NOT_EXECUTE}) {
	$Opt{c}=$ENV{DB_CONNECT_STRING} unless defined $Opt{c};
	my ($ns,@cs)=get_dbconn_cs($Opt{c});
	exit 1 unless defined $ns;
	$Opt{output_namespace}=$ns->{OUTPUT_NAMESPACE};
	$Opt{db_namespace}=$ns->{DB_NAMESPACE};
	$ENV{DB_CONNECT_STRING}=$Opt{c} if $Opt{x};
	if ($Opt{x}) {
		$Opt{xml_repo}=PERL.' '.File::Spec->rel2abs(catfile('..','bin','xml_repo.pl'))." exec";
		$Opt{xml_repo}.=' -e "> "' if $Opt{d};
		unless ($Opt{i}) {
			if (open(my $fd,"|-",$Opt{xml_repo})) {
				print $fd 'instruction print STDERR qq(drop eventually existent repository...\n)'."\n";
				print $fd "drop_repository -i\n";
				print $fd 'instruction print STDERR qq(create repository...\n)'."\n";
				print $fd "create_repository\n";
				close $fd;
				my $rc=$?;
				abort(undef,$Opt{xml_repo},": command failed - rc $rc") if $rc;
			}
			else {
				abort(undef,"can't run ",$Opt{xml_repo},"': $!");
			}
		}
		else {
			if (open(my $fd,"|-",$Opt{xml_repo})) {
				print $fd "catalog_names\n";
				close $fd;
				my $rc=$?;
				exit 1 if $rc;
			}
		}
	}
	else {
		$Opt{conn}=eval {  DBI->connect(@cs) };
		if ($@ || !defined $Opt{conn}) {
			print STDERR $@ if $@;
			abort($Opt{conn},$Opt{c}." connection failed");
		}

		$Opt{repo}=blx::xsdsql::schema_repository->new(
				DB_CONN 			=> $Opt{conn}
				,OUTPUT_NAMESPACE	=> $Opt{output_namespace}
				,DB_NAMESPACE		=> $Opt{db_namespace}
				,DEBUG				=> $Opt{d}
		);
		
		unless ($Opt{i}) {
			print STDERR "drop eventually existent repository...\n";
			$Opt{repo}->drop_repository;
			print STDERR "create repository...\n";
			$Opt{repo}->create_repository;
			print STDERR "OK\n";
		}
		else {
			unless($Opt{repo}->is_repository_installed) {
				abort($Opt{conn},"the repository is not installed");				
			}
		}
	}

}


my $startdir=File::Spec->rel2abs(File::Spec->curdir);

my $only_files=defined $Opt{f}
				? [map {  my $f=$_; $f.='.xml' unless $f=~/\.xml$/i; $f; } split(',',$Opt{f})]
				: undef
;

$Opt{v}='xmllint --schema \'%s\' --noout \'%f\'' unless defined $Opt{v};


my $step_file=$Opt{NOT_EXECUTE} 
				? undef 
				: STEP_FILE_PREFIX.'_'.$Opt{output_namespace}.'_'.$Opt{db_namespace};

my $parser= $Opt{NOT_EXECUTE} 
	? undef 
	: blx::xsdsql::xsd_parser->new(
			OUTPUT_NAMESPACE 	=> $Opt{output_namespace}
			,DB_NAMESPACE		=> $Opt{db_namespace}
			,DEBUG				=> $Opt{d}
	);

my %C=( #counters
		N	=> 0
		,F  => 0
); 

for my $n(@testdirs) { 
	my $testdir=DIR_PREFIX.$n;
	my $sf=catfile($testdir,$step_file);
	if ($Opt{T}) {
		my %test_params=(
			TEST_NUMBER 				=> $n
			,CLEAN 						=> 1
			,NOT_EXECUTE 				=> $Opt{NOT_EXECUTE}
			,DIR 						=> $testdir
		);
		do_test(%test_params);
		print STDERR "test number $n - cleaned\n";
	}
	else {
		my $rc=0;
		unlink($sf) unless $Opt{i};
		print STDERR  my_color 'blue';
		print STDERR "test number '$n' -  database '".$Opt{db_namespace}."' ";		
		unless( -e $sf) { 
			print STDERR get_message(DIR => $testdir);
			print STDERR  my_color 'reset';
			my %custom_params=();
			if (open(my $fd,'<',catfile($testdir,CUST_PARAMS_FILE))) {
				while(<$fd>) {
					chop;
					next if /^\s*#/;
					next if /^\s*$/;
					if (/^\s*(\w+)\s+(.*)$/) {
						$custom_params{$1}=$2;
					}
					else {
						print STDERR "(W) ".CUST_PARAMS_FILE.": $_: line ignored\n";
					}
				}
				close $fd;
			}
			my $sn=sprintf("%03d",$n);
			my @schema_files=get_schema_file($testdir);
			if (scalar(@schema_files) == 0) {
				print STDERR "no schema file in directory\n";
				$rc=1;
			}
			elsif (scalar(@schema_files) > 1) {
				print STDERR join(' ',@schema_files),": many schema file in directory\n";
				$rc=1;
			}
			else {
				$rc=eval {
					do_test(
						SCHEMA_FILE					=> $schema_files[0]
						,CATALOG_NAME				=> 'c'.$sn
						,VIEW_PREFIX 				=> 'V'.$sn.'_'
						,TABLE_PREFIX 				=> 'T'.$sn.'_'
						,DEBUG						=> $Opt{d}
						,XML_VALIDATOR				=> $Opt{v}
						,IGNORE_DIFF				=> $Opt{n}
						,DELETE						=> !$Opt{D}
						,NOT_LOAD_SCHEMA			=> $Opt{L}
						,TEST_VIEWS					=> !$Opt{V}
						,%custom_params
						,PARSER						=> $parser
						,REPO						=> ($Opt{x} ? $Opt{xml_repo} : $Opt{repo})
						,USE_XML_REPO				=> $Opt{x}
						,TEST_NUMBER 				=> $n
						,OUTPUT_NAMESPACE			=> $Opt{output_namespace}
						,DB_NAMESPACE				=> $Opt{db_namespace}
						,NOT_EXECUTE				=> $Opt{NOT_EXECUTE}
						,DIR 						=> $testdir
						,ONLY_FILES					=> $only_files
					);
				};
				if ($@) {
					print STDERR $@;
					$rc=1;
				}
			}
			$C{N}++;			
			$C{F}++ if $rc;
			if($rc) {
				print STDERR my_color 'red';
				print STDERR '['.$sn.'] Failed'."\n";
				print STDERR my_color 'reset';
			}
			else {
				open(my $fd,">",$sf);
				close $fd;
				print STDERR my_color 'blue';
				print STDERR '['.$sn.'] OK'."\n";
				print STDERR my_color 'reset';
			}
			if (defined (my $conn=$Opt{conn}) && ! $Opt{conn}->{AutoCommit}) {
				if ($Opt{t} eq 'c') {
					$conn->commit;
				}
				elsif ($Opt{t} eq 'r') {
					print STDERR "(W) ROOLBACK issued for user request\n";
					$conn->rollback;
				}
			}
			last if $rc && $Opt{s};
		}
		else {
			print STDERR " - skipped for already tested\n";
			print STDERR  my_color 'reset';
		}
	}
}

$Opt{F}=1 if $C{F};

unless($Opt{F}) {
	print STDERR "drop repository\n";
	if ($Opt{x}) {
		if (open(my $fd,"|-",$Opt{xml_repo})) {
			print $fd "drop_repository -i\n";
			close $fd;
			my $rc=$?;
			abort($Opt{conn},"xml_repo.pl failed - rc $rc") if $rc;
		}
		else {
			abort($Opt{conn},"can't run ".$Opt{xml_repo}."': $!");
		}
	}
	else {
		$Opt{repo}->drop_repository;
	}
	print STDERR "(W) REPOSITORY Dropped\n";
}

if (defined (my $conn=$Opt{conn})) {
	unless ($conn->{AutoCommit}) {
		if ($Opt{t} =~/^c$/i) {
			$conn->commit;
		}
		else {
			print STDERR "(W) ROOLBACK issued\n";
			$conn->rollback;
		}
	}
	$conn->disconnect;
}

print STDERR my_color($C{F} ? 'red' : 'blue'),"test numbers ",$C{N}," - failed ",$C{F},"\n";
print STDERR my_color 'reset';

exit ($C{F} ? 1 : 0);

__END__

=head1 NAME test.pl

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
