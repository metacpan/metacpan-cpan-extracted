#########
# Author:        Andy Brown (setitesuk@gmail.com)
package Test::WWW::Selenium::Conversion::IDE;

use strict;
use warnings;
use Carp;
use English q{-no_match_vars};
use Test::More; # this is designed to be a helper for tests, OK
use Test::WWW::Selenium; # we are going to run the tests in this
use XML::LibXML;
use base q{Exporter};
use Readonly; Readonly::Scalar our $VERSION => 0.5;

our @EXPORT = qw{ ide_to_TWS_run_from_suite_file ide_to_TWS_run_from_test_file };

Readonly::Scalar our $DEFAULT_TIMEOUT => 50_000;
Readonly::Scalar our $DEFAULT_SELENIUM_LOCATION => q{t/selenium_tests};
Readonly::Scalar our $MAX_TIMES_TO_LOOP => 20;

sub ide_to_TWS_run_from_suite_file {
  my ( $sel, $suite_file, $sel_test_root ) = @_;
  $sel_test_root ||= $DEFAULT_SELENIUM_LOCATION;

  my $parser = XML::LibXML->new();
  my $suite = $parser->parse_html_file( qq{$sel_test_root/$suite_file} );
  my @tests = $suite->getElementsByTagName( q{a} );
  foreach my $test ( @tests ) {
    my $test_file = $test->getAttribute( q{href} );
    $test_file =~ s{[.]/}{}xms;
    ide_to_TWS_run_from_test_file( $sel, {
      test_file => $test_file,
      sel_test_root => $sel_test_root,
      parser => $parser,
    } );
  }
  return 1;
}

