package Waft;

use 5.005;
use strict;
use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use CGI qw( -no_debug );
use Fcntl qw( :DEFAULT );
use Symbol;
require File::Spec;

$VERSION = '0.9910';

$Waft::Backword_compatible_version = $VERSION;
@Waft::Allow_template_file_exts = qw( .html .css .js .txt );
$Waft::Cache = 1;
$Waft::Correct_NEXT_DISTINCT = 1;

sub import {
    my ($base, @mixins) = @_;

    if ( defined $mixins[0] and $mixins[0] eq 'with' ) {
        shift @mixins;
    }

    return if @mixins == 0;

    my $caller = caller;
    my @bases = (@mixins, $base);

    BASE:
    for my $base ( @bases ) {
        if ( $base =~ /\A :: /xms ) {
            $base = 'Waft' . $base;
        }

        next BASE if $caller->isa($base);

        eval qq{ require $base };

        if ( $@ ) {
            CORE::die($@) if $@ !~ /\ACan't locate .*? at \(eval /;

            if ( not do { no strict 'refs'; %{ "${base}::" } } ) {
                require Carp;

                Carp::croak($@);
            }
        }

        no strict 'refs';
        push @{ "${caller}::ISA" }, $base;
    }

    return;
}

{
    my %Backword_compatible_version_of;

    sub set_waft_backword_compatible_version {
        my ($class, $backword_compatible_version) = @_;

        $class->die('This is class method') if $class->blessed;

        $Backword_compatible_version_of{$class}
            = $backword_compatible_version;

        return;
    }

    sub BCV {
        my ($self) = @_;

        my $class = $self->blessed || $self;

        my $backword_compatible_version
            = $Backword_compatible_version_of{$class}
              || $Waft::Backword_compatible_version;

        return $backword_compatible_version;
    }
}

sub get_waft_backword_compatible_version { shift->BCV(@_) }

eval q{ use Scalar::Util qw( blessed refaddr ); 1 } or do {
    *blessed = *blessed = sub {
        my ($self) = @_;

        my $blessed = ref $self;

        return $blessed;
    };

    *refaddr = *refaddr = sub {
        my ($self) = @_;

        my $blessed_class = ref $self
            or return;

        bless $self, __PACKAGE__;
        my $refaddr = "$self";

        bless $self, $blessed_class;

        return $refaddr;
    };
};

sub die {
    my ($self, @args) = @_;

    $self->dont_trust_me( sub { CORE::die(@_) }, @args );

    return;
}

