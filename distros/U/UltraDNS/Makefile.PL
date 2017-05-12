use strict;
use warnings;
use ExtUtils::MakeMaker;

my %opts = (
    NAME                => 'UltraDNS',
    AUTHOR              => 'Tim Bunce <Tim.Bunce@pobox.com>',
    VERSION_FROM        => 'lib/UltraDNS.pm',
    ABSTRACT_FROM       => 'lib/UltraDNS.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'Net::SSLeay' => 1.35,
        'RPC::XML' => 0.64,
        'XML::LibXML' => 0,
        'MIME::Base64' => 0,
    },
    dist    => {
        DIST_DEFAULT=> 'clean distcheck disttest tardist',
        PREOP => '$(MAKE) -f Makefile.old distdir',
        COMPRESS => 'gzip -v9', SUFFIX => 'gz',
    },
    clean   => { FILES => 'UltraDNS-*' },
);
$opts{LICENSE} = 'perl' if $ExtUtils::MakeMaker::VERSION >= 6.3002;

WriteMakefile(%opts);



# =====================================================================

package MY;


sub post_constants {
    return q{

svnmanifest::
	svn list -R .@HEAD | sort | grep -v '/$$' | grep -v NUS_API_XML > MANIFEST
	svn diff MANIFEST

checkkeywords::
	$(RM_RF) blib
	find . -type f \( -name .svn -prune -o -name \*.pm -o -name \*.PL -o -name \*.pl \) \
	    -exec bash -c '[ -z "$$(svn pg svn:keywords {})" ] && echo svn propset svn:keywords \"Id Revision\" {}' \;

checkpod::
	$(RM_RF) blib
	find . -type f \( -name .svn -prune -o -name \*.pm -o -name \*.PL -o -name \*.pl \) \
	    -exec podchecker {} \; 2>&1 | grep -v 'pod syntax OK'

};
}

