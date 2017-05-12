use strict;
use warnings;

# import XS interface into namespace Text::AI::CRM114::libcrm114
package Text::AI::CRM114::libcrm114;
BEGIN {
    # execute first, so all constants are defined
    require XSLoader;
    our $VERSION = '0.06';
    XSLoader::load('Text::AI::CRM114', $VERSION);
}

# main package
package Text::AI::CRM114;

=head1 NAME

Text::AI::CRM114 - Perl interface for CRM114

=head1 SYNOPSIS

  use Text::AI::CRM114;
  my $db = Text::AI::CRM114->new(
    classes => ["Alice", "Macbeth"]
  );

  $db->learn("Alice", "Alice was beginning to ...");
  $db->learn("Macbeth", "When shall we three meet again ...");

  my @ret = $db->classify("The Mole had been working very hard all the morning ...");

  say "Best classification is $ret[1]" unless ($ret[0] != Text::AI::CRM114::OK);

=head1 DESCRIPTION

This module provides a simple Perl interface to C<libcrm114>,
a library that implements several text classification algorithms.


=cut

use Carp;

# no exports
my $debug = 0;

=head1 CONSTANTS

C<libcrm114> uses several constants as status return values and to
set the classification algorithm of a new datablock. -- These constants
are accessible in this module's namespace, for example
C<Text::AI::CRM114::OK> and C<Text::AI::CRM114::OSB_WINNOW>.

=cut
use constant {
    OK                     => Text::AI::CRM114::libcrm114::OK,
    UNK                    => Text::AI::CRM114::libcrm114::UNK,
    BADARG                 => Text::AI::CRM114::libcrm114::BADARG,
    NOMEM                  => Text::AI::CRM114::libcrm114::NOMEM,
    REGEX_ERR              => Text::AI::CRM114::libcrm114::REGEX_ERR,
    FULL                   => Text::AI::CRM114::libcrm114::FULL,
    CLASS_FULL             => Text::AI::CRM114::libcrm114::CLASS_FULL,
    OPEN_FAILED            => Text::AI::CRM114::libcrm114::OPEN_FAILED,
    NOT_YET_IMPLEMENTED    => Text::AI::CRM114::libcrm114::NOT_YET_IMPLEMENTED,
    FROMSTART              => Text::AI::CRM114::libcrm114::FROMSTART,
    FROMNEXT               => Text::AI::CRM114::libcrm114::FROMNEXT,
    FROMEND                => Text::AI::CRM114::libcrm114::FROMEND,
    NEWEND                 => Text::AI::CRM114::libcrm114::NEWEND,
    FROMCURRENT            => Text::AI::CRM114::libcrm114::FROMCURRENT,
    NOCASE                 => Text::AI::CRM114::libcrm114::NOCASE,
    ABSENT                 => Text::AI::CRM114::libcrm114::ABSENT,
    BASIC                  => Text::AI::CRM114::libcrm114::BASIC,
    BACKWARDS              => Text::AI::CRM114::libcrm114::BACKWARDS,
    LITERAL                => Text::AI::CRM114::libcrm114::LITERAL,
    NOMULTILINE            => Text::AI::CRM114::libcrm114::NOMULTILINE,
    BYCHAR                 => Text::AI::CRM114::libcrm114::BYCHAR,
    STRING                 => Text::AI::CRM114::libcrm114::STRING,
    APPEND                 => Text::AI::CRM114::libcrm114::APPEND,
    REFUTE                 => Text::AI::CRM114::libcrm114::REFUTE,
    MICROGROOM             => Text::AI::CRM114::libcrm114::MICROGROOM,
    MARKOVIAN              => Text::AI::CRM114::libcrm114::MARKOVIAN,
    OSB_BAYES              => Text::AI::CRM114::libcrm114::OSB_BAYES,
    OSB                    => Text::AI::CRM114::libcrm114::OSB,
    CORRELATE              => Text::AI::CRM114::libcrm114::CORRELATE,
    OSB_WINNOW             => Text::AI::CRM114::libcrm114::OSB_WINNOW,
    WINNOW                 => Text::AI::CRM114::libcrm114::WINNOW,
    CHI2                   => Text::AI::CRM114::libcrm114::CHI2,
    UNIQUE                 => Text::AI::CRM114::libcrm114::UNIQUE,
    ENTROPY                => Text::AI::CRM114::libcrm114::ENTROPY,
    OSBF                   => Text::AI::CRM114::libcrm114::OSBF,
    OSBF_BAYES             => Text::AI::CRM114::libcrm114::OSBF_BAYES,
    HYPERSPACE             => Text::AI::CRM114::libcrm114::HYPERSPACE,
    UNIGRAM                => Text::AI::CRM114::libcrm114::UNIGRAM,
    CROSSLINK              => Text::AI::CRM114::libcrm114::CROSSLINK,
    READLINE               => Text::AI::CRM114::libcrm114::READLINE,
    DEFAULT                => Text::AI::CRM114::libcrm114::DEFAULT,
    SVM                    => Text::AI::CRM114::libcrm114::SVM,
    FSCM                   => Text::AI::CRM114::libcrm114::FSCM,
    NEURAL_NET             => Text::AI::CRM114::libcrm114::NEURAL_NET,
    ERASE                  => Text::AI::CRM114::libcrm114::ERASE,
    PCA                    => Text::AI::CRM114::libcrm114::PCA,
    BOOST                  => Text::AI::CRM114::libcrm114::BOOST,
    FLAGS_CLASSIFIERS_MASK => Text::AI::CRM114::libcrm114::FLAGS_CLASSIFIERS_MASK,
};

