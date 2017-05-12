package WWW::BigDoor::Resource;

use strict;
use warnings;
use Carp;

#use Smart::Comments -ENV;

use base qw(Class::Accessor);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
    qw(created_timestamp modified_timestamp pub_title pub_description end_user_title end_user_description resource_name)
);

sub new {
    my ( $class, $args ) = @_;

    ## new...
    my $self = {};
    ## args: $args
    ### check: ref( $args ) eq 'HASH'

    foreach my $k ( keys %{$args} ) {
        ## key: $k
        ## val: $args->{$k}
        # FIXME restrict allowed key names
        $self->{$k} = $args->{$k};
    }

    bless( $self, $class );
    return $self;
}

sub end_point {
    my ( $self ) = @_;

    my $ep = $self->_end_point;

    if ( $self->_parent_end_point() ) {
        $ep = sprintf '%s/%s/%s',
          $self->_parent_end_point(),
          $self->{$self->_parent_id_attr},
          $self->_end_point();
        ###  ep with parent: $ep
    }
    return $ep;
}

sub all {
    my ( $self, $client ) = @_;
    my $ep = $self->end_point();

    ## end_point: $ep
    ### check: defined $ep
    my $data = $client->GET( $ep );
    my @all;

    ### data: $data

    foreach my $object ( @{@$data[0]} ) {
        ### object: $object
        push @all, $self->new( $object );
        ### next...
    }
    return [@all];
}

sub load {
    my ( $self, $client, $id ) = @_;

    if ( !defined $id && !ref $self ) {
        croak "Should pass object ID\n";
    }
    my $ep = $self->_end_point();

    ## end_point: $ep

    $id = $self->get_id unless defined $id;

    ### check: defined $ep
    ### check: defined $id
    ### end_point: sprintf '%s/%s', $ep, $id
    my $data = $client->GET( sprintf '%s/%s', $ep, $id );

    ### data: $data
    ### check: defined $data

    if ( ref $self ) {
        foreach my $k ( keys %{$data->[0]} ) {
            ## key: $k
            ## val: $args->{$k}
            # FIXME restrict allowed key names
            $self->{$k} = $data->[0]->{$k};
        }
        return $self;
    }

    return $self->new( @$data[0] );
} ## end sub load

sub save {
    my ( $self, $client ) = @_;

    my $ep = $self->end_point();

    ### end_point: $ep
    ### check: defined $ep

    my $payload;
    foreach my $k ( keys %{$self} ) {
        next if ref $self->{$k};
        $payload->{$k} = $self->{$k};
    }

    my $result;

    if ( defined $self->get_id ) {
        $result =
          $client->PUT( sprintf( '%s/%s', $ep, $self->get_id ), {format => 'json'}, $payload );
    }
    else {
        $result = $client->POST( $ep, {format => 'json'}, $payload );
    }
    ### result: $result->[0]
    foreach my $k ( keys %{$result->[0]} ) {
        ## key: $k
        ## val: $args->{$k}
        # FIXME restrict allowed key names
        $self->{$k} = $result->[0]{$k};
    }
    return $self;
} ## end sub save

sub remove {
    my ( $self, $client, $id ) = @_;

    ### remove...
    use Data::Dumper;
    ### self: Dumper( $self )
    my $ep = $self->end_point();

    ### check: defined $ep

    ### check: defined $id
    $id = $self->get_id if ( ref $self && !defined $id );

    ### ref: ref $self
    ### check: defined $id
    ### end_point: sprintf '%s/%s', $ep, $id

    $client->DELETE( sprintf '%s/%s', $ep, $id );
    return;
}

sub _parent_end_point {
    return;
}

sub _end_point {
    my ( $self ) = @_;

    croak "Need object or class named" unless defined $self;

    $self = ref $self if ref $self;

    ### self1: $self

    if ( $self =~ /WWW::BigDoor::(\w+)/x ) {
        $self = $1;
    }

    $self =~ s/([A-Z]+)([A-Z][a-z])/$1_$2/xg;
    $self =~ s/([a-z\d])([A-Z])/$1_$2/xg;

    confess "Can\'t detect class name $self" unless defined $self;

    return lc $self;
}

1;
__END__

=head1 NAME

WWW::BigDoor::Resource - provides a perl OO interface for BigDoor's REST API.

=head1 VERSION

This document describes BigDoor version 0.1.1

=head1 SYNOPSIS

    use WWW::BigDoor;
    use WWW::BigDoor::Resource;

    my $client = new WWW::BigDoor( $APP_SECRET, $APP_KEY );

    my $currency_types = WWW::BigDoor::CurrencyType->all( $client );

    my $currency_type1 = WWW::BigDoor::CurrencyType->load( $client, 1 );

    my $currencies = WWW::BigDoor::Currency->all( $client );

    my $currency_obj = new WWW::BigDoor::Currency(
        {  
            pub_title            => 'Coins',
            pub_description      => 'an example of the Purchase currency type',
            end_user_title       => 'Coins',
            end_user_description => 'can only be purchased',
            currency_type_id     => '1',                                   
            currency_type_title  => 'Purchase',
            exchange_rate        => 900.00,
            relative_weight      => 2,
        }
    );

    $currency_obj->save( $client );

    printf "currency id = %d\n", $currency->get_id;
    
    $currency_obj->remove( $client );

  
=head1 DESCRIPTION

There are following objects available and their corresponding API end points:

=over 

=item Attribute /attribute

=item Award /end_user/{id}/award

=item CurrencyBalance /end_user/{id}/currency_balance

=item Currency /currency

=item CurrencyType /currency_type

=item EndUser /end_user

=item Good /end_user/{id}/good

=item Leaderboard /leaderboard/

=item Level /end_user/

=item NamedAwardCollection /named_award_collection

=item NamedAward /named_award

=item NamedGoodCollection /named_good_collection
 
=item NamedGood /named_collection

=item NamedLevelCollection /named_level_collection

=item NamedLevel /named_level

=item NamedTransactionGroup /named_transaction_group

=item NamedTransaction /named_transaction

=item Profile /end_user/{id}/profile

=item URL /url

=back

For their attributes see online documentation L<http://publisher.bigdoor.com/docs/>

=head1 INTERFACE 

=head3  new( $args )

Constructs a new BigDoor Resource object

=over 4

=item args

Reference to hash of Resource object attributes

=back

=head3 all( $client )

Loads all Resource objects of this type.

=over 4

=item client

WWW::BigDoor client object

=back

=head3 load( $client, [$id] )

Loads single Resource object identified by id or reloads existing object if id omitted.

=over 4

=item client

WWW::BigDoor client object

=item id

BigDoor Resource object ID. If calling object has id attribute defined, $id
parameter is optional

=back

=head3 save( $client )

Saves Resource object. If object has C<id> attribute defined than PUT method is
used, otherwise POST is used.

=over 4

=item client

WWW::BigDoor client object

=back

=head3 remove( $client, [$id] )

=over 4

=item client

WWW::BigDoor client object

=item id

BigDoor Resource object ID. If calling object has id attribute defined, $id
parameter is optional.

=back

=head3 end_point()

Returns corresponding end_point URL for this particular object.

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

In case of HTTP errors check HTTP response code returned by
C<< $client->get_response_code() >> or response body returned by
C<< $client->get_response_content() >>.

For debugging purpose there is result object returned by REST::Client
c<request()> call which could be accessed through C<get_request()> and this
result object contains HTTP::Response object.

=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
WWW::BigDoor::Resource requires no configuration files or environment variables.

=head1 DEPENDENCIES

The module requires WWW::BigDoor module and all its dependecies.

=head1 DIFFERENCES FROM PYTHON BIGDOORKIT

Method name C<get()> was changed to C<load()> to avoid conflict with C<get()>
method inherited from Class::Accessor. Method name C<delete> was changed to
C<remove()> to avoid conflict with Perl internal method C<delete>.


=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Code is not fully covered by tests and there are not much tests for failures
and, as consequence, not much parameters validation or checking for error
conditions. Don't expect too much diagnosticts in case of errors.

Objects correspondig to following end points are not currently implemented:

=over

=item *

http://api.bigdoor.com/api/publisher/{application_key}/auth

=item *

http://api.bigdoor.com/api/publisher/{application_key}/proxy

=item *

http://api.bigdoor.com/api/publisher/{application_key}/transaction_summary

=item *

http://api.bigdoor.com/api/publisher/{application_key}/award_summary

=item *

http://api.bigdoor.com/api/publisher/{application_key}/level_summary

=item *

http://api.bigdoor.com/api/publisher/{application_key}/good_summary

=back

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-bigdoor@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

WWW::BigDoor for procedural interface to BigDoor REST API

=head1 AUTHOR

Alex L. Demidov  C<< <alexeydemidov@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

BigDoor Open License
Copyright (c) 2010 BigDoor Media, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to
do so, subject to the following conditions:

- This copyright notice and all listed conditions and disclaimers shall
be included in all copies and portions of the Software including any
redistributions in binary form.

- The Software connects with the BigDoor API (api.bigdoor.com) and
all uses, copies, modifications, derivative works, mergers, publications,
distributions, sublicenses and sales shall also connect to the BigDoor API and
shall not be used to connect with any API, software or service that competes
with BigDoor's API, software and services.

- Except as contained in this notice, this license does not grant you rights to
use BigDoor Media, Inc. or any contributors; name, logo, or trademarks.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
