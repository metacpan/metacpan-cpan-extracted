package Text::Placeholder::Group::OS::Unix::File::Name;

use strict;
use warnings;
#use Carp qw();
#use Data::Dumper;
use parent qw(
	Text::Placeholder::Group::_
	Object::By::Array);

sub THIS() { 0 }

sub ATR_PLACEHOLDERS() { 0 }
sub ATR_SUBJECT() { 1 }

my $PLACEHOLDERS = {
	'file_name_full' => sub { return($_[THIS][ATR_SUBJECT][0])},
	'file_name_path' => sub { return($_[THIS][ATR_SUBJECT][1])},
	'file_name_base' => sub { return($_[THIS][ATR_SUBJECT][2])},
	'file_name_extension' => sub { return($_[THIS][ATR_SUBJECT][3])},
};

sub _init {
	my ($this) = @_;

	$this->[ATR_PLACEHOLDERS] = $PLACEHOLDERS;
	$this->[ATR_SUBJECT] = [];

	return;
}

sub subject {
	my ($this, $name) = @_;

	return($this->[ATR_SUBJECT][0]) unless(exists($_[1]));

	my ($full, $path, $extension) = ($name, '', '');
	if($name =~ s/^(.*)\///s) {
		$path = $1;
	}
	if($name =~ s/\.(.*?)$//s) {
		$extension = $1;
	}

	$this->[ATR_SUBJECT] = [$full, $path, $name, $extension];

	return;
}

1;
