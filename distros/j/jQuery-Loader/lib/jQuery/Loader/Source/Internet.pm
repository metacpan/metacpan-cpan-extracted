package jQuery::Loader::Source::Internet;

use jQuery::Loader;
use jQuery::Loader::Source::URI;
use jQuery::Loader::Carp;

sub new {
    my $class = shift;
#    my $uri = "http://jqueryjs.googlecode.com/files/\%j";
    my $uri = "http://ajax.googleapis.com/ajax/libs/jquery/\%v/jquery\%.f.js";
    return jQuery::Loader::Source::URI->new(uri => $uri, @_);
}

1;
