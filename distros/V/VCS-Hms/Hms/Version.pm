package VCS::Hms::Version;

@ISA = qw(VCS::Hms);

my $DIFF_CMD = "fdiff ";
my $UPDATE_CMD = "fco -p";

sub new {
    my ($class, $name, $version) = @_;
    return unless -f $name;
    my $self = {
        NAME => $name,
        VERSION => $version,
    };
    bless $self, $class;
}

sub name {
    my $self = shift;
    $self->{NAME};
}

sub version {
    my $self = shift;
    $self->{VERSION};
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
            $self->name,
            ' 2>&1 |';
        $text = $self->_read_pipe($cmd);
        #$text =~ s#.*^diff.*?\n##ms;
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
