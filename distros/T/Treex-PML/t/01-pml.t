#!perl

use strict;
use warnings;

use Test::More tests => 126;
use Treex::PML;
use File::Spec;
use File::Temp;
use Data::Dumper;
use Cwd qw(abs_path);
use URI::file;

Treex::PML::AddResourcePath(abs_path(File::Spec->catfile('test_data','pml')));

for my $file (qw(
example1.xml
example2.xml
example3.xml
example4.xml
example5.xml
example6.xml
example7.xml
example9.xml
example11.xml)) {
  my $source = File::Spec->catfile('test_data','pml',$file);
  my $fh = File::Temp->new(UNLINK=>0);
  my $tempfile = $fh->filename;

  my $instance = Treex::PML::Factory->createPMLInstance({filename => $source});
  ok (Treex::PML::does($instance,'Treex::PML::Instance'),'loaded PML instance '.$file);
  my $instance2;
  eval {
    $instance->save({fh => $fh});
    $fh->close;

    $instance = Treex::PML::Factory->createPMLInstance({filename => $source, use_resources=>1});
    $instance->set_filename($tempfile);

    $instance2 = Treex::PML::Factory->createPMLInstance({filename => $tempfile, use_resources=>1});
  };
  diag($@) if $@;
  ok(!$@,"read/write ok");
  unlink $fh;

  %{$_->get_references_hash}=() for ($instance,$instance2);
  %{$_->{'_ref'}}=() for ($instance,$instance2);
  %{$_->{'_ref-index'}}=() for ($instance,$instance2);
  is_deeply($instance2,$instance,"Compare read/write/read PML instance ".$file);
}

for my $file (qw(
example1.xml
example2.xml
example3.xml
example7.xml
example9.xml)) {
  my $fh = File::Temp->new(UNLINK=>0);
  my $tempfile = $fh->filename;
  my ($doc,$doc2);

  eval {
    $doc = Treex::PML::Factory->createDocumentFromFile(File::Spec->catfile('test_data','pml',$file));
    ok (Treex::PML::does($doc,'Treex::PML::Document'),'loaded PML document '.$file);
    ok (scalar($doc->trees()) > 0, 'found trees in '.$file);
    $doc->changeURL(URI::file->new($tempfile));
    $doc->save();
    $doc->changeURL(URI::file->new($tempfile)); # clear filename cache
    close $fh;
    $doc->changeMetaData('references',{});
    $doc->changeAppData('ref',{});

    $doc2 = Treex::PML::Factory->createDocumentFromFile($tempfile);
    $doc2->changeURL(URI::file->new($tempfile));
    $doc2->changeMetaData('references',{});
    $doc2->changeAppData('ref',{});
  };
  unlink $fh;
  diag($@) if $@;
  ok (!$@, "load/save ok");
  is_deeply($doc2,$doc,"Compare read/write/read PML document ".$file);
}

my $fh = File::Temp->new(UNLINK=>1);
my $tempfile = $fh->filename;

for my $file (qw(
example1_schema.xml
example3_schema.xml
example4_schema.xml
example5_schema.xml
example6_schema.xml
example11_schema.xml
	       )) {
  my $schema = Treex::PML::Factory->createPMLSchema({filename=>File::Spec->catfile('test_data','pml',$file)});
  ok (Treex::PML::does($schema,'Treex::PML::Schema'),'loaded PML schema '.$file);
  ok (Treex::PML::does($schema->get_root_decl,'Treex::PML::Schema::Decl'),'get root declaration');
  $schema->set_url($tempfile);
  $schema->write({filename => $tempfile});
  my $schema2 = Treex::PML::Factory->createPMLSchema({filename=>$tempfile});
  $schema2->set_url($tempfile);
  is_deeply($schema2,$schema,"Compare read/write/read PML schema ".$file);
}

