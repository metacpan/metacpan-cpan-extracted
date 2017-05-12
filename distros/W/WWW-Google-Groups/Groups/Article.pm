# $Id: Article.pm,v 1.7 2003/09/15 13:49:48 cvspub Exp $
package WWW::Google::Groups::Article;
use strict;

use Email::Simple;

sub new {
    my ($pkg, $message) = @_;
    return $$message ? Email::Simple->new($$message) : undef;
}

1;
__END__
