use strict;
use warnings;

use Scalar::Util qw(blessed);

use VS::RuleEngine::Util qw(is_valid_name is_valid_package_name is_existing_package);

sub _check_add_args {
    my ($self, $type, $has, $name, $obj) = @_;
    
    croak "Name is undefined" if !defined $name;
	croak "Name '${name}' is invalid" if !is_valid_name($name);
	croak "${type} is undefined" if !defined $obj;
	
	croak "${type} '${name}' is already defined" if $has->($self, $name);
	
	if (blessed $obj) {
		croak "${type} is an instance that does not conform to VS::RuleEngine::${type}" if !$obj->isa("VS::RuleEngine::${type}");
	}
	else {
		croak "${type} '${obj}' doesn't look like a valid class name" if !is_valid_package_name($obj);
		if (!is_existing_package($obj)) {
		    eval "require ${obj};";
		    croak $@ if $@;
		}
		
		croak "${type} '${obj}' does not conform to VS::RuleEngine::${type}" if !UNIVERSAL::isa($obj, "VS::RuleEngine::${type}");
	}
	
	1;
}

1;
__END__

=head1 DESCRIPTION

Mixin for common utils

=cut
