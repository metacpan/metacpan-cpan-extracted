package meon::Web::TimelineAggregate;

use meon::Web::SPc;
use meon::Web::Util;
use meon::Web::TimelineEntry;
use DateTime::Format::Strptime;
use File::Copy 'copy';
use Path::Class qw();
use IO::Any;

use Moose;
use MooseX::Types::Path::Class;
use 5.010;
use utf8;

has 'timeline_dir'        => (is=>'rw', isa=>'Path::Class::Dir', required => 1);
has 'timeline_sub_dir'    => (is=>'rw', isa=>'Path::Class::Dir', required => 1);
has 'other_timeline_dirs' => (is=>'rw', isa=>'ArrayRef[Path::Class::Dir]', required => 1);

sub refresh {
    my $self = shift;
    my $dir  = $self->timeline_sub_dir;
    my $timeline_dir = $self->timeline_dir;
    my $aggregated_file = $dir->file('index.xml');
    my $xpc = meon::Web::Util->xpc;

    $dir->mkpath
        unless -e $dir;
    unless (-e $dir->file('index.xml')) {
        $dir->resolve;
        $timeline_dir->resolve;
        my $list_index_file = Path::Class::file(
            meon::Web::SPc->datadir, 'meon-web', 'template', 'xml','timeline-list-index.xml'
        );
        my $timeline_index_file = Path::Class::file(
            meon::Web::SPc->datadir, 'meon-web', 'template', 'xml','timeline-index.xml'
        );
        copy($list_index_file, $aggregated_file) or die 'copy failed: '.$!;

        while (($dir = $dir->parent) && $timeline_dir->contains($dir) && !-e $dir->file('index.xml')) {
            copy($timeline_index_file, $dir->file('index.xml')) or die 'copy failed: '.$!;
        }
    }

    my $timeline_dom = XML::LibXML->load_xml(location => $aggregated_file);
    my ($timeline_el) = $xpc->findnodes('/w:page/w:content//w:timeline', $timeline_dom);
    die 'timeline element missing'
        unless $timeline_el;

    foreach my $old_entry ($timeline_el->childNodes()) {
        $timeline_el->removeChild($old_entry);
    }
    $timeline_el->appendText("\n");
    $timeline_el->setAttribute('class' => 'aggregate');

    my @entries_files;
    foreach my $other_timeline_dir (@{$self->other_timeline_dirs}) {
        next unless -d $other_timeline_dir;
        push(@entries_files, $other_timeline_dir->children(no_hidden => 1));
    }

    my @entries =
        map  { substr($_,0,-4) } # remove .xml
        map  { $_->relative($dir) }
        grep { $_->basename ne 'index.xml' }
        grep { !$_->is_dir }
        @entries_files
    ;

    foreach my $entry (@entries) {
        my $entry_node = $timeline_el->addNewChild( undef, 'w:timeline-entry' );
        $entry_node->setAttribute('href' => $entry);
        $timeline_el->appendText("\n");
    }

    IO::Any->spew($aggregated_file, $timeline_dom->toString, { atomic => 1 });
}

__PACKAGE__->meta->make_immutable;

1;
