package VCS::Vss::Version;

@ISA = qw(VCS::Vss VCS::Version);

use File::Basename;
use Win32::OLE;
use Win32::OLE::Enum;
use strict;

my $DIFF_CMD = "ss Diff";
my $UPDATE_CMD = "";

sub new {
    my($class, $url) = @_;
    my $self = $class->init($url);
	$self->_fix_path;
    return $self;
}

sub vss_object {
	my ($self) = @_;
	return $self->{vss_object} if $self->{vss_object};

	my $vss_item = $self->_get_vss_item($self->path);
	my @versions = Win32::OLE::Enum->new($vss_item->{Versions})->All();
	foreach my $version (@versions) {
		$self->{vss_object} = $version if $version->{VersionNumber} eq $self->version;
	}
	if (!$self->{vss_object}) {
		die $self->version . " is not a valid version for vss item " . $self->path;
	}
	return $self->{vss_object};
}

sub tags {
    my $self = shift;
    my ($header, $log) = $self->_split_log($self->{VERSION});
    my $header_info = $self->_parse_log_header($header);
    my %rev2tags;
    my $tag_text = $header_info->{'symbolic names'};
#warn "t_t: $tag_text\n";
    $tag_text =~ s#^\s+##gm;
#warn "t_t2: $tag_text\n";
#    return () unless defined ($rev2tags{$self->{VERSION}});
    map {
        my ($tag, $rev) = split /:\s*/;
        push @{$rev2tags{$rev}}, $tag;
    } split /\n/, $tag_text;
    @{ $rev2tags{$self->{VERSION}} || [] };
}

sub text {
    my $self = shift;
    $self->_read_pipe(
        "$UPDATE_CMD -r$self->{VERSION} $self->{NAME} 2>/dev/null |"
    );
}

sub diff {
    my $self = shift;
    my $other = shift;
#print "$self -> $other\n";
    my $text = '';
    if (ref($other) eq ref($self)) {
        my $cmd = join ' ',
            $DIFF_CMD,
            (map { "-r$_" } $self->version, $other->version),
            $self->path,
            ' 2>/dev/null|';
        $text = $self->_read_pipe($cmd);
        $text =~ s#.*^diff.*?\n##ms;
#print "cmd: $cmd gave $text\n";
    }
    $text;
}

sub author {
    my ($self) = @_;
	return $self->vss_object->{Username};
}

sub date {
    my ($self) = @_;
	return $self->vss_object->{Date};
}

sub reason {
    my ($self) = @_;
	return $self->vss_object->{Comment};
}

1;
