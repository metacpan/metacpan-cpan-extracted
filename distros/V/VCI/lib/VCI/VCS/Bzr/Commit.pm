package VCI::VCS::Bzr::Commit;
use Moose;
extends 'VCI::Abstract::Commit';

use XML::Simple qw(:strict);

has 'x_changes' => (is => 'ro', isa => 'HashRef', lazy_build => 1);
has '+revno' => (required => 1);

sub _build_as_diff {
    my $self = shift;
    my $rev = $self->revision;
    my $proj_path = $self->repository->root . $self->project->name;
    my $diff = $self->vci->x_do(
        args => ['diff', "--change=revid:$rev", $proj_path],
        errors_ignore => [1, 256]);
    return $self->diff_class->new(raw => $diff, project => $self->project);
}

sub _build_added    { shift->x_changes->{added}    }
sub _build_removed  { shift->x_changes->{removed}  }
sub _build_modified { shift->x_changes->{modified} }
sub _build_moved    { shift->x_changes->{moved}    }

sub _build_x_changes {
    my $self = shift;
    my $proj_path = $self->repository->root . $self->project->name;
    my $xml_string = $self->vci->x_do(
        args => [qw(log -v --show-ids --xml),
                 "--revision=revid:" . $self->revision, $proj_path]);
    # See Bzr::History for why we do this.
    local $XML::Simple::PREFERRED_PARSER = 'XML::Parser';
    my $xs = XML::Simple->new(ForceArray => [qw(file directory)],
                              KeyAttr => []);
    my $xml = $xs->xml_in($xml_string);
    my $log = $xml->{log};
    # The format of the XML changed in xmloutput Revision 17.
    my $files = exists $log->{'affected-files'} ? $log->{'affected-files'}
                                                : $log;
    my (@added, @removed, @modified);
    if (exists $files->{added}) {
        @added = $self->_x_parse_items($files->{added}, $log);
    }
    if (exists $files->{removed}) {
        @removed = $self->_x_parse_items($files->{removed}, $log);
    }
    if (exists $files->{modified}) {
        @modified = $self->_x_parse_items($files->{modified}, $log);
    }
        
    my %moved;
    if (exists $files->{renamed}) {
        %moved = $self->_x_parse_renamed($files->{renamed}, $log);
    }
    
    return {
        added     => \@added,
        removed   => \@removed,
        modified  => \@modified,
        moved     => \%moved,
    };
}

sub _x_parse_renamed {
    my ($self, $renamed, $log) = @_;
    my %result;
    foreach my $file (@{ $renamed->{file} || [] }) {
        $result{$file->{content}} = $self->file_class->new(
            path => $file->{oldpath}, x_before => $log->{revisionid},
            project => $self->project);
    }
    foreach my $dir (@{ $renamed->{directory} || [] }) {
        $result{$dir->{content}} = $self->directory_class->new(
            path => $dir->{oldpath}, x_before => $log->{revisionid},
            project => $self->project);
    }
    return %result;
}

sub _x_parse_items {
    my ($self, $items, $log) = @_;

    my @result;
    if (exists $items->{file}) {
        foreach my $file (@{ $items->{file} }) {
            # Have to "require" to avoid dep loops.
            push(@result, $self->file_class->new(
                path => $file->{content}, revision => $log->{revisionid},
                time => $log->{timestamp}, project => $self->project));
        }
    }
    if (exists $items->{directory}) {
        foreach my $dir (@{ $items->{directory} }) {
            require VCI::VCS::Bzr::Directory;
            push(@result, $self->directory_class->new(
                path => $dir->{content}, revision => $log->{revisionid},
                time => $log->{timestamp}, project => $self->project));
        }
    }
    return @result;
}

__PACKAGE__->meta->make_immutable;

1;
