package Test::Legal;
use v5.10;
use Data::Dumper;
use strict;
use warnings;
our $VERSION = '0.10';
use Sub::Exporter;

use CPAN::Meta;
#use Data::Show;
use File::Find::Rule;
use List::Util 'first';
use Log::Log4perl ':easy';
use List::Compare;
use IO::Prompter;
use Test::Builder::Module;
use Test::Legal::Util qw/ annotate_copyright   deannotate_copyright load_meta write_LICENSE /;


use Sub::Exporter -setup => { exports => [ qw/ disable_test_builder annotate_dirs deannotate_dirs/, 
 										  copyright_ok => \'_build_copyright_ok' ,
                                           license_ok   => \'_build_license_ok'],
                              groups  => { default => [qw/ copyright_ok license_ok /],
                                           core    => [qw/ copyright_ok license_ok /]
                                         },
		                      collectors => [qw/ defaults /]
}; 
use constant DEFAULTS =>  { base      => '.',
                            dirs      => [ qw/ lib script /],
};
my $tb = new Test::Builder ;
END   { $tb->done_testing; }

=pod 

=head1 NAME

Test::Legal -  Test and (optionally) fix copyright notices, LICENSE file, and relevant field of META file

=head1 SYNOPSIS

  use Test::Legal;         

  copyright_ok;
  license_ok;

  # Or, to fix things at the same time
  use Test::Legal  -core  => { actions =>['fix']};


  # Here is the more refined way to acomplish the same thing
  use Test::Legal  copyright_ok => {  dirs=> [qw/ sctipt lib /] } ,
                   'license_ok' ,
                   defaults     => { base=> $dir, actions => [qw/ fix /]}
  ;


  # Note,  The  "actions=>['fix']"  automatically fixes things so it can pass testing
 


=head1 DESCRIPTION

   Checks for (a) copyright notices in .pl and .pm distribution files; (b) for author entry 
 in META.yml or META.json, which ever peresent; and (c) for existence of LICENSE file, with the
 correct license text autogenerate if so desired.

   Although you can alwyas add copyright notices manually to files, Test::Legal can fix things
 for you if operated in 'fix' mode (see bellow); alternatively, use the tools available in
 script/ named copyright-injection.pl an license-injection.pl .

=head2 Fix mode

 When "fix" mode is requested, most issues are automatically fixed so testing succeeds 
 with a harmless note() send to Test::Harness. 

=head1 FUNCTIONS

=head2  disable_test_builder

=cut
sub disable_test_builder { 
	sub ok{}; sub done_testing{}; $tb=bless{} 
}
=pod

=head2  _values

