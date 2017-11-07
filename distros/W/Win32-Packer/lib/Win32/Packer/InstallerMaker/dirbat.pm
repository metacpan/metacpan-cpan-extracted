package Win32::Packer::InstallerMaker::dirbat;

use Path::Tiny;
use Win32;
use Win32::Packer::Helpers qw(win32_cmd_quote);

use Moo;
use namespace::autoclean;

extends 'Win32::Packer::InstallerMaker';

has target_dir => (is => 'lazy', coerce => \&path);
has target_bat => (is => 'lazy', coerce => \&path);

sub _build_target_dir { shift->app_name }

sub _build_target_bat {
    my $self = shift;
    my $basename = join '-', grep defined, $self->app_name, $self->app_version;
    $self->output_dir->child("$basename.bat");
}

sub run {
    my $self = shift;

    my $bat = $self->target_bat;
    my $fh = $bat->filehandle('>');
    my $target_dir = $self->target_dir;

    if ($target_dir ne '' and $target_dir ne '.') {
        print {$fh} "mkdir ".win32_cmd_quote($target_dir->canonpath)."\n";
    }


    my $fs = $self->_fs;

    # my (%group, @d);
    # for my $to (sort keys %$fs) {
    #     my $obj = $fs->{$to};
    #     my $type = $obj->{type};
    #     if ($type eq 'file') {
    #         my $key = path($to)->parent->canonpath;
    #         push @{$group{$key} //= []}, $to;
    #     }
    #     else {
    #         push @d, $to;
    #     }
    # }

    # while (@d) {
    #     my $args = '';
    #     while (@d and length $args < 7000) {
    #         my $to = shift @d;
    #         my $topto = $target_dir->child($to)->canonpath;
    #         $args .= ' ' . win32_cmd_quote($topto);
    #     }
    #     print {$fh} "mkdir$args\n";
    # }

    # for my $key (sort keys %group) {
    #     my $topkey = $target_dir->child($key)->canonpath;
    #     my @f = @{$group{$key}};
    #     while (@f) {
    #         my $args = '';
    #         while (@f and length $args < 7000) {
    #             my $to = shift @f;
    #             my $path = path($fs->{$to}{path})->canonpath;
    #             $args .= ' ' . win32_cmd_quote($path);
    #         }
    #         print {$fh} "copy$args ".win32_cmd_quote($topkey)."\n";
    #     }
    # }

    # The following code works but the generated BAT file is very
    # slow...

    for my $to (sort keys %$fs) {
        my $obj = $fs->{$to};
        my $type = $obj->{type};
        my $topto = $target_dir->child($to)->canonpath;
        $self->log->trace("Adding object '$topto' of type $type");
        if ($type eq 'dir') {
            $self->_cmdf($fh, "mkdir %s", $topto);
        }
        elsif ($type eq 'file') {
            my $key = path($to)->parent;
            my $path = path($obj->{path})->canonpath;
            $self->_cmdf($fh, "copy %s %s", $path, $topto);
        }
        else {
            $self->log->warn("Unknown file system object type '$type' for '$topto', ignoring it");
        }
    }

    $self->log->info("Bat installer generated as $bat");

}

sub _cmdf {
    my ($self, $fh, $templ, @args) = @_;
    printf {$fh} "$templ\n", win32_cmd_quote @args;
}


1;
