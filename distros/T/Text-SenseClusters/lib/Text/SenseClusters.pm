package Text::SenseClusters;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '1.05';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::SenseClusters ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

# Preloaded methods go here.

1;
__END__

=head1 NAME

SenseClusters - Cluster similar contexts using co-occurrence matrices and Latent Semantic Analysis

=head1 SYNOPSIS

SenseClusters is a suite of Perl programs that supports unsupervised 
clustering of similar contexts. It relies on it's own native methodology, 
and also provides support for Latent Semantic Analysis.

SenseClusters is a complete system that takes users from preprocessing of  
raw text to providing clustered output. It supports the selection of  
features, the creation of various kinds of context representations,  
dimensionality reduction by singular value decomposition, clustering, 
and analysis of results. 

SenseClusters integrates specialized tools such as the Ngram Statistics 
Package (L<Text::NSP>), SVDPACK, the Perl Data Language (L<PDL>) and 
CLUTO to provide a variety of choices and high efficiency at each step 
in its processing.

=head1 OVERVIEW

SenseClusters supports several different methods of clustering contexts. 
These include the native SenseClusters methodology, which is based on the 
use of first and second order representations of contexts. It also 
includes support for clustering lexical features using the native  
SenseClusters methodology or Latent Semantic Analysis. 

SenseClusters is based strictly on lexical features and does not rely on  
any manually created training data or external knowledge sources, and as  
such is language independent. The only requirement is that the language 
should be able to be tokenized via Perl regular expressions, which can be 
specified by the user. In fact, tokenization is so flexible that features 
could consist of characters, pairs of characters, etc. 

SenseClusters can be applied to the problem of discriminating word  
meanings or ambiguous names, using the target or head word representation.  
This is sometimes also called "headed" data, where each context is 
centered around the given target whose meanings are to be discovered. In 
this case the contexts that contain the given target word are clustered, 
and each cluster is assumed to correspond to a different meaning of that 
word. 

