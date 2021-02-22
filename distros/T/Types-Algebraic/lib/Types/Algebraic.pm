package Types::Algebraic;

use strict;
use 5.022;
use warnings;
our $VERSION = '0.07';

use Carp qw(croak confess);
use Data::Dumper;
use List::Util qw(all);
use List::MoreUtils qw(pairwise zip_unflatten);
use Keyword::Declare;
use Keyword::Simple;
use Moops;
use PPR;
use Scalar::Util qw(blessed);

our $_RETURN_SENTINEL = \23;

our %_KNOWN_CONSTRUCTORS;

my ($expected, $fail_loc) = ('match statement', 0);
our $_TA_REGEX_LIB = qr{
    (?(DEFINE)
        (?<ADTPattern>
            \( (?&PerlOWS)
               (?{ $expected = "the name of a constructor", $fail_loc = pos() })
               (?&PerlIdentifier)                        # constructor
               (?{ $expected = "zero or more constructor arguments", $fail_loc = pos() })
               (?:(?&PerlNWS) (?&ADTPatternSegment))*    # 0 or more arguments
               (?&PerlOWS)
            \)
        )

        (?<ADTPatternSegment>
            (?:
                \$ (?&PerlIdentifier) |   # variable
                   (?&PerlIdentifier) |   # constuctor without arguments
                   (?&ADTPattern)         # constructor with arguments - requires parentheses
            )
        )
    )

    $PPR::GRAMMAR
}xms;

class ADT {
    has tag => (is => "ro", isa => Str);
    has values => (is => "ro", isa => ArrayRef);

