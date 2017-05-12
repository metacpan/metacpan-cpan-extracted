
use Test;
BEGIN { plan tests => 2 };

use strict;
use vars qw( @ISA );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

require Waft;
require Waft::jQuery;

push @ISA, qw( Waft::jQuery Waft );

my ($text_part, $code);

$text_part =   qq{<script>\n}
             . qq{\tWaft.jQuery.get();\n}
             . qq{</script>};
$code =   qq{\$__self->output('<script>');\x0A}
        . qq{\$__self->output("\\x0A\t");}
        . qq{\$__self->output_jquery_request_script('get');}
        . qq{\$__self->output('();');\x0A}
        . qq{\$__self->output("\\x0A</script>");};
ok( __PACKAGE__->convert_text_part($text_part, "\x0A") eq $code );

$text_part =   qq{<script>\n}
             . qq{\tWaft.jQuery.post();\n}
             . qq{</script>};
$code =   qq{\$__self->output('<script>');\x0A}
        . qq{\$__self->output("\\x0A\t");}
        . qq{\$__self->output_jquery_request_script('post');}
        . qq{\$__self->output('();');\x0A}
        . qq{\$__self->output("\\x0A</script>");};
ok( __PACKAGE__->convert_text_part($text_part, "\x0A") eq $code );
