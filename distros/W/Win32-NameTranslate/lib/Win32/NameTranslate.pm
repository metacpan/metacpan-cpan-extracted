package Win32::NameTranslate;
$Win32::NameTranslate::VERSION = '0.06';
#ABSTRACT: Convenience perl wrapper around IADsNameTranslate interface

use strict;
use warnings;

use constant ADS_NAME_INITTYPE_DOMAIN => 1;
use constant ADS_NAME_INITTYPE_SERVER => 2;
use constant ADS_NAME_INITTYPE_GC => 3;
use constant ADS_NAME_TYPE_1779 => 1;
use constant ADS_NAME_TYPE_CANONICAL => 2;
use constant ADS_NAME_TYPE_NT4 => 3;
use constant ADS_NAME_TYPE_DISPLAY => 4;
use constant ADS_NAME_TYPE_DOMAIN_SIMPLE => 5;
use constant ADS_NAME_TYPE_ENTERPRISE_SIMPLE => 6;
use constant ADS_NAME_TYPE_GUID => 7;
use constant ADS_NAME_TYPE_UNKNOWN => 8;
use constant ADS_NAME_TYPE_USER_PRINCIPAL_NAME => 9;
use constant ADS_NAME_TYPE_CANONICAL_EX => 10;
use constant ADS_NAME_TYPE_SERVICE_PRINCIPAL_NAME => 11;
use constant ADS_NAME_TYPE_SID_OR_SID_HISTORY_NAME => 12;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ADS_NAME_INITTYPE_DOMAIN ADS_NAME_INITTYPE_SERVER ADS_NAME_INITTYPE_GC ADS_NAME_TYPE_1779
                    ADS_NAME_TYPE_CANONICAL ADS_NAME_TYPE_NT4 ADS_NAME_TYPE_DISPLAY ADS_NAME_TYPE_DOMAIN_SIMPLE
                    ADS_NAME_TYPE_ENTERPRISE_SIMPLE ADS_NAME_TYPE_GUID ADS_NAME_TYPE_UNKNOWN ADS_NAME_TYPE_USER_PRINCIPAL_NAME
                    ADS_NAME_TYPE_CANONICAL_EX ADS_NAME_TYPE_SERVICE_PRINCIPAL_NAME ADS_NAME_TYPE_SID_OR_SID_HISTORY_NAME);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

use Win32::OLE;

sub new {
  my $package = shift;
  my ($type,$path,$user,$dom,$pass) = @_;
  my $self = { };
  $self->{_trans} = Win32::OLE->CreateObject('NameTranslate');
  # check for error.
  $type = ADS_NAME_INITTYPE_GC unless $type && $type =~ /^[123]$/;
  $path = '' unless $path;
  if ( $user && $dom && $pass ) {
    $self->{_trans}->InitEx( $type, $path, $user, $dom, $pass );
  }
  else {
    $self->{_trans}->Init( $type, $path );
  }
  bless $self, $package;
  return $self;
}

sub multiple {
  my $self = shift;
  return unless defined $self->{_set};
  return $self->{_set} eq 'array' ? 1 : 0;
}

sub set {
  my $self = shift;
  my $type = shift;
  my $set = shift;
  # validate $type
  if ( ref $set eq 'ARRAY' ) {
    $self->{_set} = 'array';
    $self->{_trans}->SetEx( $type, $set );
  }
  else {
    $self->{_set} = 'set';
    $self->{_trans}->Set( $type, $set );
  }
  my $res = Win32::OLE->LastError;
  return Win32::OLE::HRESULT( $res ) == 0 ? 1 : 0;
}

sub get {
  my $self = shift;
  my $type = shift;
  # validate $type
  return unless $self->{_set};
  if ( $self->{_set} eq 'array' ) {
    my $results = $self->{_trans}->GetEx( $type );
    return @{ $results };
  }
  else {
    my $result = $self->{_trans}->Get( $type );
    return $result;
  }
}

