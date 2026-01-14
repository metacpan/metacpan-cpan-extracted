#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
use vars   qw($VERSION @EXPORT);
use warnings;
no warnings qw(uninitialized redefine once);


#  External modules
#
use Data::Dumper;
use IO::File;
use POSIX qw(strftime);


#  Use Exporter
#
require Exporter;


#  Exports
#
@EXPORT=qw(err errstr errclr errdump errsubst errstack errnofatal debug);


#  Version information
#
$VERSION='2.069';


#  Var to hold package wide hash, for data shared across package, and error stack
#
my (%Package, @Err);


#  Bring the WEBDYNE_DEBUG env var into package var so available via Plack handler,
#  which normally replaces env with its own
#
$Package{'WEBDYNE_DEBUG'}=$ENV{'WEBDYNE_DEBUG'};


#  All done. Positive return
#
1;


#==================================================================================================

#  Packace init, attempt to load optional Time::HiRes module
#
BEGIN {
    eval {require Time::HiRes; Time::HiRes->import(qw(time gettimeofday))};
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
    if ($debug_fn=$ENV{'WEBDYNE_DEBUG_FILE'}) {

        #  fn is whatever spec'd
        #
        $debug_fh=IO::File->new($debug_fn, O_CREAT | O_APPEND | O_WRONLY) || do {
            warn("unable to open file '$debug_fn', $!");
            undef;
        };

    }
    elsif ($ENV{'WEBDYNE_DEBUG'}) {


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
    local $|=1;
    my $debug_fh=$Package{'debug_fh'} ||
        return undef;


    #  Get caller
    #
    #  Get who is calling us
    #
    my $caller=(caller(0))[0] ||
        return undef;
    my $method=(caller(1))[3] || 'main';
    (my $subroutine=$method)=~s/^.*:://;
    (my $class=$method)=~s/::\Q${subroutine}\E$//;


    #  Time in human readable format
    #
    my ($sec, $msec)=gettimeofday();
    my $timestamp=strftime("%H:%M:%S", localtime($sec)) . sprintf('.%06d', $msec);


    #  Get the debug message
    #
    #local $SIG{__WARN__}=sub { die @_ };  #uncomment if want to trace any missing sprintf params
    my $debug=$#_ ? sprintf(shift(), @_) : shift();


    #  Filtering ?
    #
    if ($Package{'WEBDYNE_DEBUG'} && ($Package{'WEBDYNE_DEBUG'} ne '1')) {


        #  Yes - check we are getting from caller we are interested in
        #
        my @debug_target=split(/[,;]/, $Package{'WEBDYNE_DEBUG'});
        foreach my $debug_target (@debug_target) {
            if (($caller eq $debug_target) || ($method=~/\Q$debug_target\E$/)) {
            
                #  Print debug after checking for any regexp wanted
                #
                if (my $regexp=$ENV{'WEBDYNE_DEBUG_FILTER'}) {
                    next unless $debug=~qr/$regexp/m;
                }
                CORE::print $debug_fh "[$timestamp $class ($subroutine)] ", $debug, $/;
            }
        }
    }
    else {

        #  No filtering. Open floodgates but still apply any regexp
        #
        if (my $regexp=$ENV{'WEBDYNE_DEBUG_FILTER'}) {
            next unless $debug=~qr/$regexp/;
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
        $message=@Err ? $Err[$#Err]->[0] && return undef : 'undefined error';
    }
    else {
        $message=sprintf($message, @param) if @param;
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


    #  Return undef
    #
    return $Package{'nofatal'} ? undef : die(&errdump);

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


    #  Return a dump of error in a nice format, no params. Do this with
    #  format strings, so define the ones we will use
    #
    my @format=(

        '+' . ('-' x 78) . "+\n",
        "| @<<<<< | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |\n",
        "|        | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~ |\n"

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
        while (my ($key, $value)=each %{$info_hr}) {


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


    }


    #  Empty the format accumulator and return it
    #
    my $return=$^A; undef $^A;
    return $return;

}


sub errstack {

    #  Return or push the raw error stack
    #
    return @_ ? \(@Err=@{$_[1]}) : \@Err;

}

