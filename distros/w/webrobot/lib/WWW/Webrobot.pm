package WWW::Webrobot;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004-2006 ABAS Software AG

*VERSION = \'0.81';

use Carp;
use WWW::Webrobot::Properties;
use WWW::Webrobot::SymbolTable;
use WWW::Webrobot::XML2Tree;
use WWW::Webrobot::TestplanRunner;
use WWW::Webrobot::Global;
use WWW::Webrobot::AssertDefault;
use WWW::Webrobot::XHtml;


my %arg_default = (
                   data => {},
                   option => {},
                   assert => WWW::Webrobot::AssertDefault -> new(),
                   description => '',
                   useragent => '',
                   http_header => {},
                   define => {},
                   is_recursive => 0,
                   fail_str => '',
                   fail => -1,
                  );

=head1 NAME

WWW::Webrobot - Run Testplans

=head1 SYNOPSIS

 use WWW::Webrobot;
 WWW::Webrobot -> new($cfg) -> run($test_plan);

configures Webrobot with $cfg, reads a testplan and executes this plan

=head1 DESCRIPTION

Runs a testplan according to a configuration.

=head1 METHODS

=over

=item $wr = WWW::Webrobot -> new( $cfg_name, $cmd_param );

Construct an object.

 $cfg_name
     SCLAR: config string
     REF  : Name of the config file
 $cmd_param
     ??? to be documented

Example:
 $wr = WWW::Webrobot->new(\"configfile.cfg");
 $wr = WWW::Webrobot->new(<<EOF);
 names=first=value
 names=second=another value
 EOF

=cut

sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    my ($cfg_name, $cmd_param) = @_;
    $self->cfg($cfg_name, $cmd_param) if defined $cfg_name;
    return $self;
}


=item $wr -> cfg();

Get the config data.

=item $wr -> cfg($cfg_name, $cmd_properties);

Read in the config data from a file named $cfg.
Add all properties in $cmd_properties.
$cmd_properties is a ref to a list of key/value pairs.

Example:
    $cmd_properties = [[key0, value0], [key1, value1], ...];

Note:
Currently $cfg_name may also be a (internal) hash.
It is needed for webrobot-load but is declared deprecated.

=cut

sub cfg {
    my ($self, $cfg, $cmd_param) = @_;
    confess("config data: hash no more allowed")
        if (ref $cfg eq "HASH"); # formerly allowed, check for unclean updates
    $self->{cfg} = __PACKAGE__->read_configuration($cfg, $cmd_param) if defined $cfg;
    return $self->{cfg};
}


=item $wr -> run($test_plan);

=over

=item $test_plan

Read in the testplan from a file $test_plan and run it.
If $test_plan is SCALAR it is taken as a string,
if $test_plan is a reference it is taken as a file name.

Example:
 $wr->run(\"xml_file.xml");
 $wr->run(<<EOF);
 <?xml version="1.0" encoding="iso-8859-1"?>
 <plan>
     <request>
         <method value='POST'/>
         <url value='${application}/content'/>
     </request>
 </plan>
 EOF

=back


=cut

sub run {
    my $self = shift;
    my ($test_plan_name, $child_id) = @_;
    $child_id ||= 1;
    #my $cfg = $self -> cfg() or die "Missing config definition";

    $test_plan_name = $test_plan_name || $self->cfg->{testplan} or
        die "No testplan defined!";
    WWW::Webrobot::Global->plan_name(ref $test_plan_name ? $$test_plan_name : "__IN_MEMORY__");

    my $sym_tbl = WWW::Webrobot::SymbolTable->new();
    foreach (@{$self->cfg->{names}}) {
        my ($key, $value) = @$_;
        $sym_tbl -> define_symbol($key, $sym_tbl->evaluate($value));
    }
    $sym_tbl -> define_symbol("_id", $child_id);
    my $test_plan = __PACKAGE__->read_testplan($test_plan_name, $sym_tbl);

    $sym_tbl = WWW::Webrobot::SymbolTable->new();
    return WWW::Webrobot::TestplanRunner -> new() -> run($test_plan, $self->cfg, $sym_tbl);
}

sub read_testplan {
    my ($pkg, $test_plan_name, $sym_tbl) = @_;

    my $parser = WWW::Webrobot::XML2Tree->new();
    my $tree =
        (! ref $test_plan_name) ?  $parser -> parse($test_plan_name) :
        (ref $test_plan_name eq 'SCALAR') ? $parser -> parsefile($$test_plan_name) :
        undef;

    # expand all properties
    $sym_tbl->evaluate($tree);

    # convert test plan tree to internal data structure
    my $test_plan = xml2testplan($tree, $sym_tbl);

    # check and normalize 'test_plan'
    die "Can't read file $test_plan_name, err=$?, msg=$@" if $@;
    ref($test_plan) or die "No valid testplan!";
    foreach (@$test_plan) {
        $_ = {%arg_default, %$_};
    }
    return $test_plan;
}

sub assert {
    my ($cond, $text) = @_;
    croak "$text" if !$cond;
}

sub xml2testplan {
    my ($tree, $sym_tbl) = @_;
    my $plan = xml2plan($tree, $sym_tbl);
    return $plan;
}

sub xml2plan {
    my ($tree, $sym_tbl) = @_;
    my $attributes = $tree->[0];
    my $tag = $tree->[1];
    my $content = $tree->[2];
    assert($tag eq "plan", "<plan> expected");
    my $plan = xml2planlist($content, $sym_tbl);
    return $plan;
}

sub xml2planlist {
    my ($tree, $sym_tbl) = @_;

    my $plan = [];
    my $attributes = $tree->[0];
    for (my $i = 1; $i < @$tree; $i += 2) {
        my $tag = $tree->[$i];
        my $content = $tree->[$i+1];
        SWITCH: foreach ($tag) {
            ! $_ and do { last }; # skip white space, obsolete?
            /^plan$/ and do {
                my $plan_attributes = $content->[0];
                my $action = $plan_attributes->{action};
                assert(!defined $action || $action eq "shuffle",
                       "action='$action' not allowed, expected [shuffle]");
                my $sub_plan = xml2planlist($content, $sym_tbl);
                fisher_yates_shuffle($sub_plan) if $action eq "shuffle";
                push @$plan, @$sub_plan;
                last;
            };
            /^request$/ and do {
                assert(ref $content eq 'ARRAY', "Test plan request expected");
                push @$plan, request2entry($content);
                last;
            };
            /^include$/ and do {
                my $attr = $content->[0];
                my $fname = $attr->{file};
                my @list = @$content[1 .. @$content-1];
                my $parm = get_data(\@list);
                $sym_tbl->push_scope();
                foreach (keys %$parm) {
                    $sym_tbl->define_symbol($_, $parm->{$_});
                }
                my $iplan = __PACKAGE__->read_testplan(\$fname, $sym_tbl);
                push @$plan, @$iplan;
                $sym_tbl->pop_scope();
                last;
            };
            /^cookies$/ and do {
                for ($content->[0]->{value} || "") {
                    assert(m/^on$/i || m/^off$/i || m/^clear$/i || m/^clear_temporary$/i,,
                           "found '$_', expected one of [on, off, clear, clear_temporary]");
                    push @$plan, {method => "COOKIES", url => "$_"};
                }
                last;
            };
            /^referrer$/ and do {
                for ($content->[0]->{value} || "") {
                    assert(m/^on$/i || m/^off$/i || m/^clear$/i,
                           "found '$_', expected 'on', 'off, 'clear'");
                    push @$plan, {method => "REFERRER", url => "$_"};
                }
                last;
            };
            /^config$/ and do {
                my @mode = ();
                push @mode, ["filename", $content->[0]->{filename} || ""] if $content->[0]->{filename};
                push @mode, ["script"  , $content->[0]->{script  } || ""] if $content->[0]->{script};
                my $cfg = config2entry($content);
                push @$plan, {method => "CONFIG", property => $cfg->{property}, _mode => \@mode, url => ""};
                last;
            };
            /^sleep$/ and do {
                push @$plan, {method => "SLEEP", url => $content->[0]->{value} || 1};
                last;
            };
            /^global-assertion$/ and do {
                my @assert = @$content[1 .. @$content-1];
                my $mode_src = $content->[0]->{mode} || "";
                my $mode = $mode_src || "add";
                assert($mode eq "new" || $mode eq "add", "<global-assertion>: found attribute mode='$mode_src', expected 'new', 'add'");
                push @$plan, {method => "GLOBAL-ASSERTION", url => "", mode => $mode, global_assert_xml => \@assert};
                last;
            };
            assert(0, "found <$tag>, expected <plan>, <request>, <include>, <cookies>, <referrer>, <config>, <sleep>, <global-assertion>");
        }
    }
    return $plan;
}


sub config2entry { # copied from request2entry, may be subject to be joined
    my ($tree) = @_;

    my %entry = ();

    my $attributes = $tree->[0];
    for (my $i = 1; $i < @$tree; $i += 2) {
        my $tag = $tree->[$i];
        my $content = $tree->[$i+1];

        next if !$tag; # skip white space
        my $attr = $content->[0];
        # ??? obsolete iff CDATA->value
        my @list = @$content[1 .. @$content-1];
        if (@list > 1 && ! $list[0] && ! exists $attr->{value}) {
            $attr->{value} = $list[1];
        }
        SWITCH: foreach ($tag) {
            /^property$/ and do {
                foreach (qw/value/) {
                    if ($attr->{$_}) {
                        push @{$entry{property}}, [$_, $attr->{name}, $attr->{$_}];
                        last;
                    }
                }
                last;
            };
            assert(0, "found <$tag>, expected <property>");
        }
    }
    return \%entry;
}

