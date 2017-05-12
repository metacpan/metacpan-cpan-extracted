package VCI::VCS::Git::Commit;
use Moose;

extends 'VCI::Abstract::Commit';

has 'x_changes' => (is => 'ro', lazy_build => 1);
# Moose doesn't let me do lazy_build here, as of Moose 0.33.
has '+message' => (lazy => 1, default => sub { shift->_build_message });

sub _build_message {
    my $self = shift;
    my $text = $self->project->x_do('log', ['-1', '--pretty=medium',
                                            $self->revision], 1);
    # Everything before the message ends in two newlines.
    $text =~ s/^.+\n\n//s;
    # Also, every line is idented by four spaces.
    $text =~ s/^\s{4}//mg;
    # If Git's "subject" or "body" are empty, it prints "<unknown>"
    $text =~ s/^<unknown>\n//s;
    $text =~ s/\n<unknown>$//s;
    chomp($text);
    return $text;
}

sub _build_added    { return shift->_x_files_from_changes('A') }
sub _build_removed  { return shift->_x_files_from_changes('D') }
sub _build_modified { return shift->_x_files_from_changes('M') }
sub _build_moved    { return shift->_x_hash_from_changes('R')  }
sub _build_copied   { return shift->_x_hash_from_changes('C')  }

sub _build_as_diff {
    my $self = shift;
    my $diff = $self->project->x_do('whatchanged',
        ['-m', '-p', '-1', '-C', '--pretty=format:', $self->revision], 1);
    return $self->diff_class->new(raw => $diff, project => $self->project);
}

sub _x_files_from_changes {
    my ($self, $type) = @_;
    my $files = $self->x_changes->{$type};    
    (print STDERR "Creating " . scalar @$files . " $type file objects...\n")
        if $self->vci->debug;
    return [map { $self->file_class->new(path => $_, project => $self->project,
                                         revision => $self->revision) }
                @$files];
}

sub _x_hash_from_changes {
    my ($self, $type) = @_;
    my $details = $self->x_changes->{$type};
    if ($self->vci->debug) {
        print STDERR "Creating " . scalar(keys %$details)
                     . " $type file objects...\n";
    }
    my %result;
    foreach my $new_name (keys %$details) {
        my %params = %{ $details->{$new_name} };
        $result{$new_name} =
            $self->file_class->new(%params, project => $self->project);
    }
    return \%result;
}


sub _build_x_changes {
    my $self = shift;
    my $output = $self->project->x_do('whatchanged',
        ['-m', '-1', '-C', '--pretty=format:%P', $self->revision]);

    my (%moved, %copied);
    my %actions = ('A' => [], 'M' => [], 'D' => [],
                   'C' => \%copied, 'R' => \%moved);
    
    my @parents = split(' ', shift @$output) if @$output;
    foreach my $line (@$output) {
        # The format of this line is described in the git-diff-tree manpage.
        $line =~ /^:\d+ \d+ (\w+)\.* (\w+)\.* (\w)(\d+)?\t([^\t]+)(\t(.*))?$/o;
        my ($sha1, $sha2, $type, $file, $new_name) = ($1, $2, $3, $5, $7);
        if ($type eq 'C') {
            $copied{$new_name} = { path => $file, x_one_of => \@parents };
            if ($sha1 eq $sha2) {
                push(@{ $actions{'A'} }, $new_name);
            }
            else {
                push(@{ $actions{'M'} }, $new_name);
            }
        }
        elsif ($type eq 'R') {
            $moved{$new_name} = { path => $file, x_one_of => \@parents };
            if ($sha1 ne $sha2) {
                push(@{ $actions{'M'} }, $new_name);
            }
        }
        else {
            push(@{ $actions{$type} }, $file);
        }
    }
    
    return \%actions;
}

__PACKAGE__->meta->make_immutable;

1;
