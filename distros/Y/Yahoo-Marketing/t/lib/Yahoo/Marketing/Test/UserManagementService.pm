package Yahoo::Marketing::Test::UserManagementService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;
use Test::More;

use Yahoo::Marketing::User;
use Yahoo::Marketing::Address;
use Yahoo::Marketing::Authorization;
use Yahoo::Marketing::Role;
use Yahoo::Marketing::BillingUser;
use Yahoo::Marketing::CreditCardInfo;
use Yahoo::Marketing::UserManagementService;

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub test_get_authorizations : Test(4) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::UserManagementService->new->parse_config( section => $self->section );

    my @auth = $ysm_ws->getAuthorizationsForUser( username => $ysm_ws->username );
    ok( @auth, 'can get authorization' );
    ok( ( grep { $_->role->name eq 'MasterAccountAdministrator' } @auth ), 'can find right authorization for user' );

    my @user_auths = $ysm_ws->getAuthorizedUsersByMasterAccountID;
    my $find = 0;
    foreach my $user_auth ( @user_auths ) {
        if ( $user_auth->username eq $ysm_ws->username and 
                 $user_auth->role->name eq 'MasterAccountAdministrator' ) {
            $find = 1;
            last;
        }
    }
    is( $find, 1, 'find authorized user in master account' );

    @user_auths = $ysm_ws->getAuthorizedUsersByAccountID( accountIDs => [ $ysm_ws->account ] );

    $find = 0;
    foreach my $user_auth ( @user_auths ) {
        if ( $user_auth->username eq $self->common_test_data( 'test_user' ) and 
                 $user_auth->role->name eq 'AccountManager' ) {
            $find = 1;
            last;
        }
    }
    is( $find, 0, 'should not find authorized user in account' );

}


sub test_get_available_roles_by_account_id : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::UserManagementService->new->parse_config( section => $self->section );
    my @roles = $ysm_ws->getAvailableRolesByAccountID(
        accountType => 'MasterAccount',
        accountID   => $ysm_ws->master_account,
    );

    is( join('', map { $_->name } @roles), 'MasterAccountAdministrator', 'roles are right' );

    @roles = $ysm_ws->getAvailableRolesByAccountID(
        accountType => 'Account',
        accountID   => $ysm_ws->account,
    );

    is( join('', sort {$a cmp $b} map { $_->name } @roles), 'AccountManagerAnalystCampaignManager', 'roles are right' );
}


sub test_get_capabilities_for_role : Test(1) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::UserManagementService->new->parse_config( section => $self->section );
    my @capabilities = $ysm_ws->getCapabilitiesForRole(
        role => Yahoo::Marketing::Role->new->name( 'MasterAccountAdministrator' ),
    );

    ok( @capabilities, 'capabilities are right' );
}


sub test_get_and_update_my_address : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::UserManagementService->new->parse_config( section => $self->section );
    my $address = Yahoo::Marketing::Address->new
                                           ->address1( '789 Grand Ave' )
                                           ->city('Burbank')
                                           ->state('CA')
                                           ->country('US')
                                           ->postalCode('91504');

    $ysm_ws->updateMyAddress(
        address => $address,
        updateAll => 'true',
    );

    is( $ysm_ws->getMyAddress->address1, '789 Grand Ave', 'address is right' );

    my $new_address = Yahoo::Marketing::Address->new->address1( '123 Hollywood Blvd' );
    $ysm_ws->updateMyAddress(
        address => $new_address,
        updateAll => 'false',
    );

    is( $ysm_ws->getMyAddress->address1, $new_address->address1, 'address is right' );
}


sub test_get_my_authorization : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::UserManagementService->new->parse_config( section => $self->section );
    my @auths = $ysm_ws->getMyAuthorizations;

    ok( @auths );

    my $found = 0;
    foreach my $auth ( @auths ) {
        $found++ if $auth->accountID eq $ysm_ws->account or $auth->accountID eq $ysm_ws->master_account;
    }

    ok( $found, 'get auth right' );
}


