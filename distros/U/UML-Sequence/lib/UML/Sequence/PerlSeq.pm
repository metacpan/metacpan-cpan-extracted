package UML::Sequence::PerlSeq;
use     strict;
use     warnings;

=head1 NAME

UML::Sequence::PerlSeq - for use with genericseq.pl script, works on Perl programs

=head1 SYNOPSIS

    genericseq.pl UML::Sequence::PerlSeq methods_file perl_program [args...] > sequence.xml
    seq2svg.pl sequence.xml > sequence.svg

OR

    genericseq.pl UML::Sequence::PerlSeq methods_file program [args...] | seq2svg.pl > sequence.svg

=head1 DESCRIPTION

This file must be used by a script.  On demand it will form an outline by
running the supplied program with -d:UML::CallSeq which is included in
the UML::Sequence distribution.  This has been developed on
Cygwin under Windows 2000 and tested on Red Hat Linux 7.1.

The methods file should list methods you WANT to hear about.  If it isn't
in the list, it will not appear in the picture.  The format of the file
is like this:

    DiePair::new
    Die::new
    DiePair::roll
    Die::roll
    DiePair::total
    DiePair::doubles
    DiePair::to_string

Order is not important.

=cut

use strict;
use warnings;

our $VERSION = "0.02";

my $methods_file;

=head1 grab_outline_text

Call this method first.  Call it through the class
(UML::Sequence::PerlSeq->grab_outline_text)
passing it the methods_file, the program to run, and any args for that program.
Returns an outline (suitable for printing or passing on to SeqOutline).

=cut
sub grab_outline_text {
    shift;  # discard class name
    $methods_file = shift;
    _profile(@_);
    return _read_tmon();
}

sub _profile {
    `perl -d:CallSeq @_`;
}

sub _read_tmon {
    my @retval;
    open TMON, "tmon.out" or die "Couldn't read tmon.out from Devel::CallSeq\n";
    while (<TMON>) {
        chomp;
        push @retval, $_;
    }
    unlink "tmon.out";
    return \@retval;
}

=head1 grab_methods

Call this only after you have called grab_outline.  Call it through the class:
UML::Sequence::PerlSeq->grab_methods.  Arguments are ignored.
Returns a reference to an array listing the methods of interest.

=cut

sub grab_methods {
    shift;  # discard class

    open METHODS, "$methods_file" or die "Couldn't open $methods_file\n";
    chomp(my @methods = <METHODS>);
    close METHODS;

    return \@methods;
}

=head1 parse_signature

Pass a reference to this method to the UML::Sequence constructor.  It must
accept a method signature and return the class name (in scalar context) or
the class and method names in that order (in list context).

=cut

sub parse_signature {
    my $signature = shift;
    my $class     = $signature;
    $class        =~ s/::([^:]+)$//;
    my $method    = $1;

    return wantarray ? ($class, $method) : $class;
}

1;
