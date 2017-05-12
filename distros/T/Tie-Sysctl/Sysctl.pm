package Tie::Sysctl;

use base 'Tie::Hash';

our $VERSION = 0.05;

sub TIEHASH {
    my $cls = shift;
    my $self = {};
    if ($^O ne 'linux') { warn "try linux instead:)\n";return }
    $self->{node} = $_[0] || '/';
    $self->{basedir} = '/proc/sys';
    unless (-d $self->{basedir}) {
        warn "basedir $self->{basedir} not mounted\n";
        return;
    }
    bless $self => $cls;
}

sub FETCH {
    my $self = shift;
    my $key = shift;
    my @files = grep {$_ eq $key} $self->ls;
    unless (defined $files[0]) {
        return;
    }
    my $t = $self->type($key);
    unless (defined $t) {
        return;
    }
    if ($t eq 'file') {
        my $data = $self->rd($key);
        chomp($data);
        return $data;
    }
    my %h;
    tie %h, __PACKAGE__, $self->{node}.'/'.$key;
    \%h;
}

sub STORE {
    my $self = shift;
    my $key = shift;
    my $val = shift;
    unless ($self->type($key)eq'file') { return }
    $self->wrt($key,$val);
}

sub type {
    my $self = shift;
    if (-d $self->file(@_)) {
        return 'dir';
    }
    elsif (-f $self->file(@_)) {
        return 'file';
    }
    return;
}

sub file {
    my $self = shift;
    my $f = $self->{basedir}.$self->{node};
    if (@_) {
        map {$f .= '/'.$_} @_;
    }
    $f =~ s{//}{/}g;
    $f;
}

sub ls {
    my $self = shift;
    unless ($self->type eq 'dir') {
        return ();
    }
    opendir(DIR,$self->file);
    my @d = readdir(DIR);
    closedir(DIR);
    shift@d;shift@d;
    @d;
}

sub rd {
    my $self = shift;
    unless ($self->type(@_)eq'file') { return }
    open(DUS,$self->file(@_)) or return;
    my $d;
    while (<DUS>) { $d .= $_ }
    close DUS;
    $d;
}

sub wrt {
    my $self = shift;
    my $data = pop;
    my $f = $self->file(@_);
    unless ($self->type(@_)eq'file') { return }
    open(DUS,">".$self->file(@_))or return;
    my $ret = print DUS $data;
    close DUS;
    $ret;
}

sub FIRSTKEY {
    my $self = shift;
    $self->{_ls} = [$self->ls];
    $self->NEXTKEY;
}

sub NEXTKEY {
    my $self = shift;
    shift@{$self->{_ls}};
}

1;
__END__

=head1 NAME

    Tie::Sysctl - Tie a hash to /proc/sys

=head1 SYNOPSIS

    use Tie::Sysctl;

    tie %t, 'Tie::Sysctl';
    $t{net}{ipv4}{ip_forward} = 1;

=head1 AUTHOR

    Raoul Zwart, E<lt>rlzwart@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

    Copyright 2003 by Raoul Zwart

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself. 

=cut

