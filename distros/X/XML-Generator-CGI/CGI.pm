#!/usr/bin/perl -w

#=============================================================================
#
# $Id: CGI.pm,v 0.01 2002/02/24 20:41:37 mneylon Exp $
# $Revision: 0.01 $
# $Author: mneylon $
# $Date: 2002/02/24 20:41:37 $
# $Log: CGI.pm,v $
# Revision 0.01  2002/02/24 20:41:37  mneylon
# Initial Release
#
#
#=============================================================================

package XML::Generator::CGI;

use strict;
use CGI;
use XML::SAX::Base;

BEGIN {
  use Exporter   ();
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  $VERSION     = sprintf( "%d.%02d", q( $Revision: 0.01 $ ) =~ /\s(\d+)\.(\d+)/ );
  @ISA         = qw(Exporter XML::SAX::Base);
  @EXPORT      = qw();
  @EXPORT_OK   = qw( );
  %EXPORT_TAGS = (  );
}

my %defaults = (
		RootElement => "cgi",
		ParameterElement => "parameter",
		ValueElement => "value",
		CookieElement => "cookie",
		Cookies => 1
);

sub new {
  my ( $proto, %args ) = @_;
  my $class = ref( $proto ) || $proto;
  my $self = { %defaults, %args };
  bless ( $self, $class );
  return $self;
}

sub parsecgi {
  my $self = shift;
  my $arg = shift;
  if ( UNIVERSAL::isa( $arg, "CGI" ) ) { 
    $self->_parse_cgi( $arg ); 
  } elsif ( defined $arg ) {
    my $cgi = new CGI( $arg );
    $self->_parse_cgi( $cgi );
  } else {
    my $cgi = new CGI;
    $self->_parse_cgi( $cgi );
  }
}

sub _parse_cgi {
  my ( $self, $cgi ) = @_;
  
  $self->SUPER::start_document( {} );

  $self->SUPER::start_element( { Name => $self->{ RootElement },
				 Attributes => { version => $VERSION,
						 generator => "XML::Generator::CGI"
					       }
			       }
			     );

  my @params = $self->_distill_params( $cgi->param() );

  foreach my $param ( @params ) {
    $self->SUPER::start_element( { Name => $self->{ ParameterElement },
				   Attributes => { name => $param } 
				 } 
			       );
    foreach my $value ( $cgi->param( $param ) ) {
      $self->SUPER::start_element( { Name => $self->{ ValueElement } } );
      $self->SUPER::characters( { Data => $value } );
      $self->SUPER::end_element( { Name => $self->{ ValueElement } } );
    }

    $self->SUPER::end_element( { Name => $self->{ ParameterElement } } );
  }
  
  $self->SUPER::end_element( { Name => $self->{ RootElement } } );

  if ( $self->{ Cookies } ) {
    foreach my $cookie ( $cgi->cookie() ) {
      $self->SUPER::start_element( { Name => $self->{ CookieElement },
				     Attributes => { name => $cookie }
				   }
				 );
      $self->SUPER::characters( { Data => $cgi->cookie( $cookie ) } );
      $self->SUPER::end_element( { Name => $self->{ CookieElement } } );
    }
  }

  $self->SUPER::end_document( {} );
}

sub _distill_params {
  my $self = shift;
  my @params = @_;

  if ( $self->{ Exclude } ) { 
    my %exclude_hash = map { $_ => 1 } @{ $self->{ Exclude } };
    @params = grep { ! exists $exclude_hash{ $_ } } @params;
  }

  if ( $self->{ Include } ) { 
    my %include_hash = map { $_ => 1 } @{ $self->{ Include } };
    @params = grep { exists $include_hash{ $_ } } @params;
  }
  return @params;

}

1;
__END__

=head1 NAME

XML::Generator::CGI - Generate SAX2 Events from CGI objects

=head1 SYNOPSIS

  use XML::Generator::CGI;
  use XML::Handler::YAWriter; # Or any other upstream XML filter
  use CGI;

  my $ya = XML::Handler::YAWriter->new( AsString => 1 );
  my $cx = XML::Generator::CGI->new( Hanlder => $ya, <other options> );

  my $q = new CGI;
  my $xml = $cx->parsecgi( $q );

  # OR

  my $xml = $cx->parsecgi();


=head1 DESCRIPTION

XML::Generator::CGI is a SAX event generator for CGI objects.  Both
name/parameter sets and cookies are enumated in the resulting XML.  
By default, and after appropriate parsing by additional handlers, 
the resulting XML will look similar to:

  <cgi generator="XML::Generator::CGI" version="0.01">
    <parameter name="dino">
      <value>Barney</value>
      <value>TRex</value>
    </parameter>
    <parameter name="color">
      <value>purple</value>
    </parameter>
    <cookie name="ticket">123ABC</cookie>
  </cgi>

though aspects of this structure can be changed by the user.  Parameters
and multivalues will be returned in the order that CGI normally returns
these.

=head1 API

=head2 XML::Generator::CGI->new( <options> )

Creates a new generator object.  Options are passed in as key-value 
sets, and as this class inherits from XML::SXL::Base, any addition
options that work there can be accepted here.

=over 4

=item Handler (required, no default)

The hanlder that the SAX events will be passed to.

=item RootElement (optional, default: 'cgi')

The name of the root element tag that will be created in the SAX events.

=item ParameterElement (optional, default: 'parameter')

The name of the parameter element tags.  The name attribute of these tags
will contain the paramter name itself.

=item ValueElement (optional, default: 'value')

The name of the value element tags.  One of these tags is generated as
a child of the parameter element for each value that is returns from the CGI
object.  The value is stored as the character data between this tag.

=item CookieElement (optional, default: 'cookie')

The name of the cookie element tags.  The name attribute of these tags will
contain the name of the cookie.  The data inside these tags will be the
value of the cookie.

=item Cookies (optional, default: 1 (enabled))

If set true, then the cookies from the CGI will be included in the output
of SAX events, otherwise they will be ignored.

=item Include (optional, no default, list)

A list of parameter names that only should be included in the resulting
SAX events.  Parameter names that are not on this list will not be included.

=item Exclude (optional, no default, list)

A list of parameters names that should never be included in the resulting
SAX events.  Parameter names that are not on this list will be included.  
Note that Include and Exclude should be considered mutually exclusive, with
the Excluded list removed first, following by the limitation of the include
list.

=back

=head2 parsecgi( <CGI object> | <query_string> | undef )

Generates SAX events depending on the passed object.  If the passed object
is a CGI object, then processing is done on that.  If this is not the case,
but an argument is still passed, then the object will be treated as a 
query string, converted into a CGI object, and parsed appropriately.  Finally
if no object is passed, then a new CGI object is created in the current 
environment, which may be useful in a web application.

=head2 EXPORT

None by default.

=head1 AUTHOR

Michael K. Neylon, E<lt>mneylon-pm@masemware.comE<gt>

=head1 SEE ALSO

L<perl>, L<CGI>, L<XML::SAX::Base>.

=cut
