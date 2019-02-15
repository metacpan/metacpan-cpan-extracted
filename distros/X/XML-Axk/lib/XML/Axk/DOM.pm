#!/usr/bin/env perl
# XML::Axk::DOM - DOM encapsulation for axk.
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

package XML::Axk::DOM;
use XML::DOM;       # TODO change to XML::LibXML
use XML::DOM::XPath;

use Import::Into;

sub import {
    XML::DOM->import::into(1);
    XML::DOM::XPath->import::into(1);
} #import()

1;
__END__
# === Documentation ===================================================== {{{1

=pod

=encoding UTF-8

=head1 NAME

XML::Axk::DOM - DOM encapsulation for the axk XML processor

=head1 SYNOPSIS

C<use XML::Axk::DOM;> will make axk's current DOM available to you.
This is to make it easier to later change back-end.

=head1 VERSION

Version 0.01

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). Details are in the LICENSE
file accompanying this distribution.

=cut

# }}}1
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker: #
