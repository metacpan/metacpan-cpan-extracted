package lib::require::all;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use lib ();
use File::Find;

sub import {
    my($class, @dir) = @_;
    @dir = ('lib') unless @dir;
    lib->import(@dir);

    for my $dir (@dir) {
        my @files;
        File::Find::find({ no_chdir => 1, wanted => sub { push @files, $_ if /\.pm$/ } }, $dir);

        for my $file (@files) {
            $file =~ s/^\Q$dir\E[\/\\]//;
            require $file;
        }
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

lib::require::all - A tiny pragma to load all files from a lib directory

=head1 SYNOPSIS

  perl -Mlib::require::all=lib ...

=head1 DESCRIPTION

lib::require::all is a pragma to load all C<*.pm> files in a given
directory (C<lib> by default). The lib directory is automatically
added to C<@INC> via L<lib> pragma automatically.

Handy to preload all modules with tools like L<forkprove>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2012- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
