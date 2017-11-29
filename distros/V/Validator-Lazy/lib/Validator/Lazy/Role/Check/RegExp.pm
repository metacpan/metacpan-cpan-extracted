package Validator::Lazy::Role::Check::RegExp;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::RegExp


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( { regexp => { RegExp => [ list of regexps for checking ] } } );

    my $ok = $v->check( regexp => 'xxxxx' );  # true / false
    say Dumper $v->errors;  # [ { code => 'REGEXP_ERROR', field => 'regexp', data => { expr => 'expr_which_check_is_fail' } } ]


=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "RegExp" type for Validator::Lazy config.
    Allows to check value by regular expressions.


=head1 METHODS

=head2 C<check>

    Called from inside if Validator::Lazy->check process

    Temporary overrides internal Validator::Lazy::check method like this:

    $validator->check( $value, $param );

    $param - is a regular expression string or list of regular expressions
    each param should be a string in format = '/your-regexp-here/aimsx'
    all modificators can be combined with other, and all of them can be omitted

    examples:
        '/^\d+$/'             # integer
        '^[A-Z][a-z]{1,64}$'  # name
        etc.

    $value - your value to check


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

# m/s/tr

sub before_check {
    my ( $self, $value, $param ) = @_;

    confess 'at least one rule should be passed'  unless $param;
    confess 'rules should be scalar or arrayref'  unless ! ref $param || ref $param eq 'ARRAY';

    return $value;
};

sub check {
    my ( $self, $value, $param ) = @_;

    return $value  unless $value && $param;

    $param = [ $param ]  unless ref $param;

    # simple regexps
    for my $exp ( @$param ) {
        my( $e, $m ) = ( $exp =~ /^\/(.+)\/([aimsx]+)?$/ );

        confess 'cannot parse regexp = ' . $exp  unless $e;

        # a - 5.14+ - affect which character-set rules (Unicode, etc.) are used
        # x - Extend your pattern's legibility by permitting whitespace and comments.
        # i - Do case-insensitive pattern matching.
        # s - That is, change "." to match any character whatsoever, even a newline, which normally it would not match.
        # m - That is, change "^" and "$" from matching the start of the string's first line and the end of its last line to matching the start and end of each line within the string.
        $m //= '';
        $m = join '', sort split /\B/, $m;

        # aimsx
        my $ok =
            $m eq ''      ? $value =~ /$e/      :
            $m eq 'x'     ? $value =~ /$e/x     :
            $m eq 's'     ? $value =~ /$e/s     :
            $m eq 'sx'    ? $value =~ /$e/sx    :
            $m eq 'm'     ? $value =~ /$e/m     :
            $m eq 'mx'    ? $value =~ /$e/mx    :
            $m eq 'ms'    ? $value =~ /$e/ms    :
            $m eq 'msx'   ? $value =~ /$e/msx   :
            $m eq 'i'     ? $value =~ /$e/i     :
            $m eq 'ix'    ? $value =~ /$e/ix    :
            $m eq 'is'    ? $value =~ /$e/is    :
            $m eq 'isx'   ? $value =~ /$e/isx   :
            $m eq 'im'    ? $value =~ /$e/im    :
            $m eq 'imx'   ? $value =~ /$e/imx   :
            $m eq 'ims'   ? $value =~ /$e/ims   :
            $m eq 'imsx'  ? $value =~ /$e/imsx  :

            $m eq 'a'     ? $value =~ /$e/a     :
            $m eq 'ax'    ? $value =~ /$e/ax    :
            $m eq 'as'    ? $value =~ /$e/as    :
            $m eq 'asx'   ? $value =~ /$e/asx   :
            $m eq 'am'    ? $value =~ /$e/am    :
            $m eq 'amx'   ? $value =~ /$e/amx   :
            $m eq 'ams'   ? $value =~ /$e/ams   :
            $m eq 'amsx'  ? $value =~ /$e/amsx  :
            $m eq 'ai'    ? $value =~ /$e/ai    :
            $m eq 'aix'   ? $value =~ /$e/aix   :
            $m eq 'ais'   ? $value =~ /$e/ais   :
            $m eq 'aisx'  ? $value =~ /$e/aisx  :
            $m eq 'aim'   ? $value =~ /$e/aim   :
            $m eq 'aimx'  ? $value =~ /$e/aimx  :
            $m eq 'aims'  ? $value =~ /$e/aims  :
            $m eq 'aimsx' ? $value =~ /$e/aimsx :
        '';

        unless ( $ok ) {
            $self->add_error( { exp => $exp } );
        };
    }

    return $value;
};

1;
