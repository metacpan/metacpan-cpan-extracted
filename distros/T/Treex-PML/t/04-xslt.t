# Test file created outside of h2xs framework.
# Run this like so: `perl 04-xslt.t'
#   pajas@ufal.mff.cuni.cz     2010/04/22 15:01:57

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN {
    use constant PLAN => 5;
    plan tests => PLAN;
};

use warnings;
use strict;
$|=1;

use Treex::PML;
use Treex::PML::Instance::Common qw(:diagnostics);
use Cwd qw(abs_path);

SKIP: {
    skip('XML::LibXSLT not available', PLAN) unless eval{ require XML::LibXSLT; 1; };
    # if (XSLT_BUG) {
    #   diag('Buggy libxslt 1.1.27');
    #   skip('Buggy libxslt 1.1.27', PLAN);
    # }

    Treex::PML::AddResourcePath(abs_path(File::Spec->catfile('test_data','alpino')));
    Treex::PML::UseBackends('PML','PMLTransform'); # default will be PML
    Treex::PML::Backend::PML::configure(); # update configuration

    for my $file (qw(18.xml)) {
        my $source = File::Spec->catfile('test_data','alpino',$file);
        my $fh = File::Temp->new(UNLINK=>0);
        my $tempfile = $fh->filename;
        my ($doc, $doc2);
        eval {
            $doc = Treex::PML::Factory->createDocumentFromFile($source);
            ok (Treex::PML::does($doc,'Treex::PML::Document'),'loaded PML instance '.$file);
        };
        if (XSLT_BUG) {
            like($@, qr/failed/, "failed due to buggy libxslt 1.1.27");
            diag('Buggy libxslt 1.1.27');
            skip('Buggy libxslt 1.1.27', PLAN-1);
            next;
        }
        eval {
            $doc->changeURL(URI::file->new($tempfile));
            $doc->save();
            $doc->changeURL(URI::file->new($tempfile)); # clear filename cache
            $fh->close;
        };
        ok(!$@,"write ok");
        diag($@) if $@;
        eval {
            $doc2 = Treex::PML::Factory->createDocumentFromFile($tempfile);
            $doc2->changeURL(URI::file->new($tempfile));
        };
        ok(!$@,"re-read ok");
        diag($@) if $@;
        {
            local $/;
            my $F;
            open $F, '<', $source or die "Cannot open $source: $!";
            my $str1 = <$F>;
            close $F;
            open $F, '<', $tempfile or die "Cannot open $tempfile: $!";
            my $str2 = <$F>;
            close $F;
            is($str1,$str2,'Input and output are equal');
        }
        # unlink $fh;
        is_deeply($doc2,$doc,"Compare read/write/read PML instance ".$file);
    }
}
