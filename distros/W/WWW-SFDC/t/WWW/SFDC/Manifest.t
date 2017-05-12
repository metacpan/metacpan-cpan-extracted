use 5.12.0;
use strict;
use warnings;

use Data::Dumper;
use Test::More;

use lib 't';
use setup;

#make sure we can load the library
use WWW::SFDC::Constants;
use_ok("WWW::SFDC::Manifest") or BAIL_OUT("Couldn't load WWW::SFDC::Manifest");

ok my $manifest = WWW::SFDC::Manifest->new(
  constants => WWW::SFDC::Constants->new(TYPES => $setup::TYPES)
);

diag "SECTION _splitLine";

my @splitLineData = ({
  input => "objects/lead.object",
  output => {
    extension => ".object",
    name => "lead",
    type => "objects"
  }, reason => "Split object"
},{
  "input" => "email/foo/bar.email",
  "output" => {
    "extension" => ".email",
    "name" => "bar",
    "type" => "email",
    "folder" => "foo"
  }, "reason" => "Split email"
},{
  "input" => "classes/foo.cls-meta.xml",
  "output" => {
    "extension" => ".cls",
    "type" => "classes",
    "name" => "foo"
  }, "reason" => "SplitLine should ignore -meta.xml"
},{
  "input" => "quickActions/foo.bar.quickAction",
  "output" => {
    "extension" => ".quickAction",
    "name" => "foo.bar",
    "type" => "quickActions",
  }, "reason" => "Split quickAction"
},{
  "input" => "documents/foo/bar.png",
  "output" => {
    "extension" => "",
    "name" => "bar.png",
    "type" => "documents",
    "folder" => "foo"
  }, "reason" => "Split a document, meaning no extension"
},{
  "input" => "documents/foo/bar.png-meta.xml",
  "output" => {
    "extension" => "",
    "name" => "bar.png",
    "type" => "documents",
    "folder" => "foo"
  }, "reason" => "Split a document, ignoring -meta.xml"
},{
  "input" => "fields/Account:name",
  "output" => {
    "extension" => "",
    "name" => "Account.name",
    "type" => "fields"
  }, "reason" => "Get a subcomponent, replacing : with ."
},{
  "input" => "email/foo-meta.xml",
  "output" => {
    "extension" => "",
    "name" => "foo",
    "type" => "email"
  }, "reason" => "Split a folder meta file"
},{
  "input" => "\nemail/foo-meta.xml\r",
  "output" => {
    "extension" => "",
    "name" => "foo",
    "type" => "email"
  }, "reason" => 'Ignore \\n and \\r'
},{
  "input" => "documents/Apps-meta.xml",
  "output" => {
    "extension" => "",
    "name" => "Apps",
    "type" => "documents"
  }, "reason" => 'documents meta file should work'
});

is_deeply $manifest->_splitLine($$_{"input"}),
  $$_{"output"},
  $$_{"reason"}
  for @splitLineData;



diag "SECTION _getFilesForLine";

my @getFilesForLineData = ({
  "input" => "",
  "output" => [],
  "reason" => "Blank line should return empty list"
},{
  "input" => "objects/foo.object",
  "output" => ["objects/foo.object"],
  "reason" => "Objects don't need any other files"
},{
  "input" => "documents/foo/bar.png",
  "output" => ["documents/foo-meta.xml", "documents/foo/bar.png", "documents/foo/bar.png-meta.xml"],
  "reason" => "Documents need a meta and a folder-meta file"
},{
  "input" => "triggers/foo.trigger",
  "output" => ["triggers/foo.trigger", "triggers/foo.trigger-meta.xml"],
  "reason" => "Triggers need a meta file"
},{
  "input" => "reports/foo/bar.report",
  "output" => ["reports/foo-meta.xml", "reports/foo/bar.report"],
  "reason" => "Reports need a folder meta"
});

is_deeply
  [sort($manifest->_getFilesForLine($$_{"input"}))],
  [sort(@{$$_{"output"}})],
  $$_{"reason"}
  for @getFilesForLineData;



diag "SECTION getFileList";

my @completeFileListData = ({
  input => [],
  output => [],
  reason => "Blank input should produce blank output"
},{
  input => ["staticresources/Logo.resource-meta.xml"],
  output => ["staticresources/Logo.resource-meta.xml","staticresources/Logo.resource"],
  reason => "Modifying meta file => deploy actual file too"
},{
  input => ["objects/foo.object","objects/foo.object"],
  output => ["objects/foo.object"],
  reason => "Deduplication should work"
},{
  input => ["documents/foo/bar.png","documents/foo/baz.png"],
  output => [
    "documents/foo-meta.xml",
    "documents/foo/bar.png",
    "documents/foo/baz.png-meta.xml",
    "documents/foo/baz.png",
    "documents/foo/bar.png-meta.xml"
   ],
  reason => "Deduplication with folders"
});

