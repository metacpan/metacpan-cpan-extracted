package Test2::Tools::Condition;
use strict;
use warnings;

our $VERSION = "0.03";

use Carp ();

use Test2::Compare::Condition();

%Carp::Internal = (
    %Carp::Internal,
    'Test2::Tools::Condition'   => 1,
    'Test2::Compare::Condition' => 1,
);

our @EXPORT = qw/condition/;
use Exporter 'import';

sub condition (&) {
    my @caller = caller;
    return Test2::Compare::Condition->new(
        file  => $caller[1],
        lines => [$caller[2]],
        code  => $_[0],
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Test2::Tools::Condition - Conditional block with Test2

=head1 SYNOPSIS

    use Test2::V0;
    use Test2::Tools::Condition;

    my $positive_number = condition { $_ > 0 };

    is 123, $positive_number; 
    is {
        a => 0,
        b => 1,
    }, {
        a => !$positive_number,
        b => $positive_number,
    };

=head1 DESCRIPTION

Test2::Tools::Condition checks wether or not the value satisfies the condition.

=head1 FUNCTIONS

=over 4

=item $check = condition { ... };

Verify the value satisfies the condition and set C<$_> for C<$got> value in block.

    is 3, condition { 2 < $_ && $_ < 4 };

=item $check = !condition { ... };

Verify the value unsatisfies the condition and set C<$_> for C<$got> value in block.

    is 7, !condition { 2 < $_ && $_ < 4 };

=back

=head1 SEE ALSO

L<Test::Deep::Cond>

L<Test2::Suite>, L<Test2::Tools::Compare>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut
