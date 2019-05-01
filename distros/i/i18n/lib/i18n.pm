package i18n;
$i18n::VERSION = '0.13';

use 5.006;
use strict;
use constant DATA    => 0;
use constant LINE    => 1;
use constant PACKAGE => 2;
use constant NEGATED => 3;
use warnings::register;
use overload (
    '~'      => \&_negate,
    '.'      => \&_concat,
    '""'     => \&_stringify,
    fallback => 1,
);

sub import {
    my $class  = shift;
    my $caller = caller;

    local $@;
    eval { require Locale::Maketext::Simple; 1 } or return;

    overload::constant(
        q => sub {
            shift;
            pop;
            bless(
                [
                    \@_,                 # DATA
                    ( caller(1) )[2],    # LINE
                    $caller,             # PACKAGE
                ],
                $class
            );
        },
    );

    {
        no strict 'refs';
        no warnings 'redefine';

        delete ${"$class\::"}{loc};
        delete ${"$class\::"}{loc_lang};

        unshift @_, 'Path' if @_ % 2;
        Locale::Maketext::Simple->import(@_);

        *{"$caller\::loc"}      = $class->can('loc');
        *{"$caller\::loc_lang"} = $class->can('loc_lang');

        *{"$class\::loc"}      = \&_loc;
        *{"$class\::loc_lang"} = \&_loc_lang;
    }

    @_ = ( warnings => $class );
    goto &warnings::import;
}

sub unimport {
    my $class = shift;
    overload::remove_constant('q');

    @_ = ( warnings => $class );
    goto &warnings::unimport;
}

sub loc      { goto \&_loc }
sub loc_lang { goto \&_loc_lang }

sub _loc {
    my $class = shift;
    return $_[0] unless UNIVERSAL::can( $_[0], '_negate' );
    goto &_do_loc;
}

sub _loc_lang {
    my $class    = shift;
    my $caller   = caller;
    my $loc_lang = $caller->can('loc_lang') or return;
    goto &$loc_lang;
}

sub _negate {
    my $class = ref $_[0];

    return ~_stringify( $_[0] ) unless warnings::enabled($class);

    goto &_do_loc if $_[0][NEGATED];

    bless(
        [
            [ @{ $_[0][DATA] } ],    # DATA
            $_[0][LINE],             # LINE
            $_[0][PACKAGE],          # PACKAGE
            1,                       # NEGATED
        ],
        $class
    );
}

sub _concat {
    my $class = ref $_[0];
    my $pkg   = $_[0][PACKAGE];

    @_ = reverse(@_) if pop;
    return join( '', @_ ) unless warnings::enabled($class);

    my $line = (caller)[2];
    my ( $seen, @data );

    foreach (@_) {
        ( push( @data, bless( \\$_, "$class\::var" ) ), next )
          unless ref($_)
              and UNIVERSAL::isa( $_, $class );
        $seen++;

        ( push( @data, bless( \\$_, "$class\::var" ) ), next )
          unless $_->[LINE] == $line and !$_->[NEGATED];
        $seen++;

        $pkg = $_->[PACKAGE];
        push @data, @{ $_->[DATA] };
    }

    return join( '', @data ) if $seen < 2;

    return bless(
        [
            \@data,    # DATA
            $line,     # LINE
            $pkg,      # PACKAGE
        ],
        $class
    );
}

sub _stringify {
    ( $_[0][NEGATED] )
      ? ~join( '', map { ( ref $_ ) ? "$$$_" : "$_" } @{ $_[0][DATA] } )
      : join( '', map { ( ref $_ ) ? "$$$_" : "$_" } @{ $_[0][DATA] } );
}

sub _do_loc {
    my $class = ref $_[0];
    my $pkg   = $_[0][PACKAGE];

    my $loc = $pkg->can('loc')
      or return ~"$_[0]";

    my @vars;
    my $format = join(
        '',
        map {
            UNIVERSAL::isa( $_, "$class\::var" )
              ? do { push( @vars, $$$_ ); "[_" . @vars . "]" }
              : do { my $str = $_; $str =~ s/(?=[\[\]~])/~/g; $str };
          } @{ $_[0][DATA] }
    );

    # Defeat constant folding
    return bless( [ $loc => $format ], 'i18n::string' ) if !@vars;

    @_ = ( $format, @vars );
    goto &$loc;
}

package
    i18n::string;

use overload (
    '""'     => \&_stringify,
    '0+'     => \&_stringify,
    fallback => 1,
);

sub _stringify {
    $_[0][0]->( $_[0][1] );
}

package
    i18n::var;

use overload (
    '""'     => \&_stringify,
    '0+'     => \&_stringify,
    fallback => 1,
);

sub _stringify { ${ ${ $_[0] } } }

1;

__END__

=head1 NAME

i18n - Perl Internationalization Pragma

=head1 VERSION

This document describes version 0.13 of i18n, released May 1, 2019.

=head1 SYNOPSIS

In one-liners:

    % export LANG=sp
    % perl -Mi18n=/path/to/po-files/ -le 'print ~~"Hello, world"';
    Hola, mundo

In your module:

    use i18n "/path/to/po-files";
    my $place = ~~'world';
    print ~~"Hello, $world";

=head1 DESCRIPTION

Internationalization (abbreviated C<i18n>) is the process of designing an
application so that it can be adapted to various languages and regions.
The most basic task is to let your program know which strings are meant
for human consumption and which strings are intended for the computer.

Strings for humans need to get localized (translated to the language of
the human using your program) and strings for computers B<must not> get
translated.

=head2 Syntax

The C<i18n> module gives you a remarkably simple way to mark strings
that are intended for humans. All you do is put two tilde signs (C<~~>)
in front of every string that is intended to be translated.  That's it.
All the other details of localization are handled outside the program.
Here are some examples:

    my $str1 = ~~'The time is now';
    my $str2 = ~~"$str1 for having a cow";
    my $str3 = ~~qq{Wow! $str2};
    my $str4 = ~~<<END;
    How now.
    Brown cow.
    END

Think of the tilde signs as an indicator that you are looking for things
that B<approximates> the string in the user's language.  To turn off the
magic of C<~~> lexically, just say:

    no i18n;

One nice thing about this particular markup, is that you can completely
turn off internationalization, by simply removing the C<use i18n;> statement.
The C<~~> signs are actually valid Perl that just happen to not do anything
in this context, and thus are constant-optimized away at compile time.

=head2 Implementation

When you say:

    my $string = ~~"Bob is your uncle";

then C<$string> really is an C<i18n::string> object that is overloaded to
stringify as a localized translation.

Currently, the magic is just a thin wrapper on C<Locale::Maketext::Simple>,
which makes it equivalent to this call:

    my $string = loc("Bob is your uncle");

Similarly, this line:

    my $string = ~~"$person is your uncle";

will be turned into this at runtime:

    my $string = loc("[_1] is your uncle", $person);

=head1 CAVEATS

The authors of this module are not linguists.  If you would like to help us
define suitable C<i18n> magic for your language, please send us an email.

=head1 SEE ALSO

L<Locale::Maketext::Simple>, L<Locale::Maketext::Lexicon>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>,
Ingy dE<ouml>t Net E<lt>INGY@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2004, 2005, 2006, 2007, 2016, 2019 by
Audrey Tang E<lt>cpan@audreyt.orgE<gt>,
Ingy dE<ouml>t Net E<lt>INGY@cpan.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
