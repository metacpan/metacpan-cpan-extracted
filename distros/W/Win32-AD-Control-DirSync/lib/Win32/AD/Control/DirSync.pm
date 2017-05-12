# Copyright (c) 2005 Alexey Kravchuk <ak2@smr.ru>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Win32::AD::Control::DirSync;

use strict;

use Net::LDAP::Control;
use Win32::AD::Constant qw(LDAP_CONTROL_DIRSYNC); 

use vars qw(@ISA $VERSION);

@ISA = qw(Net::LDAP::Control);
$VERSION = "0.01";


use Convert::ASN1;

our $DirSync = Convert::ASN1->new;
$DirSync->prepare(<<EOF
     DirSync ::= SEQUENCE {
        flags INTEGER,
        maxAttrCnt INTEGER,
        cookie OCTET STRING
    }
EOF
);

__PACKAGE__->register(LDAP_CONTROL_DIRSYNC);

# Make access methods for the control attributes.
for my $attr (qw(flags maxAttrCnt cookie)) {
  no strict 'refs';

  *$attr = sub {  my $self = shift;
		  $self->{asn} ||= $DirSync->decode($self->{value});
		  if (@_) {
			delete $self->{value};
			$self->{asn}{$attr} = shift || (($attr eq 'cookie') ? '' : 0);
		  }
		  $self->{asn}{$attr};
		};
}


sub init {
  my($self) = @_;

  delete $self->{asn};

  unless (exists $self->{value}) {
    $self->{asn} = {
      flags => $self->{flags} || 0,
      maxAttrCnt => $self->{maxAttrCnt} || 0,
      cookie   => $self->{cookie} || '',
    };
  }

  require Carp and Carp::croak("Incorrect control OID. @{[__PACKAGE__]} class can used for DirSync control only.")
  	if defined $self->{type} and $self->{type} ne LDAP_CONTROL_DIRSYNC;

  $self->{type} = LDAP_CONTROL_DIRSYNC;


  require Carp and Carp::croak("DirSync control can't be non-critical.")
  	if defined $self->{critical} and not $self->{critical};

  $self->{critical} = 1;

  $self;
}

sub value {
  my $self = shift;

  exists $self->{value}
    ? $self->{value}
    : $self->{value} = $DirSync->encode($self->{asn});

    $self->{value}
}

sub moreData {
  my $self = shift;

  require Carp and Carp::croak("moreData method could be called only for a response DirSync control.")
  	unless exists $self->{value};

  $self->flags;
}


1;

__END__

=head1 NAME

Win32::AD::Control::DirSync - LDAPv3 DirSync control wrapper for Net::LDAP

=head1 SYNOPSIS

 use Net::LDAP;
 use Win32::AD::Constant qw(LDAP_CONTROL_DIRSYNC
 			    LDAP_DIRSYNC_ANCESTORS_FIRST_ORDER);
 use Win32::AD::Control::DirSync;

 my $timeout = 10;

 my $ldap = Net::LDAP->new( 'domain_controller_name' )	or die "$@";

 my $mesg = $ldap->bind( 'domain_user_name', password => 'user_pwd')		or die $@;

 my $reqDirSync = Win32::AD::Control::DirSync->new(
		flags		=> LDAP_DIRSYNC_ANCESTORS_FIRST_ORDER,
		maxAttrCnt	=> 100)		or die "$@";

 for(my $i=1; $i<10; $i++) {
	$do_more = 1;

 	while($do_more) {
 
		$mesg = $ldap->search(	base	=> "dc=somedomain,dc=com",
                			control	=> [ $reqDirSync ],
					filter	=> "(&(objectClass=user))",
				     ) or die $@;
 
	 	$mesg->code && die $mesg->error;

		$_->dump for grep {ref($_) eq 'Net::LDAP::Entry'} $mesg->entries;

		# DirSync control should be included in the response.
		if(my ($respDirSync) = $mesg->control(LDAP_CONTROL_DIRSYNC)) {

			$reqDirSync->cookie($respDirSync->cookie);
                  
			$do_more = $respDirSync->moreData;

		} else {
			die "There is no DirSync control in the response.";
		}
	}
	sleep($timeout);
 }
 
 $mesg = $ldap->unbind; 


=head1 DESCRIPTION

C<Win32::AD::Control::DirSync> provides an interface for the creation
and manipulation of objects that represent the C<DirSync> control,
used to synchronize with Active Directory(r).

DirSync control description:
L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/ldap/ldap/ldap_server_dirsync_oid.asp>

Using DirSync for synchronizing with AD:
L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/ad/ad/polling_for_changes_using_the_dirsync_control.asp>

Other AD-synchronizing techniques:
L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/ad/ad/tracking_changes.asp>


=head1 CONSTRUCTOR ARGUMENTS

In addition to the constructor arguments described in
L<Net::LDAP::Control> the following are provided.

=over 4

=item flags

This can be zero or a combination of one or more of the following values:


=over 4

=item *

LDAP_DIRSYNC_OBJECT_SECURITY (1)


=over 4

=item *

Windows Server 2003: If this flag is not present, the caller must have
the replicate changes right. If this flag is present, the caller requires
no rights, but can only view objects and attributes accessible to the caller.

=item *

Windows 2000 Server: Not supported.

=back

=item *

LDAP_DIRSYNC_ANCESTORS_FIRST_ORDER (2048)

Return parent objects before child objects, when parent objects would otherwise
appear later in the replication stream.

=item *

LDAP_DIRSYNC_PUBLIC_DATA_ONLY (8192)

Do not return private data in the search results.

=item *

LDAP_DIRSYNC_INCREMENTAL_VALUES (2147483648)

=over 4

=item *

Windows Server 2003: If this flag is not present, all of the values, up to
a server-specified limit, in a multi-valued attribute are returned when any
value changes. If this flag is present, only the changed values are returned.

=item *

Windows 2000 Server: Not supported.

=back

=back

=item maxAttrCnt

Specifies the maximum number of attributes to return. This value may also be
used to limit the amount of data returned. 

=item cookie

The value to use as the cookie. This is not normally set when an object is
created, but is set from the cookie value returned by the server. This
associates a search with a previous search, so it allows to incrementally
get changes from the server.

=back

=head1 METHODS

=over 4

=item moreData

Contains a non-zero value if there is more data to retrieve or zero if there
is no more data to retrieve. If this member contains a non-zero value,
a subsequent search should be performed with the Cookie of this data to
retrieve the next block of results. This method is allowed for DirSync
controls from response message only.

=back

As with L<Net::LDAP::Control> each constructor argument
described above is also available as a method on the object which will
return the current value for the attribute if called without an argument,
and set a new value for the attribute if called with an argument.

=head1 SEE ALSO

L<Net::LDAP>,
L<Net::LDAP::Control>,
L<Net::LDAP::Constant>,
L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/ldap/ldap/ldap_server_dirsync_oid.asp>
L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/ad/ad/polling_for_changes_using_the_dirsync_control.asp>
L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/ad/ad/tracking_changes.asp>


=head1 AUTHOR

Alexey Kravchuk E<lt>ak2@smr.ruE<gt>, based on Net::LDAP::Control::Page
from Graham Barr E<lt>gbarr@pobox.comE<gt>.

=head1 COPYRIGHT

Copyright (c) 2005 Alexey Kravchuk. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

