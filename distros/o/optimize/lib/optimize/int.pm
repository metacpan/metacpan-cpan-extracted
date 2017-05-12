use strict;

package optimize::int;

use constant HINT_INTEGER => 0x00000001;

my @int_translate = qw(add subtract lt gt le ge eq ne ncmp negate preinc predec postinc postdec multiply divide modulo);
my @int_flags = qw(complement left_shift right_shift bit_and bit_xor bit_or);
my %int;
for(@int_translate) {
    $int{$_} = "i_$_";
}
for(@int_flags) {
    $int{$_} = 0;
}
*old_op = *optimize::old_op;
*state  = *optimize::state;

sub check {
    my $class = shift;
    my $op = shift;
    my $mutate = 0;
    if(exists($int{$op->name})) {
	my $cv = $op->find_cv();
	if(exists($optimize::pads{$cv->ROOT->seq}) &&
	   $optimize::pads{$cv->ROOT->seq}->[$op->targ]->[1]->{int}) {
	    $mutate++;
	} elsif($op->can('first') && $op->first->name eq 'padsv' &&
		exists($optimize::pads{$cv->ROOT->seq}) &&
		$optimize::pads{$cv->ROOT->seq}->[$op->first->targ]->[1]->{int}) {
	    $mutate++;
	} elsif($op->can('last') && $op->last->name eq 'padsv' &&
		exists($optimize::pads{$cv->ROOT->seq}) &&
		$optimize::pads{$cv->ROOT->seq}->[$op->last->targ]->[1]->{int}) {
	    $mutate++;
	}
    }
    if($mutate && $int{$op->name}) {
	$op->mutate($int{$op->name});
	$op->private($op->private | HINT_INTEGER);
    } elsif($mutate) {
	$op->private($op->private | HINT_INTEGER);
    }

}

=head1 NAME

optimize::int - Turn on integer ops for specified variables

=head1 SYNOPSIS

    use optimize;
    my $int : optimize(int);
    $int = 1.5;
    $int += 1;
    if($int == 2) { print "$int is integerized" }

=head1 DESCRIPTION

Most perl operators can be turned into integer versions which do 
all work in integers and truncates (floors) all fractional 
portions. This is traditionally done by C<use integer;> which turns
on integer operations in the scope. This is usually by far too wide
area to turn on those ops in.

For greater flexibility this allows you to turn on integer ops for a
specific variable using the optimize attribute with an int argument,
C<my $int : optimize(int);>. 

=head1 AUTHOR

Artur Bergman E<lt>abergman@cpan.orgE<gt>

=head1 SEE ALSO

L<optimize> L<integer>

=cut

