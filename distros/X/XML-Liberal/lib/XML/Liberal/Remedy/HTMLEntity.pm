package XML::Liberal::Remedy::HTMLEntity;
use strict;

use HTML::Entities ();

my %DECODE = map {
    (my $name = $_) =~ s{\;\z}{};
    $name => sprintf '&#x%x;', ord $HTML::Entities::entity2char{$_}
} keys %HTML::Entities::entity2char;

# optimized to fix all errors in one apply() call
sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~ /^parser error : Entity '.*' not defined/;

    # Note that we can't tell whether "&EACUTE;" is meant to be "&eacute;"
    # or "&Eacute;", so we arbitrarily choose "&eacute;".  Fortunately, the
    # only HTML entities whose names aren't all-lower-case are the
    # upper-case equivalents of all-lower-case ones, so this doesn't
    # introduce any ambiguity that didn't exist in the source document.
    return scalar $$xml_ref =~ s{&([a-zA-Z0-9]+);}{
        $DECODE{$1} || $DECODE{lc $1}
            || Carp::carp("Can't find named HTML entity $1, error was: ",
                          $error->summary)
    }ge;
}

1;
