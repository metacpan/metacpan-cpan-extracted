package Perl::Critic::Policy::ProhibitLeadingZeros;
$Perl::Critic::Policy::ProhibitLeadingZeros::VERSION = '1.000';
# ABSTRACT: A leading zero is octal, which is right for a file mode and a bug anywhere else.

use strict;
use warnings;

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{Integer with leading zeros};
Readonly::Scalar my $EXPL => q{Perl reads it as octal; only a mode handed straight to a function that takes one should look like that};

Readonly::Array my @DEFAULT_ALLOW => qw{ chmod dbmopen mkdir mkpath make_path sysopen umask };

# Zeros, and then a significant digit: 0600, 0_644, -007.  Not 0, 00, 0.5, 0x1f
# or 0b101, none of which reads as a decimal that is not one.
Readonly::Scalar my $LEADING_ZERO_RX => qr/\A [+-]? (?: 0+ _* )+ [1-9]/xms;

# Operators that sit between arguments rather than inside one.  The
# low-precedence ones end a list operator's arguments: mkdir $d, 0700 or die.
Readonly::Hash my %LOW_PRECEDENCE => map { $_ => 1 } qw{ or and xor };
Readonly::Hash my %SEPARATOR      => ( q{,} => 1, q{=>} => 1, %LOW_PRECEDENCE );

# Words is_function_call() counts as calls that declare rather than call.
Readonly::Hash my %DECLARATOR => map { $_ => 1 } qw{ my our local state };


sub supported_parameters {
    return (
        {
            name           => 'allow',
            description    => 'Functions and methods that may take a literal with leading zeros, in addition to the built-in list.',
            default_string => join( q{ }, @DEFAULT_ALLOW ),
            behavior       => 'string list',
        }
    );
}


sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    # 'string list' hands us the configured value in place of the default, and
    # somebody naming one function of their own did not mean to start reporting
    # chmod.
    $self->{_allow}{$_} = 1 for @DEFAULT_ALLOW;

    return $self->SUPER::initialize_if_enabled($config);
}


sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return () }
sub applies_to       { return 'PPI::Token::Number' }


sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->content() !~ $LEADING_ZERO_RX;

    my $call = _enclosing_call($elem);
    return if $call && $self->_allowed($call);

    return $self->violation( $DESC, $EXPL, $elem );
}

# The word naming the call $node is the whole of an argument to, or nothing.
# Climbs out through parentheses and anonymous hashes and arrays, which is where
# named arguments live, and stops at anything else: a block, a subscript, a
# condition, the statement's end.
sub _enclosing_call {
    my ($node) = @_;

    return if !_is_whole_argument($node);

    my $list_operator = _list_operator_before($node);
    return $list_operator if $list_operator;

    my $structure = $node->parent()->parent();
    return if !$structure;

    if ( $structure->isa('PPI::Structure::List') ) {
        my $before = $structure->sprevious_sibling();
        return $before if $before && $before->isa('PPI::Token::Word');
        return _enclosing_call($structure);
    }

    return _enclosing_call($structure) if $structure->isa('PPI::Structure::Constructor');
    return;
}

sub _is_whole_argument {
    my ($node) = @_;

    foreach my $neighbour ( $node->sprevious_sibling(), $node->snext_sibling() ) {
        next     if !$neighbour || !$neighbour->isa('PPI::Token::Operator');
        return 0 if !$SEPARATOR{ $neighbour->content() };
    }
    return 1;
}

# The parenless call whose arguments $node is among, `chmod 0600, $file`: the
# nearest word before it that is called and is not already done taking
# arguments, either by having its own parentheses or by being followed straight
# away by an operator, as O_CREAT is in `O_CREAT, 0600`.
sub _list_operator_before {
    my ($node) = @_;

    for ( my $sibling = $node->sprevious_sibling(); $sibling; $sibling = $sibling->sprevious_sibling() ) {
        return if $sibling->isa('PPI::Token::Operator') && $LOW_PRECEDENCE{ $sibling->content() };
        next   if !$sibling->isa('PPI::Token::Word');
        next   if $DECLARATOR{ $sibling->content() } || !is_function_call($sibling);

        my $after = $sibling->snext_sibling();
        next if $after->isa('PPI::Structure::List') || $after->isa('PPI::Token::Operator');

        return $sibling;
    }
    return;
}

