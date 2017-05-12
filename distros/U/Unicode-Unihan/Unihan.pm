package Unicode::Unihan;

use 5.008001;
use strict;
use warnings;

our $VERSION = do { my @r = (q$Revision: 0.4 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
our $DEBUG = 0;

use Carp;
BEGIN{  @AnyDBM_File::ISA = qw(DB_File GDBM_File SDBM_File) ; }
use AnyDBM_File;
use Fcntl;

sub new($;){
    my $class = shift;
    my $dir = __FILE__; $dir =~ s/\.pm//o;
    -d $dir or die "DB Directory $dir nonexistent!";
    return bless { '_dir_' => $dir, @_ } => $class;
}

sub load($$){
    my ($self, $name) = @_;
    if ($self->{'-savemem'}){
	for my $k (keys %$self){
	    $k eq $name and next;
            $k =~ /^[A-Z]/o and delete $self->{$k};
        }
    }
    unless ( $self->{$name} ){
	my $file = $self->{_dir_} . "/$name.db";
	-f $file or croak "There is no DB for $name";
	tie %{$self->{$name}}, 'AnyDBM_File', $file, O_RDONLY, 0444
            or die "$file: $!";
    }
    $self;
}

sub unload($;){
    my $self = shift;
    if (@_){
	while(my $k = shift) {
	    $k =~ /^[A-Z]/o and delete $self->{$k};
	}
    }else{
	for my $k (keys %$self){
	    $k =~ /^[A-Z]/o and delete $self->{$k};
	}
    }
    $self;
}

sub DESTROY {
    $DEBUG and warn "$_[0] destroyed!";
}

sub AUTOLOAD {
    my $self = shift;
    my $name = our $AUTOLOAD;
    $name =~ s/.*:://o;
    $self->load($name);
    no strict 'refs';
    *$AUTOLOAD = sub { 
	my $self = shift; @_ or return;
	my $str = shift;  length($str) or return;
	if (wantarray){
	    my @result = ();
	    for my $ord (unpack("U*", $str)){
		push @result, $self->{$name}{$ord};
	    }
	    return @result;
	}else{
	    return $self->{$name}{ord($str)};
	}
    };
    return $self->$name(@_);
}

1;
__END__

# Below is stub documentation for your module. You'd better edit it!

=encoding utf8

=head1 NAME

Unicode::Unihan - The Unihan Data Base 5.1.0

=head1 SYNOPSIS

  use Unicode::Unihan;
  my $uh = Unicode::Unihan->new;
  print join("," => $uh->Mandarin("\x{5c0f}\x{98fc}\x{5f3e}")), "\n";

=head1 ABSTRACT

This module provides a user-friendly interface to the Unicode Unihan
Database 5.1.  With this module, the Unihan database is as easy as
shown in the SYNOPSIS above.

=head1 DESCRIPTION

The first thing you do is make the database available.  Just say

  use Unicode::Unihan;
  my $uh = new Unicode::Unihan;

That's all you have to say.  After that, you can access the database
via $uh-E<gt>I<tag>($string) where I<tag> is the tag in the Unihan
Database, without 'k' prefix.

=over 2

=item $data = $uh-E<gt>I<tag>($string)

=item @data = $uh-E<gt>I<tag>($string)

The first form (scalar context) returns the Unihan Database entry of
the first character in $string.  The second form (array context)
checks the entry for each character in $string.

  @data = $uh->Mandarin("\x{5c0f}\x{98fc}\x{5f3e}");
  # @data is now ('SHAO4 XIAO3','SI4','DAN4')

  @data = $uh->JapaneseKun("\x{5c0f}\x{98fc}\x{5f3e}");
  # @data is now ('CHIISAI KO O','KAU YASHINAU','TAMA HAZUMU HIKU')

=back

=head1 FIELDS AND THEIR MEANINGS

For a complete list of tags, their meaning, and information on parsing
the value field, see L<http://www.unicode.org/reports/tr38/>.

=head1 SEE ALSO

=over 2

=item L<perlunintro>

=item L<perlunicode>

=item The Unihand Database

L<http://www.unicode.org/Public/UNIDATA/Unihan.html>

=back

=head1 AUTHOR

=over 2

=item of the Module

Dan Kogai E<lt>dankogai@dan.co.jpE<gt>

=item of the Source Data

Unicode, Inc.

=back

=head1 COPYRIGHT AND LICENSE

=over 2

=item of the Module

Copyright 2002-2008 by Dan Kogai, All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=item of the Source Data

Copyright (c) 1996-2008 Unicode, Inc. All Rights reserved.

       Name: Unihan database
       Unicode version: 5.1.0
       Table version: 1.1
       Date: 3 March 2008

=back
