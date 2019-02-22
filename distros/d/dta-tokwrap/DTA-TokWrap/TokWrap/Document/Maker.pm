## -*- Mode: CPerl -*-

## File: DTA::TokWrap::Document.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: document wrapper: pseudo-make

package DTA::TokWrap::Document::Maker;
use DTA::TokWrap::Version;
use DTA::TokWrap::Document;
use DTA::TokWrap::Utils qw(:time :files);

##==============================================================================
## Globals
##==============================================================================
our @ISA = qw(DTA::TokWrap::Document);

##==============================================================================
## Constructors etc.
##==============================================================================

## $doc = CLASS_OR_OBJECT->new(%args)
##  + additional %args, %$doc:
##    ##-- pseudo-make options
##    force     => \@keys,  ##-- force re-generation of all dependencies for @keys
##
##    ##-- timestamp data
##    "${key}_stamp"   => $stamp,   ##-- timestamp for data keys; see keyStamp() method
##    "${proc}_stamp0" => $stamp0,  ##-- begin timestamp for process keys
##    "${proc}_stamp"  => $stamp0,  ##-- end timestamp for process keys
#(inherited from DTA::TokWrap::Base via DTA::TokWrap::Document)

## %defaults = CLASS->defaults()
sub defaults {
  return (
	  ##-- inherited defaults
	  $_[0]->SUPER::defaults(),

	  ##-- pseudo-make options
	  #force => 0,
	  #traceMake => 'trace',
	  #traceGen => 'trace',
	  #genDummy => 0,
	 );
}

## $doc = $doc->init()
##  + set computed defaults
sub init {
  my $doc = shift;

  ##-- inherited initialization
  $doc->SUPER::init() || return undef;

  ##-- defaults: pseudo-make
  if ($doc->{tw}) {
    ##-- propagate from $doc->{tw} to $doc, if available & not overridden
    $doc->{force} = $doc->{tw}{force} if (exists($doc->{tw}{force}) && !exists($doc->{force}));
    $doc->{genDummy} = $doc->{tw}{genDummy} if (exists($doc->{tw}{genDummy}) && !exists($doc->{genDummy}));
  }

  ##-- init: forced remake
  if ($doc->{force}) {
    $doc->{force} = [$doc->{force}] if (!UNIVERSAL::isa($doc->{force},'ARRAY'));
    $doc->forceStale($doc->keyDeps(@{$doc->{force}}),@{$doc->{force}});
  }

  ##-- return
  return $doc;
}

##==============================================================================
## Methods: Pseudo-make: Dependency Tracking
##==============================================================================

##--------------------------------------------------------------
## Methods: Pseudo-make: Dependency Tracking: Initialization

## %KEYGEN = ($dataKey => $generatorSpec, ...)
##  + maps data keys to the generating processes (subroutines, classes, ...)
##  + $generatorSpec is one of:
##     $key      : calls $doc->can($key)->($doc)
##     \&coderef : calls &coderef($doc)
##     \@array   : array of atomic $generatorSpecs (keys or CODE-refs)
our %KEYGEN =
  (
   #%DTA::TokWrap::Document::KEYGEN, ##-- inherited defaults

   ##-- overrides
   xmlfile => sub { $_[0]; },
   (map {$_=>'mkindex'} qw(cxfile sxfile txfile)),
   cxdata => 'loadCxFile',
   bx0doc => 'mkbx0',
   bxdata => 'mkbx',
   bxfile  => 'saveBxFile',
   txtfile => 'saveTxtFile',
   tokdata => 'tokenize',
   tokfile => 'saveTokFile',
   xtokdata => 'tok2xml',
   xtokdoc  => 'xtokDoc',
   xtokfile => 'saveXtokFile',
   sosdoc => 'sosxml',
   sowdoc => 'sowxml',
   soadoc => 'soaxml',
   sosfile => 'saveSosFile',
   sowfile => 'saveSowFile',
   soafile => 'saveSoaFile',
   sofiles => sub { $_[0]{sofiles}=1; },
   all => sub { $_[0]{all}=1; },
  );

## %KEYDEPS = ($dataKey => \@depsForKey, ...)
##  + hash for document data dependency tracking (pseudo-make)
##  + actually tracked are "${docKey}_stamp" variables,
##    or file modification times (for file keys)
our (%KEYDEPS, %KEYDEPS_0, %KEYDEPS_H, %KEYDEPS_N);

