package ZCS::Admin;

use strict;
use warnings;
use LWP::UserAgent qw();
use URI qw();
use ZCS::Admin::Interfaces::Admin::AdminSoap12 ();

#OFF use SOAP::Lite ( +trace => "debug" );
our $VERSION = '0.07';

=head1 NAME

ZCS::Admin - module for the Zimbra Collaboration Suite (ZCS) Admin web services

=head1 SYNOPSIS

  use ZCS::Admin;

  my $zimbra = ZCS::Admin->new;
  my $resp = $zimbra->auth( name => 'admin', password => 'mypass' );
  die ZCS::Admin->faultinfo($resp) if !$resp;
  ...

=head1 DESCRIPTION

The ZCS::Admin Perl module uses SOAP to interface with the Zimbra
Collaboration Suite Admin web services (primarily SOAP but also REST).

=head1 METHODS

=head2 new

  my $z = ZCS::Admin->new(
      name     => 'zimbra',
      password => $pass,
  );
  die ZCS::Admin->faultinfo($z) if !$z;

Create a new instance of ZCS::Admin.  On errors a SOAP fault object is
returned.  See SOAP::WSDL documentation for details of the SOAP fault
object.

During object instantiation the L<auth> method is called to ensure
communcation with the server is possible.

The default the Admin SOAP service URL is typically:

  https://127.0.0.1:7071/service/admin/soap

Use the 'proxy' argument to specify a different URL than the default:

  ...->new( proxy => 'https://my.svr.loc:7071/service/admin/soap', ... )

=cut

sub new {
    my ( $class, %args ) = @_;

    my $info = "name => <admin>, password => <pass>, [proxy => <soapurl>]";
    Carp::confess("usage: new($info)\n")
      unless ( exists $args{name} and $args{password} );

    my $self = {%args};
    bless( $self, $class );

    my $r = $self->cl;
    return $r ? $self->auth : $r;
}

=pod

A ZCS::Admin has the following object attributes:

=over 4

=item name

The user name for authentication.

=item password

The password for authentication.

=item proxy

The URL of the ZCS Admin SOAP service

=back

=cut

sub name     { @_ > 1 ? $_[0]->{name}     = $_[1] : $_[0]->{name}; }
sub password { @_ > 1 ? $_[0]->{password} = $_[1] : $_[0]->{password}; }
sub proxy    { @_ > 1 ? $_[0]->{proxy}    = $_[1] : $_[0]->{proxy}; }

=head2 new_element

  $z->new_element($element);

Get the instance of a "ZCS::Admin::Elements::$element" object.

Note: This can be used as a class or object method.

=cut

sub new_element {
    my ( $self, $elem, @args ) = @_;

    # default to ZCS::Admin::Elements::...
    $elem = __PACKAGE__ . "::Elements::" . $elem
      if ( $elem and $elem !~ /::/ );
    eval "require $elem" || die $@;    ## no critic (ProhibitStringyEval)

    return $elem->new(@args);
}

=head2 new_type

  $z->new_type($element);

Get the instance of a "ZCS::Admin::Types::$type" object.

Note: This can be used as a class or object method.

=cut

sub new_type {
    my ( $self, $type, @args ) = @_;

    # default to ZCS::Admin::Types::...
    $type = __PACKAGE__ . "::Types::" . $type
      if ( $type and $type !~ /::/ );
    eval "require $type" || die $@;    ## no critic (ProhibitStringyEval)

    return $type->new(@args);
}

=head2 new_fault

  $z->new_fault( \%args );

Get the instance of a SOAP::WSDL::SOAP::Typelib::Fault11.

Note: This can be used as a class or object method.

Warning: the object type is likely to change in a future release but
the object will still likely behave in a similar manner to the current
object.

=cut

# faultcode => ..., faultstring => ...
sub new_fault {
    my ( $self, %args ) = @_;
    require SOAP::WSDL::SOAP::Typelib::Fault11;
    return SOAP::WSDL::SOAP::Typelib::Fault11->new( \%args );
}

