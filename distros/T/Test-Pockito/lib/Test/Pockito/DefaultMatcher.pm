package Test::Pockito::DefaultMatcher;

use strict;
use warnings;

use Scalar::Util::Reftype;
use Exporter 'import';

=head1 NAME

Test::Pockito::DefaultMatcher

=head1 SYNOPSIS

Default matching for Pockito

=head1 DESCRIPTION

Default implementation of matching.  If none of the any_* subs are used for matching, then it reverts to a ne op for matching.

=head1 SUBROUTINES

=over 1

=item default_call_match( $package, $method, \@params_found, \@params_expected )

This is the default matching metchanism for Pockito though you are at will to implement your own.  Passing an implementation with this signature overrides the matching sub.  The default implementation does not use $package nor $method, but they will be of use if you have multiple, different ways to define parameters as equal.

=back

=cut

our %lookup    = ();
our @EXPORT_OK = qw(is_defined);

sub default_call_match {
    my $package = shift;
    my $method  = shift;

    my $param_found_ref    = shift;
    my $param_expected_ref = shift;

    my (@left)  = @{$param_found_ref};
    my (@right) = @{$param_expected_ref};

    if ( $#left < $#right ) {
        (@left)  = @{$param_expected_ref};
        (@right) = @{$param_found_ref};
    }

    foreach my $y ( 0 .. $#left ) {
        my $l = $left[$y]  || 0;
        my $r = $right[$y] || 0;

        if ( exists $lookup{$l} ) {
            return 0 if !&{ $lookup{$l} }($r);
        }
        elsif ( exists $lookup{$r} ) {
            return 0 if !&{ $lookup{$r} }($l);
        }
        elsif ( $l ne $r ) {
            return 0;
        }
    }

    return 1;
}

=head1 MATCHERS

All the following matchers can be exported or refered to by package name.  They use Scalar::Util::Reftype under the hood except for is_defined.

	is_defined
	is_scalar
	is_array
	is_hash
	is_code
	is_global
	is_lvalue
	is_regexp
	is_scalar_object
	is_array_object
	is_hash_object
	is_code_object
	is_glob_object
	is_lvalue_object
	is_ref_object
	is_io_object
	is_regexp_object

With these, one can write:

	$pocket->when( $mock->( is_defined, is_regexp, 1, 2, is_code_object )->...

to match 

	any defined value
	any regular expression ref
	the value 1
	the value 2
	any blessed code ref

=cut

our @types =
  qw(scalar array hash code global lvalue regexp scalar_object array_object hash_object code_object glob_object lvalue_object ref_object io_object regexp_object);

foreach my $type (@types) {

    #Going to hell for this.
    my $sub_name = __PACKAGE__ . "::is_" . $type;
    my $check    = sub {
        return reftype(shift)->$type();
    };
    my $wrapper = sub { return $check };

    no strict "refs";
    *$sub_name = $wrapper;
    use strict "refs";

    $lookup{$check} = $check;
    push( @EXPORT_OK, "is_" . $type );
}

sub check_is_defined {
    return defined shift;
}

sub is_defined {
    return \&check_is_defined;
}

$lookup{ \&check_is_defined } = \&check_is_defined;

=head1 SUPPORT

exussum@gmail.com

=head1 AUTHOR

Spencer Portee
CPAN ID: EXUSSUM
exussum@gmail.com

=head1 SOURCE

http://bitbucket.org/exussum/pockito/

=head1 COPYRIGHT

This program is free software licensed under the...

    The BSD License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;