## $cmp = PACKAGE::keycmp($a,$b)
##  + sort comparison function for data keys
sub keycmp {
  return (exists($KEYDEPS_H{$_[0]}{$_[1]}) ? 1
	  : (exists($KEYDEPS_H{$_[1]}{$_[0]}) ? -1
	     : $KEYDEPS_N{$_[0]} <=> $KEYDEPS_N{$_[1]}));
}

BEGIN {
  ##-- create KEYDEPS
  %KEYDEPS_0 = (
		xmlfile => [],  ##-- bottom-out here
		(map {$_ => ['xmlfile']} qw(cxfile txfile sxfile)),
		bx0doc => ['sxfile'],
		bxdata => [qw(bx0doc txfile)],
		(map {$_=>['bxdata']} qw(txtfile bxfile)),
		tokdata => ['txtfile'],
		tokfile => ['tokdata'],
		cxdata => ['cxfile'],
		xtokdata => [qw(cxdata bxdata tokdata)],
		xtokfile => ['xtokdata'],
		xtokdoc => ['xtokdata'],
		(map {$_=>['xtokdoc']} qw(sowdoc sosdoc soadoc)),
		(map {($_."file")=>[$_."doc"]} qw(sow sos soa)),
		sodocs  => [qw(sowdoc sosdoc soadoc)],
		sofiles => [qw(sowfile sosfile soafile)],
		##
		##-- Aliases
		tokXml      => [qw(xtokfile)],
		standoffXml => [qw(sofiles)],
		all         => [qw(xtokfile sofiles)],
	       );
  ##-- expand KEYDEPS: convert to hash
  %KEYDEPS_H = qw();
  my ($key,$deps);
  while (($key,$deps)=each(%KEYDEPS_0)) {
    $KEYDEPS_H{$key} = { map {$_=>undef} @$deps };
  }
  ##-- expand KEYDEPS_H: iterate
  my $changed=1;
  my ($ndeps);
  while ($changed) {
    $changed = 0;
    foreach (values(%KEYDEPS_H)) {
      $ndeps = scalar(keys(%$_));
      @$_{map {keys(%{$KEYDEPS_H{$_}})} keys(%$_)} = qw();
      $changed = 1 if (scalar(keys(%$_)) != $ndeps);
    }
  }
  ##-- expand KEYDEPS: sort
  %KEYDEPS_N = (map {$_=>scalar(keys(%{$KEYDEPS_H{$_}}))} keys(%KEYDEPS_H));
  while (($key,$deps)=each(%KEYDEPS_H)) {
    $KEYDEPS{$key} = [ sort {keycmp($a,$b)} keys(%$deps) ];
  }
}

##--------------------------------------------------------------
## Methods: Pseudo-make: Dependency Tracking: Utils

## @uniqKeys = uniqKeys(@keys)
sub uniqKeys {
  my %known = qw();
  my @uniq  = qw();
  foreach (@_) {
    push(@uniq,$_) if (!exists($known{$_}));
    $known{$_}=undef;
  }
  return @uniq;
}

##--------------------------------------------------------------
## Methods: Pseudo-make: Dependency Tracking: Lookup

## @deps0 = PACKAGE::keyDeps0(@docKeys)
##  + immediate dependencies for @docKeys
sub keyDeps0 {
  return uniqKeys(map { @{$KEYDEPS_0{$_}||[]} } @_);
}

## @deps = PACKAGE::keyDeps(@docKeys)
##  + recursive dependencies for @docKeys
sub keyDeps {
  return uniqKeys(map { @{$KEYDEPS{$_}||[]} } @_);
}

##--------------------------------------------------------------
## Methods: Pseudo-make: Dependency Tracking: Timestamps

## $floating_secs_or_undef = $doc->keyStamp($key)
## #$floating_secs_or_undef = $doc->keyStamp($key, $requireKey)
##  + gets $doc->{"${key}_stamp"} if it exists
##  + does NOT implicitly creates $doc->{"${key}_stamp"} for readable files
##    - this could be dangerous together with 'keeptmp'=>0
##  + returned value is (floating point) seconds since epoch
sub keyStamp {
  my ($doc,$key) = @_;
  return $doc->{"${key}_stamp"}
    if (defined($doc->{"${key}_stamp"}));
  return
    #$doc->{"${key}_stamp"} = file_mtime($doc->{$key}) ##-- DANGEROUS with keeptmp=>0 !
    file_mtime($doc->{$key}) ##-- DANGEROUS with keeptmp=>0 !
      if ($key =~ m/file$/ && defined($doc->{$key}) && -r $doc->{$key});
  return $doc->{"${key}_stamp"} = timestamp()
    if ($key !~ m/file$/ && defined($doc->{$key}));
  return undef;
  ##--
  #my ($doc,$key,$reqKey) = @_;
  #...
  #return undef
  #  if ($reqKey);
  #return $doc->depStamp($doc->keyDeps0($key));
}

