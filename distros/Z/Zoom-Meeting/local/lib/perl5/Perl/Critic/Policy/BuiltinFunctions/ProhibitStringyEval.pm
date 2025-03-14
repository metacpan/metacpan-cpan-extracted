package Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval;

use 5.010001;
use strict;
use warnings;

use Readonly;

use PPI::Document;

use Perl::Critic::Utils qw{ :booleans :severities :classification :ppi $SCOLON };
use parent 'Perl::Critic::Policy';

our $VERSION = '1.150';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Expression form of "eval"};
Readonly::Scalar my $EXPL => [ 161 ];

#-----------------------------------------------------------------------------

# The maximum number of statements that may appear in an import-only eval
# string:
Readonly::Scalar my $MAX_STATEMENTS => 3;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'allow_includes',
            description    => q<Allow eval of "use" and "require" strings.>,
            default_string => '0',
            behavior       => 'boolean',
        },
    );
}
sub default_severity     { return $SEVERITY_HIGHEST   }
sub default_themes       { return qw( core pbp bugs certrule ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->content() ne 'eval';
    return if not is_function_call($elem);

    my $argument = first_arg($elem);
    return if not $argument;
    return if $argument->isa('PPI::Structure::Block');
    return if
        $self->{_allow_includes} and _string_eval_is_an_include($argument);

    return $self->violation( $DESC, $EXPL, $elem );
}

sub _string_eval_is_an_include {
    my ($eval_argument) = @_;

    return if not $eval_argument->isa('PPI::Token::Quote');

    my $string = $eval_argument->string();
    my $document;

    eval { $document = PPI::Document->new(\$string); 1 }
        or return;

    my @statements = $document->schildren;

    return if @statements > $MAX_STATEMENTS;

    my $structure = join q{,}, map { $_->class } @statements;

    my $package_class   = qr{PPI::Statement::Package}xms;
    my $include_class   = qr{PPI::Statement::Include}xms;
    my $statement_class = qr{PPI::Statement}xms;

    return if $structure !~ m{
        ^
        (?:$package_class,)?    # Optional "package"
        $include_class
        (?:,$statement_class)?  # Optional follow-on number
        $
    }xms;

    my $is_q =     $eval_argument->isa('PPI::Token::Quote::Single')
               or  $eval_argument->isa('PPI::Token::Quote::Literal');

    for my $statement (@statements) {
        if ( $statement->isa('PPI::Statement::Package') ) {
            _string_eval_accept_package($statement) or return;
        } elsif ( $statement->isa('PPI::Statement::Include') ) {
            _string_eval_accept_include( $statement, $is_q ) or return;
        } else {
            _string_eval_accept_follow_on($statement) or return;
        }
    }

    return $TRUE;
}

sub _string_eval_accept_package {
    my ($package) = @_;

    return if not defined $package; # RT 60179
    return if not $package->isa('PPI::Statement::Package');
    return if not $package->file_scoped;

    return $TRUE;
}

sub _string_eval_accept_include {
    my ( $include, $is_single_quoted ) = @_;

    return if not defined $include; # RT 60179
    return if not $include->isa('PPI::Statement::Include');
    return if $include->type() eq 'no';

    if ($is_single_quoted) {
        # Don't allow funky inclusion of arbitrary code (note we do allow
        # interpolated values in interpolating strings because they can't
        # entirely screw with the syntax).
        return if $include->find('PPI::Token::Symbol');
    }

    return $TRUE;
}

sub _string_eval_accept_follow_on {
    my ($follow_on) = @_;

    return if not $follow_on->isa('PPI::Statement');

    my @follow_on_components = $follow_on->schildren();

    return if @follow_on_components > 2;
    return if not $follow_on_components[0]->isa('PPI::Token::Number');
    return $TRUE if @follow_on_components == 1;

    return $follow_on_components[1]->content() eq $SCOLON;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords SIGNES

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval - Write C<eval { my $foo; bar($foo) }> instead of C<eval "my $foo; bar($foo);">.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

The string form of C<eval> is recompiled every time it is executed,
whereas the block form is only compiled once.  Also, the string form
doesn't give compile-time warnings.

    eval "print $foo";        # not ok
    eval {print $foo};        # ok


=head1 CONFIGURATION

There is an C<allow_includes> boolean option for this Policy.  If set, then
strings that look like they only include an optional "package" statement
followed by a single "use" or "require" statement (with the possible following
statement that consists of a single number) are allowed.  With this option
set, the following are flagged as indicated:

    eval 'use Foo';                           # ok
    eval 'require Foo';                       # ok
    eval "use $thingy;";                      # ok
    eval "require $thingy;";                  # ok
    eval 'package Pkg; use Foo';              # ok
    eval 'package Pkg; require Foo';          # ok
    eval "package $pkg; use $thingy;";        # ok
    eval "package $pkg; require $thingy;";    # ok
    eval "use $thingy; 1;";                   # ok
    eval "require $thingy; 1;";               # ok
    eval "package $pkg; use $thingy; 1;";     # ok
    eval "package $pkg; require $thingy; 1;"; # ok

    eval 'use Foo; blah;';                    # still not ok
    eval 'require Foo; 2; 1;';                # still not ok
    eval 'use $thingy;';                      # still not ok
    eval 'no Foo';                            # still not ok

If you don't understand why the number is allowed, see
L<Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval|Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval>.

This option inspired by Ricardo SIGNES'
L<Perl::Critic::Policy::Lax::ProhibitStringyEval::ExceptForRequire|Perl::Critic::Policy::Lax::ProhibitStringyEval::ExceptForRequire>.


=head1 SEE ALSO

L<Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep|Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep>

L<Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap|Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
