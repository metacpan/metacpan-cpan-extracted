use strict;
use warnings;

print "Basic\n";
eval {
    use Web::Dash;

    Web::Dash->new(lenses_dir => '/your/personal/lenses/directory')->to_app;
};


print "Or if you want to select lenses\n";
{
    use Web::Dash;
    use Web::Dash::Lens;

    my @lenses;
    foreach my $lens_file (
        'extras-unity-lens-github', 'video'
    ) {
        push(@lenses, Web::Dash::Lens->new(
            lens_file => "/usr/share/unity/lenses/$lens_file/$lens_file.lens"
        ));
    }
    Web::Dash->new(lenses => \@lenses)->to_app;
}