sub dont_trust_me {
    my ($self, $coderef, @args) = @_;

    my $class = $self->blessed || $self;

    my $back;
    CALLER:
    while ( my @caller = caller $back++ ) {
        my ($package, $filename, $line) = @caller;

        next CALLER if $package ne $class and $self->isa($package);

        if ( not grep { defined and length >= 1 } @args ) {
            push @args, q{something's wrong};
        }

        push @args, " at $filename line $line.\n";

        last CALLER;
    }

    return $coderef->(@args);
}

sub use_utf8 {
    my ($class) = @_;

    $class->set_using_utf8(1);

    return;
}

{
    my %Using_utf8;

    sub set_using_utf8 {
        my ($class, $using_utf8) = @_;

        $class->die('This is class method') if $class->blessed;

        return if $using_utf8 and not $class->can_use_utf8;

        $Using_utf8{$class} = $using_utf8;

        return;
    }

    sub get_using_utf8 {
        my ($self) = @_;

        if ($self->BCV < 0.53) {
            return $self->stash->{use_utf8} if $self->blessed;
        }

        my $class = $self->blessed || $self;

        my $using_utf8 = $Using_utf8{$class};

        return $using_utf8;
    }
}

sub can_use_utf8 {
    my ($self) = @_;

    eval { require 5.008001 };
    return 1 if not $@;
    $self->warn($@);

    return;
}

sub warn {
    my ($self, @args) = @_;

    $self->dont_trust_me( sub { CORE::warn(@_) }, @args );

    return;
}

{
    my %Allow_template_file_exts_arrayref_of;

    sub set_allow_template_file_exts {
        my ($class, @allow_template_file_exts) = @_;

        $class->die('This is class method') if $class->blessed;

        $Allow_template_file_exts_arrayref_of{$class}
            = \@allow_template_file_exts;

        return;
    }

    sub get_allow_template_file_exts {
        my $class = $_[1] || $_[0];

        return @{ $Allow_template_file_exts_arrayref_of{$class} }
            if exists $Allow_template_file_exts_arrayref_of{$class};

        my $get_allowed_exts = do {
            no strict 'refs';
            *{ "${class}::allow_template_file_exts" }{CODE};
        };

        my @allow_template_file_exts
            =   $get_allowed_exts ? $get_allowed_exts->($class)
              :                     @Waft::Allow_template_file_exts;

        $Allow_template_file_exts_arrayref_of{$class}
            = \@allow_template_file_exts;

        return @allow_template_file_exts;
    }
}

{
    my %Default_content_type_of;

    sub set_default_content_type {
        my ($class, $default_content_type) = @_;

        $class->die('This is class method') if $class->blessed;

        $Default_content_type_of{$class} = $default_content_type;

        return;
    }

    sub get_default_content_type {
        my ($self) = @_;

        my $class = $self->blessed || $self;

        my $default_content_type = $Default_content_type_of{$class}
                                   || 'text/html';

        return $default_content_type;
    }
}

sub waft {
    my ($self, @args) = @_;

    if ($self->BCV < 0.53) {
        if ( not $self->blessed ) {
            ($self, @args) = $self->new(@args);
        }

        $self->init_base_url;
        $self->init_binmode;
        $self->_load_query_param;
    }

    if ( not $self->blessed ) {
        $self = $self->new->initialize;
    }

    my @return_values = $self->controller(@args);

    return wantarray ? ($self, @return_values) : $self;
}

sub new {
    my ($class) = @_;

    $class->die('This is class method') if $class->blessed;

    my $self;
    tie %$self, 'Waft::Object';
    bless $self, $class;

    if ($class->BCV < 1.0) {
        $class->define_subs_for_under_0_99x;
    }

    if ($class->BCV < 0.53) {
        ( undef, my @args ) = @_;

        $class->define_subs_for_under_0_52x;

        my $self;
        tie %$self, 'Waft::Object';
        bless $self, $class;

        my ($option_hashref, @return_values);

        if (ref $args[0] eq 'HASH') {
            ($option_hashref, @return_values) = @args;
        }
        else {
            $option_hashref = { @args };
        }

        $option_hashref->{content_type} ||= $self->get_default_content_type;
        $option_hashref->{headers} ||= [];

        my $stash = $self->stash;

        %$stash = %$option_hashref;

        if ($stash->{use_utf8}) {
            $self->can_use_utf8; # carp in this method if cannot 'use utf8'
        }

        return wantarray ? ($self, @return_values) : $self;
    }

    return $self;
}

sub initialize {
    my ($self) = @_;

    $self->initialize_base_url;
    $self->initialize_page;
    $self->initialize_values;
    $self->initialize_action;
    $self->initialize_response_headers;
    $self->initialize_binmode;

    return $self;
}

sub initialize_base_url {
    my ($self) = @_;

    my $base_url = $self->make_base_url;
    $self->set_base_url($base_url);

    return;
}

sub make_base_url {
    my ($self) = @_;

    my $updir = $ENV{PATH_INFO} || q{};
    my $updir_count = $updir =~ s{ /[^/]* }{../}gx;

    my $url;

    if ( defined $ENV{REQUEST_URI}
         and $ENV{REQUEST_URI} =~ /\A ([^?]+) /xms
    ) {
        $url = $1;

        for (1 .. $updir_count) {
            $url =~ s{ /[^/]* \z}{}x;
        }
    }
    else {
        $url = $ENV{SCRIPT_NAME} || $self->get_script_basename;
    }

    my $base_url =   $url =~ m{ ([^/]+) \z}xms ? "$updir$1"
                   :                             './';

    return $base_url;
}

sub get_script_basename {
    my ($self) = @_;

    return $FindBin::Script if eval { FindBin::again(); 1 };

    delete $INC{'FindBin.pm'};
    require FindBin;

    return $FindBin::Script;
}

sub set_base_url {
    my ($self, $base_url) = @_;

    if ($self->BCV < 0.53) {
        $self->stash->{url} = $base_url;
    }

    $self->stash->{base_url} = $base_url;

    return;
}

{
    my %Stash;

    sub stash { $Stash{ $_[0]->refaddr or $_[0] }{ $_[1] or caller } ||= {} }

    sub DESTROY {
        my ($self) = @_;

        my $ident = $self->refaddr;
        delete $Stash{$ident};

        return;
    }
}

sub initialize_page {
    my ($self) = @_;

    my $page =   $self->is_submitted ? $self->cgi->param('s')
               :                       $self->cgi->param('p');

    if ( $self->get_using_utf8 and defined $page ) {
        utf8::encode($page);
    }

    $page = $self->fix_and_validate_page($page);
    $self->set_page( defined $page ? $page : 'default.html' );

    return;
}

sub is_submitted {
    my ($self) = @_;

    my $is_submitted = defined $self->cgi->param('s');

    return $is_submitted;
}

sub cgi {
    my ($self) = @_;

    my $query = ( $self->stash->{query} ||= $self->create_query_obj );

    return $query;
}

sub create_query_obj {
    my ($self) = @_;

    my $query = CGI->new;

    if ($self->get_using_utf8) {
        eval qq{\n# line } . __LINE__ . q{ "} . __FILE__ . qq{"\n} . q{
            use CGI 3.21 qw( -utf8 ); # -utf8 pragma is for 3.31 or later
        };

        if ($@) {
            $self->warn($@);
        }
        elsif ($query->VERSION < 3.31) {
            $query->charset('utf-8');
        }
    }

    return $query;
}

sub fix_and_validate_page {
    my ($self, $page) = @_;

    return if not defined $page;

    $page =~ m{\A
        (?! .* [/\\]{2,} )
        (?! .* (?<! [^/\\] ) \.\.? (?! [^/\\] ) )
        (?! .* :: )
        (.+) \z}xms;
    my $untainted_page = $1;

    return $untainted_page
        if defined $untainted_page
           and not File::Spec->file_name_is_absolute($untainted_page)
           and not $untainted_page eq 'CURRENT'
           and not $untainted_page eq 'TEMPLATE'
           and not $self->to_page_id($untainted_page) =~ / __indirect \z/xms;

    $self->warn(qq{Invalid requested page "$page"});

    return;
}

sub to_page_id {
    my (undef, $page) = @_;

    my $page_id = $page;
    $page_id =~ s{ \.[^/:\\]* \z}{}xms;
    $page_id =~ tr/0-9A-Za-z_/_/c;

    return $page_id;
}

sub set_page {
    my ($self, $page) = @_;

    $self->stash->{page} = $page;

    return;
}

sub initialize_values {
    my ($self, $joined_values) = @_;

    $self->clear_values;

    $joined_values ||= $self->cgi->param('v');

    return if not defined $joined_values;

    my @key_values_pairs = split /\x20/, $joined_values, -1;

    KEY_VALUES_PAIR:
    for my $key_values_pair (@key_values_pairs) {
        my ($key, @values) = split /-/, $key_values_pair, -1;

        $key = $self->unescape_space_percent_hyphen($key);
        @values = $self->unescape_space_percent_hyphen(@values);

        if ($key eq 'ALL_VALUES') {
            $self->warn(q{Invalid init value 'ALL_VALUES'});

            next KEY_VALUES_PAIR;
        }

        $self->set_values( $key => @values );
    }

    return;
}

sub clear_values {
    my ($self) = @_;

    %{ $self->value_hashref } = ();

    return;
}

sub value_hashref { tied %{ $_[0] } }

sub unescape_space_percent_hyphen {
    my (undef, @values) = @_;

    for my $value (@values) {
        $value =~ s/ %(2[05d]) / pack 'H2', $1 /egxms;
    }

    return wantarray ? @values : $values[0];
}

sub set_values {
    my ($self, $key, @values) = @_;

    @{ $self->value_hashref->{$key} } = @values;

    return;
}

sub initialize_action {
    my ($self) = @_;

    my $action = $self->find_first_action;
    $self->set_action( defined $action ? $action : 'direct' );

    return;
}

sub find_first_action {
    my ($self) = @_;

    return if not $self->is_submitted;

    my $page_id = $self->to_page_id($self->get_page);
    my $global_action;

    my @param_names = $self->cgi->param;
    PARAM_NAME:
    for my $param_name ( @param_names ) {
        my $action_id = $self->to_action_id($param_name);

        if ($self->BCV < 0.53) {
            next PARAM_NAME if $action_id =~ /\A global_ /xms;
        }

        next PARAM_NAME if    $action_id =~ /(?: \A | _ ) direct   \z/xms
                           or $action_id =~ /(?: \A | _ ) indirect \z/xms
                           or $action_id =~ /\A global__ /xms;

        return $param_name if $self->can("__${page_id}__$action_id");

        next PARAM_NAME if defined $global_action;

        if ($self->BCV < 0.53) {
            if ( $self->can("global_$action_id") ) {
                $global_action = "global_$param_name";
            }

            next PARAM_NAME;
        }

        if ( $self->can("global__$action_id") ) {
            $global_action = "global__$param_name";
        }

        next PARAM_NAME;
    }

    return $global_action if defined $global_action;

    return 'submit' if $self->can("__${page_id}__submit");

    if ($self->BCV < 0.53) {
        return 'global_submit' if $self->can('global_submit');
    }

    return 'global__submit' if $self->can('global__submit');

    $self->warn('Requested parameters do not match with defined action');

    return;
}

sub get_page { $_[0]->stash->{page} }

sub page { shift->get_page(@_) }

sub to_action_id {
    my (undef, $action) = @_;

    my $action_id = $action;
    $action_id =~ s/ \. .* \z//xms;

    return $action_id;
}

sub set_action {
    my ($self, $action) = @_;

    $self->stash->{action} = $action;

    return;
}

sub initialize_response_headers {
    my ($self) = @_;

    $self->set_response_headers( () );

    return;
}

sub initialize_binmode {
    my ($self) = @_;

    if ( $self->get_using_utf8 ) {
        eval q{ binmode select, ':utf8' };
    }
    else {
        no strict 'refs';
        binmode select;
    }

    return;
}

sub set_response_headers {
    my ($self, @response_headers) = @_;

    if ($self->BCV < 0.53) {
        $self->stash->{headers} = \@response_headers;

        return;
    }

    $self->stash->{response_headers} = \@response_headers;

    return;
}

sub controller {
    my ($self, @relays) = @_;

    local $NEXT::SEEN if $NEXT::SEEN and $Waft::Correct_NEXT_DISTINCT;

    if ( my $coderef = $self->can('begin') ) {
        @relays = $self->call_method($coderef, @relays);
    }

    my $stash = $self->stash;
    my $call_count;
    METHOD:
    while ( not $stash->{responded} ) {
        if ( my $coderef = $self->can('before') ) {
            @relays = $self->call_method($coderef, @relays);

            last METHOD if $stash->{responded};
        }

        if ( my $coderef = $self->find_action_method ) {
            @relays = $self->call_method($coderef, @relays);

            last METHOD if $stash->{responded};

            if ($self->BCV < 0.53) {
                if ( $self->to_action_id($self->get_action) eq 'template' ) {
                    @relays = $self->call_template('CURRENT', @relays);

                    last METHOD if $stash->{responded};
                }
            }

            next METHOD;
        }
        else {
            $self->set_action('template');
        }

        @relays = $self->call_template('CURRENT', @relays);

        last METHOD if $stash->{responded};
    }
    continue {
        $self->die('Methods called too many times in controller')
            if ++$call_count > 4;
    }

    if ( $self->can('end') ) {
        my @return_values = $self->end(@relays);

        if ( @return_values ) {
            @relays = @return_values;
        }
    }

    return wantarray ? @relays : $relays[0];
}

sub call_method {
    my ($self, $method_coderef, @args) = @_;

    my @return_values = $self->$method_coderef(@args);

    return wantarray ? @return_values : $return_values[0]
        if $self->stash->{responded};

    require B;
    my $method_name = B::svref_2object($method_coderef)->GV->NAME;

    if ( $method_name eq 'begin' || $method_name eq 'before'
         and @return_values == 0
    ) {
        my $next = { page => 'CURRENT', action => undef };
        @return_values = ($next, @args);
    }

    my $next = shift @return_values;
    my ($next_page, $next_action)
        =   ref $next eq 'ARRAY' ? @$next
          : ref $next eq 'HASH'  ? ($next->{page}, $next->{action})
          :                        ($next, undef);

    if ( not defined $next_page ) {
        $next_page =   $method_name eq 'begin'  ? 'CURRENT'
                     : $method_name eq 'before' ? 'CURRENT'
                     :                            'TEMPLATE';
    }

    if ( not defined $next_action ) {
        $next_action =   $next_page eq 'TEMPLATE' ? 'template'
                       :                            'indirect';
    }

    if ($next_page eq 'CURRENT' or $next_page eq 'TEMPLATE') {
        # don't change page
    }
    else {
        $self->set_page($next_page);
    }

    if ( $next_page eq 'CURRENT'
         and $method_name eq 'begin' || $method_name eq 'before'
    ) {
        # don't change action
    }
    else {
        $self->set_action($next_action);
    }

    return @return_values;
}

sub find_action_method {
    my ($self) = @_;

    my $page_id = $self->to_page_id($self->get_page);
    my $action_id = $self->to_action_id($self->get_action);

    if ($self->BCV < 0.53) {
        if ($action_id eq 'direct') {
            return    $self->can("__${page_id}__direct")
                   || $self->can("__${page_id}")
                   || $self->can('global_direct');
        }
        elsif ($action_id eq 'indirect') {
            return    $self->can("__${page_id}__indirect")
                   || $self->can("__${page_id}")
                   || $self->can('global_indirect');
        }
        elsif ( $action_id =~ /\A global_ /xms ) {
            return $self->can($action_id);
        }
    }

    if ($action_id eq 'direct') {
        return    $self->can("__${page_id}__direct")
               || $self->can("__${page_id}")
               || $self->can('global__direct');
    }
    elsif ($action_id eq 'indirect') {
        return    $self->can("__${page_id}__indirect")
               || $self->can("__${page_id}")
               || $self->can('global__indirect');
    }
    elsif ( $action_id =~ /\A global__ /xms ) {
        return $self->can($action_id);
    }

    return $self->can("__${page_id}__$action_id");
}

sub get_action { $_[0]->stash->{action} }

sub action { shift->get_action(@_) }

sub call_template {
    my ($self, $page, @args) = @_;

    if ($self->BCV < 0.53) {
        $page =~ s/ .+ :: //xms;
    }

    if ($page eq 'CURRENT' or $page eq 'TEMPLATE') {
        $page = $self->get_page;
    }

    my ($template_file, $template_class) = $self->get_template_file($page);

    if ( not defined $template_file ) {
        $self->warn(qq{Requested page "$page" is not found});

        my $goto_not_found_coderef = sub { shift; 'not_found.html', @_ };

        return $self->call_method($goto_not_found_coderef, @args);
    }

    my $template_coderef
        = $self->compile_template_file($template_file, $template_class);

    return $self->call_method($template_coderef, @args);
}

sub include { shift->call_template(@_) }

sub get_template_file {
    my ($self, $page) = @_;

    if ($page eq 'CURRENT' or $page eq 'TEMPLATE') {
        $page = $self->get_page;
    }

    if ( File::Spec->file_name_is_absolute($page) ) {
        return if not -f $page;

        my $template_file = $page;
        my $template_class = $self->blessed || $self;

        return $template_file, $template_class;
    }

    return $self->find_template_file($page);
}

{
    my %Cached_template_file;

    sub find_template_file {
        my ($self, $page) = @_;

        my $class = $self->blessed || $self;

        return @{ $Cached_template_file{$class, $page} }
            if $Waft::Cache and exists $Cached_template_file{$class, $page};

        my ($template_file, $template_class)
            = $self->recursive_find_template_file($page, $class);

        return if not defined $template_file;

        $Cached_template_file{$class, $page}
            = [$template_file, $template_class];

        return $template_file, $template_class;
    }
}

sub recursive_find_template_file {
    my ($self, $page, $class, $seen) = @_;

    return if $seen->{$class}++;

    my $class_path = $class;
    $class_path =~ s{ :: }{/}gxms;

    my $module_file = "$class_path.pm";
    my @lib_dirs
         =   ! defined $INC{$module_file}                             ? @INC
           : $INC{$module_file} =~ m{\A (.+) /\Q$module_file\E \z}xms ? ($1)
           :                                                            @INC;

    my @finding_files;
    push @finding_files, "$class_path.template/$page";
    if ( $self->is_allowed_to_use_template_file_ext($page, $class) ) {
        push @finding_files, "$class_path/$page";
    }

    for my $lib_dir ( @lib_dirs ) {
        for my $finding_file ( @finding_files ) {
            my $template_file = "$lib_dir/$finding_file";

            return $template_file, $class if -f $template_file;
        }
    }

    my @super_classes = do { no strict 'refs'; @{ "${class}::ISA" } };
    for my $super_class ( @super_classes ) {
        my ($template_file, $template_class)
            = $self->recursive_find_template_file($page, $super_class, $seen);

        return $template_file, $template_class if defined $template_file;
    }

    return;
}

sub is_allowed_to_use_template_file_ext {
    my ($self, $page, $class) = @_;

    return if $self->BCV < 0.53;

    my @allow_template_file_exts
        = $self->get_allow_template_file_exts($class);

    EXT:
    for my $allow_template_file_ext ( @allow_template_file_exts ) {
        if (length $allow_template_file_ext == 0) {
            return 1 if $page !~ / \. /xms;

            next EXT;
        }

        return 1 if $page =~ / \Q$allow_template_file_ext\E \z/xms;
    }

    return;
}

{
    my %Cached_template_coderef;

    sub compile_template_file {
        my ($self, $template_file, $template_class) = @_;

        my @stat = stat $template_file;
        if ( not @stat ) {
            $self->warn(qq{Failed to stat template file "$template_file"});

            my $goto_internal_server_error_coderef
                = sub { shift; 'internal_server_error.html', @_ };

            return $goto_internal_server_error_coderef;
        }
        my $modified_time = $stat[9];

        my $template_name = "${template_class}::$template_file";
        my $template_id = "$template_name-$modified_time";

        return $Cached_template_coderef{$template_id}
            if $Waft::Cache and exists $Cached_template_coderef{$template_id};

        my $old_template_id_regexp = qr/\A \Q$template_name\E - \d{14} \z/xms;
        CACHED_TEMPLATE:
        for my $cached_template_id ( keys %Cached_template_coderef ) {
            next CACHED_TEMPLATE
                if $cached_template_id !~ $old_template_id_regexp;
            delete $Cached_template_coderef{$cached_template_id};
        }

        my $template_scalarref = $self->read_template_file($template_file);
        if ( not $template_scalarref ) {
            $self->warn(qq{Failed to read template file "$template_file"});

            my $goto_forbidden_coderef = sub { shift; 'forbidden.html', @_ };

            return $goto_forbidden_coderef;
        }

        my $template_coderef = $self->compile_template(
            $template_scalarref, $template_file, $template_class
        );

        $Cached_template_coderef{$template_id} = $template_coderef;

        return $template_coderef;
    }
}

sub read_template_file {
    my ($self, $template_file) = @_;

    sysopen my $file_handle = gensym, $template_file, O_RDONLY
        or return;

    binmode $file_handle;

    my ($untainted_template) = do { local $/; <$file_handle> =~ / (.*) /xms };

    close $file_handle;

    return \$untainted_template;
}

sub compile_template {
    my ($self, $template, $template_file, $template_class) = @_;

    if (ref $template eq 'SCALAR') {
        $template = $$template;
    }

    $template =~ s{ (?<= <form \b ) (.+?) (?= </form> ) }
                  { $self->insert_output_waft_tags_method($1) }egixms;

    $template =~ / ( \x0D\x0A | [\x0A\x0D] ) /xms;
    my $break = $1 || "\n";

    $template = "%>$template<%";

    $template =~ s{ (?<= %> ) (?! <% ) (.+?) (?= <% ) }
                  { $self->convert_text_part($1, $break) }egxms;

    $template
        =~ s{<% (?! \s*[\x0A\x0D]
                    =[A-Za-z]
                )
                \s* j(?:sstr)? \s* = (.*?)
             %>}{\$__self->output( \$__self->jsstr_filter($1) );}gxms;

    $template
        =~ s{<% (?! \s*[\x0A\x0D]
                    =[A-Za-z]
                )
                \s* p(?:lain)? \s* = (.*?)
             %>}{\$__self->output($1);}gxms;

    $template
        =~ s{<% (?! \s*[\x0A\x0D]
                    =[A-Za-z]
                )
                \s* t(?:ext)? \s* = (.*?)
             %>}{\$__self->output( \$__self->text_filter($1) );}gxms;

    $template
        =~ s{<% (?! \s*[\x0A\x0D]
                    =[A-Za-z]
                )
                \s* (?: w(?:ord)? \s* )? = (.*?)
             %>}{\$__self->output( \$__self->word_filter($1) );}gxms;

    $template =~ s/ %> | <% //gxms;

    $template = 'return sub {'
                . ( $self->BCV < 1.0 ? 'local $Waft::Self = $_[0];' : q{} )
                .     'my $__self = $_[0];'
                .     $template
                . '}';

    if ( defined $template_class ) {
        $template = "package $template_class;" . $template;
    }

    if ( defined $template_file ) {
        $template = qq{# line 1 "$template_file"$break} . $template;
    }

    my $coderef = $self->compile(\$template);

    $self->die($@) if $@;

    return $coderef;
}

sub insert_output_waft_tags_method {
    my ($self, $form_block) = @_;

    return $form_block if $form_block =~ m{ \b (?:
          output_waft_tags
        | (?: (?i) waft(?: \s+ | _ ) tag s? )
        | form_elements                       # deprecated
    ) \b }xms;

    $form_block =~ s{ (?= < (?: input | select | textarea | label ) \b ) }
                    {<% \$__self->output_waft_tags('ALL_VALUES'); %>}ixms;

    return $form_block;
}

sub output_waft_tags {
    my ($self, @keys_arrayref_or_key_value_pairs) = @_;

    $self->output( $self->get_waft_tags(@keys_arrayref_or_key_value_pairs) );

    return;
}

sub get_waft_tags {
    my ($self, @keys_arrayref_or_key_value_pairs) = @_;

    my $joined_values = $self->join_values(@keys_arrayref_or_key_value_pairs);
    my $waft_tags = q{<input name="s" type="hidden" value="}
                    . $self->html_escape($self->get_page)
                    . q{" /><input name="v" type="hidden" value="}
                    . $self->html_escape($joined_values)
                    . q{" />};

    return $waft_tags;
}

sub join_values {
    my ($self, @keys_arrayref_or_key_value_pairs) = @_;

    my %joined_values;

    my $value_hashref = $self->value_hashref;
    KEYS_ARRAYREF_OR_KEY:
    while ( @keys_arrayref_or_key_value_pairs ) {
        my $keys_arrayref_or_key = shift @keys_arrayref_or_key_value_pairs;

        if ( defined $keys_arrayref_or_key
             and $keys_arrayref_or_key eq 'ALL_VALUES'
        ) {
            $keys_arrayref_or_key = [ keys %$value_hashref ];
        }

        if (ref $keys_arrayref_or_key eq 'ARRAY') {
            KEY:
            for my $key ( @$keys_arrayref_or_key ) {
                if ( not defined $key ) {
                    $self->warn('Use of uninitialized value');
                    $key = q{};
                }

                next KEY if not exists $value_hashref->{$key};

                my @values = $self->get_values($key);

                VALUE:
                for my $value ( @values ) {
                    next VALUE if defined $value;
                    $self->warn('Use of uninitialized value');
                    $value = q{};
                }

                @values = $self->escape_space_percent_hyphen(@values);

                $joined_values{$key} = join q{}, map { "-$_" } @values;
            }

            next KEYS_ARRAYREF_OR_KEY;
        }

        my $key;

        if ( defined $keys_arrayref_or_key ) {
            $key = $keys_arrayref_or_key;
        }
        else {
            $self->warn('Use of uninitialized value');
            $key = q{};
        }

        my @values;

        if ( @keys_arrayref_or_key_value_pairs ) {
            my $value_or_values_arrayref
                = shift @keys_arrayref_or_key_value_pairs;

            if ( not defined $value_or_values_arrayref ) {
                $self->warn('Use of uninitialized value');
                @values = (q{});
            }
            elsif (ref $value_or_values_arrayref eq 'ARRAY') {
                @values = @$value_or_values_arrayref;

                VALUE:
                for my $value ( @values ) {
                    next VALUE if defined $value;
                    $self->warn('Use of uninitialized value');
                    $value = q{};
                }
            }
            else {
                @values = ($value_or_values_arrayref);
            }
        }
        else {
            $self->warn('Odd number of elements in arguments');
            @values = (q{});
        }

        @values = $self->escape_space_percent_hyphen(@values);

        $joined_values{$key} = join q{}, map { "-$_" } @values;

        next KEYS_ARRAYREF_OR_KEY;
    }

    my $joined_values
        = join q{ }, map { $self->escape_space_percent_hyphen($_)
                           . $joined_values{$_}
                         } sort keys %joined_values;

    return $joined_values;
}

{
    my @EMPTY;

    sub get_values {
        my ($self, $key, @i) = @_;

        return @{ $self->value_hashref->{$key} || \@EMPTY }[@i] if @i;

        return @{ $self->value_hashref->{$key} || \@EMPTY };
    }
}

sub escape_space_percent_hyphen {
    my (undef, @values) = @_;

    for my $value (@values) {
        $value =~ s/ ( [ %-] ) / '%' . unpack('H2', $1) /egxms;
    }

    return wantarray ? @values : $values[0];
}

sub convert_text_part {
    my (undef, $text_part, $break) = @_;

    if ($text_part =~ / ([^\x0A\x0D]*) ( [\x0A\x0D] .* ) /xms) {
        my ($first_line, $after_first_break) = ($1, $2);

        if (length $first_line > 0) {
            $first_line =~ s/ ( ['\\] ) /\\$1/gxms;
            $first_line = q{$__self->output('} . $first_line . q{');};
        }

        $after_first_break =~ s/ ( ["\$\@\\] ) /\\$1/gxms;

        my $breaks = $break x (
              $after_first_break =~ s/ \x0D\x0A /\\x0D\\x0A/gxms
            + $after_first_break =~ s/ \x0A /\\x0A/gxms
            + $after_first_break =~ s/ \x0D /\\x0D/gxms
            - 1
        );

        return $first_line . $break
               . qq{\$__self->output("$after_first_break");$breaks};
    }

    $text_part =~ s/ ( ['\\] ) /\\$1/gxms;

    return q{$__self->output('} . $text_part . q{');};
}

{
    package Waft::compile;

    sub Waft::compile { eval ${ $_[1] } }
}

{
    my $OUTPUT_CONTENT_CODEREF;

    sub output {
        ( $_[0]->stash->{output} ||= do {
            my ($self) = @_;

            $self->output_response_headers;
            $self->stash->{responded} = 1;

            $OUTPUT_CONTENT_CODEREF;
        } )->(@_);
    }

    $OUTPUT_CONTENT_CODEREF = sub { shift; print @_ if @_; return };
}

sub output_response_headers {
    my ($self) = @_;

    for my $response_header ( $self->get_response_headers ) {
        print "$response_header\x0D\x0A";
    }

    if ($self->BCV < 0.53) {
        if ( not grep { /\A Content-Type: /ixms
                      } $self->get_response_headers
        ) {
            my $content_type = $self->stash->{content_type};
            print "Content-Type: $content_type\x0D\x0A";
        }

        print "\x0D\x0A";

        return;
    }

    if ( not grep { /\A Content-Type: /ixms } $self->get_response_headers ) {
        print 'Content-Type: ' . $self->get_default_content_type . "\x0D\x0A";
    }

    print "\x0D\x0A";

    return;
}

sub get_response_headers {
    my ($self) = @_;

    return @{ $self->stash->{headers} } if $self->BCV < 0.53;

    return @{ $self->stash->{response_headers} }
}

{
    my $BUFFER_CONTENT_CODEREF;

    sub get_content {
        my ($self, $coderef, @args) = @_;

        my $stash = $self->stash;

        push @{ $stash->{contents} }, q{};

        local $stash->{output} = $BUFFER_CONTENT_CODEREF
            if @{ $stash->{contents} } == 1;
        my @return_values = $self->$coderef(@args);

        return pop @{ $stash->{contents} }, @return_values if wantarray;
        return pop @{ $stash->{contents} };
    }

    $BUFFER_CONTENT_CODEREF
        = sub { shift->stash->{contents}->[-1] .= join q{}, @_; return };
}

sub jsstr_filter { shift->jsstr_escape(@_) }

sub jsstr_escape {
    my ($self, @values) = @_;

    VALUE:
    for my $value (@values) {
        if ( not defined $value ) {
            $self->warn('Use of uninitialized value');

            next VALUE;
        }

        $value =~ s{ (["'/\\]) }{\\$1}gxms;
        $value =~ s/ \x0A /\\n/gxms;
        $value =~ s/ \x0D /\\r/gxms;
        $value =~ s/ < /\\x3C/gxms;
        $value =~ s/ > /\\x3E/gxms;
    }

    return wantarray ? @values : $values[0];
}

sub text_filter {
    my ($self, @values) = @_;

    VALUE:
    for my $value ( @values ) {
        if ( not defined $value ) {
            $self->warn('Use of uninitialized value');

            next VALUE;
        }

        $value = $self->expand_tabs($value);
        $value = $self->html_escape($value);
        $value =~ s{ ( \x0D\x0A | [\x0A\x0D] ) }{<br />$1}gxms;
        $value =~ s{\A \x20 }{&nbsp;}gxms;
        $value =~ s{ (\s) \x20 }{$1&nbsp;}gxms;
    }

    return wantarray ? @values : $values[0];
}

sub expand_tabs {
    my ($self, @values) = @_;

    VALUE:
    for my $value (@values) {
        if ( not defined $value ) {
            $self->warn('Use of uninitialized value');

            next VALUE;
        }

        $value =~ s{( [^\x0A\x0D]+ )}{
            my $line = $1;

            while ( $line =~ / \t /gxms ) {
                my $offset = pos($line) - 1;
                substr( $line, $offset, 1 ) = q{ } x ( 8 - $offset % 8 );
            }

            $line;
        }egxms;
    }

    return wantarray ? @values : $values[0];
}

sub html_escape {
    my ($self, @values) = @_;

    VALUE:
    for my $value (@values) {
        if ( not defined $value ) {
            $self->warn('Use of uninitialized value');

            next VALUE;
        }

        $value =~ s/ & /&amp;/gxms;
        $value =~ s/ " /&quot;/gxms;
        $value =~ s/ ' /&#39;/gxms;
        $value =~ s/ < /&lt;/gxms;
        $value =~ s/ > /&gt;/gxms;
    }

    return wantarray ? @values : $values[0];
}

sub word_filter { shift->html_escape(@_) }

{
    my (%Start, %Progress, $FIND_NEXT_CODEREF);

    sub next {
        my ($self) = @_;

        my ($back, $subroutine);
        1 while ( ( $subroutine = ( caller ++$back )[3] ) eq '(eval)' );
        my ($caller, $method) = $subroutine =~ / (.+) :: (.+) /xms;

        my $ident = $self->refaddr || $self;

        local $Start{ $ident, $method } = $caller
            if not $Start{ $ident, $method }
               or ( caller $back + 1 )[3] ne ( caller 0 )[3];
        local $Progress{ $ident, $method, $Start{ $ident, $method } }
            = $Progress{ $ident, $method, $Start{ $ident, $method } };

        my $next_coderef = $self->$FIND_NEXT_CODEREF(
            $method
            , $Start{ $ident, $method }
            , $Progress{ $ident, $method, $Start{ $ident, $method } }++
        );

        return if not $next_coderef;

        return $next_coderef->(@_);
    }

    my %Cached_next_coderefs;

    $FIND_NEXT_CODEREF = sub {
        my ($self, $method, $start, $progress) = @_;

        my $class = $self->blessed || $self;

        return $Cached_next_coderefs{$class, $method, $start}->[$progress]
            if $Waft::Cache
               and exists $Cached_next_coderefs{$class, $method, $start};

        my @next_classes;

        my @classes = ($class);
        while ( my $class = shift @classes ) {
            push @next_classes, $class;

            no strict 'refs';
            unshift @classes, @{ "${class}::ISA" };
        }

        while ( $start ne shift @next_classes ) {
            return if @next_classes == 0;
        }

        my @next_coderefs = do {
            no strict 'refs';
            grep { $_ } map { *{ "${_}::$method" }{CODE} } @next_classes;
        };

        $Cached_next_coderefs{$class, $method, $start} = \@next_coderefs;

        return $next_coderefs[$progress];
    };
}

sub get_page_id {
    my ($self, $page) = @_;

    if ( not defined $page ) {
        $page = $self->get_page;
    }

    my $page_id = $self->to_page_id($page);

    return $page_id;
}

sub page_id { shift->get_page_id(@_) }

sub set_value {
    my ($self, $key, $value) = @_;

    $self->set_values($key, $value);

    return;
}

sub get_value {
    my ($self, $key, @i) = @_;

    return( ( $self->get_values($key, @i) )[0] );
}

sub add_response_header {
    my ($self, $response_header) = @_;

    if ($_[0]->BCV < 0.53) {
        ( undef, my @response_header_blocks ) = @_;

        my $stash = $self->stash;
        for my $response_header_block ( @response_header_blocks ) {
            my @response_header_lines
                = grep { length > 0
                       } split /[\x0A\x0D]+/, $response_header_block;
            push @{ $stash->{headers} }, @response_header_lines;
        }

        return;
    }

    $response_header =~ s/ [\x0A\x0D]+ //gxms;
    push @{ $self->stash->{response_headers} }, $response_header;

    return;
}

sub header { shift->add_response_header(@_) }

sub add_header { shift->header(@_) }

sub make_url {
    my ($self, $page, @keys_arrayref_or_key_value_pairs) = @_;

    my $query_string
        = $self->make_query_string($page, @keys_arrayref_or_key_value_pairs);

    return $self->get_base_url if length $query_string == 0;

    return $self->get_base_url . '?' . $query_string;
}

sub url { shift->make_url(@_) }

sub make_absolute_url {
    my ($self, @args) = @_;

    my $protocol = $self->cgi->protocol;

    my $base_url = "$protocol://";

    if ( defined $ENV{HTTP_HOST} ) {
        $base_url .= $ENV{HTTP_HOST};
    }
    else {
        $base_url .= $ENV{SERVER_NAME};

        if (    $protocol eq 'http'  and $ENV{SERVER_PORT} != 80
             or $protocol eq 'https' and $ENV{SERVER_PORT} != 443
        ) {
            $base_url .= ":$ENV{SERVER_PORT}";
        }
    }

    if ( defined $ENV{REQUEST_URI}
         and $ENV{REQUEST_URI} =~ /\A ([^?]+) /xms
    ) {
        $base_url .= $1;
    }
    else {
        $base_url .= $ENV{SCRIPT_NAME};
    }

    local $self->stash->{url} = $base_url if $self->BCV < 0.53;
    local $self->stash->{base_url} = $base_url;

    return $self->make_url(@args);
}

sub absolute_url { shift->make_absolute_url(@_) }

sub make_query_string {
    my ($self, $page, @keys_arrayref_or_key_value_pairs) = @_;

    if (ref $page eq 'ARRAY') {
        $page = $page->[0];
    }

    $page =   ! defined $page    ? 'default.html'
            : $page eq 'CURRENT' ? $self->get_page
            :                      $page;

    my @query_string;

    if ($page ne 'default.html') {
        push @query_string,
             join( '=', ( $self->url_encode( 'p' => $page ) ) );
    }

    my $joined_values = $self->join_values(@keys_arrayref_or_key_value_pairs);
    if ( $joined_values ) {
        push @query_string,
             join( '=', ( $self->url_encode('v' => $joined_values) ) );
    }

    my $query_string = join '&', @query_string;

    return $query_string;
}

sub url_encode {
    my ($self, @values) = @_;

    my $using_utf8 = $self->get_using_utf8;

    VALUE:
    for my $value ( @values ) {
        if ( not defined $value ) {
            $self->warn('Use of uninitialized value');

            next VALUE;
        }

        if ( $using_utf8 ) {
            utf8::encode($value);
        }

        $value =~ s/ ( [^ .\w-] ) / '%' . unpack('H2', $1) /egxms;
        $value =~ tr/ /+/;
    }

    return wantarray ? @values : $values[0];
}

sub get_base_url {
    my ($self) = @_;

    return $Waft::Base_url if defined $Waft::Base_url and $self->BCV < 1.0;

    return $self->stash->{url} if $self->BCV < 0.53;

    return $self->stash->{base_url};
}

sub __forbidden__indirect {
    my ($self, @args) = @_;

    $self->add_response_header('Status: 403 Forbidden');
    $self->add_response_header('Content-Type: text/html; charset=ISO8859-1');

    $self->output(qq{<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">\n});
    $self->output(qq{<html><head>\n});
    $self->output(qq{<title>403 Forbidden</title>\n});
    $self->output(qq{</head><body>\n});
    $self->output(qq{<h1>Forbidden</h1>\n});
    $self->output( q{<p>You don't have permission to access this page.});
    $self->output(qq{</p>\n});
    $self->output(qq{</body></html>\n});

    return @args;
}

sub __not_found__indirect {
    my ($self, @args) = @_;

    $self->add_response_header('Status: 404 Not Found');
    $self->add_response_header('Content-Type: text/html; charset=ISO8859-1');

    $self->output(qq{<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">\n});
    $self->output(qq{<html><head>\n});
    $self->output(qq{<title>404 Not Found</title>\n});
    $self->output(qq{</head><body>\n});
    $self->output(qq{<h1>Not Found</h1>\n});
    $self->output(qq{<p>The requested URL was not found.</p>\n});
    $self->output(qq{</body></html>\n});

    return @args;
}

sub __internal_server_error__indirect {
    my ($self, @args) = @_;

    $self->add_response_header('Status: 500 Internal Server Error');
    $self->add_response_header('Content-Type: text/html; charset=ISO8859-1');

    $self->output(qq{<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">\n});
    $self->output(qq{<html><head>\n});
    $self->output(qq{<title>500 Internal Server Error</title>\n});
    $self->output(qq{</head><body>\n});
    $self->output(qq{<h1>Internal Server Error</h1>\n});
    $self->output(qq{<p>The server encountered an internal error or\n});
    $self->output(qq{misconfiguration and was unable to complete\n});
    $self->output(qq{your request.</p>\n});
    $self->output(qq{<p>Please contact the server administrator\n});
    $self->output(qq{ and inform them of the time the error occurred,\n});
    $self->output(qq{and anything you might have done that may have\n});
    $self->output(qq{caused the error.</p>\n});
    $self->output( q{<p>More information about this error may be });
    $self->output(qq{available\n});
    $self->output(qq{in the server error log.</p>\n});
    $self->output(qq{</body></html>\n});

    return @args;
}

{
    my $Defined_subs_for_under_0_99x;

    sub define_subs_for_under_0_99x {

        return if $Defined_subs_for_under_0_99x;

        *croak = *croak = sub { shift->die(@_) };
        *carp = *carp = sub { shift->warn(@_) };

        *init_base_url = *init_base_url
            = sub { shift->initialize_base_url(@_) };
        *init_page = *init_page
            = sub { shift->initialize_page(@_) };
        *init_values = *init_values
            = sub { shift->initialize_values(@_) };
        *init_action = *init_action
            = sub { shift->initialize_action(@_) };
        *init_response_headers = *init_response_headers
            = sub { shift->initialize_response_headers(@_) };
        *init_binmode = *init_binmode
            = sub { shift->initialize_binmode(@_) };

        *is_blessed = *is_blessed = sub { shift->blessed(@_) };

        *ident = *ident = sub { shift->refaddr(@_) };

        *keys_arrayref = *keys_arrayref
            = sub { [ keys %{ $_[0]->value_hashref } ] };

        *exists_key = *exists_key
            = sub { exists $_[0]->value_hashref->{ $_[1] } };

        *expand = *expand = sub { Waft->expand_tabs(@_) };

        $Defined_subs_for_under_0_99x = 1;

        return;
    }

    my $Defined_subs_for_under_0_52x;

    sub define_subs_for_under_0_52x {

        return if $Defined_subs_for_under_0_52x;

        *array = *array = sub {
            my ($self, $key, @values) = @_;

            if ( @values ) {
                my @old_values = $self->get_values($key);

                $self->set_values($key, @values);

                return @old_values;
            }

            return $self->get_values($key);
        };

        *arrayref = *arrayref = sub {
            my ($self, $key, $arrayref) = @_;

            return $self->value_hashref->{$key} = $arrayref
                if ref $arrayref eq 'ARRAY';

            return $self->value_hashref->{$key} ||= $arrayref;
        };

        eval q{ sub begin  { return } };
        eval q{ sub before { return } };

        *end = *end = sub { return };

        *form_elements = *form_elements = sub {
            my ($self, @args) = @_;

            if (@args == 1
                and defined $args[0]
                and $args[0] eq 'ALL' || $args[0] eq 'ALLVALUES'
            ) {
                $args[0] = 'ALL_VALUES';
            }

            $self->output_waft_tags(@args);

            return;
        };

        *query = *query = \&cgi;

        *waft_tags = *waft_tags = \&get_waft_tags;

        *_join_values = *_join_values = \&join_values;

        *_load_query_param = *_load_query_param = sub {
            my ($self) = @_;

            $self->init_page;
            $self->init_action;
            $self->init_values;

            return;
        };

        *__DEFAULT = *__DEFAULT = sub {
            my ($self, @args) = @_;

            return { page => 'default.html', action => $self->action }, @args;
        };

        $Defined_subs_for_under_0_52x = 1;

        return;
    }
}

package Waft::Object;

sub TIEHASH {

    bless {};
}

sub STORE {
    if (ref $_[2] eq 'ARRAY') {
        @{ $_[0]{ defined $_[1] ? $_[1] : warn_and_null() } } = @{$_[2]};
    }
    else {
        @{ $_[0]{ defined $_[1] ? $_[1] : warn_and_null() } } = ($_[2]);
    }
}

sub warn_and_null {
    require Carp;
    Carp::carp('Use of uninitialized value');
    q{};
}

sub FETCH {
    my $arrayref = $_[0]{ defined $_[1] ? $_[1] : warn_and_null() }
        or return;

    $arrayref->[0];
}

sub FIRSTKEY { keys %{$_[0]}; each %{$_[0]} }

sub NEXTKEY  {                each %{$_[0]} }

sub EXISTS { exists $_[0]{ defined $_[1] ? $_[1] : warn_and_null() } }

sub DELETE { delete $_[0]{ defined $_[1] ? $_[1] : warn_and_null() } }

sub CLEAR { %{$_[0]} = () }

1;
__END__

=head1 NAME

Waft - A simple web application framework

=encoding utf8

=head1 SYNOPSIS

Waft は、アプリケーションクラスの基底クラスとなって動作する、CGI用の
フレームワークである。

    package MyWebApp;

    use base qw( Waft );

    __PACKAGE__->use_utf8;
    __PACKAGE__->set_default_content_type('text/html; charset=UTF-8');

    sub __default__direct {
        my ($self) = @_;

        return 'TEMPLATE';
    }

クラスメソッド C<waft> は、アプリケーションクラスに属するオブジェクトを
生成して、リクエストに応じたメソッドをディスパッチする。

    MyWebApp->waft;

また、テンプレート処理も実装している。

    <%

    use strict;
    use warnings;

    my ($self) = @_;

    %>

    <h1><% = $self->page %></h1>

    <p>
    Howdy, world!
    </p>

=head1 DESCRIPTION

Waft は、1ファイルのみで構成された軽量の
Webアプリケーションフレームワークであり、Perl 5.005 以上で動作する。（ただし、
UTF-8 を扱うには 5.8.1 以上の Perl と 3.21 以上の L<CGI> が必要。）

リクエストに応じたメソッドのディスパッチ、
オブジェクト変数の保持、
テンプレート処理
等の機能を有する。

=head1 DISPATCH

Waft は、リクエストに応じたメソッドをディスパッチする。

CGI が QUERY_STRING を指定されずに単純に GET リクエストされた場合、
Waftは、C<__default__direct> という名前のメソッドを起動する。

    http://www/mywebapp.cgi

    $self->__default__direct を起動する

form.html というページをリクエストされた場合は、C<__form__direct> という名前の
メソッドを起動する。

    http://www/myapp.cgi?p=form.html

    $self->__form__direct を起動する

form.html から "send" という名前の SUBMIT によりリクエストされた場合は、
C<__form__send> という名前のメソッド。

    http://www/myapp.cgi?s=form.html&v=&send=

    $self->__form__send を起動する

メソッド C<__form__send> が、"confirm.html" を戻した場合は、Waft は次に、
C<__confirm__indirect> という名前のメソッドを起動する。

    sub __form__send {
        my ($self) = @_;

        return 'confirm.html';
    }

    $self->__confirm__indirect を起動する

=head2 ACTION METHOD

Waft がディスパッチするメソッドをアクションメソッドと呼ぶ。
アクションメソッドの名前は、C<page_id> と C<action_id> で構成する。

=over 4

=item *

page

Web の 1ページに相当する単位で、アクションメソッド名の構成と
テンプレートの選択のために使用する。C<< $self->page >> で取得できる。

=item *

page_id

C<page> の英数字以外の文字をアンダースコアに変換し、拡張子を除いた文字列。
form.html の場合は "form"、form/header.html の場合は、"form_header" となる。
C<< $self->page_id >> で取得できる。

=item *

action

C<page> へのリクエストの種別。C<page> とともに、
アクションメソッド名を構成する。リンクによるリクエストの場合は "direct"、
FORM からの SUBMIT によるリクエストの場合はその SUBMIT の NAME（以下の例では
"send"）、

    <input type="submit" name="send" />
                               ^^^^

クライアントからのリクエストではなく、メソッドの戻り値で指定された C<page>
への内部のページ遷移の場合は "indirect" となる。

なお、FORM からの SUBMIT によるリクエストにおいて、SUBMIT に NAME
が指定されていない場合、C<action> は "submit" となる。

    <input type="submit" />

=item *

action_id

C<action> の先頭から . までの文字列。direct の場合は "direct"、move.map.x
の場合は "move" となる。

=back

アンダースコア 2つ、C<page_id>、アンダースコア 2つ、C<action_id>
を連結した文字列をアクションメソッドの名前とする。

C<__ page_id __ action_id>

=head2 return $page

アクションメソッドの戻り値を次に処理する C<page> として、
引き続きアクションメソッドのディスパッチを行う。この場合、C<action> は
"indirect" とする。

    return 'confirm.html'; # Waft は次に __confirm__indirect を起動する

ただし、戻り値を以下のように指定する事で、C<action> に "indirect"
以外の値も指定できる。

    return ['form.html', 'direct']; # Waft は次に __form__direct を起動する

もしくは、

    return { page => 'form.html', action => 'direct' }; # same as above

=head2 'CURRENT'

"CURRENT" は、"現在のページ" を意味する。すなわち C<return 'CURRENT'> は、
C<< return $self->page >> と同義である。

    return 'CURRENT';

    return $self->page; # same as above

=head2 return 'TEMPLATE'

アクションメソッドの戻り値が "TEMPLATE" の場合、
Waft はアクションメソッドのディスパッチを終了して、C<page>
のテンプレート処理に移行する。

    sub __form__direct {

        return 'TEMPLATE'; # form.html のテンプレート処理に移行する
    }

Waft は、"CURRENT" の場合と同様に C<page> を 変更せず、C<action> を "template"
として処理する。すなわち C<return 'TEMPLATE'> は以下と同義である。

    return ['CURRENT', 'template'];

もしくは、

    return { page => 'CURRENT', action => 'template' };

=head2 begin

Waft の処理の開始時にディスパッチされるメソッド。

         begin
           |
           |<---------------------------+
         before                         |
           |                            |
     ACTION METHOD  return 'other.html' |
           +----------------------------+
           | return 'TEMPLATE'
           |
         before
           |
    TEMPLATE PROCESS
           |
           |
          end

C<begin> と C<before> の戻り値は、アクションメソッドのそれと同様に処理される。

    sub begin {

        return 'TEMPLATE'; # アクションメソッドをディスパッチせずにテンプレー
                           # ト処理に移行する
    }

=head2 before

アクションメソッドをディスパッチする前、およびテンプレート処理を行う前に
ディスパッチされるメソッド。

    sub before {
        my ($self) = @_;

        return if $self->page eq 'login.html';

        return 'login.html' if not $self->login_ok;

        return;
    }

=head2 end

Waft の処理の終了時にディスパッチされるメソッド。

=head1 OBJECT VALUE

Waft が生成するオブジェクトが持つ値をオブジェクト変数と呼ぶ。
オブジェクト変数は QUERY_STRING および FORM に展開され、
ページ遷移後に生成されるオブジェクトに引き継がれる。

    sub __default__direct {
        my ($self) = @_;

        $self->{page} = 0;
        $self->{sort} = 'id';

        return 'TEMPLATE';
    }

    <a href="<% = $self->url('page.html', 'ALL_VALUES') %>">

    page.html へ遷移するリンクの QUERY_STRING にオブジェクト変数が展開される


    sub __page__direct {
        my ($self) = @_;

        $self->{page} # 0
        $self->{sort} # 'id'

QUERY_STRING の場合は、引き継ぐ値、もしくは "ALL_VALUES" の指定が
必要であるが、FORM の場合はメソッド C<compile_template> が自動的に展開する。

    <form action="<% = $self->url %>">
    <input type="submit" />
    </form>

    compile_template が <form></form> の中に自動的に展開する

オブジェクト変数は 1次元のハッシュ変数で管理されるため、
リファレンスを引き継ぐ事はできない。また、C<undef> も引き継ぐ事ができない。

ただし、メソッド C<set_values>、C<get_values> により 1つのキーでリストを扱う事
ができる。

    $self->set_values( sort => qw( id ASC ) );

    $self->{sort}                # 'id'
    $self->get_value('sort')     # same as above
    $self->get_values('sort')    # ('id', 'ASC')
    $self->get_values('sort', 1) # ('ASC')

=head1 TEMPLATE PROCESS

Waft は、Perl コードをスクリプトレットとして処理するテンプレート処理機能を
持つ。

C<page> をテンプレートファイルとして処理する。
テンプレートファイルはアプリケーションクラスおよびその基底クラスのモジュールが
配置されているディレクトリから検索される。

アプリケーションクラス "MyWebApp" が、基底クラス "Waft::CGISession"、"Waft" を
継承している場合、default.html は以下の順に検索される。

    lib/MyWebApp.template/default.html
    lib/MyWebApp/default.html
    lib/Waft/CGISession.template/default.html
    lib/Waft/CGISession/default.html
    lib/Waft.template/default.html
    lib/Waft/default.html

C<page> が C<@Waft::Allow_template_file_exts> に定義されていない拡張子
（.html、.css、.js、.txt 以外の拡張子）である場合は、検索されるディレクトリは
.template のみとなる。

    lib/MyWebApp.template/module.pm
    lib/Waft/CGISession.template/module.pm
    lib/Waft.template/module.pm

最初に見つかったファイルをテンプレートファイルとして処理する。

テンプレートファイル内の "<%" と "%>" で囲まれた部分はスクリプトレットとして
処理される。

    <% for ( 1 .. 10 ) { %>
        <br />
    <% } %>

"<%word=" と "%>" で囲まれた部分は、評価結果がエスケープされて出力される。

    <% for ( 1 .. 4 ) { %>
        <%word= $_ %> * 2 = <%word= $_ * 2 %><br />
    <% } %>

    1 * 2 = 2
    2 * 2 = 4
    3 * 2 = 6
    4 * 2 = 8


    <% my $break = '<br />'; %>
    <%word= $break %>

    &lt;br /&gt;

"<%word=" は "<%w=" もしくは "<%=" に省略できる。スペースを空ける事もできる。

    <%word=$self->url%>
    <%w= $self->url %>  <!-- same as above -->
    <% = $self->url %>  <!-- same as above -->

"<%text=" と "%>" で囲まれた部分は、評価結果がエスケープされ、
さらにタブ文字の展開と改行タグの挿入が行われて出力される。

    <% my $text = "Header\n\tItem1\n\tItem2"; %>
    <%text= $text %>

    Header<br />
    &nbsp; &nbsp; &nbsp; &nbsp; Item1<br />
    &nbsp; &nbsp; &nbsp; &nbsp; Item2

"<%text=" は "<%t=" に省略できる。
"<%word=" と同様にスペースを空ける事もできる。

    <%text=$self->{text}%>
    <% t = $self->{text} %> <!-- same as above -->

"<%jsstr=" と "%>" で囲まれた部分は、JavaScript に必要なエスケープが行われる。

    alert('<%jsstr= '</script>' %>');

    alert('\x3C\/script\x3E');

"<%jsstr=" は "<%j=" に省略できて、他と同様にスペースも空けられる。

=head1 METHODS

=head2 set_waft_backword_compatible_version

引数: $version

クラスメソッド。Waft の過去のバージョンを保持する。いくつかのメソッドと処理が
指定バージョンの仕様になる。

=head2 use_utf8

クラスメソッド。内部処理を UTF-8 で行う。5.8.1 以上の Perl と 3.21 以上の
L<CGI> が必要。

=head2 set_allow_template_file_exts

引数: @extensions

クラスメソッド。クラスのモジュールが配置されているディレクトリから検索する
対象とするテンプレートファイルの拡張子を保持する。詳細は
L<"TEMPLATE PROCESS"> を参照の事。

=head2 set_default_content_type

引数: $content_type

クラスメソッド。L<"header"> で Content-Type が指定されない場合の値を保持する。
デフォルトは text/html。

=head2 waft

引数: @arguments?

戻り値: @return_values

オブジェクトの生成（L<"new">）、初期化（L<"initialize">）を行い、Waft の処理を
行う。オブジェクトメソッドの場合は Waft の処理のみを行う。Waft の処理の詳細は 
L<"DISPATCH"> を参照の事。指定された引数を最初に呼ぶメソッドに渡し、最後に
呼んだメソッドの戻り値を戻す。

=head2 new

戻り値: $object

クラスメソッド。オブジェクトの生成を行う。

=head2 initialize

戻り値: $object

オブジェクトの初期化を行う。

=head2 cgi

戻り値: $cgi

L<CGI> オブジェクトを戻す。

=head2 set_value

引数: $key, $value

オブジェクト変数に値を保持する。

=head2 set_values

引数: $key, @values?

オブジェクト変数に複数の値を保持する。

=head2 get_value

引数: $key, $i?

戻り値: $value

オブジェクト変数の値を戻す。指定された引数を複数の値に対する添え字とする。

=head2 get_values

引数: $key, @i?

戻り値: @values

オブジェクト変数の複数の値を戻す。指定された引数を添え字とする。

=head2 clear_values

オブジェクト変数を全て削除する。

=head2 page

戻り値: $page

page を戻す。

=head2 action

戻り値: $action

action を戻す。

=head2 header

引数: $response_header

レスポンスヘッダを保持する。L<"output"> が呼ばれるまでに呼ばれる必要がある。
add_header という別名もある。

=head2 call_template

引数: $page or $template_path, @arguments?

戻り値: @return_values

引数に指定されたページ、またはパスのファイルのテンプレート処理を行う。詳細は
L<"TEMPLATE PROCESS"> を参照の事。include という別名もある。

=head2 url

引数: $page, \@keys? and/or @key_value_pairs?

戻り値: $url

URL を戻す。引数に指定されたページとオブジェクト変数のキー、キー値ペアを
クエリ文字列に構成する。

    $self->{page} = 0;
    $self->{sort} = 'id';

    $self->url('CURRENT', ['page', 'sort']);
    # { page => 0, sort => 'id' } となる URL

    $self->url('CURRENT', ['page']);
    # { page => 0 } となる URL

    $self->url('CURRENT', ['page'], sort => 'name');
    # { page => 0, sort => 'name' } となる URL

    $self->url('CURRENT', page => 1, sort => 'name');
    # { page => 1, sort => 'name' } となる URL

=head2 absolute_url

引数: $page, \@keys? and/or @key_value_pairs?

戻り値: $absolute_url

http://、または https:// から始まる URL を戻す。

=head2 output

引数: @strings?

引数に指定された値を出力する。テンプレート処理でも使用する。最初に
呼ばれた時には、L<"header"> で指定されたレスポンスヘッダも出力する。

=head2 get_content

引数: $coderef, @arguments?

戻り値: $content, @return_values

引数で指定された無名サブルーチンを呼ぶ。その間 L<"output"> に値を出力させずに
バッファリングさせて、バッファの内容を戻す。

=head2 stash

引数: $class?

戻り値: $hashref

クラスの名前（引数に指定されたクラス、引数が指定されない場合は呼び出し元の
クラスの名前）毎に保持する stash のリファレンスを戻す。stash は
アプリケーションが自由に使用できるハッシュ変数。

=head2 html_escape

引数: @values

戻り値: @escaped_values

エスケープを行う。テンプレート処理でも使用する。

=head2 jsstr_escape

引数: @values

戻り値: @escaped_values

JavaScript に必要なエスケープを行う。テンプレート処理でも使用する。

=head2 url_encode

引数: @values

戻り値: @encoded_values

URL エンコードを行う。L<"url">、L<"absolute_url"> でも使用する。

=head2 warn

引数: @messages?

アプリケーションクラスを呼び出し元とする警告メッセージを出力する。

    package MyWebApp::Base;

    use base qw( Waft );

    use Carp;

    sub foo {
        my ($self) = @_;

        warn 'error';         # error at - line 10. # here
        carp 'error';         # error at - line 31
        $self->warn('error'); # error at - line 24.

        return;
    }

    package MyWebApp;

    use base qw( MyWebApp::Base );

    sub foo {
        my ($self) = @_;

        $self->next;          # line 24

        return;
    }

    package main;

    MyWebApp->new->foo;       # line 31

=head2 die

引数: @messages?

L<"warn"> と同様のメッセージを出力して例外を発生する。

=head2 next

引数: @arguments

戻り値: @return_values

継承元の同名のメソッドを呼ぶ。

=head1 AUTHOR

Yuji Tamashiro, E<lt>yuji@tamashiro.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Yuji Tamashiro

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