=cut
sub _values {
    my ($arg, $defaults) = @_;
	$arg //= {}; $defaults //= {};
    return unless ref $arg      eq 'HASH';	
    return unless ref $defaults eq 'HASH';	
    $arg = { %{DEFAULTS()}, %$defaults, %$arg };
    ($arg->{ meta }) = load_meta($arg->{base}) || die 'no META file in dir "'. $arg->{base}.qq("\n);
    $arg;
}
=head2  _in_mode

 Assumptions: $arg exists and has been validated
 Input: the user arguments (a hashref)
 Output: TRUE if "dry" mode was specified, otherwise FALSE

=cut
sub _in_mode {
    my ($arg,$mode) = @_;
	return unless $mode;
    return unless ref $arg eq 'HASH';	
	return unless exists $arg->{actions};
	first {$_ =~ /^$mode$/i}  @{$arg->{actions}};
}
=pod

=head2 set_of_files
=cut
sub set_of_files {
	my ($pat, @dirs) =  @_;
	$pat //= 'Copyright (C)';
	$pat = qr/\Q$pat\E/i;
	my @all_files = File::Find::Rule->file->name(qr/.*(\.pm|\.pl)$/o)->in(@dirs);
	my @copyrighted = File::Find::Rule->file->name(qr/.*(\.pm|\.pl)$/o)-> grep($pat)->in(@dirs);
	List::Compare->new( \@all_files, \@copyrighted);
}
=pod

=head2  annotate_dirs
=cut
sub annotate_dirs {
	my ($pat, @dirs) =  @_;
	my $l = set_of_files ($pat, @dirs) ;
	my @without_c =  $l->get_unique  ;
	return (0,0) unless @without_c;
	DEBUG "Without copyright:\n\t" . join "\n\t", @without_c ;
	unless ($::opts->{yes}) {
		return (0,scalar @without_c) unless (prompt '-yes', 'Add copyright to all files that need it?') ;
	}
	DEBUG "Updating...";
	my $num = annotate_copyright(\@without_c, $pat) || 0;
	#verify
	$l = set_of_files ($pat, @dirs) ;
	my @remain = $l->get_unique; 
	DEBUG "Remain without copyrigh:\n\t" . join "\n\t", @remain  if @remain;
	($num, scalar @remain);
}
=pod

=head2  deanntate_dirs
=cut
sub deannotate_dirs {
	my ($pat, @dirs) =  @_;
	my $l = set_of_files ($pat, @dirs) ;
	my @with_c =  $l->get_intersection  ;
	return (0,0) unless @with_c;
	DEBUG "Have copyright:\n\t" . join "\n\t", @with_c ;
	unless ($::opts->{yes}) {
		return (0, scalar @with_c) unless (prompt '-yes', 'Remove copyright from all files?') ;
	}
	DEBUG "Updating...";
	my $num = deannotate_copyright(\@with_c, $pat) || 0;
	#verify
	$l = set_of_files ($pat, @dirs) ;
	my @remain = $l->get_intersection ;
	DEBUG "Remain copyrighted:\n\t" . join "\n\t", @remain  if @remain;
	($num, scalar @remain);
}
=pod

=head2  _build_copyright_ok
=cut
sub _build_copyright_ok {
    my ($class, $fun, $arg, $defaults) = @_;
    $arg = _values($arg, $defaults->{defaults});  # keys : base, dirs , meta
    my @dirs   = map {$arg->{base} . "/$_"} @{$arg->{dirs}};
    sub {
	    return ('noop', $arg)  if _in_mode($arg,'noop');
		my $pat = shift;
		$pat //= 'Copyright (C)';
        my $l= set_of_files($pat, @dirs);
		if( (_in_mode($arg,'fix')) && ($l->get_unique) ) {
			# fix them by adding copyright notices
			$tb->note( 'adding Copyright notices' )  if annotate_copyright([$l->get_unique],undef);
			# re-scan for files without copyright
			$l= set_of_files($pat, @dirs);
		}
        $tb->ok( 0, $_ ) for  $l->get_unique ;
        $tb->ok( 1, $_ ) for  $l->get_intersection;
		$l->get_unique;
    }
}
=pod

=head2  _build_license_ok
=cut
sub _build_license_ok {
    my ($class, $fun, $arg, $defaults) = @_;
    $arg = _values($arg, $defaults->{defaults});  # keys : base, dirs , meta
    sub {
	    return ('noop', $arg)  if _in_mode($arg,'noop');
        my $has_file =  -f $arg->{base}.'/LICENSE' ;
		# attempt to fix?
	    if ((_in_mode($arg,'fix')) && (!$has_file)) {
			$tb->note( 'added LICENSE' )  if  write_LICENSE($arg->{base}); 
		}
        $tb->ok( -f $arg->{base}.'/LICENSE', 'dist contains LICENSE file');
        $tb->ok( @{[$arg->{meta}->license]} > 0 , 'META mentions license');
    }
}
1;
=pod

=head1 EXPORT

    copyritht_ok;
    legal_ok;

=head1 EXPORT_OK

    disable_test_builder 
	annotate_dirs 
    deannotate_dirs

=head1 SEE ALSO

 copyright_injection.pl  ( provided with Test::Legal )

 Test::Copyright

=head1 AUTHOR

Tambouras, Ioannis E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
