#!/usr/bin/perl
BEGIN { require $_.".pm" && $_->import for qw(strict warnings) }
# vim=:SetNumberAndWidth
=encoding utf-8

=head1 NAME

Xporter - Alternative Exporter with persistant defaults & auto-ISA

=head1 VERSION

Version "0.1.1"

=cut

{ package Xporter;
	BEGIN { require $_.".pm" && $_->import for qw(strict warnings) }
	our $VERSION='0.1.2';
	our @CARP_NOT;
	use mem(@CARP_NOT=(__PACKAGE__));
	# 0.1.2	 - Bad version check found in self-testing;
	#          Added test against 4 version formats
	# 0.1.1  - Bad use of modern proptype (_) for old perls
	# 0.1.0  - Bugfix: only match user input after stripping sigels or "nots" (!^-)
	#        - Feature addition, in addition to a global, (solo) 'not'
	#          at the beginning of a list to zero the default exports,
	#          individual items in EXPORTS can be excluded by prefixing them
	#          with a negating prefix (!^-);
	#        - Added new test case for specific exclusion
	#        - NOTE: blocking an export will ignore type as will asking for a non-dflt
	# 0.0.14 - Documentation update
	# 0.0.13 - Bug fix in string version compare -- didn't add leading
	#          zeros for numeric compares;
	# 0.0.12 - Add version tests to test 3 forms of version: v-string,
	# 				 numeric version, and string-based version.
	# 				 If universal method $VERSION doesn't exist, call our own
	# 				 method.
	# 0.0.11 - Add a Configure_depends to see if that satisfies the one 
	#          test client that is broken (sigh)
	# 0.0.10 - Remove P from another test (missed one);  Having to use
	#         replacement lang features is torture  on my RSI
	# 0.0.9 - add alternate version format for ExtMM(this system sucks)
	#       - remove diagnostic messages from tests (required P)
	# 0.0.8 - add current dep for BUILD_REQ of ExtMM
	# 0.0.7 - 'require' version# bugfix
	# 0.0.6 - comment cleanup; Change CONFIGURE_REQUIRES to TEST_REQUIRES
	# 0.0.5 - export inheritance test written to highlight a problem area
	# 			- problem area addessed; converted to use efficient jump table
	#	0.0.4 - documentation additions;
	#				- added tests & corrected any found problems
	#	0.0.3 - added auto-ISA-adding (via push) when this mod is used.
	#	      - added check for importing 'import' to disable auto-ISA-add
	# 0.0.2	- Allow for "!" as first arg to import to turn off default export
	# 				NOTE: defaults are defaults when using EXPORT_OK as well;
	# 							One must specifically disable defaults to turn them off.
	# 0.0.1	- Initial split of code from iomon
	#
	#require 5.8.0;
	
	# Alternate export-import method that doesn't undefine defaults by 
	# default

	sub add_to_caller_ISA($$) {
		my ($pkg, $caller) = @_;
			
		if ($pkg eq __PACKAGE__) { no strict 'refs';
			unshift @{$caller."::ISA"}, $pkg unless grep /$pkg/, @{$caller."::ISA"};
		}
	}

	# adapted from Core::Types to avoid circular include
	sub _EhV($*) {	my ($arg, $field) = @_;
		(ref $arg && 'HASH' eq ref $arg) && 
			defined $field && exists $arg->{$field} ?  $arg->{$field} : undef
	}

	sub cmp_ver($$) {
		my ($v1, $v2) = @_;
		for (my $i=0; $i<@$v2 && $i<@$v1; ++$i) {
			my ($v1p, $v1_num, $v1s) = ($v1->[$i] =~ /^([^\d]*)(\d+)([^\d]*)$/);
			my ($v2p, $v2_num, $v2s) = ($v2->[$i] =~ /^([^\d]*)(\d+)([^\d]*)$/);
			my $maxlen = $v1_num > $v2_num ? $v1_num : $v2_num;
			my $r =	sprintf("%s%0*d%s", $v1p||"", $maxlen, $v1_num, $v1s||"") cmp
							sprintf("%s%0*d%s", $v2p||"", $maxlen, $v2_num, $v2s||"");
			return -1 if $r<0;
			return 0 if $r>0;
		}
		return 0;
	}


	sub _version_specified($$;$) {
		my ($pkg, $requires) = @_;
		my $pkg_ver;
		{	no strict 'refs';
			$pkg_ver = ${$pkg."::VERSION"} || '(undef)';
		}
		my @v1=split /_|\./, $pkg_ver;
		my @v2=split /_|\./, $requires;
		if (@v1>2 || @v2>2) {
			return if cmp_ver(\@v1, \@v2) >= 0;
		} else {
			return if $pkg_ver && ($pkg_ver cmp $requires)>=0;
			return if $pkg_ver ne '(undef)' && $pkg_ver >= $requires;
		}
		require Carp; 
		Carp::croak(sprintf "module %s %s required. This is only %s", 
												$pkg, $requires, $pkg_ver);
	}


	our %exporters;


	our $tc2proto = {'&' => '&', '$'	=> '$', '@' => '@', '%'	=> '%', 
									 '*' => '*', '!'	=> '!', '-' => '!', '^'	=> '!'};

	sub list(;*) { return  @_ }

	sub op_prefix;
	sub op_prefix {
		return ($_, undef) unless $_;
		my $type = substr $_, 0, 1;
		my $mapped_op = _EhV $tc2proto, $type;
		if ($mapped_op) {
			$_ = substr($_,1);
			if ($mapped_op eq '!') {
				($_, $type, undef ) = op_prefix()  }
		} elsif ($type =~ /\w/) { $mapped_op=$type='&' }
		($_, $type, $mapped_op);
		
	}
	sub import { 
		my $pkg			= shift;
		my ($caller, $fl, $ln)	= (caller);
		no strict 'refs';


		#*{$caller."::import"}= 
		#\&{__PACKAGE__."::import"} if !exists ${$caller."::import"}->{CODE};

		if (@_ && $_[0] && $_[0] =~ /^(v?[\d\._]+)$/) {
			my @t=split /\./, $_[0];
			no warnings;
			if ($pkg->can("VERSION") && @t<3 && $1 ) { 
				$pkg->VERSION($1) }
			else {
				_version_specified($pkg, $1); }
			shift;
		}

		if ($pkg eq __PACKAGE__) {		# we are exporting
			if (@_ && $_[0] eq q(import)) {
				no strict q(refs);
				*{$caller."::import"} = \*{$pkg."::import"};
			} else {
				add_to_caller_ISA($pkg, $caller);
			}
			$exporters{$caller} = 1;
			return 1;
		}

		my ($export, $exportok, $exporttags);

		{ no strict q(refs);
			$export = \@{$pkg."::"."EXPORT"} || [];
			$exportok = \@{$pkg."::"."EXPORT_OK"} || [];
			$exporttags = \%{$pkg."::"."EXPORT_TAGS"};
		}
		
		my @allowed_exports = (@$export, @$exportok);

		if (@_ and $_[0] and  $_[0] eq '!' 	|| $_[0] eq '-' ) {
			printf("Export RESET\n");
			$export=[];
			shift @_;
		}

		for my $pat (@_) { 															# filter individual params
			$_ = $pat;																		# passed to op_prefix
			my ($name, $type, $mapped_op ) = op_prefix();
			if ($mapped_op eq '!') {
				if (grep /$name/,  @$export) {
					my @new_export = grep { !/$name/ } @$export;
					$export=\@new_export;
				}
			} elsif (grep /$name/,  @allowed_exports) {
				#printf("allowing export of %s\n", $pat);
				push @$export, $pat ;
			} 
		}


		for(@$export) {
			my ($type, $mapped_op);
			#printf("_=%s:", $_||"undef");
			($_, $type, $mapped_op) = op_prefix;
			#printf("_=%s, t=%s, mapped=%s\n", $_||"undef", $type||"undef", $mapped_op||"undef");
			if ($mapped_op) { 
				print "skip exp of $_\n" if $mapped_op eq '!';
				next if $mapped_op eq '!'; 
			} else { 
				require Carp; 
				Carp::croak("Unknown type ". ($type||"(undef)") . " in " . ($_||"(undef)")); 
			}
			my $colon_name	= "::" . $_ ;
			my ($exf, $imf)	= ( $pkg . $colon_name, $caller . $colon_name);
			no strict q(refs);
			my $case = {
				'&'	=>	\&$exf,
				'$'	=>	\$$exf,
				'@' =>	\@$exf,
				'%' =>	\%$exf,
				'*'	=>	 *$exf};
			*$imf = $case->{$type};
		}
	}
1}


