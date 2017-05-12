package Types;
use Carp;
use Data::Dumper;
use Exporter;
use base qw/Exporter/;

our $VERSION = '0.1';

our @EXPORT = qw(newtype uniontype synonymtype separatetype match
                 typeclass instance asserttype assertlisttype typeinfo);

$Carp::CarpLevel = 1;

{ package Types::Type        }
{ package Types::UnionType   }
{ package Types::SynonymType }
{ package Types::TypeClass   }

sub typeinfo (*) { \%{shift().'::info'} }

sub newtype (*;&)
{ my $t = shift
; my $p = shift
; croak 'Redefinition of a newtype '.$t if exists &{$t}
; *{$t} = $p
? do{ ${$t.'::predicate'} = $p
    ; sub{ ${$t.'::predicate'}->(@_)
         ? bless [@_], $t
         : confess "Failed constructing $t with:\n"  . Dumper(@_) }}
: sub{ bless [@_], $t }
; @{$t.'::ISA'} = 'Types::Type'
; %{$t.'::info'} = ( what => 'Types::Type'
                   , predicate => $p
                   )
}

sub uniontype (*@)
{ my $u = shift
; { eval "package $u" }
; %{$u.'::info'} = ( what => 'Types::UnionType' )
; @{$s.'::ISA'} = 'Types::UnionType'
; push @{$_.'::ISA'}, $u for @_
}

sub synonymtype (*$)
{ my( $s, $t ) = @_
; { eval "package $s" }
; @{$s.'::ISA'} = 'Types::SynonymType'
; %{$s.'::info'} = ( what => 'Types::SynonymType' )
; push @{$t.'::ISA'}, $s
}

sub typeclass (*;%)
{ my( $n, %ms ) = @_
; { eval "package $n" }
; @{$n.'::ISA'} = 'Types::TypeClass'
; %{$n.'::info'} = ( what => 'Types::TypeClass'
                   , methods => \%ms
                   )
}

sub instance (**;%)
{ my( $class, $type, %ms ) = @_
; my $classinfo = typeinfo $class
; croak "Class $class does not exist"
    unless $classinfo->{what} eq 'Types::TypeClass'
; for my $method (keys %{$classinfo->{methods}})
  { *{$type.'::'.$method} = $classinfo->{methods}->{$method} }
; for my $method (keys %ms)
  { croak "Method '$method' does not exist in the class $class"
        unless exists $classinfo->{methods}->{$method}
  ; *{$type.'::'.$method} = $ms{$method} }
; for my $method (keys %{$classinfo->{methods}})
  { croak "Method '$method' of class $class instance "
         ."of type $type is not defined"
        unless defined &{$type.'::'.$method} }
; push @{${$class.'::info'}{instances}}, $type
}

# Assert that a value is of a specified type
sub asserttype (*$)
{ my( $expect, $got ) = ( shift, shift )
; confess "Expecting $expect, got\n". Dumper $got
    unless ref($got) && $got->isa($expect)
}

sub assertlisttype (*$)
{ my( $t, $l ) = @_;
; map { asserttype $t, $_ } @$l
}

sub separatetype (*$) { my( $t, $l ) = @_
; my @a = ()
; my @b = ()
; for my $e (@$l) { $e->isa($t)
                  ? push @a, $e
                  : push @b, $e }
; (\@a,\@b)
}

sub match ($@)
{ my $v = shift
; asserttype Types::Type, $v
; for( my $i=0; $i<@_; $i=$i+2 ) { my( $p, $f ) = ( $_[$i], $_[$i+1] )
                                 ; 'CODE' eq ref $p
                                 ? $p->(@$v)
                                 ? return $f->(@$v)
                                 : undef
                                 : '_' eq $p
                                 ? return $f->(@$v)
                                 : do{ ref($v) eq $p
                                     ? return $f->(@$v)
                                     : $v->isa($p)
                                     ? return $f->($v)
                                     : undef }}
; confess "Non-exhaustive patterns for value:\n" . Dumper $v
}

1;

__END__
=head1 NAME

Types - The great new Types!

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

This module provides types in the functional programming style.
More documentation will follow.

=head1 EXPORT

newtype uniontype synonymtype separatetype match
typeclass instance asserttype assertlisttype typeinfo

=head1 AUTHOR

Eugene Grigoriev, C<< <eugene.grigoriev at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-types at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Types>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Types


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Types>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Types>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Types>

=item * Search CPAN

L<http://search.cpan.org/dist/Types>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Eugene Grigoriev, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

