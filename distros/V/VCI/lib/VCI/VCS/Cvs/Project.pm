package VCI::VCS::Cvs::Project;
use Moose;
use MooseX::Method;

use IPC::Cmd;
use File::Temp qw(tempdir);
use File::Path;

use VCI::Util;

extends 'VCI::Abstract::Project';

use constant CVSPS_SEPARATOR => "---------------------";

use constant CVSPS_MEMBER => qr/^\s+(.+):(INITIAL|[\d\.]+)->([\d\.]+)(\(DEAD\))?/o;

has 'x_tmp' => (is => 'ro', isa => 'Str', lazy => 1,
                default => sub { tempdir('vci.cvs.XXXXXX', TMPDIR => 1,
                                         CLEANUP => 1) });

sub BUILD {
    my $self = shift;
    $self->_name_never_ends_with_slash();
    $self->_name_never_starts_with_slash();
}

method 'get_file' => named (
    path     => { isa => 'VCI::Type::Path', coerce => 1, required => 1 },
    revision => { isa => 'Str' },
) => sub {
    my $self = shift;
    my ($params) = @_;
    my $path = $params->{path};
    my $rev  = $params->{revision};
    
    confess("Empty path name passed to get_file") if $path->is_empty;
    
    if (defined $rev) {
        my $file = $self->file_class->new(path => $path, revision => $rev,
                                          project => $self);
        # If $file->time works, then we have a valid file & revision.
        return $file if defined eval { $file->time };
        undef $@; # Don't mess up anything else that checks $@.
        return undef;
    }
    
    # MooseX::Method always has a hash key for each parameter, even if they
    # weren't passed by the caller.
    delete $params->{$_} foreach (grep(!defined $params->{$_}, keys %$params));
    return $self->SUPER::get_file(@_);
};

sub _build_history {
    my $self = shift;
    my @lines = split "\n", $self->x_cvsps_do(undef, 1);

    my @commits;
    my %current_commit;
    my $new_patchset = 1;
    # The first line is a CVSPS_SEPARATOR, so we just discard it.
    shift @lines;
    while (@lines) {
        my $line = shift @lines;
        if ($line =~ /^Log:\s*$/) {
            my @log_lines;
            while (@lines) {
                last if $lines[0] =~ /^Members:\s*$/;
                my $log_line = shift @lines;
                push(@log_lines, $log_line);
            }
            $current_commit{'Log'} = \@log_lines;
        }
        elsif ($line =~ /^Members:\s*$/) {
            my @member_lines;
            while (@lines) {
                my $member_line = shift @lines;
                # This discards the extra newline at the end of "Members:"
                last if $member_line eq '';
                push(@member_lines, $member_line);
            }
            $current_commit{'Members'} = \@member_lines;
        }
        elsif ($line =~ /^(\S+):\s+(.+)?$/) {
            my ($field, $value) = ($1, $2);
            $current_commit{$field} = $value;
        }
        elsif ($new_patchset and $line =~ /^PatchSet\s+(\d+)\s*$/) {
            $current_commit{PatchSet} = $1;
            $new_patchset = 0;
        }
        elsif ($line eq CVSPS_SEPARATOR) {
            $new_patchset = 1;
            push(@commits, $self->_x_commit_from_patchset(\%current_commit));
            %current_commit = ();
        }
        else {
            warn "Unparsed cvsps line: $line";
        }
    }
    
    if (keys %current_commit) {
        push(@commits, $self->_x_commit_from_patchset(\%current_commit));
    }
    
    return $self->history_class->new(commits => \@commits, project => $self);
}
    
sub _x_commit_from_patchset {
    my ($self, $data) = @_;
    my $log_lines = $data->{Log};
    # There's an extra newline at the end of @log_lines.
    pop @$log_lines;
    
    my ($added, $removed, $modified) = $self->_x_parse_members($data);
    
    return $self->commit_class->new(
        revision  => $data->{PatchSet},
        time      => $data->{Date} . ' UTC',
        committer => $data->{Author},
        message   => join("\n", @$log_lines),
        added     => $added,
        removed   => $removed,
        modified  => $modified,
        project   => $self,
    );
}

sub _x_parse_members {
    my ($self, $data) = @_;
    my $members = $data->{Members};
    my $date    = $data->{Date} . 'UTC';

    my (@added, @removed, @modified);
    foreach my $item (@$members) {
        if ($item =~ CVSPS_MEMBER) {
            my ($path, $from_rev, $to_rev, $dead) = ($1, $2, $3, $4);
            my $file = $self->file_class->new(
                path => $path, revision => $to_rev, project => $self,
                time => $date);
            if ($from_rev eq 'INITIAL') {
                push(@added, $file);
            }
            elsif ($dead) {
                push(@removed, $file);
            }
            else {
                push(@modified, $file);
            }
        }
        else {
            warn "Failed to parse message item: [$item] for patchset "
                 . $data->{PatchSet};
        }
    }
    return (\@added, \@removed, \@modified);
}

sub x_cvsps_do {
    my ($self, $addl_args) = @_;
    $addl_args ||= [];
    my @args = (@$addl_args, '-u', '-b', 'HEAD', $self->name);
    my $root = $self->repository->root;
    my $cvsps = $self->vci->x_cvsps;
    
    if ($self->vci->debug) {
        print STDERR "Running CVSROOT=$root $cvsps " . join(' ', @args)
                     . "\n";
    }

    # Just using the --root argument of cvsps doesn't work.
    local $ENV{CVSROOT} = $root;
    local $ENV{TZ} = 'UTC';
    # XXX cvsps must be able to write to $HOME or this will fail.
    my ($success, $error_msg, $all, $stdout, $stderr) =
        IPC::Cmd::run(command => [$self->vci->x_cvsps, @args]);
    if (!$success) {
        confess "$error_msg: " . join('', @$stderr);
    }
    
    return join('', @$stdout);
}

sub DEMOLISH {
    File::Path::rmtree($_[0]->x_tmp) if $_[0]->{x_tmp};
}

__PACKAGE__->meta->make_immutable;

1;
