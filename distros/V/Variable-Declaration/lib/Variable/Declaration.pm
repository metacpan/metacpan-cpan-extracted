package Variable::Declaration;
use v5.12.0;
use strict;
use warnings;

our $VERSION = "0.06";

use Keyword::Simple;
use PPR;
use Carp ();
use Import::Into;
use Data::Lock ();
use Type::Tie ();

our $LEVEL;
our $DEFAULT_LEVEL = 2;

sub import {
    shift;
    my %args = @_;
    my $caller = caller;

    $LEVEL = exists $args{level} ? $args{level}
           : exists $ENV{'Variable::Declaration::LEVEL'} ? $ENV{'Variable::Declaration::LEVEL'}
           : $DEFAULT_LEVEL;

    feature->import::into($caller, 'state');

    Keyword::Simple::define 'let'    => \&define_let;
    Keyword::Simple::define 'static' => \&define_static;
    Keyword::Simple::define 'const'  => \&define_const;
}

sub unimport {
    Keyword::Simple::undefine 'let';
    Keyword::Simple::undefine 'static';
    Keyword::Simple::undefine 'const';
}

sub define_let    { define_declaration(let => 'my', @_) }
sub define_static { define_declaration(static => 'state', @_) }
sub define_const  { define_declaration(const => 'my', @_) }

sub define_declaration {
    my ($declaration, $perl_declaration, $ref) = @_;

    my $match = _valid($declaration => _parse($$ref));
    my $tv    = _parse_type_varlist($match->{type_varlist});
    my $args  = +{ declaration => $declaration, perl_declaration => $perl_declaration, %$match, %$tv, level => $LEVEL };

    substr($$ref, 0, length $match->{statement}) = _render_declaration($args);
}

sub croak { Carp::croak @_ }

sub data_lock { Data::Lock::dlock @_ }

sub type_tie(\[$@%]@);
{
    *type_tie = \&Type::Tie::ttie;
}

our %metadata;
sub info {
    my $variable_ref = shift;
    die 'argument must be reference' unless ref $variable_ref;
    my $info = $metadata{$variable_ref} or return undef;
    require Variable::Declaration::Info;
    Variable::Declaration::Info->new(
        declaration      => $info->{declaration},
        type             => $info->{type},
        attributes       => $info->{attributes},
    )
}

sub register_info {
    my ($variable_ref, $info) = @_;
    $metadata{$variable_ref} = {
        declaration      => $info->{declaration},
        type             => $info->{type},
        attributes       => $info->{attributes},
    };
}

sub _valid {
    my ($declaration, $match) = @_;

    croak "variable declaration is required"
        unless $match->{type_varlist};

    my ($eq, $assign) = ($match->{eq}, $match->{assign});
    if ($declaration eq 'const') {
        croak "'const' declaration must be assigned"
            unless defined $eq && defined $assign;
    }
    else {
        croak "illegal expression"
            unless (defined $eq && defined $assign) or (!defined $eq && !defined $assign);
    }

    return $match;
}

sub _render_declaration {
    my $args = shift;
    my @lines;
    push @lines => _lines_declaration($args);
    push @lines => _lines_register_info($args);
    push @lines => _lines_type_check($args) if $args->{level} >= 1;
    push @lines => _lines_type_tie($args)   if $args->{level} == 2;
    push @lines => _lines_data_lock($args)  if $args->{declaration} eq 'const';
    return join ";", @lines;
}

sub _lines_declaration {
    my $args = shift;
    my $s = $args->{perl_declaration};
    $s .= do {
        my $s = join ', ', map { $_->{var} } @{$args->{type_vars}};
        $args->{is_list_context} ? " ($s)" : " $s";
    };
    $s .= $args->{attributes} if $args->{attributes};
    $s .= " = @{[$args->{assign}]}" if defined $args->{assign};
    return ($s);
}

sub _lines_type_tie {
    my $args = shift;
    my @lines;
    for (@{$args->{type_vars}}) {
        my ($type, $var) = ($_->{type}, $_->{var});
        next unless $type;
        push @lines => sprintf('Variable::Declaration::type_tie(%s, %s, %s)', $var, $type, $var);
    }
    return @lines;
}

sub _lines_type_check {
    my $args = shift;
    my @lines;
    for (@{$args->{type_vars}}) {
        my ($type, $var) = ($_->{type}, $_->{var});
        next unless $type;
        push @lines => sprintf('Variable::Declaration::croak(%s->get_message(%s)) unless %s->check(%s)', $type, $var, $type, $var)
    }
    return @lines;
}

sub _lines_data_lock {
    my $args = shift;
    my @lines;
    for my $type_var (@{$args->{type_vars}}) {
        push @lines => "Variable::Declaration::data_lock($type_var->{var})";
    }
    return @lines;
}

