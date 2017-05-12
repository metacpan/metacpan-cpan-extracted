# Test file created outside of h2xs framework.

#########################

use Test::More;
BEGIN { plan tests => 4 };
use Treex::PML;

use warnings;
use strict;
$|=1;


Treex::PML::UseBackends(qw(FS));

for my $file (qw(
		  ca01am.fs
	       )) {
  my $fh = File::Temp->new(UNLINK=>0);
  my $tempfile = $fh->filename;
  my ($doc,$doc2);

  eval {
    $doc = Treex::PML::Factory->createDocumentFromFile(File::Spec->catfile('test_data','fs',$file));
    ok (Treex::PML::does($doc,'Treex::PML::Document'),'loaded FS document '.$file);
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
  print "Comparing documents\n";
  is_deeply($doc2->tree(0),$doc->tree(0),"Compare read/write/read FS document ".$file);
}
