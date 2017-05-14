use Win32::ASP::DBRecordGroup;
use Error qw/:try/;

use DocSample::DocEntry;

package DocSample::DocEntryGroup;

@ISA = ('Win32::ASP::DBRecordGroup');

use strict vars;

sub _DB {
  return $main::TheDB;
}

sub _TYPE {
  return 'DocSample::DocEntry';
}

sub _MIN_COUNT {
  return 4;
}

sub _NEW_COUNT {
  return 2;
}

sub _QUERY_METAS {
  return $DocSample::DocEntryGroup::query_metas;
}

$DocSample::DocEntryGroup::query_metas = {

};

sub post {
  my $self = shift;
  $self->SUPER::post('Contents');
}

sub gen_docentries_table {
  my $self = shift;
  my($data, $viewtype) = @_;

  return $self->gen_table('Contents', $data, $viewtype);
}

1;
