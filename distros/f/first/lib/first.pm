package first;

use strict;
use warnings;
use Carp;

use version;our $VERSION = qv('0.0.1');

# require UNIVERSAL::require;
# until http://rt.cpan.org/Ticket/Display.html?id=24741 is added we'll inlcude it at the end

our $module;
our $failed = {};

sub import {
    my $self = shift;
    my %flags = map { $_ => 1,} grep(/^-/, @_);
    
    $module = undef;
    
    local $UNIVERSAL::Level = $UNIVERSAL::Level + 1; # || -level=1 + 1 
    
    for my $ns (grep !/^-/, @_) {
        next if !defined$ns;
        
        my $nms = $ns; # copy to possibly modify
        my @imp;
        
        if(ref $ns eq 'ARRAY') {
            $nms = shift @{ $ns };
            @imp = @{ $ns };    
        }
                        
        if( @imp ? $nms->use( @imp ) : $nms->use ) {
            $module = $nms;
            last;
        }
        else {
            $failed->{ $nms } = $@;
        }
    }
    
    if( keys %{ $failed } ) {
        my $msg = "Could not load these modules:\n\t" . join("\n\t", keys %{ $failed }) . "\n";
        carp  $msg if exists $flags{'-carp'};
        croak $msg if exists $flags{'-croak'};
    }
    
    return $module;
}

################################
#### start UNIVERSAL::require ##
################################

# UNIVERSAL-require-0.11
# sans POD, and with http://rt.cpan.org/Ticket/Display.html?id=24741

package UNIVERSAL::require;
$UNIVERSAL::require::VERSION = '0.11';

# We do this because UNIVERSAL.pm uses CORE::require().  We're going
# to put our own require() into UNIVERSAL and that makes an ambiguity.
# So we load it up beforehand to avoid that.
BEGIN { require UNIVERSAL }

package UNIVERSAL;

use strict;

use vars qw($Level);
$Level = 0;

sub require {
    my($module, $want_version) = @_;

    $UNIVERSAL::require::ERROR = '';

    die("UNIVERSAL::require() can only be run as a class method")
      if ref $module; 

    die("UNIVERSAL::require() takes no or one arguments") if @_ > 2;

    my($call_package, $call_file, $call_line) = caller($Level);

    # Load the module.
    my $file = $module . '.pm';
    $file =~ s{::}{/}g;

    # For performance reasons, check if its already been loaded.  This makes
    # things about 4 times faster.
    return 1 if $INC{$file};

    my $return = eval qq{ 
#line $call_line "$call_file"
CORE::require(\$file); 
};

    # Check for module load failure.
    if( $@ ) {
        $UNIVERSAL::require::ERROR = $@;
        return $return;
    }

    # Module version check.
    if( @_ == 2 ) {
        eval qq{
#line $call_line "$call_file"
\$module->VERSION($want_version);
};

        if( $@ ) {
            $UNIVERSAL::require::ERROR = $@;
            return 0;
        }
    }

    return $return;
}

sub use {
    my($module, @imports) = @_;

    local $Level = $Level ? $Level : 1;
    my $return = $module->require or return 0;

    my($call_package, $call_file, $call_line) = caller;

    eval qq{
package $call_package;
#line $call_line "$call_file"
\$module->import(\@imports);
};

    if( $@ ) {
        $UNIVERSAL::require::ERROR = $@;
        return 0;
    }

    return $return;
}

##############################
#### end UNIVERSAL::require ##
##############################

1;

__END__

=head1 NAME

first - use the first loadable module in a list

=head1 SYNOPSIS

  use first 'YAML::Syck', 'YAML::TINY', 'YAML';
  
  if( $first::module ) {
      print "Looks like I'll be using $first::module for this YAML..."
  }
  else {
      die "I have no YAML modules: $@";
  }
  
  my $yaml = $first::module->new();
  
  use first 'CGI::Simple', 'CGI::Minimal', 'CGI';
  my $cgi = $first::module ? $first::module->new() : $fallback_obj;

=head1 DESCRIPTION

Two main circumstances I've encountered where this is useful is:

=over 4

=item * when you have a list of modules that have the same interface but are more desirable for one reason or another like speed, portability, or availability.

    use first 'CGI::Simple', 'CGI::Minimal', 'CGI';

=item * when you have a list of modules that do the same task but via different methods

    use first 'YAML::Syck', 'YAML::TINY', 'YAML', 'XML::Tiny', 'XML::Simple', 'Storable';

    my $serializer = $first::module;
    
    # now use functions based on $serializer / $first::module, perhaps keeping it in a hash that maps funtions to the name space for a consistent API where none existed before

=back

=head1 ARGUMENTS

Arguments after 'use first' can be a name space string or an array reference whose first item is a name space and the rest is what would get passed to/after 'use Name::Space'

=head1 VARIABLES

These variables are available after 'use first' and are reset upon each call of 'use first' (Similar to how $@ is reset with every eval)

=head2 $first::module

Contains the namespace that was loaded, if any. undefined otherwise if none could be loaded.

=head2 $first::failed

Is a hashref whose keys are the name space that could not be loaded and the values are the given key's error message.

=head2 $@

Contains the last error, if any.

=head1 SEE ALSO

L<last>, L<any>, L<all>, L<fake>

=head1 TODO

More tests as per first.t

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut