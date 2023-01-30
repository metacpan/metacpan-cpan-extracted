# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2023 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package YAML::PP::Schema::Env;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};
 
    my $options = $args{options};
    my $default_value;
    my $default_separator = ':';
    for my $opt (@$options) {
        if ($opt =~ m{^defval=(.*)$}) {
            $default_value = $1;
	} elsif ($opt =~ m{defsep=(.*)$}) {
	    $default_separator = $1;
        } else {
            croak "Invalid option for ENV Schema: '$opt'";
        }
    }
 
    $schema->add_resolver(
        tag => '!ENV',
        match => [ all => sub {
            my ($constructor, $event) = @_;
	    (my $val = $event->{value}) =~ s{\$(\{.*?\})}{
                my $capture = $1;
		if ($capture =~ m{\{(.*?)(?:\Q$default_separator\E(.*))?\}$}) {
		    my($this_env, $this_default_value) = ($1, $2);
		    my $this_value;
		    if (!exists $ENV{$this_env}) {
		        if (defined $this_default_value) {
			    $this_value = $this_default_value;
		        } elsif (defined $default_value) {
			    $this_value = $default_value;
		        } else {
			    croak "There's no environment variable '$this_env', and no global or local default value was configured";
			}
		    } else {
		        $this_value = $ENV{$this_env};
		    }
		    $this_value;
		} else {
		    croak "Unexpected error: cannot parse '$capture'";
		}
            }ge;
	    return $val;
        }],
        implicit => 0,
    );
}

1;

__END__
