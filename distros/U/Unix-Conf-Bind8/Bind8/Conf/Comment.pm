# Comment.pm
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Comment - Class for handling comments
between directives.

=head1 SYNOPSIS

	use Unix::Conf::Bind8;

	my ($conf, $acl);
	$conf = Unix::Conf::Bind8->new_conf (
		FILE        => '/etc/named.conf',
		SECURE_OPEN => 1,
	) or $conf->die ("couldn't open `named.conf'");

	$acl = $conf->new_acl (
		NAME		=> 'extremix.net-slaves',
		ELEMENTS	=> [ qw (10.0.0.2 10.0.0.3) ],
	) or $acl->die ("couldn't create acl `extremix.net-slaves'");

	$comment = $conf->new_comment (
		COMMENT		=> '// Elements of this Acl are allowed to transfer this zone',
		WHERE		=> 'BEFORE',
		WARG		=> $acl,
	) or $comment->die ("couldn't create comment");

This class is not meant to be used directly, but is used instead by the
parser to store intra directive comments.

=head1 METHODS

=cut

package Unix::Conf::Bind8::Conf::Comment;

use strict;
use warnings;
use base qw (Unix::Conf::Bind8::Conf::Directive);

=over 4

=item new ()

 Arguments
 COMMENT	=> 'comment',
 WHERE  => 'FIRST'|'LAST'|'BEFORE'|'AFTER'
 WARG   => Unix::Conf::Bind8::Conf::Directive subclass object
                        # WARG is to be provided only in case WHERE eq 'BEFORE 
                        # or WHERE eq 'AFTER'
 PARENT	=> reference,   # to the Conf object datastructure. 

Class constructor
Creates a Unix::Conf::Bind8::Conf::Comment object and returns it,
on success, an Err object otherwise. Do not use this constructor directly.
Use the Unix::Conf::Bind8::Conf::new_comment method () instead.

=cut

sub new
{
	my $self = shift ();
	my $new = bless ({});
	my %args = @_;
	my $ret;

	return (Unix::Conf->_err ('new', "PARENT not defined"))
		unless ($args{PARENT});
	$ret = $new->_parent ($args{PARENT})		or return ($ret);
	$ret = $new->comment ($args{COMMENT})		or return ($ret)
		if ($args{COMMENT});	
	$args{WHERE} = 'LAST'			unless ($args{WHERE});
	$ret = Unix::Conf::Bind8::Conf::_insert_in_list ($new, $args{WHERE}, $args{WARG})
		or return ($ret);
	return ($new);
}

=item comment ()

Object method.
Get/set the comment. If argument is passed, sets the comment, and returns
true on success, an Err object otherwise. If no argument is passed, returns
the set value.

=cut

sub comment
{
	my ($self, $comment) = @_;

	if ($comment) {
		$self->_rstring (\$comment);
		return (1)
	}
	return (${$self->_rstring ()});
}

sub __render
{
	return (1);
}

1;
