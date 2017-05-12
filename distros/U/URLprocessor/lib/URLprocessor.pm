package URLprocessor;

# h2xs -XA -n URLprocessor

use 5.010001;
use strict;
#use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use URLprocessor ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.02';


# Let's rock.

##########################################################################################
### Public interface.
##########################################################################################

sub new {
	my $class = shift;
	my $self = {
		URL => undef,
		GLOBAL_PART => undef,
		LOCAL_PART => undef,
		#---
		PROTOCOL => undef,
		LOGIN => undef,
		PASSWD => undef,
		HOST => undef,
		PORT => undef,
		LOCAL_PATH => undef,
		PARAMS => {}, # hash representation of params.
		FRAGMENT => undef, # after sign #
		#--
		PARAMS_VALID => undef,
	};
	bless($self, $class);
	
	$self->{URL} = shift if @_;

	# Parsing (lower case) url.
	if (defined $self->{URL} and $self->{URL} ne '') {
		$self->{URL} =~ s/^\s+//g;
		$self->{URL} =~ s/\s+$//g;
		$self->{URL} = lc $self->{URL};
		$self->_parse_url;
	}
	
	return $self; 
}


sub url {
	my $self = shift;
	$self->_prepare_url;
	return $self->{URL}; # String of URL.
}


sub url_global_part {
	my $self = shift;
	return $self->{GLOBAL_PART};
}


sub url_local_part {
	my $self = shift;
	return $self->{LOCAL_PART};
}


sub protocol {
	my $self = shift;
	return $self->{PROTOCOL} unless @_;
	
	$self->{PROTOCOL} = shift;
	$self->{PROTOCOL} = lc $self->{PROTOCOL} if defined $self->{PROTOCOL};
}

sub login {
	my $self = shift;
	return $self->{LOGIN} unless @_;
	
	$self->{LOGIN} = shift;
}

sub passwd {
	my $self = shift;
	return $self->{PASSWD} unless @_;
	
	$self->{PASSWD} = shift;
}

sub host {
	my $self = shift;
	return $self->{HOST} unless @_;
	
	$self->{HOST} = shift;
	$self->{HOST} = lc $self->{HOST} if defined $self->{HOST};
}

sub port {
	my $self = shift;
	return $self->{PORT} unless @_;
	
	$self->{PORT} = shift;
}

sub localpath {
	my $self = shift;
	return $self->{LOCAL_PATH} unless @_;
	
	my $path = shift;
	# Only SCALAR, ARRAY and undef are allowed.
	if (ref $path eq '' or ref $path eq 'SCALAR') {
		$self->{LOCAL_PATH} = $path;
	}
	elsif (ref $path eq 'ARRAY') {
		$self->{LOCAL_PATH} = join '/', @{$path};
	}
	
	return unless defined $self->{LOCAL_PATH};
	$self->{LOCAL_PATH} = '/'.$self->{LOCAL_PATH};
	$self->{LOCAL_PATH} =~ s/^\/+/\//;
#	$self->{LOCAL_PATH} = lc $self->{LOCAL_PATH};

}

sub localpath_array {
	my $self = shift;
	my $path = $self->localpath;
	$path =~ s/^\///;
	
	return split '/', $path;
}

sub fragment {
	my $self = shift;	
	return $self->{FRAGMENT} unless @_;
	
	$self->{FRAGMENT} = shift;
}



##########################################################################################
### Params methods.
##########################################################################################

sub params_hash {
	my $self = shift;
	return $self->{PARAMS} unless @_;
	
	$self->{PARAMS} = shift;
}


sub params_string {
	my $self = shift;
	my $userDelimiter = (@_) ? shift : '&'; # & - default value
	
	my $params = '';
	my $delimiter = '';
	while(my($k, $v) = each %{$self->{PARAMS}}) {
		$params .= "$delimiter$k=$v";
		$delimiter = $userDelimiter;
	}
	return $params;
}


sub param_value {
	my $self = shift;
	my $param = shift;
	
	return $self->{PARAMS}->{$param} if defined $param and exists $self->{PARAMS}->{$param};
	return undef;
}


# Pay attention with arguments order!
# This function may generate hidden errors.
sub param_add {
	my $self = shift;
	my $param = shift;
	my $val = shift;
	
	$self->{PARAMS}->{$param} = $val if defined $param and defined $val;
}

sub param_del {
	my $self = shift;
	my $param = shift;
	
	delete $self->{PARAMS}->{$param} if defined $param;
}

# Check parameter existence.
sub param_exist {
	my $self = shift;
	my $param = shift;

	return 1 if defined $param and exists $self->{PARAMS}->{$param};
	return 0;
}

# There is no way to set string of params from outside. It is bad idea, but it isn't rule.
# In the future it will may be implemented it. 


##########################################################################################
### Parsing "private" methods.
##########################################################################################