# An entry with no package matches the name however it is reached; one with a
# package matches only a call that names that package, as Pkg::name or
# Pkg->name.
sub _allowed {
    my ( $self, $word ) = @_;

    my $name  = $word->content();
    my $arrow = $word->sprevious_sibling();
    if ( $arrow && $arrow->content() eq '->' ) {
        my $invocant = $arrow->sprevious_sibling();
        return $self->{_allow}{"${invocant}::$name"} || $self->{_allow}{$name}
          if $invocant && $invocant->isa('PPI::Token::Word');
        return $self->{_allow}{$name};
    }

    my $short = $name =~ s/\A.*:://r;
    return $self->{_allow}{$name} || $self->{_allow}{$short};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ProhibitLeadingZeros - A leading zero is octal, which is right for a file mode and a bug anywhere else.

=head1 VERSION

version 1.000

=head1 Perl::Critic::Policy::ProhibitLeadingZeros

Perl reads an integer with a leading zero as octal, so C<0032> is twenty-six.
Nobody writes that on purpose, except for a file mode, where octal is the
notation everyone reads:

    chmod 0600, $key;           # a mode: fine
    my $retries = 0010;         # eight, not ten

This policy reports the second and not the first.  A literal with leading zeros
is allowed when it is handed, whole, to a function or method that takes a mode;
everywhere else it is reported, and the fix is C<oct('0010')> or no zeros.

This is a fork of
L<Perl::Critic::Policy::Plicease::ProhibitLeadingZeros|https://metacpan.org/pod/Perl::Critic::Policy::Plicease::ProhibitLeadingZeros>,
from L<Perl-Critic-Plicease|https://github.com/uperl/Perl-Critic-Plicease> by
Graham Ollis.  That policy hard-codes C<chmod> and C<mkpath>; this one takes a
list, adds to it from configuration, and finds the call a literal belongs to by
walking the document rather than by counting siblings.

=head2 PROHIBITED

    my $z = 0032;
    $mode & 0777;
    my $perms = ( stat $file )[2] & 07777;
    is( $mode, 0600, 'the key is private' );
    chmod( ( stat $from )[2] & 07777, $to );   # a mask, not a mode
    my %args = ( mode => 0755 );               # not yet handed to anything
    use constant MODE => 0600;

=head2 ALLOWED

    umask 0022;
    chmod 0600, $key;
    chmod( 02750, $dir );
    mkdir $dir, 0700 or die;
    dbmopen( %cache, $file, 0600 );
    sysopen( my $fh, $path, O_WRONLY | O_CREAT, 0600 );
    mkpath( $dir, 1, 0700 );
    make_path( $dir, { mode => 0711 } );
    $path->chmod(0600);

And anything without a significant digit after its zeros, which is not octal by
accident: C<0>, C<00>, C<0.5>, C<0x1f>, C<0b101>.

=head2 CONFIGURATION

=over 4

=item C<allow>

Space separated list of functions and methods that may be handed a literal with
leading zeros.  It B<adds to> the built-in list rather than replacing it, so you
name only your own:

    [ProhibitLeadingZeros]
    allow = Provisioner::Utils::write_pem Test::MockFile::new_dir

The built-in list is:

    chmod dbmopen mkdir mkpath make_path sysopen umask

=back

What a name matches:

=over 4

=item A name with no package, C<chmod>

Any call to a function or method of that name, however it is reached:
C<chmod(...)>, C<CORE::chmod(...)>, C<< $path->chmod(...) >> and
C<< Some::Class->chmod(...) >>.  This is what the built-in names are, which is
how C<< $path->chmod(0600) >> for L<Path::Tiny> and C<< dir()->mkpath(1, 0700) >>
for L<Path::Class> are allowed.

=item A name with a package, C<Provisioner::Utils::write_pem>

Only a call that names that package: C<Provisioner::Utils::write_pem(...)>, or
the class method C<< Provisioner::Utils->write_pem(...) >>.  Not a bare
C<write_pem(...)>, and not C<< $object->write_pem(...) >>, since the policy
cannot know what package either one ends up in.

=back

Where in the call the literal may be:

=over 4

=item In any argument

There is no position.  C<chmod(0600, $f)> and a mode as the fourth argument of
C<sysopen> are alike; so is a mode as the value in an anonymous hash or array of
named arguments, C<< make_path( $dir, { mode => 0711 } ) >>, however deep.

=item As the whole of that argument

C<0600> is allowed in C<chmod 0600, $f>, and C<07777> is not in
C<< chmod( (stat $f)[2] & 07777, $t ) >>: next to any operator but a comma, a fat
comma or a low-precedence C<or>, C<and> or C<xor>, it is an operand in an
expression rather than a mode.

=item Of the nearest call

In C<chmod( foo(0600), $f )> the literal is C<foo>'s argument, not C<chmod>'s,
and C<foo> decides.

=back

=head2 CAVEATS

A mode has to be written where the call is.  One assigned to a variable or a
hash first, C<< my %opt = ( mode => 0755 ) >>, is not handed to anything the
policy can see, and is reported.

A mode chosen by a ternary, C<< chmod $dir ? 0755 : 0644, $f >>, or combined
with another, C<chmod 0666 & ~umask, $f>, is an operand and is reported too.
Write the combination out, or say C<## no critic (ProhibitLeadingZeros)>.

A name with no package matches any method of that name on any object, since
there is no knowing what class an invocant is.  Name the package if that is too
broad.

=head2 DIFFERENCES FROM THE ORIGINAL

What moving from C<[Plicease::ProhibitLeadingZeros]> changes, besides C<allow>:

=over 4

=item *

C<umask 0022>, C<mkdir>, C<make_path>, C<sysopen>, C<dbmopen> and
C<< Some::Class->chmod(0600) >> are allowed, where the original reported them.

=item *

C<mkpath> is allowed a mode however it is called.  The original allowed the
parenless form only with exactly three arguments, and the parenthesised form
only as a statement of its own, so not in C<mkpath( $d, 1, 0700 ) or die>.

=item *

A mask inside C<chmod>'s arguments is reported.  The original allowed
C<< chmod( $m & 07777, $t ) >> and C<chmod 0666 & ~umask, $f>.

=item *

A C<## no critic (Plicease::ProhibitLeadingZeros)> does not match this policy's
name, so an annotation that is still needed has to be renamed to
C<## no critic (ProhibitLeadingZeros)>.

=back

=head2 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros>, the core
policy, which allows C<chmod>, C<dbmopen>, C<mkdir>, C<sysopen> and C<umask> but
cannot be told about anything else.

=head2 METHODS

=head3 supported_parameters

C<allow>, the functions and methods that may take a literal with leading zeros,
added to the built-in list.

=head3 initialize_if_enabled

Folds the built-in names back into whatever C<allow> was configured with, so a
user's list adds to the defaults instead of replacing them.

=head3 default_severity

SEVERITY_MEDIUM

=head3 default_themes

None, as in the original.

=head3 applies_to

PPI::Token::Number

=head3 violates

Standard L<Perl::Critic::Policy> interface.  Returns a violation for a literal
with leading zeros, unless it is the whole of an argument to a call that
C<allow> names.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitleadingzeros/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

Original author, of Perl::Critic::Policy::Plicease::ProhibitLeadingZeros:

=over 4

=item *

Graham Ollis <plicease@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2024 by Graham Ollis, as
Perl::Critic::Policy::Plicease::ProhibitLeadingZeros in Perl-Critic-Plicease.

Modifications are copyright (c) 2026 by Troglodyne LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
