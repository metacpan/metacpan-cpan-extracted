#!/usr/local/bin/perl -w

# test.pl
# Copyright (C) 1997 by USC/ISI
# $Id: test_parsing.pl,v 1.1 2007-05-15 12:06:30 Daddy Exp $
#
# Copyright (c) 1997 University of Southern California.
# All rights reserved.                                            
#                                                                
# Redistribution and use in source and binary forms are permitted
# provided that the above copyright notice and this paragraph are
# duplicated in all such forms and that any documentation, advertising
# materials, and other materials related to such distribution and use
# acknowledge that the software was developed by the University of
# Southern California, Information Sciences Institute.  The name of the
# University may not be used to endorse or promote products derived from
# this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

sub usage 
  {
  print STDERR <<END;
usage: $0 [-dIXuv] [-e SearchEngine]

Runs WWW::Search tests.  The default action (no arguments) is to run
internal tests on all engines, then run external tests on all engines.

Options:
    -e Yahoo,HotBot  limit actions to certain Search Engine(s)
    -i               run interal tests only
    -u               update saved test files
    -v               verbose (show commands)
    -x               run external tests only
END
  my $unused = <<'UNUSED';
To save a result to a file, use the search_to_file option of WebSearch.
Something like:

bin/WebSearch -e AltaVista::Web -o search_to_file=Test-Pages/AltaVista/Web/zero_result -- '+LSAM +No_SuchWord'
UNUSED
  exit 1;
  } # usage

use strict;

# use Config;
use Getopt::Long;
use WWW::Search;
use WWW::Search::Test;

use vars qw( $verbose $debug $desired_search_engines $update_saved_files );
use vars qw( $do_internal $do_external );
$do_internal = $do_external = 0;
undef $debug;
$desired_search_engines = '';
&usage unless &GetOptions(
                          'd:i' => \$debug,
                          'e=s' => \$desired_search_engines,
                          'u' => \$update_saved_files,
                          'v' => \$verbose,
                          'i' => \$do_internal,
                          'x' => \$do_external,
                         );
($do_internal, $do_external) = (1,1) unless ($do_internal || $do_external);
$debug = 1 if (defined($debug) and ($debug < 1));

my $oTest = new WWW::Search::Test($desired_search_engines);
$oTest->{debug} = $debug;
$oTest->{verbose} = $verbose;

&main();

exit 0;

