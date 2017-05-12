package Test::Requires::Scanner;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Compiler::Lexer;

use Test::Requires::Scanner::Constants;
use Test::Requires::Scanner::Walker;
use Test::Requires::Scanner::Result;

sub scan_file {
    my ($class, $file) = @_;

    my $content = do {
        local $/;
        open my $fh, '<', $file or die $!;
        <$fh>;
    };

   $class->scan_string($content);
}

sub scan_files {
    my ($class, @files) = @_;

    my $result = Test::Requires::Scanner::Result->new;

    for my $file (@files) {
        my $ret = Test::Requires::Scanner->scan_file($file);
        $result->save_module($_, $ret->{$_}) for keys %$ret;
    }

    $result->modules;
}

sub scan_string {
    my ($class, $string) = @_;

    my $lexer = Compiler::Lexer->new;
    my $tokens = $lexer->tokenize($string);

    $class->scan_tokens($tokens);
}

sub scan_tokens {
    my ($class, $tokens) = @_;

    my $walker = Test::Requires::Scanner::Walker->new;
    my $result = Test::Requires::Scanner::Result->new;
    for my $token (@$tokens) {
        my $token_type = $token->{type};

        # For use statement
        if ($token_type == USE_DECL) {
            $walker->is_in_usedecl(1);
            $walker->is_prev_module_name(1);
            next;
        }
        if ($walker->is_in_usedecl) {
            # e.g.
            #   use Foo;
            if (
                $token_type == USED_NAME ||  # e.g. use Foo
                $token_type == SEMI_COLON    # End of declare of use statement
            ) {
                $walker->reset;
                next;
            }

            # e.g.
            #   use Foo::Bar;
            if ( ($token_type == NAMESPACE || $token_type == NAMESPACE_RESOLVER) && $walker->is_prev_module_name) {
                $walker->{module_name} .= $token->{data};
                if ($walker->module_name =~ /^Test(?:\:\:(?:Requires)?)?$/) {
                    $walker->is_prev_module_name(1);
                    $walker->is_in_test_requires($walker->module_name eq 'Test::Requires');
                }
                else {
                    $walker->reset;
                }
                next;
            }

            if (!$walker->module_name && !$walker->does_garbage_exist && _looks_like_version($token_type)) {
                # For perl version
                # e.g.
                #   use 5.012;
                $walker->reset;
                next;
            }

            # Section for Test::Requires
            if ($walker->is_in_test_requires) {
                $walker->is_prev_module_name(0);

                # For qw() notation
                # e.g.
                #   use Test::Requires qw/Foo Bar/;
                if ($token_type == REG_LIST) {
                    $walker->is_in_reglist(1);
                }
                elsif ($walker->is_in_reglist) {
                    # skip regdelim
                    if ($token_type == REG_EXP) {
                        for my $_module_name (split /\s+/, $token->{data}) {
                            $result->save_module($_module_name);
                        }
                        $walker->is_in_reglist(0);
                    }
                }

                # For simply list
                # e.g.
                #   use Test::Requires ('Foo', 'Bar');
                elsif ($token_type == LEFT_PAREN) {
                    $walker->is_in_list(1);
                }
                elsif ($token_type == RIGHT_PAREN) {
                    $walker->is_in_list(0);
                }
                elsif ($walker->is_in_list) {
                    if ($token_type == STRING || $token_type == RAW_STRING) {
                        $result->save_module($token->{data});
                    }
                }

                # For braced list
                # e.g.
                #   use Test::Requires {'Foo' => 1, 'Bar' => 2};
                elsif ($token_type == LEFT_BRACE ) {
                    $walker->is_in_hash(1);
                    $walker->hash_count(0);
                }
                elsif ($token_type == RIGHT_BRACE ) {
                    $walker->is_in_hash(0);
                }
                elsif ($walker->is_in_hash) {
                    if ( _is_string($token_type) || $token_type == KEY || _looks_like_version($token_type) ) {
                        $walker->{hash_count}++;

                        if ($walker->hash_count % 2) {
                            $walker->stashed_module($token->{data});
                        }
                        else {
                            # store version
                            $result->save_module($walker->stashed_module, $token->{data});
                            $walker->stashed_module('');
                        }
                    }
                }

                # For string
                # e.g.
                #   use Test::Requires "Foo"
                elsif (_is_string($token_type)) {
                    $result->save_module($token->{data});
                }
                next;
            }

            if ($token_type != WHITESPACE) {
                $walker->does_garbage_exist(1);
                $walker->is_prev_module_name(0);
            }
            next;
        }
    }

    $result->modules;
}


sub _is_string {
    my $token_type = shift;
    $token_type == STRING || $token_type == RAW_STRING;
}

sub _looks_like_version {
    my $token_type = shift;
    $token_type == DOUBLE || $token_type == INT || $token_type == VERSION_STRING;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::Requires::Scanner - retrieve modules specified by Test::Requires

=head1 SYNOPSIS

    use Test::Requires::Scanner;
    my $modules2version_hashref = Test::Requires::Scanner->scan_files('t/hoge.t', 't/fuga.t');

=head1 DESCRIPTION

App::TestRequires::Scanner is to retrieve modules specified by L<Test::Requires> in
test files. It is useful for CPAN module maintainer.

=head2 METHODS

=over

=item C<< $hashref = Test::Requires::Scanner->scan_string($str) >>

=item C<< $hashref = Test::Requires::Scanner->scan_file($file) >>

=item C<< $hashref = Test::Requires::Scanner->scan_files(@files) >>

A key of C<$hashref> is module name and a value is version.

=back

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

