package XT::Manager::API;

use strict;

BEGIN {
	$XT::Manager::API::AUTHORITY = 'cpan:TOBYINK';
	$XT::Manager::API::VERSION   = '0.006';
};

BEGIN {
	package XT::Manager::API::Types;
	no thanks;
	use Path::Tiny ();
	use Type::Library -base,
		-declare => qw( Path AbsPath File AbsFile Dir AbsDir XtTest XtTestSet XtComparison );
	use Type::Utils;
	use Types::Standard qw( Str ArrayRef );
	use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
	
	class_type Path, { class => "Path::Tiny" };
	
	declare AbsPath,
		as Path, where { $_->is_absolute },
		inline_as { $_[0]->parent->inline_check($_) . "&& ${_}->is_absolute" },
		message {
			is_Path($_) ? "Path '$_' is not absolute" : Path->get_message($_);
		};
	
	declare File,
		as Path, where { $_->is_file },
		inline_as { $_[0]->parent->inline_check($_) . "&& (-f $_)" },
		message {
			is_Path($_) ? "File '$_' does not exist" : Path->get_message($_);
		};
	
	declare Dir,
		as Path, where { $_->is_dir },
		inline_as { $_[0]->parent->inline_check($_) . "&& (-d $_)" },
		message {
			is_Path($_) ? "Directory '$_' does not exist" : Path->get_message($_);
		};
	
	declare AbsFile,
		as intersection([AbsPath, File]),
		message {
			is_AbsPath($_) ? File->get_message($_) : AbsPath->get_message($_);
		};
	
	declare AbsDir,
		as intersection([AbsPath, Dir]),
		message {
			is_AbsPath($_) ? Dir->get_message($_) : AbsPath->get_message($_);
		};
	
	for my $type ( Path, File, Dir ) {
		coerce(
			$type,
			from Str()        => q{ Path::Tiny::path($_) },
			from Stringable() => q{ Path::Tiny::path($_) },
			from ArrayRef()   => q{ Path::Tiny::path(@$_) },
		);
	}
	
	for my $type ( AbsPath, AbsFile, AbsDir ) {
		coerce(
			$type,
			from Path         => q{ $_->absolute },
			from Str()        => q{ Path::Tiny::path($_)->absolute },
			from Stringable() => q{ Path::Tiny::path($_)->absolute },
			from ArrayRef()   => q{ Path::Tiny::path(@$_)->absolute },
		);
	}
	
	class_type XtTest,       { class => "XT::Manager::Test" };
	class_type XtTestSet,    { class => "XT::Manager::TestSet" };
	class_type XtComparison, { class => "XT::Manager::Comparison" };
};

BEGIN {
	package XT::Manager::API::Syntax;
	no thanks;
	use Moo ();
	use Moo::Role ();
	use Import::Into ();
	use Syntax::Collector -collect => q{
		use Types::Standard 0 -types;
		use XT::Manager::API::Types 0 -types;
		use match::smart 0.004 qw(M);
		use constant 0 { true => !!1, false => !!0 };
		use constant 0 { read_only => 'ro', read_write => 'rw', lazy_build => 'lazy' };
		no thanks 0.001;
		use strict 0;
		use warnings 0;
	};
	sub _exporter_validate_opts
	{
		my $me     = shift;
		my ($opts) = @_;
		'Moo::Role'->import::into($opts->{into}) if $opts->{role};
		'Moo'->import::into($opts->{into}) if $opts->{class};
		$me->SUPER::_exporter_validate_opts(@_);
	}
}

BEGIN {
	package XT::Manager::Exception::FileNotFound;
	use XT::Manager::API::Syntax -class;
	with qw(Throwable)
};

BEGIN {
	package XT::Manager::Test;
	use XT::Manager::API::Syntax -class;
	
	has t_file => (
		is       => read_only,
		isa      => File,
		required => true,
		coerce   => File->coercion,
		handles  => { name => "basename" },
	);
	
	has config_file => (
		is         => lazy_build,
		isa        => File,
		required   => false,
		coerce     => File->coercion,
		predicate  => "has_config_file",
	);
	
	sub BUILDARGS
	{
		my $class  = shift;
		my $params = $class->SUPER::BUILDARGS(@_);
		delete $params->{config_file} unless defined $params->{config_file};
		return $params;
	}
	
	sub _build_file
	{
		my ($self, $extension) = @_;
		my $abs = $self->t_file->absolute;
		$abs =~ s/\.\Kt$/$extension/;
		return unless -f $abs;
		return $abs;
	}
	
	sub _build_config_file
	{
		shift->_build_file('config');
	}
};

