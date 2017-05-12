use 5.010;
use strict;
use warnings;

package Vim::Tag;
BEGIN {
  $Vim::Tag::VERSION = '1.110690';
}

# ABSTRACT: Generate perl tags for vim
use File::Find;
use File::Slurp;
use Hash::Rename;
use UNIVERSAL::require;
use Vim::Tag::Null;
use parent qw(Class::Accessor::Constructor Getopt::Inherited);
__PACKAGE__->mk_constructor->mk_scalar_accessors(qw(tags))
  ->mk_array_accessors(qw(libs))
  ->mk_hash_accessors(qw(is_fake_package filename_for has_super_class));
use constant DEFAULTS => (tags => {});
use constant GETOPT => (qw(use=s out|o=s first|f libs|l=s@));
use constant GETOPT_DEFAULTS => (verbose => 0, out => '-');

# --use: whether to 'use' the package; might gen more tags. The value is the
# path prefix under which to use() modules.
#
# --first: if set, tags are only generated the first time each package is
# seen. Seeing a package twice could happen if you have a development version
# but have it installed as well. Use this option if you index the development
# directory first and only want to see that version.
sub run {
    my $self = shift;
    $self->init;
    $self->do_getopt;
    $self->determine_libs;
    exit unless $self->libs;
    $self->generate_tags;
    $self->add_SUPER_tags;
    $self->add_yaml_marshall_tags;
    $self->finalize;
    $self->write_tags;
}
sub init { }

sub finalize {
    my $self = shift;

    # avoid Test::Base doing END{} processing, which, in the absence of real
    # tests, would produce annoying error messages.
    Test::Builder::plan(1) if $Test::Base::VERSION;
}

sub setup_fake_package {
    my ($self, @packages) = @_;
    for my $package (@packages) {
        (my $file = "$package.pm") =~ s!::!/!g;
        $INC{$file} = 'DUMMY';
        no strict 'refs';
        @{ $package . '::ISA' } = qw(Vim::Tag::Null);
        $self->is_fake_package($package, 1);
    }
    $self;
}

sub determine_libs {
    my $self = shift;

    our @libs = grep { !/^\.+$/ } grep { ref ne 'CODE' } @INC;
    {
        no warnings 'once';
        unshift @libs => @Devel::SearchINC::PATHS;
    }
    if (defined $self->opt('libs')) {
        unshift @libs => @{ $self->opt('libs') };
    }

    my @keep_inc;
    for my $candidate (sort { length($a) <=> length($b) } @libs) {
        next if grep { index($candidate, $_) == 0 } @keep_inc;
        push @keep_inc => $candidate;
    }
    $self->libs(@keep_inc);
}

sub generate_tags {
    my $self = shift;
    $::PTAGS = $self;
    for ($self->libs) {
        find(
            {   follow => 1,
                wanted => sub {
                    if (-d && /^(bin|t|blib|inc)$/) {
                        return $File::Find::prune = 1;
                    }
                    return unless -f;
                    if (/\.pm$/o) {
                        $self->process_pm_file;
                    } elsif (/\.pod$/o) {
                        $self->process_pod_file;
                    }
                  }
            },
            $_
        );
    }
}

sub write_tags {
    my $self    = shift;
    my %tags    = %{ $self->tags };
    my $outfile = $self->opt('out');
    ## no critic (ProhibitTwoArgOpen)
    open my $fh, ">$outfile" or die "can't open $outfile for writing: $!\n";
    for my $tag (sort keys %tags) {
        printf $fh "%s\t%s\t%s\n", $tag, @$_ for @{ $tags{$tag} };
    }
    close $fh or die "can't close $outfile: $!\n";
}

sub delete_tags_by_pattern {
    my ($self, $pattern) = @_;
    my %tags = %{ $self->tags };
    for my $key (keys %tags) {
        delete $tags{$key} if $key =~ qr/$pattern/;
    }
    $self->tags(\%tags);
}

sub make_tag_aliases {
    my ($self, @rules) = @_;
    my %tags = %{ $self->tags };
    while (my ($search, $replace) = splice @rules, 0, 2) {
        for my $tag (keys %tags) {
            my $alias_tag = $tag;
            eval "\$alias_tag =~ s/$search/$replace/";
            die $@ if $@;
            next if $tag eq $alias_tag;
            $tags{$alias_tag} = $tags{$tag};
        }
    }
    $self->tags(\%tags);
}

sub add_tag {
    my ($self, $tag, $file, $search) = @_;

    # If you derived at the filename via caller(), you might get something
    # like /loader/0x1234567 if the file was loaded via Devel::SearchINC. But
    # it will also have set the correct filename in %INC, so we can find it
    # there. The index() is just an optimization.
    if (   defined($file)
        && index($file, '/loader/0x') == 0
        && $file =~ m!^/loader/0x[0-9a-f]+/(.*)!o) {
        $file = $INC{$1};
    }
    push @{ $self->tags->{$tag} } => [ $file, $search ];
}