=head1 SYNOPIS

In the "Exporting" module:

  { package module_adder [optional version]; 
	  use warnings; use strict;
    use mem;			# to allow using module in same file
    our (@EXPORT, @EXPORT_OK);
    our $lastsum;
    our @lastargs;
    use Xporter(@EXPORT=qw(adder $lastsum @lastargs), 
            		@EXPORT_OK=qw(print_last_result));

    sub adder($$) {@lastargs=@_; $lastsum=$_[0]+$_[1]}
    sub print_last_result () {
      use P;    # using P allows answer printed or as string
      if (@lastargs && defined $lastsum){
        P "%s = %s\n", (join ' + ' , @lastargs), $lastsum;
      }
    }
  }

In C<use>-ing module (same or different file)

  package main;  use warnings; use strict;
  use module_adder qw(print_last_result);

  adder 4,5;

Printing output:

  print_last_result();

  #Result:
  
  4 + 5 = 9

(Or in a test:)
	
  ok(print_last_result eq "4 + 5 = 9", "a pod test");

=head1 DESCRIPTION

C<Xporter>  provides  C<EXPORT>  functionality similar to  L<Exporter>  with
some different rules to simplify common cases.

The primary difference, in  C<Xporter>  is that the default  C<EXPORT>  list
remains the default  C<EXPORT>  list unless the user specifically asks for it
to not be included, whereas in L<Exporter>, asking for any additional
exports from the  C<EXPORT_OK>  list, clears the default  C<EXPORT>  list.

