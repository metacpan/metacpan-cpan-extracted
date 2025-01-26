package builder::MyBuilder;
use strict;
use warnings;

use base "Module::Build";

my $DISCOUNT_VERSION = "2.2.7d";

sub new {
    my ($class, %argv) = @_;

    $class->SUPER::new(
        %argv,
        needs_compiler => 1,
        include_dirs => ["discount-$DISCOUNT_VERSION"],
    );
}

sub _build_discount {
    my $self = shift;

    chdir "discount-$DISCOUNT_VERSION";
    my $ok = do {
        local $ENV{CC} = $self->config("cc") . " -fPIC";
        $self->do_system("sh", "configure.sh");
    };
    $ok &&= $self->do_system($self->config("make"), "libmarkdown");
    chdir "..";
    $ok;
}

sub ACTION_code {
    my ($self, @argv) = @_;

    my $spec = $self->_infer_xs_spec(File::Spec->catfile("lib", "Text", "Markdown", "Discount.xs"));
    my $archive = File::Spec->catfile("discount-$DISCOUNT_VERSION", "libmarkdown.a");
    if (!$self->up_to_date($archive, $spec->{lib_file})) {
        $self->_build_discount or die;
        push @{$self->{properties}{objects}}, $archive;
    }
    $self->SUPER::ACTION_code(@argv);
}

1;
