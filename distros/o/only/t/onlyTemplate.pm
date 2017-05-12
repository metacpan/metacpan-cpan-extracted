package onlyTemplate;
@EXPORT = qw(write_template);
use strict;
use base 'Exporter';
use File::Spec;
use File::Path;

sub write_template {
    my ($template_path, $target_path, $lookup) = @_;
    open TEMPLATE, $template_path
      or die "Can't open $template_path for input:\n$!\n";
    my $template = do {local $/;<TEMPLATE>};
    $template =~ s/<%(\w+)%>/$lookup->{$1}/g;
    close TEMPLATE;

    my @parts = split '/', $target_path;
    my $file = pop @parts;
    mkpath(File::Spec->catdir(@parts));
    my $target = File::Spec->catfile(@parts, $file);

    open CONFIG, "> $target"
      or die "Can't open $target for output:\n$!\n";
    print CONFIG $template;
    close CONFIG;
}

1;
