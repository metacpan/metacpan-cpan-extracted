package Gnus::Newsrc;

=head1 NAME

Gnus::Newsrc - parse ~/.newsrc.eld files

=head1 SYNOPSIS

  $newsrc = Gnus::Newsrc->new;
  ($level, $read, $marks, $server, $group_para) =
     @{$newsrc->alist_hash->{"comp.lang.perl.misc"}};

=head1 DESCRIPTION

The C<Gnus::Newsrc> objects represents the content of the ~/newsrc.eld
files that the Gnus newsreader use to store away its state.

The following methods are provided:

=over 4

=cut

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use Lisp::Reader qw(lisp_read);



=item $newsrc = Gnus::Newsrc->new( [$filename] )

The object constructor takes an optional filename as argument.  The
file defaults to F<~/.newsrc.eld>.  It will read and parse the file
and return a reference to a C<Gnus::Newsrc> object.  The constructor
will croak if the file can't be found or can't be parsed.

=cut

sub new
{
    my($class, $file) = @_;
    $file = "$ENV{HOME}/.newsrc.eld" unless defined $file;
    local($/) = undef;  #slurp;
    open(LISP, $file) || die "Can't open $file: $!";
    my $lisp = <LISP>;
    close(LISP);

    local $Lisp::Reader::SYMBOLS_AS_STRINGS = 1;  # gives quicker parsing
    my $form = lisp_read($lisp);

    my $self = bless {}, $class;

    for (@$form) {
	my($one,$two,$three) = @$_;
	#print join(" - ", map {$_->name} $one, $two), "\n";
	if ($one eq "setq") {
	    if (ref($three) eq "ARRAY") {
		my $first = $three->[0];
		if ($first eq "quote") {
		    $three = $three->[1];
		}
	    }
	    $self->{$two} = $three;
	} else {
	    warn "$_ does not start with (setq symbo ...)\n";
	}
    }

    # make the 'gnus-newsrc-alist' into a more perl suitable structure
    for (@{$self->{'gnus-newsrc-alist'}}) {
	my($group, $level, $read, $marks, $server, $para) = @$_;

	for ($read, $marks, $para) {
	    $_ = [] unless defined;
	}
	$_->[2] = join(",", map {ref($_)?"$_->[0]-$_->[1]":$_} @$read);
	$_->[3] = @$marks ?
                     { map {shift(@$_) =>
		            join(",", map {ref($_)?"$_->[0]-$_->[1]":$_}@$_)}
                      @$marks
                     }
                  : undef;
	$_->[5] = @$para ? { map { $_->[0] => $_->[1] } @$para } : undef;

	# trim trailing undef values
	pop(@$_) until defined($_->[-1]) || @$_ == 0;
    }

    $self;
}



=item $newsrc->file_version

Return the version number found in the file
I<(gnus-newsrc-file-version)>.  The version number is a string like
C<"Gnus v5.5">.

=cut

sub file_version
{
    shift->{"gnus-newsrc-file-version"};
}



=item $newsrc->last_checked_date

Returns a string like C<"Sat Oct 18 14:05:53 1997">
I<(gnus-newsrc-last-checked-date)>.

=cut

sub last_checked_date
{
    shift->{"gnus-newsrc-last-checked-date"};
}



=item $newsrc->alist

Returns a reference to an array that will have one element for each
active newsgroup I<(gnus-newsrc-alist)>.  Each element is a array with
the following values:

   $group_name
   $group_level
   $read_articles
   \%marks
   \@server
   \%group_parameters

The C<$read_articles> and C<%marks> values is a string of integer
ranges, and it is suitable for initializing a C<Set::IntSpan> objects.

=cut

sub alist
{
    shift->{"gnus-newsrc-alist"};
}



=item $newsrc->alist_hash

Returns a reference to a hash indexed by group names.  The hash values
are the same as the C<alist> elements, but the C<$group_name> is
missing.

=cut

sub alist_hash
{
    my $self = shift;
    unless ($self->{'_alist_hash'}) {
	my %ahash;
	$self->{'_alist_hash'} = \%ahash;
	for (@{$self->alist}) {
	    my @groupinfo = @$_;
	    my $group = shift @groupinfo;
	    $ahash{$group} = \@groupinfo;
	}
    }
    $self->{'_alist_hash'};
}



=item $newsrc->server_alist

I<(gnus-server-alist)>.

=cut

sub server_alist
{
    shift->{"gnus-server-alist"};

}



=item $newsrc->killed_list

A reference to an array that contains all the killed newsgroups I<(gnus-killed-list)>.

=cut

sub killed_list
{
    shift->{"gnus-killed-list"};
}



=item $newsrc->zombie_list

A reference to an array that contains all zombie newsgroups
I<(gnus-zombie-list)>.

=cut

sub zombie_list
{
    shift->{"gnus-zombie-list"};
}



=item $newsrc->format_specs

=cut

sub format_specs
{
    shift->{"gnus-format-specs"};
}


1;
__END__


=back

=head1 SEE ALSO

L<Set::IntSpan>, http://www.gnus.org

=head1 COPYRIGHT

Copyright 1997 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

