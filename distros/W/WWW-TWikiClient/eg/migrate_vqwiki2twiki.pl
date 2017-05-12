#!/usr/bin/perl

# --------------------------------------------------------------------
# This example script originally lived in
# the Acme::PM::Dresden distribution.
#
# I just renamed Acme::PM::Dresden::TWikiClient into WWW::TWikiClient.
# --------------------------------------------------------------------

# --------------------------------------------------------------------
#
# Example script that demonstrates the usage of these classes:
#
#   WWW::TWikiClient
#   Acme::PM::Dresden::VQWikiClient
#   Acme::PM::Dresden::Convert::VQWiki2TWiki
#
# With this script I migrated a whole VQWiki into an existing TWiki.
#
# It crawls a given list of topics in VQWiki, reads the raw syntax,
# converts them into raw TWiki syntax, eventually capitalizes the
# TWiki topic names and saves the converted content into TWiki.
#
# You can run this script again and again, by watching the result in
# TWiki, finetuning this script and rerun until everything is ok. It's
# just like you would repeatedly edit in TWiki.
#
# Go to ::CUSTOMIZATION AREA:: and set your specific URLs and auth.
#
# --------------------------------------------------------------------

use strict;
use warnings;

use Data::Dumper;
use WWW::TWikiClient;
use Acme::PM::Dresden::VQWikiClient;
use Acme::PM::Dresden::Convert::VQWiki2TWiki;

# topics to migrate,
# you might prefer to generate that list automatically
my @topiclist = (
		 "CurrentProjects",
		 "KnowHow",
		 "ApacheKnowHow",
		 "UnderstandingApacheLicense",
		 "UnderstandingArtisticLicense",
		 "DebianLinux",
		 "TemplateToolkit",
		 "TestTest",
		 # and many many more
		 );

# in case "topiclist" is generated automatically
# you can specify an ignore liste here
my @ignore_topics = (
		     "TextFormattingRules",
		     "webitWikiTipps",
		     "wiki",
		     "LeftMenu",
		     "BottomArea",
		    );

print STDERR "Prepare topic list...\n";

# delete doublettes
my %topiclisthash = map { ($_ => 1) } @topiclist;

# ignore topics
delete @topiclisthash{@ignore_topics};

# ------------------------------------------------------------------
#
# ::CUSTOMIZATION AREA::
#
# ------------------------------------------------------------------
#
# Here you should customize your VQWiki and TWiki access
# (URL, user, password, default TWiki web)
#
# ------------------------------------------------------------------
#
# VQWiki
my $vqwiki = new Acme::PM::Dresden::VQWikiClient (verbose => 1);
$vqwiki->auth_user           ("VQWikiClientBot");
$vqwiki->auth_passwd         ("secretpasswd");
$vqwiki->bin_url             ('http://wiki.yourhost.de/vqwiki/jsp/Wiki');

# TWiki
my $twiki  = new WWW::TWikiClient (verbose => 1);
$twiki->auth_user           ("TWikiClientBot");
$twiki->auth_passwd         ("secretpasswd");
$twiki->override_locks      (1);
$twiki->bin_url             ('http://twiki.yourhost.de/twiki/bin/');
$twiki->current_default_web ('Ourweb'); # the target web in twiki
# -- END CUSTOMIZATION AREA ----------------------------------------


# correct artifacts
#
# In case you know of syntax artifacts that the converter doesn't handle
# (or at least not correctly), you should preprocess them here.
#
# E.g., in our vqwiki, someone started a numbered item list immediately
# after a linebreak symbol '@@' with "<tab>#list item", instead of
# starting a new line for that first list item.
sub preprocess {
  my $c = shift;
  $c =~ s/(?<!@)\@\@\t(.*)/@@\n\t$1/g;
  return $c;
}

# For collecting interwiki links
my %interwiki_defs = ();

# The vqwiki-twiki-converter
my $converter = new Acme::PM::Dresden::Convert::VQWiki2TWiki();

# loop for topics
foreach my $topic (sort keys %topiclisthash) {
  # capitalize TWiki topics
  my $twiki_topic = $topic;
  $twiki_topic =~ s/\b(\w)/\U$1/g; # capitalize

  # progress prints
  print STDERR "$topic : read topic";
  print STDERR " ($topic --> $twiki_topic)" if ($topic ne $twiki_topic);
  print STDERR "\n";

  # read vqwiki
  my $c = $vqwiki->read_topic ($topic);

  # ignore some content
  if (! $c or $c eq "delete" or $c eq "This is a new topic") {
    print STDERR "         *** ignore topic (content = ", $c||'<empty>', ")\n";
    next;
  }

  # If you are too fast, VQWiki seems to run out of database handles.
  #
  # On my machine, converting and writing to TWiki took long enough to
  # keep VQWiki alive.
  #
  # Insert a sleep if your machine and network are too fast.
  #
  #sleep 3;

  # convert content
  print STDERR "         convert topic\n";
  $c = preprocess ($c);
  my $twiki_c = $converter->vqwiki2twiki ($c);

  # collect interwiki links, you should define later in your TWiki
  foreach (qw(c2 mb mskb cvsweb wikipedia redirect)) {
    if ($twiki_c =~ m/$_:/) {
      print STDERR "         Interwiki link: $_ in $twiki_topic\n";
      $interwiki_defs{$_} .= "$twiki_topic, ";
    }
  }

  # In reality I also did some more complicated conversions
  $twiki_c =~ s/c2:/C2:/g;               #
  $twiki_c =~ s/cvsweb:/Svn:/g;          #
  $twiki_c =~ s/redirect:/Redirect:/g;   #
  $twiki_c =~ s/mb:/Mb:/g;               #
  $twiki_c =~ s/mskb:/Mskb:/g;           #
  $twiki_c =~ s/wikipedia:/Wikipedia:/g; #

  # save content
  print STDERR "         save topic\n";
  $twiki->save_topic ($twiki_c, $twiki_topic);

}

# Which interwiki links occured
print "Interwiki links: ", Dumper (\%interwiki_defs);

__END__

=head1 NAME

migrate_vqwiki2twiki.pl - convert VQWiki to TWiki.

=head1 SYNOPSIS

 perl migrate_vqwiki2twiki.pl

=head1 DESCRIPTION

Please note: This example script originally lived in the
Acme::PM::Dresden distribution. I just renamed
Acme::PM::Dresden::TWikiClient into WWW::TWikiClient.

Example script that demonstrates the usage of these classes:

   WWW::TWikiClient
   Acme::PM::Dresden::VQWikiClient
   Acme::PM::Dresden::Convert::VQWiki2TWiki

With this script I migrated a whole VQWiki into an existing TWiki.

It crawls a given list of topics in VQWiki, reads the raw syntax,
converts them into raw TWiki syntax, eventually capitalizes the
TWiki topic names and saves the converted content into TWiki.

You can run this script again and again, by watching the result in
TWiki, finetuning this script and rerun until everything is ok. It's
just like you would repeatedly edit in TWiki.

Go to ::CUSTOMIZATION AREA:: and set your specific URLs and auth.

=head1 AUTHOR

Steffen Schwigon <schwigon@cpan.org>

=head1 LICENSE

 Copyright (c) 2005,2006. Steffen Schwigon
 All rights reserved. You can redistribute and/or modify
 this bundle under the same terms as Perl itself.
