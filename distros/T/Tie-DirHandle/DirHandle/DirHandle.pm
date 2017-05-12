package Tie::DirHandle;

use Carp;

$VERSION = '1.10';

sub TIEHANDLE {
	my ($class,$dh,$dir) = @_;
	opendir $dh, $dir or croak "cannot open dir $dir: $!";
	return bless {HANDLE => $dh, DIR => $dir, PATH => $dir}, $class;
}

sub READLINE {
	my $self = shift;
	return readdir ($self->{HANDLE});
}

sub rewind {
	my $self = shift;
	return rewinddir($self->{HANDLE});
}

sub DESTROY {
	my $self = shift;
	closedir $self->{HANDLE} or croak "cannot close dir $self->{DIR}: $!";
}

1;

__END__

=head1 NAME

Tie::DirHandle - definitions for tied directory handles

=head1 SYNOPSIS

    use Tie::DirHandle;
    
    [$ref =] tie *FH, "Tie::DirHandle", *DH, "/usr/local/lib";
    while (<FH>){
        do_something_with_file($_);
    }
    (tied *FH)->rewind;	# or $ref->rewind;
    untie *FH;

=head1 DESCRIPTION

This module provides filehandle-like read access to directory handles.  There
are not many available methods, because directory handles are read-only.  The
only methods are C<TIEHANDLE>, C<READLINE>, C<DESTROY>, and C<rewind>.

To tie a filehandle to a directory handle, the syntax is as follows:
    tie *FILEHANDLE, "Tie::DirHandle", *DIRHANDLE, "/path/to/dir";

The module will open the directory (and croak with an error if not able to do
so).  When untying the filehandle, the directory is closed.

After a filehandle has been tied to a directory handle, you can read from the
directory using the <HANDLE> syntax.  This syntax calls C<READLINE>.

To rewind the directory, there are two possible syntaxes: (tied *FH)->rewind;
or $ref->rewind;

The second works if you have stored the return value of the tie in a variable
$ref.  The value of C<tied *FH> and $ref are the same.

The variable $ref (or C<tied *FH>) contains a hash reference, with three keys.
$ref->{HANDLE} returns the directory handle it references.  $ref->{PATH} and
$ref->{DIR} are synonymous, and return the path of the directory.

=over

=item TIEHANDLE classname, DIRHANDLE, DIR

This ties the specified directory handle to the filehandle given as the first
argument to tie().  DIR is the pathname of the directory.

=item READLINE this

This returns the next value (if called in a scalar context) or the next values
(if returned in a list context) of readdir().

=item DESTROY this

This closes the directory.

=back

=head1 See Also

Look into L<perltie>, the documentation on the tie() function.

=head1 Author

 Jeff Pinyan (CPAN ID: PINYAN)
 jeffp@crusoe.net
 www.crusoe.net/~jeffp

=cut