sub _prepare_url {
	my $self = shift;
	$self->{URL} = '';
	$self->{URL} = "$self->{PROTOCOL}://" if defined $self->{PROTOCOL};
	$self->{URL} .= "$self->{LOGIN}:$self->{PASSWD}@" if defined $self->{LOGIN} and defined $self->{PASSWD};
	$self->{URL} .= $self->{HOST} if defined $self->{HOST};
	$self->{URL} .= ":$self->{PORT}" if defined $self->{PORT};
	if (defined $self->{LOCAL_PATH}) {
		$self->{URL} .= '/' if $self->{LOCAL_PATH} !~ /^\//;
		$self->{URL} .= $self->{LOCAL_PATH}; # Sign '/' is not required on the end because the localpath may contains a file.
		my $params_str = $self->params_string;
		$self->{URL} .= "?$params_str" if $params_str ne '';
		$self->{URL} .= "#$self->{FRAGMENT}" if defined $self->{FRAGMENT} and $self->{FRAGMENT} ne '';		
	}
}


sub _split_url {
	my $self = shift;
	#                          global_part         local_part
	return $self->{URL} =~ m|^(\w*?://[^/?&#]+)(?:(.+))?|;
}


sub _parse_global_part {
	my $self = shift;
	#                                  protocol   auth       host            port
	return $self->{GLOBAL_PART} =~ m|^(\w*)://(?:([^@/]+)@)?([^:@/?#]*)(?:\:(.+))?|;
	# If host has a + instead of * then it isn't working correctly.
}


sub _parse_local_part {
	my $self = shift;
	#                                 localpath      params       fragment
	return $self->{LOCAL_PART} =~ m|^(/[^?&#]*)(?:\?([^#]*))?(?:#(.+))?|;
}


# This is normal function, not method. It isn't working on object attributes.
# Return PARAMS_VALID, \%PARAMS
# PARAMS_VALID == 0 - error
# PARAMS_VALID == 1 - ok
sub _parse_params {
	my $params = shift;
	my $separator = shift;

	# Params is empty.
	if (!defined $params or $params eq '') {
		return (1, undef);
	}

	my $params_ref = {};
	my $valid_status = 0;
	# Split by pairs param=val
	foreach (split $separator, $params) {
		return (0, undef) if $_ eq '';
			
		my @param_val = split '=', $_;
		if(scalar(@param_val) == 2 and $param_val[0] ne '' and $param_val[1] ne '') {
			$params_ref->{$param_val[0]} = $param_val[1];
			$valid_status = 1;
		} else {
			return (0, undef);
		}
	}
	
	return ($valid_status, $params_ref);
}


# Parse URL string and save those parts.
# This method sets attributes.
sub _parse_url {
	my $self = shift;
	
	# Split URL to global part and optionally localpath.
	($self->{GLOBAL_PART}, $self->{LOCAL_PART}) = $self->_split_url;
	
	# Parse global part.
	return unless defined $self->{GLOBAL_PART};
	my $auth;
	($self->{PROTOCOL}, $auth, $self->{HOST}, $self->{PORT}) = $self->_parse_global_part;

	# In global part: parse login and passwd.
	($self->{LOGIN}, $self->{PASSWD}) = split(':', $auth) if (defined $auth and $auth ne '');

	# Parse local part.
	return unless defined $self->{LOCAL_PART};
	my $params;
	($self->{LOCAL_PATH}, $params, $self->{FRAGMENT}) = $self->_parse_local_part;

	# Parse params.
	($self->{PARAMS_VALID}, $self->{PARAMS}) = _parse_params($params, '&'); # & - separator.

}




##########################################################################################
### Validating methods.
##########################################################################################

sub _is_valid {
	my $self = shift;
	my $msg = ''; # Message container
	
	$msg .= "Global part is undef\n" if !defined $self->{GLOBAL_PART};
	
	$msg .= "Protocol is empty\n" if !defined $self->{PROTOCOL} or $self->{PROTOCOL} eq '';
	$msg .= "Login is undef\n" if !defined $self->{LOGIN} and defined $self->{PASSWD};
	$msg .= "Passwd is undef\n" if defined $self->{LOGIN} and !defined $self->{PASSWD};
	if (defined $self->{LOGIN} and defined $self->{PASSWD}){
		$msg .= "Login is empty\n" if $self->{LOGIN} eq '' and $self->{PASSWD} ne '';
		$msg .= "Passwd is empty\n" if $self->{LOGIN} ne '' and $self->{PASSWD} eq '';			
	}

	$msg .= "Host is empty\n" if !defined $self->{HOST} or $self->{HOST} eq '';
	$msg .= "Port must be numeric value\n" if defined $self->{PORT} and $self->{PORT} !~ /^\d+$/;
	if (defined $self->{LOCAL_PART} and length $self->{LOCAL_PART} > 0 and !defined $self->{LOCAL_PATH}) {
		# Chcek only defined localpath because params and fragmet are functional dependend by localpath.
		$msg .= "Local part is set but localpath, parameters and fragment are undef\n";
	}
	if (!defined $self->{LOCAL_PATH} and (scalar keys %{$self->{PARAMS}} or defined $self->{FRAGMENT})) {
		$msg .= "Localpath cannot be undef when parameters or fragment is set\n";
	}
	
	$msg .= "Badly parameters\n" if defined $self->{PARAMS_VALID} and $self->{PARAMS_VALID} == 0;

	return (1, "OK") if $msg eq '';
	$msg =~ s/\n$//;
	return (0, $msg); # 0 - invalid URL.
}


sub valid_status {
	my $self = shift;

	return ($self->_is_valid)[0];
}


sub valid_msg {
	my $self = shift;

	return ($self->_is_valid)[1];
}




##########################################################################################
### Additional and useful "private" functions.
##########################################################################################

sub _here_im {
	return (caller(1))[3];
}


1;
__END__

=head1 NAME

URLprocessor - Perl extension for object oriented URL address processing.

=head1 SYNOPSIS

  use URLprocessor;
  
  $url = URLprocessor->new('http://login:passwd@www.cpan.org:8080/local/path/file.php?param=val&param2=val2#some_fragment');
  $url->port(80);
  $url->fragment('some_other_fragment');
  $url->param_add('newparam', 'newvalue');
  $url->param_del('param2');
  print $url->valid_status(), "\n";
  print $url->valid_msg(), "\n";
  print $url->login(), "\n";
  print $url->host(), "\n";
  print $url->url(), "\n";

=head1 DESCRIPTION

This module contains a class with implementation for representing a URL address.
You can read and write each part of a URL object. 
This class implements methods for the validation of a URL. You can build your own URL
or modify an already existing object.

A right URL must contain:

  protocol (scheme)
  host

Optional parts of a URL:

  login and passwd
  port
  local path


Optional parts of a local path:

  parameters (query)
  fragment (label)


=head1 METHODS

You have an access to some useful methods:

=item $url = URLprocessor->new( )

=item $url = URLprocessor->new( $str )

Construct new URL object and return a reference to it.
Every URL is translated to a lower case.


=item $url->url

Get string representation of a URL object.


=item $url->url_global_part

Get string representation of the global part of a URL object (protocol, login, password, host, port).


=item $url->url_local_part

Get string representation of the global part of a URL object (local path, query, label).


=item $url->protocol

=item $url->protocol( $str )

=item $url->protocol( undef )

Get and set a protocol. A string is translated to a lower case.


=item $url->login

=item $url->login( $str )

=item $url->login( undef )

Get and set a login.


=item $url->passwd

=item $url->passwd( $str )

=item $url->passwd( undef )

Get and set a passwd.


=item $url->host

=item $url->host( $str )

=item $url->host( undef )

Get and set a host. The host is translated to a lower case.


=item $url->port

=item $url->port( $str )

=item $url->port( undef )

Get and set a port. Here you can write anything but remember that the port must be a numeric value.
If not, valid_status return 0.


=item $url->localpath

=item $url->localpath( $str )

=item $url->localpath( \@array )

=item $url->localpath( undef )

Get and set a local path (with file, without query).
Only SCALAR, ARRAY and undef are allowed to set the localpath.
You should remember about '/' at the end of @array if it is a directory.
For example:

    @array = ('dir1', 'dir2', 'dir3/')


=item $url->localpath_array

Get an array of the parts of a local path.


=item $url->fragment

=item $url->fragment( $str )

=item $url->fragment( undef )

Get and set a fragment. This is a part of a URL after '#'.


=item $url->params_string

=item $url->params_string( $str )

Get string representation of query parameters.  
You can prepare a string with $str delimiter (default is '&').


=item $url->params_hash

=item $url->params_hash( undef )

=item $url->params_hash( \%params )

Get or set reference to a hash with query parameters (param => value).


=item $url->param_value( $param_name )

Get the value of a parameter from a query.


=item $url->param_add( $param_name, $param_val )

Set in a query the following pair: parameter=value. 
The parameter and value must be defined.
Pay attention to the argument order!


=item $url->param_del( $param_name )

Delete from a query the following pair: parameter=value  


=item $url->param_exist( $param_name )

Check if the pair parameter=value exists in a query.


=item $url->valid_status

Get status from the validation of a URL object. 
If anything goes wrong return 0, else 1.


=item $url->valid_msg

Get a message from the validation of a URL object. 
 


=head1 SEE ALSO

L<URI>, L<URI::URL>, L<Rose::URI>

=head1 AUTHOR

Pawel Koscielny, E<lt>koscielny.pawel@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Pawel Koscielny

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