q[I translate, therefore I am];

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::NameTranslate - Convenience perl wrapper around IADsNameTranslate interface

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Win32::NameTranslate is a convenience wrapper around the C<IADsNameTranslate> interface, which
can be used to convert the names of Active Directory objects from one format to another.
C<IADsNameTranslate> is an C<ADSI> implementation of the C<DsCrackNames> API.

C<IADsNameTranslate> is usually accessed via L<Win32::OLE>, this wrapper just makes it slightly
easier to use.

=head1 SYNPOSIS

  use strict;
  use warnings;
  use Win32::NameTranslate qw[:all];
  use Win32::OLE;

  # Create a new name translator, using Global Catalog
  my $trans = Win32::NameTranslate->new( ADS_NAME_INITTYPE_GC );

  my $canonical = 'localdomain.local/_SomeOU/_AnotherOU/Tommy Tester';

  # Specify Canonical format and name to lookup
  $trans->set( ADS_NAME_TYPE_CANONICAL, $canonical ) || die Win32::OLE->LastError;

  # Lets get the RFC 1779 'LDAP' type name
  my $rfc = $trans->get( ADS_NAME_TYPE_1779 );

  # rfc = 'CN=tommy tester,OU=_AnotherOU,OU=_SomeOU,DC=localdomain,DC=local'

  my @multiple = (
        'localdomain.local/_SomeOU/_AnotherOU/Tommy Tester',
        'localdomain.local/_Admins/_Enterprise/Johnny Admin',
  );

  # We can lookup multiple names by providing an arrayref
  $trans->set( ADS_NAME_TYPE_CANONICAL, \@multiple ) || die Win32::OLE->LastError;

  my @rfcs = $trans->get( ADS_NAME_TYPE_1779 );

=head1 EXPORTS

A number of constants are defined and exported by this module. You may specify C<:all> to import
all the constants into your namespace. Nothing is imported by default.

=over

=item C<ADS_NAME_INITTYPE_ENUM>

The C<ADS_NAME_INITTYPE_ENUM> enumeration specifies the types of initialisation to perform on a C<NameTranslate> object.

=over

=item C<ADS_NAME_INITTYPE_DOMAIN>

Initializes a NameTranslate object by setting the domain that the object binds to.

=item C<ADS_NAME_INITTYPE_SERVER>

Initializes a NameTranslate object by setting the server that the object binds to.

=item C<ADS_NAME_INITTYPE_GC>

Initializes a NameTranslate object by locating the global catalog that the object binds to.

=back

=item C<ADS_NAME_TYPE_ENUM>

The C<ADS_NAME_TYPE_ENUM> enumeration specifies the formats used for representing distinguished names:

=over

=item C<ADS_NAME_TYPE_1779>

Name format as specified in RFC 1779. For example, "CN=Jeff Smith,CN=users,DC=Fabrikam,DC=com".

=item C<ADS_NAME_TYPE_CANONICAL>

Canonical name format. For example, "Fabrikam.com/Users/Jeff Smith".

=item C<ADS_NAME_TYPE_NT4>

Account name format used in Windows NT 4.0. For example, "Fabrikam\JeffSmith".

=item C<ADS_NAME_TYPE_DISPLAY>

Display name format. For example, "Jeff Smith".

=item C<ADS_NAME_TYPE_DOMAIN_SIMPLE>

Simple domain name format. For example, "JeffSmith@Fabrikam.com".

=item C<ADS_NAME_TYPE_ENTERPRISE_SIMPLE>

Simple enterprise name format. For example, "JeffSmith@Fabrikam.com".

=item C<ADS_NAME_TYPE_GUID>

Global Unique Identifier format. For example, "{95ee9fff-3436-11d1-b2b0-d15ae3ac8436}".

=item C<ADS_NAME_TYPE_UNKNOWN>

Unknown name type. The system will estimate the format. This element is a meaningful option only with the C<set> method, but not with the C<get> method.

=item C<ADS_NAME_TYPE_USER_PRINCIPAL_NAME>

User principal name format. For example, "JeffSmith@Fabrikam.com".

=item C<ADS_NAME_TYPE_CANONICAL_EX>

