### AUTO-GENERATED FILE ###
### DO NOT EDIT. YOUR CHANGES WILL BE LOST. ###
package WebService::Bonusly;
$WebService::Bonusly::VERSION = '1.001';
use v5.14;
use Moose;

extends 'WebService::Bonusly::Base';

use WebService::Bonusly::Authentication;
use WebService::Bonusly::Bonuses;
use WebService::Bonusly::Companies;
use WebService::Bonusly::Leaderboards;
use WebService::Bonusly::Redemptions;
use WebService::Bonusly::Rewards;
use WebService::Bonusly::Users;
use WebService::Bonusly::Values;

# ABSTRACT: A handy library for accessing the Bonus.ly API


has authentication => (
    is          => 'ro',
    isa         => 'WebService::Bonusly::Authentication',
    required    => 1,
    lazy        => 1,
    builder     => __PACKAGE__->_service_builder('authentication'),
);


has bonuses => (
    is          => 'ro',
    isa         => 'WebService::Bonusly::Bonuses',
    required    => 1,
    lazy        => 1,
    builder     => __PACKAGE__->_service_builder('bonuses'),
);


has companies => (
    is          => 'ro',
    isa         => 'WebService::Bonusly::Companies',
    required    => 1,
    lazy        => 1,
    builder     => __PACKAGE__->_service_builder('companies'),
);


has leaderboards => (
    is          => 'ro',
    isa         => 'WebService::Bonusly::Leaderboards',
    required    => 1,
    lazy        => 1,
    builder     => __PACKAGE__->_service_builder('leaderboards'),
);


has redemptions => (
    is          => 'ro',
    isa         => 'WebService::Bonusly::Redemptions',
    required    => 1,
    lazy        => 1,
    builder     => __PACKAGE__->_service_builder('redemptions'),
);


has rewards => (
    is          => 'ro',
    isa         => 'WebService::Bonusly::Rewards',
    required    => 1,
    lazy        => 1,
    builder     => __PACKAGE__->_service_builder('rewards'),
);


has users => (
    is          => 'ro',
    isa         => 'WebService::Bonusly::Users',
    required    => 1,
    lazy        => 1,
    builder     => __PACKAGE__->_service_builder('users'),
);


has values => (
    is          => 'ro',
    isa         => 'WebService::Bonusly::Values',
    required    => 1,
    lazy        => 1,
    builder     => __PACKAGE__->_service_builder('values'),
);



__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bonusly - A handy library for accessing the Bonus.ly API

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    use WebService::Bonusly;
    my $bonusly = WebService::Bonusly->new( token => $token );
        
    $res = $bonusly->authentication->sessions(
        email => '...',
        password => '...',
    );
        
    $res = $bonusly->bonuses->get( id => '...' );
    $res = $bonusly->bonuses->give( reason => '...' );
    $res = $bonusly->bonuses->list;
        
    $res = $bonusly->companies->show;
    $res = $bonusly->companies->update;
        
    $res = $bonusly->leaderboards->standouts;
        
    $res = $bonusly->redemptions->get( id => '...' );
        
    $res = $bonusly->rewards->get( id => '...' );
    $res = $bonusly->rewards->list;
        
    $res = $bonusly->users->add(
        email => '...',
        first_name => '...',
        last_name => '...',
    );
    $res = $bonusly->users->autocomplete( search => '...' );
    $res = $bonusly->users->bonuses( id => '...' );
    $res = $bonusly->users->create_redemption(
        id => '...',
        denomination_id => '...',
    );
    $res = $bonusly->users->delete( id => '...' );
    $res = $bonusly->users->get( id => '...' );
    $res = $bonusly->users->list;
    $res = $bonusly->users->me;
    $res = $bonusly->users->neighborhood( id => '...' );
    $res = $bonusly->users->redemptions( id => '...' );
    $res = $bonusly->users->update( id => '...' );
        
    $res = $bonusly->values->get( id => '...' );
    $res = $bonusly->values->list;

=head1 DESCRIPTION

This is a fairly simple library for performing actions with the Bonus.ly API.

=head1 ERRORS

Normally bonusly will return C<< { success => 0, message => $reason } >> when
there are errors, but on the off chance that something went really wrong,
C<WebService::Bonusly> will synthesize a data structure like this:

 {
     success => 0,
     message => 'Not Found',
     status => 404,
     content => "<html>...",
     response_object => HTTP::Response->new(...),
 }

When handling errors, you B<may> want to consider checking if there is a
C<response_object> and logging its contents somewhere.

=head1 ATTRIBUTES

=head2 token

This is the access token to use to perform actions with.

=head2 debug

This is a boolean flag that, when set to true, causes messages to be printed to STDERR about what is being sent to and received from bonus.ly. 

This is done through calls to the C<print_debug> method.

=head2 authentication

This provides methods for accessing the Authentication aspects of the API. This provides the following methods:

=head3 sessions

    $res = $bonusly->authentication->sessions(%params);

Performs a POST against C</api/v1/sessions> at bonus.ly.

Required Parameters: C<email>, C<password>

=head2 bonuses

This provides methods for accessing the Bonuses aspects of the API. This provides the following methods:

=head3 get

    $res = $bonusly->bonuses->get(%params);

Performs a GET against C</api/v1/bonuses/:id> at bonus.ly.

Required Parameters: C<id>

=head3 give

    $res = $bonusly->bonuses->give(%params);

Performs a POST against C</api/v1/bonuses> at bonus.ly.

Required Parameters: C<reason>

