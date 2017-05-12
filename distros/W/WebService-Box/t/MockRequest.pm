package t::MockRequest;

package WebService::Box::Request;

no warnings 'redefine';

use Data::Dumper;

sub do {
    my $self   = shift;
    my %params = @_;

    my $action = delete $params{action};

    my $key = join ':', map{ $_, $params{$_} }sort keys %params;

    return %{ _returns($key) || {} };
}


sub _returns {
    my $key = shift;

    my %returns = (
        'id:1:ressource:folders' => {
            "type"        => "folder",
            "id"          => "301415432",
            "sequence_id" => "0",
            "name"        => "folder_1",
        },
        'id:123:ressource:files' => {
            "type"        => "file",
            "id"          => "123",
            "sequence_id" => "0",
            "name"        => "file_123",
            "parent_data" => {
                type        => 'folder',
                id          => 1,
                sequence_id => '0',
                name        => 'folder_1',
                etag        => undef,
            },
        },
        'id:88:ressource:files' => {
            "type"        => "file",
            "id"          => "88",
            "sequence_id" => "0",
            "name"        => "file_88",
            "created_at"  => '2013-09-13T12:45:25',
            "parent_data" => {
                type        => 'folder',
                id          => 1,
                sequence_id => '0',
                name        => 'folder_1',
                etag        => undef,
            },
        },
        'id:89:ressource:files' => {
            "type"        => "file",
            "id"          => "89",
            "sequence_id" => "0",
            "name"        => "file_89",
            "created_at"  => '2013-09-13T12:45:25',
            "parent_data" => {
                type        => 'folder',
                id          => 1,
                sequence_id => '0',
                name        => 'folder_1',
                etag        => undef,
            },
        },
    );

    return $returns{$key};
}

1;
