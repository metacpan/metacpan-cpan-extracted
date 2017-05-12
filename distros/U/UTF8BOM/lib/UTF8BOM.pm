package UTF8BOM;
use strict;

use IO::File;
use IO::Dir;
use File::Spec;

our $VERSION = '1.02';

my $BOM = "\x{ef}\x{bb}\x{bf}";

sub check_bom {
    use bytes;
    my($class, $str) = @_;
    return ($BOM eq substr($str, 0, length($BOM)))
        ? 1 : 0;
}

sub remove_from_str {
    my($class, $str) = @_;
    return $class->check_bom($str)
        ? return substr($str, length($BOM))
        : $str;
}

sub insert_into_str {
    my($class, $str) = @_;
    return $class->check_bom($str)
        ? $str
        : $BOM.$str;
}

sub remove_from_file {
    my($class, $file) = @_;
    my $fh = IO::File->new($file)
        or $class->_croak(qq/Couldn't open file "$file"./);
    my @lines = $fh->getlines;
    $fh->close;
    my $str = $class->remove_from_str( join("", @lines) );
    $fh = IO::File->new($file, "w")
        or $class->_croak(qq/Couldn't open file "$file"./);
    $fh->print($str);
    $fh->close;
}

sub insert_into_file {
    my($class, $file) = @_;
    my $fh = IO::File->new($file)
        or $class->_croak(qq/Couldn't open file "$file"./);
    my @lines = $fh->getlines;
    $fh->close;
    my $str = $class->insert_into_str( join("", @lines) );
    $fh = IO::File->new($file, "w")
        or $class->_croak(qq/Couldn't open file "$file"./);
    $fh->print($str);
    $fh->close;
}

sub remove_from_files {
    my($class, %options) = @_;
    my $dir = $options{dir} || File::Spec->curdir;
    my $recursive = $options{recursive} || 0;
    my $dh = IO::Dir->new($dir)
        or $class->_croak(qq/Couldn't open directory "$dir"./);
    while( defined( my $file = $dh->read ) ) {
        next if($file eq '.' || $file eq '..');
        my $path = File::Spec->catfile($dir, $file);
        if (-e $path && -f $path) {
            $class->remove_from_file($path);
        } elsif (-e $path && -d $path && $recursive) {
            $class->remove_from_files(
                dir       => $path,
                recursive => 1,
            );
        }
    }
    $dh->close;
}

sub insert_into_files {
    my($class, %options) = @_;
    my $dir = $options{dir} || File::Spec->curdir;
    my $recursive = $options{recursive} || 0;
    my $dh = IO::Dir->new($dir)
        or $class->_croak(qq/Coundn't open directory "$dir"./);
    while( defined( my $file = $dh->read ) ) {
        next if($file eq '.' || $file eq '..');
        my $path = File::Spec->catfile($dir, $file);
        if (-e $path && -f $path) {
            $class->insert_into_file($path);
        } elsif (-e $path && -d $path && $recursive) {
            $class->insert_into_files(
                dir       => $path,
                recursive => 1,
            );
        }
    }
    $dh->close;
}

sub _croak {
    my($self, $msg) = @_;
    require Carp; Carp::croak($msg);
}

1;
__END__

=head1 NAME

UTF8BOM - handling Byte Order Mark for UTF-8 files

=head1 SYNOPSIS

    use UTF8BOM;

    UTF8BOM->insert_into_files(
        recursive => 1,
        dir       => '/path/to/dir',
    );

    # or on your shell
    utf8bom -insert -dir  /path/to/dir  -recursive
    utf8bom -strip  -file /path/to/file

    # display usage
    utf8bom -help

=head1 DESCRIPTION

This modules allows you to insert UTF8's BOM into strings and files, or remove it from them easily.

=head1 METHODS

=over 4

=item check_bom

check whether passed string includes BOM or not, and return boolean.

    if( UTF8BOM->check_bom($str) ) {
        # $str includes BOM
    } else {
        # $str doesn't include BOM
    }

=item insert_into_str

insert BOM into passed string, and return it.

    $str = UTF8BOM->insert_into_str($str)

    # Now, $str includes BOM

=item insert_into_file

insert BOM into head of file.

    UTF8BOM->insert_into_file('/path/to/file');

    # Now, the file has BOM on it's head.

=item insert_into_files

insert BOM into head of files.

    UTF8BOM->insert_into_files(
        dir       => '/path/to/dir',
        recursive => 1,
    );

    # Now, all the in the directory has BOM on it's head.

=item remove_from_str

remove BOM from passed string, and return it.

    $str = UTF8DOM->remove_from_str($str);

=item remove_from_file

    UTF8BOM->remove_from_file('/path/to/file');

=item remove_from_files

    UTF8BOM->remove_from_files(
        dir       => '/path/to/dir',
        recursive => 1,
    );

=back

=head1 SEE ALSO

utf8bom

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