sub make_package_tag {
    my ($self, %args) = @_;
    $self->filename_for($args{tag}, $args{filename})
      unless $self->exists_filename_for($args{tag});
    $self->add_tag($args{tag}, $args{filename}, "?^$args{search}\\>");
}

sub process_pm_file {
    my $self     = shift;
    my $text     = read_file($_);
    my $filename = $File::Find::name;
    my $package;
    while ($text =~ /^(package +(\w+(::\w+)*))\s*;/gmo) {
        my ($search, $tag) = ($1, $2);
        our %package_seen;
        return if $package_seen{$tag}++ && $self->opt('first');
        $self->make_package_tag(
            filename => $filename,
            search   => $search,
            tag      => $tag
        );
        $package ||= $tag;    # only remember the first package
    }
    while ($text =~ /^((?:sub|use\s+constant)\s+(\w+(?:::\w+)*))/gmo) {
        $self->add_tag($2, $filename, "?^$1\\>");
    }

    # custom ptags: simple strings
    while ($text =~ /#\s*(ptags:\s*(\w+(::\w+)*))\s*$/gmo) {
        my $tag = do {
            ## no critic (ProhibitNoStrict)
            no strict;
            no warnings;
            eval $2;
        };
        $self->add_tag($tag, $filename, "?^$1\\>");
    }

    # Custom ptags with code. The search name must be unique within file the
    # code ptag is defined in. Can't use the code as the ptags search pattern,
    # as it probably contains characters the vim regex engine considers
    # meta-characters ('[]$' etc).
    while ($text =~ /#\s*ptags-code:\s*([\w:]+)\s*(.*)/gmo) {
        my ($search, $code) = ($1, $2);   # assign in case the code uses regexes
        my @tags = do {
            ## no critic (ProhibitNoStrict)
            no strict;
            no warnings;
            eval $code;
        };
        die $@ if $@;
        $self->add_tag($_, $filename, "?^$search\\>") for @tags;
    }

    # custom ptags: per-file regexes
    my @re;
    while ($text =~ m!#\s*ptags:\s*/(.*)/\s*$!gm) {
        push @re => qr/$1/;
    }
    for my $re (@re) {

        # in theory we could nest this loop below the loop given above but
        # because they're iterating over the same string, funny things happen
        # when the regexes interfere with each other.
        while ($text =~ /$re/gm) {
            $self->add_tag($2, $filename, "?^$1\\>");
        }
    }
    if ($self->opt('use') && index($File::Find::name, $self->opt('use')) == 0) {

        # give modules a chance to output their custom ptags using $::PTAGS
        {

            # localise global variables so that no matter what the module does
            # with them, they will be restored at the end of the block
            #
            # Spiffy messes up base::import(), so we save it here and restore
            # it later.
            local @INC = @INC;

            # %SIG values are undef first time around?
            no warnings 'uninitialized';
            local %SIG = %SIG;
            require base unless defined $INC{'base.pm'};
            my $real_base_import = \&base::import;
            local $SIG{__WARN__} = sub {
                my $warning = shift;
                return
                  if index($warning, 'Too late to run INIT block at') != -1;
                return
                  if $warning =~
                      qr/^cannot test anonymous subs .* Test::Class too late/;
                CORE::warn "Warnings during during [${package}->require]:\n";
                CORE::warn($warning);
            };
            $package->require;
            {
                no warnings 'redefine';
                *base::import = $real_base_import;
            }
        }

        # Also determine inheritance and make tags
        no strict 'refs';
        $self->add_tag("subclass--$_", $filename, "?^use base\\>")
          for @{"${package}::ISA"};

        # Remember some data for tags we can't make now; we need the
        # information from all the files.
        $self->has_super_class($package, [ @{"${package}::ISA"} ]);
    }
}

sub process_pod_file {
    my $self     = shift;
    my $text     = read_file($_);
    my $filename = $File::Find::name;
    while ($text =~ /^(=for\s+ptags\s+package +(\w+(::\w+)*))\s*;/gmo) {
        my ($search, $tag) = ($1, $2);
        our %package_seen;
        return if $package_seen{$tag}++ && $self->opt('first');
        $self->make_package_tag(
            filename => $filename,
            search   => $search,
            tag      => $tag
        );
    }
}

# Add those tags that couldn't be added from looking at one file alone.
sub add_SUPER_tags {
    my $self            = shift;
    my %has_super_class = $self->has_super_class;
    while (my ($class, $super_array_ref) = each %has_super_class) {
        for my $super (@{ $super_array_ref || [] }) {
            next if $self->is_fake_package($super);
            unless ($self->exists_filename_for($super)) {
                warn sprintf
                  "class [%s]: can't get filename of superclass [%s]\n",
                  $class, $super;
                next;
            }
            $self->add_tag(
                "superclass--$class",
                $self->filename_for($super),
                "?^package $super\\>"
            );
        }
    }
}

sub add_yaml_marshall_tags {
    my $self = shift;
    return unless defined $YAML::TagClass;
    while (my ($marshall, $package) = each %$YAML::TagClass) {
        $marshall =~ s/\W/-/g;
        my $tag  = "marshall--$marshall";
        my $file = $self->filename_for($package);
        $self->add_tag($tag, $file, 1);
    }
}
1;


