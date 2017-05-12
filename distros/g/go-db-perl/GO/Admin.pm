# $Id: Admin.pm,v 1.48 2009/08/12 17:43:32 benhitz Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

package GO::Admin;

=head1 NAME

  GO::Admin;

=head1 SYNOPSIS


=head1 DESCRIPTION

object to help administer GO dbs

use the script

  go-dev/scripts/go-manager.pl

=cut


use Carp qw(cluck confess);
use Exporter;
use GO::Utils qw(rearrange);
use GO::Model::Root;
use GO::AppHandle;
use GO::SqlWrapper qw(:all);
use strict;
use vars qw(@ISA);
use FileHandle;

use constant MAX_CVS_TRIES => 10;

our $GZIP = 'gzip -f';

@ISA = qw(GO::Model::Root Exporter);


sub _valid_params {
    return qw(dbname dbhost dbms dbuser dbauth dbport dbsocket data_root releasename tmpdbname godevdir sqldir workdir swissdir uniprotdir speciesdir administrator use_reasoner);
}

# sub pre_process_files_for_ieas {

#   ### Call process_files_for_ieas.pl to remove IEAs from the
#   ### gene_association files Added by AS on Feb 14, 2005
#   my $self = shift;
#   print STDERR ("Processing gene_association files to remove IEAs...\n\n");
#   print STDERR ("Calling process_files_for_ieas.pl:\n");
#   system ("process_files_for_ieas.pl",
# 	  $self->data_root . "/gene-associations/");
#   print STDERR ("Processing gene_association files to remove IEAs complete.\n");
# }

sub distn {
    my $self = shift;
    $self->{_distn} = shift if @_;
    if ($self->{_distn}) {
	$self->throw("No distn");
    }
    return $self->{_distn};
}

sub tmpdbname {
    my $self = shift;
    $self->{_tmpdbname} = shift if @_;
    if (!$self->{_tmpdbname}) {
	return 'test_go';
    }
    return $self->{_tmpdbname};
}

sub sqldir {
    my $self = shift;
    $self->{_sqldir} = shift if @_;
    if (!$self->{_sqldir}) {
	return $self->godevdir.'/sql' if $self->godevdir;
    }
    return $self->{_sqldir};
}

sub godevdir {
    my $self = shift;
    $self->{_godevdir} = shift if @_;
    if (!$self->{_godevdir}) {
	return $ENV{GO_ROOT};
    }
    return $self->{_godevdir};
}

sub workdir {
    my $self = shift;
    $self->{_workdir} = shift if @_;
    if (!$self->{_workdir}) {
	return '.';
    }
    return $self->{_workdir};
}

sub dbms {
    my $self = shift;
    $self->{_dbms} = shift if @_;
    if (!$self->{_dbms}) {
	return 'mysql';
    }
    return $self->{_dbms};
}

sub swissdir {
    my $self = shift;
    $self->{_swissdir} = shift if @_;
    if (!$self->{_swissdir}) {
	return 'proteomes';
    }
    return $self->{_swissdir};
}

sub uniprotdir {
    my $self = shift;
    $self->{_uniprotdir} = shift if @_;
    if (!$self->{_uniprotdir}) {
	return 'uniprot';
    }
    return $self->{_uniprotdir};
}

sub speciesdir {
    my $self = shift;
    $self->{_speciesdir} = shift if @_;
    if (!$self->{_speciesdir}) {
	return 'ncbi';
    }
    return $self->{_speciesdir};
}

# drops a db
sub dropdb {
    my $self = shift;
    my $ar = $self->mysqlargs;
    my $h = $self->mysqlhostargs;
    my $d = $self->dbname;
    my $sqldir = $self->sqldir;
    my $err =
      $self->runcmds("*mysql $h -e 'DROP DATABASE $d'",
		    );
#    if ($err) {
#	$self->throw("Cannot create!");
#    }
}

# drops and recreates an empty db
sub newdb {
    my $self = shift;
    my $ar = $self->mysqlargs;
    my $h = $self->mysqlhostargs;
    my $d = $self->dbname;
    my $sqldir = $self->sqldir;
    my $err =
      $self->runcmds("*mysql $h -e 'DROP DATABASE $d'",
		     "mysql $h -e 'CREATE DATABASE $d'",
		    );
    if ($err) {
	$self->throw("Cannot create!");
    }
}