sub ide_to_TWS_run_from_test_file {
  my ( $sel, $args ) = @_;
  my $test_file = $args->{test_file};
  my $sel_test_root = $args->{sel_test_root} || $DEFAULT_SELENIUM_LOCATION;
  my $parser = $args->{parser} || XML::LibXML->new();

  my $test_dom = $parser->parse_html_file( qq{$sel_test_root/$test_file} );
  my @title_tags = $test_dom->getElementsByTagName( q{title} );
  my $title = $title_tags[0]->firstChild->nodeValue();
  note qq{Running Selenium Test: '$title'};

  my ($tbody) = $test_dom->getElementsByTagName( q{tbody} );
  foreach my $action_set ( $tbody->getElementsByTagName( q{tr} ) ) {
    my ( $action, $operand_1, $operand_2 ) = $action_set->getElementsByTagName( q{td} );
    foreach my $node ( $action, $operand_1, $operand_2 ) {
      if ( defined $node && defined $node->firstChild ) {
        $node = $node->firstChild->nodeValue();
      } else {
        $node = q{};
      }
    }
    if ( $operand_1 =~ m{\A[(]?//}xms ) {
      $operand_1 = q{xpath=} . $operand_1;
    }
    my $test_args = {
      action => $action,
      operand_1 => $operand_1,
      operand_2 => $operand_2,
    };
    _ide_to_TWS_convert_to_method_and_test( $sel, $test_args);
  }
  return 1;
}

sub _ide_to_TWS_convert_to_method_and_test {
  my ( $sel, $args ) = @_;

  my %actions = (
    open => \&_ide_to_TWS_open_test,
    verifyTitle => \&_ide_to_TWS_verifyTitle_test,
    verifyText => \&_ide_to_TWS_verifyTextPresent_test,
    verifyTextPresent => \&_ide_to_TWS_verifyTextPresent_test,
    assertText => \&_ide_to_TWS_verifyTextPresent_test,
    assertTextPresent => \&_ide_to_TWS_verifyTextPresent_test,
    waitForElementPresent => \&_ide_to_TWS_waitForText,
    assertElementPresent => \&_ide_to_TWS_verifyTextPresent_test,
    clickAndWait => \&_ide_to_TWS_clickAndWait,
    click => \&_ide_to_TWS_clickAndWait,
    type => \&_ide_to_TWS_type,
    waitForText => \&_ide_to_TWS_waitForText,
    select => \&_ide_to_TWS_select,
    selectAndWait => \&_ide_to_TWS_select,
    random_alert => \&_ide_to_TWS_random_alert,
  );
  eval {
   $actions{$args->{action}}( $sel, $args );
   1;
  } or do {
    diag explain $args;
    diag qq{\t$EVAL_ERROR};
  };
  return;
}

sub _ide_to_TWS_random_alert {
  my ( $sel, $args ) = @_;
  my $alert_present = $sel->is_alert_present;
  my $msg = q{Random alert } . ( $alert_present ? q{} : q{not } ) . q{found} . ( $alert_present ? q{ } . $sel->get_alert : q{} );
  pass($msg);
  return;
}

sub _ide_to_TWS_select {
  my ( $sel, $args ) = @_;
  ok( $sel->select($args->{operand_1}, $args->{operand_2}), , qq{select $args->{operand_2} from $args->{operand_1}} );
  return;
}

sub _ide_to_TWS_verifyTitle_test {
  my ( $sel, $args ) = @_;
  is( $sel->get_title(), $args->{operand_1}, qq{Title is $args->{operand_1}} );
  return;
}

sub _ide_to_TWS_waitForText {
  my ( $sel, $args ) = @_;
  my $op1 = $args->{operand_1};
  my $op2 = $args->{operand_2};
  if ( $op1 && $op2 ) {
    note qq{waiting for text $op2 in $op1};
    my $found = 0;
    my $count = 1;
    while ( ! $found && $count < $MAX_TIMES_TO_LOOP ) {
      $count++;
      eval {
        my $text = $sel->get_text( $op1 );
        if ( $op2 =~ m/regexp/ixms ) {
          my ( $type, $expression ) = $op2 =~ m/(regexp[i]?):(.*)/ixms;
          if ( $type =~ /i/ixms ) {
            if ( $text =~ m/$expression/ixms ) {
              $found++;
            }
          } else {
            if ( $text =~ m/$expression/xms ) {
              $found++;
            }
          }
        } else {
          if ( $text eq $op2 ) {
            $found++;
          }
        }
      } or do {};
      if ( ! $found ) {
        sleep 1;
      }
    }
    $count = $count < $MAX_TIMES_TO_LOOP ? $count : $MAX_TIMES_TO_LOOP;
    ok( $found, qq{waiting for text $op2 in $op1 - tried $count times} );
  } else {
    note qq{waiting for text $op1};
    if ( $op1 =~ m/[id|identifier|css]=/xms ) {
      ok( $sel->wait_for_element_present( $op1, $DEFAULT_TIMEOUT ), qq{waiting for text $op1} );
    } else {
      ok( $sel->wait_for_text_present( $op1, $DEFAULT_TIMEOUT ), qq{waiting for text $op1} );
    }
  }
  return;
}

sub _ide_to_TWS_type {
  my ( $sel, $args ) = @_;
  note qq{typing $args->{operand_2} into $args->{operand_1}};
  $sel->type( $args->{operand_1}, $args->{operand_2} );
  return;
}

sub _ide_to_TWS_clickAndWait {
  my ( $sel, $args ) = @_;
  my $msg = qq{clicking $args->{operand_1}};
  note $msg;
  my $result;
  my $payload;
  eval { $sel->click($args->{operand_1}); $result = 1; } or do { $result = 0; $payload = $EVAL_ERROR; };
  ok( $result, $msg );
  if ( ! $result ) {
    diag $payload;
  }
  if ( $args->{action} ne q{click} ) {
    $msg = q{waiting for page to load};
    note $msg;
    if ( ! $result ) {
      ok( 0, $msg ); # auto fail if click failed
    } else {
      ok( $sel->wait_for_page_to_load( $DEFAULT_TIMEOUT ), $msg );
    }
  }
  return;
}

sub _ide_to_TWS_verifyTextPresent_test {
  my ( $sel, $args ) = @_;
  my $text1 = $args->{operand_1};
  my $text2 = $args->{operand_2};
  if ( $text2 ) {
    if ( $text1) {
      ok( $sel->is_element_present($text1), qq{element $text1 present on page} );
      if ( $text2 !~ m/\A[[:lower:]]+:/ixms || $text2 =~ m/\Aexact:/ixms ) {
        $text2 =~ s/exact://ixms;
        is( $sel->get_text($text1), $text2, qq{element $text1 has text of $text2} );
      }
    }
  } else {
    if ( $text1 =~ m/=/xms ) {
      ok( $sel->is_element_present($text1), qq{element $text1 present on page} );
    } else {
      like( $sel->get_body_text, qr{$text1}, qq{body text contains $text1} ); ## no critic (RegularExpressions::RequireDotMatchAnything RegularExpressions::RequireExtendedFormatting RegularExpressions::RequireLineBoundaryMatching)
    }
  }
  return;
}

sub _ide_to_TWS_open_test {
  my ( $sel, $args ) = @_;
  my $page = $args->{operand_1};
  $sel->open_ok( $page, undef, qq{open page $page} );
  return
}

1;
__END__

=head1 NAME

Test::WWW::Selenium::Conversion::IDE

=head1 VERSION

0.5

=head1 SYNOPSIS

****NOTE THIS IS IN ALPHA****

This module exports two functions to your test file, ide_to_TWS_run_from_suite_file and ide_to_TWS_run_from_test_file.

The objective is to run through Selenium IDE HTML files (Selenese) and run the tests as part of TAP in your perl test suite.

Rather than produce a perl test file which by itself can be run, this sits between a test file and the  Selenese tests, converting on the fly, so you can just add more tests in as you get more user stories, and they will automatically run for you.

This uses Test::WWW::Selenium and tries hard to use close to equivalents to the IDE commands. I do not expect it to be perfect, but should perform fairly close to.

****ALPHA - not all IDE commands have yet been converted, expect updates - ALPHA****

=head1 DESCRIPTION

How to use

Follow instructions found to download and start the Selenium Server, and you should take into account what the selenium docs say about running this. You may also need a webserver to serve you a dev version of your website (if that is what you are wanting to test).

In your test file:

  use Test::More;
  use Test::WWW::Selenium;
  use Test::WWW::Selenium::Conversion::IDE;
  
  my $sel = Test::WWW::Selenium->new( {creds} ); # See documentation for Test::WWW::Selenium
  
  ide_to_TWS_run_from_suite_file( $sel, $suite_file_name, $location_of_sel_test_root );
  ide_to_TWS_run_from_test_file( $sel, {
    test_file => $test_file_name,
    sel_test_root => $location_of_sel_test_root,
  } );
  
  done_testing();

$location_of_sel_test_root is optional, it defaults to t/selenium_tests

The selenium_server object is left to you to do in your test file, as your credentials, the browser you want to use... may be different. There is no helper method for this.

You can also pass in an optional XML::LibXML parser if you have one built, either as the last arg to 
ide_to_TWS_run_from_suite_file or 'parser => $oParser' added to the args href to ide_to_TWS_run_from_test_file.

It is worth noting, that whilst there is a difference between verify and assert in the IDE, the Conversion treats them as equivalent. This is currently deliberate, or a feature, and is unlikely to be changed in the future - who wants their test suite to croak rather than report failures? Not me!

=head1 SUBROUTINES/METHODS

=head2 ide_to_TWS_run_from_suite_file

If you have a suite file in your selenium tests directory (default t/selenium_tests) then using this function will run all test files listed in the suite

  ide_to_TWS_run_from_suite_file( $oTestWWWSelenium, $suite_file_name );
  ide_to_TWS_run_from_suite_file( $oTestWWWSelenium, $suite_file_name, $selenium_test_directory_path);

=head2 ide_to_TWS_run_from_test_file

If you just want to run one Selenese HTML IDE test file, then use this method (again, default location is t/selenium_tests)

  ide_to_TWS_run_from_test_file( $oTestWWWSelenium, $test_file_name );
  ide_to_TWS_run_from_test_file( $oTestWWWSelenium, $test_file_name, $selenium_test_directory_path );

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Carp

=item English -no_match_vars

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

As with any software, there is likely to be bugs (particularly whilst in alpha). Please feel free to report any you find.

The repository can be found

https://github.com/setitesuk/Test--WWW--Selenium--ide_to_TWS

=head1 AUTHOR

Author: Andy Brown (setitesuk@gmail.com)

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
