#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


package WebDyne::Request::Fake;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Cwd qw(cwd);
use Data::Dumper;
use HTTP::Status (RC_OK);
use WebDyne::Util;


#  Var to hold package wide hash, for data shared across package
#
my %Package;


#  Version information
#
$VERSION='2.016';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Run init code for utility accessors unless already done
#
&_init unless defined(&method);


#  All done. Positive return
#
1;


#==================================================================================================

sub _init {

    #  Load quick and dirty mod_perl equivalent handler accessors that get info from
    #  environment vars if they exist
    #
    my %handler=(
        method          => 'REQUEST_METHOD',
        protocol        => 'SERVER_PROTOCOL',
        args            => 'QUERY_STRING',
        path_info       => 'PATH_INFO',
        content_length  => 'CONTENT_LENGTH',
        hostname        => 'SERVER_NAME',
        get_server_name => 'SERVER_NAME',
        get_server_port => 'SERVER_PORT',
        get_remote_host => 'REMOTE_ADDR',
        user            => 'REMOTE_USER',
        ap_auth_type    => 'AUTH_TYPE',
        unparsed_uri    => 'REQUEST_URI',
    );
    while (my ($k, $v)=each %handler) {
        *{$k}=sub { return $ENV{$v} } unless defined &{$k}
    }

}


sub dir_config {

    my ($r, $key)=@_;
    return $ENV{$key};

}


sub filename {

    my $r=shift();

    #  Store cwd as takes a fair bit of processing time.
    File::Spec->rel2abs($r->{'filename'}, ($Package{'_cwd'} ||= cwd()));

}


sub headers {

    #  Set/get header. r=request, d=direction(in/out), k=key, v=value
    #
    my ($r, $d, $k, $v)=@_;
    
    if (@_ == 4) {
        return $r->{$d}{$k}=$v
    }
    elsif (@_ == 3) {
        return $r->{$d}{$k}
    }
    elsif (@_ == 2) {
        return ($r->{$d} ||= {});
    }
    else {
        return err("incorrect usage of %s $d object, r->$d(%s)", ref($r), join(',', @_[1..$#_]));
    }

}


sub headers_out {

    my $r=shift();
    return $r->headers('headers_out', @_);
    
}


sub headers_in {

    my $r=shift();
    return $r->headers('headers_in', @_);
    
}


sub is_main {

    my $r=shift();
    $r->{'main'} ? 0 : 1;

}


sub log_error {

    my $r=shift();
    warn(@_) unless !$r->{'warn'};

}


sub lookup_file {

    my ($r, $fn)=@_;
    my $r_child=ref($r)->new(filename => $fn) || return err();

}


sub lookup_uri {

    my ($r, $uri)=@_;
    my $fn=File::Spec::Unix->catfile((File::Spec->splitpath($r->filename()))[1], $uri);
    return $r->lookup_file($fn);

}


sub main {

    my $r=shift();
    @_ ? $r->{'main'}=shift() : $r->{'main'} || $r;

}


sub new {

    my ($class, %r)=@_;
    debug("$class, r:%s", Dumper(\%r));
    return bless \%r, $class;

}


sub notes {

    my ($r, $k, $v)=@_;
    if (@_ == 3) {
        return $r->{'_notes'}{$k}=$v
    }
    elsif (@_ == 2) {
        return $r->{'_notes'}{$k}
    }
    elsif (@_ == 1) {
        return ($r->{'_notes'} ||= {});
    }
    else {
        return err('incorrect usage of %s notes object, r->notes(%s)', +__PACKAGE__, join(',', @_[1..$#_]));
    }

}


sub parsed_uri {

    my $r=shift();
    require URI;
    URI->new($r->uri());

}


sub prev {

    my $r=shift();
    @_ ? $r->{'prev'}=shift() : $r->{'prev'};

}


sub print {

    my $r=shift();
    my $fh=$r->{'select'} || \*STDOUT;
    CORE::print $fh ((ref($_[0]) eq 'SCALAR') ? ${$_[0]} : @_);

}


sub register_cleanup {

    #my $r=shift();
    my ($r, $cr)=@_;
    push @{$r->{'register_cleanup'} ||= []}, $cr;

    #my $ar=$r->{'register_cleanup'} ||= [];
    #push @

}


sub cleanup_register {

    &register_cleanup(@_);

}


sub pool {

    #  Used by mod_perl2, usually for cleanup_register in the form of $r->pool->cleanup_register(), so just
    #  return $r and let the code then call cleanup_register
    #
    my $r=shift();

}


sub run {

    my ($r, $self)=@_;
    (ref($self) || $self)->handler($r);

}


sub status {

    my $r=shift();
    @_ ? $r->{'status'}=shift() : $r->{'status'} || RC_OK;

}


sub uri {

    shift()->{'filename'}

}


sub document_root {

    my $r=shift();
    @_ ? $r->{'document_root'}=shift() : $r->{'document_root'} || $ENV{'DOCUMENT_ROOT'}
    
}


sub output_filters {

    #  Stub
}


sub location {

    #  Stub
    shift()->{'location'}

}


sub header_only {

    #  Stub
}


sub set_handlers {

    #  Stub
}


sub noheader {

    my $r=shift();
    @_ ? $r->{'header'}=shift() : $r->{'header'};

}


sub send_http_header {

    my $r=shift();
    return unless $r->{'header'};
    my $fh=$r->{'select'} || \*STDOUT;
    CORE::printf $fh ("Status: %s\n", $r->status());
    while (my ($header, $value)=each(%{$r->{'headers_out'}})) {
        CORE::print $fh ("$header: $value\n");
    }
    CORE::print $fh "\n";

}


sub content_type {

    my ($r, $content_type)=@_;
    return ($content_type ? $r->{'headers_out'}{'Content-Type'}=$content_type : $ENV{'CONTENT_TYPE'});
    #CORE::print("Content-Type: $content_type\n");

}


sub handler {

    # Replicate mod_perl handler function
    #
    my ($r, $handler)=@_;
    return ($handler ? $r->{'handler'}=$handler : $r->{'handler'} ||= 'default-handler');

}


sub custom_response {

    my ($r, $status)=(shift, shift);
    $r->status($status);
    $r->send_http_header();
    $r->print(@_);

}


sub args {

    return $ENV{'QUERY_STRING'};
    
}


sub AUTOLOAD {

    my ($r, $v)=@_;
    debug("$r AUTOLOAD: $AUTOLOAD, v: $v");
    my $k=($AUTOLOAD=~/([^:]+)$/) && $1;
    warn(sprintf("Unhandled '%s' method, using AUTOLOAD", $k));
    $v ? $r->{$k}=$v : $r->{$k};


}


sub DESTROY {

    my $r=shift();
    debug("$r DESTROY");
    if (my $cr_ar=delete $r->{'register_cleanup'}) {
        foreach my $cr (@{$cr_ar}) {
            $cr->($r);
        }
    }

}
