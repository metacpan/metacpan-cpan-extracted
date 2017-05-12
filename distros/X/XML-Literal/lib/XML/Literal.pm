package XML::Literal;

use 5.006;
use strict;
use warnings;
use File::Glob ();

$XML::Literal::VERSION = '0.02';

sub import {
    my $class       = shift;
    my $callback    = shift;

    no warnings 'redefine';
    *CORE::GLOBAL::glob = sub {
        if ($_[0] =~ m{^\s*<}) {
            # Looks like < <tag> >
            goto &$callback;
        }
        elsif ($_[0] =~ m{/\w*\s*$}) {
            # Looks like <tag/> or <tag\>...\</tag>
            @_ = "<$_[0]>";
            goto &$callback;
        }
        else {
            # Looks like file globbing
            goto &File::Glob::glob;
        }
    };
}

1;

__END__

=head1 NAME

XML::Literal - Syntax suppor for XML literals

=head1 SYNOPSIS

    # This is not a source filter: it just augments glob().
    use XML::Simple;
    use XML::Literal \&XMLin;

    # Simple element
    my $xml1 = <hr/>;

    # With variable interpolation
    my $xml2 = <input value='$ARGV[0]' />;

    # With an extra pair of angle brackets
    my $xml3 = < <a href='/'> Some Text </a> >;

    # With escaped angle brackets 
    my $xml4 = <a href='/'\> Some Text \</a>;

    # Direct call to the xml-building glob'' constructor
    my $xml5 = glob'
        <p><em>
            Some Text
        </em></p>
    ';

    # This does not look like XML, so it's still shell glob
    my @files = <*.*>;

=head1 DESCRIPTION

This module takes one function at its C<use> line.  Afterwards, all
single-line C<< <...> >> calls that looks like a XML literal will be
processed with that function, instead of the built-in shell C<glob>.

Support for qx<...> overriding for multiline XML literals is planned for
Perl 5.10.

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT (The "MIT" License)

Copyright 2006 by Audrey Tang <cpan@audreyt.org>.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is fur-
nished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIT-
NESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE X
CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
