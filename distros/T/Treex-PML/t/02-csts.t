# Test file created outside of h2xs framework.

#########################

use Test::More;
BEGIN { plan tests => 4 };
use Treex::PML;

use warnings;
use strict;
$|=1;


Treex::PML::UseBackends(qw(CSTS));

SKIP: {
  {
    local $Treex::PML::Debug=1;
    my $reason='';
    local $SIG{__WARN__}=sub { $reason.=$_[0] };
    unless (Treex::PML::Backend::CSTS::test_nsgmls()) {
      chomp $reason;
      skip $reason, 4;
    }
  }
  for my $file (qw(
		    ca01.am.gz
		 )) {
    my $fh = File::Temp->new(UNLINK=>0);
    my $tempfile = $fh->filename;
    my ($doc,$doc2);

    eval {
      $doc = Treex::PML::Factory->createDocumentFromFile(File::Spec->catfile('test_data','csts',$file));
      ok (Treex::PML::does($doc,'Treex::PML::Document'),'loaded CSTS document '.$file);
      ok (scalar($doc->trees()) > 0, 'found trees in '.$file);
      $doc->changeURL(URI::file->new($tempfile));
      $doc->save();
      $doc->changeURL(URI::file->new($tempfile)); # clear filename cache
      close $fh;

      $doc2 = Treex::PML::Factory->createDocumentFromFile($tempfile);
      $doc2->changeURL(URI::file->new($tempfile));
    };
    unlink $fh;
    diag($@) if $@;
    ok (!$@, "load/save ok");
    is_deeply($doc2,$doc,"Compare read/write/read CSTS document ".$file);
  }


}
