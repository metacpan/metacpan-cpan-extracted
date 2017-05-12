# Let the code begin...

require 5.003;
use ExtUtils::MakeMaker;

if (system("which wget > /dev/null")) {

    print <<EOM;

 ** WARNING **

Your system does not have the wget executable - this is required if you
intend to build your own go-database. If you do intend to query a
pre-built database, you may continue safely.

wget comes as standard on most linux distributions. You should be able
to find a copy for more unixes. If you use OS X, wget is available via
fink

EOM

}

my $p = "XML::LibXSLT";
if (!eval "require $p") {

    print <<EOM;

WARNING: ** You do not have XML::LibXSLT installed **

This is required if you intend to build your own go-database. If you
do intend to query a pre-built database, you may continue
safely. However, the test suite will not work.

EOM
    ; 
    #
}
  
if (!$ENV{GO_ROOT}) {

    print <<EOM;

 ** WARNING **

You do not have the environment variable GO_ROOT set. This is required
for building the database, so that the system known where the XSL
files live.

You should set this to wherever your go-dev distribution lives; eg

  setenv GO_ROOT $HOME/go-dev/

If you are having problems installing XML::LibXSLT, please consult

  http://www.godatabase.org/dev/xml/doc/xml-doc.html

EOM

}

my $p = "DBIx::DBStag";
if (!eval "require $p") {
    print <<MSG;

 ** WARNING **

You do not have DBIx::DBStag

This is required for some of the tests in the test suite, and for
building the GO Database. If you intend to use a pre-built database,
you can ignore these errors.

MSG

}

$do_autoload_finesse = 0;
$NAME     = 'GO';
$DISTNAME = "GO";
$VERSION  = "0.01";

if( $do_autoload_finesse == 1 ) {
    fatal("Autoload finessing does not work at the moment!");
}

@BACKUP_FILES = ();

# (plagiarised from the bioperl Makefile.PL)

sub check_package {
    my ($name,$str) = @_;
    my($ver,$desc,$expl,@modules);

    ($ver,$desc,$expl,$module) = split( /\// , $str);
    if( !eval "require $name") {
	print "** WARNING **\n  External Module $name, $desc,\n is not installed on this computer.\n\n\n";
	return 1;
    }

    return 0;
}

if( $do_autoload_finesse ) {

    print "GO module installation\nPreparing modules for AUTOLOADing...";
    `perl -p -i.bak -e 's/#__END__/__END__/' Seq.pm`;
    print "done.\n\n";
}

$error = 0;
foreach $name ( keys %packages ) {
    if( &check_package($name,$packages{$name}) == 1 ) {
	$error = 1;
    }
}
if (check_package('GO::Model::Graph','go-perl')) {
    print <<GO_PERL

You do not appear to have the go-perl module loaded, or if you do, you
have not set PERL5LIB appropriately

go-perl is required for go-db-perl

Please read the installation instructions, either online
http://www.godatabase.org/dev

or locally; see the dir
  go-dev/go-perl
  go-dev/go-perl/doc/go-perl-doc.html

GO_PERL
}

our $CONF = "t/go-test.conf";
use lib '.';
use GO::Admin;

my $admin = GO::Admin->new;

if (-f $CONF) {
    $admin->loadp($CONF);
}

#if (-f "t/go-test-config.pl") {
#    eval {
#        require "t/go-test-config.pl";
#    };
#    warn($@) if $@;
#}

print <<INTRO_MSG;

go-db-perl: Gene Ontology Database API

Online documentation - http://www.godatabase.org/dev

Local documentation  - see 
                         go-dev/go-db-perl/doc/go-db-perl-doc.html

In order to test and install the API, you need database creation
privileges on a mysql database server. this is so that I can build a
few test databases to check everything is working. if you dont have
network access to any nearby servers, consider installing mysql
locally - see www.mysql.org

you will also need read access to a fully populated GO database. You can use
the main GO one or populate your own from the exports here:

http://www.godatabase.org/dev/database

INTRO_MSG

my $default = $admin->dbhost || "localhost";
print "\nmysql server address [$default]:";
my $svr = <STDIN>;
chomp $svr;
if (!$svr) {$svr = $default}
$admin->dbhost($svr);

$default = $admin->dbname || "go";
print "\nname of readonly populated GO database[$default]:";
my $db = <STDIN>;
chomp $db;
if (!$db) {$db = $default}
$admin->dbname($db);

$default = $admin->dbuser || "";
print "\nname of dbuser (optional)[$default]:";
my $dbuser = <STDIN>;
chomp $dbuser;
if (!$dbuser) {$dbuser = $default}
$admin->dbuser($dbuser);

$default = $admin->dbauth || "";
print "\ndb password (optional)[$default]:";
my $dbauth = <STDIN>;
chomp $dbauth;
if (!$dbauth) {$dbauth = $default}
$admin->dbauth($dbauth);

#if (!$ENV{GO_ROOT}) {
if (!$admin->godevdir) {
   print <<MSG1;

 ** WARNING **

You do not have the environment variable GO_ROOT set; you should
set this to wherever you have the go-dev repository checked out
(this should be the directory one above this one)

MSG1
}


$admin->savep($CONF);
#open(F, ">t/go-test-config.pl");
#print F '$ENV{GO_DATABASE_SERVER}="'.$svr."\";\n";
#print F '$ENV{GO_TEST_READONLY_DATABASE_NAME}="'.$db."\";\n";
#close(F);

if( $error == 1 ) {
    print <<QQ_ERROR_QQ;

Warning:

   There are some external packages, listed above, which GO
   uses. 

   The installation of these external packages is very simple. You
   can find them at www.cpan.org

   please read the file INSTALL

QQ_ERROR_QQ
}

WriteMakefile(
              NAME	=> 'GO',
	      'DISTNAME'         => "go-db-perl",
	      'ABSTRACT'     => 'GO-DB Perl',
	      'AUTHOR'       => 'Chris Mungall <cjm at fruitfly dot org>',
	      'VERSION_FROM' => "GO/AppHandle.pm",
              PREREQ_PM => {
                            'Carp' => '0.0/Carp',
                            'DBI' => '0.0/DBI for DbUtils::SqlWrapper',
                            'Set::Scalar' => '0.0/Scalar',
                            'Digest::MD5' => '0.0/MD5',
                            'Data::Stag'  => '0.0/Stag',
                            'DBIx::DBStag'  => '0.06',
#                            'go-perl' => '0.05',
                            'Bio::Seq' => '0.0/bioperl',
                            'FreezeThaw' => '0.0',
                           },
              'dist'      => {  COMPRESS     => 'gzip -9f',
                                SUFFIX       => '.gz', 
                                DIST_DEFAULT => 'all tardist',
                             },
              'realclean'  => {  FILES        => join(' ',@BACKUP_FILES) }
             );


sub cleanup {
my $sig = @_;
print "\n** [$0] Caught a SIG$sig -- cleaning up and shutting down.\n";

exit(0);
}

sub MY::postamble {
  qq{

pod :: \
	go-perl-make-pod-html.pl < MANIFEST

  };  
}


