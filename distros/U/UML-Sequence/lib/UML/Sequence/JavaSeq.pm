package UML::Sequence::JavaSeq;
use UML::Sequence::SimpleSeq;

@ISA = ('UML::Sequence::SimpleSeq');
$VERSION = '0.02';

use strict;
use warnings;

=head1 NAME

UML::Sequence::JavaSeq - for use with genericseq.pl script, works on compiled Java programs

=head1 SYNOPSIS

    genericseq.pl UML::Sequence::JavaSeq Hello.methods Hello > Hello.xml
    seq2svg.pl Hello.xml > Hello.svg

OR

    genericseq.pl UML::Sequence::JavaSeq Hello.methods Hello | seq2svg.pl > Hello.svg

=head1 DESCRIPTION

This file depends on L<UML::Sequence::SimpleSeq> and a Java tool called
Seq.java.  The later produces an outline of the calls to methods named
in Hello.methods.  The former provides methods L<UML::Sequence> needs to produce
an xml sequence.  Look in the provided Hello.methods to see what options
you have for controlling output.

For this class to work, you must have Seq.class (and its friends) and
tools.jar (the one containing the the jpda) in your class path.  Your
jpda must be happy.  (The jpda is the Java Platform Debugger Architecture.
It ships with java 1.3.)

=head1 grab_outline_text

Call this method through the class name with the method file, the class
you want to sequence, and any arguments that class's main method needs.
Returns an outline you can pass to UML::Sequence::SimpleSeq->grab_methods
and to the UML::Sequence constructor.

=cut

sub grab_outline_text {
    shift;  # discard class name
    my @retval;
    my $method_file     = shift;

    `java Seq $method_file SEQ.TMP @_ > /dev/null`;

    open SEQ, "SEQ.TMP" or die "Couldn't run java Seq: $!\n";
    while (<SEQ>) {
        push @retval, $_;
    }
    close SEQ;

    unlink "SEQ.TMP";
    return \@retval;
}

1;
