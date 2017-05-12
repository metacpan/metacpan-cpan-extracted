package VFS::File;

use strict;
use warnings;

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	return bless $self, $class;
}

sub commit {
	die "Commit called on basic file object - subclass this!";
}

sub read {
	my ($self) = @_;
	return "";
}

sub write {
	my ($self, $data) = @_;
	$self->{Data} = $data;
	$self->commit;	# Should update version.
	return 1;
}

1;
__END__