SenseClusters can also be applied to the problem of grouping short units 
of text that have no target or head (which is sometimes referred to as a 
"headless" representation. In this case there is no head or center to the  
context, so the entire context is being clustered to determine the 
meaning or topic of the context as a whole. Email categorization or news  
article clustering are examples of problems that could be approached 
using headless data. 

SenseClusters will automatically determine the number of clusters in the 
data based on a number of different automatic stopping measures we have 
developed, three of which are based on clustering criterion function, 
and one which is an adaptation of the well-known Gap Statistic. 

SenseClusters can also be applied to the problem of clustering words or 
lexical features, in hopes of discovering synonyms, antonyms, or other 
classes of words. 

Broadly speaking, SenseClusters can be used for any task that requires the 
recognition of contextually similar units of text, or words that occur 
in similar contexts.

=head1 DOCUMENTATION

All programs have inline source code documentation written in pod style 
and this can be browsed from command line as a man page or using 
the 'perldoc' command. For example, 'man bitsimat.pl' or 'perldoc 
bitsimat.pl' will displayed the documentation for the bitsimat.pl program.
Each program also has a --help option to provide information about program 
options. 

You can see all of the modules and their associated documentation at 
L<README.Toolkit>.

=head1 GETTING STARTED

You might first like to run the demonstration scripts in samples/ 
directory to get an idea of SenseClusters' usage and functionality, or 
try the web interface that is provided at 
L<http://senseclusters.sourceforge.net>.

samples/ contains scripts that utilize the wrapper program discriminate.pl 
that calls various other programs from the package to run a complete  
experiment. It also contains examples where specialized experiments are  
constructed directly from the programs provided in the package.  In 
general it would be useful to consult the flowcharts in doc/Flowcharts 
to understand the overall structure of the package. 

The web interface provides an intuitive means of formulating and running  
discriminate.pl commands, so the use of the web interface and certainly  
be instructive in terms of how to formulate discriminate.pl commands.

The contexts that you wish to cluster must be in Senseval-2 format. This 
is a simple XML markup that indicates the beginning and end of each 
context, and allows you to specify a target word and a "correct" 
categorization of the context, if you know that information. There is a
pre-processing  program text2sval.pl in Toolkit/preprocess/plain/ that  
converts plain text data (with a single context on each line) into 
Senseval-2 format. There is also a large amount of sample data 
that is already in Senseval-2 format available at 
L<http://senseclusters.sourceforge.net>

You can also (optionally) provide a separate training file in plain text 
format to be used as the feature selection data. If you don't do this, 
then the features will be selected from the contexts to be clustered.

=head1 PACKAGE ORGANIZATION

After downloading and unpacking SenseClusters, you should find following 
files/directories within SenseClusters' directory.

=over 4

=item L<README>, L<INSTALL>, L<CHANGES>, L<TODO>, L<FAQ>

Read-only copies of documentation found in doc/*.pod

=item L<GPL.txt>

A copy of the GNU General Public License, the terms under which SenseClusters
is distributed.

=item L<FDL.txt>

A copy of the GNU Free Documentation License, the terms under which the
documentation of SenseClusters is distributed.

=item L<discriminate.pl>

A wrapper program that acts as a driver for many other programs in 
the package. It clusters the given text instances based on their  
contextual similarities.

=item Makefile.PL

Generates a Makefile on running 'perl Makefile.PL'.

=item doc/

Contains various *.pod files that are kept in a read only form in the 
top level directory. 

doc/Flowcharts/ contains flow diagrams that illustrate how to put 
together the programs provided in SenseClusters' Toolkit with other 
packages like NSP, SVDPACK and CLUTO to run experiments without 
wrappers.

=item * Testing/ 

A directory of test cases written as C-shell scripts that will test if the 
package is installed properly or not. 

=item lib/

A stub for the Text::Similarity perl module. At present SenseClusters is 
oriented about the command line, so this is mostly for the benefit of 
CPAN indexing. 

=item t/

A stub directory created by h2xs - future site of test cases rather than 
/Testing

=item samples/

A directory of scripts that demonstrate SenseClusters' usage and 
functionality. 

=item External/

Contains a modified version of SVDPACKC, and a script that can be run to 
automatically install it, and retrieve and install Cluto.

=item Toolkit/

A directory of Perl programs implemented and used by SenseClusters. Users
who are interested to use SenseClusters' tools individually and separately 
without using the wrapper programs are encouraged to browse through the 
Toolkit and Toolkit.pod.

=item Web/

Contains an easy to use and install web interface for SenseClusters. 

=back

=head1 SEE ALSO

Please join our mailing lists to participate in the package related 
discussions, to post your questions or bugs and also to suggest 
enhancements to the package functionality.

To subscribe to the user's mailing list, visit : 

 L<http://lists.sourceforge.net/lists/listinfo/senseclusters-users>

To subscribe to a low volume news mailing list, visit : 

 L<http://lists.sourceforge.net/lists/listinfo/senseclusters-news>

To subscribe to the developer's mailing list, visit : 

 L<http://lists.sourceforge.net/lists/listinfo/senseclusters-developers>

Visit the SenseClusters project home page : 

 L<http://senseclusters.sourceforge.net/>

=head1 ACKNOWLEDGMENTS

The SenseClusters project has been partially supported by a National 
Science Foundation Faculty Early CAREER Development award (Grant 
#0092784). This award funded the work of Amruta Purandare (2002-2004)
and Anagha Kulkarni (2004-2006).

=head1 AUTHORS
 
 Ted Pedersen
 University of Minnesota, Duluth
 tpederse at d.umn.edu

 Amruta Purandare
 University of Pittsburgh

 Anagha Kulkarni
 Carnegie-Mellon University

 Mahesh Joshi
 Carnegie-Mellon University

=head1 COPYRIGHT

Copyright (c) 2003-2008,  Ted Pedersen,  Amruta Purandare,  Anagha Kulkarni, and Mahesh Joshi 

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut
