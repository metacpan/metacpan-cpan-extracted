use strict;
use warnings;

use Plack::Builder;

use File::Basename ();
use File::Spec;

use Text::APL;

my $template         = Text::APL->new;
my $templates_path   = File::Basename::dirname(__FILE__);
my $path_to_template = File::Spec->catfile($templates_path, 'template.apl');

my $app = sub {
    my ($env) = @_;

    return sub {
        my ($respond) = @_;

        my $writer = $respond->([200, ['Content-Type' => 'text/html']]);

        my $output = sub {
            my ($chunk) = @_;

            if (defined $chunk) {
                $writer->write($chunk);
            }
            else {
                $writer->close;
            }
        };

        $template->render(
            input  => $path_to_template,
            output => $output,
            vars   => {name => 'vti'}
        );
    };
};
