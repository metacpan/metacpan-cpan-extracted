package Win32::Packer::Helpers;

use 5.010;
use strict;
use warnings;
use Carp;
use Path::Tiny;

use Exporter qw(import);
our @EXPORT_OK = grep { no strict 'refs'; /^[a-z]/i and defined *{$_}{CODE} } keys %{Win32::Packer::Helpers::};

#use Data::Dumper; warn Dumper(\@EXPORT_OK);

sub assert_file { $_[0]->is_file or croak "$_[0] is not a file" }
sub assert_file_name { $_[0] =~ tr{<>:"/\\|?*}{} and croak "$_[0] is not a valid Windows file name" }
sub assert_dir  { $_[0]->is_dir or croak "$_[0] is not a directory" }

sub assert_aoh_path { defined $_->{path} or croak "$_ is not a path" for @{$_[0]} }
sub assert_aoh_path_file { $_->{path}->is_file or croak "$_->{path} is not a file" for @{$_[0]} }
sub assert_aoh_path_dir { $_->{path}->is_dir or croak "$_->{path} is not a directory" for @{$_[0]} }

sub assert_subsystem {
    $_[0] =~ /^(?:windows|console)$/
        or croak "app_subsystem must be 'windows' or 'console'";
}

sub assert_guid { $_[0] =~ /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/ }

sub mkpath {
    my $p = path(shift);
    $p->mkpath;
    $p
}

sub to_bool { $_[0] ? 1 : 0 }
sub to_list {
    return @{$_[0]} if ref $_[0] eq 'ARRAY';
    return $_[0] if defined $_[0];
    ()
}

sub to_uc { uc $_[0] }

sub to_array { [to_list(shift)] }

sub to_array_path { [map path($_), to_list(shift)] }

sub to_loh_path {
    map {
        my %h = (ref eq 'HASH' ? %$_ : (path => $_));
        defined and $_ = path($_) for @h{qw(path subdir icon)};
        $_ = to_array($_) for @h{qw(handles firewall_allow)};
        $_ = to_array_path($_) for @h{qw(search_path)};
        $h{basename} //= $h{path}->basename(qr/\.\w*/);
        assert_subsystem($h{subsystem}) if defined $h{subsystem};
        \%h
    } to_list(shift)
}

sub to_aoh_path { [ to_loh_path(shift) ] } 

sub windows_directory {
    require Win32::API;
    state $fn = Win32::API->new("KERNEL32","GetWindowsDirectoryA","PN","N");
    my $buffer = "\0" x 255;
    $fn->Call($buffer, length $buffer);
    $buffer =~ tr/\0//d;
    path($buffer)->realpath;
}

sub c_string_quote {
    my $str = shift;
    $str =~ s/(["\\])/\\$1/g;
    qq("$str")
}

sub fn_maybe_add_extension {
    my ($fn, $ext) = @_;
    $ext =~ s/^\.*/./;
    $fn =~ s/\Q$ext\E$//;
    "$fn$ext"
}

sub _w32q {
    my $arg = shift;
    for ($arg) {
        $_ eq '' and return '""';
        if (/[ \t\n\x0b"]/) {
            s{(\\+)(?="|\z)}{$1$1}g;
            s{"}{\\"}g;
            return qq("$_")
        }
        return $_
    }
}

sub win32_cmd_quote {
    my @r = map _w32q($_), @_;
    wantarray ? @r : $r[0];
}

sub guid {
    my $self = shift;
    require Data::GUID;
    Data::GUID->new->as_string;
}

1;
