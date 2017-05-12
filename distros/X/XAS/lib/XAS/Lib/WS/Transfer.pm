package XAS::Lib::WS::Transfer;

our $VERSION = '0.01';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::WS::RemoteShell',
  codecs    => 'base64 unicode',
  utils     => ':validation dotid',
  constants => 'SCALAR',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub get {
    my $self = shift;
    my ($remote, $local) = validate_params(\@_, [
        { type => SCALAR },
        { type => SCALAR },
    ]);

    # this assumes that the remote WS-Manage server is Microsoft based
    # otherwise you would use something sensible like scp

    my $fh;
    my $code   = $self->_code_get_powershell($remote);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    $self->command($invoke);
    $self->receive();
    $self->check_exitcode();
    
    if (open($fh, '>', $local)) {

        print $fh decode_base64($self->stdout);
        close $fh;

    } else {

        $self->throw_msg(
            dotid($self->class) . '.put.badfile',
            'file_create',
            $local, $!
        );

    }

    return $self->exitcode;

}

sub put {
    my $self = shift;
    my ($local, $remote) = validate_params(\@_, [
        { type => SCALAR },
        { type => SCALAR },
    ]);

    # this assumes that the remote WS-Manage server is Microsoft based
    # otherwise you would use something sensible like scp

    my $fh;
    my $size   = 30 * 57;
    my $invoke = 'powershell -noprofile -encodedcommand %s';

    if (open($fh, '<', $local)) {

        while (read($fh, my $buf, $size)) {

            my $data = encode_base64($buf, '');
            my $code = $self->_code_put_powershell($remote, $data);
            my $cmd  = sprintf($invoke, $code);

            $self->command($cmd);
            $self->receive();
            $self->check_exitcode();

        }

        close $fh;

    } else {

        $self->throw_msg(
            dotid($self->class) . '.put.badfile',
            'file_create',
            $local, $!
        );

    }

    return $self->exitcode;

}

sub exists {
    my $self = shift;
    my ($path) = validate_params(\@_, [1]);

    my $code   = $self->_code_exists_powershell($path);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    $self->command($invoke);
    $self->receive();
    $self->check_exitcode();

    return $self->exitcode ? 0 : 1;

}

sub mkdir {
    my $self = shift;
    my ($path) = validate_params(\@_, [1]);

    my $code   = $self->_code_mkdir_powershell($path);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    $self->command($invoke);
    $self->receive();
    $self->check_exitcode();

    return $self->exitcode;

}

sub rmdir {
    my $self = shift;
    my ($path) = validate_params(\@_, [1]);

    my $code   = $self->_code_rmdir_powershell($path);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    $self->command($invoke);
    $self->receive();
    $self->check_exitcode();

    return $self->exitcode;

}

sub del {
    my $self = shift;
    my ($path) = validate_params(\@_, [1]);

    my $code   = $self->_code_del_powershell($path);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    $self->command($invoke);
    $self->receive();
    $self->check_exitcode();

    return $self->exitcode;

}

