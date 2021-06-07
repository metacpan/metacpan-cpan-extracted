package Zapp::Task::Test;
# ABSTRACT: Test the output of previous tasks

#pod =head1 DESCRIPTION
#pod
#pod This task allows testing of previous tasks' output. If any test fails,
#pod this task fails.
#pod
#pod =head2 Output
#pod
#pod     tests       - An array of test hashes with the following fields
#pod         expr        - An expression to evaluate
#pod         op          - An operator
#pod         value       - The expected value
#pod         expr_value  - The value of the evaluated expression
#pod         pass        - True if the test passed
#pod
#pod =head1 SEE ALSO
#pod
#pod =cut

use Mojo::Base 'Zapp::Task', -signatures;
use Yancy::Util qw( currym );

sub run( $self, $input ) {
    my $fail = 0;
    my @tests = $input->{tests}->@*;
    for my $test ( @tests ) {
        # Stringify whatever data we get because the value to test
        # against can only ever be a string.
        # XXX: Support deep comparisons
        my $expr_value = $test->{ expr_value } = $self->app->formula->eval( $test->{expr}, currym( $self, 'context' ) );
        # XXX: Add good, robust logging to help debug job problems
        #; $self->app->log->debug( sprintf 'Test expr %s has value %s (%s %s)', $test->@{qw( expr expr_value op value )} );
        my $pass;
        if ( $test->{op} eq '==' ) {
            $pass = ( $expr_value eq $test->{value} );
        }
        elsif ( $test->{op} eq '!=' ) {
            $pass = ( $expr_value ne $test->{value} );
        }
        elsif ( $test->{op} eq '>' ) {
            $pass = ( $expr_value gt $test->{value} );
        }
        elsif ( $test->{op} eq '<' ) {
            $pass = ( $expr_value lt $test->{value} );
        }
        elsif ( $test->{op} eq '>=' ) {
            $pass = ( $expr_value ge $test->{value} );
        }
        elsif ( $test->{op} eq '<=' ) {
            $pass = ( $expr_value le $test->{value} );
        }
        $test->{pass} = $pass;
        if ( !$pass ) {
            $fail = 1;
            # XXX: Should be $self->log and logs should be added to job
            # notes
            $self->app->log->debug(
                sprintf "Failed test %s %s %s with value %s",
                    $test->@{qw( expr op value expr_value )},
            );
        }
    }
    my $method = $fail ? 'fail' : 'finish';
    return $self->$method( $input );
}

1;

=pod

=head1 NAME

Zapp::Task::Test - Test the output of previous tasks

=head1 VERSION

version 0.004

=head1 DESCRIPTION

This task allows testing of previous tasks' output. If any test fails,
this task fails.

=head2 Output

    tests       - An array of test hashes with the following fields
        expr        - An expression to evaluate
        op          - An operator
        value       - The expected value
        expr_value  - The value of the evaluated expression
        pass        - True if the test passed

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
    my $input = stash( 'input' ) // { tests => [{}] };
    my @tests = $input->{tests}->@*;
%>
% my $row_tmpl = begin
    % my ( $i, $test ) = @_;
    <div data-zapp-array-row class="form-row">
        <input type="hidden" name="tests[<%= $i %>].test_id" value="<%= $test->{test_id} // '' %>" />
        <div class="col">
            <label for="tests[<%= $i %>].expr">Expression</label>
            <input type="text" name="tests[<%= $i %>].expr" value="<%= $test->{expr} %>" class="form-control">
        </div>
        <div class="col-auto align-self-end">
            <select name="tests[<%= $i %>].op" class="form-control">
                <option value="==" <%= ($test->{op}//'') eq '==' ? 'selected' : '' %>>==</option>
                <option value="!=" <%= ($test->{op}//'') eq '!=' ? 'selected' : '' %>>!=</option>
                <option value="&gt;" <%= ($test->{op}//'') eq '>' ? 'selected' : '' %>>&gt;</option>
                <option value="&lt;" <%= ($test->{op}//'') eq '<' ? 'selected' : '' %>>&lt;</option>
            </select>
        </div>
        <div class="col">
            <label for="tests[<%= $i %>].value">Value</label>
            <input type="text" name="tests[<%= $i %>].value" value="<%= $test->{value} %>" class="form-control">
        </div>
        <div class="col-auto align-self-end">
            <button type="button" class="btn btn-outline-danger align-self-end" data-zapp-array-remove>
                <i class="fa fa-times-circle"></i>
            </button>
        </div>
    </div>
% end
<div data-zapp-array>
    <template><%= $row_tmpl->( '#', {} ) %></template>
    % for my $i ( 0 .. $#tests ) {
        %= $row_tmpl->( $i, $tests[$i] )
    % }
    <div class="form-row justify-content-end">
        <button type="button" class="btn btn-outline-success" data-zapp-array-add>
            <i class="fa fa-plus"></i>
        </button>
    </div>
</div>

@@ output.html.ep
% if ( $task->{output} && !ref $task->{output} ) {
    <h4>Error</h4>
    <div data-error class="alert alert-danger"><%= $task->{output} %></div>
% } else {
    <table class="table table-sm table-borderless">
        <thead>
            <tr>
                <th>Test Expression</th>
                <th>Got Value</th>
                <th>Op</th>
                <th>Expect Value</th>
            </tr>
        </thead>
        <tbody>
            % for my $test ( @{ $task->{output}{tests} // $task->{input}{tests} } ) {
                <tr class="<%= !defined $test->{pass} ? 'table-secondary' : $test->{pass} ? 'table-success' : 'table-danger' %>">
                    %= tag td => $test->{expr}
                    %= tag td => $test->{expr_value} // ''
                    %= tag td => $test->{op}
                    %= tag td => $test->{value}
                </tr>
            % }
        </tbody>
    </table>
% }
