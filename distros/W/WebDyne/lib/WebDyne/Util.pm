#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package WebDyne::Util;


#  Compiler Pragma
#
sub BEGIN {$^W=0}
use strict qw(vars);
use vars   qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use warnings;
no warnings qw(uninitialized redefine once);


#  Package wide vars and defaults, initialised in BEGIN
#
our (
    $WEBDYNE_DEBUG,
    $WEBDYNE_DEBUG_FILE,
    $WEBDYNE_DEBUG_FILTER,
    $WEBDYNE_DEBUG_MAX_LINES,
    $WEBDYNE_DEBUG_MAX_LENGTH,
    $WEBDYNE_DEBUG_NO_COLOUR,
    $WEBDYNE_ERROR_TEXT_SHOW_ALL,
    $WEBDYNE_ERROR_TEXT_CHAR_MAX
);


#  External modules
#
use Data::Dumper;
use File::Spec;
use IO::File;
use POSIX qw(strftime);


#  Use Exporter
#
require Exporter;


#  Exports
#
@EXPORT=qw(err errstr errclr errdump errsubst errstack errnofatal debug);
@EXPORT_OK=qw(perl_inc_dn apache_startup apache_shutdown);
%EXPORT_TAGS=(all => [@EXPORT, @EXPORT_OK]);


#  Version information
#
$VERSION='3.019';


#  Var to hold package wide hash, for data shared across package, and error stack
#
my (%Package, @Err);


#  All done. Positive return
#
1;


#==================================================================================================

#  Packace init, attempt to load optional Time::HiRes module
#
BEGIN {
    eval {require Time::HiRes; Time::HiRes->import(qw(time gettimeofday))};
    my %config=(
        WEBDYNE_DEBUG               => '',
        WEBDYNE_DEBUG_FILE          => '',
        WEBDYNE_DEBUG_FILTER        => '',
        WEBDYNE_DEBUG_MAX_LINES     => 6,
        WEBDYNE_DEBUG_MAX_LENGTH    => 1024,
        WEBDYNE_DEBUG_NO_COLOUR     => $ENV{'WEBDYNE_DEBUG_NO_COLOR'},
        WEBDYNE_ERROR_TEXT_SHOW_ALL => '',
        WEBDYNE_ERROR_TEXT_CHAR_MAX => $ENV{'WEBDYNE_ERROR_TEXT_CHAR_MAX'} || 72,
    );
    while (my($name, $value)=each(%config)) {
        ${__PACKAGE__."::${name}"}=defined($ENV{$name}) ? $ENV{$name} : $value;
    }
}


sub import {


    #  Get message
    #
    my ($message, @param)=@_;


    #  Get who is calling us
    #
    my $caller=(caller(0))[0] || return undef;


    #  fn, fh we will write to
    #
    my ($debug_fn, $debug_fh);


    #  Environment var overrides all
    #
    if ($debug_fn=$WEBDYNE_DEBUG_FILE) {

        #  fn is whatever spec'd
        #
        $debug_fh=IO::File->new($debug_fn, O_CREAT | O_APPEND | O_WRONLY) || do {
            warn("unable to open file '$debug_fn', $!");
            undef;
        };

    }
    elsif ($WEBDYNE_DEBUG) {


        #  fh is stderr
        #
        $debug_fh=\*STDERR;


    }
    elsif (ref(my $debug_hr=${"${caller}::DEBUG"}) eq 'HASH') {


        #  Debug is hash ref, extract filename etc and open
        #
        $debug_fn=$debug_hr->{'file'} || $debug_hr->{'filename'};
        my ($mode, $package)=@{$debug_hr}{qw(mode package)};
        if ($debug_fn && ($package ? ($package eq $caller) : 1)) {
            $mode ||= O_CREAT | O_APPEND | O_WRONLY;
            $debug_fh=(
                $Package{'debug_fh'}{$debug_fn} ||= (
                    IO::File->new($debug_fn, $mode) || do {
                        warn("unable to open file '$debug_fn', $!");
                        undef;
                    }
                ));
        }
        elsif (!$debug_fn) {
            warn(sprintf('no file name specified in DEBUG hash %s', Dumper($debug_hr)));
        }

    }
    elsif (!ref($debug_fn=${"${caller}::DEBUG"}) && ${"${caller}::DEBUG"}) {

        #  Just file name spec'd. Open
        #
        $debug_fh=(
            $Package{'debug_fh'}{$debug_fn} ||= (
                IO::File->new($debug_fn, O_CREAT | O_APPEND | O_WRONLY) || do {
                    warn("unable to open file '$debug_fn', $!");
                    undef;
                }
            ));
    }


    #  After all that did we get a file handle ? If so, import the debug handler
    #
    if ($debug_fh) {

        #  Yes, setup debug routine
        #
        $debug_fh->autoflush(1);
        $Package{'debug_fh'}=$debug_fh;

        if (0) {  #  Don't do it this way anymore, use a proper debug function and export
            *{"${caller}::debug"}=sub {
                local $|=1;
                my $method=(caller(1))[3] || 'main';
                (my $subroutine=$method)=~s/^.*:://;
                if ($ENV{'WEBDYNE_DEBUG'} && ($ENV{'WEBDYNE_DEBUG'} ne '1')) {
                    my @debug_target=split(/[,;]/, $ENV{'WEBDYNE_DEBUG'});
                    foreach my $debug_target (@debug_target) {
                        if (($caller eq $debug_target) || ($method=~/\Q$debug_target\E$/)) {
                            CORE::print $debug_fh "[$subroutine] ", sprintf(shift(), @_), $/;
                        }
                    }
                }
                else {
                    CORE::print $debug_fh "[$subroutine] ", $_[1] ? sprintf(shift(), @_) : $_[0], $/;
                }
                }
                unless UNIVERSAL::can($caller, 'debug');
            *{"${caller}::Dumper"}=\&Data::Dumper::Dumper
                unless UNIVERSAL::can($caller, 'Dumper');
        }

    }
    else {

        #  No, null our debug and Dumper routine
        #
        #*{"${caller}::debug"}=sub { }
        #    unless UNIVERSAL::can($caller, 'debug');
        #*{"${caller}::Dumper"}=sub { }
        #    unless UNIVERSAL::can($caller, 'Dumper');

    }


    #  Setup file handle for error backtrace
    #
    if (my $fn=${"${caller}::ERROR"}) {

        #  Just file name spec'd. Log
        #
        $Package{'error_fn'}{$fn}++

    }


    #  Done
    #
    goto &Exporter::import;

}


