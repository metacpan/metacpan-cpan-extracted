#!/usr/bin/perl
# 17.11.1999, Sampo Kellomaki <sampo@iki.fi>
#
# Open a file descriptor, fork, write password to fd from parent.
# The password will be read from the fd by the child because -$fd was
# passed as password.
#
# This method has the advantage that password is never trivially visible
# using ps(1). Never-the-less, remember that root is always root.
#
# See also: `man perlipc' and `man perlfunc' for description of pipe.

$password = shift;

pipe R,W or die $!;

if (fork) {
    # Father comes here
    
    close R;
    print W $password;
    close W;
    exit;
}

close W;
$fd = fileno(R);
warn "The password file descriptor is $fd.\n";

### Redirect stdin and stdout

open STDIN, "README" or die;
open STDOUT, ">dist.sig" or die;

exec('./smime', '-ds', 'dist-id.pem', '-'.$fd);

#EOF
