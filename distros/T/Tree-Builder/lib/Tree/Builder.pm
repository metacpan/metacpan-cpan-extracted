package Tree::Builder;

use warnings;
use strict;

=head1 NAME

Tree::Builder - Takes path like strings and builds a tree of hashes of hashes.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Tree::Builder;

    my $tb = Tree::Builder->new();

    $tb->add('a/b/c');
    $tb->add('some/thing');
    $tb->add('a/some/thing');

    my %tree=$tb->getTree;

    print $tb->getSeperator;

    $tb->setSeperator('\.');

    $tb->add('what.ever');

    #prints it using Data::Dumper
    use Data::Dumper;
    print Dumper(\%tree);


=head1 METHODS

=head2 new

This initializes the object.

=head3 args hash ref

=head4 seperator

This is the seperator, regexp, to use for breaking a string down
and hadding it to the tree.

If not specified, the default is '\/'.

Be warned, this is a regular expression, so if you don't want it to
act as such, you will want to use quotemeta.

    #initiates it with the defaults
    my $tb=Tree::Builder->new;

    #initiaties it with a seperator of .
    my $tb=Tree::Builder->new({seperator=>'\.'});

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	if (defined($args{seperator})) {
	}

	my $self={error=>undef, errorString=>undef, tree=>{}};
	bless $self;

	if (!defined($args{seperator})) {
		$self->{seperator}='/';
	}else {
		$self->{seperator}=$args{seperator};
	}

	return $self

}

=head2 add

This adds a new item to the tree.

In regards to error checking, there is no need to check this for
errors as long as you make sure that the string passed to it is
defined.

    $tb->add("some/thing");
    if($tb->{error}){
        print "Error!\n";
    }

=cut

sub add{
	my $self=$_[0];
	my $item=$_[1];

	$self->errorblank;

	if (!defined($item)) {
		$self->{error}=2;
		$self->{errorString}="Item is not defined";
		warn('Tree-Builer add:'.$self->error.': '.$self->errorString);
		return undef;
	}

	my @itemA=split(/$self->{seperator}/, $item);

	#this initializes the first part of the tree
	if (!defined($self->{tree}{$itemA[0]})) {
		$self->{tree}{$itemA[0]}={};
	}

	#if item does not exist, return
	if (!defined($itemA[1])) {
		return 1;
	}

	my %newhash=%{$self->{tree}{$itemA[0]}};

	my %newhash2=$self->addSub(\%newhash, \@itemA, 1);

	$self->{tree}{$itemA[0]}=\%newhash2;

	return 1;
}

=head2 addSub

This is a internal function.

=cut

sub addSub{
	my $self=$_[0];
	my %hash=%{$_[1]};
	my @itemA=@{$_[2]};
	my $int=$_[3];

	#return the hash if none others are defined
	if (!defined($itemA[$int])) {
		return %hash;
	}

	#add a new hash if it does not already exist
	if (!defined($hash{$itemA[$int]})) {
		$hash{$itemA[$int]}={};
	}

	my %newhash=%{$hash{$itemA[$int]}};
	my $newint=$int + 1;

	my %newhash2=$self->addSub(\%newhash, \@itemA, $newint);

	$hash{$itemA[$int]}=\%newhash2;

	return %hash;
}

=head2 getSeperator

This gets the current seperator being used.

Error checking does not need to be done on this.

    my $seperator=$tb->getSeperator;

=cut

sub getSeperator{
	return $_[0]->{seperator};
}

=head2 getTree

This fetches the tree.

    my %hash=$tb->getTree;

=cut

sub getTree{
	return %{$_[0]->{tree}};
}

=head2 setSeperator

As long as this is defined, there is no need to check if it errored or not.

    $tb->setSeperator('\/');
    if($tb->{error}){
        print "Error!\n";
    }

=cut

sub setSeperator{
	my $self=$_[0];
	my $seperator=$_[1];

	$self->errorblank;

	if (!defined($seperator)) {
		$self->{error}=1;
		$self->{errorString}='No seperator specified';
		warn('Tree-Builder setSeperator:'.$self->error.': '.$self->errorString);
		return undef;
	}

	$self->{seperator}=$seperator;

	return 1;
}

=head1 ERROR RELATED METHODS

=head2 error

Returns the current error code and true if there is an error.

If there is no error, undef is returned.

    if($tb->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub error{
    return $_[0]->{error};
}

=head2 errorString

Returns the error string if there is one. If there is not,
it will return ''.

    if($tb->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub errorString{
    return $_[0]->{errorString};
}

=head2 errorblank

This is a internal function.

=cut

sub errorblank{
	$_[0]->{error}=undef;
	$_[1]->{errorString}='';
}

=head1 ERROR CODES

As all error codes are positive, $tb->error can be checked to see if it
is true and if it is, then there is an error.

=head2 1

No seperator specified.

=head2 2

Item to add not defined.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tree-builder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tree-Builder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tree::Builder


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-Builder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tree-Builder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tree-Builder>

=item * Search CPAN

L<http://search.cpan.org/dist/Tree-Builder/>

=back


=head1 ACKNOWLEDGEMENTS

Emanuele, #69928, for pointing out the crappy docs for 0.0.0

=head1 COPYRIGHT & LICENSE

Copyright 2011 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Tree::Builder
