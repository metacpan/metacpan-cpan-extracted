#!/usr/bin/perl

package OSGi::Osgish::CompletionHandler;

use strict;
use File::Spec;
use Data::Dumper;

=head1 NAME 

OSGi::Osgish::CompletionHandler - Custom completion routines for readline.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut


sub new { 
    my $class = shift;
    my $osgish = shift || die "No osgish object given";
    my $self = {
                osgish => $osgish
               };
    bless $self,(ref($class) || $class);
    return $self;
}

sub bundles {
    my $self = shift;
    my $osgish = $self->{osgish};
    
    return $self->_bundle_or_service(sub { $osgish->agent->bundle_ids(use_cached => 1) },
                                     sub { $osgish->agent->bundle_symbolic_names(use_cached => 1)},
                                     @_);
}

sub services {
    my $self = shift;
    my $osgish = $self->{osgish};
    return $self->_bundle_or_service(sub { $osgish->agent->service_ids(use_cached => 1) },
                                     sub { $osgish->agent->service_object_classes(use_cached => 1)},
                                     @_);
}

sub files_extended {
    my $self = shift;
    return sub {
        my $term = shift;
        my $cmpl = shift;
        my $filter = undef;
        
        $term->suppress_completion_append_character();
        
        use File::Spec;
        my @path = File::Spec->splitdir($cmpl->{str} || ".");
        my $dir = File::Spec->catdir(@path[0..$#path-1]);
        my $lookup_dir = $dir;
        if ($dir =~ /^\~(.*)/) {
            my $user = $1 || "";
            $lookup_dir = glob("~$user");
        }
        my $file = $path[$#path];
        $file = '' unless $cmpl->{str};
        my $flen = length($file);
        
        my @files = ();
        $lookup_dir = length($lookup_dir) ? $lookup_dir : ".";
        if (opendir(DIR, $lookup_dir)) {
            if ($filter) {
                @files = grep { substr($_,0,$flen) eq $file && $file =~ $filter } readdir DIR;
            } else {
                @files = grep { substr($_,0,$flen) eq $file } readdir DIR;
            }
            closedir DIR;
            # eradicate dotfiles unless user's file begins with a dot
            @files = grep { /^[^.]/ } @files unless $file =~ /^\./;
            # reformat filenames to be exactly as user typed
            my @ret = ();
            for my $file (@files) {
                $file .= "/" if -d $lookup_dir . "/" . $file;
                $file = $dir eq '/' ? "/$file" : "$dir/$file" if length($dir);
                push @ret,$file;
        }
            return \@ret;
        } else {
            $term->completemsg("Couldn't read dir: $!\n");
            return [];
        }
    }
}

sub servers {
    my $self = shift;
    return sub {
        my ($term,$cmpl) = @_;
        my $osgish = $self->{osgish};
        my $server_list = $osgish->servers->list;
        return [] unless @$server_list;
        my $str = $cmpl->{str} || "";
        my $len = length($str);
        return [ grep { substr($_,0,$len) eq $str }  map { $_->{name} } @$server_list  ];
    }
}

# ====================================================================================== 

sub _bundle_or_service {
    my $self = shift;
    my $osgish = $self->{osgish};
    my ($ids_sub,$names_sub,@rest) = @_;
    my $args = @rest ? { @rest } : {};
    return sub { 
        my ($term,$cmpl) = @_;
        return [] unless $osgish->agent;
        my $str = $cmpl->{str} || "";
        my $len = length($str);
        if (!$args->{no_ids} && $str =~ /^\d+$/) { 
            # Complete on ids
            my $ret = [ sort { $a <=> $b } grep { substr($_,0,$len) eq $str } @{&$ids_sub()} ];
            return $ret;
        } else {
            my @sym_names = sort keys %{&$names_sub()};
            if ($str) {
                return [ grep { substr($_,0,$len) eq $str } @sym_names ];
            } else {
                return \@sym_names;
            }
        }
    }
}


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



