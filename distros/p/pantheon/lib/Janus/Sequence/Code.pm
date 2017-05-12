package Janus::Sequence::Code;

=head1 NAME

Janus::Sequence::Code - Load maintenence plugin code.

=head1 SYNOPSIS

 use Janus::Sequence::Code;

 my $code = Janus::Sequence::Code->load( '/code/file' );
 my ( $alpha, $omega ) = $code->dump( 'alpha', 'omega' );

=head1 CODE

B<$STATIC> may be defined with a true value - a hint that I<our> variables
in this package should have a I<static> effect.

Also, the package must return a HASH of ARRAY of CODE indexed by stage names.

Top level HASH consists of ARRAYs indexed by sequence names. Each ARRAY
consists of CODE indexed by stage names. i.e. ARRAY is a flattened HASH,
which guarantees order of stage invocations.

=cut
use strict;
use warnings;
use Carp;

our $STATIC;

=head1 METHODS

=head3 load( $file )

Load code from file. Returns object.

=cut
sub load
{
    my ( $class, $code ) = splice @_;

    my $error = "invalid code $code";
    confess $error unless -f $code || -l $code;

    require $code; ## compile time
    my %self = ( static => $STATIC );

    my @code = do $code; ## run time
    confess "$error: $@" if $@;

    $self{code} = $code = @code % 2 ? shift @code : { @code };
    confess "$error: not HASH" if ref $code ne 'HASH';

    while ( my ( $name, $seq ) = each %$code )
    {
        my $error .= "$error: $name";
        confess "$error is not ARRAY or flattened HASH"
            if ref $seq ne 'ARRAY' || @$seq % 2;

        $error .= ": invalid stage definition";

        for my $i ( 1 .. @$seq / 2 )
        {
            my ( $n, $stage ) = splice @$seq, 0, 2;
            confess $error if ref $n;
            confess "$error: $n is not CODE" if ref $stage ne 'CODE';

            push @$seq, { name => $n, code => $stage };
        }
    }

    bless \%self, ref $class || $class;
}

=head3 dump( @name )

Returns code identified by @name.

=cut
sub dump
{
    my $self = shift;
    my $code = $self->{code};
    return @$code{@_};
}

=head3 static()

Returns true if static I<hint> is on, false otherwise.

=cut
sub static
{
    my $self = shift;
    return $self->{static};
}

=head1 EXAMPLE

 use strict;
 use Data::Dumper;

 ## hint: modifications on our variables persist through all sub calls.
 our $STATIC = 1;

 our ( $foo, $bar ) = qw( foo bar );
 our %hash = ( foo => 1, bar => 1 );

 return
 (
    alpha =>
    [
        foo => sub { print "$foo\n"; $bar = 'baz'; }, 
        bar => sub { print "$bar\n"; $foo = 'bar'; delete $hash{foo}; }
    ],

    omega =>
    [
        foo => sub { print "$foo\n"; },
        bar => sub { print "$bar\n"; print Dumper \%hash },
    ]
 );

=cut
1;