=head1 METHODS

=over

=item Text::AI::CRM114->new(%options)

Creates a new instance. Options and their default values are:

=over

=item flags => Text::AI::CRM114::OSB_BAYES

sets the classification algorithm, recommended values are 

C<Text::AI::CRM114::OSB_BAYES>, 
C<Text::AI::CRM114::OSB_WINNOW>, or
C<Text::AI::CRM114::HYPERSPACE>.
C<libcrm114> includes some more algorithms (SVM, PCA, FSCM) which
may or may not be production ready.

=item datasize => 0

the intended memory size for learned data.

Note that this parameter has no immediate effect! C<libcrm114> always creates
its data structure with a default size (depending on the algorithm, 8M for OSB);
this parameter is only used for some algorithms that might grow their dataset
after learning many items.

=item classes => ['A', 'B']

a list of classes passed by reference.

=back

=cut

sub new {
    my $class = shift;
    my $self = {
        flags => OSB_BAYES,
        datasize => 0,
        classes => ['A', 'B'],
        @_ };
    bless ($self, $class);

    carp sprintf("%s->(0x%x, %s, %s)", $class, $self->{flags},
        $self->{datasize}, $self->{classes}) if ($debug);

    # now set up the C structs
    my $cb = Text::AI::CRM114::libcrm114::new_cb();
    Text::AI::CRM114::libcrm114::cb_setflags($cb, $self->{flags});
    Text::AI::CRM114::libcrm114::cb_setclassdefaults($cb);
    Text::AI::CRM114::libcrm114::cb_setdatablock_size($cb, $self->{datasize});
    $self->{classmap} = {};
    my @classes = @{$self->{classes}};
    for (my $i=0; $i < scalar(@classes); $i++) {
        Text::AI::CRM114::libcrm114::cb_setclassname($cb, $i, $classes[$i]);
        $self->{classmap}->{$classes[$i]} = $i;
    }
	Text::AI::CRM114::libcrm114::cb_set_how_many_classes($cb, scalar(@classes));
    Text::AI::CRM114::libcrm114::cb_setblockdefaults($cb);
    $self->{db} = Text::AI::CRM114::libcrm114::new_db($cb);
    Text::AI::CRM114::libcrm114::db_setuserid_text($self->{db}, "Text::AI::CRM114");
    return $self;
}

=item Text::AI::CRM114->readfile($filename)

Creates a new instance by reading a previously saved CRM114 DB from C<$filename>.

=cut

sub readfile {
    my ($class, $filename) = @_;
    my $self = {};
    bless ($self, $class);

    carp "$class->readfile($filename)" if ($debug);

    $self->{db} = Text::AI::CRM114::libcrm114::db_read_bin($filename);
    unless ($self->{db}) {
        croak("Error in Text::AI::CRM114::libcrm114::db_read_bin");
    }
    $self->{mmap} = 1;

    my @classes = Text::AI::CRM114::libcrm114::db_getclasses($self->{db});
    $self->{classmap} = {};
    for (my $i=0; $i < scalar(@classes); $i++) {
        $self->{classmap}->{$classes[$i]} = $i;
    }
    return $self;
}

=item $db->getclasses()

Returns a hash reference to the DB's classes.
This hash associates the class names (keys) with the internal integer index (values).

=cut

sub getclasses {
    my $self = shift;
    return $self->{classmap};
}

sub DESTROY {
    my $self = shift;
    carp "DESTROYING $self" if ($debug);
    if (defined($self->{mmap}) and $self->{mmap}) {
        Text::AI::CRM114::libcrm114::db_close_bin($self->{db});
    }

    # TODO: check if and how to call C free()
    #Text::AI::CRM114::libcrm114::DESTROY($self->{db});
    #carp "DESTROYING ..." if ($debug);
    return;
}

=item $db->writefile($filename)

Writes the DB into a (binary) file.

=cut

sub writefile {
    my ($self, $filename) = @_;
    carp "writefile($filename)" if ($debug);
    return Text::AI::CRM114::libcrm114::db_write_bin($self->{db}, $filename);
}

=item $db->learn($class, $text)

Learn some text of a given class.

=cut