sub test_cases 
  {
  my ($o, $query, $sSE, $sM, $file);
  my $bogus_query = $WWW::Search::Test::bogus_query;

  $sSE = 'AltaVista';
  $sM = 'John Heidemann <johnh@isi.edu>';
  
  $file = 'zero_result_no_plus';
  $oTest->test($sSE, $sM, $file, $bogus_query, $TEST_EXACTLY);
  
  $file = 'zero_result';
  $query = '+LSAM +' . $bogus_query;
  $oTest->test($sSE, $sM, $file, $query, $TEST_EXACTLY);
  
  $file = 'one_page_result';
  $query = '+LS'.'AM +Aut'.'oSearch';
  $oTest->test($sSE, $sM, $file, $query, $TEST_RANGE, 2, 10);
  
  $file = 'two_page_result';
  $query = '+LS'.'AM +IS'.'I +Heide'.'mann';
  $oTest->test($sSE, $sM, $file, $query, $TEST_GREATER_THAN, 10);
  
  ######################################################################

  $sSE = 'AltaVista::Web';
  $sM = 'John Heidemann <johnh@isi.edu>';
  
  $file = 'zero_result';
  $query = '+LSA'.'M +' . $bogus_query;
  $oTest->test($sSE, $sM, $file, $query, $TEST_EXACTLY);
  
  $file = 'one_page_result';
  $query = '+LSA'.'M +AutoSea'.'rch';
  $oTest->test($sSE, $sM, $file, $query, $TEST_RANGE, 2, 10);
  
  $file = 'two_page_result';
  $query = '+LSA'.'M +IS'.'I +I'.'B';
  $oTest->test($sSE, $sM, $file, $query, $TEST_GREATER_THAN, 10);
  
  ######################################################################

  $sSE = 'AltaVista::AdvancedWeb';
  $sM = 'John Heidemann <johnh@isi.edu>';
  $oTest->not_working($sSE, $sM);
  # $query = 'LS'.'AM and ' . $bogus_query;
  # $oTest->test($sSE, $sM, 'zero', $query, $TEST_EXACTLY);
  # $query = 'LSA'.'M and AutoSea'.'rch';
  # $oTest->test($sSE, $sM, 'one', $query, $TEST_RANGE, 2, 11);
  # $query = 'LSA'.'M and IS'.'I and I'.'B';
  # $oTest->test($sSE, $sM, 'two', $query, $TEST_GREATER_THAN, 10);
  
  ######################################################################

  $sSE = 'AltaVista::News';
  $sM = 'John Heidemann <johnh@isi.edu>';
  $oTest->not_working($sSE, $sM);
  # $query = '+pe'.'rl +' . $bogus_query;
  # $oTest->test($sSE, $sM, 'zero', $query, $TEST_EXACTLY);
  # $query = '+Pe'.'rl +CP'.'AN';
  # $oTest->test($sSE, $sM, 'multi', $query, $TEST_GREATER_THAN, 30); # 30 hits/page
  
  ######################################################################

  $sSE = 'AltaVista::AdvancedNews';
  $sM = 'John Heidemann <johnh@isi.edu>';
  $oTest->not_working($sSE, $sM);
  # $query = 'per'.'l and ' . $bogus_query;
  # $oTest->test($sSE, $sM, 'zero', $query, $TEST_EXACTLY);
  # $query = 'Per'.'l and CP'.'AN';
  # $oTest->test($sSE, $sM, 'multi', $query, $TEST_GREATER_THAN, 70); # 30 hits/page
  
  ######################################################################

  $oTest->eval_test('AltaVista::Intranet');

  ######################################################################

  $oTest->no_test('Crawler', 'unsupported');
  # $oTest->test($sSE, $sM, 'zero', $bogus_query, $TEST_EXACTLY);
  # $query = 'Bay'.'reuth Bindl'.'acher Be'.'rg Flu'.'gplatz P'.'ilot';
  # $oTest->test($sSE, $sM, 'one', $query, $TEST_RANGE, 2, 10);
  # # 10 hits/page
  # $query = 'Fra'.'nkfurter Al'.'lgemeine Sonnt'.'agszeitung Rech'.'erche';
  # $oTest->test($sSE, $sM, 'two', $query, $TEST_GREATER_THAN, 10);
  
  ######################################################################

  $oTest->eval_test('Excite::News');

  ######################################################################

  $sSE = 'ExciteForWebServers';
  $sM = 'Paul Lindner <paul.lindner@itu.int>';
  $oTest->not_working($sSE, $sM);
  # &test($sSE, $sM, 'zero', $bogus_query, $TEST_EXACTLY);
  # $query = 'bur'.'undi';
  # &test($sSE, $sM, 'one', $query, $TEST_RANGE, 2, 99);
  
  ######################################################################

  $oTest->eval_test('Fireball');
  
  ######################################################################

  $sSE = 'FolioViews';
  $sM = 'Paul Lindner <paul.lindner@itu.int>';
  $oTest->test($sSE, $sM, 'zero', $bogus_query, $TEST_EXACTLY);
  $query = 'bur'.'undi';
  $oTest->test($sSE, $sM, 'one', $query, $TEST_RANGE, 2, 400);
  
  ######################################################################

  $oTest->eval_test('Google');
  
  $oTest->no_test('Gopher', 'Paul Lindner <paul.lindner@itu.int>');

  $oTest->eval_test('GoTo');
  
  $oTest->eval_test('HotFiles');
  
  $oTest->eval_test('Infoseek::Companies');
  $oTest->eval_test('Infoseek::Email');
  $oTest->eval_test('Infoseek::News');
  $oTest->eval_test('Infoseek::Web');

  $oTest->no_test('Livelink', 'Paul Lindner <paul.lindner@itu.int>');

  $oTest->eval_test('LookSmart');
  # use WWW::Search::LookSmart;
  # $oTest->no_test('LookSmart', $WWW::Search::LookSmart::MAINTAINER);

  $oTest->eval_test('Lycos');
  
  $oTest->eval_test('Magellan');
  
  $oTest->eval_test('MetaCrawler', 'Jim Smyser <jsmyser@bigfoot.com>');
  
  ######################################################################

  $sSE = 'Metapedia';
  $sM = 'Jim Smyser <jsmyser@bigfoot.com>';
  
  $file = 'zero';
  $oTest->test($sSE, $sM, $file, $bogus_query, $TEST_EXACTLY);
  
  ######################################################################

  $sSE = 'MSIndexServer';
  $sM = 'Paul Lindner <paul.lindner@itu.int>';
  $oTest->not_working($sSE, $sM);
  # $oTest->test($sSE, $sM, 'zero', $bogus_query, $TEST_EXACTLY);
  # $query = 'bur'.'undi';
  # $oTest->test($sSE, $sM, 'one', $query, $TEST_RANGE, 2, 99);
  
  ######################################################################

  $oTest->eval_test('NetFind');

  $oTest->eval_test('NorthernLight');
  
  ######################################################################

  $sSE = 'Null';
  $sM = 'Paul Lindner <paul.lindner@itu.int>';
  $oTest->test($sSE, $sM, 'zero', $bogus_query, $TEST_EXACTLY);
  
  ######################################################################

  $oTest->eval_test('OpenDirectory');
  
  ######################################################################

  $sSE = 'PLweb';
  $sM = 'Paul Lindner <paul.lindner@itu.int>';
  $oTest->not_working($sSE, $sM);
  # $oTest->test($sSE, $sM, 'zero', $bogus_query, $TEST_EXACTLY);
  # $query = 'bur'.'undi';
  # $oTest->test($sSE, $sM, 'one', $query, $TEST_RANGE, 2, 99);
  
  ######################################################################

  $sSE = 'Search97';
  $sM = 'Paul Lindner <paul.lindner@itu.int>';
  $oTest->not_working($sSE, $sM);
  # $file = 'zero';
  # $oTest->test($sSE, $sM, $file, $bogus_query, $TEST_EXACTLY);
  # $file = 'one';
  # $query = 'bur'.'undi';
  # $oTest->test($sSE, $sM, $file, $query, $TEST_RANGE, 2, 99);
  
  ######################################################################

  $sSE = 'SFgate';
  $sM = 'Paul Lindner <paul.lindner@itu.int>';
  $oTest->test($sSE, $sM, 'zero', $bogus_query, $TEST_EXACTLY);
  $query = 'bur'.'undi';
  $oTest->test($sSE, $sM, 'one', $query, $TEST_RANGE, 2, 99);
  
  ######################################################################

  $oTest->no_test('Simple', 'Paul Lindner <paul.lindner@itu.int>');

  $oTest->eval_test('Snap');
  
  $oTest->no_test('Verity', 'Paul Lindner <paul.lindner@itu.int>');

  $oTest->eval_test('WebCrawler');
  
  $oTest->eval_test('ZDNet');

  } # test_cases
  

