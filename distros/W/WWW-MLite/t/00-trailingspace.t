#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 00-trailingspace.t 41 2019-05-29 17:01:36Z minus $
#
# For Notapad++: [ \t]+\r\n -> \r\n
# For Sublime  : [ \t]+\n
#
#########################################################################
use strict;
use Test::More;

eval "use Test::TrailingSpace";
plan skip_all => "Test::TrailingSpace required for trailing space test" if $@;

plan tests => 1;

my $finder = Test::TrailingSpace->new({
       root => '.',
       filename_regex => qr/(?:\.(?:t|pm|pl|cgi|xs|c|h|pod|PL|conf)|Changes|TODO)\z/,
       abs_path_prune_re => qr(\Asrc),
   });

# TEST
$finder->no_trailing_space("No trailing space was found");

1;

__END__
