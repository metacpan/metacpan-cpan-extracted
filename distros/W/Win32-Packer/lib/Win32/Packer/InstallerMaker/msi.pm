package Win32::Packer::InstallerMaker::msi;

use Win32::Packer::Helpers qw(guid mkpath assert_file assert_file_name assert_dir);

use XML::FromPerl qw(xml_from_perl);
use Path::Tiny;
use Win32 ();
use Moo;
use namespace::autoclean;

extends 'Win32::Packer::InstallerMaker';

has versioned_app_name => (is => 'lazy', isa => \&assert_file_name);

has wix_dir     => ( is => 'lazy', coerce => \&mkpath, isa => \&assert_dir );
has wxs_fn      => ( is => 'lazy', coerce => \&path);
has wixobj_fn   => ( is => 'lazy', cperce => \&path);
has msi_fn      => ( is => 'lazy', coerce => \&path);

has _wxs_perl   => ( is => 'lazy' );
has _wxs        => ( is => 'lazy', coerce => \&path, isa => \&assert_file );
has _wixobj     => ( is => 'lazy', coerce => \&path, isa => \&assert_file );
has _msi        => ( is => 'lazy', coerce => \&path, isa => \&assert_file );

has wix_toolset => ( is => 'lazy', coerce => \&path, isa => \&assert_dir );
has candle_exe  => ( is => 'lazy', coerce => \&path, isa => \&assert_file );
has light_exe   => ( is => 'lazy', coerce => \&path, isa => \&assert_file );

sub _mkid {
    my $self = shift;
    my $prefix = shift;
    my $ix = ++($self->{_last_ix});
    my $id = join('_', grep defined, $prefix, $ix, @_);
    $id =~ s/\W/_/g;
    $id
}

sub _build_msi_fn {
    my $self = shift;
    my $basename = join '-', grep defined, $self->app_name, $self->app_version;
    $self->output_dir->child("$basename.msi");
}

sub _build_wix_toolset {
    my $self = shift;
    my $pfiles = Win32::GetFolderPath(Win32::CSIDL_PROGRAM_FILES())
        // $self->system_drive->child('Program Files');

    my @c = path($pfiles)->children(qr/^Wix\s+Toolset\b/i);
    $c[0] // $self->_die("Wix Toolset not found in '$pfiles'");
}

sub _build_candle_exe { shift->wix_toolset->child('bin/candle.exe') }

sub _build_light_exe { shift->wix_toolset->child('bin/light.exe') }

sub _build_versioned_app_name {
    my $self = shift;
    join ' ', grep defined, $self->app_name, $self->app_version;
}

sub _build_wix_dir { shift->work_dir->child('wix') }

sub _build_wixobj_fn {
    my $self = shift;
    $self->wix_dir->child($self->app_name . ".wixobj");
}

sub _build_wxs_fn {
    my $self = shift;
    $self->wix_dir->child($self->app_name . ".wxs");
}

