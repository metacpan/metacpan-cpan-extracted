package Web::Library::Bar;
use Moose;
sub get_dir_for { "/bar-path/to/$_[1]" }

sub css_assets_for {
    ('/css/bar-one.css', '/css/bar-two.css');
}

sub javascript_assets_for {
    ('/js/bar-three.js', '/js/bar-four.js');
}
1;
