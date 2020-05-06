package URPM;

use strict;
use warnings;
use DynaLoader;

# Make sure debugging with Data::Dumper is more easily comparable:
$Data::Dumper::Sortkeys = 1;

# different files, but same package
# require them here to avoid dependencies
use URPM::Build;
use URPM::Resolve;
use URPM::Signature;

our @ISA = qw(DynaLoader);
our $VERSION = 'v5.28';

URPM->bootstrap($VERSION);

sub new {
    my ($class, %options) = @_;
    my $self = bless {
	depslist => [],
	provides => {},
	obsoletes => {},
    }, $class;
    $self->{nofatal} = 1 if $options{nofatal};
    $self;
}

sub set_nofatal {
    my ($urpm, $bool) = @_;
    $urpm->{nofatal} = $bool }

sub packages_providing {
    my ($urpm, $name) = @_;
    grep { $_ } map { $urpm->{depslist}[$_] } sort { $a <=> $b } keys %{$urpm->{provides}{$name} || {}};
}

sub packages_obsoleting {
    my ($urpm, $name) = @_;
    map { $urpm->{depslist}[$_] } keys %{$urpm->{obsoletes}{$name} || {}};
}

sub packages_by_name {
    my ($urpm, $name) = @_;
    grep { $name eq $_->name } packages_providing($urpm, $name);
}

sub search {
    my ($urpm, $name, %options) = @_;
    my $best;

    #- tries other alternative if no strict searching.
    unless ($options{strict_name}) {
	if ($name =~ /^(.*)-([^\-]*)-([^\-]*)\.([^\.\-]*)$/) {
	    foreach my $pkg (packages_providing($urpm, $1)) {
		$pkg->fullname eq $name and return $pkg;
	    }
	}
	unless ($options{strict_fullname}) {
	    if ($name =~ /^(.*)-([^\-]*)-([^\-]*)$/) {
		foreach my $pkg (packages_providing($urpm, $1)) {
		    my ($n, $v, $r, $a) = $pkg->fullname;
		    $options{src} && $a eq 'src' || $pkg->is_arch_compat or next;
		    "$n-$v-$r" eq $name or next;
		    !$best || $pkg->compare_pkg($best) > 0 and $best = $pkg;
		}
		$best and return $best;
	    }
	    if ($name =~ /^(.*)-([^\-]*)$/) {
		foreach my $pkg (packages_providing($urpm, $1)) {
		    my ($n, $v, undef, $a) = $pkg->fullname;
		    $options{src} && $a eq 'src' || $pkg->is_arch_compat or next;
		    "$n-$v" eq $name or next;
		    !$best || $pkg->compare_pkg($best) > 0 and $best = $pkg;
		}
		$best and return $best;
	    }
	}
    }

    unless ($options{strict_fullname}) {
	foreach my $pkg (packages_providing($urpm, $name)) {
	    my ($n, undef, undef, $a) = $pkg->fullname;
	    $options{src} && $a eq 'src' || $pkg->is_arch_compat or next;
	    $n eq $name or next;
	    !$best || $pkg->compare_pkg($best) > 0 and $best = $pkg;
	}
    }

    return $best;
}