C<Xporter>  makes it easy to reset or clear the default so that choice
is left to the user. 

To reset the default  C<EXPORT>  list to empty, a bare I<minus> ('-') or
I<logical-not> sign ('!') is placed as the first parameter in the client's import
list. 

=head3 Example

Suppose a module has exports:

  our (@EXPORT, @EXPORT_OK);
  use Xporter(@EXPORT=qw(one $two %three @four), 
              @EXPORT_OK=qw(&five));

In the using module, to only import symbols 'two' and 'five', 
one would use:

=head3 Example

  use MODULENAME qw(! $two five);

That negates the default C<EXPORT> list, and allows selective import
of the values wanted from either,  the default  C<EXPORT>  or the
C<EXPORT_OK> lists.  I<Note:>  modules in the default list don't need 
to be reiterated in the OK list as they are already assumed to be
"OK" to export having been in the default list.

(New in 0.1) It is also possible to negate only 1 item from the 
default C<EXPORT> list, as well as import optional symbols in 
1 statement.  

=head3 Example

  use MODULENAME qw(!$two five);      #or
  use MODULENAME qw(!two five);

Only export C<two> from the default export list will be 
excluded.  Whereas export C<five> will be added to the list
of items to import.

Other functions of Exporter are not currently implemented, though
certainly requests and code donations made via the CPAN issue database 
will be considered if possible.

=head2 Types and Type Export 

Listing the EXPORT and EXPORT_OK assignments as params to Xporter will
allow their types to be available to importing modules at compile time.
the L<mem> module was provided as a generic way to force declarations
into memory during Perl's initial BEGIN phase so they will be in effect
when the program runs.

=head2 Version Strings

Version strings in the form of a decimal fraction, (0.001001), a
V-String (v1.2.1 with no quotes), or a version string
('1.1.1' or 'v1.1.1') are supported, though note, versions in
different formats are not interchangeable.  The format specified
in a module's documentation should be used.






