#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Match text question against possible answer strings
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Text::Match;
use v5.26;
our $VERSION = 20201221;                                                        # Version
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Math::Permute::List;
use feature qw(say current_sub);

sub normalizeText($)                                                            # Normalize a string of text
 {my ($s) = @_;                                                                 # String to normalize
  split /\s+/, lc $s =~ s(\W) ( )gsr
 }

sub span($$)                                                                    # Return the length of the span if the first array is spanned by the second array otherwise undef
 {my ($Q, $A) = @_;                                                             # Question, Answer
  my @m; my $n = 0;
  while(@$A and @$Q)                                                            # Each answer word
   {if ($$A[0] eq $$Q[0])
     {shift @$Q;
      shift @$A;
     }
    else
     {++$n;
      shift @$A;
     }
   }
  @$Q ? undef : $n
 }

sub randomizeArray(@)                                                           # Randomize an array
 {my (@a) = @_;                                                                 # Array
  for my $i(keys @a)
   {my $j = int ($#a * rand);
    my $s = $a[$i];  my $t = $a[$j]; $a[$i] = $t; $a[$j] = $s;
   }
  @a
 }

sub score                                                                       # Respond to a question with a similar answer
 {my ($Q, $A) = @_;                                                             # Question, Answer
  my @q = normalizeText $Q;
  my @a = normalizeText $A;
  my @m;
  while(@a)                                                                     # Each answer word
   {my $s = span([@q], [@a]) // span([reverse @q], [@a]);                       # Normal sequence or reversed
    if (defined $s)
     {push @m, [$s, $A];
     }
    else                                                                        # All permutations if necessary
     {permute
       {my $s = span([@_], [@a]);
        push @m, [$s, $A] if defined $s;
       } @q;
     }
    shift @a;
   }
  @m
 }

#D1 Match Text                                                                  # Match some text against possible answers
sub response($$)                                                                # Respond to a question with a plausible answer
 {my ($Q, $A) = @_;                                                             # Question, possible answers
  my @m;
  for my $A(@$A)                                                                # Each possible answer
   {push @m, score($Q, $A);
   }
  return '' unless @m;
  my ($m) =
    sort {       $$a[0]  <=>        $$b[0]}                                     # Smallest score  first
    sort {length($$a[1]) <=> length($$b[1])} @m;                                # Shortest string first
  $$m[1]
 }
#d
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(
response
 );
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Text::Match - Match text question against possible answer strings

=head1 Synopsis

=head1 Description

Match text question against possible answer strings


Version 20201221.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Match Text

Match some text against possible answers

=head2 response($Q, $A)

Respond to a question with a plausible answer

     Parameter  Description
  1  $Q         Question
  2  $A         Possible answers

B<Example:>



    is_deeply response("a c", ["a b c",   "a b c d"]),   "a b c";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply response("a c", ["a b c",   "a b c d"]),   "a b c";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply response("a d", ["a b c",   "a b c d"]),   "a b c d";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    is_deeply response("b d", ["a b c d", "a b c d e"]), "a b c d";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply response("b d", ["a b c d", "a b c d e"]), "a b c d";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply response("b e", ["a b c d", "a b c d e"]), "a b c d e";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    is_deeply response("c a", ["a b c",   "a b c d"]),   "a b c";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply response("c a", ["a b c",   "a b c d"]),   "a b c";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply response("d a", ["a b c",   "a b c d"]),   "a b c d";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    is_deeply response("d b", ["a b c d", "a b c d e"]), "a b c d";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply response("d b", ["a b c d", "a b c d e"]), "a b c d";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply response("e b", ["a b c d", "a b c d e"]), "a b c d e";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    is_deeply response("c a b",   ["a b c",   "a b c d"]),            "a b c";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply response("c a d",   ["a b c",   "a b c d"]),            "a b c d";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply response("c a b d", ["a b c",   "a b c d", "C a b d"]), "a b c d";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲




=head1 Index


1 L<response|/response> - Respond to a question with a plausible answer

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install TextMatch

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More;

my $localTest = ((caller(1))[0]//'TextMatch') eq "TextMatch";                   # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i) {plan tests => 18}                                    # Supported systems
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

is_deeply [score("a c", "a b c"  )], [[1, "a b c", ]];
is_deeply [score("a c", "a b c d")], [[1, "a b c d"]];
is_deeply [score("a d", "a b c d")], [[2, "a b c d"]];

if (1) {                                                                        #Tresponse
  is_deeply response("a c", ["a b c",   "a b c d"]),   "a b c";
  is_deeply response("a c", ["a b c",   "a b c d"]),   "a b c";
  is_deeply response("a d", ["a b c",   "a b c d"]),   "a b c d";

  is_deeply response("b d", ["a b c d", "a b c d e"]), "a b c d";
  is_deeply response("b d", ["a b c d", "a b c d e"]), "a b c d";
  is_deeply response("b e", ["a b c d", "a b c d e"]), "a b c d e";

  is_deeply response("c a", ["a b c",   "a b c d"]),   "a b c";
  is_deeply response("c a", ["a b c",   "a b c d"]),   "a b c";
  is_deeply response("d a", ["a b c",   "a b c d"]),   "a b c d";

  is_deeply response("d b", ["a b c d", "a b c d e"]), "a b c d";
  is_deeply response("d b", ["a b c d", "a b c d e"]), "a b c d";
  is_deeply response("e b", ["a b c d", "a b c d e"]), "a b c d e";

  is_deeply response("c a b",   ["a b c",   "a b c d"]),            "a b c";
  is_deeply response("c a d",   ["a b c",   "a b c d"]),            "a b c d";
  is_deeply response("c a b d", ["a b c",   "a b c d", "C a b d"]), "a b c d";
 }
