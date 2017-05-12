
####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# Docs::Site_SVD::Test_Tech 
#
# Don't edit this file, edit instead
#
# Docs::Site_SVD::Test_Tech
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my $tests = join ' ',unix2os('t/Test/Tech/Tech.t');


WriteMakefile(
    NAME => 'Test::Tech',
    DISTNAME => 'Test-Tech',
    VERSION  => '0.26',
    dist     => {COMPRESS => 'gzip',
                'gz' => 'gz'},
    test     => {TESTS => $tests},
    PREREQ_PM => {'Data::Secs2' => '1.22',
                  'Data::Str2Num' => '0.05',
                  'Data::Startup' => '0.03',
                  'Test' => '1.20',},
    

    ($] >= 5.005 ?     
        (AUTHOR    => 'SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>',
        ABSTRACT  => 'The "Test::Tech" module extends the capabilities of the "Test" module.
It adds the skip_test method to the Test module, and 
adds the ability to compare complex data structures to the Test module.', ) : ()),
);



use File::Spec;
use File::Spec::Unix;
sub unix2os
{
   my @file = ();
   foreach my $file (@_) {
       my (undef, $dir, $file_unix) = File::Spec::Unix->splitpath( $file );
       my @dir = File::Spec::Unix->splitdir( $dir );
       push @file, File::Spec->catfile( @dir, $file_unix);
   }
   @file;
}