# loads SQL DDL from sqldir
sub load_schema {
    my $self = shift;
    my $ar = $self->mysqlargs;
    my $h = $self->mysqlhostargs;
    my $d = $self->dbname;
    my $dbms = $self->dbms;
    my $sqldir = $self->sqldir;
    my $err =
      $self->runcmds("$sqldir/compiledb -t $dbms $sqldir/go-tables-FULL.sql | mysql $h $d",
		    );
    if ($err) {
	$self->throw("Cannot load schema!");
    }
}

sub time_of_last_sp_update {
    my $self = shift;
    my $swissdir = $self->swissdir;
    my @f = split(/\n/, `ls $swissdir/*SPC`);
    my $t;
    foreach (@f) {
	my @stat = stat($_);
	if (!defined($t) || $stat[9] < $t) {
	    # least recent file
	    $t = $stat[9];
	}
    }
    return $t;
}

# downloads proteome sequence files from SwissProt - may take a while
sub updatesp {
    my $self = shift;
    my $swissdir = $self->swissdir;
    my $uniprotdir = $self->uniprotdir || 'uniprot';

# Don't download until we work out details of migrating from swissprot
# over to uniprot

    my $tempdir = 'temp';

    if (-d $tempdir) {
	$self->runcmd("rm -r $tempdir");
    }

    $self->runcmd("mkdir $tempdir");

# start getting the two big uniprot files.

    if (-d $uniprotdir) {
	$self->runcmd("rm -r $uniprotdir");
    }

    $self->runcmd("mkdir $uniprotdir");

    $self->runcmd("wget -r -np -nv -nd -P $uniprotdir ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.dat.gz");
    $self->runcmd("wget -r -np -nv -nd -P $uniprotdir ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_trembl.dat.gz");
}

sub update_speciesdir {
    my $self = shift;
    my $speciesdir = $self->speciesdir;

    my $f = "taxdump.tar.gz";
    if (! -d $speciesdir) {
	runcmd("mkdir $speciesdir");
    }
    $self->runcmd("cd $speciesdir && wget --passive-ftp ftp://ftp.ncbi.nih.gov/pub/taxonomy/$f && tar -zxvf $f");
    $self->runcmd("chmod -R 777 $speciesdir");
    return;
}

