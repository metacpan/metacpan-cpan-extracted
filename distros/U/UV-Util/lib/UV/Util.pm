package UV::Util;

our $VERSION = '0.003';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

use strict;
use warnings;

require XSLoader;
XSLoader::load();

1;
__END__

=encoding utf8

=head1 NAME

UV::Util - Some utility functions from libUV.

=head1 WARNING

UV::Util is being released as a learning process that will hopefully be folded
into a more complete set of modules allowing use of libUV with Perl later. In
other words, this will be more useful later. If it happens to be useful now,
that's awesome. If not, hopefully it will be soon. Until then, please let me know
of any errors during installation or of anything I can do to make this better.

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;
  use feature ':5.14';

  use Data::Dumper::Concise qw(Dumper);
  use UV::Util;
  use Syntax::Keyword::Try;

  my $res;
  try {
    $res = UV::Util::cpu_info();
  }
  catch {
    die "Aw, man. $@";
  }

=head1 DESCRIPTION

This module provides access to a few of the functions in the miscellaneous
L<libUV|http://docs.libuv.org/en/v1.x/misc.html> utilities. While it's extremely
unlikely, all functions here can throw an exception on error unless specifically
stated otherwise in the function's description.

=head1 CONSTANTS

L<UV::Util> makes the following constants available that represent different
L<handle types|http://docs.libuv.org/en/latest/handle.html#c.uv_handle_type>.

=head2 UV_UNKNOWN_HANDLE

=head2 UV_ASYNC

=head2 UV_CHECK

=head2 UV_FS_EVENT

=head2 UV_FS_POLL

=head2 UV_HANDLE

=head2 UV_IDLE

=head2 UV_NAMED_PIPE

=head2 UV_POLL

=head2 UV_PREPARE

=head2 UV_PROCESS

=head2 UV_STREAM

=head2 UV_TCP

=head2 UV_TIMER

=head2 UV_TTY

=head2 UV_UDP

=head2 UV_SIGNAL

=head2 UV_FILE

=head2 UV_HANDLE_TYPE_MAX

=head1 FUNCTIONS

All functions provided here provide a Perl interface to their
L<libUV|http://docs.libuv.org/en/latest/misc.html> equivalents.

=head2 cpu_info

    use Data::Dumper;
    use UV::Util;
    use Syntax::Keyword::Try;

    my $res;
    try { $res = UV::Util::cpu_info(); }
    catch { die "Aw, man. $@"; }
    say Dumper $res;
    # [
    #   {
    #     cpu_times => {
    #       idle => "1157161200",
    #       irq => 19912800,
    #       nice => 242400,
    #       sys => 8498700,
    #       user => 39428000
    #     },
    #     model => "Intel(R) Core(TM) i7-7700HQ CPU \@ 2.80GHz",
    #     speed => 1048
    #   },
    #   {
    #     cpu_times => {
    #       idle => 16922900,
    #       irq => 846300,
    #       nice => 371800,
    #       sys => 6491400,
    #       user => 34690000
    #     },
    #     model => "Intel(R) Core(TM) i7-7700HQ CPU \@ 2.80GHz",
    #     speed => 899
    #   }
    # ]

This L<function|http://docs.libuv.org/en/v1.x/misc.html#c.uv_cpu_info>
returns an array reference full of hashrefs. Each hashref represents an
available CPU on your system. C<cpu_times>, C<model>, and C<speed> will be
supplied for each.

=head2 get_free_memory

    use UV::Util;
    use Syntax::Keyword::Try;

    my $res;
    try { $res = UV::Util::get_free_memory(); }
    catch { die "Aw, man. $@"; }
    say $res; # 23052402688

This function returns an unsigned integer representing the number of bytes of
free memory available.

=head2 get_total_memory

    use UV::Util;
    use Syntax::Keyword::Try;

    my $res;
    try { $res = UV::Util::get_total_memory(); }
    catch { die "Aw, man. $@"; }
    say $res; # 33452101632

This function returns an unsigned integer representing the number of bytes of
total memory in the system.

