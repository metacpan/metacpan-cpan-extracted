# Copyrights 2011-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::WSS::Timestamp;
use vars '$VERSION';
$VERSION = '1.14';

use base 'XML::Compile::WSS';

use Log::Report  'xml-compile-wss';

use XML::Compile::WSS::Util qw/WSU_10/;


sub init($)
{   my ($self, $args) = @_;
    $args->{wss_version} ||= '1.1';
    $self->SUPER::init($args);

    $self->{XCWT_created}  = $args->{created};
    $self->{XCWT_expires}  = $args->{expires};
    $self->{XCWT_lifetime} = $args->{lifetime};
    $self->{XCWT_wsu_id}   = $args->{wsu_Id} || $args->{wsu_id};
    $self;
}

#----------------------------------

sub created()  {shift->{XCWT_created}}
sub expires()  {shift->{XCWT_expires}}
sub lifetime() {shift->{XCWT_lifetime}}
sub wsuId()    {shift->{XCWT_wsu_id}}


sub timestamps()
{   my $self    = shift;
    my ($c, $e, $l) = @{$self}{ qw/XCWT_created XCWT_expires XCWT_lifetime/ };
    my ($expires);

    defined $c or $c = time;
    my $created = $c eq '' ? undef : $self->dateTime($c);

    if(!$e && defined $l)
    {    $c !~ m/\D/ or error "lifetime only when created is in seconds";
         $e = $c + $l;
    }
    ($created, $self->dateTime($e));
}

sub prepareWriting($)
{   my ($self, $schema) = @_;
    $self->SUPER::prepareWriting($schema);
    return if $self->{XCWT_stamp};

    my $ts_type = $schema->findName('wsu:Timestamp') ;
    my @hooks   = $self->writerHookWsuId('wsu:TimestampType');
    my $make_ts = $schema->writer($ts_type, include_namespaces => 1
      , hooks => \@hooks);
    $schema->prefixFor(WSU_10);

    $self->{XCWT_stamp} = sub {
        my ($doc, $data) = @_;
        my ($created, $expires) = $self->timestamps;
        $data->{$ts_type} = $make_ts->($doc,
          { wsu_Id      => $self->wsuId
          , wsu_Created => $created
          , wsu_Expires => $expires
          });
        $data;
    };
}

sub create($$)
{   my ($self, $doc, $data) = @_;
    $self->SUPER::create($doc, $data);
    $self->{XCWT_stamp}->($doc, $data);
}

1;
