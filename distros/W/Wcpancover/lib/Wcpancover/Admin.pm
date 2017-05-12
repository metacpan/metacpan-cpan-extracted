package Wcpancover::Admin;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

sub change { shift->render }

sub show {
  my $self = shift;

  print STDERR 'Admin::show()',"\n";

  #my $table = $self->stash->{table};

  $self->render;
}

sub save {
  my $self   = shift;
  my $params = [$self->req->param()];

  my $table = $self->stash->{table};

  my $form = $self->form_handler($table);
  $form->from_schema($self->schema, $table);

  my $data = {};

  $data->{$_} = $self->req->param($_) ? $self->req->param($_) : 0
    for (@$params);

  for my $param (@$params) {
    if ($form->elements->{$param}->{type} eq 'text' ) {
     $data->{$param} =
      $self->req->param($param) ? $self->req->param($param) : '';
    }
    elsif ($form->elements->{$param}->{type} eq 'number' ) {
     $data->{$param} =
      $self->req->param($param) ? $self->req->param($param) : 0;
    }
    else {
     $data->{$param} =
      $self->req->param($param) ? $self->req->param($param) : undef;
    }
  }

  my @elements = @{$form->ordered_elements};

  my @checkboxes =
    grep { $form->elements->{$_}->{type} eq 'checkbox' } @elements;

  for my $param (@checkboxes) {
    $data->{$param} =
      (exists $data->{$param} && $data->{$param} eq 'on') ? 1 : 0;
  }

  my $id_field = $form->id_field;
  say STDERR 'Admin::save() $id_field: ',$id_field if $self->app->app_debug;
  if (exists $data->{$id_field} && !$data->{$id_field}) {
    delete $data->{$id_field};
  }
  say STDERR 'Admin::save() $data: ',Dumper($data) if $self->app->app_debug;

  my $rs = $self->schema->resultset($table);
  $rs->update_or_create($data);

  $self->redirect_to('/admin/show/' . $table);
}

1;