sub request2entry {
    my ($tree) = @_;

    my %entry = ();

    my $attributes = $tree->[0];
    for (my $i = 1; $i < @$tree; $i += 2) {
        my $tag = $tree->[$i];
        my $content = $tree->[$i+1];

        next if !$tag; # skip white space
        my $attr = $content->[0];
        # ??? obsolete iff CDATA->value
        my @list = @$content[1 .. @$content-1];
        if (@list > 1 && ! $list[0] && ! exists $attr->{value}) {
            $attr->{value} = $list[1];
        }
        SWITCH: foreach ($tag) {
            /^method$/ and do {
                $entry{method} = trim($attr->{value}) || "GET";
                last;
            };
            /^url$/ and do {
                $entry{url} = trim($attr->{value}) || die "URL required";
                last;
            };
            /^description$/ and do {
                $entry{description} = trim($attr->{value});
                last;
            };
            /^useragent$/ and do {
                $entry{useragent} = trim($attr->{value});
                last;
            };
            /^http-header$/ and do {
                $entry{http_header}->{$attr->{name} || ""} = trim($attr->{value});
                last;
            };
            /^data$/ and do {
                $entry{data} = get_data(\@list);
                last;
            };
            /^assert$/ and do {
                $entry{assert_xml} = \@list;
                last;
            };
            /^recurse$/ and do {
                $entry{recurse_xml} = \@list;
                last;
            };
            /^property$/ and do {
                foreach (qw/value regex xpath header status random/) {
                    if ($attr->{$_}) {
                        push @{$entry{property}}, [$_, $attr->{name}, $attr->{$_}];
                        last;
                    }
                }
                last;
            };
            assert(0, "found <$tag>, expected <method>, <url>, <description>, <useragent>, <data>, <assert>, <recurse>, <property>");
        }
    }
    return \%entry;
}

sub get_data {
    my ($list) = @_;
    my %entry = ();

    for (my $i = 0; $i < @$list; $i += 2) {
        my $tag = $list->[$i];
        my $content = $list->[$i+1];

        next if !$tag; # skip white space
        assert($tag eq 'parm', "<parm> expected");
        my $attr = $content->[0];
        my $lhs = $attr->{name};
        my $rhs = (defined $attr->{value}) ?  $attr->{value} : ($content->[1] ? "" : trim($content->[2]));
        $entry{$lhs} = $rhs;
    }
    return \%entry;
}

sub trim {
    my ($str) = @_;
    return "" if !defined $str;
    $str =~ s/^\s+//s;
    $str =~ s/\s+$//s;
    return $str;
}


# static
# shuffle an array randomly inplace
sub fisher_yates_shuffle {
    my ($array) = @_;                     # $array is a reference to an array
    my $last = @$array;
    while ($last--) {
        my $k = int rand ($last+1);
        @$array[$last, $k] = @$array[$k, $last];
    }
}


# static
sub read_configuration {
    my ($package, $cfg_name, $cmd_param) = @_;
    die "Missing config definition" if !$cfg_name;

    # read config file in 'properties' format
    my $config = WWW::Webrobot::Properties->new(
        listmode    => [qw(names auth_basic output http_header proxy no_proxy mail.Attach)],
        key_value   => [qw(names http_header proxy)],
        multi_value => [qw(auth_basic mail.Attach)],
        structurize => [qw(load mail)],
    );
    my $cfg = $config->load($cfg_name, $cmd_param);

    # adjust property 'output' to internal data structure
    $cfg->{output} = [ $cfg->{output} ] if ref($cfg->{output}) ne "ARRAY";
    my $output = $cfg->{output};
    foreach (@$output) {
        my ($class, $rest) = split /\s+/, $_, 2;
        eval "require $class;";
        die "Can't find class='$class', $@" if $@;
        $rest ||= "";
        my @parm = eval("( $rest )");
        die "Invalid parameter list: $@" if $@;
        $_ = $class -> new(@parm);
    }

    # adjust property 'auth_basic' to internal data structure
    my %intern_realm = ();
    foreach (@{$cfg->{auth_basic}}) {
        my ($id, $login, $passwd) = @$_;
        $intern_realm{$id} = [$login, $passwd];
    }
    $cfg->{auth_basic} = \%intern_realm;

    # adjust 'http_header'
    $cfg->{http_header} = array2hash($cfg->{http_header});

    # adjust 'proxy'
    $cfg->{proxy} = array2hash($cfg->{proxy});

    # adjust 'names'
    #$cfg->{names} = array2hash($cfg->{names});

    # normalize 'load'
    $cfg->{load}->{number_of_clients} ||= 1 if defined $cfg->{load};

    return $cfg;
}


sub array2hash {
    my ($http_header) = @_;
    my %hash = ();
    foreach (@$http_header) {
        my ($key, $value) = @$_;
        $hash{$key} = $value;
    }
    return \%hash;
}

=back

=head1 SEE ALSO

L<WWW::Webrobot::pod::Config>

L<WWW::Webrobot::pod::Testplan>

=cut

1;
