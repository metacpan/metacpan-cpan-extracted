### Text::PORE::Group.pm
### Contains a group of Templates or TemplateGroups

package Text::PORE::Group;

use strict;
use Text::PORE::Volatile;
use Text::PORE;

@Text::PORE::Group::ISA = qw(Volatile);

my $templates_root = "./new_templates";

sub new {
    my ($class, $root, %attrs) = @_;

    my ($self) = new Volatile(%attrs);

    if (! $root) { $root = $templates_root; }
    $self->LoadAttributes('root' => $root, 'initialized' => 0);

    bless $self, $class;
    return $self;
}

sub GetAttribute {
    my ($self, $attr) = @_;

    if (! $self->SUPER::GetAttribute('initialized')) {
	$self->Initialize();
    }

    return $self->SUPER::GetAttribute($attr);
}

sub Initialize {
    my ($self) = @_;

    my $root = $self->{'root'};   # Don't use GetAttribute before we init

    opendir(DIR, $root);
    my @list = readdir(DIR);
    my @templates = grep { /\.tpl$/ && -f "$root/$_" } @list;
    my @dirs = grep { /^[^\.]/ && -d "$root/$_" } @list;
    closedir(DIR);

    my $dir;
    foreach $dir (@dirs) {
	my $new = new Text::PORE::Group("$root/$dir");
	$self->LoadAttributes($dir => $new);
    }

    my $tpl;
    foreach $tpl (@templates) {
	my $new = new Text::PORE::Template("$root/$tpl", "file");
	$tpl =~ s/\.tpl$//;
	$self->LoadAttributes($tpl => $new);
    }

    $self->LoadAttributes('initialized' => 1);
    return $self;
}

1;
