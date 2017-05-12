package WebService::POEditor;

# ABSTRACT: POEditor.com API wrapper

use Moose;
with 'Role::REST::Client';
use MooseX::Attribute::ENV;
use WebService::POEditor::Response;

use version; our $VERSION = version->new('v1.1.0');
use namespace::clean;


has api_token => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    traits   => ['ENV'],
    env_key  => 'POEDITOR_API_TOKEN',
);


has server => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://poeditor.com/api',
    traits  => ['ENV'],
    env_key => 'POEDITOR_API_SERVER',
);

#--------------------------------------------------------------------------#
# private attributes
#--------------------------------------------------------------------------#

## overload Role::REST::Client defaults
has '+type' => (default => 'application/x-www-form-urlencoded');

has _api_methods => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    lazy    => 1,
    builder => '_build__api_methods',
    handles => {
        api_methods    => 'uniq',
        add_api_method => 'push',
    },
);

sub _build__api_methods {
    my $self = shift;

    return [
        qw/
            list_projects
            create_project
            view_project
            list_languages
            add_language
            delete_language
            set_reference_language
            clear_reference_language
            view_terms
            add_terms
            delete_terms
            sync_terms
            update_language
            export
            upload
            available_languages
            list_contributors
            add_contributor
            /
    ];
}

has _api_method_handler => (
    is      => 'ro',
    isa     => 'CodeRef',
    traits  => ['Code'],
    lazy    => 1,
    builder => '_build__api_method_handler',
    handles => { _handle_api_method => 'execute_method' });

sub _build__api_method_handler {
    my $self = shift;

    return sub {
        my ($self, $method, $params) = @_;

        my $res = $self->post(
            '/',
            {   api_token => $self->api_token,
                action    => $method,
                %{ $params || {} },
            },
        );

        return WebService::POEditor::Response->new(
            res    => $res,
            method => $method,
        );
    };
}


sub BUILD {
    my ($self,) = @_;

    foreach my $method ($self->api_methods) {
        $self->meta->add_method(
            $method => sub {
                my ($self, @args) = @_;
                return $self->_handle_api_method($method, @args);
            });
    }

    return 1;
}


1;    ## eof

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::POEditor - POEditor.com API wrapper

=head1 VERSION

version v1.1.0

=head1 SYNOPSIS

  use WebService::POEditor;

  my $poeditor = WebService::POEditor->new(api_token => 'XYZ');

  ## get a list of projects
  my $res = $poeditor->list_projects;
  my @projects = $res->list;

  ## create a project
  my $res = $poeditor->create_project({ name => 'Project X' });
  print $res->message if $res->code == 200; ## Project created.

=head1 ATTRIBUTES

=head2 api_token

Set API token L<obtained from POEditor.com|https://poeditor.com/account/api>.

Alternatively, API token can be set via environment variable C<POEDITOR_API_TOKEN>.

=head2 server

API server URL.

Can also be altered via environment variable C<POEDITOR_API_SERVER>.

Default: https://poeditor.com/api

=head1 METHODS

=head2 API methods

The following API methods (actions) are currently supported:

    add_contributor
    add_language
    add_terms
    available_languages
    clear_reference_language
    create_project
    delete_language
    delete_terms
    export
    list_contributors
    list_languages
    list_projects
    set_reference_language
    sync_terms
    update_language
    upload
    view_project
    view_terms

The method either takes no arguments (e.g. for listings), or takes one HashRef
as an argument (e.g. for creation of objects).

The return value is always an instance of L<WebService::POEditor::Response> object.

=head1 AUTHOR

Roman F. <romanf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Roman F..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
