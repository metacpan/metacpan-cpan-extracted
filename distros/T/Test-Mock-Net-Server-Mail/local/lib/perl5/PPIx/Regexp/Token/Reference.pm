=head1 NAME

PPIx::Regexp::Token::Reference - Represent a reference to a capture

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{\1}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Reference> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Reference> is the parent of
L<PPIx::Regexp::Token::Backreference|PPIx::Regexp::Token::Backreference>,
L<PPIx::Regexp::Token::Condition|PPIx::Regexp::Token::Condition> and
L<PPIx::Regexp::Token::Recursion|PPIx::Regexp::Token::Recursion>.

=head1 DESCRIPTION

This abstract class represents a reference to a capture buffer, either
numbered or named. It should never be instantiated, but it provides a
number of methods to its subclasses.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Token::Reference;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use Carp qw{ confess };
use List::Util qw{ first };
use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

sub __new {
    my ( $class, $content, %arg ) = @_;

    if ( defined $arg{capture} ) {
    } elsif ( defined $arg{tokenizer} ) {
	$arg{capture} = first { defined $_ } $arg{tokenizer}->capture();
    }

    unless ( defined $arg{capture} ) {
	foreach ( $class->__PPIX_TOKEN__recognize() ) {
	    my ( $re, $a ) = @{ $_ };
	    $content =~ $re or next;
	    @arg{ keys %{ $a } } = @{ $a }{ keys %{ $a } };
	    foreach my $inx ( 1 .. $#- ) {
		defined $-[$inx] or next;
		$arg{capture} = substr $content, $-[$inx], $+[$inx] - $-[$inx];
		last;
	    }
	    last;
	}
    }

    defined $arg{capture}
	or confess q{Programming error - reference '},
	    $content, q{' of unknown form};

    my $self = $class->SUPER::__new( $content, %arg )
	or return;

    $self->{is_named} = $arg{is_named};

    my $capture = delete $arg{capture};

    if ( $self->{is_named} ) {
	$self->{absolute} = undef;
	$self->{is_relative} = undef;
	$self->{name} = $capture;
    } elsif ( $capture !~ m/ \A [-+] /smx ) {
	$self->{absolute} = $self->{number} = $capture;
	$self->{is_relative} = undef;
    } else {
	$self->{number} = $capture;
	$self->{is_relative} = 1;
    }

    return $self;
}

=head2 absolute

 print "The absolute reference is ", $ref->absolute(), "\n";

This method returns the absolute number of the capture buffer referred
to. This is the same as number() for unsigned numeric references. If the
reference is to a named buffer, C<undef> is returned.

=cut

sub absolute {
    my ( $self ) = @_;
    return $self->{absolute};
}

=head2 is_named

 $ref->is_named and print "named reference\n";

This method returns true if the reference is named rather than numbered.

=cut

sub is_named {
    my ( $self ) = @_;
    return $self->{is_named};
}

=head2 is_relative

 $ref->is_relative()
     and print "relative numbered reference\n";

This method returns true if the reference is numbered and it is a
relative number (i.e. if it is signed).

=cut

sub is_relative {
    my ( $self ) = @_;
    return $self->{is_relative};
}

=head2 name

 print "The name is ", $ref->name(), "\n";

This method returns the name of the capture buffer referred to. In the
case of a reference to a numbered capture (i.e. C<is_named> returns
false), this method returns C<undef>.

=cut

sub name {
    my ( $self ) = @_;
    return $self->{name};
}

=head2 number

 print "The number is ", $ref->number(), "\n";

This method returns the number of the capture buffer referred to. In the
case of a reference to a named capture (i.e. C<is_named> returns true),
this method returns C<undef>.

=cut

sub number {
    my ( $self ) = @_;
    return $self->{number};
}

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    if ( ! exists $self->{absolute} && exists $self->{number}
	&& $self->{number} =~ m/ \A [-+] /smx ) {

	my $delta = $self->{number};
	$delta > 0 and --$delta;	# no -0 or +0.
	$self->{absolute} = $number + $delta;

    }
    return $number;
}

1;

__END__

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
