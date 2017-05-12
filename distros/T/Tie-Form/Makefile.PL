
####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# Docs::Site_SVD::Tie_Form 
#
# Don't edit this file, edit instead
#
# Docs::Site_SVD::Tie_Form
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my $tests = join ' ',unix2os('t/Tie/Form.t');


WriteMakefile(
    NAME => 'Tie::Form',
    DISTNAME => 'Tie-Form',
    VERSION  => '0.02',
    dist     => {COMPRESS => 'gzip',
                'gz' => 'gz'},
    test     => {TESTS => $tests},
    PREREQ_PM => {'Tie::Layers' => '0.01',
                  'Data::Startup' => '0.02',},
    

    ($] >= 5.005 ?     
        (AUTHOR    => 'SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.comE <gt>',
        ABSTRACT  => 'Text database with simple escapes so separation characters never
appear in the data. The text file resembles mimics hard copy
forms. There is a very liberal acceptance of separation sequences.', ) : ()),
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

