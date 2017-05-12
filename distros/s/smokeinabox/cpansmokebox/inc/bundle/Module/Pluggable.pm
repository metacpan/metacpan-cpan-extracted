package Module::Pluggable;

use strict;
use vars qw($VERSION);
use Module::Pluggable::Object;

# ObQuote:
# Bob Porter: Looks like you've been missing a lot of work lately. 
# Peter Gibbons: I wouldn't say I've been missing it, Bob! 


$VERSION = '3.9';

sub import {
    my $class        = shift;
    my %opts         = @_;

    my ($pkg, $file) = caller; 
    # the default name for the method is 'plugins'
    my $sub          = $opts{'sub_name'}  || 'plugins';
    # get our package 
    my ($package)    = $opts{'package'} || $pkg;
    $opts{filename}  = $file;
    $opts{package}   = $package;


    my $finder       = Module::Pluggable::Object->new(%opts);
    my $subroutine   = sub { my $self = shift; return $finder->plugins(@_) };

    my $searchsub = sub {
              my $self = shift;
              my ($action,@paths) = @_;

              $finder->{'search_path'} = ["${package}::Plugin"] if ($action eq 'add'  and not   $finder->{'search_path'} );
              push @{$finder->{'search_path'}}, @paths      if ($action eq 'add');
              $finder->{'search_path'}       = \@paths      if ($action eq 'new');
              return $finder->{'search_path'};
    };


    my $onlysub = sub {
        my ($self, $only) = @_;

        if (defined $only) {
            $finder->{'only'} = $only;
        };
        
        return $finder->{'only'};
    };

    my $exceptsub = sub {
        my ($self, $except) = @_;

        if (defined $except) {
            $finder->{'except'} = $except;
        };
        
        return $finder->{'except'};
    };


    no strict 'refs';
    no warnings qw(redefine prototype);
    
    *{"$package\::$sub"}        = $subroutine;
    *{"$package\::search_path"} = $searchsub;
    *{"$package\::only"}        = $onlysub;
    *{"$package\::except"}      = $exceptsub;

}

1;