=head2 faultinfo

  $z->faultinfo($fault);

Note: This can be used as a class or object method.

Returns a string containing the concatenation of "Code" from the ZCS
fault detail (if available), the "faultstring", and the "Trace" from
the ZCS fault detail (if available).

=cut

sub faultinfo {
    my ( $class, $fault ) = @_;
    return "<no fault info>" unless ref($fault);

    my ( $code, $trace ) = ( [], [] );
    my $error = $fault->get_detail ? $fault->get_detail->get_Error : undef;
    ( $code, $trace ) = ( [ $error->get_Code ], [ $error->get_Trace ] )
      if ($error);

    return join( "; ", @$code, $fault->get_faultstring, @$trace );
}

=head2 client

Creates and returns a new instance of
ZCS::Admin::Interfaces::Admin::AdminSoap12, which is the underlying
object being used to communicate with the ZCS Admin SOAP service.  On
errors a SOAP fault object is returned.  See SOAP::WSDL documentation
for details of the SOAP fault object.

=cut

sub client {
    my ($self) = @_;

    my $r = $self->{_client};
    unless ($r) {
        my @proxy = $self->proxy ? ( proxy => $self->proxy ) : ();
        $r = $self->{_client} =
          ZCS::Admin::Interfaces::Admin::AdminSoap12->new( {@proxy} );
    }
    return $r;    # a client or fault object
}

=head2 cl

Gets a ZCS::Admin::Interfaces::Admin::AdminSoap12 object via client()
and calls auth() if the current session authentication information has
expired or no session information is already stored.

=cut

sub cl {
    my ($self) = @_;

    my $r = $self->client;
    if ($r) {
        my $exp = $self->{_auth}->{expires};
        if ( !$exp or time() > $exp ) {
            my $cl = $r;
            $r = $self->auth;
            $r = $cl if $r;
        }
    }

    return $r;    # a client or fault object
}

=head1 REST and SOAP Interface Calls

=head2 auth

Calls Auth on the underlying ZCS Admin object, removes stale context()
information and caches new authentication information on success.
Returns itself (for call chaining if desired) or a SOAP Fault object
on failures.

=cut

sub auth {
    my ($self) = @_;

    my %auth = ( map { $_ => $self->$_ } qw(name password) );
    my $r = $self->client->Auth( \%auth );
    if ($r) {
        delete $self->{_context};
        $self->{_auth} = {
            expires   => $r->get_lifetime / 1000 + time(),
            sessionId => $r->get_sessionId,
            authToken => $r->get_authToken,
        };
    }

    return $r ? $self : $r;
}

=head2 delegateauth

  $z->delegateauth( name => $acct );

Calls DelegateAuth on the underlying ZCS Admin object. And returns results.

Probably need to do more but this is a start. Probably need some sort of
context updating in most cases. But not sure how we should manage multiple
contexts and push/pop them as we need.

Returns DelegateAuth response for now.

=cut

sub delegateauth {
    my ( $self, $by, $acct ) = @_;

    my $s = $self->new_type( "GetAccountSpecifier", { value => $acct } );
    $s->attr( { "by" => $by } );

    my $e = $self->new_element( "DelegateAuthRequest", { account => $s } );
    return $self->cl->DelegateAuth( $e, $self->context );
}

=head2 context

Returns a context element object using cached information if it exists
or by calling cl() if no cached data is available (auth() clears a
cached context object if re-authentication has taken place).

=cut

sub context {
    my ($self) = @_;

    my $r = $self->{_context};
    return $r if $r;

    $r = $self->cl;
    if ($r) {
        $r =
          $self->new_element( "context",
            { map { $_ => $self->{_auth}->{$_} } qw(sessionId authToken) } );
        $self->{_context} = $r if $r;
    }

    return $r;
}

=head2 createaccount

  $z->createaccount( name => $name, password => $password, a => \@attr );

=cut

sub createaccount {
    my ( $self, %args ) = @_;

    my @attr = @{ delete $args{a} || [] };
    my @item = $self->item_from_attr(@attr);
    $args{a} = \@item if @item;

    my $e = $self->new_element( "CreateAccountRequest", {%args} );
    return $self->cl->CreateAccount( $e, $self->context );
}

=head2 getaccount

=head2 getaccountinfo

  $z->getaccount( name => $acct );
  $z->getaccountinfo( name => $acct );

Arguments:

=over 4

=item {id|name} => $acct

=back

=cut

sub getaccount {
    my ( $self, $by, $acct ) = @_;

    my $s = $self->new_type( "GetAccountSpecifier", { value => $acct } );
    $s->attr( { "by" => $by } );

    my $e = $self->new_element( "GetAccountRequest", { account => $s } );
    return $self->cl->GetAccount( $e, $self->context );
}

sub getaccountinfo {
    my ( $self, $by, $acct ) = @_;

    my $s = $self->new_type( "GetAccountSpecifier", { value => $acct } );
    $s->attr( { "by" => $by } );

    my $e = $self->new_element( "GetAccountInfoRequest", { account => $s } );
    return $self->cl->GetAccountInfo( $e, $self->context );
}

=head2 getaccountid

  my $id = $z->getaccountid($acct);

=cut

# BUG?: return fault if no $id is found? (shouldn't happen but...)
sub getaccountid {
    my ( $self, $acct ) = @_;

    my $r = $self->getaccountinfo( "name" => $acct );
    return $r if !$r;

    # use list context: there should be only one element/id in the list!
    my ($id) = $self->get_from_a( $r->get_a, "zimbraid" );
    return $id;
}

=head2 addaccountalias

  $z->addaccountalias( name => $acct, alias => $alias );

Arguments:

=over 4

=item {id|name} => $acct

=back

=cut

sub addaccountalias {
    my ( $self, $by, $acct, %args ) = @_;

    my $id = $acct;
    if ( $by ne "id" ) {
        $id = $self->getaccountid($acct);
        return $id if ( !$id );
    }

    my $e =
      $self->new_element( "AddAccountAliasRequest", { id => $id, %args } );
    return $self->cl->AddAccountAlias( $e, $self->context );
}

=head2 removeaccountalias

  $z->removeaccountalias( name => $acct, alias => $alias );

Arguments:

=over 4

=item {id|name} => $acct

=back

=cut

sub removeaccountalias {
    my ( $self, $by, $acct, %args ) = @_;

    my $id = $acct;
    if ( $by ne "id" ) {
        $id = $self->getaccountid($acct);
        return $id if ( !$id );
    }

    my $e =
      $self->new_element( "RemoveAccountAliasRequest", { id => $id, %args } );
    return $self->cl->RemoveAccountAlias( $e, $self->context );
}

=head2 modifyaccount

  $z->modifyaccount( name => $acct, attr1 => val1, attr2 => val2, ... );

Arguments:

=over 4

=item {id|name} => $acct

=back

=cut

sub modifyaccount {
    my ( $self, $by, $acct, @attr ) = @_;

    my $id = $acct;
    if ( $by ne "id" ) {
        $id = $self->getaccountid($acct);
        return $id if ( !$id );
    }

    my %args;
    my @item = $self->item_from_attr(@attr);
    $args{a} = \@item if @item;

    my $e = $self->new_element( "ModifyAccountRequest", { id => $id, %args } );
    return $self->cl->ModifyAccount( $e, $self->context );
}

=head2 renameaccount

  $z->renameaccount( name => $acct, $newname );

Arguments:

=over 4

=item {id|name} => $acct

=item $newname

=back

=cut

sub renameaccount {
    my ( $self, $by, $acct, $newname ) = @_;

    my $id = $acct;
    if ( $by ne "id" ) {
        $id = $self->getaccountid($acct);
        return $id if ( !$id );
    }

    return $self->cl->RenameAccount( { id => $id, newName => $newname },
        $self->context );
}

