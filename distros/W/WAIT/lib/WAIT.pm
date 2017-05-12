#!/usr/bin/perl
#                              -*- Mode: Cperl -*-
# $Basename: WAIT.pm $
# $Revision: 1.7 $
# Author          : Ulrich Pfeifer
# Created On      : Wed Nov  5 16:59:32 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Mon May 31 22:34:35 1999
# Language        : CPerl
# Update Count    : 5
# Status          : Unknown, Use with caution!
#
# (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
#
#

package WAIT;
require DynaLoader;
use vars qw($VERSION @ISA);
@ISA = qw(DynaLoader);

# $Format: "$\VERSION = sprintf '%5.3f', ($ProjectMajorVersion$ * 100 + ($ProjectMinorVersion$-1))/1000;"$
$VERSION = sprintf '%5.3f', (18 * 100 + (1-1))/1000;


bootstrap WAIT $VERSION;

__END__

=head1 NAME

WAIT - a rewrite of the freeWAIS-sf engine in Perl and XS

=head1 SYNOPSIS

A Synopsis is not yet available.

=head1 Status of this document

I started writing down some information about the implementation
before I forget them in my spare time. The stuff is incomplete at
least. Any additions, corrections, ... welcome.

=head1 PURPOSE

As you might know, I developed and maintained B<freeWAIS-sf> (with the
help of many people in The Net). FreeWAIS-sf is based on B<freeWAIS>
maintained by the Clearing House for Network Information Retrieval
(CNIDR) which in turn is based on B<wais-8-b5> implemented by Thinking
Machine et al. During this long history - implementation started about
1989 - many people contributed to the distribution and added features
not foreseen by the original design. While the system fulfills its
task now, the code has reached a state where adding new features is
nearly impossible and even fixing longstanding bugs and removing
limitations has become a very time consuming task.

Therefore I decided to pass the maintenance  to WSC Inc. and built a
new system from scratch. For obvious reasons I choosed Perl as
implementation language.

=head1 DESCRIPTION

The central idea of the system is to provide a framework and the
building blocks for any indexing and search system the users might
want to build. Obviously the framework limits the class of system
which can be build.

       +------+     +-----+     +------+
   ==> |Access| ==> |Parse| ==> |      |
       +------+     +-----+     |      |
                       ||       |      |     +-----+
                       ||       |Filter| ==> |Index|
                       \/       |      |     +-----+
      +-------+     +-----+     |      |
   <= |Display| <== |Query| <-> |      |
      +-------+     +-----+     +------+

A collection (aka table) is defined by the instances of the B<access>
and B<parse> module together with the B<filter definitions>. At query
time in addition a B<query> and a B<display> module must be choosen.

=head2 Access

The access module defines which documents are members of a database.
Usually an access module is a tied hash, whose keys are the Ids of the
documents (did = document id) and whose values are the documents
themselves. The indexing process loops over the keys using C<FIRSTKEY>
and C<NEXTKEY>. Documents are retrieved with C<FETCH>.

By convention access modules should be members of the
C<WAIT::Document> hierarchy. Have a look at the
C<WAIT::Document::Split> module to get the idea.


=head2 Parse

The task of the parse module is to split the documents into logical
parts via the C<split> method. E.g. the C<WAIT::Parse::Nroff> splits
manuals piped through B<nroff>(1) into the sections I<name>,
I<synopsis>, I<options>, I<description>, I<author>, I<example>,
I<bugs>, I<text>, I<see>, and I<environment>. Here is the
implementation of C<WAIT::Parse::Base> which handles documents with a
pretty simple tagged format:

  AU: Pfeifer, U.; Fuhr, N.; Huynh, T.
  TI: Searching Structured Documents with the Enhanced Retrieval
      Functionality of freeWAIS-sf and SFgate
  ER: D. Kroemker
  BT: Computer Networks and ISDN Systems; Proceedings of the third
      International World-Wide Web Conference
  PN: Elsevier
  PA: Amsterdam - Lausanne - New York - Oxford - Shannon - Tokyo
  PP: 1027-1036
  PY: 1995

  sub split {                     # called as method
    my %result;
    my $fld;

    for (split /\n/, $_[1]) {
      if (s/^(\S+):\s*//) {
        $fld = lc $1;
      }
      $result{$fld} .= $_ if defined $fld;
    }
    return \%result;
  }

Since the original document cannot be reconstructed from its
attributes, we need a second method (I<tag>) which marks the regions
of the document with tags for the different attributes. This tagged
form is used by the display module to hilight search terms in the
documents. Besides the tags for the attributes, the method might assign
the special tags C<_b> and C<_i> for indicating bold and italic
regions.

  sub tag {
    my @result;
    my $tag;

    for (split /\n/, $_[1]) {
      next if /^\w\w:\s*$/;
      if (s/^(\S+)://) {
        push @result, {_b => 1}, "$1:";
        $tag = lc $1;
      }
      if (defined $tag) {
        push @result, {$tag => 1}, "$_\n";
      } else {
        push @result, {}, "$_\n";
      }
    }
    return @result;               # we don't go for speed
  }

Obviously one could implement C<split> via C<tag>. The reason for
having two functions is speed. We need to call C<split> for each
document when indexing a collection. Therefore speed is essential. On
the other hand, C<tag> is called in order to display a single document
and may be a little slower. It may care about tagging bold and italic
regions. See C<WAIT::Parse::Nroff> how this might decrease
performance.


=head2 Filter definition

From the Information Retrieval perspective, the hardest part of the
system is the filter module. The database administrator defines for
each attribute, how the contents should be processed before it is
stored in the index. Usually the processing contains steps to restrict
the character set, case transformation, splitting to words and
transforming to word stems. In WAIT these steps are defined naturally
as a pipeline of processing steps. The pipelines are made up by
functions in the package B<WAIT::Filter> which is pre-populated by the
most common functions but may be extended any time.

The equivalent for a typical freeWAIS-sf processing would be this
pipeline:

        [ 'isotr', 'isolc', 'split2', 'stop', 'Stem']

The function C<isotr> replaces unknown characters by blanks. C<isolc>
transforms to lower case. C<split2> splits into words and removes
words shorter than two characters. C<stop> removes the freeWAIS-sf
stopwords and C<Stem> applies the Porter algorithm for computing the
stem of the words.

The filter definition for a collection defines a set of pipelines for
the attributes and modifies the pipelines which should be used for
prefix and interval searches.

Several complete working examples come with WAIT in the script
directory. It is recommended to follow the pattern of the scripts
smakewhatis and sman.

=cut

