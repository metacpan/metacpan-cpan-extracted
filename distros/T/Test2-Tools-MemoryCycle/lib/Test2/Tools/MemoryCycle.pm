package Test2::Tools::MemoryCycle;

use strict;
use warnings;
use 5.008004;
use Devel::Cycle qw( find_cycle );
use Test2::API qw( context );
use Exporter qw( import );

# ABSTRACT: Check for memory leaks and circular memory references
our $VERSION = '0.01'; # VERSION


our @EXPORT = qw( memory_cycle_ok );

# Adapted from Test::Memory::Cycle for Test2::API
sub memory_cycle_ok {
    my $ref = shift;
    my $msg = shift;

    $msg ||= 'no memory cycle';

    my $cycle_no = 0;
    my @diags;

    # Callback function that is called once for each memory cycle found.
    my $callback = sub {
        my $path = shift;
        $cycle_no++;
        push( @diags, "Cycle #$cycle_no" );
        foreach (@$path) {
            my ($type,$index,$ref,$value) = @$_;

            my $str = 'Unknown! This should never happen!';
            my $refdisp = _ref_shortname( $ref );
            my $valuedisp = _ref_shortname( $value );

            $str = sprintf( '    %s => %s', $refdisp, $valuedisp )               if $type eq 'SCALAR';
            $str = sprintf( '    %s => %s', "${refdisp}->[$index]", $valuedisp ) if $type eq 'ARRAY';
            $str = sprintf( '    %s => %s', "${refdisp}->{$index}", $valuedisp ) if $type eq 'HASH';
            $str = sprintf( '    closure %s => %s', "${refdisp}, $index", $valuedisp ) if $type eq 'CODE';

            push( @diags, $str );
        }
    };

    find_cycle( $ref, $callback );
    my $ok = !$cycle_no;

    my $ctx = context();
    if($ok) {
        $ctx->pass_and_release($msg);
    } else {
        $ctx->fail_and_release($msg, @diags);
    }

    return $ok;
} # memory_cycle_ok

my %shortnames;
my $new_shortname = "A";

sub _ref_shortname {
    my $ref = shift;
    my $refstr = "$ref";
    my $refdisp = $shortnames{ $refstr };
    if ( !$refdisp ) {
        my $sigil = ref($ref) . " ";
        $sigil = '%' if $sigil eq "HASH ";
        $sigil = '@' if $sigil eq "ARRAY ";
        $sigil = '$' if $sigil eq "REF ";
        $sigil = '&' if $sigil eq "CODE ";
        $refdisp = $shortnames{ $refstr } = $sigil . $new_shortname++;
    }

    return $refdisp;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::MemoryCycle - Check for memory leaks and circular memory references

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Tools::MemoryCycle;

 my $foo = { bar => 1 };
 
 memory_cycle_ok $foo;  # pass
 
 $foo->{baz} = sub {
   print $foo->{bar}, "\n";
 };

 memory_cycle_ok $foo;  # fail

 done_testing;

=head1 DESCRIPTION

Perl's garbage collection has one big problem: Circular references can't get cleaned up.
The above example is the sort of thing that sometimes trips me up, where a code reference
inside a data structure refers to another part of the data structure.  There already
exists a good testing module to find these sort of problems: L<Test::Memory::Cycle>,
so why write this one?  Well that module uses L<Test::Builder>, and this one instead uses
L<Test2::API>.  If you want to write L<Test2::Suite> tests without pulling in L<Test::Builder>
then this is the cycle testing module for you.

This module also uses the standard L<Exporter> interface, instead of letting you specify
a test plan.  That behavior was once in vogue I guess, but I do not care for it.

=head1 FUNCTIONS

=head2 memory_cycle_ok

 memory_cycle_ok $reference, $message;
 memory_cycle_ok $reference;

Checks that C<$reference> doesn't have any circular memory references.

=head1 CAVEATS

This module is based on and quite similar to L<Test::Memory::Cycle>.  That module is
more mature, and has more features.  So far I only need the one test function.  Other
features may be added in the future.

=head1 SEE ALSO

=over 4

=item L<Test::Memory::Cycle>

=item L<Devel::Cycle>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
