package PerlConsole::Console;

# This class implements all the stuff needed to communicate with 
# the console.
# Either for displaying message in the console (error and verbose stuff)
# or for launcing command, or even changing the console's context.

# dependencies
use strict;
use warnings;
use Term::ReadLine;
use PerlConsole::Preferences;
use PerlConsole::Commands;
use Module::Refresh;
use Lexical::Persistence;
use Getopt::Long;
use B::Keywords qw(@Functions);

# These are all the built-in keywords of Perl
my @perl_keywords = @B::Keywords::Functions;

##############################################################
# Constructor
##############################################################
sub new($@)
{
    my ($class, $version) = @_;

    # the console's data structure
    my $self = {
        version             => $version,
        prefs               => new PerlConsole::Preferences,
        terminal            => new Term::ReadLine("Perl Console"),
        lexical_environment => new Lexical::Persistence,
        rcfile              => $ENV{HOME}.'/.perlconsolerc',
        prompt              => "Perl> ",
        modules             => {},
        logs                => [],
        errors              => [],
    };
    bless ($self, $class);

    # set the readline history if a Gnu terminal
    if ($self->{'terminal'}->ReadLine eq "Term::ReadLine::Gnu") {
        $SIG{'INT'} = sub { $self->clean_exit(0) };
        $self->{'terminal'}->ReadHistory($ENV{HOME} . "/.perlconsole_history");
    }

    # init the completion list with Perl internals...
    $self->addCompletion([@perl_keywords]);

    # ... and with PerlConsole's ones 
    $self->addCompletion([$self->{'prefs'}->getPreferences]);
    foreach my $pref ($self->{'prefs'}->getPreferences) {
        $self->addCompletion($self->{'prefs'}->getValidValues($pref));
    }
    # FIXME : we'll have to rewrite the commands stuff in a better way
    $self->addCompletion([qw(:quit :set :help)]);
    # the console's ready!
    return $self;
}

# This is where we define all the options supported
# on the command-line
sub parse_options
{
    my ($self) = @_;
    GetOptions('rcfile=s' => \$self->{rcfile});
    
    # cleanup of the ~ shortcut for $ENV{HOME}
    my $home = $ENV{HOME};
    $self->{rcfile} =~ s/^~/${home}/;
}

# method for exiting properly and flushing the history
sub clean_exit($$)
{
    my ($self, $status) = @_;
    if ($self->{'terminal'}->ReadLine eq "Term::ReadLine::Gnu") {
        $self->{'terminal'}->WriteHistory($ENV{HOME} . "/.perlconsole_history");
    }
    exit $status;
}

##############################################################
# Terminal
##############################################################

sub addCompletion($$)
{
    my ($self, $ra_list) = @_;
    my $attribs = $self->{'terminal'}->Attribs;
    $attribs->{completion_entry_function} = $attribs->{list_completion_function};
    if (! defined $attribs->{completion_word}) {
        $attribs->{completion_word} = $ra_list;
    }
    else {
        foreach my $elem (@{$ra_list}) {
            push @{$attribs->{completion_word}}, $elem;
        }
    }
}

sub is_completion
{
    my ($self, $item) = @_;
    my $attribs = $self->{'terminal'}->Attribs;
    return grep /^${item}$/, @{$attribs->{completion_word}};
}

sub getInput
{
    my ($self) = @_;
    return $self->{'terminal'}->readline($self->{'prompt'});
}

##############################################################
# Communication methods
##############################################################

sub header
{
    my ($self) = @_;
    $self->message("Perl Console ".$self->{'version'});
}

# add an error the error list, this is a LIFO stack, see getError.
sub addError($$)
{
    my ($self, $error) = @_;
    return unless defined $error;
    chomp ($error);
    push @{$self->{'errors'}}, $error;
}