# these schemas will have different serialization due to line numbers
for my $file (qw(
example2_schema.xml
example7_schema.xml
example8_schema.xml
example9_schema.xml
example10_schema.xml
)) {
  my $schema = Treex::PML::Factory->createPMLSchema({filename=>File::Spec->catfile('test_data','pml',$file)});
  ok (Treex::PML::does($schema,'Treex::PML::Schema'),'loaded PML schema '.$file);
  ok (Treex::PML::does($schema->get_root_decl,'Treex::PML::Schema::Decl'),'get root declaration');
  $schema->set_url($tempfile);
  my $dump = Data::Dumper->new([$schema],['schema'])->Dump;
  $dump=~s/'-##' => \d+/'-##' => 0/g;
  $schema->write({filename => $tempfile});
  my $schema2 = Treex::PML::Factory->createPMLSchema({filename=>$tempfile});
  $schema2->set_url($tempfile);
  my $dump2 = Data::Dumper->new([$schema],['schema'])->Dump;
  $dump2=~s/'-##' => \d+/'-##' => 0/g;
  is($dump,$dump2,"Compare read/write/read PML schema ".$file);

}

for my $file (qw(
templates2_schema.xml
)) {
  my $schema = Treex::PML::Factory->createPMLSchema({filename=>File::Spec->catfile('test_data','pml',$file)});
  ok (Treex::PML::does($schema,'Treex::PML::Schema'),'loaded PML schema '.$file);

  my $meta = $schema->find_type_by_path('!e2.meta.type');
  ok (Treex::PML::does($meta,'Treex::PML::Schema::Struct'),'find meta declaration');
  my $id = $meta && $meta->get_member_by_name('xml:id');
  ok (Treex::PML::does($id,'Treex::PML::Schema::Member'),'find xml:id member');
  is ($id && $id->get_role,'#ID','xml:id has role #ID');

  my $terminal = $schema->find_type_by_path('!e2.terminal.type');
  ok (Treex::PML::does($terminal,'Treex::PML::Schema::Container'),'find terminal declaration');
  ok (Treex::PML::does($terminal->get_content_decl,'Treex::PML::Schema::CDATA'),'terminal content');
  is ($terminal->get_content_decl->get_format,'string','content is a string');
  ok (Treex::PML::does($terminal->get_member_by_name('xml:id'),'Treex::PML::Schema::Attribute'),'terminal has xml:id');
  ok (!defined($terminal->get_member_by_name('id')),'terminal has no member id');
}

for my $file (qw(
example7.xml
example9.xml
	       )) {
  my $file = File::Spec->catfile('test_data','pml',$file);
  my $expected_ref_url = Treex::PML::ResolvePath(Treex::PML::IO::make_abs_URI($file),'example6.xml');

  my $doc = Treex::PML::Factory->createDocumentFromFile($file);
  if ($^O eq 'MSWin32') {
    is(lc($doc->referenceURLHash()->{t}), lc($expected_ref_url),"resolved URL");
  } else {
    is($doc->referenceURLHash()->{t}, $expected_ref_url,"resolved URL");
  }
  is ($doc->referenceNameHash()->{tokenization},'t','reference name maps to reference id');
  is (ref($doc->referenceObjectHash()->{t}),'XML::LibXML::Document','DOM reference read as XML::LibXML::DOM');
}


