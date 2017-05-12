#!/usr/bin/env perl
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use Getopt::Std;
use File::Basename;

use blx::xsdsql::ut::ut qw(nvl ev);
use blx::xsdsql::xsd_parser;
use blx::xsdsql::schema_repository;
use blx::xsdsql::connection;
use DBI;

use constant {
 	DEFAULT_VIEW_PREFIX				=> 'V'
	,DEFAULT_ROOT_TABLE_NAME 		=> 'ROOT'
 	,DEFAULT_SEQUENCE_PREFIX			=> 'S'
 	,DEFAULT_TABLE_DICTIONARY		=> 'table_dictionary'
 	,DEFAULT_COLUMN_DICTIONARY		=> 'column_dictionary'
	,DEFAULT_RELATION_DICTIONARY 	=> 'relation_dictionary'
	,O_KEYS							=>  [ qw(MAX_VIEW_COLUMNS MAX_VIEW_JOINS EMIT_SCHEMA_DUMPER) ]
	
};

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


my %Opt=();
unless (getopts ('hc:r:p:t:v:do:',\%Opt)) {
	print STDERR "invalid option or option not set\n";
	exit 1;
}

if ($Opt{h}) {
	print STDOUT 
$0,q(  [<options>]  [<xsdfile>] [<command>...]
    <options>: 
        -h  - this help
        -d  - emit debug info 
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
			
        -r <root_table_name> - set the root table name  (default '".DEFAULT_ROOT_TABLE_NAME."')
        -p <table_prefix_name> - set the prefix for the tables name (default none)
        -v <view_prefix_name>  - set the prefix for views name (default '".DEFAULT_VIEW_PREFIX."')
                WARNING - This option can influence table names
        -t <table_name>|<path_name>[,<table_name>|<path_name>...] - generate view starting only from <table_name> (default all tables)
            if the first <table_name>|<path_name> begin with comma then <table_name>|<path_name> (without comma) is a file name containing a list of <table_name>|<path_name>
        -o <name>=<value>[,<name>=<value>...]
            set extra params - valid names are:
                MAX_VIEW_COLUMNS     =>  produce view code only for views with columns number <= MAX_VIEW_COLUMNS
                    -1 is a system limit (database depend)
                    false is no limit (the default)
                MAX_VIEW_JOINS         =>  produce view code only for views with join number <= MAX_VIEW_JOINS 
                    -1 is a system limit (database depend)
                    false is no limit (the default)
    <commands>
        display_namespaces - display on stdout the namespaces (type+db) founded (Es: sql::pg)
        drop_table  - generate a drop tables on stdout
        create_table - generate a create tables on stdout
        addpk - generate primary keys on stdout
        drop_sequence - generate a drop sequence on stdout
        create_sequence - generate a create sequence on stdout
        drop_view       - generate a drop view on stdout
        create_view     - generate a create view on stdout
        drop_dictionary - generate a drop dictionary on stdout
        create_dictionary - generate a create dictionary on stdout
        insert_dictionary - generate an insert dictionary on stdout
        display_path_relation - display on stdout the relation from path and table/column
),"\n";
    exit 0;
}


my @cl_namespaces=blx::xsdsql::generator::get_namespaces;

if (nvl($ARGV[0]) eq 'display_namespaces') {	
	for my $n(@cl_namespaces) {
		print STDOUT $n,"\n";
	}
	exit 0;
}

my ($ns,@conn)=get_dbconn_cs($Opt{c});
exit 1 unless defined $ns;
$Opt{output_namespace}=$ns->{OUTPUT_NAMESPACE};
$Opt{db_namespace}=$ns->{DB_NAMESPACE};

unless (grep($_ eq $ns->{OUTPUT_NAMESPACE}.'::'.$ns->{DB_NAMESPACE},@cl_namespaces)) {
	print STDERR $ns->{OUTPUT_NAMESPACE}.'::'.$ns->{DB_NAMESPACE}.": namespace not know";
	exit 1;
}


if (defined (my $t=$Opt{t})) {
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
			$Opt{t}=\@lines;
			close $fd;
		}
		else {
			print STDERR "$1: $!\n";
			exit 1;
		}
	}
	else {
	   $Opt{t}=[split(",",$t)];
	}
}

