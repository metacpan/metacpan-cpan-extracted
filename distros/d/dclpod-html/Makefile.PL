use 5.00502;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $exe_ext = '';
$exe_ext = '.com' if $^O eq 'VMS';
$exe_ext = '.bat' if $^O eq 'Win32';
WriteMakefile(
    'NAME'		=> 'DCLPod::Html',
    'VERSION_FROM'	=> 'Html.pm', # finds $VERSION
#    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'EXE_FILES'         => [("dcl2html$exe_ext")], 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Html.pm', # retrieve abstract from module
       AUTHOR     => 'Peter Prymmer <pprymmer@pc.factset.com>') : ()),
);

package MY;

sub postamble {
    return '' if ( $^O ne 'VMS' );
    return << 'EOF';
dcl2html.com : dcl2html.pl
	$(PERL) $(MMS$SOURCE)
EOF
}