#- Olivier Thauvin:
#- Returns @$listid, $start .. $end or the whole deplist id
#- according to the given args
sub build_listid {
    my ($urpm, $start, $end, $listid) = @_;

    @{$listid || []} > 0 ? @$listid :
        (($start || 0) .. (defined($end) ? $end : $#{$urpm->{depslist}}));
}

#- this is used when faking a URPM::DB: $urpm can be used as-a $db
#- (used for urpmi --env)
sub traverse {
    my ($urpm, $callback) = @_;

    if ($callback) {
	foreach my $p (@{$urpm->{depslist} || []}) {
	    $callback->($p);
	}
    }

    scalar @{$urpm->{depslist} || []};
}


#- this is used when faking a URPM::DB: $urpm can be used as-a $db
#- (used for urpmi --env)
sub traverse_tag {
    my ($urpm, $tag, $names, $callback) = @_;
    my $count = 0; 
    my %names;

    if (@{$names || []}) {
	if ($tag eq 'name') {
	    foreach my $n (@$names) {
		foreach my $p (packages_providing($urpm, $n)) {
		    $p->name eq $n or next;
		    $callback and $callback->($p);
		    ++$count;
		}
	    }
	} elsif ($tag eq 'whatprovides') {
	    foreach (@$names) {
		foreach (keys %{$urpm->{provides}{$_} || {}}) {
		    $callback and $callback->($urpm->{depslist}[$_]);
		    ++$count;
		}
	    }
	} else {
	    @names{@$names} = ();
	    if ($tag eq 'whatrequires') {
		foreach (@{$urpm->{depslist} || []}) {
		    if (grep { exists $names{$_} } $_->requires_nosense) {
			$callback and $callback->($_);
			++$count;
		    }
		}
	    } elsif ($tag eq 'whatconflicts') {
		foreach (@{$urpm->{depslist} || []}) {
		    if (grep { exists $names{$_} } $_->conflicts_nosense) {
			$callback and $callback->($_);
			++$count;
		    }
		}
	    } elsif ($tag eq 'group') {
		foreach (@{$urpm->{depslist} || []}) {
		    if (exists $names{$_->group}) {
			$callback and $callback->($_);
			++$count;
		    }
		}
	    } elsif ($tag eq 'triggeredby' || $tag eq 'path') {
		foreach (@{$urpm->{depslist} || []}) {
		    if (grep { exists $names{$_} } $_->files, grep { m!^/! } $_->provides_nosense) {
			$callback and $callback->($_);
			++$count;
		    }
		}
	    } else {
		die "unknown tag";
	    }
	}
    }

    $count;
}

#- this is used when faking a URPM::DB: $urpm can be used as-a $db
#- (used for urpmi --env)
sub traverse_tag_find {
    my ($urpm, $tag, $name, $callback) = @_;
    $urpm->traverse_tag($tag, [ $name ], $callback);
}


#- this is used when faking a URPM::DB: $urpm can be used as-a $db
#- (used for urpmi --env)
sub create_transaction {
    my ($_urpm) = @_; # same args as URPM.xs:create_transaction()
    die "Installing is not supported with a fake environment!";
}

# wrapper around XS functions
# it handles error cases
sub _parse_hdlist_or_synthesis {
    my ($parse_func, $urpm, $file, %options) = @_;

    my $previous_indice = @{$urpm->{depslist}};
    if (my ($start, $end) = $parse_func->($urpm, $file, %options)) {
	($start, $end);
    } elsif (!$options{callback}) {
	#- parse_hdlist__XS may have added some pkgs to {depslist},
	#- but we don't want those pkgs since reading hdlist failed later.
	#- so we need to drop them
	#- FIXME: {provides} would need to be reverted too!
	splice(@{$urpm->{depslist}}, $previous_indice);
	();
    } else {
	#- we need to keep them since the callback has been used
	#- and we can't pretend we didn't parse anything
	#- (needed for genhdlist2)
	();
    }
}
sub parse_synthesis { _parse_hdlist_or_synthesis(\&parse_synthesis__XS, @_) }
sub parse_hdlist { _parse_hdlist_or_synthesis(\&parse_hdlist__XS, @_) }

sub add_macro {
    my ($s) = @_;
    #- quote for rpmlib, *sigh*
    $s =~ s/\n/\\\n/g;
    add_macro_noexpand($s);
}

package URPM::Package;
our @ISA = qw(); # help perl_checker

#- debug help for urpmi
sub dump_flags {
    my ($pkg) = @_;
    <<EODUMP;
available:	  ${\($pkg->flag_available)}
base:		  ${\($pkg->flag_base)}
disable_obsolete: ${\($pkg->flag_disable_obsolete)}
installed:	  ${\($pkg->flag_installed)}
requested:	  ${\($pkg->flag_requested)}
required:	  ${\($pkg->flag_required)}
selected:	  ${\($pkg->flag_selected)}
skip:		  ${\($pkg->flag_skip)}
upgrade:	  ${\($pkg->flag_upgrade)}
EODUMP
}

my %arch_cache;
sub is_arch_compat {
    my ($pkg) = @_;
    my $arch = $pkg->arch;
    exists $arch_cache{$arch} and return $arch_cache{$arch};

    $arch_cache{$arch} = is_arch_compat__XS($pkg);
}

sub changelogs {
    my ($pkg) = @_;

    my @ti = $pkg->changelog_time or return;
    my @na = $pkg->changelog_name or return;
    my @tx = $pkg->changelog_text or return;
    map {
	{ time => $ti[$_], name => $na[$_], text => $tx[$_] };
    } 0 .. $#ti;
}

package URPM::Transaction;
our @ISA = qw(); # help perl_checker

package URPM::DB;
our @ISA = qw(); # help perl_checker

1;

__END__

=head1 NAME

URPM - Manipulate RPM files and headers

=head1 SYNOPSIS

    use URPM;

    # using the local RPM database
    my $db = URPM::DB::open();
    $db->traverse(sub {
	my ($package) = @_; # this is a URPM::Package object
	print $package->name, "\n";
	# ...
    });

    # loading and parsing a synthesis file
    my $urpm = new URPM;
    $urpm->parse_synthesis("synthesis.sample.cz");
    $urpm->traverse(sub {
	# retrieve all packages from the dependency list
	# ...
    });

=head1 DESCRIPTION

The URPM module allows you to manipulate RPM files, RPM header files and
hdlist files and manage them in memory. It is notably used by the L<urpmi>
utility. It provides four classes : C<URPM>, C<URPM::DB>, C<URPM::Package>,
and C<URPM::Transaction>.

=head2 The URPM class

=head3 Initialization

=over 4

=item URPM->new()

The constructor creates a new, empty URPM object. It's a blessed hash that
contains three fields:

=over

=item *

B<depslist> is an arrayref containing the list of depending packages (which are
C<URPM::Package> objects).

=item *

B<obsoletes> is an hashref containing as keys the list of property names
obsoleted by the URPM object.

=item *

B<provides> is an hashref containing as keys the list of property names
provided by the URPM object. The associated value is true if the property is
versioned.

=back

If the constructor is called with the arguments C<< nofatal => 1 >>, various
fatal error messages are suppressed (file not found in parse_hdlist() and
parse_synthesis()).

=item URPM::read_config_files()

Force the re-reading of the RPM configuration files.

=back

=head3 Loading packages data

$urpm->{depslist} is loaded when parsing sources (synthesis, hdlists or a plain
rpm file).

Synthesis and hdlists files are generated by L<genhdlist2> or L<gendistrib> (a
gendhlist2 wrapper handling a whole media set) from L<rpmtools> package.

=over

=item $urpm->parse_synthesis($file [, callback => sub {...} ])

This method gets the B<depslist> and the B<provides> from a synthesis file
and adds them to the URPM object.

Callback signature is callback(C<URPM>, C<URPM::Package>).

The return value is a two-element array containing the first and the last id
parsed.

=item $urpm->parse_hdlist($file, %options)

This method loads rpm informations from rpm headers contained in an hdlist
file and adds them to the URPM object. Allowed options are 

    packing => 0 / 1
    callback => sub { ... }
    keep_all_tags => 0 / 1

Callback signature is callback(C<URPM>, C<URPM::Package>).

The return value is a two-element array containing the first and the last id
parsed.

=item $urpm->parse_rpm($file, %options)

This method gets the B<depslist> and the B<provides> from an RPM file
and adds them to the URPM object. Allowed options are

    packing => 0 / 1
    keep_all_tags => 0 / 1
    callback => sub { ... }

If C<keep_all_tags> isn't specified, URPM will drop all memory-consuming tags
(notably changelogs, filelists, scriptlets).

Callback signature is callback(URPM::Package).

=back

=head3 Searching packages

=over

=item URPM::ranges_overlap($range1, $range2)

This utility function compares two version ranges, in order to calculate
dependencies properly. The ranges have roughly the form

    [<|<=|==|=>|>] [epoch:]version[-release]

where epoch, version and release are RPM-style version numbers.

=item $urpm->packages_providing($name)

Returns a list of C<URPM::Package> providing <$name>

=item $urpm->packages_by_name($name)

Returns a list of C<URPM::Package> corresponding to the wanted <$name>

=item $urpm->search($name, %options)

Search an RPM by name or by part of name in the list of RPMs represented by
this $urpm. The behaviour of the search is influenced by several options:

=over

=item  strict_name only match short name (N) =>  0 / 1

=item strict_fullname only match fullname (NVRA) (fast) => 0 / 1

=item src => look only for srpms => 0 / 1

=back

=back

=head3 Debuging

These are used when faking a URPM::DB: $urpm can be used as-a $db

=over

=item $urpm->traverse($callback)

Executes the callback for each package in the depslist, passing a
C<URPM::Package> object as argument the callback.

=item $urpm->traverse_tag($tag, $names, $callback)

$tag may be one of C<name>, C<whatprovides>, C<whatrequires>, C<whatconflicts>,
C<group>, C<triggeredby>, or C<path>.
$names is a reference to an array, holding the acceptable values of the said
tag for the searched variables.
Then, $callback is called for each matching package in the depslist.

Callback signature is callback(URPM::Package).

=item $urpm->traverse_tag_find($tag,$name,$callback)

Quite similar to C<traverse_tag>, but stops when $callback returns true.

(also note that only one $name is handled)

Callback signature is callback(URPM::Package).

=back

=head3 Checking packages

=over

=item URPM::verify_rpm($file, %options)

Verifies an RPM file.
Returns 0 on failure, 1 on success.
Recognized options are:

    nodigests => 0 / 1
    nosignatures => 0 / 1

=item URPM::verify_signature($file)

Verifies the signature of an RPM file. Returns a string that will contain "OK"
or "NOT OK" as well as a description of the found key (if successful) or of the
error (if signature verification failed.)

=item $urpm->import_pubkey(%options)

Imports a key in the RPM database.

    db => $urpm_db
    root => '...'
    block => '...'
    filename => '...'

=back

=head2 The URPM::DB class

=over 4

=item open($prefix, $write_perm)

Returns a new C<URPM::DB> object pointing on the local RPM database (or
C<undef> on failure).

$prefix defaults to C<""> and indicates the RPM DB root directory prefix if
any. (See the B<--root> option to rpm(1)).

$write_perm is a boolean that defaults to false, and that indicates whether
the RPM DB should be open in read/write mode.

=item rebuild($prefix)

Rebuilds the RPM database (like C<rpm --rebuilddb>). $prefix defaults to C<"">.

=item verify($prefix)

Verify the RPM database (like C<rpmdb --verify>). $prefix defaults to C<"">.

=item $db->traverse($callback)

Executes the specified callback (a code reference) for each package
in the DB, passing a C<URPM::Package> object as argument the callback.

Returns the number of packages seen (all).

=item $db->traverse_tag($tag,$names,$callback)

$tag may be one of C<name>, C<whatprovides>, C<whatrequires>, C<whatconflicts>,
C<group>, C<triggeredby>, or C<path>.
$names is a reference to an array, holding the acceptable values of the said
tag for the searched variables.
Then, $callback is called for each matching package in the DB.

Callback signature is callback(URPM::Package).

Returns the number of packages seen (all those that matched provided names).

=item $db->traverse_tag_find($tag,$name,$callback)

Quite similar to C<traverse_tag>, but stops when $callback returns true.

(also note that only one $name is handled)

Callback signature is callback(URPM::Package).

Returns whether callback returned true once.

=item $db->create_transaction()

Creates and returns a new transaction (an C<URPM::Transaction> object) on the
specified DB.

=back

=head2 The URPM::Package class

=head3 Getting a URPM::Package object

URPM::Package objects are usually retrieved from $urpm->{depslist} after
having loaded either the RPM DB and/or synthesis files.

It's also possible to get such an object with:

=over

=item URPM::spec2srcheader($specfile)

Returns a URPM::Package object containing the header of the source rpm produced
by the evaluation of the specfile whose path is given as argument. All
dependencies stored in this header are exactly the one needed to build the
specfile.

=item URPM::stream2header($fp)

Returns a URPM::Package object containing the header read from $fp.

=back

=head3 Methods

Most methods of C<URPM::Package> are accessors for the various properties
of an RPM package.

=over 4

=item $package->arch()

Gives the package architecture

=item $package->build_header($fileno)

Writes the rpm header to the specified file ($fileno being an integer).

=item $package->build_info($fileno, [$provides_files])

Writes a line of information in a synthesis file.

=item $package->buildarchs()

=item $package->buildhost()

=item $package->buildtime()

=item $package->changelog_name()

=item $package->changelog_text()

=item $package->changelog_time()

=item $package->compare($evr)

=item $package->compare_pkg($other_pkg)

=item $package->conf_files()

=item $package->conflicts()

Full conflicts tags

=item $package->conflicts_nosense()

Just the conflicted package name.
This is only used when faking a URPM::DB: $urpm can be used as-a $db

=item $package->description()

=item $package->dirnames()

=item $package->distribution()

=item $package->epoch()

=item $package->EVR()

=item $package->excludearchs()

=item $package->exclusivearchs()

=item $package->filelinktos()

=item $package->files()

List of files in this rpm.

=item $package->files_flags()

=item $package->files_gid()

=item $package->files_group()

=item $package->files_md5sum()

=item $package->files_mode()

=item $package->files_mtime()

=item $package->files_owner()

=item $package->files_size()

=item $package->files_uid()

=item $package->flag($name)

=item $package->flag_available()

=item $package->flag_base()

=item $package->flag_disable_obsolete()

=item $package->flag_installed()

=item $package->flag_requested()

=item $package->flag_required()

=item $package->flag_selected()

=item $package->flag_skip()

=item $package->flag_upgrade()

=item $package->free_header()

=item $package->fullname()

Returns a 4 element list: name, version, release and architecture in an array
context. Returns a string NAME-VERSION-RELEASE.ARCH in scalar context.

=item $package->get_tag($tagid)

Returns an array containing values of $tagid. $tagid is the numerical value of
rpm tags. See rpmlib.h. 

=item $package->queryformat($format)

Querying the package like rpm --queryformat do. 

The function calls directly the rpmlib, then use header informations, so it 
silently failed if you use synthesis instead of hdlist/rpm/header files or rpmdb.

=item $package->get_tag_modifiers($tagid)

Return an array of human readable view of tag values. $tagid is the numerical value of rpm tags.

=item $package->group()

=item $package->id()

=item $package->installtid()

=item $package->is_arch_compat()

Returns whether this package is compatible with the current machine's
architecture. 0 means not compatible. The lower the result is, the preferred
the package is.

=item $package->license()

=item $package->name()

The rpm's bare name.

=item $package->obsoletes()

Full obsoletes tags

=item $package->obsoletes_nosense()

Just the obsoleted package name.

=item $package->obsoletes_overlap($s)

=item $package->os()

=item $package->pack_header()

If a header is associated with the package, fill the package fields from
the header's tags (NEVRA,
requires/recommends/obsoletes/conflicts/provides/summary)
then free the header

It's useful when traversing the rpm DB, if one wants to keep around a
package from the DB
else the info would not be available outside the traverse_*() function.

It's also useful when creating a URPM_Package from a package file in
order to shrink memory footprint.

=item $package->packager()

=item $package->payload_format()

=item $package->provides()

Full provides tags

=item $package->provides_nosense()

Just the provided package name.

=item $package->provides_overlap($s)

=item $package->rate()

=item $package->release()

=item $package->requires()

=item $package->recommends()

Full requires tags

=item $package->requires_nosense()

Just the required package name.

=item $package->recommends_nosense()

=item $package->rflags()

=item $package->filesize()

Size of the rpm file (ie the rpm header + cpio body)

=item $package->set_flag($name, $value)

=item $package->set_flag_base($value)

=item $package->set_flag_disable_obsolete($value)

=item $package->set_flag_installed($value)

=item $package->set_flag_requested($value)

=item $package->set_flag_required($value)

=item $package->set_flag_skip($value)

=item $package->set_flag_upgrade($value)

=item $package->set_id($id)

=item $package->set_rate($rate)

=item $package->set_rflags(...)

=item $package->size()

=item $package->sourcerpm()

=item $package->summary()

=item $package->update_header($filename, ...)

=item $package->url()

=item $package->vendor()

=item $package->version()

=back

=head2 The URPM::Transaction class

=over 4

=item $trans->set_script_fd($fileno)

Sets the transaction output filehandle.

=item $trans->add($pkg, %options)

Adds a package to be installed to the transaction represented by $trans.
$pkg is an C<URPM::Package> object.

Options are:

    update => 0 / 1 : indicates whether this is an upgrade
    excludepath => [ ... ]

=item $trans->addReinstall($pkg)

Adds a package to be re-installed to the transaction represented by $trans.
$pkg is an C<URPM::Package> object.

=item $trans->remove($name)

Adds a package to be erased to the transaction represented by $trans.
$name is the name of the package.

=item $trans->check(%options)

Checks that all dependencies can be resolved in this transaction.

Options are:

    translate_message => 0 / 1 (currently ignored.)

In list context, returns an array of problems (an empty array indicates
success).

=item $trans->order()

Determines package order in a transaction set according to dependencies. In
list context, returns an array of problems (an empty array indicates success).

=item $trans->run($data, %options)

Runs the transaction.

$data is an arbitrary user-provided piece of data to be passed to callbacks.
It's usually the $urpm object.

Recognized options are:

    callback_close  => sub { ... }
    callback_elem   => sub { ... }
    callback_error  => sub { ... }
    callback_inst   => sub { ... }
    callback_open   => sub { ... }
    callback_trans  => sub { ... }
    callback_uninst => sub { ... }
    callback_verify => sub { ... }
    delta => used for progress callbacks (trans, uninst, inst)
    excludedocs => 0 / 1
    force => 0 / 1
    ignorearch => 0 / 1
    nosize => 0 / 1
    noscripts => 0 / 1
    oldpackage => 0 / 1
    test => 0 / 1
    translate_message => 1

They roughly correspond to command-line options to rpm(1).

'callback_open' signature is (C<$data>, C<$cb_type>, C<$pkg_id>). It _must_ return a file handler for the asked package.

'callback_close' signature is (C<$data>, C<$cb_type>, C<$pkg_id>). It is called just before URPM close the fd for the installed package.

C<$cb_type> is one of 'open' or 'close'.

Other Callbacks signature is callback(C<$data>, C<$cb_type>, C<$pkg_id>, C<$subtype>, C<$amout>, C<$total>)

C<$cb_type> is one of 'elem', 'error', 'inst', 'trans' or 'uninst'. C<$subtype> can be 'start', 'progress' or 'stop'.
For 'error', it can be 'cpio', 'script' or 'unpack'.

The purpose of those callbacks is to report progress (the two last parameters (C<$amount> & C<$total>) enable to compute progress percentage).

=item $trans->traverse($callback)

Executes the specified callback (a code reference) for each package in the
transaction, passing a C<URPM::Package> object as argument the callback.

=back

=head3 Transaction Element management

=over 4

=item $trans->NElements($fileno)

Returns the number of elements in the transaction.

=item $trans->Element_version($index)

Returns the version of the $index-th element in the transaction.

=item $trans->Element_release($index)

Returns the release of the $index-th element in the transaction.

=item $trans->Element_fullname($index)

Returns the fullname of the $index-th element in the transaction.

=back

=head2 Macro handling functions

=over

=item loadmacrosfile($filename)

Load the specified macro file. Sets $! if the file can't be read.

=item expand($name)

Expands the specified macro.

=item add_macro($macro_definition)

=item add_macro_noexpand($macro_definition)

Define a macro. For example,

    URPM::add_macro("vendor Mageia");
    my $vendor = URPM::expand("%vendor");

The 'noexpand' version doesn't expand literal newline characters in the
macro definition.

=item del_macro($name)

Delete a macro.

=item resetmacros()

Destroys macros.

=back

=head2 Misc other functions

=over

=item setVerbosity($level)

Sets rpm verbosity level. $level is an integer between 2 (RPMMESS_CRIT) and 7
(RPMMESS_DEBUG).

=item rpmErrorString()

=item rpmErrorWriteTo($fd)

=item archscore($arch)

Return the score of the given arch. 0 mean not compatible,
lower is prefered.

=item osscore($os)

Return the score of the given os. 0 mean not compatible,
lower is prefered.

=back

=head2 The $state object

It has the following fields:

B<backtrack>: { 
   selected => { id => undef }, 
   deadlock => { id|property => undef },
 }

B<cached_installed>: { property_name => { fullname => undef } }

B<oldpackage>: int
   # will be passed to $trans->run to set RPMPROB_FILTER_OLDPACKAGE

B<selected>: { id => { 
     requested => bool, install => bool,
     from => pkg, psel => pkg,
     promote => name, unsatisfied => [ id|property ]
 } }

B<rejected>: { fullname => { 
     size => int, removed => { fullname|"asked" => undef },
     obsoleted => { fullname|"asked" => undef },
     backtrack => { # those info are only used to display why package is unselected
         promote => [ name ], keep => [ fullname ], 
         unsatisfied => [ id|property ], 
         conflicts => [ fullname ],
     },
     closure => { fullname => { old_requested => bool, 
                                unsatisfied => [ id|property ],
                                conflicts => property },
                                avoid => bool },
     },
 } }

B<rejected_already_installed>: { id => pkg }

B<orphans_to_remove>: [ pkg ]

B<whatrequires>: { name => { id => undef } }
   # reversed requires_nosense for selected packages

B<unselected_uninstalled>: [ pkg ]
   # (old) packages which are needed, but installed package is newer

more fields only used in build_transaction_set and its callers):

B<transaction>: [ { upgrade => [ id ], remove => [ fullname ] } ]

B<transaction_state>: $state object


=head1 SEE ALSO

The L<URPM::Resolve> implements the resolving bits.

The L<URPM::Signature> implements the pubkey bits.

The L<urpm> package is a higher level module used by the urpmi command line tool,
the rpmdrake GUI and the drakx installer.

=head1 COPYRIGHT

Copyright 2002, 2003, 2004, 2005 MandrakeSoft SA

Copyright 2005, 2006, 2007, 2008 Mandriva SA

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Mageia

FranE<ccedil>ois Pons (original author), Rafael Garcia-Suarez, Pixel, Thierry Vignaud <tv@mageia.org> (current maintainer)

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