for my $file (qw(
sample0.a
	       )) {
  my $file = File::Spec->catfile('test_data','pdt',$file);
  my $expected_m_ref_url = Treex::PML::ResolvePath(Treex::PML::IO::make_abs_URI($file),'sample0.m');
  my $expected_schema_url = Treex::PML::ResolvePath(Treex::PML::IO::make_abs_URI($file),'adata_schema.xml');

  my $doc = Treex::PML::Factory->createDocumentFromFile($file);
  ok(Treex::PML::does($doc->schema,'Treex::PML::Schema'),'has schema');
  is($doc->schemaURL,'adata_schema.xml','remembers unresolved schema URL');
  if ($^O eq 'MSWin32') {
    is(lc($doc->schema->get_url),lc($expected_schema_url),'whereas Schema remembers the URL resloved');
  } else {
    is($doc->schema->get_url,$expected_schema_url,'whereas Schema remembers the URL resloved');
  }
  if ($^O eq 'MSWin32') {
    is(lc($doc->referenceURLHash()->{'m'}),lc($expected_m_ref_url),"resolved URL");
  } else {
    is($doc->referenceURLHash()->{'m'}, $expected_m_ref_url,"resolved URL");
  }
  is ($doc->referenceNameHash()->{mdata},'m','reference name maps to reference id');
  is (ref($doc->referenceObjectHash()->{'m'}),'Treex::PML::Instance','PML reference read as Treex::PML::Instance');

  my $node = $doc->lookupNodeByID('a-ln94210-2-p3s1w14');
  ok (Treex::PML::does($node,'Treex::PML::Node'), "loopupNodeByID");
  is ($node->{afun},'Coord','get attribute value');
  is ($node->attr('afun'),'Coord','get attribute value via attr()');
  is ($node->attr('m/tag'),'J^-------------','get nested knitted attribute value via attr()');
  is ($node->attr('m/w/token'),'a','get nested doubly knitted attribute value via attr()');
}

for my $file (qw(
sample0.t
	       )) {
  my $file = File::Spec->catfile('test_data','pdt',$file);
  my $expected_m_ref_url = Treex::PML::ResolvePath(Treex::PML::IO::make_abs_URI($file),'sample0.a');

  my $doc = Treex::PML::Factory->createDocumentFromFile($file);
  if ($^O eq 'MSWin32') {
    is(lc($doc->referenceURLHash()->{'a'}), lc($expected_m_ref_url),"resolved URL");
  } else {
    is($doc->referenceURLHash()->{'a'}, $expected_m_ref_url,"resolved URL");
  }
  is ($doc->referenceNameHash()->{adata},'a','reference name maps to reference id');
  is ($doc->referenceObjectHash()->{'a'},undef,"tree document references not loaded by default");
  my @loaded = $doc->loadRelatedDocuments();
  is (scalar(@loaded),1,'load one reference');
  ok (Treex::PML::does($loaded[0],'Treex::PML::Document'), 'loadRelatedDocuments returns a document...');
  is ($loaded[0], $doc->referenceObjectHash()->{'a'}, '...and it is the adata file');
  my @super = $loaded[0]->relatedSuperDocuments;
  is (scalar(@super),1,'... and has one superior document');
  is ($super[0],$doc,'... which is the current t-document');
}

for my $file (qw(
sample0.t
	       )) {
  my $file = File::Spec->catfile('test_data','pdt',$file);
  my $doc = Treex::PML::Factory->createDocumentFromFile($file);

  my $called=0;
  my @loaded = $doc->loadRelatedDocuments(0,sub { $called++; 0 });
  is ($called,1,'callback called');
  is (scalar(@loaded),0,'no reference loaded');
  eval {
    $doc->loadRelatedDocuments(0,sub { $called++; 'foo_bar.xml' });
  };
  is ($called,2,'callback called');
  ok ($@ =~ /foo_bar\.xml/,"Got error");
  is ($doc->referenceObjectHash()->{'a'},undef,"a document stil not loaded");


  my $adoc = Treex::PML::Factory->createDocumentFromFile($doc->referenceURLHash()->{'a'});
  is ($adoc->schema->get_root_name, 'adata', 'loaded adata');
  @loaded = $doc->loadRelatedDocuments(0,sub { $called++; $adoc });
  is ($called,3,'callback called');
  is (scalar(@loaded),1,'load one reference');
  is ($loaded[0],$adoc, 'loadRelatedDocuments returns the correct document');
  is ($doc->referenceObjectHash()->{'a'},$adoc,"document associated");
  my @super = $adoc->relatedSuperDocuments;
  is (scalar(@super),1,'... and has one superior document');
  is ($super[0],$doc,'... which is the current t-document');
}