=head2 deleteaccount

  $z->deleteaccount( name => $acct );

Arguments:

=over 4

=item {id|name} => $acct

=back

=cut

sub deleteaccount {
    my ( $self, $by, $acct ) = @_;

    my $id = $acct;
    if ( $by ne "id" ) {
        $id = $self->getaccountid($acct);
        return $id if ( !$id );
    }

    return $self->cl->DeleteAccount( { id => $id }, $self->context );
}

=head2 getcos

  $z->getcos( name => $cos, @attrs );

Arguments:

=over 4

=item {id|name} => $cos

=item @attrs (optional)

=back

=cut

sub getcos {
    my ( $self, $by, $cos, @attr ) = @_;

    my $gcs = $self->new_type( "GetCosSpecifier", { value => $cos } );
    $gcs->attr( { "by" => $by } );

    my $gce = $self->new_element( "GetCosRequest", { cos => $gcs } );
    $gce->attr( { "attrs" => join( ",", @attr ) } ) if @attr;

    return $self->cl->GetCos( $gce, $self->context );
}

=head2 getcosid

  $z->getcosid($cos);

=cut

sub getcosid {
    my ( $self, $cos ) = @_;

    my $r = $self->getcos( "name" => $cos );
    return $r if !$r;
    return $r->get_cos->attr->get_id;
}

=head2 getserver

  $z->getserver( name => $svr, %args);

Arguments:

=over 4

=item {id|name} => $svr

=item applyConfig => 0|1

=item attrs => "attr1,attr2" || [qw(attr1 attr2)]

=back

=cut

sub getserver {
    my ( $self, $by, $svr, %args ) = @_;

    my $s = $self->new_type( "GetServerSpecifier", { value => $svr } );
    $s->attr( { "by" => $by } );

    my $attrs = delete $args{attrs};
    my @attr  = $attrs ? ( ref($attrs) ? @$attrs : ($attrs) ) : ();
    my $e     = $self->new_element( "GetServerRequest", { server => $s } );
    $e->attr( { ( @attr ? ( "attrs" => join( ",", @attr ) ) : () ), %args, } );
    return $self->cl->GetServer( $e, $self->context );
}

=head2 searchdirectory

  $z->searchdirectory( query => query, %args );

Arguments:

=over 4

=item query => $query

=item limit => $limit

=item types => "type1,type2,..."

=item ...

=back

=cut

sub searchdirectory {
    my ( $self, %args ) = @_;

    my $q = delete $args{query};
    my $e = $self->new_element( "SearchDirectoryRequest", { query => $q } );
    $e->attr( \%args ) if %args;

    return $self->cl->SearchDirectory( $e, $self->context );
}

=head2 enablearchive

  $z->enablearchive( {id|name} => $acct, %args );

Arguments:

=over 4

=item {id|name} => $acct # acct-for-which-archiving-is-being-enabled

=item create => 0|1

=item name => $name

=item password => $pass

=item cos => $cosname    # BUG: only allow name at the moment

=item a => \@attr

=back

=cut

# BUG: for performance allow Cos to be an ID or other object?
sub enablearchive {
    my ( $self, $by, $acct, %elem ) = @_;

    my $gas = $self->new_type( "GetAccountSpecifier", { value => $acct } );
    $gas->attr( { "by" => $by } );

    my @item   = $self->item_from_attr( @{ delete $elem{a} || [] } );
    my $create = delete $elem{create};
    my $acos   = delete $elem{cos};
    if ($acos) {
        $acos = $self->new_type( "GetCosSpecifier", { value => $acos } );
        $acos->attr( { "by" => "name" } );
    }

    my $ars = $self->new_type(
        "ArchiveSpecifier",
        {
            %elem,
            ( $acos ? ( cos => $acos )  : () ),
            ( @item ? ( a   => \@item ) : () ),
        }
    );
    $ars->attr( { create => $create } ) if defined($create);

    my $e = $self->new_element(
        "EnableArchiveRequest",
        {
            account => $gas,
            archive => $ars,
        }
    );
    return $self->cl->EnableArchive( $e, $self->context );
}

