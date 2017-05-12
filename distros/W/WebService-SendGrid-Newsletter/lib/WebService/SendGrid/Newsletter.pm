use strict;
use warnings;
package WebService::SendGrid::Newsletter;

# ABSTRACT: Perl interface to SendGrid Newsletter API
our $VERSION = '0.02'; # VERSION

use HTTP::Request::Common;
use JSON;
use HTTP::Tiny;

use WebService::SendGrid::Newsletter::Lists;
use WebService::SendGrid::Newsletter::Recipients;
use WebService::SendGrid::Newsletter::Schedule;
use WebService::SendGrid::Newsletter::Identity;
use WebService::SendGrid::Newsletter::Categories;
use parent 'WebService::SendGrid::Newsletter::Base';


sub new {
    my ($class, %args) = @_;

    my $self = {};
    bless($self, $class);

    $self->_check_required_args([ qw( api_user api_key ) ], %args);

    $self->{api_user} = $args{api_user};
    $self->{api_key} = $args{api_key};
    
    $self->{ua} = HTTP::Tiny->new;
    $self->{ua}->agent(__PACKAGE__ . '/' .
        ($__PACKAGE__::VERSION || 0) . ' (Perl)');

    $self->{json_options} = $args{json_options};

    $self->{last_response} = undef;
    $self->{last_response_code} = undef;
    
    if (exists $args{identity}) {
        $self->{identity} = $args{identity};
    }
    
    return $self;
}

# Sends a request to SendGrid Newsletter API
sub _send_request {
    my ($self, $path, %args) = @_;

    my $params = { api_user => $self->{api_user}, api_key => $self->{api_key}, %args };

    my $url = 'https://api.sendgrid.com/api/newsletter/' . $path . '.json';

    my $response = $self->{ua}->post_form($url, $params);

    $self->{last_response_code} = $response->{status};
    $self->{last_response} = decode_json $response->{content};

    return $response->{success};
}


sub get {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name ) ], %args);

    if ($self->_send_request('get', %args)) {
        return $self->{last_response};
    }
    else {
        return;
    }
}


sub add {
    my ($self, %args) = @_;

    if (!exists $args{identity}) {
        $args{identity} = $self->{identity};
    }

    $self->_check_required_args([ qw( identity name subject text html ) ],
        %args);

    return $self->_send_request('add', %args);
}


sub edit {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name newname identity subject text
        html ) ], %args);

    return $self->_send_request('edit', %args);
}


sub list {
    my ($self, %args) = @_;

    if ($self->_send_request('list', %args)) {
        return $self->{last_response};
    }
    else {
        return;
    }
}


sub delete {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name ) ], %args);

    return $self->_send_request('delete', %args);
}


sub lists {
    my ($self) = @_;

    if (!defined $self->{lists}) {
        $self->{lists} = WebService::SendGrid::Newsletter::Lists->new(
            sgn => $self
        );
    }

    return $self->{lists};
}


sub recipients {
    my ($self) = @_;

    if (!defined $self->{recipients}) {
        $self->{recipients} =
            WebService::SendGrid::Newsletter::Recipients->new(sgn => $self);
    }

    return $self->{recipients};
}


sub schedule {
    my ($self) = @_;

    if (!defined $self->{schedule}) {
        $self->{schedule} =
            WebService::SendGrid::Newsletter::Schedule->new(sgn => $self);
    }

    return $self->{schedule};
}


sub identity {
    my ($self) = @_;

    if (!defined $self->{identity}) {
        $self->{identity} =
            WebService::SendGrid::Newsletter::Identity->new(sgn => $self);
    }

    return $self->{identity};
}


sub categories {
    my ($self) = @_;

    if (!defined $self->{categories}) {
        $self->{categories} =
            WebService::SendGrid::Newsletter::Categories->new(sgn => $self);
    }

    return $self->{categories};
}


sub last_response_code {
    my ($self) = @_;

    return $self->{last_response_code};
}


