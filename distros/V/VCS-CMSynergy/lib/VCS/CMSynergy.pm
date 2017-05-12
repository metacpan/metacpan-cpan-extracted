package VCS::CMSynergy;

# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod for usage and distribution rights.

use 5.008_001;                          # i.e. v5.8.1
use strict;
use warnings;

our $VERSION = '1.51';

use VCS::CMSynergy::Client qw(
    is_win32 _fullwin32path $Error $Ccm_command _error);

our @ISA = qw(VCS::CMSynergy::Client);
our @EXPORT_OK = qw( ANY_OF NONE_OF );

use Carp;
use Config;
use File::Spec;
use File::Temp qw(tempfile);            # in Perl core v5.6.1 and later
use Log::Log4perl qw(:easy);

use Type::Params qw( validate );
use Types::Standard qw( slurpy Optional Str InstanceOf HasMethods Undef
    ArrayRef CodeRef GlobRef HashRef ScalarRef FileHandle Dict );

use constant _KEYWORDS     => slurpy ArrayRef[Str];
use constant _FILE_SPEC    => ( Str | InstanceOf["VCS::CMSynergy::Object"] );
use constant _PROJECT_SPEC => ( Str | InstanceOf["VCS::CMSynergy::Project"] );
use constant _QUERY        => ( Str | ArrayRef | HashRef );

use constant ROW_HASH   => 1;
use constant ROW_OBJECT => 2;

sub import
{
    my $class = shift;

    my @list;
    my %use =
    (
        tied_objects            => 0,
        cached_attributes       => 0,
    );

    foreach (@_)
    {
        if (/^([!:])(.*)$/ and exists $use{$2})
        {
            $use{$2} = $1 eq ":" ? 1 : 0;
        }
        else
        {
            push @list, $_;
        }
    }

    unless (caller() =~ /^VCS::CMSynergy/)
    {
        while (my ($opt, $value) = each %use)
        {
            eval "use constant use_$opt => $value";
        }
    }

    # let Exporter handle the rest
    __PACKAGE__->export_to_level(1, undef, @list);

    # require V::C::Object _after_ use_* have been defined,
    # so that optimization based on constant expressions can 
    # e.g. eliminate branches guarded with "if (V::C::use_cached_attributes)"
    require VCS::CMSynergy::Object;
    require VCS::CMSynergy::ObjectTieHash if use_tied_objects();
}

sub new
{
    my ($class, %args) = @_;

    my %client_args;
    foreach (keys %args)
    {
        $client_args{$_} = delete $args{$_} 
            if exists $VCS::CMSynergy::Client::opts{$_};
    }
    return $class->_start(VCS::CMSynergy::Client->new(%client_args), %args);
}


