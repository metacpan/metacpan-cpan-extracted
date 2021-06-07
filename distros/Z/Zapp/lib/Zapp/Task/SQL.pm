package Zapp::Task::SQL;
use Mojo::Base 'Zapp::Task', -signatures;
use Mojo::File qw( tempdir tempfile );

sub schema( $class ) {
    return {
        input => {
            type => 'object',
            required => [qw( sql )],
            properties => {
                dsn => {
                    type => 'string',
                },
                username => {
                    type => 'string',
                },
                password => {
                    type => 'string',
                    format => 'password',
                },
                sql => {
                    type => 'string',
                    format => 'textarea',
                },
            },
        },
        output => {
            type => 'object',
            required => [qw( rows count )],
            properties => {
                rows => {
                    type => 'array',
                    items => {
                        type => 'object',
                        additionalProperties => {
                            type => 'string',
                        },
                    },
                },
                count => {
                    type => 'integer',
                },
            },
        },
    };
}

sub run( $self, $input ) {
    my $dbh = DBI->connect( $input->@{qw( dsn username password )} );
    my $rows = $dbh->selectall_arrayref( $input->{sql}, { Slice => {} } );
    $self->finish({
        rows => $rows,
        count => scalar @$rows,
    });
}

1;

=pod

=head1 NAME

Zapp::Task::SQL

=head1 VERSION

version 0.004

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ input.html.ep
% my $input = stash( 'input' ) // { script => '' };
<div class="form-group">
    <label for="dsn">Data Source Name (DSN)</label>
    %= text_field dsn => $input->{dsn}, class => 'form-control'
</div>
<div class="form-row">
    <div class="form-group">
        <label for="username">Username</label>
        %= text_field username => $input->{username}, class => 'form-control'
    </div>
    <div class="form-group">
        <label for="password">Password</label>
        %= text_field password => $input->{password}, class => 'form-control'
    </div>
</div>
<div class="form-group">
    <label for="sql">SQL</label>
    <div class="grow-wrap">
        <!-- XXX: support markdown -->
        <%= text_area "sql", $input->{sql},
            oninput => 'this.parentNode.dataset.replicatedValue = this.value',
            placeholder => 'SQL',
        %>
    </div>
</div>

@@ output.html.ep
% if ( my @rows = @{ $task->{output}{rows} // [] } ) {
<table class="table table-striped table-hover">
    % my @cols = sort keys %{ $rows[0] };
    <thead>
        <tr>
            % for my $col ( @cols ) {
            <th><%= $col %></th>
            % }
        </tr>
    </thead>
    <tbody>
        % for my $row ( @rows ) {
        <tr>
            % for my $col ( @cols ) {
            <td><%= $row->{ $col } %></td>
            % }
        </tr>
    % }
    </tbody>
</table>
% }

%= include 'zapp/more_info', id => "task-$task->{task_id}", content => begin
    <h4>SQL</h4>
    <pre class="m-1 border p-1 rounded bg-light"><code><%= $task->{input}{sql} %></code></pre>
% end