Optional Parameters: C<giver_email>, C<parent_bonus_id>, C<receiver_email>, C<amount>

=head3 list

    $res = $bonusly->bonuses->list(%params);

Performs a GET against C</api/v1/bonuses> at bonus.ly.

Optional Parameters: C<limit>, C<skip>, C<start_time>, C<end_time>, C<non_zero>, C<top_level>, C<giver_email>, C<receiver_email>, C<user_email>, C<hashtag>, C<include_children>

=head2 companies

This provides methods for accessing the Companies aspects of the API. This provides the following methods:

=head3 show

    $res = $bonusly->companies->show;

Performs a GET against C</api/v1/companies/show> at bonus.ly.

=head3 update

    $res = $bonusly->companies->update(%params);

Performs a PUT against C</api/v1/companies/update> at bonus.ly.

Optional Parameters: C<name>, C<custom_properties>

The C<custom_properties> parameter must be given a reference to a hash.

=head2 leaderboards

This provides methods for accessing the Leaderboards aspects of the API. This provides the following methods:

=head3 standouts

    $res = $bonusly->leaderboards->standouts(%params);

Performs a GET against C</api/v1/analytics/standouts> at bonus.ly.

Optional Parameters: C<role>, C<value>, C<limit>, C<period>, C<custom_property_name>, C<custom_property_value>

=head2 redemptions

This provides methods for accessing the Redemptions aspects of the API. This provides the following methods:

=head3 get

    $res = $bonusly->redemptions->get(%params);

Performs a GET against C</api/v1/redemptions/:id> at bonus.ly.

Required Parameters: C<id>

=head2 rewards

This provides methods for accessing the Rewards aspects of the API. This provides the following methods:

=head3 get

    $res = $bonusly->rewards->get(%params);

Performs a GET against C</api/v1/rewards/:id> at bonus.ly.

Required Parameters: C<id>

=head3 list

    $res = $bonusly->rewards->list(%params);

Performs a GET against C</api/v1/rewards> at bonus.ly.

Optional Parameters: C<catalog_country>, C<request_country>, C<personalize_for>

=head2 users

This provides methods for accessing the Users aspects of the API. This provides the following methods:

=head3 add

    $res = $bonusly->users->add(%params);

Performs a POST against C</api/v1/users> at bonus.ly.

Required Parameters: C<email>, C<first_name>, C<last_name>

Optional Parameters: C<custom_properties>, C<user_mode>, C<budget_boost>, C<external_unique_id>

The C<custom_properties> parameter must be given a reference to a hash.

=head3 autocomplete

    $res = $bonusly->users->autocomplete(%params);

Performs a GET against C</api/v1/users/autocomplete> at bonus.ly.

Required Parameters: C<search>

=head3 bonuses

    $res = $bonusly->users->bonuses(%params);

Performs a GET against C</api/v1/users/:id/bonuses> at bonus.ly.

Required Parameters: C<id>

Optional Parameters: C<skip>, C<start_time>, C<hashtag>, C<end_time>, C<include_children>, C<limit>, C<role>

=head3 create_redemption

    $res = $bonusly->users->create_redemption(%params);

Performs a POST against C</api/v1/users/:id/redemptions> at bonus.ly.

Required Parameters: C<id>, C<denomination_id>

=head3 delete

    $res = $bonusly->users->delete(%params);

Performs a DELETE against C</api/v1/users/:id> at bonus.ly.

Required Parameters: C<id>

=head3 get

    $res = $bonusly->users->get(%params);

Performs a GET against C</api/v1/users/:id> at bonus.ly.

Required Parameters: C<id>

=head3 list

    $res = $bonusly->users->list(%params);

Performs a GET against C</api/v1/users> at bonus.ly.

Optional Parameters: C<limit>, C<skip>, C<email>, C<sort>

=head3 me

    $res = $bonusly->users->me;

Performs a GET against C</api/v1/users/me> at bonus.ly.

=head3 neighborhood

    $res = $bonusly->users->neighborhood(%params);

Performs a GET against C</api/v1/users/:id/neighborhood> at bonus.ly.

Required Parameters: C<id>

Optional Parameters: C<days>

=head3 redemptions

    $res = $bonusly->users->redemptions(%params);

Performs a GET against C</api/v1/users/:id/redemptions> at bonus.ly.

Required Parameters: C<id>

Optional Parameters: C<limit>, C<skip>

=head3 update

    $res = $bonusly->users->update(%params);

Performs a PUT against C</api/v1/users/:id> at bonus.ly.

Required Parameters: C<id>

Optional Parameters: C<email>, C<first_name>, C<last_name>, C<custom_properties>, C<user_mode>, C<budget_boost>, C<external_unique_id>

The C<custom_properties> parameter must be given a reference to a hash.

=head2 values

This provides methods for accessing the Values aspects of the API. This provides the following methods:

=head3 get

    $res = $bonusly->values->get(%params);

Performs a GET against C</api/v1/values/:id> at bonus.ly.

Required Parameters: C<id>

=head3 list

    $res = $bonusly->values->list;

Performs a GET against C</api/v1/values> at bonus.ly.

=head1 DEVELOPMENT

If you are interested in helping develop this library. Please check it out from github. See L<https://github.com/zostay/WebService-Bonusly>. The library is automatically generated from a script named F<apigen.pl>. To build the library you will need to install L<Dist::Zilla> and run:

    dzil authordeps | cpanm
    dzil build

Instead of running the "dzil build" command you may also run:

    ./apigen.pl

The templates for generating the code are found in F<tmpl>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