BEGIN {
	package XT::Manager::TestSet;
	use XT::Manager::API::Syntax -role;
	
	requires qw(
		add_test
		remove_test
		_build_tests
		_build_disposable_config_files
	);
	
	has tests => (
		is         => lazy_build,
		isa        => ArrayRef[XtTest],
		predicate  => "has_tests",
	);
	
	has disposable_config_files => (
		is         => lazy_build,
		isa        => Bool,
		predicate  => "has_disposable_config_files",
	);
	
	sub is_ignored { +return }
	
	sub test
	{
		my ($self, $name) = @_;
		my @results = grep { $_->name eq $name } @{ $self->tests };
		wantarray ? @results : $results[0];
	}
};

BEGIN {
	package XT::Manager::FileSystemTestSet;
	use XT::Manager::API::Syntax -role;
	with qw(XT::Manager::TestSet);
	
	has dir => (
		is       => read_only,
		isa      => Dir,
		required => true,
		coerce   => Dir->coercion,
	);
	
	sub _build_tests
	{
		my $self = shift;
		$self->dir->mkpath unless -d $self->dir;
		
		[
			map  { XtTest->new(t_file => $_) }
			grep { !$_->is_dir and $_ =~ /\.t$/ }
			$self->dir->children
		]
	}
	
	sub _build_disposable_config_files { true }
	
	sub compare
	{
		my ($self, $other) = @_;
		my %results;
		foreach my $t (@{ $self->tests })
		{
			$results{ $t->name }{L} = [ $t->t_file->stat->mtime ];
		}
		foreach my $t (@{ $other->tests })
		{
			$results{ $t->name }{R} = [ $t->t_file->stat->mtime ];
		}
		
		XtComparison->new(
			left  => $self,
			right => $other,
			data  => \%results,
		);
	}
	
	sub add_test
	{
		my ($self, $t) = @_;
		my $o = $t;
		$t = $self->test($t) unless ref $t;
		
		"XT::Manager::Exception::FileNotFound"->throw(
			message => "$o not found in ".$self->dir
		) unless ref $t;
		
		my $dir = $self->dir;
		my ($t_file, $config_file);
		my $dump = sub {
			my ($old, $new) = @_;
			my $fh = $new->openw;
			print $fh $old->slurp;
			close $fh;
			utime $old->stat->mtime, $old->stat->mtime, "$new";
		};
		
		$t_file = File->coercion->([ "$dir", $t->t_file->basename ]);
		$dump->($t->t_file, $t_file);
		
		if ($t->has_config_file)
		{
			$config_file = File->coercion->([ "$dir", $t->config_file->basename ]);
			$dump->($t->config_file, $config_file) if $self->disposable_config_files || !(-e $config_file);
		}
		
		my $object = XtTest->new(
			t_file      => $t_file,
			config_file => $config_file,
		);
		push @{ $self->tests }, $object;
		
		return $object;
	}
	
	sub remove_test
	{
		my ($self, $t) = @_;
		my $o = $t;
		$t = $self->test($t) unless ref $t;
		
		"XT::Manager::Exception::FileNotFound"->throw(
			"$o not found in ".$self->dir
		) unless ref $t;
		
		$t->t_file->remove;
		if ($t->has_config_file)
		{
			$t->config_file->remove if $self->disposable_config_files || !(-e $t->config_file);
		}
		
		$self->tests([ grep { $_->name ne $t->name } @{ $self->tests } ]);
		return $self;
	}
};

BEGIN {
	package XT::Manager::Repository;
	use XT::Manager::API::Syntax -class;
	with qw(XT::Manager::FileSystemTestSet);
}

