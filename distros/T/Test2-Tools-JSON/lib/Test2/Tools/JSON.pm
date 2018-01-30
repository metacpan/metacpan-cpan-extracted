package Test2::Tools::JSON;
use strict;
use warnings;

our $VERSION = "0.03";

use Carp ();
use JSON::MaybeXS qw/JSON/;

use Test2::Compare::JSON();

%Carp::Internal = (
    %Carp::Internal,
    'Test2::Tools::JSON'   => 1,
    'Test2::Compare::JSON' => 1,
);

our @EXPORT = qw/json relaxed_json/;
use Exporter 'import';

sub json ($) {
    my @caller = caller;
    return Test2::Compare::JSON->new(
        file  => $caller[1],
        lines => [$caller[2]],
        inref => $_[0],
        json  => JSON->new->utf8,
    );
}

sub relaxed_json ($) {
    my @caller = caller;
    return Test2::Compare::JSON->new(
        file  => $caller[1],
        lines => [$caller[2]],
        inref => $_[0],
        json  => JSON->new->utf8->relaxed(1),
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Test2::Tools::JSON - Compare JSON string as data structure with Test2

=head1 SYNOPSIS

    use Test2::V0;
    use Test2::Tools::JSON;
    
    is {
        foo     => 'bar',
        payload => '{"a":1}',
    }, {
        foo     => 'bar',
        payload => json({a => E}),
    };

=head1 DESCRIPTION

Test2::Tools::JSON provides comparison tools for JSON string.
This module was inspired by L<Test::Deep::JSON>.

=head1 FUNCTIONS

=over 4

=item $check = json($expected)

Verify the value in the C<$got> JSON string has the same data structure as C<$expected>.

    is '{"a":1}', json({a => 1});

=item $check = relaxed_json($expected)

Verify the value in the C<$got> relaxed JSON string has the same data structure as C<$expected>.

    is '[1,2,3,]', relaxed_json([1,2,3]);

=back

=head1 SEE ALSO

L<Test::Deep::JSON>

L<Test2::Suite>, L<Test2::Tools::Compare>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut
