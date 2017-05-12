package Ubic::AtomicFile;
$Ubic::AtomicFile::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: atomic file operations


use IO::Handle;
use Params::Validate qw(:all);

sub store($$;$) {
    my ($data, $file, @options) = @_;

    my $options = validate(@options, {
        sync => { default => 1 },
    });

    my $new_file = "$file.new";

    open my $fh, '>', $new_file or die "Can't open '$new_file' for writing: $!";
    print {$fh} $data or die "Can't print to '$new_file': $!";
    $fh->flush or die "Can't flush '$new_file': $!";

    if ($options->{sync}) {
        # Here is a link which says why we should do sync too if we don't want to lose data:
        # https://bugs.launchpad.net/ubuntu/+source/linux/+bug/317781/comments/54
        #
        # For some types of atomic files this is important, for others (pidfiles, temp files) it can be too big performance hit.
        # Every part of ubic code decides for itself.
        $fh->sync or die "Can't sync '$new_file': $!";
    }

    close $fh or die "Can't close '$new_file': $!";
    rename $new_file => $file or die "Can't rename '$new_file' to '$file': $!";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::AtomicFile - atomic file operations

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    use Ubic::AtomicFile;

    Ubic::AtomicFile::store("blah\n" => "/var/lib/blah");

    # store but don't sync content to disk
    Ubic::AtomicFile::store("blah\n" => "/var/lib/blah", { sync => 0 });

=head1 FUNCTIONS

=over

=item B<store($data, $file)>

=item B<store($data, $file, $options)>

Store C<$data> into C<$file> atomically. Temporary C<$file.new> will be created and then renamed to C<$file>.

If I<sync> flag is set and false in C<$options> hash then data will not be synced on disk before file is renamed (should be faster, but you can lose your data - see comments in code).

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
