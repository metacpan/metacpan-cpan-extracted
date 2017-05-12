package The::Net;

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2009110702';

push @INC => sub {
    require LWP::Simple;
    require IO::File;
    require Fcntl;

    my $url      = pop;

    return unless $url =~ m{^\w+://};

    my $document = LWP::Simple::get ($url) or die "Failed to fetch $url: $!\n";

    my $fh = IO::File -> new_tmpfile or die "Failed to create temp file: $!\n";
    $fh -> print ($document) or die "Failed to print: $!\n";
    $fh -> seek (0, Fcntl::SEEK_SET()) or die "Failed to seek: $!\n";

    $fh;
};


1;

__END__

=head1 NAME

The::Net - Use the Net to fetch your required modules.

=head1 SYNOPSIS

    use The::Net;

    require 'http://www.example.com/Module.pm';

=head1 DESCRIPTION

By using The::Net, you enable C<require> to fetch Modules using HTTP
or FTP, when given a URL as argument.

=head1 DEVELOPMENT
 
The current sources of this module are found on github,
L<< git://github.com/Abigail/the--net.git >>.

=head1 AUTHOR
    
Abigail L<< mailto:cpan@abigail.be >>.

=head1 COPYRIGHT and LICENSE
    
Copyright (C) 2001, 2009 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:
        
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
    
=cut
