package WebService::Leanpub;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.3.0');

use HTTP::Request::Common;
use JSON;
use LWP::UserAgent;
use URI::Escape;

# Module implementation here

my $lpurl = 'https://leanpub.com/';

sub new {
    my ($self, $api_key, $slug) = @_;
    my $type = ref($self) || $self;

    unless ($api_key) { die "Missing API key for Leanpub"; }
    unless ($slug)    { die "Missing SLUG for book"; }

    $self = bless {}, $type;

    $self->{api_key} = uri_escape($api_key);
    $self->{slug}    = uri_escape($slug);
    $self->{ua}      = LWP::UserAgent->new(
	agent => "libwebservice-leanpub-perl/$VERSION",
    );
    $self->{json}    = JSON->new;

    return $self;
} # new()

#----- coupons -----
sub create_coupon {
    my ($self,$opt) = @_;

    unless ($opt->{coupon_code})	{ return; }
    unless ($opt->{discounted_price})	{ return; }
    unless ($opt->{start_date})		{ return; }

    my $var = {
	'coupon[coupon_code]'	   => $opt->{coupon_code},
	'coupon[discounted_price]' => $opt->{discounted_price},
	'coupon[start_date]'	   => $opt->{start_date},
    };
    
    if ($opt->{end_date}) {
	$var->{'coupon[end_date]'} = $opt->{end_date};
    }
    if ($opt->{has_uses_limit}) {
	$var->{'coupon[has_uses_limit]'} = $opt->{has_uses_limit};
    }
    if ($opt->{max_uses}) {
	$var->{'coupon[max_uses]'} = $opt->{max_uses};
    }
    if ($opt->{note}) {
	$var->{'coupon[note]'} = $opt->{note};
    }
    if ($opt->{suspended}) {
	$var->{'coupon[suspended]'} = $opt->{suspended};
    }
    return $self->_post_request( { path => '/coupons.json', var => $var } );
} # create_coupon()

sub get_coupon_list {
    my ($self) = @_;

    return $self->_get_request( { path => '/coupons.json' } );

} # get_coupon_list()

sub update_coupon {
    my ($self,$opt) = @_;

    unless ($opt->{coupon_code})    { return; }

    my $cc = delete $opt->{coupon_code};
    my $path = "/coupons/$cc.json";

    _wash_coupon_opts($opt);
    my $content = encode_json( $opt );

    return $self->_put_request( { path => $path, content => $content } );
} # update_coupon()

sub _wash_coupon_opts {
    my $opt = $_[0];
    my $bool = sub {
	return ($_[0] =~/^(no|false|0)$/i) ? 'false' : 'true';
    };
    if (exists $opt->{suspended}) {
	$opt->{suspended} = $bool->($opt->{suspended});
    }
    if (exists $opt->{has_uses_limit}) {
	$opt->{has_uses_limit} = $bool->($opt->{has_uses_limit});
    }
} # _wash_coupon_opts;

#----- sales -----

sub get_individual_purchases {
    my ($self,$opt) = @_;
    my $req = { path => '/individual_purchases.json' };
    $req->{var} = { page => $opt->{page} } if ($opt->{page});
    return $self->_get_request($req);

} # get_individual_purchases()

sub get_sales_data {
    my ($self) = @_;

    return $self->_get_request( { path => '/sales.json' } );

} # get_sales_data()

#----- jobs -----

sub get_job_status {
    my ($self) = @_;

    return $self->_get_request( { path => '/book_status.json' } );

} # get_job_status()

sub partial_preview {
    my ($self) = @_;

    return $self->_post_request( { path => '/preview/subset.json' } );
} # partial_preview()

sub preview {
    my ($self) = @_;

    return $self->_post_request( { path => '/preview.json' } );
} # preview()

sub publish {
    my ($self,$opt) = @_;
    my $var = {};

    if ($opt->{email_readers}) {
	$var->{'publish[email_readers]'} = 'true';
    }
    if (exists $opt->{release_notes}) {
	$var->{'publish[release_notes]'} = $opt->{release_notes};
    }
    return $self->_post_request( { path => '/publish.json', var => $var } );
} # publish()

sub single {
    my ($self,$opt) = @_;

    if ($opt->{content}) {
	my $json = JSON->new->encode({ 'content' => $opt->{content} });
	return $self->_json_post_request({ path => '/preview/single.json'
					 , content => $json });
    }
    else {
	return;
    }
} # single()

sub subset {
    my ($self) = @_;

    return $self->_post_request( { path => '/preview/subset.json' } );
} # subset()

sub summary {
    my ($self) = @_;

    return $self->_get_request( { path => '.json' } );
} # summary()

#----- JSON functions -----
sub pretty_json {
    my $json = $_[0]->{json};
    return $json->pretty->encode($json->decode($_[1]));
} # pretty_json()
#----- helper functions -----

sub _get_request {
    my ($self,$opt) = @_;

    my $url = $lpurl . $self->{slug} . $opt->{path}
            . '?api_key=' . $self->{api_key};
    if ($opt->{var}) {
	foreach my $var (keys %{$opt->{var}}) {
	    $url .= "&$var=" . uri_escape($opt->{var}->{$var});
	}
    }
    my $res = $self->{ua}->get($url);

    if ($res->is_success) {
	return $res->decoded_content;
    }
    return;
} # _get_request()

