
# $Id: Header.pm,v 1.3 2000/10/02 17:43:20 nwiger Exp $
####################################################################
#
# Copyright (c) 2000 Nathan Wiger <nate@sun.com>
#
# This simple module provides two functions, header and unheader,
# which do lightweight, general-purpose RFC 822 header parsing.
#
# This module is intended mainly as a proof-of-concept for the Perl
# 6 proposal located at: http://dev.perl.org/rfc/3__.html
#
####################################################################
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.
#
####################################################################

package Text::Header;
require 5.004;

use strict;
use vars qw(@EXPORT @ISA $VERSION);
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(header unheader);

sub header {
    my @ret;
    my @args = @_;

    # go through each tag pair, reformatting the tag
    # and pushing it onto an array
    while (my $tag = shift @args and my $val = shift @args) {
        chomp($tag = ucfirst lc $tag);
        $tag =~ s/[-_](\w)/-\u$1/g;
        if ( ref $val ) {
           $val = join ', ', @$val;
        }
        chomp $val;
        push @ret, "$tag: $val\n";
    }
    return @ret;
}

sub unheader {
    my @ret;
    chomp(my @lines = @_);
    my $i = 0;
    while (my $line = $lines[$i]) {

        # join multiple indented lines per RFC 822
        $line .= $lines[$i] while ($lines[++$i] =~ /^\s+/);

        # split the two and change the tag to lowercase 
        my($tag, $val) = $line =~ m/([-\w]+)\s*:\s*(.*)/s;
        $tag = lc $tag;
        $tag =~ s/-/_/g;
   
        # some cleanup
        $val =~ s/\n\s*/ /g;
        $val =~ s/\s*,\s+/, /g;
        push @ret, $tag, $val;
    }
    return @ret;
}

1;

__END__

=head1 NAME

Text::Header - RFC 822/2068 C<header> and C<unheader> functions

=head1 SYNOPSIS

   use Text::Header;     # header and unheader exported

   # Construct headers similar to CGI.pm and HTTP::Headers

   @HEADERS = header(content_type => 'text/html',
                     author => 'Nathan Wiger',
                     last_modified => $date,
                     accept => [qw(text/html text/plain)]);

   # The above produces the array:

   @HEADERS = ("Content-Type: text/html\n",
               "Author: Nathan Wiger\n",
               "Last-Modified: Wed Sep 27 13:31:06 PDT 2000\n",
               "Accept: text/html, text/plain\n");

   # Can also construct SMTP headers to format mail

   @mail_headers = header(from => 'Nathan Wiger <nate@sun.com>',
                          to => 'perl5-porters@perl.org');
   
   print $MAIL @mail_headers, "\nKeep up the great work!\n";

   # The above would print this to the $MAIL handle:

   From: Nathan Wiger <nate@sun.com>
   To: perl5-porters@perl.org

   Keep up the great work!


=head1 DESCRIPTION

This module provides two new functions, C<header> and C<unheader>,
which provide general-purpose RFC 822 header construction and parsing.
They do not provide any intelligent defaults of HTTP-specific methods.
They are simply aimed at providing an easy means to address the
mechanics of header parsing.

The output style is designed to mimic C<CGI.pm> and C<HTTP::Headers>,
so that users familiar with these interfaces will feel at home with
these functions. As shown above, the C<headers> function automatically
does the following:

   1. uc's the first letter of each tag token and lc's the
      rest, also converting _'s to -'s automatically

   2. Adds a colon separating each tag and its value, and
      exactly one newline after each one

   3. Combines list elements into a comma-delimited
      string 

Note that a list is always joined into a comma-delimited string. To
insert multiple separate headers, simply call C<header> with multiple
args:

   push @out, header(accept => 'text/html',
                     accept => 'text/plain');

This would create multiple "Accept:" lines.

Note that unlike C<CGI.pm>, the C<header> function provided here
does not provide any intelligent defaults. If called as:

    @out_headers = header;

It will return an empty list. This allows C<header> to be more general
pupose, so it can provide SMTP and other headers as well. You can also
use it as a generic text formatting tool, hence the reason it's under
the C<Text::> hierarchy.

The C<unheader> function works in exactly the opposite direction from
C<header>, pulling apart headers and returning a list. C<unheader>:

   1. lc's the entire tag name, converting -'s to _'s

   2. Separates each tag based on the colon delimiter,
      chomping newlines.

   3. Returns a list of tag/value pairs for easy assignment
      to a hash

So, assuming the C<@HEADERS> array shown up top:

   %myheaders = unheader(@HEADERS);

The hash C<%myheaders> would have the following values:

   %myheaders = (
       content_type => 'text/html',
       author => 'Nathan Wiger',
       last_modified => 'Wed Sep 27 13:31:06 PDT 2000',
       accept => 'text/html, text/plain'
   );

Note that all keys are converted to lowercase, and their values have
their newlines stripped. However, note that comma-separated fields
are B<not> split up on input. This cannot be done reliably because
some fields, such as the HTTP C<Date:> header, can contain commas
even though they are not lists. Inferring this type of structure
would require knowledge of content, and these functions are
specifically designed to be content-independent.

The C<unheader> function will respect line wrapping, as seen in
SMTP headers. It will simply join the lines and return the value,
so that:

   %mail = unheader("To: Nathan Wiger <nate@sun.com>,
                             perl5-porters@perl.org");

Would return:

   $mail{to} = "Nathan Wiger <nate@sun.com>, perl5-porters@perl.org"

Notice that multiple spaces between the comma separator have been
condensed to a single space. Since the C<header> and C<unheader>
functions are direct inverses, this call:

   @out = header unheader @in;

Will result in C<@out> being exactly equivalent to C<@in>.

=head1 REFERENCES

This is designed as both a Perl 5 module and also a Perl 6 prototype.
Please see the Perl 6 proposal at http://dev.perl.org/rfc/333.html

This module is designed to be fully compliant with the internet
standards RFC 822 (SMTP Headers) and RFC 2068 (HTTP Headers).

=head1 AUTHOR

Copyright (c) 2000 Nathan Wiger <nate@sun.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