sub _lines_register_info {
    my $args = shift;
    my @lines;
    for my $type_var (@{$args->{type_vars}}) {
        push @lines => sprintf("Variable::Declaration::register_info(\\%s, { declaration => '%s', attributes => %s, type => %s })",
            $type_var->{var},
            $args->{declaration},
            ($args->{attributes} ? "'$args->{attributes}'" : 'undef'),
            ($type_var->{type} or 'undef'),
        );
    }
    return @lines;
}

sub _parse {
    my $src = shift;

    return unless $src =~ m{
        \A
        (?<statement>
            (?&PerlOWS)
            (?<assign_to>
                (?<type_varlist>
                    (?&PerlIdentifier)? (?&PerlOWS)
                    (?&PerlVariable)
                |   (?&PerlParenthesesList)
                ) (?&PerlOWS)
                (?<attributes>(?&PerlAttributes))? (?&PerlOWS)
            )
            (?<eq>=)? (?&PerlOWS)
            (?<assign>(?&PerlConditionalExpression))?
        ) $PPR::GRAMMAR }x;

    return +{
        statement       => $+{statement},
        type_varlist    => $+{type_varlist},
        assign_to       => $+{assign_to},
        eq              => $+{eq},
        assign          => $+{assign},
        attributes      => $+{attributes},
    }
}

sub _parse_type_varlist {
    my $expression = shift;

    if ($expression =~ m{ (?<list>(?&PerlParenthesesList)) $PPR::GRAMMAR }x) {
        my ($type_vars) = $+{list} =~ m/\A\((.+)\)\Z/;
        my @list = split ',', $type_vars;
        return +{
            is_list_context => 1,
            type_vars       => [ map { _parse_type_var($_) } @list ],
        }
    }
    elsif (my $type_var = _parse_type_var($expression)) {
        return +{
            is_list_context => 0,
            type_vars       => [ $type_var ],
        }
    }
    else {
        return;
    }
}

sub _parse_type_var {
    my $expression = shift;

    return unless $expression =~ m{
        \A
        (?&PerlOWS)
        (?<type>(?&PerlIdentifier) | (?&PerlCall) )? (?&PerlOWS)
        (?<var>(?:(?&PerlVariable)))
        (?&PerlOWS)
        \Z
        $PPR::GRAMMAR
    }x;

    return +{
        type => $+{type},
        var  => $+{var},
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Variable::Declaration - declare with type constraint

=head1 SYNOPSIS

    use Variable::Declaration;
    use Types::Standard '-all';

    # variable declaration
    let $foo;      # is equivalent to `my $foo`
    static $bar;   # is equivalent to `state $bar`
    const $baz;    # is equivalent to `my $baz;dlock($baz)`

    # with type constraint

    # init case
    let Str $foo = {}; # => Reference {} did not pass type constraint "Str"

    # store case
    let Str $foo = 'foo';
    $foo = {}; # => Reference {} did not pass type constraint "Str"

=head1 DESCRIPTION

Warning: This module is still new and experimental. The API may change in future versions. The code may be buggy.

Variable::Declaration provides new variable declarations, i.e. C<let>, C<static>, and C<const>.

C<let> is equivalent to C<my> with type constraint.
C<static> is equivalent to C<state> with type constraint.
C<const> is equivalent to C<let> with data lock.

=head2 INTROSPECTION

The function Variable::Declaration::info lets you introspect return values like L<Variable::Declaration::Info>:

    use Variable::Declaration;
    use Types::Standard -types;

    let Str $foo = "HELLO";
    my $vinfo = Variable::Declaration::info \$foo;

    $vinfo->declaration; # let
    $vinfo->type; # Str

=head2 LEVEL

You can specify the LEVEL in three stages of checking the specified type:

C<LEVEL 0> does not check type,
C<LEVEL 1> check type only at initializing variables,
C<LEVEL 2> check type at initializing variables and reassignment.
C<LEVEL 2> is default level.

    # CASE: LEVEL 2 (DEFAULT)
    use Variable::Declaration level => 2;

    let Int $s = 'foo'; # => ERROR!
    let Int $s = 123;
    $s = 'bar'; # => ERROR!

    # CASE: LEVEL 1
    use Variable::Declaration level => 1;

    let Int $s = 'foo'; # => ERROR!
    let Int $s = 123;
    $s = 'bar'; # => NO error!

    # CASE: LEVEL 0
    use Variable::Declaration level => 0;

    let Int $s = 'foo'; # => NO error!
    let Int $s = 123;
    $s = 'bar'; # => NO error!

There are three ways of specifying LEVEL.
First, as shown in the example above, pass to the arguments of the module.
Next, set environment variable C<$ENV{Variable::Declaration::LEVEL}>.
Finally, set C<$Variable::Declaration::DEFAULT_LEVEL>.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