## @newerDeps = $doc->keyNewerDeps($key)
## @newerDeps = $doc->keyNewerDeps($key, $missingDepsAreNewer)
sub keyNewerDeps {
  my ($doc,$key,$reqMissing) = @_;
  my $key_stamp = $doc->keyStamp($key);
  return keyDeps($key) if (!defined($key_stamp));
  my (@newerDeps,$dep_stamp);
  foreach (keyDeps($key)) {
    $dep_stamp = $doc->keyStamp($_);
    push(@newerDeps,$_) if ( defined($dep_stamp) ? $dep_stamp > $key_stamp : $reqMissing );
  }
  return @newerDeps;
}

## $bool = $doc->keyIsCurrent($key)
## $bool = $doc->keyIsCurrent($key, $requireMissingDeps)
##  + returns true iff $key is at least as new as all its
##    dependencies
##  + if $requireMissingDeps is true, missing dependencies
##    are treated as infinitely new (function returns false)
sub keyIsCurrent {
  return !scalar($_[0]->keyNewerDeps(@_[1..$#_]));
}

##--------------------------------------------------------------
## Methods: Pseudo-make: (Re-)generation

## $bool = $doc->genKey($key)
## $bool = $doc->genKey($key,\%KEYGEN)
##  + unconditionally (re-)generate a data key (single step only)
##  + passes on local \%KEYGEN
sub genKey {
  return $_[0]->SUPER::genKey($_[1], ($_[2] || \%KEYGEN));
}

## $bool = $doc->makeKey($key)
## $bool = $doc->makeKey($key,\%queued)
##  + conditionally (re-)generate a data key, checking dependencies
sub makeKey {
  my ($doc,$key) = @_;
  $doc->vlog($doc->{traceMake},"$doc->{xmlbase}: makeKey($key)") if ($doc->{traceMake});
  return $doc->{$key} if ($doc->keyIsCurrent($key));
  foreach ($doc->keyDeps0($key)) {
    $doc->makeKey($_) if (!defined($doc->{"${_}_stamp"}) || !$doc->keyIsCurrent($_));
  }
  return $doc->genKey($key) if (!$doc->keyIsCurrent($key));
}

## $bool = $doc->makeAll()
##  + alias for $doc->makeKey('all')
sub makeAll { return $_[0]->makeKey('all'); }

## undef = $doc->forceStale(@keys)
##  + forces all keys @keys to be considered stale by setting $doc->{"${key}_stamp"}=-$ix,
##    where $ix is the index of $key in the dependency-sorted list
##  + you can use the $doc->keyDeps() method to get a list of all dependencies
##  + in particular, using $doc->keyDeps('all') should mark all keys as stale
sub forceStale {
  my $doc = shift;
  my @keys = sort {keycmp($a,$b)} @_;
  foreach (0..$#keys) {
    $doc->{"$keys[$_]_stamp"} = -$_-1;
  }
  return $doc;
}

## $keyval_or_undef = $doc->remakeKey($key)
##  + unconditionally (re-)generate a data key and all its dependencies
sub remakeKey {
  my ($doc,$key) = @_;
  #$doc->genKey($_) foreach ($doc->keyDeps($key));
  #return $doc->genKey($key);
  ##--
  $doc->vlog($doc->{traceMake},"$doc->{xmlbase}: makeKey($key)") if ($doc->{traceMake});
  $doc->forceStale($doc->keyDeps($key),$key);
  return $doc->makeKey($key);
}


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::Document::Maker - DTA tokenizer wrappers: document wrapper: make-mode

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Document::Maker;
 
 $doc = DTA::TokWrap::Document::Maker->new(%opts);
 $doc->makeKey($key);
 
 ##-- ... any other DTA::TokWrap::Document method ...

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::TokWrap::Document::Maker provides an experimental
L<DTA::TokWrap::Document|DTA::TokWrap::Document>
subclass which attempts to perform C<make>-like dependency
tracking on document data keys.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Document::Maker: Globals
=pod

=head2 Globals

=over 4

=item @ISA

DTA::TokWrap::Document::Maker
inherits from
L<DTA::TokWrap::Document|DTA::TokWrap::Document>,
and should support all DTA::TokWrap::Document methods.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Document::Maker: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $doc = $CLASS_OR_OBJECT->new(%args);

Low-level constructor for make-mode document wrapper object.
See L<DTA::TokWrap::Document::new|DTA::TokWrap::Document/new>.

=item defaults

 %defaults = CLASS->defaults();

Static class-dependent defaults.

=item init

 $doc = $doc->init();

Dynamic object-dependent defaults.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Document::Maker: Methods: Pseudo-make: Dependency Tracking
=pod

=head2 Methods: make Mode: Dependency Tracking

=over 4

=item Variable: %KEYGEN

%KEYGEN = ($dataKey =E<gt> $generatorSpec, ...)

See L<%DTA::TokWrap::Document::KEYGEN|DTA::TokWrap::Document/%KEYGEN>.

=item %KEYDEPS

 %KEYDEPS = ($dataKey => \@depsForKey, ...)

Recursive key dependencies.

=item %KEYDEPS_0

 %KEYDEPS_0 = ($dataKey => \@immediateDepsForKey, ...)

Immediate key dependencies.

=item %KEYDEPS_H

 %KEYDEPS_0 = ($dataKey => {$dep1=>undef,$dep2=>undef,...}, ...)

Recursive dependencies as a hash-of-hashes.

=item keycmp

 $cmp = DTA::ToKWrap::Document::Maker::keycmp($a,$b);

Sort comparison function for data keys.

=item uniqKeys

 @uniqKeys = uniqKeys(@keys);

Returns unique keys from @keys.

=item keyDeps0

 @deps0 = PACKAGE::keyDeps0(@docKeys);

Returns unique immediate dependencies for @docKeys.

=item keyDeps

 @deps = PACKAGE::keyDeps(@docKeys);

Returns unique recursive dependencies for @docKeys.

=item keyStamp

 $floating_secs_or_undef = $doc->keyStamp($key);

Returns $doc-E<gt>{"${key}_stamp"} if it exists.
Otherwise returns file modification time for file keys.
Returned value is (floating point) seconds since epoch.

=item keyNewerDeps

 @newerDeps = $doc->keyNewerDeps($key);
 @newerDeps = $doc->keyNewerDeps($key, $missingDepsAreNewer)

Returns list of recursive dependencies for $key which are
newer than $key itself.  If $missingDepsAreNewer is given
and true, missing dependencies are not allowed.

=item keyIsCurrent

 $bool = $doc->keyIsCurrent($key);
 $bool = $doc->keyIsCurrent($key, $requireMissingDeps)

Returns true iff $key is at least as new as all its
dependencies.

If $requireMissingDeps is true, missing dependencies
are treated as infinitely new (function returns false).

=item genKey

 $bool = $doc->genKey($key);
 $bool = $doc->genKey($key,\%KEYGEN)

Unconditionally (re-)generate a data key (single step only,
ignoring dependencies).

Passes on local \%KEYGEN.

=item makeKey

 $bool = $doc->makeKey($key);
 $bool = $doc->makeKey($key,\%queued)

Conditionally (re-)generate a data key, checking dependencies.

=item makeAll

 $bool = $doc->makeAll();

Alias for $doc-E<gt>makeKey('all').

=item forceStale

 undef = $doc->forceStale(@keys);

Forces all keys @keys to be considered stale by setting $doc-E<gt>{"${key}_stamp"}=-$ix,
where $ix is the index of $key in the dependency-sorted list.

You can use the $doc-E<gt>keyDeps() method to get a list of all dependencies.
In particular, using $doc-E<gt>keyDeps('all') should mark all keys as stale

=item remakeKey

 $keyval_or_undef = $doc->remakeKey($key);

Unconditionally (re-)generate a data key and all its dependencies.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## See Also
##======================================================================

=pod

=head1 SEE ALSO

L<DTA::TokWrap::Intro(3pm)|DTA::TokWrap::Intro>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
...

=cut

##======================================================================
## See Also
##======================================================================

=pod

=head1 SEE ALSO

L<DTA::TokWrap::Intro(3pm)|DTA::TokWrap::Intro>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
...

=cut

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