sub learn {
    my ($self, $class, $text) = @_;
    croak("learn requires category and text as arguments")
        unless (defined $class && defined $text);

    my $err = Text::AI::CRM114::libcrm114::learn_text($self->{db}, $self->{classmap}->{$class}, $text, length($text));
    if ($err != OK) {
        croak("Text::AI::CRM114::libcrm114::learn_text failed and returns #$err");
    }
}

=item $db->classify($text [, $verbatim] )

Classify the text.

The normal mode (without the optional C<$verbatim> flag)
adjusts the return values to be useful with two classes (e.g. spam/ham).

If the C<$verbatim> flag is true, then the values are passed unchanged as they come
from C<libcrm114>. See section "Classify Verbatim" below for more details and an
example.

Returns a list of five scalar values:

=over

=item $err

A numeric error code, should be C<Text::AI::CRM114::libcrm114::OK>

=item $class

The name of the best matching class.

=item $prob

The success probability. Normally the probability of the matching class (with 0.5 <= $prob <= 1)

=item $pR

The logarithmic probability ratio i.e. C<log10($prob) - log10(1-$prob)>
(theorethic range is 0 <= $pR <= 340, limited by floating point precision;
but in practice a p = .99 yields a pR = 2, so high values are rather unusual).

=back

=cut

sub classify {
    my ($self, $text, $verbatim) = @_;
    croak("classify_text requires a text as argument")
        unless (defined $text);

    my ($err, $class, $prob, $pR, $unk) = Text::AI::CRM114::libcrm114::classify($self->{db}, $text, length($text));

    if (!$verbatim and $self->{classmap}->{$class}) {
        # change prob and pR values relative to second class
        $prob = 1 - $prob;
        $pR = -$pR;
    }

    return ($err, $class, $prob, $pR);
}

=back

=head1 CLASSIFY VERBATIM

The following example shows the effect of the C<$verbatim> flag to C<classify()>:

  my $db = Text::AI::CRM114->new( classes => ["Macbeth", "Alice"]);
  $db->learn("Macbeth", SampleText::Macbeth());
  $db->learn("Alice",   SampleText::Alice());
  
  my @ret = $db->classify(SampleText::Willows_frag(), 1);
  printf "verbatim mode: err %d, class %s, prob %.3f, pR %.3f\n", @ret;
  @ret = $db->classify(SampleText::Willows_frag());
  printf "normal mode:   err %d, class %s, prob %.3f, pR %.3f\n", @ret;

Output is:

  verbatim mode: err 0, class Alice, prob 0.103, pR -0.938
  normal mode:   err 0, class Alice, prob 0.897, pR 0.938

The background here is that C<libcrm114> may use many classes, but on top of
that all classes have "success" and "failure" bits (as a meta-category if you
will). By default the first class indicates "success" and all other classes are
"failures".

This is important because the probability and the probability ratio (pR) of a
result is not given relative to a single class, but relative to the "success"
meta-category. So in the verbatim mode the probability of 0.103 is obviously
not the probability of the best class I<p(Alice)>, but it is the probability of
"success" I<p(success)>. If the first class is the best classification then
these numbers are the same (because the class and the meta-category align);
they are only different if another class is found to be the best match.

In order to simplify the expected most common usage with two classes, this
module inverts the values as needed.

The C<$verbatim> flag just provides access to the original values for those who
need them. If you use more than two classes then you should look into
C<libcrm114> for the exact meaning of the result values, and you might want to
add accessor methods to set the "success"/"failure" flags for single classes.

=head1 ISSUES

This is my first attempt to write a Perl module, so all hints and improvements
are appreciated.

I wonder if we should ensure Text::AI::CRM114::OK maps to 0, as this makes
the caller's return value checking easier.
Currently this is trivial because it already is 0 in C<libcrm114>.
If that should change we would have to insert a rewrite into
every XS call to a C function (ugly, but maybe worth it).

I am still not sure if the C memory management works correctly.

Another issue is Unicode support, which is missing in C<libcrm114>, so it might
be a good thing to convert unicode strings into some 8-bit encoding.
As long as no string contains \0-values nothing bad[tm] will happen,
but I assume that Unicode strings will internally cause wrong tokenization
(this should be checked in C<libtre>).

=head1 SEE ALSO

CRM114 homepage: L<http://crm114.sourceforge.net/>

AI::CRM114, a module using the crm language interpreter: L<https://metacpan.org/module/AI::CRM114>

=head1 HISTORY

=over

=item *

v0.05 change new() parameter passing from array to hash, set DB userid, move 2nd namespace

=item *

v0.04 remove crm114_strerror, which is not in libcrm114 tarball

=item *

v0.03 initial CPAN release

=item *

v0.02 initial push to github

=back

=head1 AUTHOR

Martin Schuette, E<lt>info@mschuette.nameE<gt>

=head1 COPYRIGHT AND LICENSE

Perl module: Copyright (C) 2012 by Martin Schuette

libcrm114: Copyright (C) 2009-2010 by William S. Yerazunis

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License version 3.


=cut

1;
__END__
