#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Data::Dumper;

BEGIN {
    # load from t/lib
    use_ok('Getopt::Trait::Provider');
    use_ok('Getopt::Trait::Handler');
}

=pod


=cut

BEGIN {
    package MyApp;
    use strict;
    use warnings;

    use decorators qw[ :accessors Getopt::Trait::Provider ];

    use parent 'UNIVERSAL::Object';
    our %HAS; BEGIN { %HAS = (
        name    => sub { __PACKAGE__ },
        verbose => sub { 0 },
        debug   => sub { 0 },
    )};

    sub app_name   : Opt('name=s')    ro(name);
    sub is_verbose : Opt('v|verbose') ro(verbose);
    sub is_debug   : Opt('d|debug')   ro(debug);

    sub new_from_options {
        my $class = shift;
        my %args  = Getopt::Trait::Handler::get_options( $class );

        #use Data::Dumper;
        #warn Dumper \%args;

        return $class->new( %args, @_ );
    }

}

{
    @ARGV = ();

    my $app = MyApp->new_from_options;
    isa_ok($app, 'MyApp');

    #use Data::Dumper;
    #warn Dumper $app;

    ok(!$app->is_verbose, '... got the right setting for verbose');
    ok(!$app->is_debug, '... got the right setting for debug');

    is($app->app_name, 'MyApp', '... got the expected app-name');
}

{
    @ARGV = ('--verbose', '--name', 'FooBarBaz');

    my $app = MyApp->new_from_options;
    isa_ok($app, 'MyApp');

    #use Data::Dumper;
    #warn Dumper $app;

    ok($app->is_verbose, '... got the right setting for verbose');
    ok(!$app->is_debug, '... got the right setting for debug');

    is($app->app_name, 'FooBarBaz', '... got the expected app-name');
}

{
    @ARGV = ('--verbose', '-d');

    my $app = MyApp->new_from_options;
    isa_ok($app, 'MyApp');

    #use Data::Dumper;
    #warn Dumper $app;

    ok($app->is_verbose, '... got the right setting for verbose');
    ok($app->is_debug, '... got the right setting for debug');

    is($app->app_name, 'MyApp', '... got the expected app-name');
}



done_testing;

