
# $Id: LKFile.pm,v 1.6 2003/05/19 13:41:59 joern Exp $

package NewSpirit::LKFile;

$VERSION = "0.01";

use strict;
use FileHandle;
use Carp;
use Fcntl ':flock';

sub new {
        my $type = shift;
        my ($filename) = @_;

	croak "NewSpirit::LKFile: missing filename" unless $filename;

        my $self = {
		filename =>$filename
	};

        return bless $self, $type;
}

sub read {
	my $self = shift;
	
	my $filename = $self->{filename};
	my $fh = new FileHandle;
	open ($fh, $filename) or confess "can't read $filename";
	binmode $fh;

	flock $fh, LOCK_SH or croak "can't share lock $filename";
	my $data = join ('', <$fh>);
	close $fh;

	return \$data;
}

sub write {
	my $self = shift;
	my ($data) = @_;
	
	my $filename = $self->{filename};

	my $fh = new FileHandle;

	open ($fh, "+> $filename") or croak "can't write $filename";
	binmode $fh;
	flock $fh, LOCK_EX or croak "can't exclusive lock $filename";
	seek $fh, 0, 0 or croak "can't seek $filename";
	print $fh $$data or croak "can't write data $filename";
	truncate $fh, length($$data) or croak "can't truncate $filename";;
	close $fh or croak "can't close $filename";

	1;
}

1;