sub debug {


    #  Send debug message to log file. Turn off buffering and get file handle
    #
    my ($debug, @param)=@_;
    local $|=1;
    my $debug_fh=$Package{'debug_fh'} ||
        return undef;


    #  Get caller, iterate until not eval
    #
    my $caller=(caller(0))[0] ||
        return undef;
    my ($eval_fg, $method);
    { my $i=1; while(1) {
        my @caller=caller($i++);
        last unless @caller;
        $method=$caller[3] || 'main';
        if ($method=~/\(eval\)/) {
            $eval_fg++;
            next;
        }
        last;
    }}
    (my $subroutine=$method)=~s/^.*:://;
    (my $class=$method)=~s/::\Q${subroutine}\E$//;
    $subroutine.='(eval)' if $eval_fg;


    #  Time in human readable format
    #
    my ($sec, $msec)=gettimeofday();
    my $timestamp=strftime("%H:%M:%S", localtime($sec)) . sprintf('.%06d', $msec);


    #  Get the debug message
    #
    #local $SIG{__WARN__}=sub { CORE::die("SPRINTF: ". Dumper([$debug, @param])) }; #uncomment if want to trace any missing sprintf params
    #local $SIG{__WARN__}=sub { require Carp; &Carp::confess(@_) };  #uncomment if want to trace any missing sprintf params
    $debug=@param ? sprintf($debug, map { defined($_) ? $_ : 'undef' } @param) : $debug;
    
    
    #  Truncate ?
    #
    if ($WEBDYNE_DEBUG_MAX_LINES && (length($debug) > $WEBDYNE_DEBUG_MAX_LENGTH)) {
        $debug=substr($debug, 0, $WEBDYNE_DEBUG_MAX_LENGTH);
    }
    
    
    #  Wrap lines ?
    #
    $debug =~ s/\n(?!\z)/\n    /g;
    
    
    #  Truncate lines ?
    #
    if ($WEBDYNE_DEBUG_MAX_LINES) {
        my @debug=split(/\n/, $debug, $WEBDYNE_DEBUG_MAX_LINES+1);
        if (@debug > $WEBDYNE_DEBUG_MAX_LINES) {
            splice(@debug, $WEBDYNE_DEBUG_MAX_LINES);
            push @debug, '...';
        }
        $debug=join("\n", @debug);
    }
    chomp($debug);
    
    
    #  Colourise
    #
    if (-t STDOUT && !($WEBDYNE_DEBUG_NO_COLOUR)) {
        eval {
            require Term::ANSIColor;
            $timestamp=Term::ANSIColor::color('cyan') . $timestamp;
            $class=Term::ANSIColor::color('magenta') . $class;
            $subroutine=Term::ANSIColor::color('bold green') . $subroutine;
            $debug=Term::ANSIColor::color('reset') . $debug;
        };
        eval {} if $@;
    }
    
    
    #  Filtering ?
    #
    if ($WEBDYNE_DEBUG && ($WEBDYNE_DEBUG ne '1')) {


        #  Yes - check we are getting from caller we are interested in
        #
        my @debug_target=split(/[,;]/, $WEBDYNE_DEBUG);
        foreach my $debug_target (@debug_target) {
            if (($caller eq $debug_target) || ($method=~/\Q$debug_target\E$/)) {
            
                #  Print debug after checking for any regexp wanted
                #
                if (my $regexp=$WEBDYNE_DEBUG_FILTER) {
                    next unless $debug=~qr/$regexp/m;
                }
                CORE::print $debug_fh "[$timestamp $class ($subroutine)] ", $debug, $/;
            }
        }
    }
    else {

        #  No filtering. Open floodgates but still apply any regexp
        #
        if (my $regexp=$WEBDYNE_DEBUG_FILTER) {
            return unless $debug=~qr/$regexp/;
        }
        CORE::print $debug_fh "[$timestamp $class ($subroutine)] ", $debug, $/;
    }

}


sub errnofatal {


    #
    #
    @_ ? $Package{'nofatal'}=@_ : $Package{'nofatal'};


}


