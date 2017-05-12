package WebService::Scriptogram;
use base qw( WebService::Simple );
use 5.006;
use strict;
use warnings;

binmode STDOUT, ":encoding(UTF-8)";

use Carp;
use Params::Validate qw( :all );
use Readonly;

=head1 NAME

WebService::Scriptogram - Scriptogr.am API

This module provides a Perl wrapper around the Scriptogr.am ( <http://scriptogr.am> ) API.  You'll need a Scriptogr.am blog and an API key before you'll be able to do anything interesting with this module.

See <http://scriptogr.am/dashboard#api_documentation> for authoritative documentation of API calls.

=head1 VERSION

Version v0.0.2

=cut

# constants
use version; our $VERSION = 'v0.0.2';

Readonly my $SCRIPTOGRAM_API => 'http://scriptogr.am/api';

Readonly my $REGEX_APPKEY => '^[[:alnum:]]{42}$';
Readonly my $REGEX_USERID => '^[[:alnum:]]{42}$';

__PACKAGE__->config(
    base_url        => $SCRIPTOGRAM_API,
    article_url     => "$SCRIPTOGRAM_API/article/post/",
    delete_url      => "$SCRIPTOGRAM_API/article/delete/",
    response_parser => 'JSON',
    debug => 1,
);

=head1 SYNOPSIS

    use WebService::Scriptogram;

    my $sg = WebService::Scriptogram->new;

    my $text = <<TEXT;
    **Hello, World!**

    First post!

    I'm using [WebService::Scriptogram](https://github.com/hakamadare/webservice-scriptogram).
    TEXT

    my $status = $sg->article(
        app_key => 'Scriptogr.am App Key',
        user_id => 'Scriptogr.am User ID',
        name => 'My First API Post',
        text => $text,
    );

Each method corresponds to an API call; methods accept a hash of parameters, and return a hashref representing the status returned by the API (see Scriptogr.am API documentation for an explanation of status values).

=head1 METHODS

=head2 article

Post a new article or edit an existing article.  Accepts the following parameters:

=over

=item app_key

Scriptogr.am API key.  Register an application with Scriptogr.am to obtain one.

=item user_id

Scriptogr.am user ID.  Get this from the settings pane of the Scriptogr.am dashboard.

=item name

Title of the article as you would like it to appear on your blog.

=item text

(Optional) text of the article, in Markdown format.

=back

=cut

my %article_spec = (
    app_key => {
        type  => SCALAR,
        regex => qr/$REGEX_APPKEY/,
    },
    user_id => {
        type  => SCALAR,
        regex => qr/$REGEX_USERID/,
    },
    name => {
        type => SCALAR,
    },
    text => {
        optional => 1,
        type     => SCALAR,
    },
);

sub article {
    my $self = shift;

    local $self->{base_url} = $self->config->{article_url};

    my %params = validate( @_, \%article_spec );

    my $response = $self->post( \%params );

    my $status = $response->parse_response;

    return $status;
}

=head2 delete

Delete an existing article.  Accepts the following parameters:

=over

=item app_key

Scriptogr.am API key.  Register an application with Scriptogr.am to obtain one.

=item user_id

Scriptogr.am user ID.  Get this from the settings pane of the Scriptogr.am dashboard.

=item filename

Name of the file as it appears in your Dropbox folder.

=item text

(Optional) text of the article, in Markdown format.

=back

=cut

my %delete_spec = (
    app_key => {
        type  => SCALAR,
        regex => qr/$REGEX_APPKEY/,
    },
    user_id => {
        type  => SCALAR,
        regex => qr/$REGEX_USERID/,
    },
    filename => {
        type => SCALAR,
    },
);

sub delete {
    my $self = shift;

    local $self->{base_url} = $self->config->{delete_url};

    my %params = validate( @_, \%delete_spec );

    my $response = $self->post( \%params );

    my $status = $response->parse_response;

    return $status;
}

=head1 AUTHOR

Steve Huff, C<< <shuff at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-scriptogram at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Scriptogram>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Scriptogram

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Scriptogram>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Scriptogram>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Scriptogram>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Scriptogram/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to the fine folks at #crimsonfu for bringing Scriptogr.am to my attention.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Steve Huff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::Scriptogram