# creates a database from a tarball mysql dump file
# WARNING - overwrites current db!
# it will probably fail if not given an empty db; run $admin->newdb first
sub build_from_file {
    my $self = shift;
    my $f = shift;
    my $ar = $self->mysqlargs;
    if ($f =~ /(.*-tables)\.tar/) {
	my $tdir = $1;
	my @parts = split(/\//, $tdir);
	my $d = $parts[-1];
	my $args = "xvf";
        my $unzip_tar_command = "tar -$args $f";
	if ($f =~ /\.gz$/) {
            $unzip_tar_command = "gunzip -c $f | tar -$args -";
	}
	$self->runcmds($unzip_tar_command,
		       "cat $d/*.sql | mysql $ar",
		       "mysqlimport -L $ar $d/*.txt");
    }
    elsif ($f =~ /(.*-data)/) {
#	my $tdir = $1;
#	my @parts = split(/\//, $tdir);
#	my $d = $parts[-1];
	my $cat = "cat";
	if ($f =~ /\.gz$/) {
	    $cat = "gzcat";
	}
	$self->runcmds("$cat $f | mysql $ar");
    }
    else {
	die $f;
    }
}

sub released_files {
    my $self = shift;
    my $wd = $self->workdir;
    my @f = split(/\n/, `find $wd -follow -name '*gz'`);
    return @f;
}


sub mysqlargs {
    my $self = shift;
    my $args = $self->dbhost ? "-h ".$self->dbhost : "";
    $args .= " ".$self->dbname;
    $args .= $self->dbsocket ? " --socket=".$self->dbsocket : "";
    $args .= $self->dbuser ? " -u".$self->dbuser : "";
    $args .= $self->dbauth ? " -p".$self->dbauth : "";
    $args;
}

sub mysqlhostargs {
    my $self = shift;
    my $args = $self->dbhost ? "-h ".$self->dbhost : "";
    $args .= $self->dbsocket ? " --socket=".$self->dbsocket : "";
    $args .= $self->dbuser ? " -u".$self->dbuser : "";
    $args .= $self->dbauth ? " -p".$self->dbauth : "";

    $args;
}

sub refresh_data_root {
    my $self = shift;
    my $D = $_[0] ? "-D " . shift  : "";
    my $data_root = $self->data_root;
    if (!-d "$data_root/CVS") {
	$self->throw("no CVS in $data_root");
    }

    $self->runcmds("/bin/rm -rf $data_root/gene-associations/gene*");

    $self->runcmds("cd $data_root;cvs update -dA $D");

}

sub makecoderelease {
    my $self = shift;
    my $D = $_[0] ? "-D " . shift  : "";
    my $distn = $self->releasename;
    my $godev = $self->godevdir;
    my $sqldir = $self->sqldir;
    my $dbms = $self->dbms;
    my $r = $self->releasename;
    my $host = $self->dbhost;
    my $schema = "$r-schema-$dbms.sql";
    my $html = "$r-schema-html";
    my $dtd = "$r-rdf.dtd";
    my $coderel = "$r-utilities-src";
    $ENV{CVS_RSH} = 'ssh';

    for (my $tries = 1; $tries <= MAX_CVS_TRIES; $tries++) {
        my $err = $self->runcmd("*cvs -d :pserver:anonymous\@geneontology.cvs.sourceforge.net:/cvsroot/geneontology checkout go-dev");
        last unless $err;
    }

    $self->runcmds("*rm -rf $coderel",
		   "cp go-dev/xml/dtd/go-rdf.dtd $dtd && $GZIP $dtd",
		   "cp go-dev/xml/dtd/obo-xml.dtd $r-obo-xml.dtd && $GZIP $r-obo-xml.dtd",
		   "mv go-dev $coderel",
		   "*find $coderel -name CVS -exec rm -rf {} \\;",
		   "tar cf $coderel.tar $coderel",
		   "$GZIP $coderel.tar",
                   "*sqlt --from MySQL --to HTML $schema > $html && $GZIP $html",
		   "$sqldir/compiledb -t $dbms $sqldir/go-tables-FULL.sql > $schema",
		   "$GZIP $schema",
                   # use SQL::Translator to make HTML
		   );
}

sub make_release_tarballs {
    my $self = shift;
    my $suff = shift || $self->guess_release_type;
    my $distn = $self->releasename . '-' .$suff;
    my $t = $distn."-tables";
    my $td = $distn."-data";
    my $tt = $t.".tar";

    
    ### Updated by AS on April 21, 2005
    my $releaseNm;
    if($self->releasename =~ m/go\_(\d+)/i) { ### eg: go_200504 or go_20050421 or go_daily
	$releaseNm = $1;
	
	### hyphenate the releasename

	my @dateNos = split(//, $releaseNm);
	my ($year, $month, $date);
	$year = $dateNos[0] . $dateNos[1] . $dateNos[2] . $dateNos[3];
	$month = $dateNos[4] . $dateNos[5];

	if (@dateNos == 6) { ### gofull, eg: 200504
	    $releaseNm = $year . '-' . $month;
	}
	elsif (@dateNos == 8) { ### golite, eg: 20050421
	    $date = $dateNos[6] . $dateNos[7];
	    $releaseNm = $year . '-' . $month . '-' . $date;
	}
    }
    ###

    my $mysqlargs = $self->mysqlargs;

    $self->runcmds("mysql $mysqlargs -e 'delete from instance_data'",
		   "mysql $mysqlargs -e \"insert into instance_data (release_name, release_type) values ('".$releaseNm."', '$suff')\"");

#    chdir($self->workdir);
    if (-d $t) {
	my $time = time;
	$self->runcmds("mv $t OLD.$time.$t");	
    }
    eval {
	$self->runcmds("mkdir $t",
		       "chmod 777 $t",
		       "cd $t; chmod 777 .",
		       "mysqldump --compatible=mysql40 -T $t $mysqlargs",
		       
		       # some WEIRD problem with tar on the bdgp machines;
		       # it seems we need to sleep for a bit otherwise tar
		       # fails
		       "sleep 60",
		       "ls -alt $t > LISTING.$t",
		       "tar cvf $tt $t",
		       "$GZIP $tt",
		      );
    };
    
    $self->runcmds("mysqldump --compatible=mysql40 $mysqlargs > $td",
		   "$GZIP $td",
		  );
    my $report_file = $distn.'-summary.txt';
    open(F, ">$report_file") || $self->throw("can't open $report_file");
    print F $self->report;
    close(F);
    $self->runcmds("$GZIP $report_file");
}
*makedist = \&make_release_tarballs;

sub runcmds {
    my $self = shift;
    my @cmds = @_;
    my $cmd;

    while ($cmd = shift @cmds) {
        print STDERR "CMD: $cmd\n";
	$self->runcmd($cmd);
    }
}



sub runcmd {
    my $self = shift;
    my $c = shift;
    my $fallible;
    if ($c =~ /^\*(.*)/) {
	$c = $1;
	$fallible = 1;
    }
    trace0("running:$c\n");
    my $err = system($c);
    if ($err) {
	if ($fallible) {
	    warn "error in:$c";
	}
	else {
	    confess "error in:$c";
	}
    }
    return $err;
}

sub loadp {
    my $self = shift;
    my $f = shift;
    open(F, $f) || $self->throw("Cannot open $f");
    while(<F>) {
	chomp;
	s/^ *//;
	s/ *$//;
	next if /^\#/;
	next unless $_;
	my ($p, @v) = split(/\s*:\s*/, $_);
	$self->$p(join(':', @v));
    }
    close(F);
}

sub savep {
    my $self = shift;
    my $f = shift;
    open(F, ">$f") || $self->throw("Cannot open $f for writing");
    my @p = $self->_valid_params;
    foreach (@p) {
	printf F "$_:".$self->$_()."\n";
    }
    close(F);
}

sub apph {
    my $self = shift;
    $self->{_apph} = shift if @_;
    if (!$self->{_apph}) {
	my @p = (-dbname=>$self->dbname);
	if ($self->dbhost) {
	    push(@p, -dbhost=>$self->dbhost);
	}
	if ($self->dbms) {
	    push(@p, -dbms=>$self->dbms);
	}
	if ($self->dbuser) {
	    push(@p, -dbuser=>$self->dbuser);
	}
	if ($self->dbauth) {
	    push(@p, -dbauth=>$self->dbauth);
	}
	if ($self->dbport) {
	    push(@p, -dbport=>$self->dbport);
	}
	if ($self->dbsocket) {
	    push(@p, -dbsocket=>$self->dbsocket);
	}
	eval {
	    $self->{_apph} =
	      GO::AppHandle->connect(@p);
	};
    }
    return $self->{_apph};
}

sub is_connected {
    my $self = shift;
    my $apph = $self->apph;
    if ($apph) {
	my $dbh = $apph->dbh;
	return $dbh->{Active};
    }
    return 0;
}

sub guess_release_type {
    my $self = shift;
    my $apph = $self->apph;
    my $dbh = $apph->dbh;
    my @t =
      qw(term
	 term_definition 
	 term_synonym    
	 graph_path      
	 association     
	 gene_product    
	 gene_product_count
	 seq
	 species);
    my %c =
      map {
	  $_ => 
	    select_val($dbh,
		       $_,
		       undef,
		       "count(*)");
      } @t;
    $c{iea} =
      select_val($dbh,
		 "evidence",
		 "code = 'IEA'",
		 "count(*)");
    my $type = "unknown";
    if (!$c{term_definition} ||
	!$c{term_synonym} ||
	!$c{term} ||
	!$c{graph_path}) {
	$type = "incomplete";
    }
    elsif (!$c{association}) {
	$type = "termdb";
    }
    elsif (!$c{gene_product} ||
	   !$c{gene_product_count}) {
	$type = "assocdb-incomplete";
    }
    elsif ($c{seq}) {
	$type = "seqdb";
	if (!$c{iea}) {
	    $type = "seqdblite";
	}
    }
    elsif (!$c{iea}) {
	$type = "assocdblite";
    }
    else {
	# everything bar seq is present
	$type = "assocdb";
    }

    if ($type ne 'termdb' && 
	!select_val($dbh,
		    "species",
		    "common_name is not null",
		    "count(*)")) {
	
	print STDERR "\nYOU NEED TO LOAD SPECIES\n\n";
    }
	
    print STDERR "\nGuessing... Type is $type\n";
    return $type;
}

sub tcount {
    my $self = shift;
    require "DBIx/DBSchema.pm";
    my $dbh = $self->apph->dbh;
    my $schema = DBIx::DBSchema->new_native($dbh);
    my @table_names = sort $schema->tables;
    foreach (@table_names) {
	my $rows =
	  $dbh->selectcol_arrayref("SELECT COUNT(*) FROM $_");
	my $count = shift @$rows;
	if (!defined($count)) {
	    print STDERR "COULD NOT QUERY:$_\n";
	    exit 1;
	}
	print "$_: $count\n";
    }
}

sub stats {
    my $self = shift;
    my $dbh = $self->apph->dbh;

    my @types =
      @{select_vallist($dbh, "term", undef, "distinct term_type")};
    my @xdbs =
      @{select_vallist($dbh, "dbxref", undef, "distinct xref_dbname")};
    my @gpdbs =
      @{select_vallist($dbh, 
		       "dbxref INNER JOIN gene_product ON (dbxref_id=dbxref.id)", 
		       undef, 
		       "distinct xref_dbname")};
    my @evcodes =
      @{select_vallist($dbh, "evidence", undef, "distinct code")};
    my @stats =
      (
       ["Total GO Terms" =>
	select_val($dbh,
		   "term",
		   "term_type != 'relationship'",
		   "count(*)")],
       ["Total GO Terms (not obsolete)" =>
	select_val($dbh,
		   "term",
		   "term_type != 'relationship' AND is_obsolete = 0",
		   "count(*)")],
       (map {
	   ["Total $_" =>
	    select_val($dbh,
		       "term",
		       "term_type = '$_'",
		       "count(*)")]
       } @types),
       (map {
	   ["Total $_ (not obsolete)" =>
	    select_val($dbh,
		       "term",
		       "term_type = '$_' AND is_obsolete = 0",
		       "count(*)")]
       } @types),
       ["GO Terms with defs" =>
	select_val($dbh,
		   "term_definition",
		   undef,
		   "count(*)")],
       ["Synonyms" =>
	select_val($dbh,
		   "term_synonym",
		   "term_synonym.term_synonym not like 'GO:%'",
		   "count(*)")],
       ["Terms with dbxrefs" =>
	select_val($dbh,
		   "term_dbxref INNER JOIN dbxref ON (dbxref_id = dbxref.id)",
		   undef,
		   "count(distinct term_id)")],
       ["Associations" =>
	select_val($dbh,
		   "association",
		   undef,
		   "count(*)")],
       (map {
	   ["Associations type $_" =>
	    select_val($dbh,
		       "association INNER JOIN evidence ON (association.id = association_id)",
		       "code = '$_'",
		       "count(*)")]
       } @evcodes),
       
       (map {
	   ["Associations DB: $_" =>
	    select_val($dbh,
		       q[association 
			 INNER JOIN 
			 gene_product ON (gene_product.id = gene_product_id)
			 INNER JOIN
			 dbxref       ON (dbxref_id = dbxref.id)],
		       "dbxref.xref_dbname = '$_'",
		       "count(distinct association.id)")]
       } @gpdbs),
       
       (map {
	   ["Gene Products DB: $_" =>
	    select_val($dbh,
		       q[ 
			 gene_product
			 INNER JOIN
			 dbxref       ON (dbxref_id = dbxref.id)],
		       "dbxref.xref_dbname = '$_'",
		       "count(*)")]
       } @gpdbs),
       
       (map {
	   ["Seqs DB: $_" =>
	    select_val($dbh,
		       q[
			 gene_product_seq
			 INNER JOIN
			 gene_product ON (gene_product_id = gene_product.id)
			 INNER JOIN
			 dbxref       ON (dbxref_id = dbxref.id)],
		       "dbxref.xref_dbname = '$_'",
		       "count(distinct gene_product.id)")]
       } @gpdbs),
       
      );
    @stats;		  
}

sub report {
    my $self = shift;
    my $name = shift || $self->releasename . '_' . $self->guess_release_type;
    my @stats = $self->stats;
    push(@stats, ["GUESSED TYPE" => $self->guess_release_type]);
    sprintf("REPORT ON: $name\n==========\n%s\n",
	    join('', 
		 map {sprintf("%20s:%s\n", @$_)} @stats));
}

sub check_rdfxml_rfile {
    my $self = shift;
    my $f = shift;
    my $fh;
    if ($f =~ /\.gz$/) {
	$fh = FileHandle->new("gzcat $f|");
    }
    else {
	$fh = Filehandle->new($f);
    }
    $fh || die("cant open $f");
    # should do seperate proper rdfxml check, validate
    my $nt = 0;
    my $nd = 0;
    my $na = 0;
    my $ns = 0;
    
    while(<$fh>) {
	/\<go:term[\>\s]/ && $nt++;
	/\<go:definition[\>\s]/ && $nd++;
	/\<go:association[\>\s]/ && $na++;
	/\<go:synonym[\>\s]/ && $ns++;
    }
    $fh->close;
    return
      sprintf("TERMS:     $nt\n".
	      "DEFS:      $nd\n".
	      "ASSOCS:    $na\n".
	      "SYNS:      $ns\n");
}

sub check_fasta_rfile {
    my $self = shift;
    my $f = shift;
    my $fh;
    if ($f =~ /\.gz$/) {
	$fh = FileHandle->new("gzcat $f|");
    }
    else {
	$fh = Filehandle->new($f);
    }
    $fh || die("cant open $f");
    my $nseq = 0;
    
    while(<$fh>) {
	/^\>/ && $nseq++;
    }
    $fh->close;
    return
      sprintf("SEQS:      $nseq\n");
}

# IEAs take up a lot of space in db
sub remove_iea {
    my $self = shift;
    my $apph = $self->apph;
    $apph->remove_iea;
}


sub load_termdb {
    my $self = shift;
    my $data_root = $self->data_root;
    if ($self->use_reasoner) {
        $self->load_go('obo_text', "$data_root/ontology/gene_ontology_edit.obo", "-add_root -reasoner -e load_termdb.err-xml");
        $self->run_reasoner();
    }
    else {
        $self->load_go('obo_text', "$data_root/ontology/gene_ontology_edit.obo", "-add_root -fill_path -e load_termdb.err-xml");
    }
    $self->load_go('go_xref', "$data_root/external2go/*2go", "-e load_xref.err-xml");
}

sub populate_graph_path {
    my $self = shift;
    if ($self->use_reasoner) {
        $self->run_reasoner();
    }
    else {
        $self->load_go('obo_text', "", " -fill_path");
    }
}

sub load_assocdb {
    my $self = shift;
    my $bulk_load = shift;
    my $extra = shift;
    my $data_root = $self->data_root;

    # stuff needed for bulk load
    my $sqldir = $self->sqldir;
    my $mysqlargs = $self->mysqlargs;

    # always load from compressed files
    my @files = glob("$data_root/gene-associations/gene_association.*.gz");
    my $auth = $self->db_auth_string;

    if ($bulk_load eq 'bulk') { # quick hack to ignore flag
	$self->runcmd ("load-go-assoc-bulk.pl $auth -local-infile 1 -fill_count -e load_assocdb.err-xml $extra @files");
    } else { 
	$extra .= " $bulk_load" if $bulk_load; # in case called with 1 arg.
	$self->load_go('go_assoc', "@files", "-fill_count", $extra, "-e load_assocdb.err-xml");
    }
}

sub load_xrf_abbs {
    my $self = shift;
    my $data_root = $self->data_root;
    $self->load_go('xrf_abbs', "$data_root/doc/GO.xrf_abbs", "-e load_xrf_abbs.err-xml");
}

sub load_go {
    my $self = shift;
    my $dt = shift;
    my $f = shift;
    my $extra = shift || '';
    my $auth = $self->db_auth_string;

    $self->runcmd ("load-go-into-db.pl $auth -datatype $dt $extra $f");
}

sub run_reasoner {
    my $self = shift;
    my $auth = $self->db_auth_string;
    
    $self->runcmd("go-db-reasoner.pl $auth");
}

sub check_release_tarballs {
    my $self = shift;
    my $tmpdbname = $self->tmpdbname;
    my $r = $self->releasename;
    my $f = $self->releasename . '-CHECK';
   
    ### my $auth = $self->db_auth_string(dbname=>$tmpdbname, method=>'tarballs');
    ### AS, Apr 19, 2005
    ### should modify db_auth_string() to include an option for -f flag
    ### hard coding values for temporary database name and
    ### configuration file in the meantime

    my $auth = "-d test_go -f go-manager.conf";

	if ($r =~ /daily/) {
		my $f2 = 'go_daily.autoQC';
    	$self->runcmds(
			"(go-check-release-tarball.pl $auth $r*.gz | tee $f2) > $f 2>&1"
			);
	} else {
		$self->runcmds("go-check-release-tarball.pl $auth $r*.gz  > $f 2>&1");
	}
}

sub dumprdfxml {
    my $self = shift;
    my $suff = shift || $self->guess_release_type;
    my $f = $self->releasename . '-' .$suff . '.rdf-xml';

    my $auth = $self->db_auth_string;
    $self->runcmds("go-dump-rdf-xml.pl $auth > $f", "$GZIP $f");
}

sub dumpoboxml {
    my $self = shift;
    my $suff = shift || $self->guess_release_type;
    my $data_root = $self->data_root;
    my $f = $self->releasename . '-' .$suff . '.obo-xml';
    $self->runcmds("go2obo_xml $data_root/ontology/gene_ontology_edit.obo > $f && $GZIP $f");
}

sub dumpowl {
    my $self = shift;
    my $suff = shift || $self->guess_release_type;
    my $data_root = $self->data_root;
    my $f = $self->releasename . '-' .$suff . '.owl';
    $self->runcmds("go2owl $data_root/ontology/gene_ontology_edit.obo > $f && $GZIP $f");
}

sub dumpseq {
    my $self = shift;
    my $suff = shift || $self->guess_release_type;
    my $f = $self->releasename . '-' .$suff . '.fasta';
    my $auth = $self->db_auth_string;
    $self->runcmds("go-get-seqs.pl $auth -all -fullheader -skipnogo -withname > $f",
		   "$GZIP $f");
}

sub load_seqs {
    my $self = shift;
    my $bulk_load = shift;
    my $auth = $self->db_auth_string;
    my $data_root = $self->data_root;
    my $swissdir = $self->swissdir || 'proteomes';
    my $uniprotdir = $self->uniprotdir || 'uniprot';
    my $suff = shift || $self->guess_release_type;
    my $distn = $self->releasename . '-' .$suff;
   

    my $log = "./gp2protein_fail.log";
    if ($bulk_load eq 'bulk') {
	# new bulk loading version
	$self->runcmd("load-sp-bulk.pl $auth -local-infile 1 -log $log -nouni -verbose $data_root/gp2protein/gp2protein.*");

    } else {
# force uncompress of *.gz files, even if uncompressed file exists
	$self->runcmd("gunzip -f $data_root/gp2protein/gp2protein.*.gz");
	my $fasta = $distn."-min.fasta";
	$self->runcmd("load_sp.pl $auth -nouni -uniprotdir $uniprotdir -out $fasta -log $log -verbose $data_root/gp2protein/gp2protein.*");
# Added -noncbi flag to save us from NCBI
#	$self->runcmd("load_sp.pl $auth -nouni -uniprotdir $uniprotdir -out $fasta -log $log -verbose -noncbi $data_root/gp2protein/gp2protein.*");

    }

}

sub load_species {
    my $self = shift;
    my $auth = $self->db_auth_string;
    my $data_root = $self->data_root;
    my $speciesdir = $self->speciesdir || 'ncbi';
    $self->runcmd("load-tax-into-db.pl $auth $speciesdir/names.dmp");
    $self->runcmd("load-tax-hierarchy-into-db.pl $auth $speciesdir/nodes.dmp");
}

sub load_refg {
    my $self = shift;
    my $auth = $self->db_auth_string;
    my $data_root = $self->data_root;
    $self->runcmd("wget -O refg_id_list.txt --passive-ftp ftp://ftp.informatics.jax.org/pub/curatorwork/GODB/refg_id_list.txt");
    $self->runcmd("load-refg-set-full.pl $auth refg_id_list.txt");
}

sub db_auth_string {
   my $self = shift;
   my (%args) = @_;

   my $auth_string = "";

   if (defined ($args{dbname})) {
       $auth_string .= " -d ".$args{dbname};
   } 
   else {
       $auth_string .= " -d ".$self->dbname;
   }
 
   $auth_string .= " -h ".$self->dbhost;
   $auth_string .= " -u ".$self->dbuser if ($self->dbuser);
   $auth_string .= " -p ".$self->dbauth if ($self->dbauth);
   $auth_string .= " -dbsocket ".$self->dbsocket if ($self->dbsocket);
   $auth_string .= " -dbport ".$self->dbport if ($self->dbport);

   return $auth_string;
}

sub trace0 {
    my @m = @_;
    print STDERR "@m";
}

1;
