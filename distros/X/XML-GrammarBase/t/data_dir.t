#!/usr/bin/perl

package MyClass::WithDataDir;

use MooX 'late';

with ('XML::GrammarBase::Role::DataDir');

has '+module_base' => (default => 'XML::Grammar::MyGrammar');

package main;

use strict;
use warnings;

use Test::More tests => 1;

{
    my $obj;
    eval
    {
        # TEST
        $obj = MyClass::WithDataDir->new;
        my $test = $obj->module_base;
    };

    my $Err = $@;

    # TEST
    like ($Err, qr/isa check for "module_base" failed/,
        "Accessing module_base threw an exception",
    );
}

=head1 COPYRIGHT & LICENSE

Copyright 2013 by Shlomi Fish

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
