package Zapp::Task::Script;
# ABSTRACT: Run a Script

#pod =head1 DESCRIPTION
#pod
#pod This task executes arbitrary scripts. By default, they are run as
#pod scripts for the current shell. With a shebang line (e.g.
#pod C<#!/usr/bin/perl>), any arbitrary interpreter can be invoked.
#pod
#pod =head2 Output
#pod
#pod     output      - The output of the script
#pod     pid         - The process ID of the script
#pod     exit        - The exit code
#pod     info        - A text description of the exit code
#pod
#pod =head1 SEE ALSO
#pod
#pod =cut

use Mojo::Base 'Zapp::Task', -signatures;
use Mojo::File qw( tempdir tempfile );
use IPC::Open3 qw( open3 );
use Cwd qw( cwd );
use Symbol qw( gensym );
use Mojo::Util qw( decode );

sub schema( $class ) {
    return {
        input => {
            type => 'object',
            required => [qw( script )],
            properties => {
                env => {
                    type => 'array',
                    items => {
                        type => 'object',
                        properties => {
                            name => {
                                type => 'string',
                            },
                            value => {
                                type => 'string',
                            },
                        },
                    },
                },
                script => {
                    type => 'string',
                    format => 'textarea',
                },
            },
        },
        output => {
            type => 'object',
            required => [qw( output )],
            properties => {
                output => {
                    type => 'string',
                    format => 'textarea',
                },
                pid => {
                    type => 'integer',
                },
                exit => {
                    type => 'integer',
                },
                info => {
                    type => 'string',
                },
            },
        },
    };
}

# Match ANSI escape sequences that are not formatting/color (m)
my $ANSI = qr{ \e \[ [HJ] }x;

sub run( $self, $input ) {
    # The script came from the browser's form with \r\n as line ending
    # character, but we need to use the native OS's line ending
    # character...
    my $script = $input->{script} =~ s/\r\n/\n/gr;

    my $exe = $ENV{SHELL} // "/bin/sh";
    if ( $script =~ /^\#!([^\n]+)/s ) {
        $exe = $1;
        $script =~ s/^\#!\n+//;
    }

    my $cwd = cwd;
    my $dir = tempdir;
    chdir $dir;
    my $file = tempfile( DIR => $dir, UNLINK => 1 );
    $file->spurt( $script );

    my ( $stdout, $stderr, $pid );
    $stderr = gensym;

    {
        local %ENV = %ENV;
        for my $var ( @{ $input->{vars} // [] } ) {
            $ENV{ $var->{name} } = $var->{value};
        }
        #; $self->app->log->debug( "Environment: \n" . join "\n", map { "$_=$ENV{$_}" } keys %ENV ); 

        $pid = open3( my $stdin, $stdout, $stderr, $exe, $file );
        # XXX: Put PID somewhere we can use it while process is running
    }

    if ( !$pid || $pid <= 0 ) {
        chdir $cwd;
        return $self->fail({
            info => 'Could not execute script: ' . $!,
            output => '',
            exit => -1,
            pid => 0,
            error_output => '',
        });
    }

    # XXX: Read from stdout/stderr at the same time so both can be seen
    # while process runs
    my $output = '';
    while ( my $line = <$stdout> ) {
        $output .= $line =~ s/$ANSI//gr;
        # XXX: Put output somewhere it can be seen while process runs
    }
    my $error_output = '';
    while ( my $line = <$stderr> ) {
        $error_output .= $line =~ s/$ANSI//gr;
        # XXX: Put output somewhere it can be seen while process runs
    }

    waitpid $pid, 0;
    my $exit = $?;
    my $info
        = $exit == -1 ? 'Could not execute script: ' . $!
        : $exit & 127 ? 'Script ended with signal: ' . ( $? & 127 )
        : 'Script exited with value: ' . ( $? >> 8 )
        ;
    $exit >>= 8;

    my $method = $exit == 0 ? 'finish' : 'fail';
    chdir $cwd;
    return $self->$method({
        pid => $pid,
        output => decode( 'UTF-8', $output ) // $output,
        exit => $exit,
        info => $info,
        error_output => decode( 'UTF-8', $error_output ) // $error_output,
    });
}

1;

=pod

=head1 NAME

Zapp::Task::Script - Run a Script

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This task executes arbitrary scripts. By default, they are run as
scripts for the current shell. With a shebang line (e.g.
C<#!/usr/bin/perl>), any arbitrary interpreter can be invoked.

=head2 Output

    output      - The output of the script
    pid         - The process ID of the script
    exit        - The exit code
    info        - A text description of the exit code

=head1 SEE ALSO

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ input.html.ep
<%
    my $input = stash( 'input' ) // { script => '' };
    my @vars = @{ $input->{vars} // [ {} ] };
%>
% my $row_tmpl = begin
    % my ( $i, $env ) = @_;
    <div data-zapp-array-row class="form-row">
        <div class="col">
            <label for="vars[<%= $i %>].name">Name</label>
            <input type="text" name="vars[<%= $i %>].name" value="<%= $env->{name} %>" class="form-control">
        </div>
        <div class="col">
            <label for="vars[<%= $i %>].value">Value</label>
            <%= include 'zapp/textarea',
                name => "vars[$i].value",
                value => $env->{value},
                args => [
                    rows => 1,
                ],
            %>
        </div>
        <div class="col-auto align-self-start">
            <button type="button" style="margin-top: 2em" class="btn btn-outline-danger align-self-end" data-zapp-array-remove>
                <i class="fa fa-times-circle"></i>
            </button>
        </div>
    </div>
% end
<div class="form-group">
    <label for="vars">Environment Variables</label>
    <div data-zapp-array>
        <template><%= $row_tmpl->( '#', {} ) %></template>
        % for my $i ( 0 .. $#vars ) {
            %= $row_tmpl->( $i, $vars[$i] )
        % }
        <div class="form-row justify-content-end">
            <button type="button" class="btn btn-outline-success" data-zapp-array-add>
                <i class="fa fa-plus"></i>
            </button>
        </div>
    </div>

    <label for="script">Script</label>
    %= include 'zapp/textarea', name => 'script', value => $input->{script}, args => [ placeholder => 'Script' ]
</div>

@@ output.html.ep
<%
    use Mojo::Util qw( xml_escape );
    use Zapp::Util qw( ansi_colorize );
%>
% if ( $task->{output} && !ref $task->{output} ) {
    <h3>Error</h3>
    <div data-error class="alert alert-danger"><%= $task->{output} %></div>
% } elsif ( $task->{output} ) {
    % if ( $task->{output}{output} ) {
        <pre data-output class="m-1 border p-1 rounded bg-light"><output><%== ansi_colorize( xml_escape( $task->{output}{output} ) ) %></output></pre>
    % }
    % if ( $task->{output}{error_output} ) {
        <h4>Error Output</h4>
        <pre data-output class="m-1 border p-1 rounded table-warning"><output><%== ansi_colorize( xml_escape( $task->{output}{error_output} ) ) %></output></pre>
    % }
% }

%= include 'zapp/more_info', id => "task-$task->{task_id}", content => begin
    <h3>Script</h3>
    % my @vars = grep { $_->{name} } @{ $task->{input}{vars} // [] };
    % if ( @vars > 0 ) {
        <h4>Environment Variables</h4>
        <dl>
            % for my $var ( @vars ) {
                <dt><%= $var->{name} %></dt>
                <dd class="text-break text-pre-wrap"><%= $var->{value} %></dd>
            % }
        </dl>
    % }
    <pre data-input class="m-1 border p-1 rounded bg-light"><code><%= $task->{input}{script} %></code></pre>
% end
