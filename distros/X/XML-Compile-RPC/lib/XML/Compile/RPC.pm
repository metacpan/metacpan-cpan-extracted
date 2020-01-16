# Copyrights 2009-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-RPC.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::RPC;
use vars '$VERSION';
$VERSION = '0.20';

use base 'XML::Compile::Cache';

use warnings;
use strict;

use Log::Report 'xml-compile-rpc', syntax => 'SHORT';
use File::Glob     qw/bsd_glob/;
use File::Basename qw/dirname/;


sub init($)
{   my ($self, $args) = @_;

    unshift @{$args->{opts_rw}}
      , sloppy_floats   => 1    # no need for Big::
      , sloppy_integers => 1
      , mixed_elements  => 'STRUCTURAL';

    unshift @{$args->{opts_readers}}
      , hooks =>
         [ {type => 'ValueType', replace => \&_rewrite_string}
         , {type => 'ISO8601',   replace => \&_reader_rewrite_date}
         ];

    unshift @{$args->{opts_writers}}
      , hooks =>
         [ {type => 'ISO8601', before => \&_writer_rewrite_date}
         ];

    $self->SUPER::init($args);

    $self->addPrefixes
      ( ex => 'http://ws.apache.org/xmlrpc/namespaces/extensions'
      );

    (my $xsddir = __FILE__) =~ s/\.pm$//i;
    my @xsds = bsd_glob "$xsddir/*.xsd";
    $self->importDefinitions(\@xsds);

    # only declared methods are accepted by the Cache
    $self->declare(WRITER => 'methodCall');
    $self->declare(READER => 'methodResponse');
    $self;
}

sub _rewrite_string($$$$$)
{   my ($element, $reader, $path, $type, $replaced) = @_;

      (grep $_->isa('XML::LibXML::Element'), $element->childNodes)
    ? $replaced->($element)
    : (value => {string => $element->textContent});
}

# xsd:dateTime requires - and : between the components
sub _iso8601_to_dateTime($)
{   my $s = shift;
    $s =~ s/^([12][0-9][0-9][0-9])-?([01][0-9])-?([0-3][0-9])T/$1-$2-$3T/;
    $s =~ s/T([012][0-9]):?([0-5][0-9]):?([0-6][0-9])/T$1:$2:$3/;
    $s;
}

sub _writer_rewrite_date
{   my ($doc, $string, $path) = @_;
    _iso8601_to_dateTime $string;
}

sub _reader_rewrite_date
{   my ($element, $reader, $path, $type, $replaced) = @_;
    my $schema_time = _iso8601_to_dateTime $element->textContent;
    # $schema_time should get validated...
    ('dateTime.iso8601' => $schema_time);
}

1;
