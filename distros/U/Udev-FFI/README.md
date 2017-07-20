# NAME

Udev::FFI - Perl bindings for libudev using ffi.

# SYNOPSIS

    use Udev::FFI;

    #get udev version
    my $udev_version = Udev::FFI::udev_version();
    if(defined $udev_version) {
        print $udev_version. "\n";
    }
    else {
        warn "Can't get udev version: $@";
    }


    #create udev context
    my $udev = Udev::FFI->new() or
        die "Can't create udev context: $@";

# DESCRIPTION

Udev::FFI exposes OO interface to libudev.

# EXAMPLES

See examples folder.

# SEE ALSO

libudev

[FFI::Platypus](https://metacpan.org/pod/FFI::Platypus)

# AUTHOR

Ilya Pavlov, <iluxz@mail.ru>

# COPYRIGHT AND LICENSE

Copyright (C) 2017 by Ilya Pavlov

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License for more details.

You should have received a copy of the GNU Library General Public License along with this library; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
