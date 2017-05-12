package WebService::ConstructorIO;

use 5.006;
use strict;
use warnings;
use Moo;
with 'WebService::Client';
use Carp;
use Method::Signatures;

=head1 NAME

WebService::ConstructorIO - A Perl client for the Constructor.io API. Constructor.io provides a lightning-fast, typo-tolerant autocomplete service that ranks your users' queries by popularity to let them find what they're looking for as quickly as possible.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.04';

has api_token        => ( is => 'ro', required => 1 );
has autocomplete_key => ( is => 'ro', required => 1 );

has '+base_url'    => ( is => 'ro', default => 'https://ac.cnstrc.com' );

=head1 SYNOPSIS

    use WebService::ConstructorIO;

    my $constructorio = WebService::ConstructorIO->new(
        api_token => [your API token], # from https://constructor.io/dashboard
        autocomplete_key => [your autocomplete key]
    );
    $constructor_io->add(item_name => "item", autocomplete_section => "standard");
    $constructor_io->modify(item_name => "item", new_item_name => "new item",
      autocomplete_section => "standard");
    $constructor_io->remove(item_name => "new item");

=cut

method BUILD(...) {
  $self->ua->default_headers->authorization_basic($self->api_token);
  $self->ua->ssl_opts( verify_hostname => 0 );
}

=head1 METHODS

=head2 verify()

Verify that authentication works correctly.

=cut

method verify() {
  my $response = $self->get("/v1/verify?autocomplete_key=" . $self->autocomplete_key);
}

=head2 add( item_name => $item_name, autocomplete_section => $autocomplete_section [, suggested_score => $suggested_score, keywords => $keywords, url => $url] )

Add an item to your autocomplete index.

=cut

method add(%args) {
  my $response = $self->post("/v1/item?autocomplete_key=" . $self->autocomplete_key, \%args);
}

=head2 add_batch( items => [ { item_name => $item_name [, suggested_score => $suggested_score ] } ], autocomplete_section => $autocomplete_section )

Add multiple items to your autocomplete index.

=cut

method add_batch(%args) {
  my $response = $self->post("/v1/batch_items?autocomplete_key=" . $self->autocomplete_key, \%args);
}

=head2 add_or_update( item_name => $item_name, autocomplete_section => $autocomplete_section [, suggested_score => $suggested_score, keywords => $keywords, url => $url] )

Add an item to your autocomplete index, or update it if an existing item with the same name already exists.

=cut

method add_or_update(%args) {
  my $response = $self->put("/v1/item?force=1&autocomplete_key=" . $self->autocomplete_key, \%args);
}

=head2 add_or_update_batch( items => [ { item_name => $item_name [, suggested_score => $suggested_score ] } ], autocomplete_section => $autocomplete_section )

Add multiple items to your autocomplete index, or update them if existing items with the same names already exist.

=cut

method add_or_update_batch(%args) {
  my $response = $self->put("/v1/batch_items?force=1&autocomplete_key=" . $self->autocomplete_key, \%args);
}

=head2 remove( item_name => $item_name, autocomplete_section => $autocomplete_section )

Remove an item from your autocomplete index.
=cut

method remove(%these_args) {
  my $path = "/v1/item?autocomplete_key=" . $self->autocomplete_key;

  my %args = ();
  my $headers = $self->_headers(\%args);
  my $url = $self->_url($path);
  my %content = $self->_content(\%these_args, %args);
  my $req = HTTP::Request->new(
      'DELETE', $url, [%$headers], $content{content}
  );
  $self->req($req, %args);
}

=head2 modify( item_name => $item_name, new_item_name => $new_item_name, autocomplete_section => $autocomplete_section [, suggested_score => $suggested_score, keywords => $keywords, url => $url] )

Modify an item in your autocomplete index.

=cut

method modify(%args) {
  my $response = $self->put("/v1/item?autocomplete_key=" . $self->autocomplete_key, \%args);
}

=head2 track_search( term => $term [, num_results => $num_results ] )

Track a customer search.

=cut

method track_search(%args) {
  my $response = $self->post("/v1/search?autocomplete_key=" . $self->autocomplete_key, \%args);
}

=head2 track_click_through( term => $term, autocomplete_section => $autocomplete_section [, item => $item ] )

Track a customer click-through.

=cut

method track_click_through(%args) {
  my $response = $self->post("/v1/click_through?autocomplete_key=" . $self->autocomplete_key, \%args);
}

=head2 track_conversion( term => $term, autocomplete_section => $autocomplete_section [, item => $item, revenue => $revenue ] )

Track a customer conversion.

=cut

method track_conversion(%args) {
  my $response = $self->post("/v1/conversion?autocomplete_key=" . $self->autocomplete_key, \%args);
}

=head1 AUTHOR

Dan McCormick, C<< <dan at constructor.io> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-constructorio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-ConstructorIO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::ConstructorIO


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-ConstructorIO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-ConstructorIO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-ConstructorIO>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-ConstructorIO/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Constructor.io

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

1; # End of WebService::ConstructorIO
