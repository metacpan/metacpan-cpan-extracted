#!/usr/bin/perl

=head1 NAME 

OSGi::Osgish::Upload - Upload a bundle to the agent upload directory

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package OSGi::Osgish::Agent::Upload;

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common;
use OSGi::Osgish;
use JMX::Jmx4Perl::Agent::UserAgent;
use Data::Dumper;
use vars qw($HAS_PROGRESS_BAR);

my $UPLOAD_SERVICE_NAME = "osgish:type=Upload";

BEGIN {
    eval {
        require "Term/ProgressBar.pm";
        $HAS_PROGRESS_BAR = 1;
    };
}

sub new { 
    my $class = shift;
    my $agent = shift || die "No OSGi::Osgish object given";
    my $ua = new JMX::Jmx4Perl::Agent::UserAgent();
    $ua->jjagent_config($agent->cfg());
    my $self = { 
                url => $agent->cfg('url') . "-upload",
                agent => $agent,
                ua => $ua
               };
    bless $self,(ref($class) || $class);
    return $self;
}

sub list {
    my $self = shift;
    my $agent = $self->{agent};
    $self->{list} = $agent->execute($UPLOAD_SERVICE_NAME,"listUploadDirectory");    
    return $self->{list};
}

sub cache_update {
    # Refrehs internal list cache
    shift->list;
}

sub remove {
    my $self = shift;
    my $file = shift || die "No file given\n";
    my $agent = $self->{agent};
    return $agent->execute($UPLOAD_SERVICE_NAME,"deleteFile",$file);
}

sub upload { 
    my $self = shift;
    my $file = shift;
    my $cfg = {};
    if (@_) {
        $cfg = ref($_[0]) eq "HASH" ? $_[0] : { @_ };
    }
    #$file = glob($file) if $file =~ /^~/;
    die "No file $file\n" unless $file and -f $file;
    my $ua = $self->{ua};
    
    {
        local $HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;
        
        my $req = 
          POST 
            $self->{url},
              'Content_Type' => 'form-data', 
                'Content' => { "upload" => [ $file ] };
        my $reader = $self->_content_reader($req->content(),$cfg,$req->header('Content_Length'));
        $req->content($reader);
        my $resp = $ua->request($req);
        die "Error while uploading $file: ",$resp->message if $resp->is_error;
    }
}

sub complete_files_in_upload_dir {
    my $self = shift;
    my $term = shift;
    my $cmpl = shift;
    
    my $list = $self->{list} || $self->list;
    my $file = $cmpl->{str} || "";
    my $flen = length($file);

    my @files = grep { substr($_,0,$flen) eq $file } keys %$list;
    return \@files;
}

sub _content_reader {
    my $self = shift;
    my $gen = shift;
    my $cfg = shift;
    my $len = shift;
    if ($HAS_PROGRESS_BAR && $cfg->{progress_bar}) {
        my $progress = new Term::ProgressBar({name => "Upload",count => $len,remove => 1,term_width => 65});
        $progress->minor(0);
        my $size = 0;
        my $next_update = 0;
        sub {
            my $chunk = &$gen();
            $size += length($chunk) if $chunk;
            $next_update = $progress->update($size)
              if $size >= $next_update;
            return $chunk;
        }
    } else {
        return sub {
            return &$gen();
        }
    }
}

#my $u = new OSGi::Osgish(url => "http://localhost:8080/j4p-upload");
#$u->upload("n",progress_bar => 1);

=head1 LICENSE

This file is part of osgish.

Osgish is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

osgish is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with osgish.  If not, see <http://www.gnu.org/licenses/>.

A commercial license is available as well. Please contact roland@cpan.org for
further details.

=head1 PROFESSIONAL SERVICES

Just in case you need professional support for this module (or JMX or OSGi in
general), you might want to have a look at www.consol.com Contact
roland.huss@consol.de for further information (or use the contact form at
http://www.consol.com/contact/)

=head1 AUTHOR

roland@cpan.org

=cut

1; 
