package URL::Google::GURL;
use 5.008;
use strict;
use warnings;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('URL::Google::GURL', $VERSION);

1;
__END__

=head1 NAME

URL::Google::GURL - GURL class implementation from the Google URL library.

=head1 SYNOPSIS

    my $u1 = URL::Google::GURL->new('http://user:pass@google.com:99/foo;bar?q=a#ref'); $u1->is_valid();         # 1
    $u1->scheme_is('http');  # 1 
    $u1->scheme_is_file()    # 0
    $u1->scheme();           # 'http'
    $u1->username();         # 'user'
    $u1->password();         # 'pass'
    $u1->host();             # 'google.com'
    $u1->port();             # '99'
    $u1->int_port();         # 99
    $u1->path();             # '/foo;bar'
    $u1->query();            # 'q=a'
    $u1->ref();              # 'ref'

    my $u2 = URL::Google::GURL->new('http://foo.bar.com:80');
    $u2->spec();   # 'http://foo.bar.com/'

    my $u3 = URL::Google::GURL->new('http://foo.bar.com:8080');
    $u3->spec();   # 'http://foo.bar.com:8080/'

    my $u4 = URL::Google::GURL->new('http://foo.bar.com?baz=1');
    $u4->spec();   # 'http://foo.bar.com/?baz=1'

=head1 DESCRIPTION

This module provides an export of the GURL class from
the standards compliant, high performance google url library (c++)
(project hosted at L<http://code.google.com/p/google-url/>). The GURL class
is a convenient high-level abstraction for parsing and canonicalizing standard
urls.

The google url library source code is included in this module distribution.
The code is manually synchronized with the primary source
project and will therefore lag the project source in updates.

=head1 PREREQUISITES

In addition to a few perl dependencies, this module requires the ICU libraries
for building and execution (L<http://site.icu-project.org/download>).
If precompiled packages are availble for your system, that is the easiest way
to install (be sure to include the development headers). Otherwise, you can
consider using one of the precompiled binary packages available on the project
site or you can build from source.

=head1 AUTHOR

Mike Ellery

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Michael Ellery.

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same conditions as perl itself.

=cut