Extended canonical name format. For example, "Fabrikam.com/Users Jeff Smith".

=item C<ADS_NAME_TYPE_SERVICE_PRINCIPAL_NAME>

Service principal name format. For example, "www/www.fabrikam.com@fabrikam.com".

=item C<ADS_NAME_TYPE_SID_OR_SID_HISTORY_NAME>

A SID string, as defined in the Security Descriptor Definition Language (SDDL), for either the SID of the current object or one from the object SID history.
For example, "O:AOG:DAD:(A;;RPWPCCDCLCSWRCWDWOGA;;;S-1-0-0)"

=back

=back

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new Win32::NameTranslate object, initialising a C<NameTranslate> object internally.

Without any arguments it binds to C<ADS_NAME_INITTYPE_GC>.

Can take five arguments.

The first argument is the type of initialisation to be performed, C<ADS_NAME_INITTYPE_ENUM>.

The second argument is the name of the server or domain, depending on the type of initialisation. When
C<ADS_NAME_INITTYPE_SERVER> is used, specify the machine name of a directory server. When
C<ADS_NAME_INITTYPE_DOMAIN> is used, specify the domain name. This value is ignored when
C<ADS_NAME_INITTYPE_GC> is issued.

Optionally, you may provide a further three arguments to specify user credential than the current user, if these are
provided, then all must be provided. The arguments are: username, user domain name and user password, respectively.

Examples:

  # Just use default, which is ADS_NAME_INITTYPE_GC
  my $trans = Win32::NameTranslate->new();

  # Bind to a specific domain
  my $trans = Win32::NameTranslate->new( ADS_NAME_INITTYPE_DOMAIN, 'localdomain.local' );

  # Bind to a specific domain providing credentials
  my $trans = Win32::NameTranslate->new( ADS_NAME_INITTYPE_DOMAIN, 'localdomain.local', 'johnny', 'LOCAL', 'sekret' );

=back

=head1 METHODS

The C<set> method must be called before the C<get> method.

=over

=item C<set>

Directs the directory service to set up a specified object for name translation. This is a single wrapper around the
underlying C<IADsNameTranslate::Set> and C<IADsNameTranslate::SetEx> methods.

The first argument required is a format type, C<ADS_NAME_TYPE_ENUM>.

The second argument required is either a scalar of the name to translate or an arrayref of a number of names to translate.

Examples:

  # translate a single name from Canonical name format
  $trans->set( ADS_NAME_TYPE_CANONICAL, "Fabrikam.com/Users/Jeff Smith" );

  # translate a number of names from Canonical name format
  $trans->set( ADS_NAME_TYPE_CANONICAL, [ "Fabrikam.com/Users/Jeff Smith", "Fabrikam.com/Users/Johnny Rotten", "Fabrikam.com/Users/Billy Bookcase" ] );

The method will return a C<true> value on success or C<false> on failure. You may check C<< Win32::OLE->LastError >> to see what the error was.

=item C<get>

Retrieves the name of a directory object in the specified format. C<set> must be called before using this method. This is a single wrapper
around the underlying C<IADsNameTranslate::Get> and C<IADsNameTranslate::GetEx> methods. What is returned is determined on whether C<set> was called
with a C<scalar> or C<arrayref>.

The first argument required is the format type, C<ADS_NAME_TYPE_ENUM>, of the output name.

If C<set> was called with a single name to translate the result is a single output name.

If C<set> was called with an C<arrayref> the result is a list of output names.

Examples:

  # translate to RFC 1779
  my $result = $trans->get( ADS_NAME_TYPE_1779 );

  # we passed an arrayref, so get a list back
  my @results = $trans->get( ADS_NAME_TYPE_1779 );

=item C<multiple>

Returns C<true> or C<false> (respectively) depending on whether C<set> was called with an C<arrayref> or not.

=back

=head1 SEE ALSO

L<http://msdn.microsoft.com/en-us/library/windows/desktop/aa706046%28v=vs.85%29.aspx>

L<http://www.rlmueller.net/NameTranslateFAQ.htm>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