sub _json_post_request {
    my ($self,$opt) = @_;
    my $url  = $lpurl . $self->{slug} . $opt->{path}
             . '?api_key=' .  $self->{api_key};
    my @args = (
	'Content_Type' => 'application/json; charset=utf-8',
	'Content'      => $opt->{content},
    );
    my $res = $self->{ua}->post($url, @args);

    if ($res->is_success) {
	return $res->decoded_content;
    }
} # _json_post_request()

sub _post_request {
    my ($self,$opt) = @_;
    my $url  = $lpurl . $self->{slug} . $opt->{path};
    my $form = { api_key => $self->{api_key}, };

    if ($opt->{var}) {
	foreach my $var (keys %{$opt->{var}}) {
	    $form->{$var} = $opt->{var}->{$var};
	}
    }
    my $res = $self->{ua}->post($url, $form);

    if ($res->is_success) {
	return $res->decoded_content;
    }
    return;
} # _post_request()

sub _put_request {
    my ($self,$opt) = @_;
    my $url = $lpurl . $self->{slug} . $opt->{path}
            . '?api_key=' . $self->{api_key};

    my $req = HTTP::Request::Common::PUT($url,
	                                 'Content-Type' => 'application/json',
	                                 'Content' => $opt->{content});
    my $res = $self->{ua}->request($req);
    if ($res->is_success) {
	return $res->decoded_content;
    }
    return;
} # _put_request();

1; # Magic true value required at end of module
__END__

=head1 NAME

WebService::Leanpub - Access the Leanpub web API.


=head1 VERSION

This document describes WebService::Leanpub version 0.0.1


=head1 SYNOPSIS

    use WebService::Leanpub;

    my $wl = WebService::Leanpub->new($api_key, $slug);

    $wl->get_individual_purchases( { slug => $slug } );

    $wl->get_job_status( { slug => $slug } );

    $wl->preview();

    $wl->subset();

    $wl->get_sales_data( { slug => $slug } );

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=head2 new($api_key, $slug)

Create a new WebService::Leanpub object.

Since you need an API key to access any function of the Leanpub API, you have
to give that API key as an argument to C<new()>.

The same holds for the I<slug> which is the part of the Leanpub URL denoting
your book. For instance if your books URL was
C<< https::/leanpub.com/your_book >>, the slug woud be I<your_book>.

=head2 get_individual_purchases()

=head2 get_individual_purchases( $opt )

Get the data for individual purchases.

Optionally this method takes as argument a hash reference with this key:

=over

=item C<< page >>

the page of the individual purchases data.

=back

=head2 get_job_status()

Get the status of the last job.

=head2 get_sales_data()

Get the sales data.

=head2 partial_preview()

Start a partial preview of your book using Subset.txt.

=head2 subset()

Start a partial preview of your book using Subset.txt.

=head2 preview()

Start a preview of your book.

=head2 single( $opt )

Generate a preview of a single file.

The argument C<$opt> is a hash reference with the following keys and values:

=over

=item content

The content of the file in a scalar string.

=back

=head2 publish( $opt )

This will publish your book without emailing your readers.

The argument C<$opt> is a hash reference with the following keys:

=over

=item email_readers

If the corresponding value evaluates to I<true>, an email is sent to the
readers.

=item release_notes

The value corresponding to this key is sent as release note.

=back

=head2 create_coupon( $opt )

Create a coupon.

The argument C<$opt> is a hash reference with the following keys:

=over

=item coupon_code

Required.
The coupon code for this coupon. This must be unique for the book.

=item discounted_price

Required.
The amount the reader will pay when using the coupon.

=item start_date

Required.
The date the coupon is valid from. Formatted like YYYY-MM-DD.

=item end_date

The date the coupon is valid until. Formatted like YYYY-MM-DD.

=item has_uses_limit

Whether or not the coupon has a uses limit.

Values '0', 'false', 'no' count as false, all other values as true.

=item max_uses

The max number of uses available for a coupon. An integer.

=item note

A description of the coupon. This is just used to remind you of what it was
for.

=item suspended

Whether or not the coupon is suspended.

Values '0', 'false', 'no' count as false, all other values as true.

=back

=head2 update_coupon( $opt )

Update a coupon.

Takes the same argumentes for C<$opt>) as I<create_coupon()> but only the key
C<coupon_code> is required, all others are optional.

=head2 get_coupon_list()

Returns a list of the coupons for the book formatted as JSON.

=head2 pretty_json( $json )

This is just a convenience function for pretty printing the output of the
C<get_*()> functions.

=head2 summary()

This returns information about the book.

Since this API function does not need an API key, this is the only method that
returns meaningful data if you provide a wrong API key.

=head1 DIAGNOSTICS

=over

=item C<< Missing API key for Leanpub >>

Since the Leanpub API only works with an API key from leanpub.com, you have to
provide an API key as first argument to WebService::Leanpub->new().

=item C<< Missing SLUG for book >>

Since every action in the Leanpub API involves a book which is identified by a
slug, you have to provide the slug as the second argument to
WebService::Leanpub->new().

A slug is the part after the hostname in the Leanpub URL of your book. So for
instance for the Book "Using the Leanpub API with Perl" which has the URL
L<< https://leanpub.com/using-the-leanpub-api-with-perl >> the slug is
C<using-the-leanpub-api-with-perl>.

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
WebService::Leanpub requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-leanpub@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Mathias Weidner  C<< <mamawe@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Mathias Weidner C<< <mamawe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
