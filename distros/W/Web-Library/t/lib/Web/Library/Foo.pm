package Web::Library::Foo;
use Moose;
sub get_dir_for { "/foo-path/to/$_[1]" }

sub css_assets_for {
    qw(/css/foo-one.css /css/foo-two.css);
}

sub javascript_assets_for {
    qw(/js/foo-three.js /js/foo-four.js);
}
1;
