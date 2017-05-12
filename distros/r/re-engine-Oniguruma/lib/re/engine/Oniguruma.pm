package re::engine::Oniguruma;

require 5.009005;

use strict;
use warnings;
use XSLoader ();

# All engines should subclass the core Regexp package
our @ISA = 'Regexp';

our $VERSION = '0.05';
XSLoader::load __PACKAGE__, $VERSION;

sub import {
    $^H{regcomp} = ENGINE();
}

sub unimport {
    delete $^H{regcomp}
      if $^H{regcomp} == ENGINE();
}

1;

__END__

=head1 NAME

re::engine::Oniguruma - Use the Oniguruma regex engine with Perl

=head1 SYNOPSIS

    use re::engine::Oniguruma;

    if ("Hello, world" =~ /(?<=Hello), (world)/) {
        print "Greetings, $1!";
    }

=head1 DESCRIPTION

Replaces perl's regex engine in a given lexical scope with the Oniguruma
engine.

See L<http://www.geocities.jp/kosako3/oniguruma/> for more information.

=head1 AUTHORS

Andy Armstrong <andy@hexten.net>

Most of the code was modified from L<re::engine::PCRE>. Thanks to
E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason for writing it an all his
other regex related work.

=head1 COPYRIGHT

Copyright 2007, Andy Armstrong

Oniguruma is copyright 2002-2007, K.Kosako <sndgk393 AT ybb DOT ne DOT jp>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See F<onig/COPYING> for details of Oniguruma's licence.

=cut
