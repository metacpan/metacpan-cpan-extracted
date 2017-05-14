use Win32::ASP::DBRecordGroup;
use Error qw/:try/;

use DocSample::Document;

package DocSample::DocumentGroup;

@ISA = ('Win32::ASP::DBRecordGroup');

use strict vars;

sub _DB {
  return $main::TheDB;
}

sub _TYPE {
  return 'DocSample::Document';
}

sub _QUERY_METAS {
  return $DocSample::DocumentGroup::query_metas;
}

$DocSample::DocumentGroup::query_metas = {

};

DocSample::Document->ADD_FIELDS(
  Win32::ASP::Field->new(
    name => 'DocID_Active',
    sec  => 'ro',
    type => 'dispmeta',
    desc => 'DocID',

    as_html => sub {
      my $self = shift;
      my($record, $data, $viewtype) = @_;

      $self->can_view($record) or return;

      my $temp = $record->field('DocID', $data, $viewtype);
      chomp(my $retval = <<ENDHTML);
<A HREF="view.asp?DocID=$record->{$data}->{DocID}">$temp</A>
ENDHTML
      return $retval;
    },
  ),
);

sub query {
  my $self = shift;
  my($ref2constraints, $order, $columns) = @_;

#  $ref2constraints = {TAStatus => '^X', can_view => 1, %{$ref2constraints}};
  $self->SUPER::query($ref2constraints, $order, "$columns,DocID,Author,Locked,Hidden");
}

1;