sub _build__wxs_perl {
    my $self = shift;

    my $data = [ Wix => { xmlns => 'http://schemas.microsoft.com/wix/2006/wi',
                          'xmlns:fw' => 'http://schemas.microsoft.com/wix/FirewallExtension' },
                 my $product =
                 [ Product => { Name         => $self->versioned_app_name,
                                Id           => guid,
                                Manufacturer => $self->app_vendor,
                                Version      => $self->app_version,
                                Language     => '1033', Codepage => '1252' },
                   [ Package => { Description      => $self->app_description,
                                  Keywords         => $self->app_keywords,
                                  Comments         => $self->app_comments,
                                  Manufacturer     => $self->app_vendor,
                                  InstallerVersion => '405',
                                  Languages        => '1033',
                                  Compressed       => 'yes',
                                  SummaryCodepage  => '1252' } ],
                   [ MediaTemplate => { EmbedCab => 'yes' } ],
                   my $target_dir =
                   [ Directory => { Id => 'TARGETDIR', Name => 'SourceDir' },
                     [ Directory => { Id => 'ProgramFilesFolder', Name => 'PFiles' },
                       my $install_dir =
                       [ Directory => { Id => 'INSTALLDIR', Name => $self->app_name } ]]],
                   my $feature =
                   [ Feature => { Id    => 'MainProduct',
                                  Title => 'Main Product',
                                  Level => '1' } ],
                   [ UIRef => { Id => 'WixUI_InstallDir' } ],
                   [ Property => { Id => 'WIXUI_INSTALLDIR', Value => 'INSTALLDIR' } ]]];

    if (defined (my $app_id = $self->app_id)) {
        $self->log->info("MSI UpgradeCode: $app_id");
        $product->[1]{UpgradeCode} = $self->app_id;
    }
    else {
        $self->log->warn("An application Id has not been provided, consider adding one otherwise "
                         . "the generated installer would not be upgreadable!");
    }

    if (defined (my $icon = $self->icon)) {
        push @$product,
            [ Icon     => { Id => 'Icon.ico', SourceFile => $icon } ],
            [ Property => { Id => "ARPPRODUCTICON", Value => "Icon.ico" } ];
    }

    my %dir = ('.' => $install_dir);
    my %dir_id = ('.' => 'INSTALLDIR');
    my @shortcuts;
    my $license;
    my $fs = $self->_fs;
    for my $to (sort keys %$fs) {
        my $obj = $fs->{$to};
        my $parent = path($to)->parent;
        my $basename = path($to)->basename;
        my $type = $obj->{type};
        my $e;
        if ($type eq 'dir') {
            my $id = $dir_id{$to} = $self->_mkid(dir => $basename);
            $dir{$to} = $e = [ Directory => { Id => $id,
                                              Name => $basename }];
        }
        elsif ($type eq 'file') {
            my $id = $self->_mkid(component => $basename);
            my $file_id = $self->_mkid(component => $basename);
            $e = [ Component => { Id => $id, Guid => guid },
                   my $file =
                   [ File => { Name   => $basename,
                               Source => path($obj->{path})->canonpath,
                               Id     => $file_id } ] ];

            $license = $to if $obj->{_is_license};

            if (defined (my $hs = $obj->{handles})) {
                $self->log->info("Adding handlers for $to") if @$hs;
                for my $hs (@$hs) {
                    if (defined (my $ext = $hs->{extension})) {
                        $ext =~ s/^\.//;
                        $self->log->debug("file $to handles extension $ext");
                        my $id = $self->_mkid(component => $basename);
                        push @$target_dir,
                            [ Component => { Id => $id, Guid => guid, KeyPath => 'yes' },
                              [ ProgId => { Id => $self->_mkid(progid => $basename),
                                            Icon => $file_id, IconIndex => 0 },
                                [ Extension => { Id => ".$ext",
                                                 ContentType => $hs->{content_type} // "application/x-$ext" },
                                  [ Verb => { Id => 'open', Command => '&Open',
                                              TargetFile => $file_id, Argument => '"%1"' } ] ] ] ];

                        push @$feature, [ ComponentRef => { Id => $id } ];
                    }

                    if (defined (my $scheme = $hs->{scheme})) {
                        $self->log->debug("file $to handles scheme $scheme");
                        push @$e,
                            [ RegistryKey => { Root => 'HKCR',
                                               Key  => $scheme },
                              [ RegistryValue => { Type=> 'string', Name => 'URL Protocol', Value => ''} ],
                              [ RegistryValue => { Type => 'string', Value => "URL:$scheme" } ],
                              [ RegistryKey => { Key => "DefaultIcon" },
                                [ RegistryValue => { Type => 'string', Value => "[$dir_id{$parent}]$basename" } ] ],
                              [ RegistryKey => { Key => 'shell\\open\\command' },
                                [ RegistryValue => { Type => "string",
                                                     Value => qq("[$dir_id{$parent}]$basename" "%1") } ]]];
                    }
                }
            }

            push @$feature, [ ComponentRef => { Id => $id }];

            if (defined(my $shortcut = $obj->{shortcut})) {
                my $id = $self->_mkid(component => $basename);

                push @shortcuts,
                    [ Component => { Id => $id, Guid => guid },
                      [ Shortcut => { Id          => $self->_mkid(shortcut => $basename),
                                      Name        => $shortcut,
                                      Description => $obj->{shortcut_description} // $shortcut,
                                      Target      => "[$dir_id{$parent}]$basename" } ],
                                   [ RemoveFolder => { Id => $self->_mkid(remove => $basename),
                                                       On => 'uninstall' } ],
                                   [ RegistryValue => { Root    => 'HKCU',
                                                        Key     => join('\\', 'Software', $self->app_vendor, $self->app_name),
                                                        Name    => 'installed',
                                                        Type    => 'integer',
                                                        Value   => '1',
                                                        KeyPath => 'yes' } ] ];
                push @$feature,
                    [ ComponentRef => { Id => $id } ];
            }

            if (defined (my $rules = $obj->{firewall_allow})) {
                if (@$rules) {
                    for my $rule (@$rules) {
                        my ($src, $proto) = split /:/, lc $rule;
                        my $id = $self->_mkid(component => $basename, 'fw_rule');
                        my $rule_id = $self->_mkid(firewall => $basename);
                        push @$target_dir,
                            [ Component => { Id => $id, Guid => guid, KeyPath => 'yes' },
                              my $r =
                              [ 'fw:FirewallException' => { Id            => $rule_id,
                                                            Name          => join(" ", $self->versioned_app_name, rule => $rule_id),
                                                            Program       => "[$dir_id{$parent}]$basename",
                                                            IgnoreFailure => 'yes' } ] ];
                        push @$feature,
                            [ ComponentRef => { Id => $id } ];

                        if ($src eq 'localhost') {
                            push @$r, [ 'fw:RemoteAddress' => '127.0.0.1/24' ]
                        }
                        elsif ($src eq 'localnet' or $src eq 'localsubnet') {
                            $r->[1]{Scope} = 'localSubnet';
                        }
                        elsif ($src eq 'any' or $src eq '*') {
                            $r->[1]{Scope} = 'any';
                        }
                        if (defined $proto) {
                            $r->[1]{Protocol} = $proto;
                        }
                    }
                }
            }
        }
        else {
            $self->log->warn("Unknown object type '$type' for '$to', ignoring...");
            next;
        }
        my $parent_dir = $dir{$parent} // $self->_die("Parent directory '$parent' for '$to' not found");
        push @{$parent_dir}, $e;
    }

    if (@shortcuts) {
        if (@shortcuts > 1) {
            push @$target_dir,
                [ Directory => { Id => 'ProgramMenuFolder' },
                  [ Directory => { Id => 'MyShortcutsDir',
                                   Name => $self->app_name }, @shortcuts ] ];
        }
        else {
            push @$target_dir,
                [ Directory => { Id => 'ProgramMenuFolder' }, @shortcuts ];
        }
    }

    if (defined $license) {
        push @$product,
            [ WixVariable => { Id => 'WixUILicenseRtf',
                               Value => $license } ];
    }

    $data
}

sub _build__wxs {
    my $self = shift;
    $self->log->info("Generating Wxs file");
    my $data = $self->_wxs_perl;
    my $doc = xml_from_perl $data;
    my $wxs_fn = $self->wxs_fn;
    $doc->toFile($wxs_fn, 2);
    $self->log->debug("Wxs file created at '$wxs_fn'");
    $wxs_fn
}

sub _build__wixobj {
    my $self = shift;
    my $out = $self->wixobj_fn;
    my $in = $self->_wxs;
    $self->log->info("Generating Wixobj file");
    my $rc = $self->_run_cmd($self->candle_exe, $in, -out => $out, -ext => 'WixFirewallExtension')
        or $self->_die("unable to compile wxs file '$in'");
    $out;
}

sub _build__msi {
    my $self = shift;
    my $out = $self->msi_fn;
    my $in = $self->_wixobj;

    $self->log->info("Generating MSI file");
    my $wix_toolset = $self->wix_toolset;
    my @ext = map { -ext => $wix_toolset->child(bin => "Wix${_}Extension.dll")->canonpath } qw(UI Firewall);
    my $rc = $self->_run_cmd($self->light_exe, $in, @ext, -out => $out)
        or $self->_die("unable to link wixobj file '$in'");
    $out
}

sub run {
    my $self = shift;
    my $wxs = $self->_msi;
}

1;