sub last_response {
    my ($self) = @_;

    return $self->{last_response};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid::Newsletter - Perl interface to SendGrid Newsletter API

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $sgn = WebService::SendGrid::Newsletter->new(api_user => 'user',
                                                    api_key => 'SeCrEtKeY'
                                                    identity => 'johndoe');

    # Create a new recipients list
    $sgn->lists->add(list => 'subscribers', name => 'name');

    # Add a recipient to the list
    $sgn->lists->email->add(list => 'subscribers',
                            data => { name => 'Tom', email => 'tom@foo.com' });

    # Create a new newsletter
    $sgn->add(identity => 'johndoe',
              name => 'first newsletter',
              subject => 'Your weekly newsletter',
              text => 'Hello, this is your weekly newsletter',
              html => '<h1>Hello</h1><p>This is your weekly newsletter</p>');

    # Assign recipients list to the newsletter
    $sgn->recipients->add(name => 'first newsletter', list => 'subscribers');

    # Schedule the newsletter to be sent in 30 minutes
    $sgn->schedule->add(name => 'first newsletter', after => 30);

=head1 METHODS

=head2 new

Creates a new instance of WebService::SendGrid::Newsletter.

    my $sgn = WebService::SendGrid::Newsletter->new(api_user => 'user',
                                                    api_key => 'SeCrEtKeY');

Parameters:

=over 4

=item * C<api_user>

=item * C<api_key>

=item * C<json_options>

=back

=head2 get

Retrieves an existing newsletter.

Parameters:

=over 4

=item * C<name>

B<(Required)> The name of the newsletter to retrieve.

=back

=head2 add

Creates a new newsletter.

Parameters:

=over 4

=item * C<identity>

B<(Required)> The identity that will be assigned to this newsletter. Can be
omitted if it was given as an argument when the
WebService::SendGrid::Newsletter instance was created.

=item * C<name>

B<(Required)> The name of the newsletter.

=item * C<subject>

B<(Required)> The subject line of the newsletter.

=item * C<text>

B<(Required)> The text contents of the newsletter.

=item * C<html>

B<(Required)> The HTML contents of the newsletter.

=back

=head2 edit

Modifies an existing newsletter.

Parameters:

=over 4

=item * C<identity>

B<(Required)> The identity that will be assigned to this newsletter.

=item * C<name>

B<(Required)> The existing name of the newsletter.

=item * C<newname>

B<(Required)> The new name of the newsletter.

=item * C<subject>

B<(Required)> The subject line of the newsletter.

=item * C<text>

B<(Required)> The text contents of the newsletter.

=item * C<html>

B<(Required)> The HTML contents of the newsletter.

=back

=head2 list

Retrieves a list of all newsletters.

Parameters:

=over 4

=item * C<name>

Newsletter name. If provided, the call checks if the specified newsletter
exists.

=back

=head2 delete

Deletes a newsletter.

Parameters:

=over 4

=item * C<name>

B<(Required)> The name of the newsletter to delete.

=back

=head2 lists

Returns an instance of L<WebService::SendGrid::Newsletter::Lists>, which is used
to manage recipient lists.

=head2 recipients

Returns an instance of L<WebService::SendGrid::Newsletter::Recipients>, which
allows to assign recipient lists to newsletters.

=head2 schedule

Returns an instance of L<WebService::SendGrid::Newsletter::Schedule>, which is
used to schedule a delivery time for a newsletter.

=head2 identity

Returns an instance of L<WebService::SendGrid::Newsletter::Identity>, which is
used to manipulate address of sender.

=head2 categories

Returns an instance of L<WebService::SendGrid::Newsletter::Categories>, which
creates and manages categories within newsletters

=head2 last_response_code

Returns the code of the last response from the API.

=head2 last_response

Returns the data structure retrieved with the last response from the API.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/Sidnet/p5-WebService-SendGrid-Newsletter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/Sidnet/p5-WebService-SendGrid-Newsletter>

  git clone https://github.com/Sidnet/p5-WebService-SendGrid-Newsletter.git

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Michal Wojciechowski Michał Pattawan Kaewduangdee oiami

=over 4

=item *

Michal Wojciechowski <odyniec@odyniec.net>

=item *

Michał Wojciechowski <odyniec@odyniec.eu.org>

=item *

Pattawan Kaewduangdee <pattawan.kaewduangdee@sidnet.info>

=item *

Pattawan Kaewduangdee <pattawanna@gmail.com>

=item *

oiami <pattawanna@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
