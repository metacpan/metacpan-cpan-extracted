use File::Spec;
use Test::More;

plan skip_all => 'Author test. Set $ENV{AUTHOR_TESTS} to a true value to run.' unless $ENV{AUTHOR_TESTS};

eval { require Test::Perl::Critic; };

if ($@) {

    my $msg = 'Test::Perl::Critic required to criticize code';
    plan(skip_all => $msg);

}

my $rcfile = File::Spec->catfile( 'xt', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