BEGIN {
	package XT::Manager::XTdir;
	use XT::Manager::API::Syntax -class;
	with qw(XT::Manager::FileSystemTestSet);
	
	has ignore_list => (
		is         => lazy_build,
		isa        => Any,
		predicate  => "has_ignore_list",
	);
	
	sub _build_disposable_config_files { false }
	
	sub _build_ignore_list
	{
		my $self = shift;
		$self->dir->mkpath unless -d $self->dir;
		
		my $file  = File->coercion->([ $self->dir, '.xt-ignore' ]);
		return unless -f "$file";
		my @ignore =
			map { qr{$_} }
			map { chomp; $_ }
			$file->slurp;
		return \@ignore;
	}
	
	sub is_ignored
	{
		my ($self, $name) = @_;
		return true if $name |M| $self->ignore_list;
		return;
	}
	
	sub add_ignore
	{
		my ($self, $string) = @_;
		$self->dir->mkpath unless -d $self->dir;
		
		my $file  = File->coercion->([ $self->dir, '.xt-ignore' ]);
		open my $fh, '>>', "$file";
		print $fh quotemeta($string);
		close $fh;
		push @{ $self->ignore_list }, qr{ \Q $string \E }x;
	}
};

BEGIN {
	package XT::Manager::Comparison;
	use XT::Manager::API::Syntax -class;
	
	use constant {
		LEFT_ONLY     => '+   ',
		RIGHT_ONLY    => '  ? ',
		LEFT_NEWER    => 'U   ',
		RIGHT_NEWER   => '  M ',
	};
	
	has data => (
		is       => read_only,
		isa      => HashRef,
		required => true,
	);
	
	has [qw/left right/] => (
		is       => read_only,
		does     => XtTestSet,
		required => true,
	);
	
	sub test_names
	{
		my $self = shift;
		sort keys %{ $self->data };
	}
	
	sub left_has
	{
		my ($self, $name) = @_;
		return $self->data->{$name}{L};
	}
	
	sub right_has
	{
		my ($self, $name) = @_;
		return $self->data->{$name}{R};
	}
	
	sub status
	{
		my ($self, $name) = @_;
		my $L = $self->left_has($name);
		my $R = $self->right_has($name);
		
		return LEFT_ONLY   if (  $L and !$R );
		return RIGHT_ONLY  if ( !$L and  $R );
		return LEFT_NEWER  if (  $L and  $R  and $L->[0] > $R->[0] );
		return RIGHT_NEWER if (  $L and  $R  and $L->[0] < $R->[0] );
		return;
	}
	
	sub show
	{
		my ($self, $verbose) = @_;
		
		my $str = '';
		foreach my $t ($self->test_names)
		{
			next if $self->right->is_ignored($t);
			
			my $status = $self->status($t);
			if (defined $status and length $status)
			{
				$str .= sprintf("%s  %s\n", $status, $t);
			}
			elsif ($verbose)
			{
				$str .= "      $t\n";
			}
		}
		return $str;
	}
	
	sub should_pull
	{
		my $self = shift;
		grep
		{
			my $f = $_;
			if ($self->right->is_ignored($f))
			{
				0;
			}
			else
			{
				my $st = $self->status($f);
				$st = "" unless defined $st;
				$st eq LEFT_ONLY || $st eq LEFT_NEWER;
			}
		} $self->test_names;
	}
};

__FILE__
__END__

=pod

=encoding utf-8

=for stopwords XT xt

=head1 NAME

XT::Manager::API - this is the interface you want to use for scripting XT::Manager

=head1 DESCRIPTION

Currently this is not documented, and subject to change in backwards
incompatible ways without notice.

This module defines the following classes:

=over

=item * C<< XT::Manager::Test >> - a single test file

=item * C<< XT::Manager::Repository >> - a repository of test files

=item * C<< XT::Manager::XTdir >> - an "xt" directory

=item * C<< XT::Manager::Comparison >> - the result of comparing two TestSet objects

=back

And a bunch of Moo roles.

The source code of the C<< XT::Manager::Command::* >> modules are fairly
good examples of how these classes can be used.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=XT-Manager>.

=head1 SEE ALSO

L<XT::Manager>, L<XT::Util>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

