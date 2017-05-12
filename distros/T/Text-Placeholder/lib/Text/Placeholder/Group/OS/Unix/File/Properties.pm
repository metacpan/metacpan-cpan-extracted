package Text::Placeholder::Group::OS::Unix::File::Properties;

use strict;
use warnings;
#use Carp qw();
#use Data::Dumper;
use parent qw(
	Text::Placeholder::Group::_
	Object::By::Array);

sub P_MODE() { 0 }
sub as_rwx_string($) {
	my @permissions = split('', unpack('b*', pack('i', $_[P_MODE])));
	foreach my $i (0, 3, 6) {
		$permissions[$i] = ($permissions[$i]) ? 'x' : '-';
		$permissions[$i+1] = ($permissions[$i+1]) ? 'w' : '-';
		$permissions[$i+2] = ($permissions[$i+2]) ? 'r' : '-';
	}
	$permissions[0] = 's' if($permissions[9]);
	$permissions[3] = 's' if($permissions[10]);
	$permissions[6] = 's' if($permissions[11]);
	return(join('', reverse(splice(@permissions, 0, 9))));
}

sub THIS() { 0 }

sub ATR_PLACEHOLDERS() { 0 }
sub ATR_SUBJECT() { 1 }
sub ATR_STAT() { 2 }

my $PLACEHOLDERS = {
	'file_mode_octal' => sub { return($_[THIS][ATR_STAT][2])},
	'file_mode_rwx' => sub { return(as_rwx_string($_[THIS][ATR_STAT][2]))},
	'file_owner_id' => sub { return($_[THIS][ATR_STAT][4])},
	'file_owner_name' => sub { return((getpwuid($_[THIS][ATR_STAT][4]))[0])},
	'file_group_id' => sub { return($_[THIS][ATR_STAT][5])},
	'file_group_name' => sub { return((getgrgid($_[THIS][ATR_STAT][5]))[0])},
	'file_size' => sub { return($_[THIS][ATR_STAT][7])},
	'file_timestamp_creation' => sub { return(localtime($_[THIS][ATR_STAT][8]))},
	'file_timestamp_modification' => sub { return(localtime($_[THIS][ATR_STAT][9]))},
	'file_timestamp_status' => sub { return(localtime($_[THIS][ATR_STAT][10]))}
};

sub _init {
	my ($this) = @_;

	$this->[ATR_PLACEHOLDERS] = $PLACEHOLDERS;
	$this->[ATR_SUBJECT] = undef;
	$this->[ATR_STAT] = [];

	return;
}

sub subject {
	my ($this, $name) = @_;

	return($this->[ATR_SUBJECT][0]) unless(exists($_[1]));

	Carp::confess($name) unless(-e $name);
	$this->[ATR_SUBJECT] = $name;
	$this->[ATR_STAT] = [stat($name)];

	return;
}

1;