is_deeply
  [
    sort(
      WWW::SFDC::Manifest->new(
        constants => WWW::SFDC::Constants->new(TYPES => $setup::TYPES)
      )->addList(@{ $$_{"input"} })->getFileList()
    )
  ],
  [sort(@{ $$_{"output"}})],
  $$_{"reason"}
  for @completeFileListData;



diag "SECTION _dedupe";

is_deeply
  WWW::SFDC::Manifest->new(
    manifest => {"objects" => ["foo","foo","bar"]},
    constants => WWW::SFDC::Constants->new(TYPES => $setup::TYPES)
  )->_dedupe()->manifest,
  {
    "objects" => ["bar","foo"]};



diag "SECTION addList";

my @getComponentsData = ({
  isDeletion => 0,
  inputs => ["objects/foo.object"],
  output => {"CustomObject" => ["foo"]},
  reason => "Get the components for foo.object",
},{
  isDeletion => 0,
  inputs => ["reports/bar/foo.report"],
  output => {"Report" => ["bar","bar/foo"]},
  reason => "Get the components for bar/foo.report",
},{
  isDeletion => 1,
  inputs => ["reports/bar/foo.report"],
  output => {"Report" => ["bar/foo"]},
  reason => "Folders are omitted when the isDeletion argument is set",
},{
  isDeletion => 0,
  inputs => ["documents/bar/foo.png"],
  output => {"Document" => ["bar","bar/foo.png"]},
  reason => "Folders are included when the isDeletion argument is not set",
},{
  isDeletion => 0,
  inputs =>  ["documents/bar/foo.png", "classes/baz.cls"],
  output =>{
    "Document" => ["bar","bar/foo.png"],
    "ApexClass" => ["baz"]
  },
  reason => "Passing in a list"
});

is_deeply WWW::SFDC::Manifest
  ->new(
    isDeletion=>$$_{isDeletion},
    constants => WWW::SFDC::Constants->new(TYPES => $setup::TYPES)
  )
  ->addList(@{$$_{inputs}})
  ->manifest,
  $$_{output},
  $$_{reason}
  for @getComponentsData;



diag "SECTION getXML";

my @writeXMLdata = ({
  input => {
    "Document" => ["bar","bar/foo.png"]
  },
  output =>  q(<?xml version='1.0' encoding='UTF-8'?><Package xmlns='http://soap.sforce.com/2006/04/metadata'><types><name>Document</name><members>bar</members><members>bar/foo.png</members></types><version>33</version></Package>),
  reason => "Writing XML for a single type"
},{
  input => {
    "Document" => ["bar","bar/foo.png"],
    "ApexClass" => ["baz"]
  },
  output => q{<?xml version='1.0' encoding='UTF-8'?><Package xmlns='http://soap.sforce.com/2006/04/metadata'><types><name>ApexClass</name><members>baz</members></types><types><name>Document</name><members>bar</members><members>bar/foo.png</members></types><version>33</version></Package>},
  reason => "Passing in multiple types",
});

# this test is written thus because the keys of a hash can change around,
# leading to more than 1 possible valid xml output
is WWW::SFDC::Manifest
  ->new(
    manifest => $$_{input},
    apiVersion => 33,
    constants => WWW::SFDC::Constants->new(TYPES => $setup::TYPES)
  )
  ->getXML(),
  $$_{output},
  $$_{reason}
  for @writeXMLdata;


diag "SECTION add";

my @addManifestData = ({
  input1 => {"Document" => ["bar"]},
  input2 => {"Document" => ["bar/foo.png"]},
  output => {"Document" => ["bar","bar/foo.png"]},
  reason => "simple addition"
});

is_deeply
  WWW::SFDC::Manifest->new(
    manifest=>$$_{input1},
    constants => WWW::SFDC::Constants->new(TYPES => $setup::TYPES)
  )->add($$_{input2})->manifest,
  $$_{output},
  $$_{reason}
  for @addManifestData;

is_deeply
  WWW::SFDC::Manifest->new(
    constants => WWW::SFDC::Constants->new(TYPES => $setup::TYPES),
    manifest => $$_{input1})->add(
      WWW::SFDC::Manifest->new(
        manifest => $$_{input2},
        constants => WWW::SFDC::Constants->new(TYPES => $setup::TYPES)
      )
   )->manifest,
  $$_{output},
  $$_{reason}
  for @addManifestData;

TODO: {
  local $TODO = "Manifest file parsing currently untested";

  ok(0);
}

done_testing();
