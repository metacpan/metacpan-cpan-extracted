package VCI::VCS::Hg::Commit;
use Moose;
use VCI::VCS::Hg::Diff;
use VCI::VCS::Hg::File;

extends 'VCI::Abstract::Commit';

has 'x_changes' => (is => 'ro', isa => 'HashRef', lazy_build => 1);

use constant DIFF_HEADER => qr/^([\-\+]{3}) (\S+)\t\w{3} \w{3} \d\d \d\d:\d\d:\d\d \d{4} [\+\-]\d{4}$/;

# XXX Hg does have a concept of revno, but we can't access it via hgweb.
# So we have to use the default "revno is revision id".

sub _build_added {
    my $self = shift;
    my $files = $self->x_changes->{added};
    return [map { $self->file_class->new(path => $_, project => $self->project,
                      revision => $self->revision, time => $self->time) }
               @$files];
}

sub _build_removed {
    my $self = shift;
    my $files = $self->x_changes->{removed};
    return [map { $self->file_class->new(path => $_, project => $self->project,
                      revision => $self->revision, time => $self->time) }
               @$files];
}

sub _build_modified {
    my $self = shift;
    my $files = $self->x_changes->{modified};
    return [map { $self->file_class->new(path => $_, project => $self->project,
                      revision => $self->revision, time => $self->time) }
               @$files];
}


sub x_from_rss_item {
    my ($class, $item, $project) = @_;
    my $project_path = $project->repository->root . $project->name;
    my $revision = $item->{'guid'}->{'content'};
    # Older versions of hgweb have it in "link"
    if (!$revision) {
        $revision = $item->{'link'};
    }
    
    # Sometimes revisions come to us with log{$rev}. We also include
    # log/$rev/File as an option in case they fix the bug in Hg.
    $revision =~ s#^\Q$project_path\E(/rev/|/log[{/])##;
    $revision =~ s#}?/.+$##;
    my $time = $item->{pubDate};
    
    my $message = $item->{description};
    # As far as I know, this is the only HTML that hgweb adds here.
    $message =~ s/<br\/>//g;
    
    return $class->new(
        message   => $message,
        revision  => $revision,
        time      => $time,
        committer => $item->{author},
        project   => $project);
}

sub _build_as_diff {
    my $self = shift;
    my $text = $self->project->x_get(['raw-rev', $self->revision]);
    my @lines = split("\n", $text);
    my $line = shift @lines;
    # XXX This may break if there's a line identical to DIFF_HEADER
    #     in the log message.
    while ($line !~ DIFF_HEADER) {
        $line = shift @lines;
        last if (!defined $line);
    }
    unshift(@lines, $line) if defined $line;
    return $self->diff_class->new(raw => join("\n", @lines),
                                  project => $self->project);
}

# Mercurial doesn't say anything about directories in its logs, so we have
# no idea when directories are added or removed.

sub _build_x_changes {
    my $self = shift;
    my $text = $self->as_diff->raw;
    my $files = _diff_files($text);
    
    my (@added, @removed, @modified);
    foreach my $set (@$files) {
        my ($file1, $file2) = @$set;
        my $changed_file = $file1 eq '/dev/null' ? $file2 : $file1;
        if ($file1 eq $file2) {
            push(@modified, $changed_file);
        }
        elsif ($file1 eq '/dev/null') {
            push(@added, $changed_file);
        }
        else {
            push(@removed, $changed_file);
        }
    }
    return { added => \@added, removed => \@removed, modified => \@modified };
}

# There is currently a bug in Text::Diff::Parser where it doesn't process
# correctly beyond the first file in the diff. So I just do this manually
# instead of parsing the diff.
sub _diff_files {
    my $text = shift;
    my @files;
    my @current_set = (undef, undef);
    foreach my $line (split("\n", $text)) {
        if ($line =~ DIFF_HEADER) {
            my ($type, $file) = ($1, $2);
            # Strip a/ or b/ if the file starts with that.
            $file =~ s|^[ab]/||;
            if ($type eq '---') {
                $current_set[0] = $file;
            }
            else {
                $current_set[1] = $file;
                push(@files, [@current_set]);
                @current_set = (undef, undef);
            }
        }
    }
    return \@files;
}

__PACKAGE__->meta->make_immutable;

1;