if (defined $Opt{o}) {
	my %h=();
	for my $e(split(",",$Opt{o})) {
		my ($name,$value)=$e=~/^([^=]+)=(.*)$/;
		unless (defined $name) {
			print STDERR $Opt{o},": option o is invalid - valid is <name>=<value>[,<name>=<value>...]\n";
			exit 1;
		}
		$h{$name}=$value;
	}
	my $o_keys=O_KEYS;
	for my $k(keys %h) {
		unless (grep($_ eq $k,@$o_keys)) {
			print STDERR "$k: key on 'o' option is not valid - valid keys are ",join(',',@$o_keys),"\n";
			exit 1;
		}
	}
	$Opt{o}=\%h;
}
else {
	$Opt{o}={};
}

$Opt{w}=DEFAULT_VIEW_PREFIX unless defined $Opt{w};
$Opt{r}=DEFAULT_ROOT_TABLE_NAME unless defined $Opt{r};
$Opt{s}=DEFAULT_SEQUENCE_PREFIX unless defined $Opt{s};
$Opt{b}=DEFAULT_TABLE_DICTIONARY.':'.DEFAULT_COLUMN_DICTIONARY.':'.DEFAULT_RELATION_DICTIONARY unless defined $Opt{b};
my @dic=split(":",$Opt{b});
$dic[0]=DEFAULT_TABLE_DICTIONARY unless $dic[0];
$dic[1]=DEFAULT_COLUMN_DICTIONARY unless $dic[1];
$dic[2]=DEFAULT_RELATION_DICTIONARY unless $dic[2];

if (scalar(@dic) != 3) {
	print STDERR $Opt{b},": option b is invalid - valid is <table_dictionary>[:<column_dictionary>[:<relation_dictionary>]]\n";
	exit 1;
}
$Opt{b}=\@dic;


my $schema_pathname=sub {
	my $s=shift;
	$s='-' unless defined $s;
	$s='-' unless length($s);
	return $s;
}->(shift @ARGV);


my @cmds=@ARGV;
for my $cmd(@cmds) {
	unless (grep($_ eq $cmd,qw( drop_table create_table addpk drop_sequence create_sequence drop_view create_view drop_dictionary create_dictionary insert_dictionary display_path_relation display_namespaces))) {
		print STDERR "$cmd: invalid command\n";
		exit 1;
	}
}


my $conn=eval { DBI->connect(@conn) };
if ($@ || !defined $conn) {
	print STDERR $@ if $@;
	print STDERR "connection failed\n";
	exit 1;
}


my $repo=blx::xsdsql::schema_repository->new(
	%$ns
	,DB_CONN 	=> $conn
	,DEBUG		=> $Opt{d}
);



my $g=$repo->get_attrs_value(qw(GENERATOR));
my $xsd_parser=blx::xsdsql::xsd_parser->new(%$ns,DEBUG => $Opt{d});

my $schema=$xsd_parser->parsefile(
		$schema_pathname
		,ROOT_TABLE_NAME 				=> $Opt{r}
		,TABLE_PREFIX 					=> $Opt{p}
		,VIEW_PREFIX 					=> $Opt{v}
);
					


for my $cmd(@cmds) {
	if ($cmd eq 'display_path_relation') {
		my $paths=$schema->get_attrs_value(qw(MAPPING_PATH))->get_attrs_value(qw(TC));
		for my $line(map {
								my $k=$_;
								my $e=$paths->{$k};
								my $obj=ref($e) eq 'HASH' ? $e->{C} : $e->[-1]->{T};
								my $minoccurs=$obj->get_min_occurs;
								my	$out=($minoccurs == 0 ? " " : "M").' '.$k.' => '.(ref($e) eq 'HASH' ? $e->{C}->get_full_name : $e->[-1]->{T}->get_sql_name);
								$out;
							} sort keys %$paths) {
			print "$line\n";
		}
		print "\n";
	}
	elsif ($cmd eq 'display_namespaces') {
		for my $n(@cl_namespaces) {
			print STDOUT $n,"\n";
		}
	}
	else {
		if (grep ($cmd eq $_,(qw(drop_dictionary create_dictionary)))) {
			$g->generate(
				SCHEMA				=> undef
				,COMMAND 			=> $cmd
				,FD 				=> *STDOUT

			);
		}
		else {
			$g->generate(
				SCHEMA				=> $schema
				,COMMAND 			=> $cmd
				,FD 				=> *STDOUT
				,CATALOG_NAME		=> basename($schema_pathname)
				,SCHEMA_CODE		=> basename($schema_pathname)
				,LOCATION			=> $schema_pathname
			);
		}
	}
}

exit 0;
__END__

=head1 NAME xsd2sql.pl

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
