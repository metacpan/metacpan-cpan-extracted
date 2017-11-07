package Win32::Packer::InstallerMaker;

use Path::Tiny;
use Win32::Packer::Helpers qw(to_list);

use Moo;
use namespace::autoclean;

extends 'Win32::Packer::Base';

has _fs => ( is => 'ro', default => sub { {} } );
has _lc_fs => ( is => 'ro', default => sub { {} } );

sub add_file {
    my $self = shift;
    my $from = shift;
    my $to = shift // $from->realpath->basename;

    $self->log->debug("Adding file '$from' as '$to'");

    $self->_add_obj($to, @_, type => 'file', path => $from);
}

sub add_tree {
    my $self = shift;
    my $from = shift;
    my $to = shift // path($from->realpath->basename);
    $self->log->debug("Adding dir '$from' as '$to'");
    my %opts = @_;
    my %to_skip = map { lc(path($to)->child($_)) => 1 } to_list $opts{skip};
    $self->_add_tree($from, $to, \%to_skip);
}

sub _add_tree {
    my ($self, $from, $to, $to_skip) = @_;

    if ($to_skip->{lc $to}) {
        $self->log->trace("Skipping '$from', to: '$to'");
        return;
    }
    if ($from->is_dir) {
        $self->_add_obj($to, type => 'dir');
        for my $c ($from->children) {
            $self->_add_tree($c, $to->child($c->basename), $to_skip);
        }
    }
    elsif ($from->is_file) {
        $self->_add_obj($to, type => 'file', path => $from);
    }
    else {
        $self->log->warn("Unsupported file system object at '$from'");
    }
}

sub _add_obj {
    my ($self, $to, %opts) = @_;
    return if $to eq '.' or $to eq '' or $to eq '/';

    my $parent = path($to)->parent;
    $self->_add_obj("$parent", type => 'dir');

    $self->_add_obj_norec($to, %opts);
}

sub _normalize_to {
    my ($self, $to) = @_;
    $self->_lc_fs->{lc $to} //= $to; # case normalization
}

sub _add_obj_norec {
    my ($self, $to, %opts) = @_;
    my $to1 = $self->_normalize_to($to);
    my $obj = $self->_fs->{$to1} //= {};

    $self->_merge($to, $obj, %opts);
}

sub _merge {
    my ($self, $to, $obj, %opts) = @_;
    for my $k (keys %opts) {
        if (defined $opts{$k}) {
            if (defined $obj->{$k}) {
                if (grep $k eq $_, qw(handles firewall_allow)) {
                    $obj->{$k} = [@{$obj->{$k}}, @{$opts{$k}}];
                }
                else {
                    $self->_die("fs object $to reinserted with a different value for $k: $opts{$k}, was: $obj->{$k}")
                        unless $obj->{$k} eq $opts{$k};
                }
            }
            else {
                $obj->{$k} = $opts{$k}
            }
        }
    }
}

sub merge {
    my ($self, $to, %opts) = @_;
    $self->log->debug("Merging object at '$to'");
    my $obj = $self->_fs->{$self->_normalize_to($to)} // $self->_die("Unable to merge nonexistent object $to");
    $self->_merge($to, $obj, %opts);
}

sub run {
    my $self = shift;
    $self->_dief("class %s does not implement virtual method run", ref $self);
}

1;
