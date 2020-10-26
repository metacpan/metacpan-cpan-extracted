package usww;
use 5.012005;

our $VERSION = "0.12";

use parent 'usw';

1;

__END__

=encoding utf-8

=head1 NAME

usww - was forked from usw especially for Windows.

=head1 SYNOPSIS

 use usww; # is just 9 bytes pragma instead of below:
 use utf8;
 use strict;
 use warnings;
 my $cp = '__YourCP__' || 'UTF-8';
 binmode \*STDIN,  ':encoding($cp)';
 binmode \*STDOUT, ':encoding($cp)';
 binmode \*STDERR, ':encoding($cp)';
  
=head1 DESCRIPTION

usww is deprecated because L<usw> now adapt Windows.

This document exists just only for backwards compatibility.

=head1 LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida(L<worthmine|https://github.com/worthmine>)

=cut