sub err {


    #  Get the message and any sprintf params
    #
    my ($message, @param)=@_;


    #  If no message supplied return last one seen
    #
    unless ($message) {
        $message=@Err ? ($Err[$#Err]->[0] && return undef) : 'undefined error';
    }
    else {
        $message=@param ? sprintf($message, map { defined($_) ? $_ : 'undef' } @param) : $message;
    }


    #  Init the caller var and array
    #
    my @caller;
    my $caller=(caller(0))[0];


    #  Populate the caller array
    #
    for (my $i=0; my @info=(caller($i))[0..3]; $i++) {


        #  Push onto the caller array
        #
        push @caller, \@info;


    }
    debug("err: $message, caller:%s", Dumper(\@caller));



    #  If this message is *not* the same as the last one we saw,
    #  we will log it
    #
    unless ($message eq (@Err && $Err[0]->[0])) {


        #  Add to stack
        #
        unshift @Err, [$message, @caller];


        #  If caller has a debug function enabled, call this with the warning
        #
        if (UNIVERSAL::can($caller, 'debug')) {


            #  Yes, they are using the debug module, so can we call it
            #
            &{"${caller}::debug"}($message);


        }


        #  Dump to backtrace file if enabled
        #
        foreach my $fn (keys %{$Package{'error_fn'}}) {

            unless (my $fh=IO::File->new($fn, O_CREAT | O_APPEND | O_WRONLY)) {
                warn("unable to open file '$fn', $!");
            }
            else {
                seek($fh, 0, 2);    # Seek to EOF
                my $errdump=&errdump();
                CORE::print $fh $errdump, $/, $/;
                $fh->close();
            }

        }


    }


    #  If operating under eval and withing a WebDyne::<inode> block call CORE::die;
    #
    foreach my $caller_ar (@caller) {
        if ($caller_ar->[0]=~/^WebDyne::[a-f0-9]{32}$/) {
            debug("die with WebDyne::<inode> eval detected, calling CORE::die");
            CORE::die($message);
        }
    }
    debug('not under WebDyne eval, proceeding');


    #  Return undef
    #
    return $Package{'nofatal'} ? undef : die(&errdump || 'undefined webdyne error');

}


sub errstr {


    #  Check that there are messages in the stack before trying to get
    #  the last one
    #
    if (my $count=@Err) {


        #  There are objects in the array, so it is safe to do a fetch
        #  on the last (-1) array slot
        #
        my $errstr=$Err[--$count]->[0];


        #  And return the errstr
        #
        return $errstr;

    }
    else {


        #  Nothing in the array stack, return undef
        #
        return undef;


    }

}


sub errclr {


    #  Clear the warning stack
    #
    undef @Err;


    #  Replace errors if args
    #
    @_ && (return &err(@_));


    #  Return OK always
    #
    return 1;

}


sub errsubst {


    #  Replace the current error message with a new one, keeping callback
    #  stack
    #
    my ($message, @param)=@_;

    #  If no message supplied return last one seen
    #
    unless ($message) {
        $message=@Err ? $Err[$#Err]->[0] && return undef : 'undefined error';
    }
    else {
        $message=sprintf($message, @param);
    }

    #  Chomp the message
    #
    chomp($message);


    #  Replace if present, define if not
    #
    @Err ? ($Err[$#Err]->[0]=$message) : goto &err;


    #  Return
    #
    return undef;


}


sub errdump {


    #  Use can send additional info to dump as key/value pairs in hash ref
    #  supplied as arg
    #
    my $info_hr=shift();

    # formline writes to the global format accumulator. Keep errdump output
    # isolated and restore any outer accumulator automatically on return.
    local $^A=q();


    #  Return a dump of error in a nice format, no params. Do this with
    #  format strings, so define the ones we will use
    #
    my @format=(

        #'+' . ('-' x 78) . "+\n",
        #"| @<<<<< | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |\n",
        #"|        | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~ |\n"
        '+' . ('-' x ($WEBDYNE_ERROR_TEXT_CHAR_MAX + 12)) . "+\n",
        sprintf('| @<<<<< | ^%s |'."\n", ('<' x $WEBDYNE_ERROR_TEXT_CHAR_MAX)),
        sprintf('|        | ^%s~~ |'."\n", ('<' x ($WEBDYNE_ERROR_TEXT_CHAR_MAX-2) ))

    );

    #  Go through the message stack on error at a time in reverse order
    #
    foreach my $err_ar (reverse @Err) {


        #  Get message, clean up
        #
        my $message=ucfirst($err_ar->[0]);
        $message=~s/\s+$//;
        $message.='.' unless $message=~/[\.\!\?]$/;
        my @message=split("\n", $message);
        $message=shift @message if @message;


        #  Print out date, time, error message
        #
        formline $format[0];
        formline $format[1], 'Date', scalar(localtime());
        formline $format[0];
        formline $format[1], 'Error', $message;
        (formline $format[2], $message)        if $message;
        map {formline $format[2], $_} @message if @message;
        formline $format[0];


        #  Flag so we know we have printed the caller field
        #
        my $caller_fg;


        #  Go through callback stack
        #
        for (my $i=1; defined($err_ar->[$i]); $i++) {


            #  Get method, line no and file
            #
            my $method=$err_ar->[$i+1][3] || $err_ar->[$i][0] || last;
            my $lineno=$err_ar->[$i][2] || next;
            my $filenm=$err_ar->[$i][1];


            #  Print them out, print out caller label unless we
            #  have already done so
            #
            formline $format[1],
                $caller_fg++ ? '' : 'Caller', "$method, line $lineno";

        }


        #  Include any user supplied info
        #
        #while (my ($key, $value)=each %{$info_hr}) {
        foreach my $key (sort keys %{$info_hr}) {
            my $value=$info_hr->{$key};

            # Older perls can interact badly with overloaded objects during
            # formline formatting, so keep diagnostic fields as plain scalars.
            if (ref($value)) {
                my $string=eval {
                    UNIVERSAL::can($value, 'as_string') ? $value->as_string() : "$value";
                };
                $value=defined($string) ? $string : ref($value);
            }

            #  Print separator, info
            #
            formline $format[0];
            formline $format[1], $key, $value;
            (formline $format[2], $value) if $value;

        }


        #  Finish off formatting, print PID. Dont ask me why $$ has to be "$$",
        #  it does not show up any other way
        #
        formline $format[0];
        formline $format[1], 'PID', "$$";
        formline $format[0];
        formline "\n";
        
        
        #  Only show first error message
        #
        last unless $WEBDYNE_ERROR_TEXT_SHOW_ALL;


    }


    #  Return the localized format accumulator.
    #
    return $^A;

}


sub errstack {

    #  Return or push the raw error stack
    #
    return @_ ? \(@Err=@{$_[1]}) : \@Err;

}


sub perl_inc_dn {

    #  Return array ref of any additional libraries specified via command line (-I)
    #
    my %default_inc=map { $_ => 1 } @{ perl_inc_dn_default() || [] };
    my %seen;
    my @lib=grep {
        !$default_inc{$_} && !$seen{$_}++
    } map {
        File::Spec->rel2abs($_)
    } grep {
        defined($_) && !ref($_) && length($_) && -d $_
    } @INC;

    return \@lib;
}


sub perl_inc_dn_default {

    my @default_inc;
    #local %ENV=%ENV;
    #delete @ENV{qw(PERL5LIB PERLLIB PERL_USE_UNSAFE_INC)};

    if (open(my $perl_fh, '-|', $^X, '-e', 'print join qq(\0), grep { defined && !ref && length && -d } @INC')) {
        local $/;
        my $inc=<$perl_fh>;
        close($perl_fh);
        @default_inc=map {
            File::Spec->rel2abs($_)
        } split(/\0/, ($inc || ''));
    }

    return \@default_inc;
}


sub apache_startup {

    my $opt_hr=shift() || {};

    #  Use an Apache::Test server root under tmp.  By default File::Temp cleans
    #  this at process exit; --keep_tmp flips CLEANUP off for debugging.
    #
    require File::Temp;
    my $svr_root_dn=$opt_hr->{'serverroot'} || File::Temp::tempdir(
        'webdyne_apache_XXXXXXXX',
        TMPDIR  => 1,
        CLEANUP => exists($opt_hr->{'keep_tmp'}) ? !$opt_hr->{'keep_tmp'} : 1,
    );

    #  Some command-line helpers run best with an isolated cache inside the
    #  temporary server root, rather than the system/default WebDyne cache.
    #
    if ($opt_hr->{'cache_dn_env'}) {
        mkdir(my $cache_dn=File::Spec->catdir($svr_root_dn, 'cache'));
        $ENV{'WEBDYNE_CACHE_DN'}=$cache_dn;
    }

    #  Apache::Test may warn about duplicate inherited options; they are noisy
    #  but benign for these one-process throwaway instances.
    #
    local $SIG{__WARN__}=sub {
        return if $_[0] =~ /Duplicate specification/;
        CORE::warn @_;
    };

    #  Avoid Apache::Test attempting to adjust process ulimits in environments
    #  where that is either unnecessary or not permitted.
    #
    $ENV{'APACHE_TEST_ULIMIT_SET'}++;

    #  Apache::Test normally writes startup.pl and index.html helpers. WebDyne
    #  supplies the whole runtime config via the caller's postamble instead.
    #
    no warnings qw(once redefine);
    require Apache::TestConfig;
    *Apache::TestConfig::generate_index_html=sub {};
    *Apache::TestConfig::configure_startup_pl=sub {};

    #  Load Apache::Test lazily so WebDyne::Util can be used without mod_perl
    #  development dependencies unless an Apache helper is actually invoked.
    #
    require Apache::TestRunPerl;
    my $runner=Apache::TestRunPerl->new();
    unless ($runner) {
        my $message='unable to create Apache::TestRunPerl instance';
        die "$message\n" if $opt_hr->{'die_on_error'};
        return err($message);
    }

    #  The postamble is caller-owned because wdrender, webdyne.apache, and the
    #  test harness each need subtly different Apache configuration fragments.
    #
    my @argv=(
        '-port'         => defined($opt_hr->{'port'}) ? $opt_hr->{'port'} : 'select',
        '-serverroot'   => $svr_root_dn,
        '-documentroot' => $opt_hr->{'documentroot'},
        '-postamble'    => $opt_hr->{'postamble'},
        '-one-process',
        '-start-httpd',
    );
    unshift(@argv, '-apxs',  $ENV{'APACHE_TEST_APXS'})
        if $ENV{'APACHE_TEST_APXS'};
    unshift(@argv, '-httpd', $ENV{'APACHE_TEST_HTTPD'})
        if $ENV{'APACHE_TEST_HTTPD'};

    $runner->run(@argv);
    return $runner;
}


sub apache_shutdown {

    my $runner=shift();
    return unless $runner && $runner->{'server'};
    $runner->{'server'}->stop();
    return;
}

1;__END__

=begin markdown

# WebDyne::Util #

# NAME #

WebDyne::Util - debugging and error-stack utility functions for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Util;

debug('message: %s', $value);
err('something failed');
my $msg = errstr();
```

# DESCRIPTION #

`WebDyne::Util` provides the common debugging, error-stack, and error-formatting functions used throughout the WebDyne codebase.

It exports the standard utility functions by default and uses environment variables such as `WEBDYNE_DEBUG`, `WEBDYNE_DEBUG_FILE`, `WEBDYNE_DEBUG_FILTER`, and related settings to control runtime debug output.

`perl_inc_dn` is exported by default and can also be requested explicitly. `apache_startup` and `apache_shutdown` are available on request, or through the `:all` export tag.

# FUNCTIONS #

* **debug($message, @args)**

    Emit a formatted debug message if debugging is enabled for the calling package or environment.

* **err($message, @args)**

    Push an error message onto the WebDyne error stack.

* **errstr()**

    Return the current error string.

* **errclr()**

    Clear the current error state.

* **errsubst(...)**

    Apply error-text substitutions and formatting helpers.

* **errdump(...)**

    Produce a formatted dump of the current error stack and related diagnostics.

* **errstack()**

    Return the current error stack.

* **errnofatal($bool)**

    Control whether errors are treated as fatal by the utility layer.

* **perl_inc_dn()**

    Return non-default library directories from `@INC`.

* **apache_startup(\%options)**

    Start an Apache::Test runner instance with a caller-supplied postamble.

* **apache_shutdown($runner)**

    Stop an Apache::Test runner instance if it is active.

# NOTES #

This module is foundational to the rest of WebDyne. Most other modules import it for debug and error handling.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 WebDyne::Util


=head1 NAME

WebDyne::Util - debugging and error-stack utility functions for WebDyne


=head1 SYNOPSIS


 use WebDyne::Util;
 
 debug('message: %s', $value);
 err('something failed');
 my $msg = errstr();

=head1 DESCRIPTION

C<WebDyne::Util> provides the common debugging, error-stack, and error-formatting functions used throughout the WebDyne codebase.

It exports the standard utility functions by default and uses environment variables such as C<WEBDYNE_DEBUG>, C<WEBDYNE_DEBUG_FILE>, C<WEBDYNE_DEBUG_FILTER>, and related settings to control runtime debug output.

C<perl_inc_dn> is exported by default and can also be requested explicitly. C<apache_startup> and C<apache_shutdown> are available on request, or through the C<:all> export tag.


=head1 FUNCTIONS

=over

=item *

B<debug($message, @args)>

Emit a formatted debug message if debugging is enabled for the calling package or environment.



=item *

B<err($message, @args)>

Push an error message onto the WebDyne error stack.



=item *

B<errstr()>

Return the current error string.



=item *

B<errclr()>

Clear the current error state.



=item *

B<errsubst(...)>

Apply error-text substitutions and formatting helpers.



=item *

B<errdump(...)>

Produce a formatted dump of the current error stack and related diagnostics.



=item *

B<errstack()>

Return the current error stack.



=item *

B<errnofatal($bool)>

Control whether errors are treated as fatal by the utility layer.



=item *

B<perl_inc_dn()>

Return non-default library directories from C<@INC>.



=item *

B<apache_startup(\%options)>

Start an Apache::Test runner instance with a caller-supplied postamble.



=item *

B<apache_shutdown($runner)>

Stop an Apache::Test runner instance if it is active.



=back


=head1 NOTES

This module is foundational to the rest of WebDyne. Most other modules import it for debug and error handling.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
