## H2XS GENERATED CODE ##
package Unicode::Transliterate;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);
use constant UTRANS_FORWARD => "FORWARD";
use constant UTRANS_REVERSE => "REVERSE";


# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Unicode::Transliterate ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Unicode::Transliterate macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}


## BEAUTIFULLY HAND CRAFTED CODE ##


##
# $class->new;
# ------------
#   Instanciates a new Unicode::Transliterate object
##
sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless { @_ }, $class;
    return $self;
}


##
# $self->from;
# ------------
#   Accessor for the from attribute
##
sub from
{
    my $self = shift;
    if (@_)
    {
	my $from = shift;
	my $q_from = quotemeta ($from);
	my $ok = 0;
	foreach my $transliterator_id ($self->list_pairs)
	{
	    $ok = 1 if ($transliterator_id =~ /^$q_from\-/);
	}
	$ok or croak "No transliterators available for $from";
	$self->{from} = $from;
    }
    else
    {
	return $self->{from};
    }
}


##
# $self->to
# ---------
#   Accessor for the to attribute
## 
sub to
{
    my $self = shift;
    if (@_)
    {
	my $to = shift;
	my $q_to = quotemeta ($to);
	my $ok = 0;
	foreach my $transliterator_id ($self->list_pairs)
	{
	    $ok = 1 if ($transliterator_id =~ /\-$q_to$/);
	}
	$ok or croak "No transliterators available for $to";
	$self->{to} = $to;
    }
    else
    {
	return $self->{to};
    }
}


##
# $self->list_pairs
# -----------------
#   Returns a list of ids that can be used
##
sub list_pairs
{
    my $self = shift;
    my $list = $self->{list_pairs};
    unless (defined $list)
    {
	my $available_indexes = _myxs_countAvailableIDs();
	my $res = {};
	foreach my $index (0..$available_indexes)
	{
	    my $transliterator_id = _myxs_getAvailableID ($index);
	    my ($from, $to) = $transliterator_id =~ /(.*)-(.*)/;
	    $res->{$from . '-' . $to} = 1;
	    $res->{$to . '-' . $from} = 1;
	}
	$self->{list_pairs} = $res;
	$list = $res;
    }
    return sort keys %{$list};
}


# internal
sub _raw_list_pairs
{
    my $self = shift;
    my @res  = ();
    my $available_indexes = _myxs_countAvailableIDs();
    foreach my $index (0..$available_indexes)
    {
	my $transliterator_id = _myxs_getAvailableID ($index);
	push @res, $transliterator_id;
    }
    return @res;
}


##
# $self->process (@_);
# --------------------
#   Returns a list of transliterated strings from @_
##
sub process
{
    my $self = shift;
    my $data = shift;
    
    my $forward = $self->from . '-' . $self->to;
    my $reverse = $self->to . '-' . $self->from;
    
    foreach my $transliterator_id ($self->_raw_list_pairs)
    {
	($transliterator_id eq $forward) and return _myxs_transliterate ($transliterator_id, UTRANS_FORWARD, $data);
	($transliterator_id eq $reverse) and return _myxs_transliterate ($transliterator_id, UTRANS_REVERSE, $data);
    }
    
    die "Cannot find $forward nor $reverse transliterator.\n\n" . join "\n", $self->list_pairs;
}


bootstrap Unicode::Transliterate $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Unicode::Transliterate - Perl wrapper for ICU transliteration services

=head1 SYNOPSIS

A perl wrapper to perform transliteration between different languages
using UTF-8

    use Unicode::Transliterate;
    my $translit = new Unicode::Transliterate ( from => 'Latin', to => 'Katakana' );
    print $translit->process ("Watakushi wa Sheffield ni sunde imasu");


=head1 DESCRIPTION

Unicode::Transliterate is a Perl wrapper around IBM's ICU 2.x libraries.
You need to install ICU 2.0 before you can use it.
see http://oss.software.ibm.com/icu/


=head2 new

Creates a new Unicode::Transliterate object. Optional parameters can be passed
to the constructor, such as 'from' and 'to'.

    my $translit = new Unicode::Transliterate;


=head2 list_pairs

Lists pairs that can be used from the transliteration.


=head2 from

Accessor for the 'from' attribute

    $translit->from ('Katakana');
    my $from = $translit->from;


=head2 to

Accessor for the 'to' attribute

    $translit->to ('Katakana');
    my $from = $translit->to;


=head2 process

Processes the data and returns transliterated result

    my $transliterated = $translit->process ("Foo");


=head2 EXPORT

None by default.


=head1 AUTHOR

Jean-Michel Hiver (jhiver@mkdoc.com)
This module is redistributed under the same licence as Perl itself.

Bug reports welcome!


=head1 SEE ALSO

ICU, International Components for Unicode - http://oss.software.ibm.com/icu/

PICU, Perl Wrappers for ICU Project - http://picu.sourceforge.net/


=cut