sub main 
  {
  # print "\nVERSION INFO:\n  ";
  # my ($cmd) = &web_search_bin . " --VERSION";
  # print `$cmd`;
  
  if ($update_saved_files) 
    {
    print "\nUPDATING.\n\n";
    $oTest->mode($MODE_UPDATE);
    &test_cases();
    # Can not do update AND test:
    return;
    } # if
  
  if ($do_internal) 
    {
    print "\nTESTING INTERNAL PARSING.\n  (Errors here should be reported to the WWW::Search maintainer.)\n\n";
    $oTest->reset_error_count;
    $oTest->mode($MODE_INTERNAL);
    &test_cases();
    print "\n";
    if ($oTest->{error_count} <= 0) 
      {
      print "All ", $oTest->mode, " tests have passed.\n\n";
      }
    else 
      {
      print "Some ", $oTest->mode, " tests failed.  Please check the README file before reporting errors (sometimes back-ends have known failures).\n";
      }
    } # if $do_internal
    
  if ($do_external) 
    {
    print "\n\nTESTING EXTERNAL QUERIES.\n  (Errors here suggest search-engine reformatting and should be\n  reported to the maintainer of the back-end for the search engine.)\n\n";
    $oTest->reset_error_count;
    $oTest->mode($MODE_EXTERNAL);
    &test_cases();
    print "\n";
    if ($oTest->{error_count} <= 0)
      {
      print "All ", $oTest->mode, " tests have passed.\n\n";
      }
    else
      {
      print "Some ", $oTest->mode, " tests failed.  Please check the README file before reporting errors (sometimes back-ends have known failures).\n";
      }
    } # if $do_external
  } # main

=head2 TO DO

=over

=item  No identified needs at the moment...

=back

=head2 HOW IT WORKS

At present there is only one function available, namely &test().  It
takes at least 5 arguments.  These are: 1) the name of the search
engine (string); 2) the maintainer's name (and email address)
(string); 3) a filename (unique among tests for this backend)
(string); 4) the raw query string; 5) the test method (one of the
constants $TEST_EXACTLY, $TEST_RANGE, $TEST_GREATER_THAN,
$TEST_BY_COUNTING); optional arguments 6 and 7 are integers to be used
when counting the results.

The query is sent to the engine, and the results are compared to
previously stored results as follows: If the method is $TEST_EXACTLY,
the two lists of URLs must match exactly.  If the method is
$TEST_RANGE, the number of URLs must be between arg6 and arg7.  If the
method is $TEST_GREATER_THAN, the number of URLs must be greater than
arg6.  If the method is $TEST_BY_COUNTING, the number of URLs must be
exactly arg6 (but we don't care what the URLs are).

=cut

