
package Tie::FlatFile::Array;
use strict;
use warnings;

use Fcntl;
use POSIX qw(:stdio_h);

sub block_shift {
    my ($self, $position, $nelements, $distance) = @_;
    my $fh = $self->fh;
    my $reclen = $self->reclen;

    my $block;
    $self->seek_index($position);
    unless (read $fh, $block, $nelements * $reclen) {
        return;
    }

    $self->seek_index($position + $distance);
    print $fh $block;
}

sub seek_index {
    my ($self, $index) = @_;
    seek($self->fh, $index * $self->reclen, SEEK_SET);
}

sub tell_index {
    my $self = shift;
    my $pos = tell($self->fh) / $self->reclen;
	ceil($pos);
}



sub block_move {
	my ($self, $index, $newindex, $blocksize) = @_;
	my $fh = $self->fh;
	my $reclen = $self->reclen;
	return unless $newindex != $index;

	# Copy the block to be moved.
	my @block = map $self->FETCH($_), ($index..$index+$blocksize-1);

	# Store the block in its new location.
	my $n = $newindex;;
	$self->STORE($n++, shift @block) while(@block);
	1;
}

sub tester {
	my $testfile = shift;
	unlink $testfile;

	unless ($testfile =~ /\.dbf$/) {
		die ("Filename '$testfile' does not end with .dbf");
	}

	my @part = (
		['x_lycos.com', 8000],
		['x_msn.com',6140],
		);

	my $flat;
	$flat = tie my @dbf, 'Tie::FlatFile::Array', $testfile,
		O_RDWR | O_CREAT, 0644, { packformat => 'A30N' }
		or die("Tie failed: $!");

	push @dbf, ['google.com', 14592];
	push @dbf, ['yahoo.com', 10126];
	push @dbf, ['ask.com', 8114];
	push @dbf, ['tyson.com', 314];
	push @dbf, ['janesearch.com', 559], ['waits.org', 1029];
	# $flat->block_move(1,0,2);


	foreach my $n (0..$#dbf) {
		print "@{$dbf[$n]}\n";
	}

	undef $flat;
	untie @dbf;

}


1;


