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

package WebDyne::Request::Fake;


#  Compiler Pragma
#
use strict qw(vars);
use vars qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Cwd qw(cwd);
use Data::Dumper;
use HTTP::Status (RC_OK);


#  Version information
#
$VERSION='1.246';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  All done. Positive return
#
1;


#==================================================================================================


sub dir_config {

    my ($r, $key)=@_;
    return $ENV{$key};

}


sub filename {

    my $r=shift();
    File::Spec->rel2abs($r->{'filename'}, cwd());

}


sub headers_out {

    my ($r, $k, $v)=@_;
    if (@_ == 3) {
        return $r->{'headers_out'}{$k}=$v
    }
    elsif (@_ == 2) {
        return $r->{'headers_out'}{$k}
    }
    elsif (@_ == 1) {
        return ($r->{'headers_out'} ||= {});
    }
    else {
        return err ('incorrect usage of %s headers_out object, r->headers_out(%s)', +__PACKAGE__, join(',', @_[1..$#_]));
    }

}


sub headers_in {

    my $r=shift();
    $r->{'headers_in'} ||= {};

}


sub is_main {

    my $r=shift();
    $r->{'main'} ? 0 : 1;

}


sub log_error {

    my $r=shift();
    warn(@_) unless $r->notes('nowarn');

}


sub lookup_file {

    my ($r, $fn)=@_;
    my $r_child=ref($r)->new(filename => $fn) || return err ();

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
        return err ('incorrect usage of %s notes object, r->notes(%s)', +__PACKAGE__, join(',', @_[1..$#_]));
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

    my $r=shift();
    push @{$r->{'register_cleanup'} ||= []}, @_;

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


sub debug {

    #  Stub
}


sub output_filters {

    #  Stub
}


sub location {

    #  Stub
}


sub header_only {

    #  Stub
}


sub set_handlers {

    #  Stub
}


sub noheader {

    my $r=shift();
    @_ ? $r->{'noheader'}=shift() : $r->{'noheader'};

}


sub send_http_header {

    my $r=shift();
    return if $r->{'noheader'};
    my $fh=$r->{'select'} || \*STDOUT;
    CORE::printf $fh ("Status: %s\n", $r->status());
    while (my ($header, $value)=each(%{$r->{'headers_out'}})) {
        CORE::print $fh ("$header: $value\n");
    }
    CORE::print $fh "\n";

}


sub content_type {

    my ($r, $content_type)=@_;
    $r->{'header'}{'Content-Type'}=$content_type;

    #CORE::print("Content-Type: $content_type\n");

}


sub custom_response {

    my ($r, $status)=(shift, shift);
    $r->status($status);
    $r->send_http_header();
    $r->print(@_);

}


sub AUTOLOAD {

    my ($r, $v)=@_;
    my $k=($AUTOLOAD=~/([^:]+)$/) && $1;
    warn(sprintf("Unhandled '%s' method, using AUTOLOAD", $k));
    $v ? $r->{$k}=$v : $r->{$k};


}


sub DESTROY {

    my $r=shift();
    if (my $cr_ar=delete $r->{'register_cleanup'}) {
        foreach my $cr (@{$cr_ar}) {
            $cr->($r);
        }
    }
}
