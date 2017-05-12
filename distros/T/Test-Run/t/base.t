use strict;
use warnings;

use Test::More tests => 1;

{
    # TEST
    ok (scalar(eval 'require Test::Run::Obj'),
        "Eval of Test::Run::Obj's require");
}

__END__

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php
