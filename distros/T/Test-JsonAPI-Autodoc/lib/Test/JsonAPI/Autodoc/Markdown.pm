package Test::JsonAPI::Autodoc::Markdown;
use strict;
use warnings;
use utf8;
use Data::Section::Simple;
use Time::Piece;
use Text::Xslate qw(mark_raw);
use Text::Xslate::Bridge::Star;
use Test::JsonAPI::Autodoc::Path;

sub new {
    my ($class, $output_path, $template) = @_;

    bless {
        output_path => $output_path,
        template    => $template,
    }, $class;
}

sub generate {
    my ($self, $description, $results, $first_time) = @_;

    my $document_path = Test::JsonAPI::Autodoc::Path->document_path($self->{output_path});

    my $vpath = Data::Section::Simple->new()->get_data_section();
    my $tx    = Text::Xslate->new(
        type => 'text',
        path => [$vpath],
        module => ['Text::Xslate::Bridge::Star'],
    );

    my $fh;
    my $generated_at;
    if ($first_time) {
        $fh = $document_path->openw_utf8( { locked => 1 } );
        $generated_at = localtime->strftime('%Y-%m-%d %H:%M:%S');
    }
    else {
        $fh = $document_path->opena_utf8( { locked => 1 } );
    }

    my $vars = {
        generated_at => $generated_at,
        description  => $description,
        results      => $results,
    };
    my $rendered = $self->{template} ? $tx->render_string($self->{template}, $vars)
                                     : $tx->render('document.json.tx', $vars);
    print $fh $rendered;
    close $fh;
}
1;

__DATA__
@@ document.json.tx
: if $generated_at {
generated at: <: $generated_at :>

: }
## <: $description :>

: for $results -> $result {
<: $result.note :>

: if $result.server {
### Target Server

<: $result.server :>
: if $result.is_plack_app {

(Plack application)
: }

:}
### Parameters

: if $result.request_parameters {
    : if $result.request_content_type {
__<: $result.request_content_type :>__

    : }
: for $result.request_parameters -> $parameter {
<: $parameter :>
: }
: }
: else {
Not required
: }

### Request

<: $result.method:> <: $result.path :>
: if $result.query {

    <: $result.query :>
: }

### Response

- Status:       <: $result.status :>
- Content-Type: <: $result.response_content_type :>

```json
<: $result.response_body :>
```

: }
