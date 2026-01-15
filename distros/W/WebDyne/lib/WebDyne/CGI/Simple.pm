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
package WebDyne::CGI::Simple;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION $AUTOLOAD @ISA);
use warnings;
no warnings qw(uninitialized);


#  WebDyne Modules
#
use WebDyne::Constant;
use WebDyne::Util;


#  External modules
#
use Data::Dumper;
use Hash::MultiValue;
use CGI::Simple;
@ISA=qw(CGI::Simple);


#  Version information
#
$VERSION='2.070';


#  CGI upload vars
#
$CGI::Simple::DISABLE_UPLOADS=$WEBDYNE_CGI_DISABLE_UPLOADS;
$CGI::Simple::POST_MAX=$WEBDYNE_CGI_POST_MAX;


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#==============================================================================

sub new {


    #  New instance of CGI::Common
    #
    my ($class, $r, %param)=@_;
    debug("class: $class, r: $r, param: %s", Dumper(\%param));
    my $cgi_or=CGI::Simple->new($r) ||
        return err('unable to get CGI::Simple objedt');
    my $self=bless($cgi_or, __PACKAGE__);
    map { $self->param($_, $param{$_}) } keys %param;
    return $self;
    
}


sub Vars {

    #  Simulate Plack::Request Hash::MultiValue response
    #
    my ($self, $hr)=@_;
    if ($hr) {
        
        #  Pushing back into CGI
        #
        $self->delete_all();
        foreach my $param (keys %{$hr}) {
            $self->param($param, $hr->get_all($param));
        }
        return $hr;
        
    }
    else {
        my @pairs;
        foreach my $param ($self->param()) {
            my @values=$self->param($param);
            map { push @pairs, ( $param => $_ ) } @values;
        }
        return Hash::MultiValue->new(@pairs)
    }

}


sub env {

    return \%ENV
    
}


sub uploads {

    #  Replicate Plack::Request::Uploads->uploads()
    #
    my $self=shift();
    my @pairs;
    foreach my $param ($self->param()) {
        
        my @fn = $self->upload_info();
        next unless @fn;

        foreach my $fn (@fn) {
            next unless $fn;  # skip undef
            my $fh = $self->upload($fn);
            my $size     = -s $fh;
            my $upload_or = WebDyne::CGI::Simple::Upload->new(
                filename => $fn,
                size     => $size,
                mime	 => $self->upload_info($fn, 'mime'),
                fh       => $fh,
                tempfile => $fh,
            );
            push @pairs, ($param => $upload_or);
        }
    }

    return Hash::MultiValue->new(@pairs);
}


#  Emulate Plack::Request::Upload object
#
package WebDyne::CGI::Simple::Upload;
use strict;
use File::Basename qw();

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}
sub filename { $_[0]->{'filename'} }
sub size     { $_[0]->{'size'} }
sub content  {
    my $self = shift;
    seek ($self->{'fh'}, 0, 0);
    local $/;
    my $fh=$self->{'fh'};
    return <$fh>;
}
sub fh       { $_[0]->{'fh'} }
sub path     { $_[0]->{'tempfile'} }
sub content_type { $_[0]->{'mime'} }
sub basename { &File::Basename::basename($_[0]->{'filename'}) }

1;
