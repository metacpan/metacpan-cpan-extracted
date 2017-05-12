package XML::Liberal::Remedy::DeprecatedDTD;
use strict;

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~
        /:\d+: parser error : Content error in the external subset/;

    return 1 if $$xml_ref =~
        s{(?<=\s(["'])http://)my\.netscape\.com/publish/formats(?=/rss-0\.91?\.dtd\1\s*>)}
         {www.rssboard.org};

    Carp::carp("Can't find deprecated DTD, error was: ", $error->summary);
    return 0;
}

1;
