package Unicode::CharWidth;

use 5.010;
use strict;
use warnings;

=head1 NAME

Unicode::CharWidth - Character Width properties

=head1 VERSION

Version 1.05

=cut

our $VERSION = '1.05';

# the names of the character classes we'll define
# we arrange them so, that in an array of 4 elements the mbwidth value
# indexes the corresponding element, -1 being equivalent to 3

use Carp;
our @CARP_NOT = qw(utf8); # otherwise we see errors from unicode_heavy.pl

use constant CLASS_NAMES => (
    'InZerowidth',   # mbwidth ==  0 
    'InSinglewidth', # mbwidth ==  1
    'InDoublewidth', # mbwidth ==  2
    'InNowidth',     # mbwidth == -1
);

use constant WIDTH_VALUES => (0 .. 2, -1); # order corresponds to CLASS_NAMES
use constant STD_QUICKSTART => 'UCW_startup';

sub import {
    my $class = shift;
    my ($arg) = @_;
    if ( $arg and $arg eq '-gen' ) {
        _gen_and_save_proptab(_startup_path());
        carp 'Exiting';
        exit 0; # so no useful program runs with this option
    }
    _compile_functions();
    @_ = ($class);
    require Exporter;
    goto(Exporter->can('import') or die q(Exporter can't import?));
}

our @EXPORT = CLASS_NAMES;

# compile the four exported functions
sub _compile_functions {
    my $tabs = _get_proptab(_startup_path());
    for my $name ( CLASS_NAMES ) {
        my $tab = $tabs->{$name};
        no strict 'refs';
        # avoid 'redefined' warnings
        *$name = sub { $tab } unless __PACKAGE__->can($name);
    }
}

use Dir::Self;
use File::Spec::Functions ();

sub _startup_path {
    File::Spec::Functions::catfile(
        __DIR__, STD_QUICKSTART()
    )
}

sub _get_proptab {
    my $file = _startup_path();
    _read_startup($file) || croak(
        "Missing $file in distribution " . __PACKAGE__
    )
}

sub _gen_and_save_proptab {
    unless ( _effective_locale() =~ /\.UTF-8$/ ) {
        croak "Generation must be under a UTF-8 locale"
    }
    _write_startup(_gen_proptab(), _startup_path());
}

sub _effective_locale {
    $ENV{LC_CTYPE} || $ENV{LANG} || $ENV{LC_ALL} || ''
}

use constant MAX_UNICODE => 0x10FFFF;

sub _gen_proptab {
    require Text::CharWidth;
    my @proptab; # we'll make it a hash later (_reform_proptab)
    # make room for as many elements as we have class names
    # so index -1 is index 3 (InNowidth)
    $#proptab = $#{ [CLASS_NAMES] };
    my $last_width = 99; # won't occur
    for my $code ( 0 .. MAX_UNICODE ) {
        my $width = Text::CharWidth::mbwidth(chr $code);
        if ( $width == $last_width ) {
            # continue current interval
            $proptab[$width]->[-1]->[1] = $code;
        } else {
            # start new interval (pair) for current length
            push @{ $proptab[$width] }, [$code, $code];
        }
        $last_width = $width;
    }
    _reform_proptab(@proptab) # make a hash of strings, keyed by class name
}

sub _reform_proptab {
    my @proptab = @_;
    for my $tab ( @proptab ) {
        $tab = join "\n", map _one_or_two(@$_), @$tab;
    }
    my %proptab;
    @proptab{CLASS_NAMES()} = @proptab;
    \ %proptab
}

use constant CODEPOINT_FMT => '%04X';

sub _one_or_two {
    my ($from, $to) = @_;
    my $fmt = CODEPOINT_FMT; # print only first element if second is equal
    $fmt .= " $fmt" if $from != $to; # ... or both elements
    sprintf $fmt, $from, $to
}

use Storable ();

sub _read_startup {
    my ($file) = @_;
    my $tab = eval { Storable::retrieve($file) } or croak(
        _strip_error($@)
    );
    unless ( _validate_proptab($tab) ) {
        croak("File '$file' wasn't created by " . __PACKAGE__);
    }
    $tab;
}

sub _write_startup {
    my ($proptab, $file) = @_;
    # only write validated $proptab
    die "Failing our own validation" unless _validate_proptab($proptab);
    if ( eval { Storable::nstore($proptab, $file); 1 } ) {
        carp "Created startup file $file";
    } else {
        # remove file/line from message and re-croak
        croak _strip_error($@);
    }
    return # nothing in particular, no-one cares
}

sub _strip_error {
    my ($error) = @_;
    $error =~ s/at .* line \d+.*//s;
    ucfirst $error
}

        $@ =~ s/at .* line \d+.*//s;
use List::Util ();

sub _validate_proptab {
    my ($tab) = @_;
    my $ncn = @{ [CLASS_NAMES] }; # number of class names
    ref $tab eq 'HASH' and
    $ncn == grep { exists $tab->{$_} } CLASS_NAMES and
    $ncn == grep { defined $tab->{$_} } CLASS_NAMES and
    $ncn == grep { $tab->{$_} =~ /^[[:xdigit:]\s]*$/ } CLASS_NAMES
}

__PACKAGE__
__END__

=head1 SYNOPSIS

    use Unicode::CharWidth;

    if ( $string =~ /\p{InDoublewidth)/ ) {
        # string contains double width (two-column) characters
    }

    if ( $string !~ /\p{InNowidth} ) {
        # all string characters have a defined column width
    }

    # use capital P for negation

    if ( $string =~ /\P{InSinglewidth)/ ) {
        # string contains characters that aren't single width
    }

=head1 DESCRIPTION

=head2 Export

C<Unicode::CharWidth> exports four functions: C<InZerowidth>,
C<InSinglewidth>, C<InDoubleWidth> and C<InNowidth>.

These functions enable the use of like-named (inofficial) unicode
properties in regular expressions. Thus C</\p{InSinglewidth}/> matches
all characters that occupy a single screen column.

The functions are not supposed to be called directly (they return
strings that describe character properties, some of them lengthy),
but are automatically called by Perl's Unicode matching system.
They must be present in your current package for the L</unicode properties>
to work as described below.

C<Unicode::CharWidth> normally ignores arguments in the C<use>-statement.
There is one exception:

    use Unicode::CharWidth -gen

You don't ever I<need> to run this on an installed copy of this module.
See L</The -gen Option> for more.

=head2 Unicode Properties

The enabled Unicode properties are InZerowidth, InSinglewidth,
InDoubleWidth, and InNowidth.

They are not derived from Unicode documents directly, but rely on
the implementation of the C library function C<wcwidth(3)>.

=over 4

=item InZerowidth

C</\p{InZerowidth}/> matches the characters that don't occupy 
column space of their own. Most of these are modifying or overlay
characters that add accents or overstrokes to the preceding character.
C<"\0"> also has zero width. It is the only zero width character in
the ASCII range.

=item InSinglewidth

C</\p{InSinglewidth}/> matches what most westerners would consider
"normal" characters that occupy a single screen column. All printing
(non-control) ASCII characters are in this class, as well as most
characters in other alphabetic scripts.

=item InDoublewidth

C</\p{InDoublewidth}/> matches characters (in east-asian scripts) that
occupy two adjacent screen columns. There are no ASCII characters in this
class.

=item InNowidth

C</\p{InNowidth}/> These are characters that don't have a (fixed) column
width assigned at all. All ASCII control characters except C<"\0"> are in
this class, C<"\t">, C<"\n">, and C<"\r"> are examples.  Outside ASCII,
vast ranges of unassigned and reserved unicode characters fall in
this class.

=back

Every unicode character has (matches) exactly one of these four
character properties. Thus the column width (if any) of a 
character can in principle be recovered by trying it against
the four regexes and registering which one matched. But
use the function C<Text::CharWidth::mbwidth> for that (under a
unicode locale), it is much faster and it's what the character
properties are based on in the first place.

=head2 The -gen Option

As mentioned, C<use Unicode::CharWidth -gen> is handled as a special
case. Its purpose is to generate a file that holds the definitions
of the character properties exported by this module. The file (called
F<UCW_startup>) is distributed with the module, so there is no need
to generate it again. If it gets lost or corrupted (rarely), you can
force a re-install like with any other damaged module.

The -gen mechanism is not separated from the distribution,
though techically it could, mostly for simplicity, but also,
... we're supposed to be open software, aren't we? Generating
files in private and shipping them to an unsuspecting public
isn't the done thing.

If you want to to run with -gen for any reason, you must be able to do
a few things:

=over 4

=item Overwrite the shipped UCW_startup file

The shipped file is installed directly next to the file 
F<.../Unicode/CharWidth.pm>, as F<.../Unicode/UCW_startup>.
(Consult C<$INC{'Unicode/CharWidth.pm'}> if in doubt.) You must
have permission to overwrite/create that file as necessary.

=item Have C<Text::CharWidth> installed

While this module is entirely based on C<Text::CharWidth>,
C<Text::CharWidth> isn't a prerequisite.  All the wisdom we draw from it
is packed into the startup file. If you want to generate the startup file,
you need the module.

=item Run Under a Unicode Locale

Our base function(s) from C<Text::CharWidth> are in fact locale dependent.
To make sure that the generated file conforms to unicode semantics,
we must secure an appropriate locale. The effective locale for our
purpose is C<$ENV{LC_CTYPE} || $ENV{LANG} || $ENV{LC_ALL} || ''> and it
must end with the string ".UTF-8" (this could probably be more liberal).

=back

If these conditions are met, C<use Unicode::CharWidth> generates the
startup file and exits (!) with return code 0. That is so that no
useful program can have the option accidentally set, it cannot be
combined with a normal run.

=head1 See Also

Text::CharWidth, Unicode::EastAsianWidth

=head1 AUTHOR

Anno Siegel, C<< <anno5 at mac.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-unicode-charwidth at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Unicode-CharWidth>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Unicode::CharWidth


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Unicode-CharWidth>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Unicode-CharWidth>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Unicode-CharWidth>

=item * Search CPAN

L<http://search.cpan.org/dist/Unicode-CharWidth/>

=back

=head1 ACKNOWLEDGEMENTS

The B<C community> is the author of our grandmother function,
C<wcwidth(3)>.

B<KUBOTA> is the author of our mother module
L<https://metacpan.org/pod/Text::CharWidth>. This module is
essentially based on one of its functions, C<mbwidth()> which
in its turn is based on C<wcwidth(3)>.

B<AUDREYT> is the author of our sister module
L<https://metacpan.org/pod/Unicode::EastAsianWidth>,
which was a role model for this implementation.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Anno Siegel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