sub _start
{
    my ($class, $client, %args) = @_;
    croak(__PACKAGE__."::_start: $client is not a VCS::CMSynergy::Client")
        unless UNIVERSAL::isa($client, 'VCS::CMSynergy::Client');

    # make a deep clone of $client 
    my $self = { %$client };
    $self->{env} = { %{ $client->{env} } } if $client->{env};
    bless $self, $class;

    # remember the process that created $self (so we can check in DESTROY)
    $self->{pid} = $$;

    # prime web_mode early as possible
    $self->{web_mode} = 1 if $self->version >= 7.2;

    my $role = delete $args{role};              # initial role

    foreach (qw( KeepSession UseCoprocess ))
    {
        $self->{$_} = delete $args{$_} if exists $args{$_};
    }

    if (defined(my $ccm_addr = delete $args{CCM_ADDR}))  # reuse an existing Synergy session
    {
        # NOTE: Web mode may be determined (if still unknown) via "ccm ps".

        # fail early if CCM_ADDR is bogus
        my $ps = $self->ps(rfc_address => $ccm_addr);
        return $self->set_error(qq[can't find session "$ccm_addr" in "ccm ps"]) 
            unless $ps && @$ps;

        $self->{env}{CCM_ADDR} = $ccm_addr;
        $self->{web_mode} = $ps->[0]{process} eq "usr_cmd_interface";

        # anything still left in %args is an error
        croak(__PACKAGE__."::_start: option(s) not valid when CCM_ADDR is specified: ".
             join(", ", keys %args)) if %args;

        $self->{KeepSession} = 1 unless defined $self->{KeepSession};
        INFO sprintf(qq[%s keep session "%s"],
                     $self->{KeepSession} ? "will" : "won't",
                     $ccm_addr);

        if (is_win32 && !$self->web_mode)
        {
            # create a minimal ini file (see below for an explanation)
            (my $inifh, $self->{ini_file}) = tempfile(SUFFIX => ".ini", UNLINK => 0);
            $self->{ini_file} = _fullwin32path($self->{ini_file}) if $^O eq 'cygwin';
                                # because this name is passed down to ccm.exe
                
            printf $inifh "[UNIX information]\nUser = %s\n", $self->user;
            close($inifh);
            push @{ $self->{files_to_unlink} }, $self->{ini_file};
        }
    }
    else                                # start a new Synergy session
    {
        # NOTE: Web mode in Synergy version prior to 7.2 must be explicitly
        # requested with option "-s".
        $self->{web_mode} ||= defined $args{server};

        if ($^O eq 'cygwin')
        {
            # Cygwin: some start options denote path names that are
            # passed down to Synergy; convert them to native Windows form
            foreach (qw/home ini_file ui_database_dir/)
            {
                $args{$_} = _fullwin32path($args{$_}) if defined $args{$_};
            }
        }

        # %start_opts: its keys are all valid options that can be
        # passed to VCS::CMSynergy::_start; moreover,
        # if $start_opts{foo} is defined then arg "foo" is automagically
        # passed to "ccm start" as "... $start_opts{foo} $args{foo} ..."
        my %start_opts =
        (
            database            => "-d",
            server              => "-s",
            password            => "-pw",
            user                => "-n",
        $self->web_mode ? () : (                # classic mode only
            ini_file            => undef,
            remote_client       => undef,
            home                => "-home",
            host                => "-h",
            ui_database_dir     => "-u",
        ));

        my @start = qw/start -m -q -nogui/;
        while (my ($arg, $value) = each %args)
        {
            croak(__PACKAGE__."::_start: invalid option: $arg")
                unless exists $start_opts{$arg};

            $self->{$arg} = $value unless $arg eq "password";
            push @start, $start_opts{$arg} => $value if defined $start_opts{$arg};
        }
        push @start, '-rc' if $self->{remote_client};

        # NOTE: If neither database nor CCM_ADDR was specified "ccm start ..."
        # will fail later on, but with rather cryptic messages from Synergy;
        # hence better fail early.
        croak(__PACKAGE__."::_start: don't know how to connect to Synergy: neither database nor CCM_ADDR specified")
            unless $self->{database};

        unless ($self->web_mode)
        {
            unless (defined $self->{ini_file})
            {
                if (is_win32)
                {
                    # NOTES: 
                    # (1) "ccm start -f nul ..." doesn't work on Windows
                    #     (leads to error from ccm_seng), 
                    #     so use an empty ini_file instead
                    # (2) we can't use UNLINK=>1 with tempfile, because 
                    #     the actual unlink may occur before the session is
                    #     stopped and Windows refuses removing the "busy" file
                    (undef, $self->{ini_file}) = tempfile(SUFFIX => ".ini", UNLINK => 0);
                    $self->{ini_file} = _fullwin32path($self->{ini_file}) if $^O eq 'cygwin';
                    push @{ $self->{files_to_unlink} }, $self->{ini_file};
                }
                else
                {
                    $self->{ini_file} = File::Spec->devnull;
                }
            }
            push @start, "-f", $self->{ini_file};
        }


        my ($rc, $out, $err) = $self->_ccm(@start);
        return $self->set_error($err || $out) unless $rc == 0;

        $self->{env}{CCM_ADDR} = $out;
        INFO qq[started session "$out"];
    }

    if (defined $role)
    {
        my ($rc, $out, $err) = $self->_set(role => $role);
        return $self->set_error($err || $out) unless $rc == 0;
    }

    # NOTE: Use of $CCM_INI_FILE fixes the annoying `Warning:
    # Security violation.  User JLUSER is not authorized to the
    # Continuus interface at ...'  when running on Windows.
    #
    # Background: The problem is the obsolete ccm.ini file in
    # Windows' %SystemRoot%.  If ccm_gui or "ccm start ..." is
    # invoked _without_ specifying an ini file it writes the
    # Unix user (as given in the login popup or -n option, resp.)
    # into this file. If $CCM_INI_FILE is not set, all other "ccm ..."
    # invocations will read this file and check its "user"
    # entry against the session identified by $CCM_ADDR. If
    # they don't match, the above warning is issued and the
    # command aborted.  If we already have have an ini_file we
    # just set $CCM_INI_FILE to its name. Otherwise we fake
    # a minimal ini file with the correct setting of "user"
    # and set $CCM_INI_FILE to its name.
    #
    # NOTE: Synergy versions >= 6.0 on Windows do not use 
    # %SystemRoot%\ccm.ini any more. However, the problem persists:
    # if there's a [UNIX information] section in $CCM_HOME\etc\ccm.ini
    # or the user's personal ccm.ini its "User" setting will be used
    # and may trigger the "security violation".

    $self->{env}{CCM_INI_FILE} = $self->{ini_file}
        if is_win32 && !$self->web_mode;

    # web mode renames the %filename placeholder (cf. "ccm set text_editor")
    $self->{"%filename"} = $self->web_mode ? "%file" : "%filename";

    if ($self->{UseCoprocess})
    {
        if ($self->web_mode)
        {
            carp(__PACKAGE__."::_start: UseCoprocess is invalid in web mode -- ignoring UseCoprocess");
        }
        elsif ($self->_spawn_coprocess)
        {
            TRACE sprintf("spawned coprocess (pid=%d)", $self->{coprocess}->pid);
        }
        else
        {
            carp(__PACKAGE__."::_start: can't establish coprocess: $self->{error} -- ignoring UseCoprocess");
        }
    }

    # cache some info from database; this also doubles as a test for a valid session
    {
        my ($rc, $out, $err) = $self->_ccm(qw/delimiter/);
        return $self->set_error($err || $out) unless $rc == 0;
        $self->{delimiter} = $out;

        $self->{delimiter_rx} = qr/[$self->{delimiter}:]/;
        $self->{objectname_rx} = 
            qr/^(.*?)$self->{delimiter_rx}(.*?):(.*?):(.*?)$/;
                                        # -> (name, version, cvtype, instance)
        $self->{finduse_rx} = 
            qr/^(.*?)$self->{delimiter_rx}.*?\@(.*?)$/;
                                        # -> (path, project)
    }

    # NOTE: If option `database' was present it may not be in the
    # canonical form; purge it from $self so that $self->database
    # will recompute it on demand.
    delete $self->{database};

    $self->{objects} = {} if use_cached_attributes();

    return $self;
}


sub DESTROY 
{
    my $self = shift;

    # no-op if the session has not yet been established
    return unless $self->ccm_addr;      

    # no-op if this is not the process that created $self
    return unless $self->{pid} == $$;   

    # NOTE: DESTROY might be called implicitly while unwinding 
    # stack frames during exception processing, e.g.
    #
    # eval {
    #   my $ccm = VCS::CMSynergy->new(...);
    #   ...
    #   die "D.O.A."                    # <-- exception thrown
    #   ...
    # };
    # print "oops: $@\n" if $@;         # <-- handle it
    #
    # The exception causes a premature exit from the eval block.
    # But this block is also the scope of $ccm, hence $ccm->DESTROY
    # is called. Any eval block encountered during processing of DESTROY()
    # will reset $@  - even if no excpetion is thrown. Hence $@
    # might be empty at "print...". 
    # We localize $@ to avoid this unexpected behavior.
    # FIXME: might be more correct to push localization into the
    # offending methods.
    local $@;

    local $?;                           # don't screw up global $?
    $self->_kill_coprocess if $self->{coprocess};

    # don't stop session if KeepSession is set 
    unless ($self->{KeepSession})
    {
        $self->_ccm(qw/stop/);
        INFO sprintf(qq[stopped session "%s"], $self->ccm_addr);
    }

    # on Windows, certain files (e.g. the fake ccm.ini) might still be busy
    my @files_to_unlink;
    foreach (@{ $self->{files_to_unlink} })
    {
        unlink($_) or push @files_to_unlink, $_;
    }
    if (is_win32 && @files_to_unlink)
    {
        # wait a little, then try again
        sleep(2);
        unlink(@files_to_unlink);
    }

    %$self = ();                        # paranoia setting
}


sub ccm_addr    { return shift->{env}{CCM_ADDR}; }

sub delimiter   { return shift->{delimiter}; }

# find my session's entry in "ccm ps" and return the value of $field
# returns undef (or throws an error) if the session can't be found
sub _my_ps
{ 
    my $self = shift;
    my ($field) = @_;

    my $ccm_addr = $self->ccm_addr;
    my $ps = $self->ps(rfc_address => $ccm_addr);
    return $self->set_error(qq[can't find session "$ccm_addr" in "ccm ps"]) 
        unless $ps && @$ps;

    return $ps->[0]{$field};
}

# determine database path (in canonical format) etc from "ccm ps"
__PACKAGE__->_memoize_method(database => sub { shift->_my_ps('database'); });
__PACKAGE__->_memoize_method(user     => sub { shift->_my_ps('user'); });
__PACKAGE__->_memoize_method(web_mode => sub { shift->_my_ps('process') eq "usr_cmd_interface"; });


sub query
{
    my $self = shift;

    my ($rc, $out, $err) = $self->_ccm(qw/query -u/, @_);

    # NOTE: If there are no hits, `ccm query' exits 
    # with status 1 (classic mode) or 6 (web mode),
    # but produces no output on either stdout and stderr.

    return [ split(/\n/, $out) ] if $rc == 0;
    return [ ] if $rc != 0 and $out eq "" and $err eq "";
    return $self->set_error($err || $out);
}


sub query_arrayref
{
    my $self = shift;
    my ($query, $keywords) = validate(\@_, _QUERY, _KEYWORDS);

    return _flatten_rows($self->_query($query, $keywords, ROW_HASH), $keywords);
}


sub query_hashref
{
    my $self = shift;
    my ($query, $keywords) = validate(\@_, _QUERY, _KEYWORDS);

    return $self->_query($query, $keywords, ROW_HASH);
}


sub query_object
{
    my $self = shift;
    my ($query, $keywords) = validate(\@_, _QUERY, _KEYWORDS);

    return $self->_query($query, $keywords, ROW_OBJECT);
}

*query_object_with_attributes = \&query_object;         # compatibility alias

sub query_count
{
    my $self = shift;
    my ($query) = validate(\@_, _QUERY);

    my ($rc, $out, $err) = $self->_ccm(
        qw/query -u -ns -nf -format X/, $self->_expand_query($query));

    # NOTE: If there are no hits, `ccm query' exits 
    # with status 1 (classic mode) or 6 (web mode),
    # but produces no output on either stdout and stderr.
    return 0 if $rc != 0 and $out eq "" and $err eq "";
    return $out =~ tr/X/X/ if $rc == 0;                 # count 'em X's
    return $self->set_error($err || $out);
}


# NOTE: We use \cA and \cD as record/field separators.
# SYNERGY/Change uses \x1C-\x1E in attribute
# "transition_log" of "problem" objects, so these are out.
# Also people have been known to enter strange characters
# like \cG even when using a GUI exclusively.
# Change these at your own risk, YMMV.

our $RS = "\cA";        # record separator for query etc
our $FS = "\cD";        # field separator for query etc

# helper method: query with correct handling of multi-line attributes
sub _query
{
    my ($self, $query, $keywords, $row_type) = @_;

    $query = $self->_expand_query($query);

    my $want = _want($row_type, $keywords);

    my $want_finduse = delete $want->{finduse};
    if ($want_finduse)
    {
        croak(__PACKAGE__.qq[::_query: keyword "finduse" not allowed when ROW_OBJECT wanted])
            if $row_type == ROW_OBJECT;
        croak(__PACKAGE__.qq[::_query: keyword "finduse" does not work in web mode])
            if $self->web_mode;
    }

    my $format = $RS . join($FS, values %$want) . $FS;

    my ($rc, $out, $err) = $want_finduse ?
        $self->_ccm_with_option(
            Object_format => $format, 
            qw/finduse -query/ => $query) :
        $self->_ccm( 
            qw/query -u -ns -nf -format/ => $format, $query);

    # NOTE: If there are no hits, `ccm query' exits 
    # with status 1 (classic mode) or 6 (web mode),
    # but produces no output on either stdout and stderr.
    return [ ] if $rc != 0 && $out eq "" && $err eq "";

    # NOTE: If the query string contained a syntax error, Synergy
    # prints "Syntax error in query request", but won't tell you the
    # query string, making it hard to diagnose the problem.
    # So append the query string to the error message.
    return $self->set_error(($err || $out).qq[\n  Query was "$query"]) 
        unless $rc == 0;

    my @result;
    foreach (split(/\Q$RS\E/, $out))            # split into records 
    {
        next unless length($_);                 # skip empty leading record

        my @cols = split(/\Q$FS\E/, $_, -1);    # don't strip empty trailing fields

        my %finduse;
        if ($want_finduse)
        {
            # finduse information is the last "column" 
            my $fu_lines = pop @cols;   

            # finduse lines are of the forms
            #
            #   \t relative_path/name-version@pname-pversion 
            #   \t relative_path/name-version@pname-pversion:project:pinstance
            #
            # which we parse into a hash
            #   "project_objectname" => "relative_path/name"

            # NOTE: Starting with Synergy 6.3, project objects may have instances
            # other than '1' (either for DCM reasons, or because someone
            # created a second project with the same name while the
            # model attribute "multiple_local_proj_instances" was TRUE).
            # Synergy 6.3 apparently still returns "proj_vers" if instance='1' and
            # the full objectname otherwise. We return the full objectname
            # in any case.

            unless ($fu_lines =~ /Object is not used in scope/)
            {
                foreach (split(/\n/, $fu_lines))
                {
                    s/^\s*//;
                    next if /^$/;
                    my ($path, $project) = /$self->{finduse_rx}/
                        or return $self->set_error(
                            qq[unrecognizable line returned from "finduse -query": "$_"]);
                    $finduse{$self->_projspec2objectname($project)} = $path;
                }
            }
        }

        my $row = $self->_query_result($want, \@cols, $row_type);
        $row->{finduse} = \%finduse if $want_finduse;
        push @result, $row;
    }
    return \@result;
}

# Sigh. "ccm query -f %objectname" returns old-style fullnames
# (i.e. "instance/cvtype/name/version") for certain legacy types of 
# objects, e.g. "cvtype" and "attype". But Synergy
# doesn't accept these where a "file_spec" is expected 
# (at least on Unix, because they contain slashes). 
# Hence rewrite these fullnames to objectnames.
# Also normalize the name/version separator to a colon.
sub _fullname2objectname
{
    my ($self, $fullname) = @_;
    if ($fullname =~ m{/} && (my @p = split("/", $fullname)) == 4)
    {
        $fullname = join(":", $p[2], $p[3], $p[1], $p[0]);
    }
    else
    {
        $fullname =~ s/$self->{delimiter_rx}/:/;
    }
    return $fullname;
}

# NOTE: The Synergy pseudo attributes (e.g. %task) are implemented in
# baselib/src/base/pseudo_attrs.ac (except for the hard-wired %objectname
# and %displayname) and the table in attribute "pseudo_attrs" 
# of base-1:model:base.

# rewrite rules for complex pseudo attributes
# - key is the name of the pseudo attribute
# - value is a hash consisting of:
#   format: the string to use in a ccm format option to get the raw value
#   rewrite: a sub that will be called with two arguments: a VCS::Synergy
#     session and the raw value; it must return the converted value
#     NOTE: the raw value will always be defined, because undef ("<void>")
#       raw values are automatically passed thru
#   row_object_ok: whether this pseudo attribute allowed when the final
#     answer is in terms of VCS::CMSynergy::Objects (e.g. query_object())
my %_rewrite_rule = 
(
    objectname => 
    {
        format          => "%objectname",
        rewrite         => sub { my ($self, $value) = @_;
                                 $self->_fullname2objectname($value); },
        row_object_ok   => 1,
    },
    object => 
    {
        format          => "%objectname",
        rewrite         => sub { my ($self, $value) = @_;
                                 $self->object($self->_fullname2objectname($value)); },
        row_object_ok   => 1,
    },
    task_objects => 
    {
        format          => "%task",
        rewrite         => sub { my ($self, $value) = @_;
                                 [ map { $self->task_object($_) } 
                                       split(/,/, $value) ]; },
        row_object_ok   => 0,
    },
    cr_objects =>
    {
        format          => "%change_request",
        rewrite         => sub { my ($self, $value) = @_;
                                 [ map { $self->cr_object($_) } 
                                       split(/,/, $value) ]; },
        row_object_ok   => 0,
    },
    baseline_project =>
    {
        format          => "%baseline",
        rewrite         => sub { my ($self, $value) = @_;
                                 $self->project_object($value); },
        row_object_ok   => 0,
    },
    baseline_object =>
    {
        format          => "%in_baseline",
        rewrite         => sub { my ($self, $value) = @_;
                                 $self->baseline_object($value); },
        row_object_ok   => 0,
    },
);


# helper (not a method): build "want" array from keyword list (common case)
# NOTE: if $want_row_object is true, the keyword "object" will be 
#   automatically added to the returned hash
sub _want
{
    my ($row_type, $keywords) = @_;
    my %want = map { $_ => "%$_" } @$keywords;
    $want{object} = "%objectname" if $row_type == ROW_OBJECT;

    # handle special keywords
    foreach (keys %want)
    {
        if (my $rule = $_rewrite_rule{$_})
        {
            croak(__PACKAGE__.qq[::_want: keyword "$_" not allowed when ROW_OBJECT wanted]) 
                if $row_type == ROW_OBJECT && !$rule->{row_object_ok};
            $want{$_} = $rule->{format};
        }
    }

    return \%want;
}

sub _query_result
{
    my ($self, $want, $cols, $row_type) = @_;

    my %row;
    
    # strip trailing newline (for consistency with get_attribute()),
    # translate "<void>" to undef and fill into correct slots
    # NOTE: per construction, @$cols are in the same order as keys %$want
    @row{keys %$want} = map { s/\n\z//; /^<void>$/ ? undef : $_ } @$cols;
    
    # handle special keywords
    foreach (keys %$want)
    {
        next unless defined $row{$_};
        if (my $rule = $_rewrite_rule{$_})
        {
            $row{$_} = $rule->{rewrite}->($self, $row{$_});
        }
    }

    if ($row_type == ROW_OBJECT)
    {
        my $obj = delete $row{object};
        $obj->_update_acache(\%row);
        return $obj;
    }
    return \%row;
}

# helper
sub _expand_query
{
    my ($self, $query) = @_;
    if (ref $query eq 'ARRAY')
    {
        $query = $self->_query_shortcut($query);
    }
    elsif (ref $query eq 'HASH')
    {
        $query = $self->_query_deprecated_shortcut($query);
    }
    else
    {
        # Sanitize query string by replacing whitespace (esp. newlines)
        # by a single blank except inside single or double quotes.
        # This helps to improve the legibility of longish queries with 
        # whitespace and line breaks (which Synergy's CLI dosen't grok).
        $query =~ s/('.*?'|".*?"|[^'"\s]+)|(\s+)/defined $2 ? " " : $1/sge;
    }
    return $query;
}

my %ac_cvtype = map { $_ => "AC/cvtype/$_/1" } 
                    qw/ admin asm attype bstype cvtype mcomp model pdtype /;

# helper: expand shortcut queries
sub _query_shortcut
{
    my ($self, $aref) = @_;
    croak("shortcut query must consist of an even number of elements") unless @$aref % 2 == 0;

    DEBUG "shortcut query [ " .
            join(", ", map { $_ % 2 ? () : qq[$aref->[$_] => "$aref->[$_+1]"] }
                       0..(@$aref-1)) .
          "]";

    my %expr;
    while (@$aref)
    {
        my ($key, $value) = splice(@$aref, 0, 2);
        push @{ $expr{$key} },
             ref $value eq "ARRAY"
                 ? ANY_OF($key, @$value)
                 : $key . ($value =~ /[*?]/ ? " match " : "=") . _quote_value($value);
    }

    my $expanded = join(" and ",
                        map { my $alt = join(" or ", @$_);
                              @$_ == 1 ? $alt : "($alt)"; } values %expr); 
    DEBUG qq[expanded shortcut query "$expanded"];
    return $expanded;
}

# helper: expand shortcut queries (deprecated)
sub _query_deprecated_shortcut
{
    my ($self, $href) = @_;
    carp(qq[shortcut queries with {...} are deprecated, see the section on "shortcut query notation" in VCS::CMSynergy's pod]);

    DEBUG "deprecated shortcut query { ".join(", ", map { "$_ => $href->{$_}" } keys %$href)." }";

    my @clauses;
    while (my ($key, $value) = each %$href)
    {
        my $ref = ref $value;
        if ($ref eq '')
        {
            for ($key)
            {
                /^task$/ && do          # same as "ccm query -task ..."
                {
                    push @clauses, "is_associated_cv_of(task('$value'))";
                    next;
                };
                /^match$/ && do
                {
                    push @clauses, "name match '$value'";
                    next;
                };
                /^(cv)?type$/ && do
                {
                    # rumor (D. Honey) has it that 
                    # "has_cvtype('base/cvtype/foo/1')" is somehow faster
                    # than "type='foo'; note that the two are not synonyms,
                    # since the latter also applies to the AC cvtypes 
                    # like "admin" or "model"
                    my $cvtype = $ac_cvtype{$value} || "base/cvtype/$value/1";
                    push @clauses, "has_cvtype('$cvtype')";
                    next;
                };
                push @clauses, "$key="._quote_value($value);
            }
        }
        elsif ($ref eq 'ARRAY')
        {
            my $args = join(",", map { _quote_value($_) } @$value);
            push @clauses, "$key($args)";
        }
        elsif ($ref eq 'HASH')
        {
            my $nested = $self->_query_shortcut($value);
            push @clauses, "$key($nested)";
        }
        else
        {
            (my $method = (caller(1))[3]) =~ s/^.*:://;
            croak(qq[$method: dunno how to handle "$key => $ref" in shortcut query]);
        }
    }

    my $expanded = join(" and ", @clauses);
    DEBUG qq[expanded shortcut query "$expanded"];

    return $expanded;
}

sub ANY_OF
{
    my $key = shift;
    croak(__PACKAGE__.qq[::ANY_OF needs at least one value]) unless @_;

    return "(" . join(" or ", map { "$key="._quote_value($_) } @_). ")";
}

sub NONE_OF
{
    return "(not " . ANY_OF(@_) . ")";
}

# helper (not a method): smart quoting of string or boolean values
# NOTE: Synergy seems to use the following quoting rules
# for the right hand side of an "attribute value clause" in a query:
# - string and text values must be quoted
# - boolean values ("TRUE" or "FALSE") must not be quoted
# - integer values must not be quoted, but must always have a leading sign
# - time values must be written as "time('Fri Dec 12 1997')"
sub _quote_value
{
    local ($_) = @_;
    return /^(TRUE|FALSE)$/ ? $_ : # don't quote boolean
           /'/ ? qq["$_"] :        # use double quotes if contains single quote
           qq['$_'];               # use single quotes otherwise
}

# helper (not a method): $rows is an array of hashes;
# replace each hash by the values of the keys in $keys (in this order);
# if $rows is undefined, return undefined
# NOTE: This modifies the original array.
sub _flatten_rows
{
    my ($rows, $keys) = @_;
    return unless defined $rows;

    $_ = [ @$_{@$keys} ] foreach @$rows;
    return $rows;
}

# helper method used by several "ccm foo -show" implementations
sub _generic_show
{
    my ($self, $cmd, $keywords, $row_type) = @_;

    my $want = _want($row_type, $keywords);
    my $format = $RS . join($FS, values %$want) . $FS;

    my ($rc, $out, $err) = $self->ccm( 
            @$cmd, qw/-u -ns -nch -nf/, -format => $format);
    return $self->set_error($err || $out) unless $rc == 0;

    # split $out at $RS and ignore the first element
    # (which is either empty or a header like "Baseline...:")
    my (undef, @records) = split(/\Q$RS\E/, $out);

    my @result;
    foreach (@records)
    {
        my @cols = split(/\Q$FS\E/, $_, -1);    # don't strip empty trailing fields
        my $row = $self->_query_result($want, \@cols, $row_type);
        push @result, $row;
    }
    return \@result;
}

sub history
{
    my $self = shift;

    my ($rc, $out, $err) = $self->_ccm(qw/history/, @_);
    return $self->set_error($err || $out) unless $rc == 0;

    return [ split(/^\*+\n?/m, $out) ];
}


sub history_arrayref
{
    my $self = shift;
    my ($file_spec, $keywords) = validate(\@_, _FILE_SPEC, _KEYWORDS);

    return _flatten_rows($self->_history($file_spec, $keywords), $keywords);
}


sub history_hashref
{
    my $self = shift;
    my ($file_spec, $keywords) = validate(\@_, _FILE_SPEC, _KEYWORDS);

    return $self->_history($file_spec, $keywords);
}


# helper: history with correct handling of multi-line attributes
# NOTE: similar to _query(..., ROW_HASH) 
sub _history
{
    my ($self, $file_spec, $keywords) = @_;

    return self->_history_classic($file_spec, $keywords)
        unless $self->web_mode;

    my $want = _want(ROW_HASH, $keywords);

    # the web mode "keywords" for predecessors and successors are
    # "%[predecessors]objectname" and "%[successors]objectname";
    # use "\n" to separate list elements and "" for an empty list
    foreach (qw( predecessors successors ))
    {
        $want->{$_} = "%{[$_]objectname[separator='\\n' null='']}" if $want->{$_};
    }

    my $format = $RS . join($FS, values %$want) . $FS;

    my ($rc, $out, $err) = $self->_ccm(qw/history -nf -format/, $format, $file_spec);
    return $self->set_error($err || $out) unless $rc == 0;

    my @result;
    foreach (split(/\Q$RS\E/, $out))            # split into records 
    {
        next unless length($_);                 # skip empty leading record

        my @cols = split(/\Q$FS\E/, $_, -1);    # don't strip empty trailing fields
        my $row = $self->_query_result($want, \@cols, ROW_HASH);

        my %cessors;
        foreach (qw( predecessors successors ))
        {
            next unless $want->{$_};
            my $list = delete $row->{$_};       # temporarily strip slot
            $cessors{$_} = [ map { $self->object($_) } split(/\n/, $list) ];
        }

        if ($want->{object})
        {
            my $obj = delete $row->{object};    # temporarily strip "object" slot...
            $obj->_update_acache($row);         # ... update $obj's cached attributes
            $row->{object} = $obj;              # ... and put "object" slot back
        }

        # put predecessors, successors slots back
        @$row{keys %cessors} = values %cessors;

        push @result, $row;
    }
    return \@result;
}

sub _history_classic
{
    my ($self, $file_spec, $keywords) = @_;

    my $want = _want(ROW_HASH, $keywords);
    my $want_predecessors = delete $want->{predecessors};
    my $want_successors = delete $want->{successors};

    my $format = $RS . join($FS, values %$want) . $FS;

    # NOTE: documentation says option "-format" is allowed,
    # but implementation accepts only "-f"
    my ($rc, $out, $err) = $self->_ccm(qw/history -f/, $format, $file_spec);
    return $self->set_error($err || $out) unless $rc == 0;

    my @result;
    foreach (split(/\Q$RS\E/, $out))            # split into records 
    {
        next unless length($_);                 # skip empty leading record

        my @cols = split(/\Q$FS\E/, $_, -1);    # don't strip empty trailing fields
        
        # NOTE: the last "column" contains the actual history information
        # (predecessors and successors), the rest is formatted like
        # a "ccm query" result
        my $history = pop @cols;

        my $row = $self->_query_result($want, \@cols, ROW_HASH);

        if ($want->{object})
        {
            my $obj = delete $row->{object};    # temporarily strip "object" slot...
            $obj->_update_acache($row);         # ... update $obj's cached attributes
            $row->{object} = $obj;              # ... and put "object" slot back
        }

        if ($want_predecessors || $want_successors)
        {
            # parse history information
            my ($predecessors, $successors) = $history =~
                /^Predecessors:\n\t?(.*)
                 ^Successors:\n\t?(.*)
                 ^\*
                /msx;

            if ($want_predecessors)
            {
                $row->{predecessors} = 
                    [ map { $self->object($_) } split(/\n\t?/, $predecessors) ];
            }
            if ($want_successors)
            {
                $row->{successors} = 
                    [ map { $self->object($_) } split(/\n\t?/, $successors) ];
            }
        }

        push @result, $row;
    }
    return \@result;
}


# not a method
# returns a new list of objects with duplicates removed 
# (takes and return an array ref)
sub _uniq_objects
{
    my ($list) = @_;
    my %uniq;
    $uniq{$_} = $_ foreach @$list;       # ye olde trick: stringified ref => ref
    return [ values %uniq ];
}


sub finduse
{
    my $self = shift;
    my ($file_specs) = validate(\@_, slurpy ArrayRef[_FILE_SPEC]);

    my ($rc, $out, $err) = $self->_ccm(qw/finduse/, @$file_specs);

    # NOTE: `ccm finduse ...' without `-query' complains if some of 
    # the given objects do not exist (and exits with status 1 unless at least
    # one exists). But for `ccm finduse -query ...', if there are no hits, 
    # the command exits with an error status and produces no output on either 
    # stdout and stderr. (This is the same behavior as for `ccm query ...'.) 
    # We will not produce an error in any case. However, the returned array
    # will contain undef in postions corresponding to non-existing objects.
    return [ ] if $rc != 0 and $out eq "" and $err eq "";
    return $self->set_error($err || $out) unless $rc == 0;

    my (@result, $uses);
    foreach (split(/\n/, $out))
    {
        s/^\s*//;

        # push undef for any non-existing objects 
        if (/Object version could not be identified/)
        {
            push @result, undef;
            next;
        }

        # ignore the dummy "use" line printed if object is not used anywhere,
        # also the dummy "Projects:" line (web mode)
        if (/Object is not used in scope|Projects:/)
        {
            next;
        }

        # a usage line is matched by finduse_rx
        if (my ($path, $proj_spec) = /$self->{finduse_rx}/)
        {
            $uses->{$self->project_object($proj_spec)} = $path;
            next;
        }

        # otherwise the line describes an object satisfying the query
        # in the format given by option `Object_format' (default:
        # "%displayname %status %owner %type %project %instance %task");
        # push it with an empty hash of uses (will be filled in by the
        # following lines)
        push(@result, [ $_, $uses = {} ]);
    }
    return \@result;
}


sub findpath
{
    my $self = shift;
    my ($file_spec, $proj_spec) = validate(\@_, _FILE_SPEC, Str);
    my $finduse = $self->finduse($file_spec);
    return unless defined $finduse;
    return $self->set_error("`$file_spec' matches more than one object") 
        unless @$finduse == 1;
    return $finduse->[0]->[1]->{$self->project_object($proj_spec)};
}


use constant _FROM_TO_NAME =>
    from => Optional[_FILE_SPEC], 
    to   => Optional[_FILE_SPEC], 
    name => Optional[Str];

sub relations_arrayref
{
    my ($self, %args) = @_;
    validate([\%args], Dict[ _FROM_TO_NAME ]);

    return _flatten_rows($self->relations_hashref(%args), [qw/ from name to create_time /]);
}


sub relations_hashref
{
    my ($self, %args) = @_;
    validate([\%args], Dict[ _FROM_TO_NAME,
                             from_attributes => Optional[ArrayRef[Str]],
                             to_attributes   => Optional[ArrayRef[Str]] ]);

    my %defaulted;
    foreach my $arg (qw/from to/)
    {
        my $attrs = "${arg}_attributes";
        next if $args{$attrs};

        # default to keyword "objectname"
        $args{$attrs} = [ qw/objectname/ ];
        $defaulted{$arg}++;
    }

    my $result = $self->_relations(\%args, ROW_HASH);
    return unless $result;

    # if we defaulted "objectname" above, replace the corresponding
    # hash containing the sole key "objectname" with its value
    foreach my $arg (qw/from to/)
    {
        if ($defaulted{$arg})
        {
            $_->{$arg} = $_->{$arg}->{objectname} foreach @$result;
        }
    }
    return $result;
}


sub relations_object
{
    my ($self, %args) = @_;
    validate([\%args], Dict[ _FROM_TO_NAME,
                             from_attributes => Optional[ArrayRef[Str]],
                             to_attributes   => Optional[ArrayRef[Str]] ]);

    $args{$_} ||= [] foreach qw/from_attributes to_attributes/;
                                # coz _relations() likes 'em defined

    return $self->_relations(\%args, ROW_OBJECT);
}


# helper method: synthesize command and parse result of "ccm relate -show ..."
sub _relations
{
    my ($self, $args, $row_type) = @_;
    # NOTES: 
    # (1) $args->{from_attributes}/$args->{to_attributes} must not be undef
    # (2) only ROW_HASH and ROW_OBJECT are allowed for $row_type


    my $want_from = _want($row_type, $args->{from_attributes});
    my $ncol_from = keys %$want_from;
    my $want_to   = _want($row_type, $args->{to_attributes});
    my $ncol_to   = keys %$want_to;
    my $format;

    if ($self->web_mode)
    {
        # NOTE: Web mode wants "%[from]keyword" and "%[to]keyword", resp.,
        # instead of just "%keyword" for from_attributes
        # and to_attributes, resp.
        s/^%/%[from]/ foreach values %$want_from;
        s/^%/%[to]/   foreach values %$want_to;

        $format =
            $RS .                       # record delimiter
            join($FS,                   # column separator
                values %$want_from,     # "from" part
                "%name",                # name of relation
                values %$want_to,       # "to" part
                "%create_time");        # create_time of relation
    }
    else                                # classic mode
    {
        # NOTE: If the "from" part (the part before "::") of the format
        # or the "to" part are empty, Synergy may default it from
        # the other part. Hence both "from" and "to" part below are never
        # empty, even if $want_from or $want_to are empty.

        $format = 
            $RS .                       # record delimiter
            join($FS,                   # column separator
                values %$want_from,     # "from" part
                "::",                   # will be replaced by name of relation
                values %$want_to) .     # "to" part
            $FS;                        # will be followed by create_time
    }

    my ($rc, $out, $err) = $self->_ccm(
        qw/relate -show -nf -format/ => $format, 
            map { defined $args->{$_} ? ( "-$_" => $args->{$_}) : () } 
                qw/from to name/);

    # NOTE: If there are no hits, `ccm relate' exits 
    # with status 1 (classic mode) or 6 (web mode),
    # but produces no output on either stdout and stderr.
    return [ ] if $rc != 0 and $out eq "" and $err eq "";
    return $self->set_error($err || $out) unless $rc == 0;

    my (@result, $from, $to);
    foreach (split(/\Q$RS\E/, $out))            # split into records 
    {
        next unless length($_);                 # skip empty leading record

        my @cols = split(/\Q$FS\E/, $_, -1);    # don't strip empty trailing fields

        # first $ncol_from columns are the "from" part;
        # avoid to parse "from" part more than once if "from => ..." was specified
        my @cols_from = splice(@cols, 0, $ncol_from);
        $from = $self->_query_result($want_from, \@cols_from, $row_type)
            unless $args->{from} && $from;

        # next column is the name of the relation; trim whitespace
        (my $name = shift @cols) =~ s/^\s+|\s+$//g;     

        # next $ncol_to columns are the "to" part;
        # avoid to parse "to" part more than once if "to => ..." was specified
        my @cols_to = splice(@cols, 0, $ncol_to);
        $to = $self->_query_result($want_to, \@cols_to, $row_type)
            unless $args->{to} && $to;

        # last column is the create_time of the relation; trim whitespace
        (my $create_time = shift @cols) =~ s/^\s+|\s+$//g;

        push @result, 
            {
                from            => $from,
                to              => $to,
                name            => $name,
                create_time     => $create_time,
            };
    }
    return \@result;
}



sub project_tree
{
    my $self = shift;
    my ($options, $projects) = 
        validate(\@_, (Undef | HashRef), slurpy ArrayRef[_PROJECT_SPEC]);

    # make a copy of $options, because we're modifying it below
    my %wanted = %{ $options || {} };           # Note: $options may be undef

    my $mark_projects = delete $wanted{mark_projects};
    $wanted{pathsep} ||= VCS::CMSynergy::Client::_pathsep;
    my $omit_rx = (delete $wanted{omit_top_dir}) 
                  && qr/^.*?\Q$wanted{pathsep}\E/; # everything up to the first pathsep
    # NOTE: all other options are passed thru to traverse() 
    # (and get checked there)

    my (%tree, $idx);           # referenced in closure below
    $wanted{wanted} = sub
    {
        # skip projects unless "mark_projects" is in effect
        return if $_->is_project && !$mark_projects;

        # store into %tree with relative workarea pathname as the key
        # NOTE: VCS::CMSynergy::Traversal::path() has the same
        # value when invoked for a project and its top level
        # directory; the "||=" below makes sure we dont't overwrite
        # the project entry when "mark_projects" is in effect
        my $path = VCS::CMSynergy::Traversal::path();
        if ($omit_rx)
        {
            $path =~ s/$omit_rx// or return; # drop top level entirely
        }
        @$projects == 1 ? $tree{$path} : $tree{$path}->[$idx] ||= $_;
    };

    $idx = 0;
    foreach my $proj (@$projects)
    {
        $proj = $self->project_object($proj) unless ref $proj;

        $proj->traverse(\%wanted) or return;
        $idx++;
    }

    return \%tree;
}


sub project_diff
{
    my $self = shift;
    my ($options, $old_project, $new_project, $differ) = 
        validate(\@_, (Undef | HashRef), _PROJECT_SPEC, _PROJECT_SPEC, HasMethods[qw( added deleted changed )]);

    # make a copy of $options, because we're modifying it below
    my %opts = %{ $options || {} };     # Note: $options may be undef

    my $hide_sub_trees = delete $opts{hide_sub_trees};

    # FIXME lift this hardcoded restriction:
    # we must also adjust the regex below (to extract dirname from $path)
    $opts{pathsep} = "/";    

    my $tree = $self->project_tree(\%opts, $old_project, $new_project);

    $differ->start($old_project, $new_project) if $differ->can("start");

    # NOTE: the hiding of subtrees depends on an ordering of keys %tree
    # that sorts "foo/bar/quux" _after_ "foo/bar"
    my %hidden;                 # directory paths of deleted/added dirs
    foreach my $path (sort keys %$tree)
    {
        my ($old, $new) = @{ $tree->{$path} };

        if (!defined $new)
        { 
            # only report the root of a deleted sub tree?
            if ($hide_sub_trees)
            {
                $hidden{$path}++ if $old->is_dir;
                (my $dirname = $path) =~ s:/[^/]*$::;
                next if $hidden{$dirname};
            }
            $differ->deleted($path, $old); 
        }
        elsif (!defined $old)
        { 
            # only report the root of an added sub tree?
            if ($hide_sub_trees)
            {
                $hidden{$path}++ if $new->is_dir;
                (my $dirname = $path) =~ s:/[^/]*$::;
                next if $hidden{$dirname};
            }
            $differ->added($path, $new);
        }
        elsif ($old ne $new)    
        { 
            $differ->changed($path, $old, $new); 
        }
        else                    
        {
            $differ->identical($path, $old) if $differ->can("identical");
        }
    }

    return $differ->can("finish") ? $differ->finish : undef;
}


sub get_attribute
{
    my $self = shift;
    my ($name, $file_spec) = validate(\@_, Str, _FILE_SPEC);

    my ($rc, $out, $err) = $self->_ccm(qw/attribute -show/, $name, $file_spec);
    return $out if $rc == 0;
    return if ($err || $out) =~ /Attribute .* does not exist/;
    return $self->set_error($err || $out);
}


sub set_attribute
{
    my $self = shift;
    my ($name, $file_spec, $value) = validate(\@_, Str, _FILE_SPEC, Str);


    # try "ccm attribute -modify ..." first
    my ($rc, $out, $err) = $self->_ccm_attribute(
        -modify => $name, -value => $value, $file_spec);

    # if this fails because the attribute is inherited,
    # try "ccm attribute -force -create ..."
    if ($rc != 0 && ($err || $out) =~ /Attribute .* is inherited/)
    {
        # determine attribute's type 
        my $type = $self->list_attributes($file_spec)->{$name}
            or return $self->set_error(
                "oops: attribute $name on `$file_spec' seems inherited, but doesn't show with `ccm attr -la'");
        
        ($rc, $out, $err) = $self->_ccm_attribute(
            -create => $name, -value => $value, -type => $type, -force => $file_spec);
    }

    return $value if $rc == 0;
    return $self->set_error($err || $out);
}


# helper method (used for "ccm attr -modify" and "ccm attr -force -create")
sub _ccm_attribute
{
    my ($self, @args) = @_;     # @args must contain ..., -value => $value, ...

    # squeeze -value => $value from @args
    my $value;
    for (my $i = 0; $i < @args; $i++)
    {
        next unless $args[$i] =~ /^-(?:v|value)$/;
        (undef, $value) = splice(@args, $i, 2);
        last;
    }
    croak(__PACKAGE__.qq[::_ccm_attribute: mssing argument "-value"])
        unless defined $value;

    my @cmd = ("attribute", @args);
    if ($value eq "")
    {
        # Setting a text attribute to an empty string is a real PITA:
        # - Synergy will launch text_editor, even if "-v ''" was specified
        # - if the temporary file containing the attribute's value is empty 
        #   after the editor exits, Synergy prompts with:
        #       Result of edit is an empty attribute.
        #       Confirm: (y/n) [n] 
        
        # the following doesn't work on Windows (CCM seems to read 
        # the confirmation answer directly from CON:, _not_ from stdin)
        croak(__PACKAGE__."::_ccm_attribute: setting a text attribute to an empty string is not supported on Windows")
            if is_win32;

        return $self->_ccm_with_option(
            text_editor => $^O eq 'MSWin32' ?
                qq[cmd /c echo off > $self->{"%filename"}] :    #/
                qq[$Config{cp} /dev/null $self->{"%filename"}],
            @cmd, { in =>  \"y\n" });
    }

    if (($self->{coprocess} && (length($value) > 1600 || $value =~ /["\r\n]/))
        || (is_win32 && (length($value) > 100 || $value =~ /[%<>&"\r\n]/)))
    {
        # Use ye olde text_editor trick if $value may cause problems
        # (depending on execution mode and platform) because its
        # too long or contains unquotable characters or...
        return $self->ccm_with_text_editor($value, @cmd);
    }

    return $self->_ccm(@cmd, -value => $value);
}


sub create_attribute
{
    my $self = shift;
    my ($name, $type, $value, $file_specs) = 
        validate(\@_, Str, Str, Str, slurpy ArrayRef[_FILE_SPEC]);

    my ($rc, $out, $err) = $self->_ccm_attribute(
            -create => $name, -value => $value, -type => $type, @$file_specs);
    return $self->set_error($err || $out) unless $rc == 0;
    return 1;
}


sub delete_attribute
{
    my $self = shift;
    my ($name, $file_specs) = validate(\@_, Str, slurpy ArrayRef[_FILE_SPEC]);

    return scalar $self->ccm(qw/attribute -delete/, $name, @$file_specs);
}


sub copy_attribute
{
    my $self = shift;

    # extract flags first (makes validation easier)
    my @flags;
    @flags = map { "-$_" } @{ splice(@_, 1, 1) } if defined $_[1] && ref $_[1] eq "ARRAY";
    
    my ($names, $file_specs) = validate(\@_, (Str | ArrayRef[Str]), slurpy ArrayRef[_FILE_SPEC]);
    $names = join(':', @$names) if ref $names eq "ARRAY";

    return scalar $self->ccm(qw/attribute -copy/, $names, @flags, @$file_specs);
}


sub list_attributes
{
    my $self = shift;
    my ($file_spec) = validate(\@_, _FILE_SPEC);

    my ($rc, $out, $err) = $self->_ccm(qw/attribute -la/, $file_spec);
    return $self->set_error($err || $out) unless $rc == 0;

    # NOTE: regex works for both classic mode and web mode
    my %attrs = $out =~ /^(\S+) \s+ \(? (\S+?) [\s)]/gmx;
    return \%attrs;
}


sub properties_hashref
{
    my $self = shift;
    my ($file_specs, $keywords) = validate(\@_, ArrayRef[_FILE_SPEC], _KEYWORDS);

    return $self->_properties($file_specs, $keywords, ROW_HASH);
}

sub properties_object
{
    my $self = shift;
    my ($file_specs, $keywords) = validate(\@_, ArrayRef[_FILE_SPEC], _KEYWORDS);

    return $self->_properties($file_specs, $keywords, ROW_OBJECT);
}

sub _properties
{
    my ($self, $file_specs, $keywords, $row_type) = @_;
    # NOTE: only ROW_HASH and ROW_OBJECT are allowed for $row_type

    return [ ] if @$file_specs == 0;            # silly, but consistent

    my $want = _want($row_type, $keywords);
    my $format = $RS . join($FS, values %$want) . $FS;

    my ($rc, $out, $err) = 
        $self->_ccm(qw/properties -nf -format/, $format, @$file_specs);
    return $self->set_error($err || $out) unless $rc == 0;

    my @result;
    foreach (split(/\Q$RS\E/, $out))            # split into records 
    {
        next unless length($_);                 # skip empty leading record

        my @cols = split(/\Q$FS\E/, $_, -1);    # don't strip empty trailing fields
        push @result, $self->_query_result($want, \@cols, $row_type);
    }
    return \@result;
}


sub property
{
    my $self = shift;
    my ($keyword_s, $file_spec) = 
        validate(\@_, (Str | ArrayRef[Str]), _FILE_SPEC);

    if (ref $keyword_s)
    {
        # return a hash ref of property names and values
        return $self->_property($file_spec, $keyword_s, ROW_HASH);
    }
    else
    {
        # return just the property value
        my $row = $self->_property($file_spec, [ $keyword_s ], ROW_HASH) or return;
        return $row->{$keyword_s};
    }
}


sub _property
{
    my ($self, $file_spec, $keywords, $row_type) = @_;
    # NOTE: only ROW_HASH and ROW_OBJECT are allowed for $row_type

    my $want = _want($row_type, $keywords);
    my $format = $RS . join($FS, values %$want) . $FS;

    my ($rc, $out, $err) = 
        $self->_ccm(qw/properties -nf -format/, $format, $file_spec);
    return $self->set_error($err || $out) unless $rc == 0;

    my (undef, $props) = split(/\Q$RS\E/, $out, -1);
    my @cols = split(/\Q$FS\E/, $props, -1);    # don't strip empty trailing fields
    return $self->_query_result($want, \@cols, $row_type);
}

sub cat_object
{
    my $self = shift;

    my $want_return = @_ == 1;
    my ($file_spec, $destination) = 
        validate(\@_, _FILE_SPEC, Optional[Str | GlobRef | FileHandle | ScalarRef]);

    my $out;
    $destination = \$out if $want_return;

    my ($rc, undef, $err) = $self->_ccm(
        cat => $file_spec, 
        { out => $destination, binmode_stdout => ':raw' });

    if (get_logger()->is_trace)
    {
        TRACE 
            ref $destination eq ""
            ? sprintf("-> out written to file \"%s\"", $destination) :
            ref $destination eq "SCALAR"
            ? sprintf("-> out captured to string (%d bytes)", length($$destination)) 
            : "-> out redirected to filehandle";
    }

    return $self->set_error($err || "`ccm cat $file_spec' failed") 
        unless $rc == 0;
    return $want_return ? $out : 1;
}


sub types
{
        my $self = shift;
        my ($rc, $out, $err) = $self->_ccm(qw/show -types/);
        return $self->set_error($err || $out) unless $rc == 0;
        return split(/\n/, $out);
}


sub migrate_auto_rules
{
        my $self = shift;
        my ($rc, $out, $err) = $self->_ccm(qw/show -migrate_auto_rules/);
        return $self->set_error($err || $out) unless $rc == 0;
        return map { [ split(/ /, $_) ] } split(/\n/, $out);
}


sub ls
{
    my $self = shift;

    my ($rc, $out, $err) = $self->_ccm(qw/ls/, @_);
    return $self->set_error($err || $out) unless $rc == 0;

    # filter out messages that a file has been implicitly synced 
    return [ grep { !/^\tUpdating database/ } split(/\n/, $out) ];
}


sub ls_arrayref
{
    my $self = shift;
    my ($file_spec, $keywords) = validate(\@_, _FILE_SPEC, _KEYWORDS);

    return _flatten_rows($self->_ls($file_spec, $keywords, ROW_HASH), $keywords);
}


sub ls_hashref
{
    my $self = shift;
    my ($file_spec, $keywords) = validate(\@_, _FILE_SPEC, _KEYWORDS);

    return $self->_ls($file_spec, $keywords, ROW_HASH);
}


sub ls_object
{
    my $self = shift;
    my ($file_spec, $keywords) = validate(\@_, _FILE_SPEC, _KEYWORDS);

    return $self->_ls($file_spec, $keywords, ROW_OBJECT);
}


sub _ls
{
    my ($self, $file_spec, $keywords, $row_type) = @_;

    my $want = _want($row_type, $keywords);
    
    my $format = $RS . join($FS, values %$want) . $FS;

    my ($rc, $out, $err) = $self->_ccm(qw/ls -format/, $format, $file_spec);
    return $self->set_error($err || $out) unless $rc == 0;

    # filter out messages that a file has been implicitly synced 
    $out =~ s/^\tUpdating database.*?(?:\n|\z)//m;

    my @result;
    foreach (split(/\Q$RS\E/, $out))            # split into records 
    {
        next unless length($_);                 # skip empty leading record

        my @cols = split(/\Q$FS\E/, $_, -1);    # don't strip empty trailing fields
        my $row = $self->_query_result($want, \@cols, $row_type);
        push @result, $row;
    }
    return \@result;
}

    
sub set
{
    my $self = shift;
    my ($option, $value) = validate(\@_, Optional[Str], Optional[Str]);

    if (@_ == 0)
    {
        my ($rc, $out, $err) = $self->_ccm(qw/set/);
        return $self->set_error($err || $out) unless $rc == 0;

        my %options;
        while ($out =~ /^(\S+) = (.*)$/gm)
        {
            $options{$1} = $2 eq "(unset)" ? undef : $2;
        }
        return \%options;
    }

    my ($rc, $out, $err);
    my $old_value;

    # no need to get old value if we are called in void context
    if (defined wantarray)
    {
        my ($rc, $out, $err) = $self->_set($option);
        return $self->set_error($err || $out) unless $rc == 0;
        $old_value = $out;
    }

    if (@_ == 2)
    {
        my ($rc, $out, $err) = $self->_set($option, $value);
        return $self->set_error($err || $out) unless $rc == 0;
    }
    
    return $old_value;
}

sub _set
{
    my ($self, $option, $new_value) = @_;

    if (@_ == 2)
    {
        my ($rc, $out, $err) = $self->_ccm(set => $option);
        $out = undef if $rc == 0 &&  $out eq "(unset)";
        return ($rc, $out, $err);
    }

    if (@_ == 3)
    {
        my ($rc, $out, $err) = defined $new_value ?
            $self->_ccm(set => $option, $new_value) :
            $self->_ccm(unset => $option);
        return ($rc, $out, $err);
    }
    
    return _error("wrong number of arguments");
}


# helper: save value of $option, set it to $new_value, 
#  call _ccm(@args), restore $option; returns ($rc, $out, $err)
#  (usually the return value from _ccm(@args) except there were errors
#  in setting the option)
sub _ccm_with_option
{
    my ($self, $option, $new_value, @args) = @_;

    my ($rc, $out, $err);

    WITH_OPTION:
    {
        ($rc, $out, $err) = $self->_set($option);
        last WITH_OPTION unless $rc == 0;
        my $old_value = $out;

        ($rc, $out, $err) = $self->_set($option, $new_value);
        last WITH_OPTION unless $rc == 0;

        my @result = $self->_ccm(@args);

        ($rc, $out, $err) = $self->_set($option, $old_value);
        last WITH_OPTION unless $rc == 0;

        ($rc, $out, $err) = @result;
    }

    return ($rc, $out, $err);
}

# helper: write text to temporary file and return its name
# BEWARE: may re-use the same temporary file (deleted on script exit)
sub _text_to_tempfile
{
    my ($self, $text) = @_;

    my $fh;
    if ($self->{_tempfile})
    {
        open $fh, ">", $self->{_tempfile}
            or return $self->set_error(qq[can't open temp file "$self->{_tempfile}": $!]); #'
    }
    else
    {
        ($fh, $self->{_tempfile}) = tempfile(UNLINK => 1)
            or return $self->set_error(qq[can't create temp file: $!]); #'
    }
    print $fh $text;
    close $fh;

    return $self->{_tempfile};
}

# helper: implements ye olde text_editor trick for ccm commands
# that would interactively open an editor in order to let the user modify
# some (text) value; ccm_with_text_editor writes $text_value 
# to a temporary file, then calls ccm_with_option with
# text_editor="cp temporary_file %filename" and returns its results
# calls $self->_ccm(@args).
sub ccm_with_text_editor
{
    my $self = shift;
    my ($text, $args) = validate(\@_, Str, slurpy ArrayRef);

    my $tempfile = $self->_text_to_tempfile($text) or return;

    # NOTE: 
    # (1) On Win32 $Config{cp} is "copy", but Synergy doesn't invoke
    #     the command processor on Windows when executing user
    #     callbacks like "text_editor"; thus "shell" builtins like "copy"
    #     (and redirection) won't work in user callbacks; hence 
    #     prefix it with "cmd /c" (use "/b" to get a binary copy
    #     and "/y" to overwite files without prompting).
    # (2) On Cygwin $Config{cp} is "cp", i.e. a Cygwin program.
    #     Hence it is safe to pass the Cygwin pathname $tempfile to it.
    my ($rc, $out, $err) = $self->_ccm_with_option(
        text_editor => $^O eq 'MSWin32' ?
            qq[cmd /c copy /b /y "$tempfile" $self->{"%filename"}] :            #/
            qq[$Config{cp} "$tempfile" $self->{"%filename"}],
        @$args);
    return $self->set_error($err || $out) unless $rc == 0;
    return wantarray ? ($rc, $out, $err) : 1;
}


__PACKAGE__->_memoize_method(dcm_delimiter => sub
{
    my $self = shift;

    my ($rc, $out, $err) = $self->_ccm(qw/dcm -show -delimiter/);
    return $self->set_error($err || $out) unless $rc == 0;

    return $out;
});


__PACKAGE__->_memoize_method(dcm_database_id => sub
{
    my $self = shift;

    my ($rc, $out, $err) = $self->_ccm(qw/dcm -show -database_id/);
    return $self->set_error($err || $out) unless $rc == 0;

    return $out;
});


sub dcm_enabled         { shift->dcm_database_id ne ""; }


__PACKAGE__->_memoize_method(default_project_instance => sub
{
    my $self = shift;
    return $self->dcm_enabled ?
        $self->dcm_database_id . $self->dcm_delimiter . '1' : '1';
});


sub _projspec2objectname
{
    my ($self, $project) = @_;
    $project .= ':project:' . $self->default_project_instance
        unless $project =~ /:project:/;
    return $project;
}

sub _must_be_one_of
{
    my ($what, @choices) = @_;
    croak(qq["$what" must be one of ].join(", ", @choices))
        unless grep { $_ eq $what } @choices;
}


# generic wrapper for undefined method "foo":
#       $ccm->foo(@args)
# gets turned into
#       $ccm->ccm("foo", @args)
# in fact, we create a method `foo' on the fly with this definition
sub AUTOLOAD
{
    my ($this) = @_;

    our $AUTOLOAD;

    # NOTE: the fully qualified name of the method has been placed in $AUTOLOAD
    my ($class, $method) = $AUTOLOAD =~ /^(.*)::([^:]*)$/;
    return if $method eq 'DESTROY'; 

    # we don't allow autoload of class methods
    croak(qq[Can't locate class method "$method" via class "$class"]) #'
        unless ref $this;
    DEBUG qq[autoloading method "$method"];

    # create the new method on the fly
    no strict 'refs';
    *{$method} = sub { return shift->ccm($method, @_) };

    # call it w/o pushing a new stack frame (with same parameters)
    goto &$method;
}


# test whether session is still alive (without causing an exception)
sub ping
{
    my ($rc) = shift->_ccm(qw/delimiter/);
    return $rc == 0;
}


# $ccm->object(objectname) => VCS::CMSynergy::Object
# $ccm->object(name, version, cvtype, instance) => VCS::CMSynergy::Object
sub object
{
    my $self = shift;

    croak(__PACKAGE__."::object: invalid number of arguments" .
          "\n  usage: \$ccm->object(\$name, \$version, \$cvtype, \$instance)" .
          "\n  or     \$ccm->object(\$objectname)")
        unless @_ == 1 || @_ == 4;
    
    return VCS::CMSynergy::Object->new($self, @_ == 4 ? join(":", @_) : $_[0]);
}

# convenience methods to get the base model object etc
# NOTE: base_model should actually be determined from attribute "active_model"
# of "default-1:admin:AC" (the value is an old-style fullname,
# but I've never seen anything else than "base/model/base/1").
sub base_model  { $_[0]->object("base:1:model:base"); }
sub base_admin  { $_[0]->object("base:1:admin:base"); }
sub dcm_admin   { $_[0]->object("dcm:1:admin:dcm"); }
sub cs_admin    { $_[0]->object("cs:1:admin:1"); }
sub cvtype      { $_[0]->object("$_[1]:1:cvtype:base"); }
sub attype      { $_[0]->object("$_[1]:1:attype:base"); }


# do a query_object() and expect exactly one result, error out otherwise
sub _query_object_unique
{
    my $self = shift;

    my $objs = $self->query_object(@_);
    return $objs->[0] if @$objs == 1;

    my $query = $self->_expand_query($_[0]);
    return $self->set_error(@$objs == 0
        ? qq[no object matches query "$query"]
        : qq[multiple objects match query "$query": @$objs]);
}


# get folder/task/... object from displayname
sub baseline_object
{
    my $self = shift;
    my ($baseline_name, @keywords) = @_;
    return $self->_query_object_unique("baseline('$baseline_name')", @keywords);
}

sub cr_object
{
    my $self = shift;
    my ($cr_id, @keywords) = @_;
    return $self->_query_object_unique("cr('$cr_id)'", @keywords);
}

sub folder_object
{
    my $self = shift;
    my ($folder_id, @keywords) = @_;
    return $self->_query_object_unique("folder('$folder_id')", @keywords);
}

sub project_object
{
    $_[0]->object($_[0]->_projspec2objectname($_[1]));
}

sub task_object
{
    my $self = shift;
    my ($task_id, @keywords) = @_;
    return $self->_query_object_unique("task('$task_id')", @keywords);
}

sub tset_object
{
    my $self = shift;
    my ($tset_name, @keywords) = @_;
    return $self->_query_object_unique([ type => "tset", tset_name => $tset_name ], @keywords);
}


# $ccm->object_other_version(object, version) => VCS::CMSynergy::Object
#       new Object with same name/cvtype/instance as OBJECT, but version VERSION
sub object_other_version
{
    my $self = shift;
    my ($object, $other_version) = 
        validate(\@_, InstanceOf["VCS::CMSynergy::Object"], Str);

    return $self->object($object->name, $other_version, $object->cvtype, $object->instance);
}


# $ccm->object_from_cvid(cvid) => VCS::CMSynergy::Object
sub object_from_cvid
{
    my $self = shift;
    my ($cvid, $keywords) = validate(\@_, Str, _KEYWORDS);

    return $self->_property("\@=$cvid", $keywords, ROW_OBJECT);
    # NOTE: if the cvid doesn't exist, "ccm property ..." has exit code 0, but 
    # "Warning: Object version representing type does not exist." on stderr
}


# $ccm->object_from_proj_ref($path, $proj_spec) => VCS::CMSynergy::Object
sub object_from_proj_ref
{
    my $self = shift;
    my ($path, $proj_spec, $keywords) =
        validate(\@_, (Str | ArrayRef[Str]), _PROJECT_SPEC, _KEYWORDS);

    $path = join(VCS::CMSynergy::Client::_pathsep, @$path) if ref $path; 
    $proj_spec = $proj_spec->displayname if ref $proj_spec;
    return $self->_property("$path\@$proj_spec", $keywords, ROW_OBJECT);
    # NOTE/FIXME: no error if path isn't bound? possible errors:
    #   Specified project not found in database: '$self'
    #   Object version could not be identified from reference form: '$path'
}


1;