=head2 getrusage

    use Data::Dumper;
    use UV::Util;
    use Syntax::Keyword::Try;

    my $res;
    try { $res = UV::Util::getrusage(); }
    catch { die "Aw, man. $@"; }
    say Dumper $res;
    # {
    #   ru_idrss => 0,
    #   ru_inblock => 0,
    #   ru_isrss => 0,
    #   ru_ixrss => 0,
    #   ru_majflt => 0,
    #   ru_maxrss => 10132,
    #   ru_minflt => 1624,
    #   ru_msgrcv => 0,
    #   ru_msgsnd => 0,
    #   ru_nivcsw => 1,
    #   ru_nsignals => 0,
    #   ru_nswap => 0,
    #   ru_nvcsw => 1,
    #   ru_oublock => 0,
    #   ru_stime => "0.005963",
    #   ru_utime => "0.02801"
    # }

This L<function|http://docs.libuv.org/en/v1.x/misc.html#c.uv_getrusage>
returns a hash reference of resource metrics for the current process.

=head2 guess_handle_type

    use UV::Util;
    use Syntax::Keyword::Try;

    my $res;
    try { $res = UV::Util::guess_handle_type(\*STDIN); }
    catch { die "Aw, man. $@"; }
    say "yay!" if ($res == UV::Util::UV_TTY);

This L<function|http://docs.libuv.org/en/latest/misc.html#c.uv_guess_handle>
takes in a reference to a handle (e.g. C<\*STDIN>) and returns an integer that
represents one of the L<CONSTANTS|UV::Util/CONSTANTS> above.

=head2 hrtime

    use UV::Util;

    # does not throw exceptions
    my $time = UV::Util::hrtime();

This L<function|http://docs.libuv.org/en/latest/misc.html#c.uv_hrtime>
returns the current high-resolution real time. This is expressed in nanoseconds.
It is relative to an arbitrary time in the past. It is not related to the time
of day and therefore not subject to clock drift. The primary use is for
measuring performance between intervals.

Not every platform can support nanosecond resolution; however, this value will
always be in nanoseconds.

=head2 interface_addresses

    use Data::Dumper qw(Dumper);
    use UV::Util;
    use Syntax::Keyword::Try;

    my $res;
    try { $res = UV::Util::interface_addresses(); }
    catch { die "Aw, man. $@"; }
    say Dumper $res;
    # [
    #   {
    #     address => "127.0.0.1",
    #     is_internal => 1,
    #     mac => "00:00:00:00:00:00",
    #     name => "lo",
    #     netmask => "255.0.0.0"
    #   },
    # ]


This L<function|http://docs.libuv.org/en/latest/misc.html#c.uv_interface_addresses>
returns an array reference containing hash references representing each of your
available interfaces.

=head2 loadavg

    use Data::Dumper qw(Dumper);
    use UV::Util;

    # does not throw exceptions
    my $res = UV::Util::loadavg();
    say Dumper $res;
    # [
    #   "0.43212890625",
    #   "0.39599609375",
    #   "0.27880859375"
    # ]

This L<function|http://docs.libuv.org/en/latest/misc.html#c.uv_loadavg>
returns an array reference containing the
L<load average|http://en.wikipedia.org/wiki/Load_(computing)>.

On Windows, this will B<always> return C<[0,0,0]> as it's not implemented.

=head2 resident_set_memory

    use Data::Dumper qw(Dumper);
    use UV::Util;
    use Syntax::Keyword::Try;

    my $res;
    try { $res = UV::Util::resident_set_memory(); }
    catch { die "Aw, man. $@"; }
    say Dumper $res; # 10473472

This L<function|http://docs.libuv.org/en/latest/misc.html#c.uv_resident_set_memory>
returns an unsigned integer representing the resident set size (RSS) for the
current process.

=head2 uptime

    use Data::Dumper qw(Dumper);
    use UV::Util;
    use Syntax::Keyword::Try;

    my $res;
    try { $res = UV::Util::resident_set_memory(); }
    catch { die "Aw, man. $@"; }
    say Dumper $res; # uptime

This L<function|http://docs.libuv.org/en/latest/misc.html#c.uv_uptime>
returns a float representing the current system uptime.

=head2 version

    use UV::Util;

    say UV::Util::version();
    # 1.9.1

This L<function|http://docs.libuv.org/en/v1.x/version.html>
returns the libUV version number as a string. Does not throw errors.

=head1 COPYRIGHT AND LICENSE

Copyright 2017, Chase Whitener.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
