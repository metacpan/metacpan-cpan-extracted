#
#  This file is part of WebDyne.
#
#  This software is Copyright (c) 2016 by Andrew Speer <andrew@webdyne.org>.
#
#  This is free software, licensed under:
#
#    The GNU General Public License, Version 2, June 1991
#
#  Full license text is available at:
#
#  <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>
#
package WebDyne::Err;


#  Compiler Pragma
#
use strict qw(vars);
use vars qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  Webmod Modules.
#
use WebDyne::Constant;
use WebDyne::Err::Constant;
use WebDyne::Base;


#  External modules
#
use HTTP::Status qw(is_success is_error RC_INTERNAL_SERVER_ERROR);
use File::Spec;


#  Version information
#
$VERSION='1.246';


#  Debug
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  Package wide vars
#
my %Package;
*debug=\&WebDyne::debug;


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
    debug("in error routine self $self, errstr $errstr, caller %s", join(',', (caller(0))[0..3]));


    #  Get errstr from stack if not supplied, or add if it
    #  has been
    #
    if ($errstr) {err ($errstr)}
    else {
        $errstr=errstr() || do {err ($_='undefined error from handler'); $_}
    }

    #$errstr ? err($errstr) : ($errstr=errstr() || do {err($_='undefined error from handler'); $_});
    debug("final errstr $errstr");


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
    my $cgi_or=$self->{'_CGI'} || CGI->new();
    debug("cgi_or $cgi_or");


    #  Log the error
    #
    $r->log_error($errstr);


    #  Status must be internal error
    #
    $r->status(RC_INTERNAL_SERVER_ERROR);


    #  Do not run any more handlers
    #
    $r->set_handlers(PerlHandler => undef);


    #  Optionally kill this Apache process afterwards to make sure it does not behave
    #  badly after this error, if that is what the user has configured
    #
    if ($WEBDYNE_ERROR_EXIT) {
        my $cr=sub {CORE::exit()};
        $MP2 ? $r->pool->cleanup_register($cr) : $r->register_cleanup($cr);
    }


    #  Error can be text or HTML, must be text if in Safe eval mode
    #
    if ($WEBDYNE_ERROR_TEXT || $WEBDYNE_EVAL_SAFE || $self->{'_error_handler_run'}++ || !$cgi_or) {


        #  Text error, set content type
        #
        debug(
            "using text error (%s:%s:%s:%s) - update $r content_type",
            $WEBDYNE_ERROR_TEXT, $WEBDYNE_EVAL_SAFE, $self->{'_error_handler_run'}, $cgi_or
        );
        $r->content_type('text/plain');


        #  Push error
        #
        my $err_text=errdump(
            {

                'URI'  => $r->uri(),
                'Line' => scalar $self->data_ar_html_line_no(),

            });


        #  Clear error stack and $@.
        #
        errclr(); eval {undef} if $@;


        #  Print error and return
        #
        $r->send_http_header() if !$MP2;
        $r->print($err_text);
        return &Apache::OK;


    }
    else {


        #  Get error parameters, must make copy of stack, data block - they will be erased.
        #
        debug('using html error');
        my @errstack=@{&errstack()};
        my %param=(

            errstr      => $errstr,
            errstack_ar => \@errstack,
            errperl_sr  => $self->{'_err_perl_sr'},
            data_ar     => $self->{'_data_ar'},
            r           => $r

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
                $Package{'container_ar'} ||= &WebDyne::Compile::compile(
                    $self,
                    {

                        srce     => $WEBDYNE_ERR_TEMPLATE,
                        nofilter => 1

                    })) || return $self->err_html('fatal problem in error handler during compile !');


            #  Get the data portion of the container (meta info not needed) and render. Bit of cheating
            #  to use internal
            #
            my $data_ar=$container_ar->[$WEBDYNE_CONTAINER_DATA_IX];


            #  Reset render state and render error page
            #
            $self->render_reset($data_ar);
            my $html_sr=$self->render(
                {

                    data  => $data_ar,
                    param => \%param

                }) || return $self->err_html('fatal problem in error handler during render: %s !', errstr() || 'undefined error');


            #  Set custom handler
            #
            $status=$r->status();
            debug("send custom response for status $status on r $r");
            $r->custom_response($status, ${$html_sr});


            #  Clear error stack again, make sure all is clean before we return.
            #
            errclr(); eval {undef} if $@;

        };


        #  Check if render went OK, if not revert to text - better than
        #  showing nothing ..
        #
        if ($@ || !$status) {
            debug("unable to render HTML template, reverting to text");
                err ($@) if $@;
                err ('previous error stack %s', Data::Dumper::Dumper(\@errstack));
            my $webdyne_error_text_save=$WEBDYNE_ERROR_TEXT;
            $WEBDYNE_ERROR_TEXT=1;
            $status=$self->err_html($errstr);
            $WEBDYNE_ERROR_TEXT=$webdyne_error_text_save;

        }

        #  Return result
        #
        return $status

    }

}


sub err_eval {

    #  Special handler for eval errors
    #
    my ($self, $message, $perl_sr)=@_;
    debug("err_eval $message, %s, caller %s", Dumper($perl_sr), Dumper([caller()]));


    #  Store away for future ref by error handler
    #
    $self->{'_err_perl_sr'}=$perl_sr;


    #  Send message off to main error handler and return
    #
    return &errsubst($message);

}

