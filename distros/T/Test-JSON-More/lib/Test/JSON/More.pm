package Test::JSON::More;
use strict;
use warnings;
use Test::Differences;
use parent 'Test::Builder::Module';

our $VERSION = '0.02';

my $JSON;

sub import {
    my $class       = shift;
    my $json_module = shift || 'JSON';

    my $caller = caller;

    for my $func (qw/ ok_json cmp_json parsed_json ok_json_schema /) {
        no strict 'refs'; ## no critic
        *{"${caller}::$func"} = \&{"${class}::$func"};
    }

    $JSON = _load_module($json_module)->new;
}

sub _load_module {
    my $module = shift;

    my $lib = $module;
    $lib =~ s!::!/!g;
    require "$lib.pm"; ## no critic
    $lib->import;

    $module;
}

our $PARSED_HASH;
sub parsed_json { $PARSED_HASH }

sub ok_json {
    my ($input_json, $test_name) = @_;

    my $test = __PACKAGE__->builder;

    $test->croak("ok_json: undefined JSON") unless defined $input_json;

    eval { $PARSED_HASH = $JSON->decode($input_json) };

    if ( my $error = $@ ) {
        $test->ok( 0, $test_name );
        $test->diag("invalid JSON:\n\n\t$error");
        return;
    }
    else {
        $test->ok( 1, $test_name );
        return 1;
    }
}

sub cmp_json {
    my ($input_json, $expected_json, $test_name) = @_;

    my $test = __PACKAGE__->builder;

    $test->croak("cmp_json: input JSON is undefined")    unless defined $input_json;
    $test->croak("cmp_json: expected JSON is undefined") unless defined $expected_json;

    my %json_for;

    for my $item ( [ input => $input_json ], [ expected => $expected_json ] ) {
        eval { $PARSED_HASH = $JSON->decode($item->[1]) };
        if ( my $error = $@ ) {
            $test->ok( 0, $test_name );
            $test->diag("$item->[0] is invalid JSON:\n\n\t$error");
            return;
        }
        else {
            $json_for{ $item->[0] } = $PARSED_HASH;
        }
    }
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eq_or_diff( $json_for{input}, $json_for{expected}, $test_name );
}

sub ok_json_schema {
    my ( $input_json, $schema, $test_name  ) = @_;

    my $test = __PACKAGE__->builder;

    $test->croak("ok_json_schema: input JSON is undefined") unless defined $input_json;

    eval { $PARSED_HASH = $JSON->decode($input_json) };
    if ( my $error = $@ ) {
        $test->ok( 0, $test_name );
        $test->diag("invalid JSON: $error");
        return;
    }

    my $jsv = _load_module('JSV::Validator')->new;
    $schema = (!defined $schema || ref($schema) eq 'HASH') ? $schema : $JSON->decode($schema);
    my $res = $jsv->validate($schema, $PARSED_HASH);

    if ( $res->error || scalar @{$res->errors} ) {
        $test->ok( 0, $test_name );
        for my $error ( $res->get_error ) {
            $test->diag("schema error: $error->{message}". ($error->{pointer} ? " pointer:$error->{pointer}" : ""));
        }
        return;
    }
    else {
        if (!defined $schema) {
            $test->carp("Schema is undefined". ($test_name ? ":$test_name" : ""));
        }
        $test->ok( 1, $test_name );
        return 1;
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Test::JSON::More - JSON Test Utility


=head1 SYNOPSIS

    use Test::JSON::More;
    use Test::More;

    my $json = '{"foo":123,"bar":"baz"}';

    ok_json($json);

    cmp_json($json, '{"bar":"baz","foo":123}');

    my $schema = {
        type       => "object",
        properties => {
            foo => { type => "integer" },
            bar => { type => "string" }
        },
        required => [ "foo" ]
    };

    ok_json_schema($json, $schema);

    is parsed_json->{foo}, 123;

    done_testing;


=head1 DESCRIPTION

Test::JSON::More is the utility for testing JSON string.

=head2 SWITCH JSON MODULES

By default, B<Test::JSON::More> use L<JSON> module for encoding/decoding JSON. If you would like to use an another JSON module in the test, then you can specify it at loading C<Test::JSON::More>, like below.

    use Test::JSON::More 'JSON::XS';

NOTE that the switching JSON module needs to implement B<new>, B<encode> and B<decode> methods.

=head1 METHODS

=head2 ok_json

    ok_json($json, $test_name)

Test passes if the string is valid JSON.

=head2 cmp_json

    cmp_json($json, $expected_json, $test_name)

Test passes if the two JSON strings are valid JSON and evaluate to the same data structure.

=head2 ok_json_schema

    ok_json_schema($json, $schema, $test_name)

Test passes if the string is valid JSON and fits the schema againsts its specification.

C<$schema> is a perl hash reference or a string of JSON schema, whichever is OK.

=head2 parsed_json

    $ref = parsed_json();

The C<parsed_json> function returns the perl hash ref or array ref that is the result of parsed JSON in a test methods(i.e. ok_json, cmp_json or ok_json_schema).


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Test-JSON-More"><img src="https://secure.travis-ci.org/bayashi/Test-JSON-More.png?_t=1461806674"/></a> <a href="https://coveralls.io/r/bayashi/Test-JSON-More"><img src="https://coveralls.io/repos/bayashi/Test-JSON-More/badge.png?_t=1461806674&branch=master"/></a>

=end html

Test::JSON::More is hosted on github: L<http://github.com/bayashi/Test-JSON-More>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

JSON validator: L<JSV::Validator>, L<JSV>

Test builder: L<Test::Builder::Module>

Inspired by L<Test::JSON>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
