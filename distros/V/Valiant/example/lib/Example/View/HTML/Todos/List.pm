package Example::View::HTML::Todos::List;

use Moo;
use Valiant::HTML::PagerBuilder;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div fieldset a b u span form_for pager_for table thead tbody tfoot trow th td),
  -util => qw($sf create_uri edit_uri list_uri),
  -views => 'HTML::Page', 'HTML::Navbar';

has 'list' => (is=>'rw', required=>1, handles=>[qw/pager status/]);
has 'todo' => (is=>'ro', required=>1, clearer=>'clear_todo');

sub set_list_to_last_page($self) {
  $self->list($self->list->get_last_page);
}

sub render($self, $c) {

  html_page page_title=>'Todo List', sub($layout) {
    html_navbar active_link=>'todo_list',
    div +{ class=>'col-5 mx-auto' },
    form_for 'todo', sub ($self, $fb, $todo) {
      fieldset [
        $fb->legend,
        $fb->model_errors({show_message_on_field_errors=>'Please fix the listed errors.'}),

        pager_for 'list', +{uri_base => list_uri(+{'todo.status'=>$self->status})}, sub ($self, $pg, $list) {
          $pg->window_info,
          table +{class=>'table table-striped table-bordered', style=>'margin-bottom:0.5rem'}, [
            thead
              trow [
                th +{scope=>"col"},'Title',
                th +{scope=>"col", style=>'width:8em'}, 'Status',
              ],
            tbody { repeat=>$list }, sub ($self, $todo, $i) {
              trow [
                td a +{ href=>edit_uri([$todo]) }, $todo->title,
                td $todo->status,
              ],
            },
            tfoot { if=>$pg->pager->last_page > 1  },
              td {colspan=>2, style=>'background:white'},
                $pg->navigation_line,
          ],
        }, sub ($self, $list) {
          div "There are no tasks to display."
        },
  
        $self->status_filter_box,

        div +{ class=>'form-group' }, [
          $fb->input('title', +{ placeholder=>'What needs to be done?' }),
          $fb->errors_for('title'),
        ],
        $fb->submit('Add Todo to List'),
      ],
    },
  };
}

sub status_filter_box($self) {
  div {style=>'text-align:center; margin-bottom: 1rem'}, [
    map { $self->status_filter($_) } qw/all active completed/,
  ];
}

sub status_filter($self, $status) {
  return span {style=>'margin: .5rem'}, [b u $status] if $self->status eq $status;
  return a { href=>list_uri(+{'todo.page'=>1, 'todo.status'=>$status}), style=>'margin: .5rem'}, $status;
}

1;
