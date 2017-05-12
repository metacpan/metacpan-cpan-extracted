package Fake::Mechanize;

use strict;
use warnings;

use IO::File;

# -----------------------------------------------------------------------------
# Object methods

sub new {
	my $class = shift;
    my $self  = shift;

    return  unless($self->{file});

	# create the object
	bless $self, $class;

    return $self;
}

sub content {
    my $self = shift;

    unless($self->{path}) {
        $self->{path} = sprintf "t/data/%s", $self->{file};
        my $fh = IO::File->new($self->{path},'r') or die "Failed to open file [$self->{path}]: $!\n";
        while(<$fh>) { $self->{content} .= $_ }
    }

    return $self->{content};
}

sub uri {
    my $self = shift;

    return $self->{path};
}

1;
