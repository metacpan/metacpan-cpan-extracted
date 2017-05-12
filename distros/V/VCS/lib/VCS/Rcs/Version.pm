package VCS::Rcs::Version;

use File::Basename;

use vars qw(@ISA $DIFF_CMD $UPDATE_CMD);
use strict;
@ISA = qw(VCS::Rcs VCS::Version);

$DIFF_CMD = "rcsdiff -u2";
$UPDATE_CMD = "co -p";

sub new {
    my ($class, $url) = @_;
    my $self = $class->init($url);
    my $path = $self->path;
    die "$class->new: $path: $!\n" unless -f $path;
    die "$class->new: $path not in an RCS directory: $!\n"
        unless -d dirname($path) . '/RCS' or -f "$path,v";
    $self;
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
        "$UPDATE_CMD -r$self->{VERSION} $self->{PATH} 2>/dev/null |"
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
            $self->{PATH},
            ' 2>&1 |';
        $text = $self->_read_pipe($cmd);
        $text =~ s#.*^diff.*?\n##ms;
#print "cmd: $cmd gave $text\n";
    }
    $text;
}

sub author {
    shift->_boiler_plate_info('author');
}

sub date {
    shift->_boiler_plate_info('date');
}

sub reason {
    join "\n", @{shift->_boiler_plate_info('reason')};
}

1;
