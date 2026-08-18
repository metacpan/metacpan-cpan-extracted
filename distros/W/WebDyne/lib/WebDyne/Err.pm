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
package WebDyne::Err;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  Webmod Modules.
#
use WebDyne::Constant;
use WebDyne::Err::Constant;
use WebDyne::Util;


#  External modules
#
use HTTP::Status qw(:constants is_error);
use File::Spec;
use Data::Dumper;
$Data::Dumper::Indent=1;


#  Version information
#
$VERSION='3.018';


#  Debug
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  Package wide vars
#
my %Package;


#  Fix issues if mod_perl loads legacy Carp with modern Carp::Heavy
#
{   my $cr=sub {return \@_};
    foreach my $method (qw(shortmess_real longmess_real shortmess_heavy longmess_heavy)) {
        *{"Carp::${method}"}=sub {return @_}
            unless Carp->can($method);
    }
}


#  And done
#
1;


#------------------------------------------------------------------------------


sub err_html {


    #  Output errors to browser.
    #
    my ($self, $errstr)=@_;
    $errstr=sprintf($errstr, @_[2..$#_]);


    #  Debug
    #
    debug("in error routine self: $self, errstr: $errstr, caller: %s", Dumper( [ (caller(0))[0..3] ]));


    #  Get errstr from stack if not supplied, or add if it
    #  has been
    #
    if ($errstr) {err($errstr)}
    else {
        $errstr=errstr() || do {err($_='undefined error from handler'); $_}
    }

    #$errstr ? err($errstr) : ($errstr=errstr() || do {err($_='undefined error from handler'); $_});
    debug("final errstr: $errstr");


    #  Try to get request handler;
    #
    my $r;
    if ($r=eval {$self->{'_r'}}) {

        #  Get main request handler in case we are in subrequest
        #
        $r=$r->main() || $r;

    }
    debug("r $r");


    #  Print errstr and exit immediately if  no request object yet, or in error loop - something
    #  is seriously wrong;
    #
    if (!$r) {
        print(errdump());
        CORE::exit 0;
    }


    #  Try to get CGI object from class, or create if not present - may
    #  not have been initialised before error occured);
    #
    my $cgi_or=$self->{'_CGI'} || CGI::Simple->new($r);
    debug("cgi_or $cgi_or");


    #  Log the error
    #
    $r->log_error($errstr);


    #  Status must be internal error if not set to something else already
    #
    debug('existing status: %s', $r->status());
    unless ($r->status() && (is_error($r->status()))) {
        debug('setting status to: %s', HTTP_INTERNAL_SERVER_ERROR);
        $r->status(HTTP_INTERNAL_SERVER_ERROR);
    }


    #  Do not run any more handlers
    #
    $r->set_handlers(PerlHandler => undef);


    #  Optionally kill this Apache process afterwards to make sure it does
    #  not behave badly after this error, if that is what the user has
    #  configured
    #
    if ($WEBDYNE_ERROR_EXIT) {
        my $cr=sub {CORE::exit()};
        $MP2 ? $r->pool->cleanup_register($cr) : $r->register_cleanup($cr);
    }


    #  Error can be text or HTML, must be text if in Safe eval mode
    #
    debug("WEBDYNE_ERROR_TEXT: $WEBDYNE_ERROR_TEXT");
    #if ($WEBDYNE_ERROR_TEXT || $WEBDYNE_EVAL_SAFE || $self->{'_error_handler_run'}++ || !$cgi_or || UNIVERSAL::can($self, 'debug')) {
    if ($WEBDYNE_ERROR_TEXT || $WEBDYNE_EVAL_SAFE || $self->{'_error_handler_run'}++ || !$cgi_or) {


        #  Text error, set content type
        #
        debug(
            "using text error; WEBDYNE_ERROR_TEXT: %s, WEBDYNE_EVAL_SAFE: %s, _error_handler_run: %s, cgi_or: %s, updating $r content_type",
            $WEBDYNE_ERROR_TEXT, $WEBDYNE_EVAL_SAFE, $self->{'_error_handler_run'}, $cgi_or
        );
        #$r->content_type('text/plain');
        debug('existing content type: %s', $r->content_type);
        $r->content_type($WEBDYNE_CONTENT_TYPE_TEXT);
        debug('updated content type: %s', $r->content_type);
        

        #  Push error
        #
        my $err_text=errdump(
            {

                'URI'  => $r->uri(),
                #'Line' => scalar $self->data_ar_html_line_no(pop @{$self->{'_data_ar_err'}}),
                'Line' => scalar $self->data_ar_html_line_no(),

            });


        #  Clear error stack and $@.
        #
        errclr(); eval {undef} if $@;


        #  Print error and return
        #
        $r->send_http_header() if !$MP2;
        if (1) {
            my $status=$r->status();
            unless($status && is_error($status)) {
                $r->status($status=HTTP_INTERNAL_SERVER_ERROR);
            };
            $r->custom_response($status, $err_text);
            $r->print($err_text);
            return $status;
        }
        else {
            $r->custom_response(HTTP_INTERNAL_SERVER_ERROR, $err_text);
            $r->status(HTTP_INTERNAL_SERVER_ERROR);
            $r->print($err_text);
            return HTTP_INTERNAL_SERVER_ERROR;
        }

    }
    else {


        #  Get error parameters, must make copy of stack, data block - they will be erased.
        #
        debug('using html error');
        my @errstack=@{&errstack()};
        my %param=(

            errstr           => $errstr,
            errstack_ar      => \@errstack,
            err_eval_perl_sr => $self->{'_err_eval_perl_sr'},
            err_eval_line    => $self->{'_err_eval_line'},
            data_ar_err      => $self->{'_data_ar_err'},

        );


        #  Clear error stack and $@ so this render works without errors
        #
        errclr(); eval {undef} if $@;


        #  Wrap everything in eval block in case this error was thrown interally by
        #  WebDyne not being able to load/start etc, in which case trying to run it
        #  again won't be helpful
        #
        my $status;
        eval {


            #  Only compile container once if we can help it
            #
            local $SIG{__DIE__};
            require WebDyne::Compile;
            my $container_ar=(

                #  Don't cache it - only minor penalty to recompile and WEBDYNE_RELOAD=1 breaks error handler
                #  if multiple errors.
                #$Package{'container_ar'} ||= &WebDyne::Compile::compile(
                $self->WebDyne::Compile::compile({

                        srce     => $WEBDYNE_ERR_TEMPLATE,
                        no_filter => 1

                    })) || return $self->err_html('fatal problem in error handler during compile !');


            #  Get the data portion of the container (meta info not needed) and render. Bit of cheating
            #  to use internal
            #
            my $data_ar=$container_ar->[$WEBDYNE_CONTAINER_DATA_IX];
            debug("err_html data_ar: %s", Dumper($param{'data_ar'}));


            #  Reset render state and render error page
            #
            $self->render_reset($data_ar);
            #my $html_sr=$self->render({
##
#                    data  => $data_ar,
#                    param => \%param
#
#            }) || return $self->err_html('fatal problem in error handler during render: %s !', errstr() || 'undefined error');
            my $html_sr=$self->render_data_ar(

                    data  => $data_ar,
                    param => \%param

            ) || return $self->err_html('fatal problem in error handler during render: %s !', errstr() || 'undefined error');


            #  Set custom handler
            #
            $status=$r->status();
            debug("send custom response for status $status on r $r");
            $r->custom_response($status, ${$html_sr});


            #  Clear error stack again, make sure all is clean before we return.
            #
            errclr(); eval {} if $@;

        };


        #  Check if render went OK, if not revert to text - better than
        #  showing nothing ..
        #
        if ($@ || !$status) {
            debug("unable to render HTML template, reverting to text");
            err($@) if $@;
            err('previous error stack %s', Data::Dumper::Dumper(\@errstack));
            my $webdyne_error_text_save=$WEBDYNE_ERROR_TEXT;
            $WEBDYNE_ERROR_TEXT=1;
            $status=$self->err_html($errstr);
            $WEBDYNE_ERROR_TEXT=$webdyne_error_text_save;

        }

        #  Return result
        #
        debug("return status: $status");
        return $status

    }

}


sub err_eval {

    #  Special handler for eval errors
    #
    my ($self, $message, $perl_sr, $inode)=@_;
    debug("err_eval: %s, perl_sr:  %s, caller %s", $message, Dumper($perl_sr), Dumper([caller()]));


    #  Try to scrape line from message
    #
    my ($err_eval_line)=($message=~/WebDyne::${inode}\s+line\s+(\d+)/);
    unless ($err_eval_line) {

        #  Only if Devel::Confess installed will this parse work
        #
        #  Illegal division by zero at (eval 211)[WebDyne::6d8da02b63e4707b80466fda560173a6:5] line 1.
        #
        ($err_eval_line)=($message=~/\[WebDyne::${inode}:(\d+)\]/);
    }
    debug("err_eval eval_line:$err_eval_line");


    #  Store away for future ref by error handler
    #
    $self->{'_err_eval_perl_sr'}=$perl_sr;
    $self->{'_err_eval_line'}=$err_eval_line;


    #  Send message off to main error handler and return
    #
    #return &errsubst($message);
    return err($message);

}

__END__

=begin markdown

# WebDyne::Err #

# NAME #

WebDyne::Err - error rendering and eval-error support for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Err;

my $status = $self->err_html('something went wrong');
```

# DESCRIPTION #

`WebDyne::Err` provides the runtime error handlers used by the WebDyne framework. It can render errors either as plain text or through the bundled WebDyne HTML error template, log them against the active request object, and translate eval failures into user-facing error output.

# METHODS #

* **err_html($self, $message, @args)**

    Main error-rendering routine. Logs the error, ensures an error HTTP status is set, and emits either text or HTML error output depending on configuration and runtime conditions.

* **err_eval(...)**

    Helper used for formatting and presenting eval-related failures.

# NOTES #

Behavior is influenced by constants in `WebDyne::Constant` and `WebDyne::Err::Constant`, especially:

* `WEBDYNE_ERROR_TEXT`
* `WEBDYNE_ERROR_EXIT`
* `WEBDYNE_ERR_TEMPLATE`
* the various `WEBDYNE_ERROR_*` display controls

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


=head1 WebDyne::Err


=head1 NAME

WebDyne::Err - error rendering and eval-error support for WebDyne


=head1 SYNOPSIS


 use WebDyne::Err;
 
 my $status = $self->err_html('something went wrong');

=head1 DESCRIPTION

C<WebDyne::Err> provides the runtime error handlers used by the WebDyne framework. It can render errors either as plain text or through the bundled WebDyne HTML error template, log them against the active request object, and translate eval failures into user-facing error output.


=head1 METHODS

=over

=item *

B<err_html($self, $message, @args)>

Main error-rendering routine. Logs the error, ensures an error HTTP status is set, and emits either text or HTML error output depending on configuration and runtime conditions.



=item *

B<err_eval(...)>

Helper used for formatting and presenting eval-related failures.



=back


=head1 NOTES

Behavior is influenced by constants in C<WebDyne::Constant> and C<WebDyne::Err::Constant>, especially:

=over

=item *

C<WEBDYNE_ERROR_TEXT>


=item *

C<WEBDYNE_ERROR_EXIT>


=item *

C<WEBDYNE_ERR_TEMPLATE>


=item *

the various C<WEBDYNE_ERROR_*> display controls


=back


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
