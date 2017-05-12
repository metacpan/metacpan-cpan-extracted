package XUL::App::I18N;

use strict;
use warnings;

#use lib 'tmplib/lib';
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon ();
use File::Spec ();
#use Smart::Comments;

our $Lang = [];

sub new {
    my $class = shift;
    my $self  = {};
    my $lang = $Lang;
    bless $self, $class;

    # XXX: this requires a full review, LML->get_handle is calling new
    # on I18N::lang each time, but we really shouldn't need to rerun
    # the import here.

    my @import = map { (Gettext => $_) } _get_file_patterns();

    ### @import
    ### NEW BEGIN...
    Locale::Maketext::Lexicon->import(
        {   '*' => \@import,
            _decode => 1,
            _auto   => 1,
            _style  => 'gettext',
        }
    );
    ### NEW END...

    my $lh = $class->get_handle(@$lang);
    #if (!defined $lh) {
    #die "Can't get I18N handle for @$lang";
        #}

    $self->init;

    my $loc_method = sub {
        # Retain compatibility with people using "-e _" etc.
        return \*_ unless @_; # Needed for perl 5.8

        # When $_[0] is undef, return undef.  When it is '', return ''.
        no warnings 'uninitialized';
        return $_[0] unless (length $_[0]);

        local $@;
        # Force stringification to stop Locale::Maketext from choking on
        # things like DateTime objects.
        my @stringified_args = map {"$_"} @_;
        my $result = eval { $lh->maketext(@stringified_args) };
        if ($@) {
            warn $@;
            # Sometimes Locale::Maketext fails to localize a string and throws
            # an exception instead.  In that case, we just return the input.
            return join(' ', @stringified_args);
        }
        return $result;
    };

    {
        no strict 'refs';
        no warnings 'redefine';
        #die "I know you!";
        *_ = $loc_method;
        ${"main::_"} = $loc_method;
    }
    return $self;
}

sub _get_file_patterns {
    my @ret;

    my $dir = File::Spec->rel2abs('po');
    if (!-d $dir) {
        die "Po Directory po/ does not exist: $dir";
    }
    @ret = "$dir/*.po";
    if (!@ret) {
        warn "No po/*.po files found.\n";
    }
    #die "@ret";
    return @ret;
}

package XUL::App::I18N::en;
use base 'Locale::Maketext';
our %Lexicon = ( _fallback => 1, _AUTO => 1 );

1;

