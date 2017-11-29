package Validator::Lazy::Role::Check::Trim;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::Trim


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( { trim => { Trim => 'all' } } ); # trim all unwanted spaces from a value

    my( $ok,$data ) = $v->check( trim => '  john   smith  ' );

    say $data->{trim}; # 'john smith'


=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "Trim" type for Validator::Lazy config.
    Allows to trim value's spaces.
    Do not performs any validations.


=head1 METHODS

=head2 C<check>

    Called from inside if Validator::Lazy->check process

    Temporary overrides internal Validator::Lazy::check method like this:

    $validator->check( $value, $param );

    $param - scalar or list. can have one or any of values = [ left right inner all ]
    $value - your value to do with.


=head1 SUPPORT AND DOCUMENTATION

    After installing, you can find documentation for this module with the perldoc command.

    perldoc Validator::Lazy

    You can also look for information at:

        RT, CPAN's request tracker (report bugs here)
            http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator-Lazy

        AnnoCPAN, Annotated CPAN documentation
            http://annocpan.org/dist/Validator-Lazy

        CPAN Ratings
            http://cpanratings.perl.org/d/Validator-Lazy

        Search CPAN
            http://search.cpan.org/dist/Validator-Lazy/


=head1 AUTHOR

ANTONC <antonc@cpan.org>

=head1 LICENSE

    This program is free software; you can redistribute it and/or modify it
    under the terms of the the Artistic License (2.0). You may obtain a
    copy of the full license at:

    L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

use v5.14.0;
use utf8;
use Modern::Perl;
use Moose::Role;

sub check {
    my ( $self, $value, $param ) = @_;

    return $value  unless $value && $param;

    $param = [ $param ]  unless ref $param;
    my @rules = @$param;

    if ( grep /^all$/, @rules ) {
        push @rules, qw/ left right inner /;
    };

    for ( @rules ) {
        if    ( /^left$/  ) { $value =~ s/^\s+//smg; }
        elsif ( /^right$/ ) { $value =~ s/\s+$//smg; }
        elsif ( /^inner$/ ) { $value =~ s/(?<=\S)\s+(?=\S)/ /smg; }
        elsif ( /^all$/   ) { } # do nothing, this rule splitted on 'left' + 'right' + 'inner'
        else  { confess 'Unknown rule: ' . $_ };
    };

    return $value;
};

1;
