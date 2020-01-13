package urpm::md5sum;

use strict;
use urpm::util qw(cat_ file_size);
use urpm::msg;


=head1 NAME

urpm::md5sum - Meta-data checking routines for urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut 


=item parse($md5sum_file)

Parse a MD5SUM file.
Returns a hash of file => md5sum 

=cut

sub parse {
    my ($md5sum_file) = @_;

    my %h = map {
	my ($md5sum, $file) = m|^([0-9-a-f]+)\s+(?:\./)?(\S+)$|i or return;
	$file => $md5sum;
    } cat_($md5sum_file) or return;

    \%h;
}


=item parse($md5sum_file)

Check size and parse a MD5SUM file.
Returns a hash of file => md5sum 

=cut

sub check_file {
    my ($md5sum_file) = @_;

    file_size($md5sum_file) > 32 && parse($md5sum_file);
}

sub from_MD5SUM__or_warn {
    my ($urpm, $md5sums, $basename) = @_;
    $md5sums->{$basename} or $urpm->{log}(N("warning: md5sum for %s unavailable in MD5SUM file", $basename));
    $md5sums->{$basename};
}


=item versioned_media_info_file($urpm, $medium, $basename)

Returns the latest versionated file name for $basename

=cut

sub versioned_media_info_file {
    my ($urpm, $medium, $basename) = @_;
    my $md5sums = $medium->{parsed_md5sum} or $urpm->{log}("$medium->{name} has no md5sum"), return;

    my @l = map { $md5sums->{$_} eq $md5sums->{$basename} && /^(\d{8}-\d{6})-\Q$basename\E$/ ? $1 : @{[]} } keys %$md5sums;

    if (@l == 0) {
	$urpm->{debug}("no versioned $basename for medium $medium->{name}") if $urpm->{debug};
    } else {
	@l > 1 and $urpm->{debug}("multiple versions for $basename for medium $medium->{name}: @l") if $urpm->{debug};
    }
    $l[0];
}

=item compute($file)

Return the MD5SUM control sum of $file

=cut

sub compute {
    my ($file) = @_;
    eval { require Digest::MD5 };
    if ($@) {
	#- Use an external command to avoid depending on perl
	return (split ' ', `/usr/bin/md5sum '$file'`)[0];
    } else {
	my $ctx = Digest::MD5->new;
	open my $fh, $file or return '';
	$ctx->addfile($fh);
	close $fh;
	return $ctx->hexdigest;
    }
}

1;


=back

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2020 Mageia

=cut