__END__
=pod

=for test_synopsis 1;
__END__

=head1 NAME

Vim::Tag - Generate perl tags for vim

=head1 VERSION

version 1.110690

=head1 SYNOPSIS

    $ ptags --use ~/code/coderepos -o ~/.ptags

In C<.vimrc>:

    set tags+=~/.ptags

then this works in vim:

    :ta Foo::Bar
    :ta my_subroutine

bash completion:

    cpanm Bash::Completion::Plugins::VimTag
    alias vit='vi -t'

then you can do:

    $ vit Foo::Bar
    $ vit my_subroutine

Custom tag generation

    package Foo::Bar;

    $::PTAGS && $::PTAGS->add_tag($tag, $filename, $line);

=head1 DESCRIPTION

Manage tags for perl code in vim, with ideas on integrating tags with the bash
programmable completion project. See the synopsis.

You should subclass this class to use it in your C<ptags>-generating
application. It could be as simple as that:

    #!/usr/bin/env perl
    use warnings;
    use strict;
    use base qw(Vim::Tag);
    main->new->run;

And if you want just that, there's the C<ptags> program. But it is more
interesting to extend this with custom aliases and to have your modules
generate custom tags and so on. The documentation on those features is a bit
sparse at the moment, but take a look in this distribution's C<examples/>
directory.

=head1 METHODS

=head2 add_tag

Takes a tag name, a filename and a 'search' argument that can either be a line
number which caused the tag, or a vim search pattern which will jump to the
tag. It will add the tag to the C<tags> hash.

=head2 add_SUPER_tags

Adds tags to find a class' superclass, generated if C<--use> is in effect.

=head2 add_yaml_marshall_tags

Adds tags for L<YAML::Marshall> serialization handlers.

=head2 delete_tags_by_pattern

Takes a pattern and deletes all tags that match this pattern. It's not used
directly in this class or in C<ptags>, but if you write a custom tags
generator you might want to munge the results.

=head2 determine_libs

Determines which directories should be searched. This includes all of C<@INC>
and anything set via C<--libs>. We also weed out nested directories. For
example, C<@INC> might contain

    /.../perl-5.12.2/lib/5.12.2/darwin-2level
    /.../perl-5.12.2/lib/5.12.2

Then we don't want the first one, but we do want the second one.

We go through library directories in C<@INC> order. I assume that
custom directories will be C<unshift()>-tacked onto L<@INC> so they
come first - this happens with C<use lib>, for example. That means
that the main perl libraries will come last. By going through the
libraries in reverse order, a local version of a module will take
precedence over a module that's installed system-wide. This is useful
if you have a module both under development in your C<$PROJROOT> as
well as installed system-wide; in this case you most likely want tags
to point to the locally installed version.

=head2 finalize

Finalizes things just before the tags are written. Here we just very
specifically avoid C<END{}> processing when L<Test::Base> has been
loaded.

=head2 generate_tags

Goes through all files in the directories set in C<determine_libs()>
and calls C<process_pm_file()> for C<.pm> files or
C<process_pod_file()> for C<.pod> files. The directories C<bin>, C<t>,
C<blib> and C<inc> (used by L<Module::Install>) are pruned.

=head2 make_package_tag

Makes a tag for a given package.

=head2 make_tag_aliases

Takes a list of regex/replace pairs and applies each pair to each tag
name. If the name has been changed by the C<s///> operation, a new tag
is recorded.

It's not used directly in this class or in C<ptags>, but if you write
a custom tags generator you might want to munge the results. For
example, you might want to make alias tags for long package names.
Instead of C<My::Very::Long::Package::Namespace::*> you might like to
have C<mvlpn::*> tags.

=head2 process_pm_file

Processes the given C<.pm> file.

=head2 process_pod_file

Processes the given C<.pod> file.

=head2 run

The main method that calls the other methods to do its work. This is
the method your tag generator - for example, C<ptags> - will call.

=head2 setup_fake_package

If you use C<--use> and the packages load modules which can't be loaded easily
in the context of L<Vim::Tag> or which have some side-effects, you can act as
though that module has already been loaded.

This method takes a list of package names and changes C<@INC> for each one.

It's not used directly in this class or in C<ptags>, but if you write a custom
tags generator you might need to use it.

=head2 write_tags

Writes the generated tags to the file determined by C<--out> in a
format C<vim> can understand.

=head1 PLANS

=over 4

=item * C<ptags> only has one global tags file and generates everything every
time it is run. This is especially a problem if you have various perl
installations, for example, using C<perlbrew>: Every time you switch between
perl installations you'd have to re-run C<ptags> to keep it up-to-date.

=back

=head1 SEE ALSO

L<Bash::Completion::Plugins::VimTag>

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Vim-Tag>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Vim-Tag/>.

The development version lives at L<http://github.com/hanekomu/Vim-Tag>
and may be cloned from L<git://github.com/hanekomu/Vim-Tag.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

