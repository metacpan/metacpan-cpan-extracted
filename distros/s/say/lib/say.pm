package say;
use strict;
use warnings;

our $VERSION = '0.02';

sub import {
    my $class  = shift;

    my $caller = caller;

    if( $] < 5.010 ) {
        require Perl6::Say;
        Perl6::Say->import;

        no strict 'refs'; ## no critic
        *{$caller . '::say'} = \&Perl6::Say::say;
    }
    else {
        require feature;
        for my $f ('say', @_) {
            feature->import($f);
        }
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

say - say anything


=head1 SYNOPSIS

    use say;
    say "Hello!";


=head1 DESCRIPTION

B<say> module allows Perl code to use B<say>.

And if you would pass args to B<say> like below, then some features are enabled to use them as same as L<feature> module.

    use say qw/state switch/;

    state $foo = int(rand 10);

    given ($foo) {
        when (1) { say "One" }
        when (2) { say "Two" }
        default  { say "Above Two" }
    }


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/say"><img src="https://secure.travis-ci.org/bayashi/say.png?_t=1475708487"/></a> <a href="https://coveralls.io/r/bayashi/say"><img src="https://coveralls.io/repos/bayashi/say/badge.png?_t=1475708487&branch=master"/></a>

=end html

say is hosted on github: L<http://github.com/bayashi/say>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<feature>

L<Say::Compat>

L<Perl6::Say>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
