### Socket.pm --- Choose an IO::Socket::INET* class  -*- Perl -*-

### Ivan Shmakov, 2013

## To the extent possible under law, the author(s) have dedicated all
## copyright and related and neighboring rights to this software to the
## public domain worldwide.  This software is distributed without any
## warranty.

## You should have received a copy of the CC0 Public Domain Dedication
## along with this software.  If not, see
## <http://creativecommons.org/publicdomain/zero/1.0/>.

### Code:
package t::Socket;

use common::sense;

our $Class
    = undef;
foreach (qw (IO::Socket::INET6 IO::Socket::INET IO::Socket)) {
    ## .
    next
        unless (eval ("require " . $_ . ";"));
    $Class
        = $_;
    ## .
    last;
}

## .
1;

### Emacs trailer
## Local variables:
## coding: us-ascii
## End:
### Socket.pm ends here