# returns the last error message seen
sub getError($)
{
    my ($self) = @_;
    return $self->{'errors'}[$#{$self->{'errors'}}];
}

# clear the error messages, back to an empty list.
sub clearErrors($)
{
    my ($self) = @_;
    $self->{'errors'} = [];
}

# prints an error message, and record it to the error list
sub error($$)
{
    my ($self, $string) = @_;
    chomp $string;
    $self->addError($string);
    print "[!] $string\n";
}

sub message
{
    my ($self, $string) = @_;
    if (! defined $string) {
        print "undef\n";
    }
    else {
        chomp $string;
        print "$string\n";
    }
}

# time 
sub getTime($)
{
    my ($self) = @_;
    my ($sec, $min, $hour, 
        $mday, $mon, $year, 
        $wday, $yday, $isdst) = localtime(time);
    $mon++;
    $year += 1900;
    $mon = sprintf("%02d", $mon);
    $mday = sprintf("%02d", $mday);
    return "$year-$mon-$mday $hour:$mon:$sec";
}

# push a log message on the top of the stack
sub addLog($$)
{
    my ($self, $log) = @_;
    push @{$self->{'logs'}}, "[".$self->getTime."] $log";
}

# get the last log message and remove it
sub getLog($)
{
    my ($self) = @_;
    my $log = $self->{'logs'}[$#{$self->{'logs'}}];
    pop @{$self->{'logs'}};
    return $log;
}

# Return the list of all unread log message and empty it
sub getLogs
{
    my ($self) = @_;
    my $logs = $self->{'logs'};
    $self->{'logs'} = [];
    return $logs;
}

##############################################################
# Preferences
##############################################################

# accessors for the encapsulated preference object
sub setPreference($$$)
{
    my ($self, $pref, $value) = @_;
    my $prefs = $self->{'prefs'};
    $self->addLog("setPreference: $pref = $value");
    return $prefs->set($pref, $value);
}

sub getPreference($$)
{
    my ($self, $pref) = @_;
    my $prefs = $self->{'prefs'};
    my $val = $prefs->get($pref);
    return $val;
}

# set the output and take care to load the appropriate module
# for the output
sub setOutput($$)
{
    my ($self, $output) = @_;
    my $rh_output_modules = {
        'yaml'   => 'YAML',
        'dumper' => 'Data::Dumper',
        'dump'   => 'Data::Dump',
        'dds'    => 'Data::Dump::Streamer',
    };
    
    if (exists $rh_output_modules->{$output}) {
        my $module = $rh_output_modules->{$output};
        unless ($self->load($module)) {
            $self->error("Unable to load module \"$module\", ".
                "cannot use output mode \"$output\"");
            return 0;
        }
    }
    
    unless ($self->setPreference("output", $output)) {
        $self->error("unable to set preference output to \"$output\"");
        return 0;
    }

    return 1;
}

# this interprets a string, it calls the appropriate internal 
# function to deal with the provided string
sub interpret($$)
{
    my ($self, $code) = @_;

    # cleanup a bit the input string
    chomp $code;
    return unless length $code;

    # look for the exit command.
    $self->clean_exit(0) if $code =~ /(:quit|exit)/i;

    # look for console's internal language
    return if $self->command($code);

    # look for a module to import
    return if $self->useModule($code);

    # Refresh the loaded modules in @INC that have changed
    Module::Refresh->refresh;

    # looks like it's time to evaluates some code ;)
    $self->print_result($self->evaluate($code));
    print "\n";
    
    # look for something to save in the completion list
    $self->learn($code);

}

# this reads and interprets the contents of an rc file (~/.perlconsolerc)
# at startup.  It is useful for things like loading modules that we always
# want present or setting up some default variables
sub source_rcfile($)
{
    my ($self) = @_;
    my $file = $self->{'rcfile'};
    $self->addLog("loading rcfile: $file");

    if ( -r $file) {
        if (open(RC, "<", "$file")) {
            while(<RC>) {
                $self->interpret($_);
            }
            close RC;
        }
        else {
            $self->error("unable to read rcfile $file : $!");
        }
    }
    else {
        $self->error("rcfile $file is not readable");
    }
}

# Context methods

# load a module in the console's namespace
# also take car to import all its symbols in the complection list
sub load($$;$)
{
    my ($self, $package, $tag) = @_;
    unless (defined $self->{'tags'}{$package}) {
        $self->{'tags'}{$package} = {};
    }

    # look for already loaded modules/tags
    if (defined $tag) {
        return 1 if defined $self->{'tags'}{$package}{$tag};
    }
    else {
        return 1 if defined $self->{'modules'}{$package};
    }

    if (eval "require $package") {
        if (defined $tag) {
            foreach my $t (split /\s+/, $tag) {
                eval { $package->import($t); };
                if ($@) {
                    $self->addError($@);
                    return 0;
                }
                # mark the tag as loaded
                $self->{'tags'}{$package}{$tag} = 1;
            }
        }
        else {
            eval { $package->import(); };
            if ($@) {
                $self->addError($@);
                return 0;
            }
        }
        # mark the module as loaded
        $self->{'modules'}{$package} = 1;
        return 1;
    }
    $self->addError($@);
    return 0;
}

# This function takes a module as argument and loads all its namespace
# in the completion list.
sub addNamespace($$)
{
    my ($self, $module) = @_;
    my $namespace;
    eval '$namespace = \%'.$module.'::';
    if ($@) {
        $self->error($@);
    }
    $self->addLog("loading namespace of $module");

    foreach my $token (keys %$namespace) {
        # only put methods found that begins with a letter
        if ($token =~ /^([a-zA-Z]\S+)$/) {
            $self->addCompletion([$1]);
        }
    }
}
 
# This function reads the command line and looks for something that is worth
# saving in the completion list
sub learn($$)
{
    my ($self, $code) = @_;
    my $env = $self->{lexical_environment}->get_context('_');
    foreach my $var (keys %$env) {
        $self->addCompletion([substr($var, 1)]) 
            unless $self->is_completion(substr($var, 1));
    }
}


# Thanks a lot to Devel::REPL for the Lexical::Persistence idea
# http://chainsawblues.vox.com/library/post/writing-a-perl-repl-part-3---lexical-environments.html
#
# We take the code given and build a sub around it, with each variable of the
# lexical environment declared with my's. Then, the sub built is evaluated
# in order to get its code reference, which is returned as the "compiled"
# code if success. If an error occured during the sub evaluation, undef is
# returned an the error message is sent to the console.
sub compile($$)
{
    my ($self, $code) = @_;
    # first we declare each variable in the lexical env
    my $code_begin = "";
    foreach my $var (keys %{$self->{lexical_environment}->get_context('_')}) {
        $code_begin .= "my $var;\n";
    }
    # then we prefix the user's code with those variables init and put the 
    # resulting code inside a sub
    $code = "sub {\n$code_begin\n$code;\n};\n";

    # then we evaluate the sub in order to get its ref
    my $compiled = eval "$code";
    if ($@) {
        $self->error("compilation error: $@");
        return undef;
    }
    return $compiled;
}

# This function takes care of evaluating the inputed code
# in a way corresponding to the user's output choice.
sub evaluate($$)
{
    my ($self, $code) = @_;

    # compile the code to a coderef where each variables of the lexical 
    # environment are declared
    $code = $self->compile($code);
    return undef unless defined $code;

    # wrap the compiled code with Lexical::Persitence
    # in order to catch each variable in the lexenv
    $code = $self->{lexical_environment}->wrap($code);
    return undef unless defined $code && (ref($code) eq 'CODE');

    # now evaluate the coderef pointed by the sub lexenv->wrap 
    # built for us
    my @result = eval { &$code(); };

    # an error occured?
    if ($@) {
        $self->error("Runtime error: $@");
        return undef;
    }
    return \@result;
}

# This function is dedicated to print the result in the good way
# It takes the resulting array of the code evaluated and converts it
# to the wanted output
sub print_result
{
    my ($self, $ra_result) = @_;
    return unless defined $ra_result and (ref($ra_result) eq 'ARRAY');
    my @result = @{$ra_result};
    $self->message($self->get_output(@result));
}


# the outputs
sub get_output($@)
{
    my ($self, @result) = @_;
    my $output = $self->getPreference('output');
    
    # default output is scalar
    my $str = (@result == 1) ? $result[0] : @result;
    
    # YAML output
    if ($output eq 'yaml') {
        eval '$str = YAML::Dump(@result)';
    }

    # Data::Dumper output
    elsif ($output eq 'dumper') {
        eval '$str = Data::Dumper::Dumper(@result)';
    }

    # Data::Dump output
    elsif ($output eq 'dump') {
        eval '$str = Data::Dump::dump(@result)';
    }

    # Data::Dump::Streamer output
    elsif ($output eq 'dds') {
        my $to_dump = (@result > 1) ? \@result : $result[0];
        if (ref($to_dump)) {
            eval 'my $dds = new Data::Dump::Streamer; '.
             '$dds->Freezer(sub { return "$_[0]"; }); '.
             '$dds->Data($to_dump); '.
             '$str = $dds->Out;';
        }
        else {
            return $to_dump;
        }
    }

    if ($@) {
        $self->error("Unable to get formated output: $@");
        return "";
    }
    return $str;
}

# This looks for a use statement in the string and if so, try to 
# load the module in the namespance, with all tags sepcified in qw()
# Returns 1 if the code given was about something to load, 0 else.
sub useModule($$)
{
    my ($self, $code) = @_;
    my $module;
    my $tag;
    if ($code =~ /use\s+(\S+)\s+qw\((.+)\)/) {
        $module = $1;
        $tag = $2;
    }
    elsif ($code =~ /use\s+(\S+)/) {
        $module = $1;
    }

    if (defined $module) {
        # drop the possible trailing ";"
        $module =~ s/\s*;\s*$//;

        if (!$self->load($module, $tag)) {
            my $error = $@;
            chomp $error;
            $self->error($error);
        }
        else {
            $self->addNamespace($module);
        }
        return 1;
    }
    return 0;
}

# this looks for internal command in the given string
# this is used for changing the user's preference, saving the session,
# loading a session, etc...
# The function returns 1 if it found something to do, 0 else.
sub command($$)
{
    my ($self, $code) = @_;
    return 0 unless $code;

    if (PerlConsole::Commands->isInternalCommand($code)) {
        return PerlConsole::Commands->execute($self, $code);
    }
    return 0;
}



# END 
1;
