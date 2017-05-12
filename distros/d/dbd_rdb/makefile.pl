# -*- perl -*-

require 5.005;
use strict;
use vmsish;
use ExtUtils::MakeMaker;
use DBI::DBD;
use Config;

my $obj_ext = $Config{'obj_ext'} || '.obj';

my %opts =
    ('NAME' => 'DBD::RDB',
     'DISTNAME' => 'DBD_RDB',
     'AUTHOR' => 'Andreas Stiller (andreas.stiller@nospam.eds.com)',
     'PMLIBDIRS' => [qw(DBD)],
     'VERSION_FROM' => 'rdb.pm',
     'INC' => 'perl_root:[lib.site_perl.VMS_AXP.auto.dbi]',
     'C' => [ qw(dbdimp.c) ],
     'OBJECT' => "rdb$obj_ext dbdimp$obj_ext dbdsql$obj_ext",
    clean => { FILES => 'test.rdb test.snp rdb.xsi dbdsql.h *.tar-gz' },
    dist  => {  DIST_DEFAULT    => 'clean distcheck disttest zipdist'}
     );


ExtUtils::MakeMaker::WriteMakefile(%opts);


package MY;

sub postamble {
DBI::DBD::dbd_postamble().
"
.FIRST
      @ define/nolog lnk\$library sys\$library:sql\$user.olb
      @ tar :== vmstar
      @ set proc/parse=trad

.SUFFIXES .sqlmod

.sqlmod.obj :
      mc sql\$mod \$(mms\$source) /c_proto/connect/warn=nodeprecate

dbdimp.obj : dbdsql.obj

";
}

sub libscan {
    my($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
}
