package Test::Simpler;

use warnings;
use strict;
use autodie;
use 5.014;

our $VERSION = '0.000007';

use PadWalker  qw< peek_my peek_our >;
use Data::Dump qw< dump >;
use List::Util qw< max >;

use base 'Test::Builder::Module';

# Export the module's interface...
our @EXPORT      = ( 'ok' );
our @EXPORT_OK   = ();
our %EXPORT_TAGS = ();

sub ok($;$) {
    my $outcome = shift;
    my $desc    = @_ ? "@_" : undef;

    # Grab the upscope variables...
    my %value_for = ( %{peek_our(1)}, %{peek_my(1)} );

    # Cache for source code...
    state %source;

    # Where were we called???
    my ($package, $file, $line) = caller;

    # Grab the source...
    if (!exists $source{$file}) {
        open my $fh, '<', $file;
        $source{$file} = do { local $/; readline $fh };
    }
    my $source = $source{$file};
    my $remove_lines = $line - 1;
    $source =~ s{ \A (?: \N*\n ){$remove_lines} }{}xms;

    # Extract code from source...
    use PPI;
    my $doc = PPI::Document->new(\$source);

    # Extract statement from code...
    my @target;
    STATEMENT:
    for my $statement (@{ $doc->find('PPI::Statement') }) {
        my @token = $statement->children;
        next STATEMENT if $token[0]->content ne 'ok';
        @target = @token[1..$#token];  # don't need the 'ok'
        last STATEMENT;
    }

    # Did we find the statement?
    die "Can't understand arguments to ok()" if !@target;

    # Flatten to a list of relevant tokens...
    SKIPPED:
    while (1) {
        # Remove whitespaces...
        if ($target[0]->isa('PPI::Token::Whitespace')) {
            shift @target;
        }
        # Step into lists...
        elsif ($target[0]->isa('PPI::Structure::List')) {
            @target = $target[0]->children;
        }
        # Step into expressions...
        elsif ($target[0]->isa('PPI::Statement::Expression')) {
            @target = $target[0]->children;
        }
        else {
            last SKIPPED;
        }
    }

    # Find first comma or end-of-statement (i.e. end of first arg)...
    TOKEN:
    for my $n (0..$#target) {
        my $target = $target[$n];

        # The comma is an operator...
        if ($target->isa('PPI::Token::Operator')
        ||  $target->isa('PPI::Token::Structure')) {
                # But is the operator the one we want???
                my $content = $target->content;
                if ($content =~ m{^(?: , | => | ; )$}x) {
                    # IF so, truncate tokens here and escape...
                    splice @target, $n;
                    last TOKEN;
                }
        }
    }

    # Compact and clean up the resulting code...
    my $test_code = _rebuild_code(@target);

    # Split on a comparison operator...
    state $COMPARATOR
        = qr{\A(?:
            eq | ne | lt | le | gt | ge
          | == | != | <  | <= | >  | >=
          | =~ | !~ | ~~
          ) \Z }x;

    my $expected_code = $test_code;
    my ($got_code, $comparator);
    for my $n (0..$#target) {
        my $target = $target[$n]->content;

        # Find a comparison operator to split upon...
        if ($target =~ $COMPARATOR) {
            $got_code      = _rebuild_code(@target[0..$n-1]);
            $comparator    = $target;
            $expected_code = _rebuild_code(@target[$n+1..$#target]);
        }
    }


    $desc //= $test_code;

    # Extract all the variables from the code...
    my @symbols      = _uniq( map { _get_symbols($_) } @target );

    my @symbol_names;
    my @symbol_lookup;

    for my $symbol (@symbols) {
        my $subscript;
        my $symbol_source = $symbol->content;
        my $next_symbol   = $symbol;

        ACCUMULATE_SYMBOL:
        while ($next_symbol = $next_symbol->snext_sibling) {
            # A simple array or hash look-up???
            if ($next_symbol->isa('PPI::Structure::Subscript')) {
                $subscript     .= $next_symbol->content;
                $symbol_source .= $next_symbol->content;
            }

            # A dereferenced look-up or method call???
            elsif ($next_symbol->content eq '->') {
                # What's after the arrow???
                $next_symbol = $next_symbol->snext_sibling;

                # Is it a subscript??? Then deal with it on the next loop...
                if ($next_symbol->isa('PPI::Structure::Subscript')) {
                    redo ACCUMULATE_SYMBOL;
                }

                # Is it a method call??? Then deal with it here...
                elsif ($next_symbol->isa('PPI::Token::Word') || $next_symbol->isa('PPI::Token::Symbol') ) {
                    my $methname = $next_symbol->content;
                    if ($next_symbol->isa('PPI::Token::Symbol') && $value_for{$next_symbol->content}) {
                        $methname = ${ $value_for{$next_symbol->content} }
                    }

                    # Save the arrow and method name...
                    $subscript     .= '->' . $methname;
                    $symbol_source .= '->' . $next_symbol->content;

                    # Look for a trailing argument list...
                    $next_symbol = $next_symbol->snext_sibling;

                    # Ignore this symbol if it's not a list...
                    redo ACCUMULATE_SYMBOL
                        if ! $next_symbol->isa('PPI::Structure::List');

                    # Otherwise, keep the list and continue...
                    $subscript     .= $next_symbol->content;
                    $symbol_source .= $next_symbol->content;
                }
            }
            else {
                last ACCUMULATE_SYMBOL;
            }
        }
        my $symbol_name = $symbol->symbol;
        my $symbol_lookup = $symbol->symbol_type eq '$'
                    ? '${$value_for{q{' . $symbol_name . '}}}'
                    :   '$value_for{q{' . $symbol_name . '}}'
                    ;

        if (length $subscript) {
            $subscript =~ s{\A->}{}xms;
            $symbol_lookup .= "->$subscript";
        }

        push @symbol_names,  $symbol_source;
        push @symbol_lookup, $symbol_lookup;
    }

    my $symlen = max map { length $_ } @symbol_names;

    # Now report the test...
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $builder = Test::Builder->new;

    $builder->no_diag(1);
    $builder->ok($outcome, $desc);
    $builder->no_diag(0);

    # And report the problem (if any)...
    if (!$outcome) {
        state $VAR_FORMAT = q{      %-*s --> %s};
        $builder->diag("  Failed test at $file line $line");
        $builder->diag("      $got_code")      if defined $got_code;
        $builder->diag("        isn't $comparator")  if defined $comparator;
        if (defined $comparator) {
            $builder->diag("      $expected_code");
            $builder->diag("  Because:");
        }
        else {
            $builder->diag("  Expected true value for:  $expected_code");
            $builder->diag("  But was false because:");
        }
        if (@symbol_names) {
            for my $symbol ( @symbol_names ) {
                my $symbol_lookup = shift @symbol_lookup;
                $builder->diag(
                    sprintf $VAR_FORMAT, $symlen, $symbol,
                            _tidy_values(eval "package $package; no warnings; $symbol_lookup")
                );
            }
            $builder->diag(q{});
        }
        if (defined $got_code) {
            my $got_code_value      = eval "package $package; no warnings; $got_code";
            my $expected_code_value = eval "package $package; no warnings; $expected_code";
            my $symlen = max map { defined $_ ? length $_ : 0 } $got_code, $expected_code;
            if (defined( $got_code_value // $expected_code_value ) && !@symbol_names) {
                $builder->diag("   because:");
            }
            if (defined $got_code_value && $got_code_value ne $got_code) {
                $builder->diag( sprintf $VAR_FORMAT, $symlen, $got_code, $got_code_value);
            }
            if (defined $expected_code_value && $expected_code_value ne $expected_code) {
                $builder->diag( sprintf $VAR_FORMAT, $symlen, $expected_code, $expected_code_value);
            }
        }
    }
}

sub _rebuild_code {
    my $code = join q{}, map { my $content = $_;
                               $content =~ /^\n+/  ? q{}
                             : $content =~ /^\s*$/ ? q{ }
                             :                       $_
                             } @_;
    return $code =~ s{\A\s+|\s+\Z}{}gr;
}

sub _tidy_values {
    my ($ref) = @_;

    my $type = ref($ref);

    return  $type eq 'ARRAY'  ?  dump @{$ref}
         :  $type eq 'HASH'   ?  dump($ref) =~ s/^{/(/r =~ s/}$/)/r
         :  $type eq 'SCALAR' ?  dump ${$ref}
         :                       dump $ref;
}

sub _get_symbols {
    my $element = shift;
    return $element if $element->isa('PPI::Token::Symbol');
    return map { _get_symbols($_) } eval{ $element->children };
}

sub _uniq {
    my %seen;
    return grep { $seen{$_}++ ? () : $_ } @_;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Test::Simpler - Simpler than Test::Simple; more powerful than Test::More


=head1 VERSION

This document describes Test::Simpler version 0.000007


=head1 SYNOPSIS

    use Test::Simpler tests => 6;

    # and later...

    ok  $result -  $expected[0];
    ok  $result eq $expected[0];
    ok  $result == $expected->[0]->{a}[0];
    ok  $result ~~ $expected[0];
    ok  $result !~ $expected[0];
    ok  $result >  twice($expected{'half'});


=head1 DESCRIPTION

This module acts as a drop-in replacement for Test::Simple. It provides
exactly the same interface (i.e. a single subroutine named C<ok()>), but
produces TAP reports whose diagnostics are considerably more detailed and
informative than those of either Test::Simple or Test::More.

For example, using Test::Simple the set of C<ok()> tests above
would produce:

    1..6
    not ok 1
    #   Failed test at demo/ts_ok.pl line 14.
    ok 2
    not ok 3
    #   Failed test at demo/ts_ok.pl line 16.
    ok 4
    not ok 5
    #   Failed test at demo/ts_ok.pl line 18.
    not ok 6
    #   Failed test at demo/ts_ok.pl line 19.
    # Looks like you failed 4 tests of 6.

giving no indication of what caused each test to fail.

Whereas, using Test::Simpler with the same size statements, you
would get:

    1..6
    not ok 1 - $result - $expected[0]
    #   Failed test at demo/ts_ok-er.pl line 14
    #   Expected true value for:  $result - $expected[0]
    #   But was false because:
    #       $result      --> 1
    #       $expected[0] --> 1
    #
    ok 2 - $result eq $expected[0]
    not ok 3 - $result == $expected->[0]->{a}[0]
    #   Failed test at demo/ts_ok-er.pl line 16
    #       $result
    #         isn't ==
    #       $expected->[0]->{a}[0]
    #   Because:
    #       $result                --> 1
    #       $expected->[0]->{a}[0] --> undef
    #
    ok 4 - $result ~~ $expected[0]
    not ok 5 - $result !~ $expected[0]
    #   Failed test at demo/ts_ok-er.pl line 18
    #       $result
    #         isn't !~
    #       $expected[0]
    #   Because:
    #       $result      --> 1
    #       $expected[0] --> 1
    #
    not ok 6 - $result > double($hash{'b b'})
    #   Failed test at demo/ts_ok-er.pl line 19
    #       $result
    #         isn't >
    #       twice($hash{'half'})
    #   Because:
    #       $result       --> 1
    #       $hash{'half'} --> 2
    #
    # Looks like you failed 4 tests of 6.


=head1 INTERFACE

The module's API is identical to Test::Simple. See that module's
documentation for details.


=head1 DIAGNOSTICS

=over

=item C<< Can't understand arguments to ok() >>

The module was unable to parse the arguments you passed to C<ok()>. Or,
more precisely, PPI was not able to. That must be some freaky arcane
Perl expression you used there! Maybe try a simpler test condition?

=back


=head1 CONFIGURATION AND ENVIRONMENT

Test::Simpler requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires:

=over

=item PPI

...to parse the arguments of C<ok()>

=item Test::Builder::Module

...to produce TAP reports and to emulate the Test::Simple interface.

=item PadWalker

...to track variable values

=item Data::Dump

...to print variable values

=back

(Which means it's only simpler on the outside ;-)


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-simpler@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
