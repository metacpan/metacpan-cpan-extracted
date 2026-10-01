package builder::MyBuilder;
use strict;
use warnings;

use base "Module::Build";
use Cwd qw(getcwd);
use File::Spec;

my $DISCOUNT_VERSION = "3.0.2.0";
my $DISCOUNT_DIR = "discount-$DISCOUNT_VERSION";

sub new {
    my ($class, %argv) = @_;

    $class->SUPER::new(
        %argv,
        needs_compiler => 1,
        include_dirs => [$DISCOUNT_DIR],
    );
}

sub _build_discount {
    my $self = shift;

    my $cwd = getcwd();
    chdir $DISCOUNT_DIR or die "chdir $DISCOUNT_DIR: $!";
    my $ok = do {
        local $ENV{CC} = $self->config("cc") . " -fPIC";
        $self->do_system("sh", "configure.sh");
    };
    $ok &&= $self->do_system($self->config("make"), "clean");
    $ok &&= $self->do_system($self->config("make"), "libmarkdown");
    chdir $cwd or die "chdir $cwd: $!";
    $ok;
}

sub ACTION_code {
    my ($self, @argv) = @_;

    my $spec = $self->_infer_xs_spec(File::Spec->catfile("lib", "Text", "Markdown", "Discount.xs"));
    my $archive = File::Spec->catfile($DISCOUNT_DIR, "libmarkdown.a");
    my @sources = (
        __FILE__,
        $spec->{lib_file},
        grep { -f } glob(File::Spec->catfile($DISCOUNT_DIR, "*")),
    );
    if (!$self->up_to_date(\@sources, $archive)) {
        $self->_build_discount or die;
    }
    push @{$self->{properties}{objects}}, $archive;
    $self->SUPER::ACTION_code(@argv);
}

1;
