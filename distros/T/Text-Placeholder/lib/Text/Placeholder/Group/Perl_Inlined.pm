package Text::Placeholder::Group::Perl_Inlined::Ground;
use strict;
use warnings;
my $data = ();
my %data = ();
my @data = ();
my $sub_eval_shift = sub{eval shift};

package Text::Placeholder::Group::Perl_Inlined;

use strict;
use warnings;
#use Carp qw();
#use Data::Dumper;
use parent qw(
	Text::Placeholder::Group::_
	Object::By::Array);

sub THIS() { 0 }

sub ATR_SUBJECT() { 0 }
sub ATR_COMPILED() { 1 }

sub _init {
	my ($this) = @_;

	$this->[ATR_SUBJECT] = undef;
	$this->[ATR_COMPILED] = undef;

	return;
}

sub P_PLACEHOLDER() { 1 }
sub lookup {
	$_[THIS]->subject($_[P_PLACEHOLDER]);
	return([$sub_eval_shift, $_[P_PLACEHOLDER]]);
}

sub P_CODE() { 1 }
sub subject {
	my ($this) = @_;

	return($this->[ATR_SUBJECT]) unless(exists($_[P_CODE]));
	$this->[ATR_SUBJECT] = $_[P_CODE];

	return;
}

sub clear {
	$data = ();
	%data = ();
	@data = ();
}

1;
