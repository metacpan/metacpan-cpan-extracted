use strict;
use warnings;

use lib 't/lib';
use MockStore;
use Toggle;

use Test::Spec;
use Test::Spec::Mocks;

describe 'A feature' => sub {
    my $storage;
    my $toggle;

    before each => sub {
        $storage = MockStore->new();
        $toggle = Toggle->new( storage => $storage );
    };

    context 'when first added' => sub {
        before sub {
            $toggle->add_feature('chat');
        };

        it 'is inactive for all users' => sub {
            ok !$toggle->is_active( chat => stub( id => 42 ) );
        };

        it 'appears in the feature list' => sub {
            ok grep { $_ eq 'chat' } $toggle->features;
        };
    };

    context 'when removed' => sub {
        before sub {
            $toggle->add_feature('chat');
            $toggle->remove_feature('chat');
        };

        it 'is inactive for all users' => sub {
            ok !$toggle->is_active( chat => stub( id => 42 ) );
        };

        it 'does not appear in the feature list' => sub {
            ok !grep { $_ eq 'chat' } $toggle->features;
        };
    };

    context 'when globally activated' => sub {
        before sub {
            $toggle->activate('chat');
        };

        it 'is active if checked without a user' => sub {
            ok $toggle->is_active('chat');
        };

        it 'is active if checked with a user' => sub {
            ok $toggle->is_active( chat => stub( id => 1 ) );
        };

        it 'appears in the feature list' => sub {
            ok grep { $_ eq 'chat' } $toggle->features;
        };
    };

    context 'when globally activated twice' => sub {
        before sub {
            $toggle->activate('chat');
            $toggle->activate('chat');
        };

        it 'appears in the feature list once' => sub {
            is_deeply( [ $toggle->features() ], ['chat'] );
        };
    };

    context 'when globally deactivated' => sub {
        before sub {
            $toggle->define_group( fivesonly => sub { shift->id == 5 } );
            $toggle->activate_group( chat => 'all' );
            $toggle->activate_group( chat => 'fivesonly' );
            $toggle->activate_user( chat => stub( id => 51 ) );
            $toggle->activate_percentage( chat => 100 );
            $toggle->activate('chat');
            $toggle->deactivate('chat');
        };

        it 'is inactive for users who were in active groups' => sub {
            ok !$toggle->is_active( chat => stub( id => 0 ) );
            ok !$toggle->is_active( chat => stub( id => 5 ) );
        };

        it 'is inactive for users who were enabled explicitly' => sub {
            ok !$toggle->is_active( chat => stub( id => 51 ) );
        };

        it 'is inactive for users who were enabled via a percentage' => sub {
            ok !$toggle->is_active( chat => stub( id => 24 ) );
        };

        it 'is inactive if checked without a user' => sub {
            ok !$toggle->is_active('chat');
        };

        it 'still appears in the features list' => sub {
            ok grep { $_ eq 'chat' } $toggle->features;
        };
    };

    context 'when activated for a group' => sub {
        before sub {
            $toggle->define_group( fivesonly => sub { shift->id == 5 } );
            $toggle->activate_group( chat => 'fivesonly' );
        };

        it 'is active for users in the group' => sub {
            ok $toggle->is_active( chat => stub( id => 5 ) );
        };

        it 'is not active for users not in the group' => sub {
            ok !$toggle->is_active( chat => stub( id => 1 ) );
        };

        it 'appears in the feature list' => sub {
            ok grep { $_ eq 'chat' } $toggle->features;
        };
    };

    context 'when activated for an undefined group' => sub {
        before sub {
            $toggle->activate_group( chat => 'fake' );
        };

        it 'is not active for any user' => sub {
            ok !$toggle->is_active( chat => stub( id => 1 ) );
        };

        it 'appears in the feature list' => sub {
            ok grep { $_ eq 'chat' } $toggle->features;
        };
    };

    describe 'when activated for the "all" group' => sub {
        before each => sub {
            $toggle->activate_group( chat => 'all' );
        };

        it 'is active for all users' => sub {
            ok $toggle->is_active( 'chat', stub( id => 0 ) );
        };

        it 'appears in the feature list' => sub {
            ok grep { $_ eq 'chat' } $toggle->features;
        };
    };

    context 'when deactivated for a group' => sub {
        before sub {
            $toggle->define_group( fivesonly => sub { shift->id == 5 } );
            $toggle->activate_group( chat => 'all' );
            $toggle->activate_group( chat => 'some' );
            $toggle->activate_group( chat => 'fivesonly' );
            $toggle->deactivate_group( chat => 'all' );
            $toggle->deactivate_group( chat => 'some' );
        };

        it 'is not active for that group' => sub {
            ok !$toggle->is_active( chat => stub( id => 10 ) );
        };

        it 'leaves other groups active' => sub {
            ok $toggle->is_active( chat => stub( id => 5 ) );
        };
    };

    context 'when activated for a user' => sub {
        before sub {
            $toggle->activate_user( chat => stub( id => 42 ) );
        };

        it 'is active for that user' => sub {
            ok $toggle->is_active( chat => stub( id => 42 ) );
        };

        it 'remains inactive for other users' => sub {
            ok !$toggle->is_active( chat => stub( id => 24 ) );
        };

        it 'appears in the feature list' => sub {
            ok grep { $_ eq 'chat' } $toggle->features;
        };
    };

    context 'when activated for a user with a string id' => sub {
        before sub {
            $toggle->activate_user( chat => stub( id => 'user-72' ) );
        };

        it 'is active for that user' => sub {
            ok $toggle->is_active( chat => stub( id => 'user-72' ) );
        };

        it 'remains inactive for other users' => sub {
            ok !$toggle->is_active( chat => stub( id => 'user-12' ) );
        };

        it 'appears in the feature list' => sub {
            ok grep { $_ eq 'chat' } $toggle->features;
        };
    };

    context 'when deactivated for a user' => sub {
        before sub {
            $toggle->activate_user( chat => stub( id => 42 ) );
            $toggle->activate_user( chat => stub( id => 4242 ) );
            $toggle->activate_user( chat => stub( id => 24 ) );
            $toggle->deactivate_user( chat => stub( id => 42 ) );
            $toggle->deactivate_user( chat => stub( id => "4242" ) );
        };

        it 'is inactive for that user' => sub {
            ok !$toggle->is_active( chat => stub( id => 42 ) );
        };

        it 'remains active for other active users' => sub {
            ok $toggle->is_active( chat => stub( id => 24 ) );
        };
    };

    context 'when activated for 20% of users' => sub {
        before sub {
            $toggle->activate_percentage( chat => 20 );
        };

        it 'is active for roughly 200/1000 users' => sub {
            my @active
                = grep { $toggle->is_active( chat => stub( id => $_ ) ) }
                1 .. 1000;
            ok( 190 <= @active && @active <= 210 );
        };

        it 'is active for roughly 40/200 users' => sub {
            my @active
                = grep { $toggle->is_active( chat => stub( id => $_ ) ) }
                1 .. 200;
            ok( 35 <= @active && @active <= 45 );
        };

        it 'appears in the feature list' => sub {
            ok grep { $_ eq 'chat' } $toggle->features;
        };
    };

    context 'when activated for 5% of users' => sub {
        before sub {
            $toggle->activate_percentage( chat => 5 );
        };

        it 'is active for roughly 5/100 users' => sub {
            my @active
                = grep { $toggle->is_active( chat => stub( id => $_ ) ) }
                1 .. 100;
            ok( 3 <= @active && @active <= 7 );
        };
    };

    context 'when the percentage of users is increased' => sub {
        my ( @old_active, @new_active );

        before sub {
            $toggle->activate_percentage( chat => 5 );
            @old_active
                = grep { $toggle->is_active( chat => stub( id => $_ ) ) }
                1 .. 100;
            $toggle->activate_percentage( chat => 10 );
            @new_active
                = grep { $toggle->is_active( chat => stub( id => $_ ) ) }
                1 .. 100;
        };

        it 'remains active for the previous users' => sub {
            cmp_deeply( \@new_active, superbagof(@old_active) );
        };
    };

    context 'when the percentage of users is deactivated' => sub {
        before sub {
            $toggle->activate_percentage( chat => 100 );
            $toggle->deactivate_percentage('chat');
        };

        it 'becomes inactive for all users' => sub {
            ok !$toggle->is_active( chat => stub( id => 24 ) );
        };
    };

    context 'when given variants' => sub {
        before sub {
            $toggle->set_variants(
                chat => [
                    a => 20,
                    b => 40,
                ],
            );
        };

        it 'returns variant "a" for roughly 40/200 users' => sub {
            my @active
                = grep { 'a' eq $toggle->variant( chat => stub( id => $_ ) ) }
                1 .. 200;

            ok( 35 <= @active && @active <= 45 );
        };

        it 'returns variant "b" for roughly 40/100 users' => sub {
            my @active
                = grep { 'b' eq $toggle->variant( chat => stub( id => $_ ) ) }
                1 .. 100;

            ok( 39 <= @active && @active <= 41 );
        };
    };
};

runtests unless caller();