sub test_get_and_update_my_user_info : Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::UserManagementService->new->parse_config( section => $self->section );
    my $user = $ysm_ws->getMyUserInfo;

    ok( $user, 'can get my user info' );

    my $phone = '212-555-'.substr($$,0,4);

    $ysm_ws->updateMyUserInfo(
        userInfo  => $user->workPhone( $phone ),
        updateAll => 'false',
    );

    my $fetched_user = $ysm_ws->getMyUserInfo;

    is( $fetched_user->workPhone, $phone, 'work phone updated' );

    $ysm_ws->updateMyUserInfo(
        userInfo => $user,
        updateAll => 'false',
    );
    my $fetched_user2 = $ysm_ws->getMyUserInfo;

    is( $fetched_user2->workPhone, $user->workPhone, 'work phone update right' );
}


sub test_get_and_update_user_address : Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::UserManagementService->new->parse_config( section => $self->section );
    my $address = $ysm_ws->getUserAddress( username => $ysm_ws->username );

    ok( $address );

    my $new_address = $address;
    $ysm_ws->updateUserAddress(
        username => $ysm_ws->username,
        address => $new_address->address1( '789 Grand Ave' ),
        updateAll => 'false',
    );

    is( $ysm_ws->getUserAddress( username => $ysm_ws->username )->address1, '789 Grand Ave', 'address is right' );

    $ysm_ws->updateUserAddress(
        username => $ysm_ws->username,
        address => $address,
        updateAll => 'false',
    );

    is( $ysm_ws->getUserAddress( username => $ysm_ws->username )->address1, $address->address1, 'address is right' );
}


sub test_get_and_update_user_info : Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::UserManagementService->new->parse_config( section => $self->section );
    my $user = $ysm_ws->getUserInfo( username => $ysm_ws->username );

    ok( $user );

    my $new_user = $user;
    $ysm_ws->updateUserInfo(
        username => $ysm_ws->username,
        userInfo => $new_user->workPhone( '818-555-7890' )->email( 'test@yahoo-inc.com' ),
        updateAll => 'true',
    );
    my $fetched_user = $ysm_ws->getUserInfo( username => $ysm_ws->username );

    is( $fetched_user->workPhone, '818-555-7890', 'work phone is right' );

    $ysm_ws->updateUserInfo(
        username => $ysm_ws->username,
        userInfo => $user,
        updateAll => 'false',
    );
    my $fetched_user2 = $ysm_ws->getUserInfo( username => $ysm_ws->username );

    is( $fetched_user2->workPhone, $user->workPhone, 'phone is right' );
}


sub test_test_username : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::UserManagementService->new->parse_config( section => $self->section );

    # we know this username should not be available, we're using it!
    is( $ysm_ws->testUsername( username => $ysm_ws->username ), 'false', 'our username is not available' );

    # we hope this randomish username is available
    is( $ysm_ws->testUsername( username => $self->_make_username ), 'true', 'randomish username is available' );
}



sub startup_test_user_management_service : Test(startup) {
    my $self = shift;

    $self->common_test_data( 'test_user', $self->get_user ) unless defined $self->common_test_data( 'test_user' );
}

sub cleanup_user : Test(shutdown) {
    my $self = shift;

    $self->common_test_data( 'test_user', undef );
}


sub _make_username {
    my $self = shift;

    my $time = time();
    return 'tu'.substr( $time, length($time) - 8, length( $time ) );
}

sub get_user {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::UserManagementService->new->parse_config( section => $self->section );

    my @user_names = $ysm_ws->getUsersInCompany;
    foreach my $username ( @user_names ) {
        next if $username eq $ysm_ws->username;
        return $username if $ysm_ws->getUserStatus( username => $username ) eq 'Active';
    }
    # this company has no more active user to test.
    return;
}


1;


__END__

# addUser
# addAuthorizationsForUser
# addAuthorizationForUser
# getAvailableRolesByAccountID
# testUsername
# getMyUserInfo
# getMyAddress
# updateMyUserInfo
# updateMyAddress
# updateMyEmail
# getMyAuthorizations
# updateUserInfo
# updateUserAddress
# getUserInfo
# getUserAddress
# getUserEmail
# getUserStatus
# enableUser
# disableUser
# getAuthorizationsForUser
# getUsersInCompany
# getAuthorizedUsersByMasterAccountID
# getAuthorizedUsersByAccountID
# deleteAuthorizationsForUser
# deleteAuthorizationForUser
# deleteUser
# deleteUsers
# updateMyPassword
# resetUserPassword
# getCapabilitiesForRole
# addCreditCard
# updateCreditCard
# getPaymentMethods



