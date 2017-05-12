package WebService::Wedata;

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use JSON::XS;
use WebService::Wedata::Database;

use version; our $VERSION = qv('0.0.4');
our $URL_BASE = 'http://wedata.net';

sub new {
    my($class, $api_key) = @_;
    bless {
        ua => LWP::UserAgent->new,
        api_key => $api_key,
    }, $class;
}

sub get_databases {
    my($self) = @_;
    $self->get_database;
}

sub get_database {
    my($self, $dbname, $page) = @_;
    my $path = ($dbname) ? "/databases/$dbname.json" : '/databases.json';
    $page ||= '';
    my $url = $URL_BASE . $path;
    my $response = $self->{ua}->get($url, page => $page);
    if ($response->is_success) {
        my $data = decode_json($response->content);
        my $parse_response = sub {
            my($data) = @_;
            my @required_keys = split / /, $data->{required_keys};
            my @optional_keys = (defined $data->{optional_keys}) ? split / /, $data->{optional_keys} : ();
            my $database = WebService::Wedata::Database->new(
                ua => $self->{ua},
                api_key => $self->{api_key},
                name => $data->{name},
                description => $data->{description},
                resource_url => $data->{resource_url},
                required_keys => [@required_keys],
                optional_keys => [@optional_keys],
                permit_other_keys => $data->{permit_other_keys},
            );
            $database;
        };
        if ($dbname) {
            $parse_response->($data);
        }
        else {
            my $result = [];
            foreach my $db (@$data) {
                push @$result, $parse_response->($db);
            }
            $result;
        }
    }
    else {
        croak 'Faild to get_database:' . $response->status_line;
    }
}

sub create_database {
    my($self, @params) = @_;
    my $params = {@params};
    croak "require name on create_database\n" unless $params->{name};

    my $param_description = $params->{description} || '';
    my $param_required_keys = join '%20', @{$params->{required_keys}};
    my $param_optional_keys = join '%20', @{$params->{optional_keys}};
    my $param_permit_other_keys = ($params->{permit_other_keys}) ? 'true' : 'false';

    my $url = $URL_BASE . '/databases';
    my $content = '';
    $content = join '&',
        "api_key=$self->{api_key}",
        "database[name]=$params->{name}",
        "database[description]=$param_description",
        "database[required_keys]=$param_required_keys",
        "database[optional_keys=$param_optional_keys",
        "database[permit_other_keys]=$param_permit_other_keys"
    ;
    my $req = HTTP::Request->new(
        POST => $url,
        HTTP::Headers->new(
            'content-type' => 'application/x-www-form-urlencoded',
            'content-length' => length($content),
        ),
        $content,
    );

    my $response = $self->{ua}->request($req);
    if ($response->is_success) {
        my $database = WebService::Wedata::Database->new(
            ua => $self->{ua},
            api_key => $self->{api_key},
            name => $params->{name},
            description => $params->{description},
            required_keys => $params->{required_keys},
            optional_keys => $params->{optional_keys},
            permit_other_keys => ($params->{permit_other_keys} == 1) ? 1 : 0,
            resource_url => $response->header('location'),
        );
        $database;
    }
    else {
        croak 'Faild to create_database:' . $response->status_line;
    }
}

sub update_database {
    my($self, @params) = @_;
    my $params = {@params};
    croak "require name on create_database\n" unless $params->{name};

    $params->{api_key} = $self->{api_key};
    $params->{resource_url} = $URL_BASE . '/databases/' . $params->{name};
    my $req = WebService::Wedata::Database::_make_update_request($params);

    my $response = $self->{ua}->request($req);
    if ($response->is_success) {
        $self->get_database($params->{name});
    }
    else {
        croak 'Faild to update_database:' . $response->status_line;
    }
}

sub delete_database {
    my($self, @params) = @_;
    my $params = {@params};
    croak "require name on create_database\n" unless $params->{name};

    $params->{api_key} = $self->{api_key};
    my $req = WebService::Wedata::Database::_make_delete_request($params);
    my $response = $self->{ua}->request($req);
    if ($response->is_success) {
        return;
    }
    else {
        croak 'Faild to delete_database:' . $response->status_line;
    }
}


1; # Magic true value required at end of module
__END__

=head1 NAME

WebService::Wedata - Perl Interface for wedata.net


=head1 VERSION

This document describes WebService::Wedata version 0.0.4


=head1 SYNOPSIS

    use WebService::Wedata;
    
    my $wedata = WebService::Wedata->new('YOUR_API_KEY');
    my $database = $wedata->create_database(
        name => 'database_name',
        required_keys => [qw/foo bar baz/],
        optional_keys => [qw/hoge fuga/],
        permit_other_keys => 'true,'
    );
    
    my $item = $database->create_item(
        name => 'item_name',
        data => {
            foo => 'foo_value',
            bar => 'bar_value',
            baz => 'baz_value',
        }
    );
    $item->update(
        foo => 'foo_updated_value',
        bar => 'bar_updated_value',
        baz => 'baz_updated_value',
    );
    
    $item->delete;
    $database->delete;
  
=head1 DESCRIPTION

Perl Interface for wedata.net

=head1 METHODS

=head2 new

=over 4

=item Arguments: $api_key

=item Return Value: $wedata_instance

=back

Constructor.


=head2 get_databases

=over 4

=item Arguments: none

=item Return Value: @databases

=back

Get all databases.


=head2 get_database

=over 4

=item Arguments: $dbname, $page

=item Return Value: $database

=back

Get specified database. Return value is instance of WebService::Wedata::Database.


=head2 create_database

=over 4

=item Arguments: %params(name, description, required_keys, optional_keys, permit_other_keys)

=item Return Value: $database

=back

Create databse. Return value is instance of WebService::Wedata::Database.


=head2 update_database

=over 4

=item Arguments: %params(name, description, required_keys, optional_keys, permit_other_keys)

=item Return Value: $database

=back

Update databse. Return value is instance of WebService::Wedata::Database.


=head2 delete_database

=over 4

=item Arguments: %params(name)

=item Return Value: none

=back

Delte database.


=head1 DEPENDENCIES

LWP::UserAgent
JSON::XS


=head1 AUTHOR

Tsutomu KOYACHI  C<< <rtk2106@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Tsutomu KOYACHI C<< <rtk2106@gmail.com> >>. All rights reserved.

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

=head1 SEE ALSO

L<http://wedata.net/help/api>

=cut
