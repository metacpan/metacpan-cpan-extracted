package XAO::DO::Data::ContentData;
use strict;
use XAO::Objects;
use base XAO::Objects->load(objname => 'FS::Hash');
###############################################################################
1;
__END__

=head1 NAME

XAO::DO::Data::ContentData - dynamic content object

=head1 DESCRIPTION

A XAO::FS object that supports dynamic content elements for
XAO::DO::Web::Content.

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::DO::Web::Content>,
L<XAO::FS>,
L<XAO::Web>.
