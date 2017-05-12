package Win32::SecretFile;

our $VERSION = '0.02';

use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(create_secret_file);

require XSLoader;
XSLoader::load('Win32::SecretFile', $VERSION);

use Carp;
use File::Spec;

my $csff_overwrite = 1;
my $csff_temporary = 2;
my $csff_hidden = 4;
my $csff_encrypted = 8;

my $win32_error_file_exists = 80;

my $unique_ix = 0;

sub create_secret_file {
    my ($name, $data, %opts) = @_;

    my $local_appdata = delete $opts{local_appdata};
    my $short_path = delete $opts{short_path};
    my $make_path = delete $opts{make_path} // 1;
    my $unique = delete $opts{unique};
    my $overwrite = ($unique ? 0 : delete $opts{overwrite}) // 1;
    my $hidden = delete $opts{hidden} // 1;
    my $temporary = delete $opts{temporary} // 1;
    my $encrypted = delete $opts{encrypted};

    %opts and croak "option(s) '" . join("', '", keys %opts) . "' are unknown or bad combination";

    if ($local_appdata) {
        my $base = _local_appdata_path() // return;
        $name = File::Spec->rel2abs($name, $base);
    }
    else {
        $name = File::Spec->rel2abs($name);
    }

    my ($drive, $path, $file) = File::Spec->splitpath($name);
    if ($make_path) {
        my $base = $drive;
        my @path = File::Spec->splitdir($path);
        while (@path) {
            $base = File::Spec->join($base, shift(@path));
            _create_directory($base);
        }

        my $base_exists = do {
            local ($!, $^E);
            my $short = _short_path($base);
            defined $short and -d $short
        };
        return unless $base_exists;
    }

    my $ext;
    if ($unique) {
        $file =~ /(\.[^\.]*)$/;
        $ext = $1 // '';
        my $len_ext = length $ext;
        substr($name, -$len_ext, $len_ext, '');
    }

    my $flags = (($overwrite ? $csff_overwrite : 0) |
                 ($hidden    ? $csff_hidden    : 0) |
                 ($temporary ? $csff_temporary : 0) |
                 ($encrypted ? $csff_encrypted : 0));
    while (1) {
        my $final_name = ($unique ? join('-', $name, $$, $unique_ix++, int rand 1000).$ext : $name);
        if (_create_secret_file($final_name, $data // '', $flags)) {
            if ($short_path) {
                return _short_path($final_name) // $final_name;
            }
            return $final_name;
        }
        return unless $unique and $^E == $win32_error_file_exists;
    }
}


1;
__END__

=head1 NAME

Win32::SecretFile - Save secret data into files with restricted accessibility

=head1 SYNOPSIS

  use Win32::SecretFile qw(create_secret_file)
  my $short = create_secret_file($path, $path, short_path => 1);
  system $cmd, "-pwdpath=$short";
  unlink $short;

=head1 DESCRIPTION

Sometimes you need to pass secret data to some other process through
the filesystem. This module allows you to create a file with a quite
restricted set of access permissions and save some data inside.

The module exports the following function:

=over 4

=item $path = create_secret_file($filename, $data, %opts)

Creates at the given position C<$filename> a file which only the
current user has permissions to access and saves the contents of $data
inside.

The function returns the final absolute file path. In case of failure
it returns undef (C<$^E> can be inspected then to discover the cause
of failure).

The following optional arguments are accepted:

=over 4

=item local_appdata => $bool

When given a true value, the filename is taken relative to the user's
local application data directory (usually, something like
C<C:\\Documents and Settings\\Rolf\\Local Configuration\\Program
Data>).

Defaults to false.

=item make_path => $bool

The function creates any non-existent directories on the target
path. Defaults to true.

=item overwrite => $bool

If a file with the same name already exists it is
overwritten. Defaults to true.

=item unique => $bool

Appends a pseudo-random string into the filename until it finds an
unoccupied path. Defaults to false.

=item short_path => $bool

Returns the short form of the final path.

=item hidden => $bool

Sets the hidden attribute on the created file. Defaults to true.

=item temporary => $bool

Sets the temporary attribute on the created file. Defaults to true.

=item encrypted => $bool

Sets the encrypted attributed on the created file. Defaults to false.

=back

=back

=head1 SEE ALSO

This module was a spin-off of L<Net::SSH::Any> where it is used to
pass passwords to slave commands.

The thread in Perlmonks where it was discussed:
L<http://perlmonks.org/?node_id=1110748>

See also the MSDN documentation for
L<CreateFile|http://msdn.microsoft.com/en-us/library/windows/desktop/aa363858%28v=vs.85%29.aspx>
for further information about the hidden, temporary and encrypted
flags.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>
Copyright (C) 2014 by BrowserUk

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.21.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
