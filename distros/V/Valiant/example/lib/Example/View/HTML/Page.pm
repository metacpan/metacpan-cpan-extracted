package Example::View::HTML::Page;

use CatalystX::Moose;
use Example::Syntax;
use Example::View::HTML;

has 'page_title' => (is=>'ro', required=>1);

sub render($self, $c, $content) {
  return Html +{ lang=>'en' }, [
    Head [
      Title $self->page_title,
      Meta +{ charset=>"utf-8" },
      Meta +{ name=>"viewport", content=>"width=device-width, initial-scale=1, shrink-to-fit=no" },
      Link +{ rel=>"icon", href=>"data:," },
      Link +{ rel=>"stylesheet", type=>'text/css', href=>"/static/core.css" },
      Link +{ rel=>"stylesheet",
              href=>"https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css",
              integrity=>'sha384-xOolHFLEh07PJGoPkLv1IbcEPTNtaed2xpHsD9ESMhqIYd0nLMwNLD69Npy4HI+N',
              crossorigin=>"anonymous" },
      ($self->caller->can('css') ? $self->caller->css : ''),
    ],
    Body [
      $content,
      Div $self->the_time,
      Script +{ src=>'https://code.jquery.com/jquery-3.7.0.min.js',
                integrity=>'sha256-2Pmvv0kuTBOenSvLm6bvfBSSHrUJ+3A7x6P5Ebd07/g=',
                crossorigin=>"anonymous" }, '',
      Script +{ src=>'https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js',
                integrity=>'sha384-Fy6S3B9q64WdZWQUiU+q4/2Lc9npb8tCaSX9FK7E8HnRr0Jz8D6OP9dO5Vg3Q9ct',
                crossorigin=>"anonymous" }, '',
      Script +{ src=>'https://cdnjs.cloudflare.com/ajax/libs/jquery-ujs/1.2.3/rails.js' }, '',
      Script +{ src=>'/static/core.js' }, '',
      ($self->caller->can('js') ? $self->caller->js : ''),
    ],
  ];
}

__PACKAGE__->meta->make_immutable;