    sub _equality {
        my ($type, $x, $y) = @_;

        return 0 unless ref($x) && (ref($x) // '') eq (ref($y) // '');
        return 0 unless $x->tag eq $y->tag;
        return List::Util::all { $_ } List::MoreUtils::pairwise { $type eq '==' ? $a == $b : $a eq $b } @{$x->values}, @{$y->values};
    }

    sub _equality_num { return _equality('==', @_); }
    sub _equality_str { return _equality('eq', @_); }

    sub _stringify {
        my $v = shift;
        return $v->tag . "(" . join(", ", map { "$_" } @{ $v->values }) . ")";
    }

    use overload
        '==' => sub { _equality('==', @_) },
        '!=' => sub { ! _equality('==', @_) },
        'eq' => sub { _equality('eq', @_) },
        'ne' => sub { ! _equality('eq', @_) },
        '""' => \&_stringify;
}

sub _apply_pattern {
    my ($value, $pattern) = @_;

    if ($pattern->{type} eq 'variable') {
        return (1, [$value]);
    }

    return 0 unless $value && blessed($value) && $value->isa('Types::Algebraic::ADT');

    return 0 unless $pattern->{constructor} eq $value->tag;

    my @variables;
    for my $pair (List::MoreUtils::zip_unflatten(@{$value->values}, @{$pattern->{arguments}})) {
        my ($rv, $new_vars) = _apply_pattern(@$pair);
        return 0 unless $rv;
        push(@variables, @$new_vars);
    }

    return (1, \@variables);
}

keytype ADTConstructor is / (?<tag> (?&PerlIdentifier)) (?<fields> (?: (?&PerlNWS) : (?&PerlIdentifier) )* ) /x;

sub _verify_constructor {
    my ($constructor, $arity) = @_;
    my $info = $_KNOWN_CONSTRUCTORS{$constructor};

    confess("Unknown constructor '$constructor'. Pattern matching requires types created through Types::Algebraic.")
        unless $info;

    confess("Constructor '$constructor' expects $info->{arg_count} arguments - but is pattern matched with $arity.")
        unless $info->{arg_count} == $arity;

}

sub _parse_pattern {
    my ($pattern) = @_;
    $pattern =~ m{
        \A
        \(
           (?&PerlOWS)
           (?<tag>(?&PerlIdentifier))
           (?<identifiers> (?:(?&PerlNWS) (?&ADTPatternSegment))* )
           (?&PerlOWS)
        \)
        $Types::Algebraic::_TA_REGEX_LIB
    }xms;
    my ($tag, $idents) = @+{qw(tag identifiers)};

    my @segments;
    my @variables;
    while ($idents =~ m/(?&PerlNWS) (?<segment>(?&ADTPatternSegment)) $Types::Algebraic::_TA_REGEX_LIB/xmsg) {
        my $segment = $+{segment};

        if ($segment =~ m/^\$/) {
            push(@segments, { type => 'variable', value => $segment });
            push(@variables, $segment);
        } elsif ($segment =~ m/^\(/) {
            my ($parsed, $new_vars) = _parse_pattern($segment);
            push(@segments, $parsed);
            push(@variables, @$new_vars);
        } else {
            _verify_constructor($segment, 0);

            push(@segments, { type => 'pattern', constructor => $segment, arguments => [] });
        }
    }

    _verify_constructor($tag, scalar @segments);

    return ({ type => 'pattern', constructor => $tag, arguments => \@segments }, \@variables);
}

sub import {
    Moops->import;

    Keyword::Simple::define 'match', sub {
        my ($doc_src) = @_;

        ($expected, $fail_loc) = ('match statement', 0);
        my $curly_open = '{';

        $$doc_src =~ s{
            \A
            (?&PerlNWS)
            (?{ $expected = "parenthesized expression", $fail_loc = pos() })
            (?<matched_expression> (?&PerlParenthesesList) )
            (?&PerlNWS)
            (?{ $expected = "a '$curly_open'", $fail_loc = pos() })
            \{ (?&PerlOWS)

            $Types::Algebraic::_TA_REGEX_LIB
        }{}xms or croak("Invalid match statement.\nExpected: $expected\nFound: ", substr($$doc_src, $fail_loc) =~ /(\S+)/,"\n");

        my $expr = $+{matched_expression};

        my $res = "{\n";
        my $match_body = $expr . "->match(\n";

        while ($$doc_src =~ m/^(?:with|default)/) {
            $$doc_src =~ s{
                \A
                (?{ $expected = "a with or default statement", $fail_loc = pos() })
                (?:
                    with (?&PerlNWS)
                    (?{ $expected = "a match pattern", $fail_loc = pos() })
                        (?<with_pattern> (?&ADTPattern))
                    |
                    (?<default> default)
                ) (?&PerlOWS)
                (?{ $expected = "a code block", $fail_loc = pos() })
                (?<block> (?&PerlBlock) ) (?&PerlOWS)

                $Types::Algebraic::_TA_REGEX_LIB
            }{}xms or croak("Invalid match statement.\nExpected: $expected\nFound: ", substr($$doc_src, $fail_loc) =~ /(\S+)/,"\n");

            my ($default, $pattern, $block) = @+{qw(default with_pattern block)};

            if ($default) {
                $match_body .= "[ sub { $block; return \$Types::Algebraic::_RETURN_SENTINEL; } ],\n";
            } else {
                my ($parsed, $variables) = _parse_pattern($pattern);

                local $Data::Dumper::Indent = 0;
                local $Data::Dumper::Terse = 1;

                my $flattened_pattern = Data::Dumper::Dumper($parsed);
                my $args = join(',', @$variables);

                $match_body .= "[$flattened_pattern, sub { my ($args) = \@_; $block; return \$Types::Algebraic::_RETURN_SENTINEL; } ],\n";
            }
        }
        $match_body .= ")";

        my $curly_close = '}';
        $$doc_src =~ s{
            \A
            (?{ $expected = "a '$curly_close'", $fail_loc = pos() })
            \}

            $Types::Algebraic::_TA_REGEX_LIB
        }{}xms or croak("Invalid match statement.\nExpected: $expected\nFound: ", substr($$doc_src, $fail_loc) =~ /(\S+)/,"\n");

        $res .= <<"EOF";
    if (wantarray) {
        my \@types_algebraic_match_result = $match_body;
        if (\@types_algebraic_match_result != 1 || \$types_algebraic_match_result[0] != \$Types::Algebraic::_RETURN_SENTINEL) { return \@types_algebraic_match_result };
    } else {
        my \$types_algebraic_match_result = $match_body;
        if (\$types_algebraic_match_result && \$types_algebraic_match_result != \$Types::Algebraic::_RETURN_SENTINEL) { return \$types_algebraic_match_result; }
    }
EOF
        $res .= "}\n";
        #say STDERR "\n\n\n$res\n\n-----\n";
        $$doc_src = $res . $$doc_src;
    };

    keyword data (Ident $name, '=', ADTConstructor* @constructors :sep(/\|/)) {
        my %ARGS;
        for my $constructor (@constructors) {
            my $tag = $constructor->{tag};

            my @args;
            while ($constructor->{fields} =~ m/ (?&PerlNWS) : (?<ident> (?&PerlIdentifier) ) $PPR::GRAMMAR/xg ) {
                push(@args, $+{ident});
            }

            $ARGS{$tag} = scalar @args;

            $_KNOWN_CONSTRUCTORS{$tag} = {
                typename  => $name,
                arg_count => scalar @args,
            };
        }

        my $args_str = join(", ", map { "$_ => $ARGS{$_}" } keys %ARGS);

        my $res = <<CODE;
class $name extends Types::Algebraic::ADT {
    my %ARGS = ( $args_str );
CODE

        $res .= <<'CODE';
    sub BUILD {
        my ($self, $args) = @_;
        my $tag = $args->{tag} || confess("tag is required - please use public interface");
        my $values = $args->{values} || confess("values is required - please use public interface");

        confess("Unknown constructor $tag") unless exists $ARGS{$tag};
        confess("$tag expects $ARGS{$tag} arguments - given ".scalar @$values) unless @$values == $ARGS{$tag};
    }

    sub match {
        my $self = shift;
        for my $case (@_) {
            if (@$case == 2) {
                my ($pattern, $f) = @$case;

                my ($matches, $values) = Types::Algebraic::_apply_pattern($self, $pattern);
                return $f->(@$values) if $matches;
            }
            # default
            if (@$case == 1) {
                return $case->[0]->(@{ $self->values });
            }
        }
    }
}
CODE

        for my $key (keys %ARGS) {
            $res .= <<CODE;
sub $key { return $name->new( tag => '$key', values => [\@_] ); }
CODE

        }

        #say STDERR $res;

        return $res;
    }

}

sub unimport {
    unkeyword data;
    Keyword::Simple::undefine 'match';
}

1;
__END__

=encoding utf-8

=head1 NAME

Types::Algebraic - Algebraic data types in perl

=head1 SYNOPSIS

  use Types::Algebraic;

  data Maybe = Nothing | Just :v;

  my $sum = 0;
  my @vs = ( Nothing, Just(5), Just(7), Nothing, Just(6) );
  for my $v (@vs) {
      match ($v) {
         with (Nothing) { }
         with (Just $v) { $sum += $v; }
      }
  }
  say $sum;

=head1 DESCRIPTION

Types::Algebraic is an implementation of L<algebraic data types|https://en.wikipedia.org/wiki/Algebraic_data_type> in perl.

These kinds of data types are often seen in functional languages, and allow you to create and consume structured data containers very succinctly.

The module provides two keywords: L</"data"> for creating a new data type, and L</"match"> to provide pattern matching on the type.

=head1 USAGE

=head2 Creating a new type with C<data>

The C<data> keyword is used for creating a new type.

The code

  data Maybe = Nothing | Just :v;

creates a new type, of name C<Maybe>, which has 2 I<data constructors>, C<Nothing> (taking no parameters), and C<Just> (taking 1 parameter).

You may insantiate values of this type by using one of the constructors with the appropriate number of arguments.

  my $a = Nothing;
  my $b = Just 5;

=head2 Unpacking values with C<match>

In order to access the data stored within one of these values, you can use the C<match> keyword.

  my $value = Just 7;
  match ($value) {
      with (Nothing) { say "There was nothing in there. :("; }
      with (Just $v) { say "I got the value $v!"; }
  }

The cases are matched from the top down, and only the first matching case is run.

You can also create a default fallback case, which will always run if reached.

  data Color = Red | Blue | Green | White | Black;
  match ($color) {
      with (Red) { say "Yay, you picked my favorite color!"; }
      default    { say "Bah. You clearly have no taste."; }
  }

=head2 Nested patterns

Note, patterns can be nested, allowing for more complex unpacking:

  data PairingHeap = Empty | Heap :head :subheaps;
  data Pair = Pair :left :right;

  # Merge two pairing heaps (https://en.wikipedia.org/wiki/Pairing_heap)
  sub merge {
      my ($h1, $h2) = @_;

      match (Pair($h1, $h2)) {
          with (Pair Empty $h) { return $h; }
          with (Pair $h Empty) { return $h; }
          with (Pair (Heap $e1 $s1) (Heap $e2 $s2)) {
              return $e1 < $e2 ? Heap($e1, [$h2, @$s1])
                               : Heap($e2, [$h1, @$s2]);
          }
      }
  }

=head1 LIMITATIONS

=over 4

=item Currently, match statements can't be nested.

=back

=head1 BUGS

Please report bugs directly on L<the project's GitHub page|https://github.com/Eckankar/Types-Algebraic>.

=head1 AUTHOR

Sebastian Paaske Tørholm E<lt>sebbe@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2020- Sebastian Paaske Tørholm

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
