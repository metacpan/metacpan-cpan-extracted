package VCS::Hms::File;
require Sort::Versions;

@ISA = qw(VCS::Hms);

use File::Basename;

sub new {
    my ($class, $url) = @_;
    my $self = $class->init($url);
    my $path = $self->path;
    die "$class->new: $path: $!\n" unless -f $path;
    die "$class->new: $path not in a CVS directory: $!\n"
        unless -d dirname($path) . '/HMS' or -f "$path,v";
    die "$class->new: $path failed to split log\n"
        unless $self->_split_log;
    $self;
}

# assumption - no query strings on URL
sub versions {
    my($self, $lastflag) = @_;
    my @rq_version = @_;
    my ($header, @log_revs) = $self->_split_log;
    my @revs= reverse sort Sort::Versions::versions map(/revision ([\d+\.]+)/, @log_revs);
    my $header_info = $self->_parse_log_header($header);
    my $last_rev = $header_info->{'head'};
#warn "last_rev: $last_rev\n";
    my ($rev_head, $rev_tail) = ($last_rev =~ /(.*)\.(\d+)$/);
    return VCS::Hms::Version->new("$self->{URL}/$rev_head.$rev_tail")
        if defined $lastflag;
    map { VCS::Hms::Version->new("$self->{URL}/$rev_head.$_") } @revs;
}

# UNTESTED!
sub tags {
    my $self = shift;
    my ($header, $log) = $self->_split_log($self->{VERSION});
    my $header_info = $self->_parse_log_header($header);
    my $tags_hash = {};
    my $tag_text = $header_info->{'symbolic names'};
    $tag_text =~ s#^\s+##gm;
    map {
        my ($tag, $rev) = split /:\s*/;
        $tags_hash->{$tag}=$rev;
    } split /\n/, $tag_text;
    return $tags_hash;
}

1;
