package WWW::Baidu::Record;

use strict;
use warnings;
use base qw(Class::Accessor);

our $VERSION = '0.06';

__PACKAGE__->mk_ro_accessors(
    qw/ title url summary size date cached_url /
);

1;
__END__

=head1 NAME

WWW::Baidu::Record - Record object representing an item in baidu.com's search results

=head1 VERSION

This document describes version 0.06 of C<WWW::Baidu::Record>, released Jan 21, 2007.

=head1 SYNOPSIS

    # ... construct the WWW::Baidu object $baidu somehow earlier
    $record = $baidu->next;
    if ($record) {
        print "Found page titled ", $record->title;
        print " whose URL is ", $record->url;
        print " and the summary looks like ", $record->summary;
        print ". Its size is ", $record->size;
        print ". You can preview the cached version from ", $record->cached_url,
        print " if you've got a 404 error. :)";
    }

=head1 DESCRIPTION

This class represent objects for the search results returned by Baidu.com.

=head1 CONSTRUCTIOR

There's a constructor generated automatically by L<Class::Accessor>, but usually
you don't need to construct a C<WWW::Baidu::Record> instance yourself.

Please always use the C<next> method of L<WWW::Baidu> object to get an object of
this class.

=head1 PROPERTIES

All the properties of this class are read-only and return strings in the GBK/GB2312
encoding. If you want UTF-8, use the L<Encode> module to decode the strings yourself:

    use Encode 'decode';
    $utf8 = decode('GBK', $gbk);

=over

=item C<< $value = $obj->title >>

Returns the matched web page or document's page title.

=item C<< $value = $obj->url >>

Returns the absolute URL for the matched web document.

=item C<< $value = $obj->summary >>

A brief summary for the matched web document from Baidu.com

=item C<< $value = $obj->size >>

Size info for the matched document. Note that it's not an number, instead it's in
the form of '32K' or something like that.

=item C<< $value = $obj->cached_url >>

Returns the url pointing to the cached version of the matched document on Baidu.com.
Note that, for documents with types like DOC, PPT and XSL, there won't be a cached
version. So this property always returns undef in these cases.

=back

=head1 AUTHOR

Agent Zhang E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2007 by Agent Zhang. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<WWW::Baidu>, L<Encode>.
