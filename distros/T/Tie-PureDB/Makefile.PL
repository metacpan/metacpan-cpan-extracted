use ExtUtils::MakeMaker;
use ExtUtils::Embed qw[ ccopts ldopts ];
use Config;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $build  = 1; #grep { /^--build/ } @ARGV; # no real good reason to ever skip this
my $cc     = $Config{cc};
my $o      = $Config{_o};
my $ccopts = ccopts();
my $ldopts = ldopts();
my    $INC = ' -I./pure-db-2.1/src ';
my   $LIBS = '-L./pure-db-2.1/src/.libs ';
my $LDFROM = "./pure-db-2.1/src/puredb_write$o ./pure-db-2.1/src/puredb_read$o";
my $system = 0;

if( $^O =~ /mswin/i ) {
    $INC = ' -I./pure-db-2.1/windows ';
    $LIBS = '-L./pure-db-2.1/windows ';
    if( $cc =~ /bcc/ ) {
        require File::Spec;
        $LDFROM = File::Spec->canonpath("./pure-db-2.1/windows/puredb_write$o ");
        $LDFROM .= File::Spec->canonpath("./pure-db-2.1/windows/puredb_read$o");
    } else {
        $LDFROM = "./pure-db-2.1/windows/puredb_write$o ./pure-db-2.1/windows/puredb_read$o";
    }
}



if($build){
    print q[


Attempting to compile pure-db-2.1 ... you need a compiler for this ;)


];

    if( $^O =~ /mswin/i ) {
        chdir 'pure-db-2.1/windows';
        system qw[ clean_all.bat ];
        $system += system qw[build_cl.bat] if $cc =~ /cl/i;
        $system += system qw[build_borland.bat] if $cc =~ /bcc/i;
        chdir '..';
        chdir '..';
    } else {
        chdir 'pure-db-2.1';
#        system qq[./configure CFLAGS='--save-temps $ccopts' LDFLAGS='$ldopts'];
        system qw[ make clean ];
        $system += system qq[./configure];
        $system += system qw[make];
        chdir '..';
    }

}

if( $system ) {
    die q[


Something went wrong building pure-db-2.1 (perhaps you have no compiler?)
Makefile not written.


    
];

}

print q[


Successfully compiled pure-db-2.1 ... or so I think ;)


];


WriteMakefile(
    'NAME'	    	=> 'Tie::PureDB',
    'VERSION_FROM'	=> 'PureDB.pm', # finds $VERSION
    'LDFROM'        => '$(OBJECT) '.$LDFROM,
    'INC'		    => "-I/usr/local/include $INC",
#    'DEFINE'        => '-DPureDEBUG', # if debugging
#    'LIBS'		=> [ ## one of these might work, but you shouldn't need it
#        "$LIBS -llibpuredb_write -llibpuredb_read",
#        "$LIBS -llibpuredb_write$Config{_a} -llibpuredb_read$Config{_a}",
#        "-L/usr/local/lib/ -llibpuredb_write -llibpuredb_read",
#    ],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'PureDB.pm', # retrieve abstract from module
       AUTHOR     => 'D. H. <PodMaster@cpan.org>') : ()),
);


__END__

perl -MFile::Find -le" find(sub{ print $File::Find::name;},@ARGV) " pure-db-2.1
perl -MFile::Find -le" find(sub{ print $File::Find::name if -f $_;},@ARGV) " pure-db-2.1
perl -MFile::Find -le" find(sub{ print $File::Find::name if -f $_;},@ARGV) " pure-db-2.1 >MANIFEST
