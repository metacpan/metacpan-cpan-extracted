package Web::Library::Provider;
use Moose::Role;
use 5.14.0;
use File::Spec;
use File::ShareDir ();
use Cwd qw(abs_path);
requires qw(latest_version css_assets_for javascript_assets_for);

# This is a version of dist_dir() that takes into account local.
# Taken from File::Share, but that didn't work for me.
sub dist_dir {
    my ($dist) = @_;
    (my $inc = "$dist.pm") =~ s!(-|::)!/!g;
    my $path = $INC{$inc};
    return File::ShareDir::dist_dir($dist) unless $path;
    my @split = File::Spec->splitdir(abs_path $path);
    1 while @split && pop(@split) ne 'lib';
    $path = File::Spec->catfile(@split);
    my $local_share = File::Spec->catfile($path, 'share');
    my $makefile_pl = File::Spec->catfile($path, 'Makefile.PL');
    my $dist_ini    = File::Spec->catfile($path, 'dist.ini');
    return ((-e $makefile_pl || -e $dist_ini) && -e $local_share)
      ? $local_share
      : File::ShareDir::dist_dir($dist);
}

sub dist_name {
    my $self = shift;
    ref($self) =~ s/::/-/gr;
}

sub get_dir_for {
    my ($self, $version) = @_;
    $version = $self->latest_version if $version eq 'latest';
    File::Spec->catfile(dist_dir($self->dist_name), $version);
}
1;

=pod

=head1 NAME

Web::Library::Provider - Moose role for client-side library distributions

=head1 SYNOPSIS

    package Web::Library::Bootstrap;
    use Moose;
    with 'Web::Library::Provider';
    sub latest_version { '2.3.1' }

=head1 DESCRIPTION

This Moose role is used by distributions that wrap a client-side library. If
you just use L<Web::Library> normally, you do not need it.

