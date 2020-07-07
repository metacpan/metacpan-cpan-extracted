package Types::Algebraic;

use strict;
use 5.022;
use warnings;
our $VERSION = '0.03';

use Keyword::Declare;
use Moops;
use PPR;

our $_RETURN_SENTINEL = \23;

class ADT {
    has tag => (is => "ro", isa => Str);
    has values => (is => "ro", isa => ArrayRef);
}

keytype ADTMatch is /
    (?:
        with (?&PerlNWS) \( (?&PerlOWS) (?<tag>(?&PerlIdentifier)) (?<identifiers> (?: (?&PerlNWS) \$ (?&PerlIdentifier) )* ) (?&PerlOWS) \) |
        default
    ) (?&PerlOWS) (?<block> (?&PerlBlock) ) (?&PerlOWS)

/x;

keytype ADTConstructor is / (?<tag> (?&PerlIdentifier)) (?<fields> (?: (?&PerlNWS) : (?&PerlIdentifier) )* ) /x;

sub import {
    Moops->import;

    keyword match (ParenthesesList $v, '{', ADTMatch* @body, '}') {
        my $res = "{\n";
        $res .= 'my @types_algebraic_match_result = '. $v . "->match(\n";
        for my $case (@body) {
            my $tag = $case->{tag};
            my $idents = $case->{identifiers};

            my @idents;
            while ($idents =~ m/ (?&PerlNWS) (?<ident> \$ (?&PerlIdentifier) $PPR::GRAMMAR )/xg ) {
                push(@idents, $+{ident});
            }

            my $count = scalar @idents;
            my $args = join(", ", @idents);
            my $block = $case->{block};

            if ($tag) {
                $res .= "[ '$tag', $count, sub { my ($args) = \@_; $block; return \$Types::Algebraic::_RETURN_SENTINEL; } ],\n";
            } else {
                $res .= "[ sub { $block; return \$Types::Algebraic::_RETURN_SENTINEL; } ],\n";
            }
        }
        $res .= ");\n";
        $res .= 'if (@types_algebraic_match_result != 1 || $types_algebraic_match_result[0] != $Types::Algebraic::_RETURN_SENTINEL) { return @types_algebraic_match_result };' . "\n";
        $res .= "}\n";
        return $res;
    }

    keyword data (Ident $name, '=', ADTConstructor* @constructors :sep(/\|/)) {
        my %ARGS;
        for my $constructor (@constructors) {
            my $tag = $constructor->{tag};

            my @args;
            while ($constructor->{fields} =~ m/ (?&PerlNWS) : (?<ident> (?&PerlIdentifier) ) $PPR::GRAMMAR/xg ) {
                push(@args, $+{ident});
            }

            $ARGS{$tag} = scalar @args;
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
            if (@$case == 3) {
                my ($tag, $argc, $f) = @$case;
                confess("$tag requires $ARGS{$tag} arguments - pattern uses $argc") unless $ARGS{$tag} == $argc;
                if ($tag eq $self->tag) {
                    return $f->(@{ $self->values });
                }
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

        return $res;
    }

}

sub unimport {
    unkeyword data;
    unkeyword match;
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
