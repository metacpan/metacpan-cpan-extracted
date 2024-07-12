package Text::Schmutz;

# ABSTRACT: You̇r screen is quiṭe dirty, please cleȧn it.

use v5.20;
use utf8;

use Moo;

use Types::Common qw( ArrayRef Bool NumRange StrLength );

# RECOMMEND PREREQ: Type::Tiny::XS

use experimental qw( postderef signatures );

our $VERSION = 'v0.1.1';


my $Prob = NumRange [ 0, 1 ];

has prob => (
    is      => 'ro',
    isa     => $Prob,
    default => 0.1,
);


has use_small => (
    is      => 'lazy',
    isa     => Bool,
    default => sub($self) { return !( $self->use_large || $self->strike_out ) },
);


has use_large => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has strike_out => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has _schmutz => (
    is      => 'lazy',
    isa     => ArrayRef [ StrLength [1] ],
    builder => sub($self) {
        my @schmutz;

        push @schmutz, ( "\x{0323}", "\x{0307}", "\x{0312}" ) if $self->use_small;
        push @schmutz, ( "\x{0314}", "\x{031C}", "\x{0358}", "\x{0353}", "\x{0335}" ) if $self->use_large;
        push @schmutz,
          ( "\x{0337}", "\x{0338}", "\x{0336}", "\x{0335}", "\x{20d2}", "\x{20d3}", "\x{20e5}", "\x{20e6}", "\x{20eb}" )
          if $self->strike_out;
        return \@schmutz;

    },
    init_arg => undef,
);


sub mangle ( $self, $text, $prob = undef ) {

    my @schmutz = $self->_schmutz->@*;
    my $size    = scalar(@schmutz);

    $Prob->assert_valid( $prob //= $self->prob );

    return join( "", map { rand(1) <= $prob ? $_ . $schmutz[ int( rand($size) ) ] : $_ } split //, $text );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Schmutz - You̇r screen is quiṭe dirty, please cleȧn it.

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

    use Text::Schmutz;

    my $s = Text::Schmutz->new( prob => 0.1, use_small => 1 );

    say $s->mangle($text);

=head1 DESCRIPTION

"Th̔ough̜t̒s of ḍirt spill ̵ȯve̜r to ̜yo͘ur ̜u̒nico͘de̜ ͘enabled t̵ext"

This is a Perl adaptation of F<schmutz.go> by Clemens Fries <github-schmutz@xenoworld.de>.

=head1 ATTRIBUTES

=head2 prob

This is the probability that a character will be dirty, between 0 and 1. It defaults to 0.1.

=head2 use_small

"spray dust on your text".

If L</use_large> and L</strike_out> are not enabled, then this is enabled by default.

For example:

    Ḷorem i̇ps̒um ̒doḷor sit amet, conse̒ctėṭur adipiscing eḷit̒, ̒se̒d ̒ḋo
    eiusṃo̒d ̣tempor incịḍiḋunt ut lạbore ̣e̒t dolo̒re ̣ma̒gna̒ ̣aliq̒uȧ.

=head2 use_large

"a cookie got mangled in your typewriter"

For example, with L</prob> set to 0.5:

    L̔ore̔m ͓ipsum͘ dol͓or͓ sit am͓e͘t̔, ͓cons͓ectet̔ur ͘a̔d̵i̜pisc̔in̜g el̵i͓t͓,͓ s̵e͘d͘ do̔
    ei͘usm͓od̜ ͓temp̜or ͓i̵n̔c͓idid̵u̜nt ut ̔la̔bo̜r̵e ̵et̵ ̵dolore̜ ma̵gn͓a͓ ͘al̵i̔qua͓.̵

=head2 strike_out

"this is unacceptable"

For example, with L</prob> set to 1.0:

    L⃫o⃓r⃫e̷m⃓ ⃒i⃥p⃓s̶u⃓m⃥ ⃫d⃒o⃥l⃒o̵r⃦ ̶s̶i⃫t̸ ̶a⃥m̶e⃒t̶,⃥ ̵c⃫o⃥n⃓s̷e⃓c̵t⃒e⃓t̶u̶r⃫ ⃥a⃒d⃥i̶p̵i̵s̷c̸i⃓n⃒g⃒ ̵e̸l⃦i⃓t⃒,̵ ⃥s̵e⃥d̸ ̵d̶o̶
    ̷e̵i⃥u̵s⃓m⃓o⃫d̶ ̸t̶e⃒m̸p⃓o⃦r⃒ ⃒i̷n⃥c⃫i⃓d⃥i̵d̷u̷n̶t̸ ̵u̷t⃥ ̶l̷a⃦b⃥o̵r⃓e⃒ ⃒e̵t̸ ̸d⃦o̸l̵o̵r⃓e̶ ⃒m̷a̷g̷n̵a̵ ̵a⃦l̷i̷q⃥u̸a̶.⃒

=head1 METHODS

=head2 mangle

   $dirty = $s->mangle( $text, $prob );

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Text-Schmutz>
and may be cloned from L<git://github.com/robrwo/perl-Text-Schmutz.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Text-Schmutz/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The original L<schmutz|https://github.com/githubert/schmutz> was written by Clemens Fries <github-schmutz@xenoworld.de>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Robert Rothenberg.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