=head2 disablearchive

  $z->disablearchive( {id|name} => $acct );

Arguments:

=over 4

=item {id|name} => $acct # acct-for-which-archiving-is-already-enabled

=back

=cut

sub disablearchive {
    my ( $self, $by, $acct ) = @_;

    my $s = $self->new_type( "GetAccountSpecifier", { value => $acct } );
    $s->attr( { "by" => $by } );

    my $e = $self->new_element( "DisableArchiveRequest", { account => $s } );
    return $self->cl->DisableArchive( $e, $self->context );
}

###
# Backup

=head2 exportmailbox

 $z->exportmailbox( name => 'user@dom', dest => 'my.svr.loc', ... );

Arguments:

=over 4

=item name => $acct      # account email address

=item dest => $server    # hostname of target server

=item destPort => $port  # target port for mailbox import

=item switchover => 1|0  # update ldap on/off

=item overwrite => 1|0   # replace target mailbox if it exists

=back

Notes: when switchover is 1, ldap is updated to use the target server as the 
mailhost for the account; the original host is not longer in use. 
When switchover is 0, no ldap setting is updated after the move.

if overwrite = 1, the target mailbox will be replaced if it exists

=cut

sub exportmailbox {
    my ( $self, @attrs ) = @_;

    my $s = $self->new_type("ExportMailboxSpecifier");
    $s->attr( {@attrs} );

    my $e = $self->new_element( "ExportMailboxRequest", { account => $s } );
    return $self->cl->ExportMailbox( $e, $self->context );
}

=head2 purgemovedmailbox

  $z->purgemovedmailbox( 'user@dom' );

 <PurgeMovedMailboxRequest>
   <mbox name="{account email address}"/>
 </PurgeMovedMailboxRequest>

Following a successful mailbox move to a new server, the mailbox on the old
server remains.  This allows manually checking the new mailbox to confirm
the move worked.  Afterwards, PurgeMovedMailboxRequest should be used to remove
the old mailbox and reclaim the space.

=cut

sub purgemovedmailbox {
    my ( $self, $name ) = @_;

    my $s = $self->new_type("PurgeMovedMailboxSpecifier");
    $s->attr( { name => $name } );

    my $e = $self->new_element( "PurgeMovedMailboxRequest", { mbox => $s } );
    return $self->cl->PurgeMovedMailbox( $e, $self->context );
}

=head2 addmessage

  $z->addmessage( name => $name, folder => $folder, file => $file )

POST a message from file $file to /home/$name/$folder using the ZCS
REST interface.

=cut

sub addmessage {
    my ( $self, %args ) = @_;

    my $uri = URI->new( $self->cl->get_endpoint );

    my $name   = delete $args{name};
    my $file   = delete $args{file};
    my $folder = delete $args{folder};

    # ensure a folder to put the message in is specified
    $folder = "Inbox" unless ( defined $folder );
    $folder =~ s,^\s*/,,;

    $uri->path("/home/$name/$folder");
    $uri->query( "auth=qp&zauthtoken=" . $self->{_auth}->{authToken} );

    my $lwp = LWP::UserAgent->new;
    $lwp->agent( __PACKAGE__ . " $VERSION" );

    #$lwp->add_handler("request_send",  sub { shift->dump; return });
    #$lwp->add_handler("response_done", sub { shift->dump; return });

    my $r = eval {
        $lwp->post(
            $uri->as_string,
            Content_Type => 'multipart/form-data',
            Content      => [ file => [$file] ],
        );
    };
    chomp( my $e = $@ );

    if ( $r and $r->is_success ) {
        return $r;
    }
    else {
        my $info = "addmessage '$name' file '$file' to '/$folder'";
        my $err = join( "; ", $r ? $r->status_line : (), $e ? $e : () );
        return $self->new_fault(
            faultcode   => 'soap:Client',
            faultstring => "$info: $err",
        );
    }
}

