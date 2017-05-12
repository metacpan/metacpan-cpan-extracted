use 5.12.0;
use strict;
use warnings;
use Test::More;
use File::Path;
use File::Slurp;

use_ok("WWW::SFDC::Zip");

my $FOLDER = "temp_test";

my $ZIP = 'UEsDBBQACAgIAJRafEUAAAAAAAAAAAAAAAAeAAAAdW5wYWNrYWdlZC9vYmplY3RzL1NpdGUub2JqZWN0TY1BDsIgEADvvIJwl0VjjDFADya9etEHUFi1pkDDbo3Pt8fOcZLJ2O6XJ/nFRmMtTu21URJLrGksL6ce9353Vp0X9roQ13wbPhhZrkkhp97M8wWAapg1PWuLqGPNcDDmBOYIGTmkwEF5IVcsljBM2CMm8twWtLA1wsL24cUfUEsHCLyaO4x+AAAAmgAAAFBLAwQUAAgICACUWnxFAAAAAAAAAAAAAAAAIgAAAHVucGFja2FnZWQvd29ya2Zsb3dzL1NpdGUud29ya2Zsb3cNyksOwiAQANA9pyCzL0MbY4yBsusJalwTPkosDAGiHl/f+inzzQd/h9YTFQ2zkMBDceRTeWi47dt0AbMydaf2igd9+L+XruE5Rr0idrJV9EjNBeEo4yLlGeUJcxjW22EBV8Z+UEsHCF464fpkAAAAZAAAAFBLAwQUAAgICACUWnxFAAAAAAAAAAAAAAAAFgAAAHVucGFja2FnZWQvcGFja2FnZS54bWydkLsOwjAMRfd8RZWdOjyEEErTAYkVJEDMaeqW0iapmvD6e6o+BAsLnnxs61i6PH7qKrhj4wprIjoNGQ3QKJsWJo/o6bidrGgsCN9LVcocg/bauIhevK/XAM7KOnSZbRSGymqYMbYEtgCNXqbSSypI0Bb3rxpd33esUSftS3EoPHIY6bM3UqPY3Jy3epdcUXkO3ai3wZfuP/XZNmVW2cdv7ZCImLeJcBiJcBiCEOQNUEsHCOAiLgKvAAAAOgEAAFBLAQIUABQACAgIAJRafEW8mjuMfgAAAJoAAAAeAAAAAAAAAAAAAAAAAAAAAAB1bnBhY2thZ2VkL29iamVjdHMvU2l0ZS5vYmplY3RQSwECFAAUAAgICACUWnxFXjrh+mQAAABkAAAAIgAAAAAAAAAAAAAAAADKAAAAdW5wYWNrYWdlZC93b3JrZmxvd3MvU2l0ZS53b3JrZmxvd1BLAQIUABQACAgIAJRafEXgIi4CrwAAADoBAAAWAAAAAAAAAAAAAAAAAH4BAAB1bnBhY2thZ2VkL3BhY2thZ2UueG1sUEsFBgAAAAADAAMA4AAAAHECAAAAAA=='; # contains Site.object, Site.workflow

my $OBJECT = '<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <enableFeeds>true</enableFeeds>
</CustomObject>
';

my $WORKFLOW = '<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata"/>

';

my $PACKAGE = '<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Site</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Site</members>
        <name>Workflow</name>
    </types>
    <version>31.0</version>
</Package>
';

rmtree $FOLDER if -e $FOLDER;

rmtree $FOLDER if -e $FOLDER;

subtest "unzip pre-defined zip file", sub {
  WWW::SFDC::Zip::unzip($FOLDER, $ZIP);
  ok -e "$FOLDER/objects/Site.object";
  is (read_file("$FOLDER/objects/Site.object"), $OBJECT);
  ok -e "$FOLDER/workflows/Site.workflow";
  is (read_file("$FOLDER/workflows/Site.workflow"), $WORKFLOW);
  ok -e "$FOLDER/package.xml";
  is (read_file("$FOLDER/package.xml"), $PACKAGE);
  done_testing();
};

subtest "zip and unzip is eidempotent", sub {
  my $newZip = WWW::SFDC::Zip::makezip("$FOLDER", "objects/Site.object",
          "workflows/Site.workflow",
          "package.xml");

  rmtree $FOLDER;
  WWW::SFDC::Zip::unzip($FOLDER, $newZip);
  ok -e "$FOLDER/objects/Site.object";
  is (read_file("$FOLDER/objects/Site.object"), $OBJECT);
  ok -e "$FOLDER/workflows/Site.workflow";
  is (read_file("$FOLDER/workflows/Site.workflow"), $WORKFLOW);
  ok -e "$FOLDER/package.xml";
  is (read_file("$FOLDER/package.xml"), $PACKAGE);
  done_testing();
};

subtest "can skip file using callback", sub {
  rmtree $FOLDER;
  WWW::SFDC::Zip::unzip(
    $FOLDER, $ZIP,
    sub {
      my ($path, $content) = @_;
      $content = "" if $path =~ /\.object/;
      return $content;
    });
  ok !-e "$FOLDER/objects/Site.object";

  ok -e "$FOLDER/workflows/Site.workflow"
    and is (read_file("$FOLDER/workflows/Site.workflow"), $WORKFLOW);
  ok -e "$FOLDER/package.xml"
    and is (read_file("$FOLDER/package.xml"), $PACKAGE);
  done_testing();
};

subtest "can modify file using callback", sub {
  rmtree $FOLDER;
  WWW::SFDC::Zip::unzip(
    $FOLDER, $ZIP,
    sub {
      my ($path, $content) = @_;
      $content =~ s/<enableFeeds>true<\/enableFeeds>/<enableFeeds>false<\/enableFeeds>/;
      return $content;
    });
  ok -e "$FOLDER/objects/Site.object"
    and is read_file("$FOLDER/objects/Site.object"),
    '<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <enableFeeds>false</enableFeeds>
</CustomObject>
';
    ;

  ok -e "$FOLDER/workflows/Site.workflow"
    and is read_file("$FOLDER/workflows/Site.workflow"), $WORKFLOW;
  ok -e "$FOLDER/package.xml"
    and is read_file("$FOLDER/package.xml"), $PACKAGE;
  done_testing();
};

rmtree $FOLDER;

done_testing();