sub dir {
    my $self = shift;
    my ($path) = validate_params(\@_, [1]);

    my $code   = $self->_code_dir_powershell($path);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    $self->command($invoke);
    $self->receive();
    $self->check_exitcode();

    return $self->stdout;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Powershell Boilerplate - yeah heredoc...
#
# some powershell code borrowed from
#    https://github.com/WinRb/winrm-fs/tree/master/lib/winrm-fs/scripts
# ----------------------------------------------------------------------

sub _code_put_powershell {
    my $self     = shift;
    my $filename = shift;
    my $data     = shift;

    my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
try {
    $data = '__DATA__'
    $bytes = [System.Convert]::FromBase64String($data)
    $file = [System.IO.File]::Open('__FILENAME__', 'Append')
    $file.Write($bytes, 0, $bytes.Length)
    $file.Close()
    exit 0
} catch {
    Write-Error -Message $_.Exception.Message
    exit 1
}
CODE

    $code =~ s/__FILENAME__/$filename/;
    $code =~ s/__DATA__/$data/;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_get_powershell {
    my $self = shift;
    my $filename = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath('__FILENAME__')
if (Test-Path $path -PathType Leaf) {
    $bytes = [System.convert]::ToBase64String([System.IO.File]::ReadAllBytes($path))
    Write-Host $bytes
    exit 0
}
Write-Error -Message 'File not found'
exit 1
CODE

    $code =~ s/__FILENAME__/$filename/;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_exists_powershell {
    my $self = shift;
    my $path = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath('__PATH__')
if (Test-Path $path) {
   exit 0
} else {
   Write-Error -Message '__PATH__ not found'
   exit 1
}
CODE

    $code =~ s/__PATH__/$path/g;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_mkdir_powershell {
    my $self = shift;
    my $path = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath('__PATH__')
if (!(Test-Path $path)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    exit 0
}
Write-Error -Message '__PATH__ not found'
exit 1
CODE

    $code =~ s/__PATH__/$path/g;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_rmdir_powershell {
    my $self = shift;
    my $path = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath('__PATH__')
if (Test-Path $path) {
    Remove-Item $path -Force
    exit 0
}
Write-Error -Message '__PATH__ not found'
exit 1
CODE

    $code =~ s/__PATH__/$path/g;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_del_powershell {
    my $self = shift;
    my $path = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath('__PATH__')
if (Test-Path $path) {
    Remove-Item $path -Force
    exit 0
}
Write-Error -Message '__PATH__ not found'
exit 1
CODE

    $code =~ s/__PATH__/$path/g;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_dir_powershell {
    my $self = shift;
    my $path = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath('__PATH__')
if (Test-Path $path) {
    Get-ChildItem -Path __PATH__
    exit 0
}
Write-Error -Message '__PATH__ not found'
exit 1
CODE

    $code =~ s/__PATH__/$path/g;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

1;

__END__

=head1 NAME

XAS::Lib::WS::Transfer - A class to transfer files with WS-Manage

=head1 SYNOPSIS

 use Try::Tiny;
 use XAS::Lib::WS::Transfer;

 my $trans = XAs::Lib::WS::Transfer->new(
   -username    => 'Administrator',
   -password    => 'secret',
   -url         => 'http://windowserver:5985/wsman',
   -auth_method => 'basic',
   -keep_alive  => 1,
 );

 try {

     if ($trans->create) {

         if ($trans->exists('test.txt')) {

             $trans->del('test.txt');

         }

         $trans->put('junk.txt', 'test.txt');

         my $output = $trans->dir('.');
         printf("%s\n", $output);

         $trans->destroy;

     }

 } catch {

     my $ex = $_;
     $trans->destroy;
     die $ex;

 };

=head1 DESCRIPTION

This package implements a crude method of performing file operations
with a Windows based WS-Manage server. These methods should be wrapped 
in an exception handling block to trap errors. If not, resources will not
be freed on the remote server. You have been warned.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::WS::RemoteShell|XAS::Lib::WS::RemoteShell> and
takes the same parameters.

=head2 get($remote, $local)

Retrieve a file from the remote server. This is very memory intensive 
operation as the file is converted to base64 and dumped to stdout on the 
remote end. This blob is then buffered on the local side and converted back
to a binary blob before being written out to disk. This method can be used 
to transfer binary files. 

=over 4

=item B<$local>

The name of the local file. Paths are not checked and any existing file
will be over written.

=item B<$remote>

The name of the remote file. 

=back

=head2 put($local, $remote)

This method will put a file on the remote server. This is an extremely slow 
operation. The local file is block read and the buffer is converted to
base64. This buffer is then stored within a script that will be executed to 
convert the blob back into a binary stream. This stream is then appended to 
the remote file. Not recommended for large files. This method can be used to 
transfer binary files. 

=over 4

=item B<$local>

The name of the local file.

=item B<$remote>

The name of the remote file. Paths are not checked and any existing file 
will be appended too.

=back

=head2 exists($path)

This method checks to see if the remote path exists. Returns true if it does.

=over 4

=item B<$path>

The name of the path.

=back

=head2 del($filename)

This method will delete a remote file. Returns true if successfull.

=over 4

=item B<$filename>

The name of the file to delete.

=back

=head2 mkdir($path)

This method will create a directory on the remote server. Intermediate 
directories are also created. Returns true if successful.

=over 4

=item B<$path>

The path for the directory.

=back

=head2 rmdir($path)

This method will remove a directory for the the remote server. Returns
true if successful.

=over 4

=item B<$path>

The name of the directory to remove.

=back

=head2 dir($path)

This method will return a listing of a directory on the remote server.
No effort to format the listing is made. This is the raw output.

=over 4

=item B<$path>

The name of the directory to perform the listing on.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::WS::Base|XAS::Lib::WS::Base>

=item L<XAS::Lib::WS::RemoteShell|XAS::Lib::WS::RemoteShell>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
