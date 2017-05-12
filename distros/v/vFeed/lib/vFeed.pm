#
# $Id: vFeed.pm 11 2014-04-10 11:55:50Z gomor $
#
package vFeed;
use strict;
use warnings;

require v5.6.1;

our $VERSION = '0.12';

1;

__END__

=head1 NAME

vFeed - Interface to vFeed Open Source Cross Linked and Aggregated Local Vulnerability Database

=head1 DESCRIPTION

The following Perl module is an implementation of vFeed's API, originally written in Python.

vFeed is an Open Source Cross Linked and Aggregated Local Vulnerability Database. It is developed by Nabil Ouchn from ToolsWatch (@ToolsWatch, http://www.toolswatch.org/). The original source code, written in Python, is accessible on GitHub:

https://github.com/toolswatch/vFeed

The idea is to have an aggregated local vulnerability database you can download and use without Internet connection. The current format of vFeed database is SQL, implemented with the use of SQLite. More information can be found here:

http://www.toolswatch.org/2013/09/vfeed-open-source-aggregated-vulnerability-database-v0-4-5-released-support-of-cwe-2-5-and-snort-rules/ .

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
