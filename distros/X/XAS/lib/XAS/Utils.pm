package XAS::Utils;

our $VERSION = '0.06';

use DateTime;
use Try::Tiny;
use XAS::Exception;
use DateTime::Format::Pg;
use Digest::MD5 'md5_hex';
use Params::Validate ':all';
use DateTime::Format::Strptime;
use POSIX qw(:sys_wait_h setsid);

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'Badger::Utils',
  constants  => 'HASH ARRAY LOG_LEVELS',
  filesystem => 'Dir File',
  exports => {
    all => 'db2dt dt2db trim ltrim rtrim daemonize hash_walk  
            load_module bool compress exitcode _do_fork glob2regex dir_walk
            env_store env_restore env_create env_parse env_dump env_clear
            left right mid instr is_truthy is_falsey run_cmd
            validate_params validation_exception level2syslog
            stat2text bash_escape create_argv de_camel_case',
    any => 'db2dt dt2db trim ltrim rtrim daemonize hash_walk  
            load_module bool compress exitcode _do_fork glob2regex dir_walk
            env_store env_restore env_create env_parse env_dump env_clear
            left right mid instr is_truthy is_falsey run_cmd
            validate_params validation_exception level2syslog
            stat2text bash_escape create_argv de_camel_case',
    tags => {
      dates      => 'db2dt dt2db',
      env        => 'env_store env_restore env_create env_parse env_dump env_clear',
      modules    => 'load_module',
      strings    => 'trim ltrim rtrim compress left right mid instr',
      process    => 'daemonize exitcode run_cmd _do_fork bash_escape create_argv',
      boolean    => 'is_truthy is_falsey bool',
      validation => 'validate_params validation_exception',
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub validation_exception {
    my $param = shift;
    my $class = shift;

    my $format = 'invalid parameters passed, reason: %s';
    my $method = Badger::Utils::dotid($class) . '.invparams';

    $param = trim(lcfirst($param));

    my $ex = XAS::Exception->new(
        type => $method,
        info => Badger::Utils::xprintf($format, $param),
    );

    $ex->throw();

}

sub validate_params {
    my $params = shift;
    my $specs  = shift;
    my $class  = shift;

    unless (defined($class)) {

        $class = (caller(1))[3];

    }

    my $results = validate_with(
        params => $params,
        called => $class,
        spec   => $specs,
        normalize_keys => sub {
            my $key = shift; 
            $key =~ s/^-//; 
            return lc $key;
        },
        on_fail => sub {
            my $param = shift;
            validation_exception($param, $class);
        },
    );

    return wantarray ? @$results : $results;

}

# recursively walk a HOH
sub hash_walk {
    my $p = validate_params(\@_, {
        -hash     => { type => HASHREF }, 
        -keys     => { type => ARRAYREF }, 
        -callback => { type => CODEREF },
    });

    my $hash     = $p->{'hash'};
    my $key_list = $p->{'keys'};
    my $callback = $p->{'callback'};

    while (my ($k, $v) = each %$hash) {

        # Keep track of the hierarchy of keys, in case
        # our callback needs it.

        push(@$key_list, $k);

        if (ref($v) eq 'HASH') {

            # Recurse.

            hash_walk(-hash => $v, -keys => $key_list, -callback => $callback);

        } else {
            # Otherwise, invoke our callback, passing it
            # the current key and value, along with the
            # full parentage of that key.

            $callback->($k, $v, $key_list);

        }

        pop(@$key_list);

    }

}

# recursively walk a directory structure
sub dir_walk {
    my $p = validate_params(\@_, {
        -directory => { isa  => 'Badger::Filesystem::Directory' },
        -callback  => { type => CODEREF },
        -filter    => { optional => 1, default => qr/.*/, callbacks => {
            'must be a compiled regex' => sub {
                return (ref shift() eq 'Regexp') ? 1 : 0;
            }
        }},
    });

    my $folder   = $p->{'directory'};
    my $filter   = $p->{'filter'};
    my $callback = $p->{'callback'};

    my @files = grep ( $_->path =~ /$filter/, $folder->files() );
    my @folders = $folder->dirs;

    foreach my $file (@files) {

        $callback->($file);

    }

    foreach my $folder (@folders) {

        dir_walk(-directory => $folder, -filter => $filter, -callback => $callback);

    }

}

# Perl trim function to remove whitespace from the start and end of the string
sub trim {
    my ($string) = validate_params(\@_, [1]);

    $string =~ s/^\s+//;
    $string =~ s/\s+$//;

    return $string;

}

# Left trim function to remove leading whitespace
sub ltrim {
    my ($string) = validate_params(\@_, [1]);

    $string =~ s/^\s+//;

    return $string;

}

# Right trim function to remove trailing whitespace
sub rtrim {
    my ($string) = validate_params(\@_, [1]);

    $string =~ s/\s+$//;

    return $string;

}

# replace multiple whitspace with a single space
sub compress {
    my ($string) = validate_params(\@_, [1]);

    $string =~ s/\s+/ /gms;

    return $string;

}

# emulate Basics string function left()
sub left {
    my ($string, $offset) = validate_params(\@_, [1,1]);

    return substr($string, 0, $offset);

}

# emulate Basics string function right()
sub right {
    my ($string, $offset) = validate_params(\@_, [1,1]);

    return substr($string, -($offset));

}

# emulate Basics string function mid()
sub mid {
    my ($string, $start, $length) = validate_params(\@_, [1,1,1]);

    return substr($string, $start - 1, $length);

}

# emulate Basics string function instr()
sub instr {
    my ($start, $string, $compare) = validate_params(\@_, [1,1,1]);

    if ($start =~ /^[0-9\-]+/) {

        $start++;

    } else {

        $compare = $string;
        $string = $start;
        $start = 0;

    }

    return index($string, $compare, $start) + 1;

}

sub de_camel_case {
    my ($s) = validate_params(\@_, [1]);

    my $o;
    my @a = split('', $s);
    my $z = scalar(@a);

    for (my $x = 0; $x < $z; $x++) {

        if ($a[$x] =~ /[A-Z]/) {

            if ($x == 0) {

                $o .= lc($a[$x]);

            } else {

                $o .= '_' . lc($a[$x]);

            }

        } else {

            $o .= $a[$x];

        }

    }

    return $o;

}

# Checks to see if the parameter is the string 't', 'true', 'yes', '0E0'
# or the number 1.
#
sub is_truthy {
    my ($parm) = validate_params(\@_, [1]);

    my @truth = qw(yes true t 1 0e0);

    return scalar(grep {lc($parm) eq $_} @truth);

}

# Checks to see if the parameter is the string 'f', 'false', 'no' or 
# the number 0.
#
sub is_falsey {
    my ($parm) = validate_params(\@_, [1]);

    my @truth = qw(no false f 0);

    return scalar(grep {lc($parm) eq $_} @truth);

}

sub bool {
    my ($item) = validate_params(\@_, [1]);

    my @truth = qw(yes true 1 0e0 no false f 0);
    return grep {lc($item) eq $_} @truth;

}

sub exitcode {

    my $ex    = $?;
    my $rc    = $ex >> 8;    # return code of process
    my $sig   = $ex & 127;   # signal it was killed with
    my $cored = $ex & 128;   # wither the process cored

    return $rc, $sig, $cored;

}

sub _do_fork {

    my $child = fork();

    unless (defined($child)) {

        my $ex = XAS::Exception->new(
            type => 'xas.utils.daemonize',
            info => "unable to fork, reason: $!"
        );

        $ex->throw;

    }

    exit(0) if ($child);

}

sub daemonize {

    _do_fork(); # initial fork
    setsid();   # become session leader
    _do_fork(); # second fork to prevent aquiring a controlling terminal

    # change directory to a netural place and set the umask

    chdir('/');
    umask(0);

    # redirect our standard file handles

    open(STDIN,  '<', '/dev/null');
    open(STDOUT, '>', '/dev/null');
    open(STDERR, '>', '/dev/null');

}

sub db2dt {
    my ($p) = validate_params(\@_, [
        { regex => qr/\d{4}-\d{2}-\d{2}.\d{2}:\d{2}:\d{2}/ }
    ]);

    my $parser = DateTime::Format::Strptime->new(
        pattern => '%Y-%m-%d %H:%M:%S',
        time_zone => 'local',
        on_error => sub {
            my ($obj, $err) = @_;
            my $ex = XAS::Exception->new(
                type => 'xas.utils.db2dt',
                info => $err
            );
            $ex->throw;
        }
    );

    return $parser->parse_datetime($p);

}

sub dt2db {
    my ($dt) = validate_params(\@_, [
        { isa => 'DateTime' }
    ]);

    return $dt->strftime('%Y-%m-%d %H:%M:%S');

}

sub run_cmd {
    my ($command) = validate_params(\@_, [1]);

    my @output = `$command 2>&1`;
    my ($rc, $sig, $cored) = exitcode();

    return \@output, $rc, $sig;

}

sub load_module {
    my ($module) = validate_params(\@_, [1]);

    my @parts;
    my $filename;

    @parts = split("::", $module);
    $filename = File(@parts);

    try {

        require $filename . '.pm';
        $module->import();

    } catch {

        my $x = $_;
        my $ex = XAS::Exception->new(
            type => 'xas.utils.load_module',
            info => $x
        );

        $ex->throw;

    };

}

sub glob2regex {
    my ($globstr) = validate_params(\@_, [1]);

    my %patmap = (
        '*' => '.*',
        '?' => '.',
        '[' => '[',
        ']' => ']',
    );

    $globstr =~ s{(.)} { $patmap{$1} || "\Q$1" }ge;

    return '^' . $globstr . '$';

}

sub stat2text {
    my ($stat) = validate_params(\@_, [1]);
    
    my $status = 'unknown';

    $status = 'suspended ready'   if ($stat == 6);
    $status = 'suspended blocked' if ($stat == 5);
    $status = 'blocked'           if ($stat == 4);
    $status = 'running'           if ($stat == 3);
    $status = 'ready'             if ($stat == 2);
    $status = 'other'             if ($stat == 1);

    return $status;

}

sub level2syslog {
    my ($level) = validate_params(\@_, [
        { regex => LOG_LEVELS },
    ]);

    my $translate = {
        info  => 'info',
        error => 'err',
        warn  => 'warning',
        fatal => 'alert',
        trace => 'notice',
        debug => 'debug'
    };

    return $translate->{lc($level)};

}

# ********************************************************************** 
# The Bourne shell treats some characters in a command's argument list as
# having a special meaning.  This could result in the shell executing    
# unwanted commands. This code escapes the special characters by         
# prefixing them with the \ character.                                   
#
# taken from: https://www.slac.stanford.edu/slac/www/resource/how-to-use/cgi-rexx/cgi-esc.html
#
# **********************************************************************

sub bash_escape {
    my $arg = shift;

    $arg =~ s/([;<>\*\|&\$!#\(\)\[\]\{\}:'"])/\\$1/g;

    return $arg;

}

#
# Extracted form Parse::CommandLine.
#

sub create_argv {
    my ($str) = validate_params(\@_, [1]);

    $str =~ s/\A\s+//ms;
    $str =~ s/\s+\z//ms;

    my @argv;
    my $buf;
    my $escaped;
    my $double_quoted;
    my $single_quoted;

    for my $char (split //, $str) {

        if ($escaped) {

            $buf .= $char;
            $escaped = undef;
            next;

        }

        if ($char eq '\\') {

            if ($single_quoted) {

                $buf .= $char;

            } else {

                $escaped = 1;

            }
            next;

        }

        if ($char =~ /\s/) {

            if ($single_quoted || $double_quoted) {

                $buf .= $char;

            } else {

                push @argv, $buf if defined $buf;
                undef $buf;

            }
            next;

        }

        if ($char eq '"') {

            if ($single_quoted) {

                $buf .= $char;
                next;

            }

            $double_quoted = !$double_quoted;
            next;

        }

        if ($char eq "'") {

            if ($double_quoted) {

                $buf .= $char;
                next;

            }

            $single_quoted = !$single_quoted;
            next;

        }

        $buf .= $char;

    }

    push @argv, $buf if defined $buf;

    if ($escaped || $single_quoted || $double_quoted) {

        my $ex = XAS::Exception->new(
            type => 'xas.utils.create_argv',
            info => 'invalid command line string',
        );

        $ex->throw;

    }

    return @argv;

}

sub env_store {

    my $env;

    while (my ($key, $value) = each(%ENV)) {

        $env->{$key} = $value;

    }

    return $env;

}

sub env_clear {
    
    while (my ($key, $value) = each(%ENV)) {
        
        delete $ENV{$key};
        
    }
    
}

sub env_restore {
    my ($env) = validate_params(\@_, [
        { type => HASHREF },
    ]);

    env_clear();
    env_create($env);

}

sub env_create {
    my ($env) = validate_params(\@_, [
        { type => HASHREF },
    ]);

    while (my ($key, $value) = each(%$env)) {

        $ENV{$key} = $value;

    }

}

sub env_parse {
    my ($e) = validate_params(\@_, [
        { type => SCALAR },
    ]);

    my $env;
    my @envs = split(';;', $e);

    foreach my $y (@envs) {

        my ($key, $value) = split('=', $y);
        $env->{$key} = $value;

    }

    return $env;

}

sub env_dump {

    my $env;

    while (my ($key, $value) = each(%ENV)) {

        $env .= "$key=$value;;";

    }

    # remove the ;; at the end

    chop $env;
    chop $env;

    return $env;

}

1;

__END__

=head1 NAME

XAS::Utils - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Base',
   utils   => 'db2dt dt2db'
 ;

 printf("%s\n", dt2db($dt));

=head1 DESCRIPTION

This module provides utility routines that can by loaded into your current 
namespace. 

=head1 METHODS

=head2 validate_params($params, $spec, $class)

This method is used to validate parameters. Internally this uses 
Params::Validate::validate_with() for the parameter validation. 

By convention, all named parameters have a leading dash. This method will 
strip off that dash and lower case the parameters name.

If an validation exception is thrown, the parameter name will have the dash 
stripped.

Based on the $spec, this can return an array or a hashref of validated
parameters and values. 

=over 4

=item B<$params>

An array ref to a set of parameters. 

=item B<$spec>

A validation spec as defined by L<Params::Validate|https://metacpan.org/pod/Params::Validate>.

=item B<$class>

An optional class that is calling this method. If one is not provided then
caller() is used to determine the calling method.

=back

=head2 validation_exception($param, $class)

This is a package level sub routine. It exists to provide a uniform exception
error message. It takes these parameters:

=over 4

=item B<$param>

The error message returned by L<Params::Validate|https://metacpan.org/pod/Params::Validate>.

=item B<$class>

The routine that the error occurred in.

=back

=head2 db2dt($datestring)

This routine will take a date format of YYYY-MM-DD HH:MM:SS and convert it
into a L<DateTime|https://metacpan.org/pod/DateTime> object.

=head2 dt2db($datetime)

This routine will take a L<DateTime|https://metacpan.org/pod/DateTime>
object and convert it into the following string: YYYY-MM-DD HH:MM:SS

=head2 trim($string)

Trim the whitespace from the beginning and end of $string.

=head2 ltrim($string)

Trim the whitespace from the end of $string.

=head2 rtrim($string)

Trim the whitespace from the beginning of $string.

=head2 compress($string)

Reduces multiple whitespace to a single space in $string.

=head2 left($string, $offset)

Return the left chunk of $string up to $offset. Useful for porting
VBS code. Makes allowances that VBS strings are ones based while 
Perls are zero based.

=head2 right($string, $offset)

Return the right chunk of $string starting at $offset. Useful for porting 
VBS code. Makes allowances that VBS strings are ones based while Perls 
are zero based.

=head2 mid($string, $offset, $length)

Return the chunk of $string starting at $offset for $length characters.
Useful for porting VBS code. Makes allowances that VBS strings are ones
based while Perls are zero based.

=head2 instr($start, $string, $compare)

Return the position in $string of $compare. You may offset within the
string with $start. Useful for porting VBS code. Makes allowances that
VBS strings are one based while Perls are zero based.

=head2 de_camel_case($string)

Break up a "CamelCase" string into a "camel_case" string. The opposit of
camel_case() from L<Badger::Utils|https://metacpan.org/pod/Badger::Utils>.

=head2 exitcode

Decodes Perls version of the exit code from a cli process. Returns three items.

 Example:

     my @output = `ls -l`;
     my ($rc, $sig, $cored) = exitcode();

=head2 run_cmd($command)

Run a command and capture the output, exit code and exit signal, stderr 
is merged with stdout.

 Example:
 
     my ($output, $rc, $sig) = run_cmd("ls -l");
     if ($rc == 0) {

         foreach my $line (@$output) {

             print $line;

         }

     }

=head2 daemonize

Become a daemon. This will set the process as a session lead, change to '/',
clear the protection mask and redirect stdin, stdout and stderr to /dev/null.

=head2 glob2regx($glob)

This method will take a shell glob pattern and convert it into a Perl regex.
This also works with DOS/Windows wildcards.

=over 4

=item B<$glob>

The wildcard to convert.

=back

=head2 hash_walk

This routine will walk a HOH and does a callback on the key/values that are 
found. It takes these parameters:

=over 4

=item B<-hash>

The hashref of the HOH.

=item B<-keys>

An arrayref of the key levels.

=item B<-callback>

The routine to call with these parameters:

=over 4

=item B<$key>

The current hash key.

=item B<$value>

The value of that key.

=item B<$key_list>

A list of the key depth.

=back

=back

=head2 dir_walk

This will walk a directory structure and execute a callback for the found 
files. It takes these parameters:

=over 4

=item B<-directory>

The root directory to start from.

=item B<-filter>

A compiled regex to compare files against.

=item B<-callback>

The callback to execute when matching files are found.

=back

=head2 load_module($module)

This routine will load a module. 

=over 4

=item B<$module>

The name of the module.

=back

=head2 stat2text($stat)

This will convert the numeric process status to a text string.

=over 4

=item B<$stat>

A number between 0 and 6.

 0 = 'unknown'
 1 = 'other'
 2 = 'ready'
 3 = 'running'
 4 = 'blocked'
 5 = 'suspended blocked'
 6 = 'suspended ready'

=back

=head2 level2syslog($level)

This will convert a XAS log level to an appropriate syslog priority.

=over 4

=item B<$level>

A XAS log level, it should be lower cased.

 info  = 'info',
 error = 'err',
 warn  = 'warning',
 fatal = 'alert',
 trace = 'notice',
 debug = 'debug'

=back

=head2 env_store

Remove all items from the $ENV variable and store them in a hash variable.

  Example:
    my $env = env_store();

=head2 env_restore

Remove all items from $ENV variable and restore it back to a saved hash variable.

  Example:
    env_restore($env);

=head2 env_create

Store all the items from a hash variable into the $ENV varable.

  Example:
    env_create($env);

=head2 env_parse

Take a formatted string and parse it into a hash variable. The string must have
this format: "item=value;;item2=value2";

  Example:
    my $string = "item=value;;item2=value2";
    my $env = env_parse($string);
    env_create($env);

=head2 env_dump

Take the items from the current $ENV variable and create a formatted string.

  Example:
    my $string = env_dump();
    my $env = env_create($string);

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<Badger::Utils|https://metacpan.org/pod/Badger::Utils>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
