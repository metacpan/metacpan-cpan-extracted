package Win32::Packer::InstallerMaker::zip;

use Path::Tiny;
use Scalar::Util qw(looks_like_number);
use Win32::Packer::Helpers qw(fn_maybe_add_extension);

my %ct;
BEGIN {
    package
        Win32::Packer::InstallerMaker::zip::ct;
    use Archive::Zip qw(:CONSTANTS);

    for (keys %{__PACKAGE__ . '::'}) {
        if (/^(COMPRESSION(?:_LEVEL)?)_(\w+)$/) {
            my $type = $1;
            my $name = $2;
            no strict refs;
            $ct{$type}{$name} = $ct{$type}{$_} = &{$_}();
        }
    }
    $ct{COMPRESSION_LEVEL}{BEST} = $ct{COMPRESSION_LEVEL}{BEST_COMPRESSION}
}

use Moo;
use namespace::autoclean;

extends 'Win32::Packer::InstallerMaker';

has zip_name => (is => 'lazy', coerce => sub { path(fn_maybe_add_extension($_[0], 'zip')) } );
has compression => (is => 'ro');
has compression_level => (is => 'ro');
has toplevel => (is => 'lazy');

sub _build_toplevel { shift->app_name }

sub _build_zip_name {
    my $self = shift;
    my $basename = join '-', grep defined, $self->app_name, $self->app_version;
    $self->output_dir->child("$basename.zip");
}

sub _ct {
    my $self = shift;
    my $slot = shift;
    my $val = $self->$slot // return;
    return $val if looks_like_number($val);
    my $ucslot = uc $slot;
    my $ct = $ct{$ucslot}
        or $self->_die("Internal error: invalid constant type $slot");

    my $ucval = uc $val;
    $ct->{$ucval} // $ct->{"${ucslot}_${ucval}"} //
        $self->_die("Invalid constant '$val' for slot '$slot'");
}

sub run {
    my $self = shift;
    my $zip = Archive::Zip->new;

    my $toplevel = $self->toplevel;
    $toplevel =~ s{/*$}{/} if length $toplevel;

    my $compression_method = $self->_ct('compression');
    my $compression_level = $self->_ct('compression_level');

    my %add_file_opts;
    $add_file_opts{compressionLevel} = $compression_level if defined $compression_level;

    my $fs = $self->_fs;
    for my $to (sort keys %$fs) {
        my $topto = "$toplevel$to";
        $self->log->trace("Adding object '$topto' to zip");
        my $obj = $fs->{$to};
        my $type = $obj->{type};
        if ($type eq 'dir') {
            $zip->addDirectory({ zipName => "$topto/" }) //
                $self->_die("Unable to add directory as $topto to zip archive");
        }
        elsif ($type eq 'file') {
            my $member = $zip->addFile({ filename => "$obj->{path}", zipName => $topto }) //
                $self->_die("Unable to add file  $obj->{path} as $topto to zip archive");
            $member->desiredCompressionMethod($compression_method) if defined $compression_method;
            $member->desiredCompressionLevel($compression_level) if defined $compression_level;
        }
        else {
            $self->log->warn("Unknown file system object type '$type' for '$topto', ignoring it");
        }
    }
    my $zip_name = $self->zip_name;
    $self->log->trace("Creating zip archive $zip_name");
    $zip->writeToFileNamed("$zip_name");
    $self->log->info("Zip file created at $zip_name");
}



1;
