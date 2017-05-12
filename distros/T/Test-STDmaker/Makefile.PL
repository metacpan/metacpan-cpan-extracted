
####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# Docs::Site_SVD::Test_STDmaker 
#
# Don't edit this file, edit instead
#
# Docs::Site_SVD::Test_STDmaker
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my $tests = join ' ',unix2os('t/Test/STDmaker/basic.t');


WriteMakefile(
    NAME => 'Test::STDmaker',
    DISTNAME => 'Test-STDmaker',
    VERSION  => '0.23',
    dist     => {COMPRESS => 'gzip',
                'gz' => 'gz'},
    test     => {TESTS => $tests},
    PREREQ_PM => {'File::AnySpec' => '1.1',
                  'File::Package' => '1.1',
                  'File::Where' => '1.16',
                  'File::SmartNL' => '1.1',
                  'Text::Replace' => '1.08',
                  'Text::Column' => '1.08',
                  'File::Maker' => '0.03',
                  'Tie::Form' => '0.02',
                  'Tie::Layers' => '0.04',
                  'Test::Harness' => '2.42',
                  'Data::Startup' => '0.02',},
    

    ($] >= 5.005 ?     
        (AUTHOR    => 'SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>',
        ABSTRACT  => 'generate test scripts, demo scripts from a test description short hand.', ) : ()),
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