=head2 getdistributionlist

  $z->getdistributionlist( name => $list );

Arguments:

=over 4

=item {id|name} => $list

=back

=cut

sub getdistributionlist {
    my ( $self, $by, $acct ) = @_;

    my $s = $self->new_type( "GetDlSpecifier", { value => $acct } );
    $s->attr( { "by" => $by } );

    my $e = $self->new_element( "GetDistributionListRequest", { dl => $s } );
    return $self->cl->GetDistributionList( $e, $self->context );
}

=head2 createdistributionlist

  $z->createtdistributionlist( name => $list );

=cut

sub createdistributionlist {
    my ( $self, %args ) = @_;

    my $e = $self->new_element( "CreateDistributionListRequest", {%args} );
    return $self->cl->CreateDistributionList( $e, $self->context );
}

=head2 deletedistributionlist

  $z->deletedistributionlist( name => $list );

Arguments:

=over 4

=item {id|name} => $list

=back

=cut

sub deletedistributionlist {
    my ( $self, $by, $list ) = @_;

    my $id = $list;
    if ( $by ne "id" ) {
        my $r = $self->getdistributionlist( $by => $list );
        return $r if !$r;
        $id = $r->get_dl->attr->get_id;
    }

    return $self->cl->DeleteDistributionList( { id => $id }, $self->context );
}

=head1 Helper Methods

=head2 get_from_a

  my @vals = $z->get_from_a( $result->get_a, @attrs );

Returns an array (arrayref in SCALAR context) of values for attributes
(case-insensitively) matched from the list of attribute name(s)
specified in @attrs.

Returns undef on error.

=cut

sub get_from_a {
    my ( $self, $ra, @item ) = @_;

    return undef unless $ra;

    my %want = map { lc($_) => $_ } @item;
    my %data;

    foreach my $at ( @{ $ra || [] } ) {
        my $name = lc( $at->attr->get_n );
        my $want = defined $want{$name} ? $want{$name} : undef;
        push( @{ $data{$name} }, $at ) if ( !@item || defined($want) );
    }

    # got more than 1 item or %data has multiple keys?
    if ( !@item or @item > 1 or keys(%data) > 1 ) {
        return wantarray ? %data : \%data;
    }
    else {
        my $key = ( keys %data )[0];
        my $val = $data{$key};
        return wantarray ? @$val : $val;
    }
}

=head2 item_from_attr

  my @item = $z->item_from_attr(@attr_name_val_pairs);

Returns an array (arrayref in SCALAR context) of ItemAttribute types
populated with the name/value pairs specified in @attr_name_val_pairs.

Returns undef on error.

=cut

sub item_from_attr {
    my ( $self, @attr ) = @_;

    return undef unless @attr;

    my @item;

    while (@attr) {
        my ( $n, $v ) = ( shift(@attr), shift(@attr) );
        my $i = $self->new_type( "ItemAttribute", { value => $v } );
        $i->attr( { "n" => $n } );
        push( @item, $i );
    }
    return wantarray ? @item : \@item;
}

1;

__END__

=head1 SEE ALSO

See the following documentation and links to related software and
topics:

=over 4

=item *

L<ZCS::Admin::Interfaces::Admin::AdminSoap12|ZCS::Admin::Interfaces::Admin::AdminSoap12>
- Factory class for the admin Interface.

=item *

L<SOAP::WSDL|SOAP::WSDL> website L<http://soap-wsdl.sourceforge.net> and on CPAN
L<http://search.cpan.org/dist/SOAP-WSDL/>.

=item *

Class::Std documentation L<http://search.cpan.org/perldoc?Class::Std>

=item *

Class::Std::Fast documentation L<http://search.cpan.org/perldoc?Class::Std::Fast>

=item *

Zimbra Collaboration Suite L<http://www.zimbra.com/>

=back

=head1 AUTHOR

Phil Pearl E<lt>phil@zimbra.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by Phil Pearl.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
