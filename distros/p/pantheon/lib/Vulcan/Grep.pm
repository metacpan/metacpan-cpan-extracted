package Vulcan::Grep;

=head1 NAME

Vulcan::Grep - Evaluate input according to supplied rules

=head1 SYNOPSIS
 
 use Vulcan::Grep;

 my $grep = Vulcan::Grep->new( input => \@lines, rule => \@rules );
 my @match = $grep->eval();

=cut
use strict;
use warnings;
use Carp;

sub new
{
    my ( $class, %self ) = splice @_;
    my ( $input, $rule, @rule ) = map { defined $self{$_} ?
        $self{$_} : confess "$_ not defined" } qw( input rule );

    unless ( my $ref = ref $input )
    {
        $self{input} = [ $input ];
    }
    elsif ( $ref ne 'GLOB' && $ref ne 'ARRAY' )
    {
        confess "input is not ARRAY or handle";
    }

    $rule = [ $rule ] if ref $rule ne 'ARRAY';

    for ( my $i = 0; $i < @$rule; $i ++ )
    {
        my ( $regex, $test, @test ) = @$rule[ $i ++, $i ];
        my $ref = ref $regex;

        if ( $ref ne 'Regexp' )
        {
            $regex = $ref ? '' : eval $regex;
            confess 'invalid rule' if ref $regex ne 'Regexp';
        }

        if ( defined $test && ref $test eq 'ARRAY' ) { @test = @$test }
        else { $i -- }
        push @rule, [ $regex, @test ]; 
    }

    $self{rule} = \@rule;
    bless \%self, ref $class || $class;
}

=head1 METHODS

=head3 eval()

Return matched input. In list context return array of matched input. In scalar
context return array reference of matchecd input, if any, undef otherwise.

=cut
sub eval
{
    my ( $self, @match ) = shift;
    my ( $input, $rule ) = @$self{ qw( input rule ) };

    for my $input ( ref $input eq 'ARRAY' ? @$input : <$input> )
    {
        for my $rule ( @$rule )
        {
            next if $input !~ $rule->[0] ||
                @$rule > 1 && ! grep { eval $rule->[$_] } 1 .. @$rule - 1;

            push @match, $input;
        }
    }
    return wantarray ? @match : @match ? \@match : undef;
}

1;
