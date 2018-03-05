# Copyrights 2007-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-SOAP.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::XOP;
use vars '$VERSION';
$VERSION = '3.23';


use warnings;
use strict;

use Log::Report   'xml-compile-soap';

use XML::Compile::SOAP::Util   qw/:xop10/;
use XML::Compile::XOP::Include ();

XML::Compile->addSchemaDirs(__FILE__);
XML::Compile->knownNamespace
  ( &XMIME10   => '200411-xmlmime.xsd'
  , &XMIME11   => '200505-xmlmime.xsd'
  );


sub new(@) { my $class = shift; (bless {})->init( {@_} ) }

sub init($)
{   my ($self, $args) = @_;

    $self->{XCX_xmime} = $args->{xmlmime_version} || XMIME11;
    $self->{XCX_xop}   = $args->{xop_version}     || XOP10;
    $self->{XCX_host}  = $args->{hostname}        || 'localhost';
    $self->{XCX_cid}   = time;
    $self;
}


sub _include(@)
{   my $self = shift;
    XML::Compile::XOP::Include->new
      ( cid   => $self->{XCX_cid}++ . '@' . $self->{XCX_host}
      , xmime => $self->{XCX_xmime}
      , xop   => $self->{XCX_xop}
      , type  => 'application/octet-stream'
      , @_
      );
}
sub file(@)  { my $self = shift; $self->_include(file  => @_) }
sub bytes(@) { my $self = shift; $self->_include(bytes => @_) }


1;
