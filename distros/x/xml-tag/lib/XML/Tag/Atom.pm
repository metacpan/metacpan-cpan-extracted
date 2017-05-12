package XML::Tag::Atom;
# roughly extracted with:
# perl -lnE '
#    END {say for sort keys %T }
#    $T{$1}++ while m{</?([^? >]+)}g' test.xml > X 

use Exporter 'import';
use XML::Tag;
BEGIN {
    our @EXPORT = qw<
        author
        category
        content
        entry
        icon
        id
        link
        name
        published
        rights
        title
        updated >;
    ns '' => @EXPORT;
};

1;
