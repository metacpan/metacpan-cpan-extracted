package WWW::HarWalk;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp qw(croak);
use JSON;
use HTTP::Request;
use base qw(Exporter);

=head1 NAME

WWW::HarWalk - Replay HTTP requests from HAR ( HTTP Archive ) file

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

our @EXPORT_OK = qw(walk_har);

=head1 SYNOPSIS

    use LWP::UserAgent;
    use WWW::HarWalk qw(walk_har);
    
    my $ua = LWP::UserAgent->new;

    # simple usage
    walk_har($ua, 'c.lietou.com.har');
    
    # with hooks
    walk_har($ua,                 # a LWP::UserAgent instance
         'c.lietou.com.har',      # har file path
         sub {
             my $entry = shift;   # entries item in har
             
             # request of the entry item. Note: this is not the HTTP::Request instance
             my $request = $entry->{request};
             
             # return false to skip this entry
             return 0 if $request->{url} =~ /\.(?:gif|png|css|js)(?:\?.*)?$/;
             
             # modify post params
             if ($request->{url} =~ /login.php/) {
                 $request->{postData}->{text} =~ s/username=\w+/username=Tom/;
             }
             
             # must return true to request this entry
             return 1;
         },
         sub {
             # $res is a HTTP::Response intance, decoded
             my ($entry, $res, $entries) = @_;
             
             # you can print or capture something from some response
             if ($entry->{request}->{url} =~ /refreshresume/) {
                 print $res->content, "\n";
             }
         });

=head1 EXPORT

walk_har

=head1 SUBROUTINES/METHODS

=head2 walk_har($ua, $har_file, $before_sub, $after_sub)

Walk through all the entries in the HAR file, and issue each request.

The first two arguments is required. The $ua is a LWP::UserAgent instance, you can do some configuration first, eg: set timeout. $har_file is the HAR file you recorded.

The last two arguments are for hooks. In the before hook you can decide wheather this request shall be sent, you can return false to skip some unnessary request, such as images, css, etc. You can modify the $entry here. Eg: you can change the username and password in the postData to replay twitter requests with another user. The prototype of the before hook is:

    sub {
        my ($entry) = @_;
        return 1;
    }

The after hook is for people to get some information from the response. Eg: get some link to download and push them into @$entries. It is prototype is :

    sub {
        my ($entry, $res, $entries) = @_;
    }

The $entry is the item in the entries array in the HAR file ( log -> entries ). The $res is a decoded HTTP::Response instance.

=cut

sub walk_har {
    my ($ua, $harfile, $before_sub, $after_sub) = @_;
    open my $fh, $harfile or croak "can not open harfile for read " . $!;
    my $content;
    {
        local $/;
        $content = <$fh>;
    }
    close $fh;
    my $json = JSON->new->utf8;
    my $o = $json->decode($content);
    while (my $entry = shift @{$o->{log}->{entries}}) {
        my $request = $entry->{request};
        if ($before_sub && ref $before_sub eq 'CODE') {
            my $rv = $before_sub->($entry);
            next unless $rv;
        }
        my $method = $request->{method};
        my $url = $request->{url};
        my $headers = $request->{headers};
        my $req = HTTP::Request->new($method, $url);
        for my $h (@$headers) {
            $req->header($h->{name}, $h->{value});
        }
        if (defined $request->{postData}) {
            $req->content($request->{postData}->{text});
        }
        my $res = $ua->request($req);
        $res->decode;
        if ($after_sub && ref $after_sub eq 'CODE') {
            $after_sub->($entry, $res, $o->{log}->{entries});
        }
    }
}


=head1 AUTHOR

Achilles Xu, C<< <xudaye at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-harwalk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-HarWalk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

HAR Specifiction: L<http://www.softwareishard.com/blog/har-12-spec/>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::HarWalk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-HarWalk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-HarWalk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-HarWalk>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-HarWalk/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Achilles Xu.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WWW::HarWalk
