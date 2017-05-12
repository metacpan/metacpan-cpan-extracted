#!perl
use 5.14.1;
use warnings;
use Ref::Util qw/is_hashref/;
use Test::Spec;
use HTTP::Response;
use Test::Fatal;

use Twitter::API;

BEGIN {
    eval { require Net::Twitter };
    plan skip_all => 'Net::Twitter >= 4.01041 not installed'
        if $@ || Net::Twitter->VERSION lt '4.01041';
}

my %skip = map +($_ => 1), (
    'contributees',           # deprecated
    'contributors',           # deprecated
    'create_media_metadata',  # described incorrectly in Net::Twitter
    'similar_places',         # no longer documented
    'update_delivery_device', # no longer documented
    'update_profile_colors',  # no longer documented
    'update_with_media',      # deprecated
    'upload_status',          # no longer documented
);

# These methods are either modified with an "around" or defined incorrectly in
# Net::Twitter, override what we expect for required parameters.
my %override_required = (
    show_user          => [ ':ID' ],
    create_friend      => [ ':ID' ],
    destroy_friend     => [ ':ID' ],
    friends_ids        => [ ':ID' ],
    followers_ids      => [ ':ID' ],
    create_block       => [ ':ID' ],
    destroy_block      => [ ':ID' ],
    report_spam        => [ ':ID' ],
    update_friendship  => [ ':ID' ],
    new_direct_message => [ qw/text :ID/ ],
    create_mute        => [ ':ID' ],
    destroy_mute       => [ ':ID' ],
);
# aliases
for ( \%override_required ) { # damned name is too long!
    $_->{follow} = $_->{follow_new} = $_->{create_friendship}
        = $_->{create_friend};
    $_->{destroy_friendship} = $_->{unfollow} = $_->{destroy_friend};
    $_->{following_ids} = $_->{friends_ids};
}

sub new_client {
    my $client = Twitter::API->new_with_traits(
        traits          => 'ApiMethods',
        consumer_key    => 'key',
        consumer_secret => 'secret',
    );
    $client->stubs(request => sub {
        my ( $self, $method, $path, $args ) = @_;
        die 'too many args' if @_ > 4;
        die 'too few args'  if @_ < 3;
        die 'final arg must be HASH' if @_ > 3 && !is_hashref($args);

        return ( uc $method, $args );
    });

    return $client;
}

sub http_response_ok {
    HTTP::Response->new(
        200, 'OK',
        [
            content_type   => 'application/json;charset=utf-8',
            contest_length => 4,
        ],
        '{}'
    );
}

my $nt = Net::Twitter->new(traits => [ qw/API::RESTv1_1/ ]);
my @nt_methods =
    # We'll test all methods through their aliases, too
    map {
        my $meta = $_;
        my @names = ($_->name, @{ $_->aliases });
        map [ $_, $meta ], @names;
    }
    sort { $a->name cmp $b->name }
    grep !$_->deprecated,
    grep $_->isa('Net::Twitter::Meta::Method'),
    map $_->original_method // $_, # may be wrapped
    $nt->meta->get_all_methods;

for my $pair ( @nt_methods ) {
    my ( $name, $nt_method ) = @$pair;
    next if $skip{$nt_method->name};

    describe $name => sub {
        my ( $client, @required );
        before each => sub {
            $client = new_client;
            @required = @{ $override_required{$name} // $nt_method->required };
        };

        it 'method exists' => sub {
            ok $client->can($name);
        };
        it 'has correct HTTP method' => sub {
            # path-part arguments must be passed
            my %must_have_args;
            @must_have_args{
                ( $nt_method->path =~ /:(\w+)/g ),
                map $_ eq ':ID' ? 'screen_name' : $_,
                @required
            } = 'a' .. 'z';
            my ( $http_method, undef ) = $client->$name(
                keys %must_have_args ? \%must_have_args : ()
            );
            is $http_method, $nt_method->method;
        };

        it "handles ${ \(0+@required) }  positional args" => sub {
            my @args; @args[0 .. $#required] = 'a' .. 'z';
            my %expected; @expected{
                map $_ eq ':ID' ? 'screen_name' : '$_', @required
            } = 'a' .. 'z';
            my ( undef, $args ) = $client->$name(@args);
            is_deeply $args, \%expected;
        } if @required > 0;

        it "handles mixed positional and named args" => sub {
            my %args; @args{@required[1..$#required]} = 'a' .. 'z';
            my %expected; @expected{
                map $_ eq ':ID' ? 'screen_name' : '$_', @required
            } = ( 'foo', 'a' .. 'z' );
            my ( undef, $args ) = $client->$name('foo', \%args);
            is_deeply $args, \%expected;
        } if @required > 1;
    };
}

runtests;
