package Tickit::Widget::LogAny;
# ABSTRACT: display log output in a Tickit window
use strict;
use warnings;

use parent qw(Tickit::ContainerWidget);

our $VERSION = '0.005';

=head1 NAME

Tickit::Widget::LogAny - log message rendering

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 #!/usr/bin/env perl
 use strict;
 use warnings;
 
 use Tickit;
 use Tickit::Widget::LogAny;
 use Log::Any qw($log);
 
 my $tickit = Tickit->new(
 	root => Tickit::Widget::LogAny->new(
 		stderr => 1,
 	)
 );
 print STDERR "print to STDERR\n";
 printf STDERR "printf(...) to %s", 'STDERR';
 warn "a warning\n";
 warn "a warning with no \\n";
 $log->trace('trace message');
 $log->info('info message');
 $log->debug('debug message');
 $log->notice('notice message');
 $log->warn('warn message');
 $log->error('error message');
 $log->critical('critical message');
 $tickit->run;

=head1 DESCRIPTION

Provides basic log rendering, with optional C<warn> / C<STDERR> capture.

=begin HTML

<p>Basic rendering:</p>
<p><img src="http://tickit.perlsite.co.uk/cpan-screenshot/tickit-widget-logany-basic.png" alt="Log::Any output displayed in Tickit widget" width="663" height="208"></p>
<p>Stack trace popup:</p>
<p><img src="http://tickit.perlsite.co.uk/cpan-screenshot/tickit-widget-logany-stacktrace.png" alt="Log message with stack trace popup display using Tickit desktop layout" width="675" height="362"></p>

=end HTML

Activating any line in the list of log messages (typically by pressing C<Enter>) will
show the stack trace for that entry. Use the OK button to close (typically by pressing
C<Tab>, then C<Enter>).

=cut

use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Any::Adapter::Tickit;
use Log::Any::Adapter::Util ();

use Variable::Disposition qw(dispose retain retain_future);
use POSIX qw(strftime);
use Text::Wrap (); 

use Syntax::Keyword::Try;

use Tickit::Utils qw(textwidth substrwidth);
use Tickit::Style;
use Tickit::Widget::Table;
use Tickit::Widget::VBox;
use Tickit::Widget::Static;
use Tickit::Widget::Frame;
use Tickit::Widget::Button;

use constant WIDGET_PEN_FROM_STYLE => 1;

BEGIN {
	style_definition base =>
		date_fg               => 'white',
		date_sep_fg           => 'white',
		time_fg               => 6,
		time_sep_fg           => 'white',
		ms_fg                 => 6,
		ms_sep_fg             => 'white',
		severity_emergency_fg => 'hi-red',
		severity_alert_fg     => 'hi-red',
		severity_critical_fg  => 'hi-red',
		severity_error_fg     => 'hi-red',
		severity_warning_fg   => 'red',
		severity_notice_fg    => 'green',
		severity_info_fg      => 'green',
		severity_debug_fg     => 'grey',
		severity_trace_fg     => 'grey',
		subname_fg            => 'hi-blue',
		subname_b             => 1,
		;
}

=head1 METHODS

=cut

sub lines { 1 }
sub cols  { 1 }

=head2 new

Takes the following named parameters:

=over 4

=item * warn - if true, will install a handler for warn()

=item * stderr - if true, will install a handler for all STDERR output

=item * scroll - if true (default), will attempt to scroll the window on new entries

=item * max_entries - will limit the number of entries we'll store, default is 5000, set to 0 for no limit

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $log_storage = Adapter::Async::OrderedList::Array->new;
	Log::Any::Adapter->set('Tickit', adapter => $log_storage);

	my $max_entries = delete($args{max_entries}) // 5000;
	my $io_async = delete $args{io_async};
	my $lines = delete $args{lines};
	my $warn = delete $args{warn};
	my $stderr = delete $args{stderr};
	my $scroll = exists $args{scroll} ? delete $args{scroll} : 1;
	my $self = $class->SUPER::new(%args);
	$log_storage->bus->subscribe_to_event(
		splice => $self->curry::weak::on_splice,
	);
	$self->{log_storage} = $log_storage;
	$self->{lines} = $lines if $lines;
	$self->{scroll} = $scroll;
	$self->{log} = [];

	$self->{table} = Tickit::Widget::Table->new(
		class   => 'log_entries',
		adapter => $self->log_storage,
		on_activate => $self->curry::weak::show_stacktrace,
		failure_transformations => [
			sub { '' }
		],
		columns => [ {
			label => 'Timestamp',
			width => 23,
			transform => sub {
				my ($row, $col, $cell) = @_;
				return Future->done('') unless defined $cell && length $cell;
				my @date = $self->get_style_pen('date')->getattrs;
				my @date_sep = $self->get_style_pen('date_sep')->getattrs;
				my @time = $self->get_style_pen('time')->getattrs;
				my @time_sep = $self->get_style_pen('time_sep')->getattrs;
				my @ms = $self->get_style_pen('ms')->getattrs;
				my @ms_sep = $self->get_style_pen('ms_sep')->getattrs;
				Future->done(
					String::Tagged->new(
						sprintf '%s.%03d', strftime('%Y-%m-%d %H:%M:%S', localtime $cell), 1000 * ($cell - int($cell))
					)
					->apply_tag( 0, 4, @date)
					->apply_tag( 4, 1, @date_sep)
					->apply_tag( 5, 2, @date)
					->apply_tag( 7, 1, @date_sep)
					->apply_tag( 8, 2, @date)
					->apply_tag(11, 2, @time)
					->apply_tag(13, 1, @time_sep)
					->apply_tag(14, 2, @time)
					->apply_tag(16, 1, @time_sep)
					->apply_tag(17, 2, @time)
					->apply_tag(19, 1, @ms_sep)
					->apply_tag(20, 3, @ms)
				)
			}
		}, {
			label => 'Severity',
			width => 9,
			transform => sub {
				my ($row, $col, $cell) = @_;
				$self->{severity_style}{$cell} // Future->done('')
			}
		}, {
			label => 'Category',
			width => 24
		}, {
			label => 'Message'
		} ],
		item_transformations => [
			sub {
				my ($idx, $item) = @_;
				Future->done([ map $_ // '', @{$item}{qw(timestamp severity category message)} ])
			}
		]
	);
	$log->debug("Created table");

	# Take over warn statements if requested
	$SIG{__WARN__} = sub {
		my ($txt) = @_;
		s/\v+//g for $txt;
		$log->warn($txt)
	} if $warn;

	if($stderr) {
		require Tie::Tickit::LogAny::STDERR;
		tie *STDERR, 'Tie::Tickit::LogAny::STDERR';
	}

	# Just handled via STDERR for now
#	if($io_async) {
#		require IO::Async::Notifier;
#		open $IO::Async::Notifier::DEBUG_FD, '>', \my $str or die $!;
#
#	}
	$self;
}

sub update_severity_styles {
	my ($self) = @_;
	my %severity;
	for my $severity (Log::Any::Adapter::Util::logging_methods) {
		my @style = $self->get_style_pen('severity_' . $severity)->getattrs;
		die "Bad style - $severity ($@)" unless @style;
		$severity{$severity} = 
			Future->done(
				String::Tagged->new(
					$severity
				)
				->apply_tag( 0, -1, @style)
			);
	}
	$self->{severity_style} = \%severity;
	$self
}

sub on_splice {
	my ($self, $ev, $idx, $len, $data, $spliced) = @_;
	return unless $self->max_entries;
	retain_future(
		$self->log_storage->count->then(sub {
			my ($rows) = @_;
			my $len = $rows - $self->max_entries;
			return Future->done if $len <= 0;
			$self->log_storage->splice(
				0, $len, []
			)
		})
	)
}

sub max_entries { shift->{max_entries} }

sub log_storage { shift->{log_storage} }

sub window_gained {
	my ($self, $win) = @_;
	$self->SUPER::window_gained($win);
	$self->update_severity_styles;
	my $child = $win->make_sub(
		1, 0, $win->lines, $win->cols
	);
	$self->{table}->set_window($child);
}

sub children { shift->{table} }

sub render_to_rb {
	my ($self, $rb, $rect) = @_;
	my $win = $self->window or return;
	$rb->clear;
	$rb->text_at(0,0, "Level: all   Category: all   Filter: ", $self->get_style_pen);
}

sub show_stacktrace {
	my ($self, $id, $items) = @_;

	my ($item) = @$items;
	my ($holder, $cleanup) = $self->stacktrace_holder_widget;

	{
		local $Text::Wrap::columns = $holder->window->cols;
		my @text = map { split /\n/, $_ } Text::Wrap::wrap('', '', $item->{message});
		$holder->add(Tickit::Widget::Static->new(text => $_)) for @text;
	}

	my $tbl;
	$tbl = Tickit::Widget::Table->new(
		columns => [
			{ label => 'Location', transform => sub {
				my ($row, $col, $cell) = @_;
				$cell =~ s{^\Q$_/}{} for @INC;
				Future->done($cell)
			} },
			{ label => 'Context', width => 8 },
			{ label => 'Sub', transform => sub {
				my ($row, $col, $cell) = @_;
				my $w = $tbl->column_width($col) - textwidth($cell);
				$cell = '...' . substrwidth($cell, 3-$w) if $w < 0;
				my $pos = rindex($cell, '::') or return Future->done($cell);
				Future->done(
					String::Tagged->new(
						$cell
					)->apply_tag(
						$pos + 2, -1, $self->get_style_pen('subname')->getattrs
					)
				)
			} },
		],
		failure_transformations => [
			sub { '' }
		],
		item_transformations => [
			sub {
				my ($idx, $item) = @_;
				Future->done([
					$item->{filename} . ':' . $item->{line},
					@{$item}{qw(ctx sub)}
				])
			}
		]
	);
	$tbl->adapter->push(map $_->{stack}, @$items);
	$holder->add($tbl, expand => 1);
	my $win = $self->window;
	$holder->add(
		Tickit::Widget::Button->new(
			class => 'stacktrace_ok',
			style => { linetype => 'none' },
			label => 'OK',
			on_click => sub {
				eval {
					$cleanup->();
					1
				} or warn "Failed to do cleanup - $@";

				$win->close;
				$win->tickit->later(sub {
					try {
						dispose $holder;
					} catch {
						warn "Failed to dispose vbox - $@";
					}
				});
			}
		)
	);
	retain $holder;
}

sub stacktrace_holder_widget {
	my ($self, $code) = @_;
	my $container = $self;
	$container = $container->parent while !$container->isa('Tickit::Widget::FloatBox') && !$container->isa('Tickit::Widget::Layout::Desktop') && $container->can('parent') && $container->parent;
	$container = $self unless $container;

	my $cleanup = sub { ... };
	retain(my $vbox = Tickit::Widget::VBox->new(style => { spacing => 1 }));
	my $win = $self->window;
	if($container->isa('Tickit::Widget::FloatBox')) {
		$container->add_float(
			child => $vbox
		)
	} elsif($container->isa('Tickit::Widget::Layout::Desktop')) {
		my $panel = $container->create_panel(
			label => 'Stack trace',
			lines => 20,
			cols  => 60,
			top   => 5,
			left  => 5,
		);
		$panel->add($vbox);
		$cleanup = sub {
			$panel->close;
			$win->tickit->later(sub {
				try {
					dispose $vbox;
					dispose $panel;
				} catch {
					warn "Failed - $@";
				}
			});
			$win->expose;
		};
	} else {
		# We don't have any suitable float holders, so we'll just overlay this
		# using our window as a parent. This next set of measurements assumes we
		# have a bit of space to play with - if we don't, I'm not sure how best
		# to handle this: use the root window instead, or just bail out?
		my $float = $win->make_float(
			2,
			2,
			$win->lines - 4,
			$win->cols - 4
		);
		# Need to hold on to the top widget in the new hierarchy
		retain(my $frame = Tickit::Widget::Frame->new(
			child => $vbox,
			title => 'Stack trace',
			style => { linetype => 'single' }
		));

		$frame->set_window($float);
		$float->show;

		# We're responsible for disposing the $frame object, since we retained
		# it earlier.
		$cleanup = sub {
			$frame->set_window(undef);
			$float->close;
			$win->tickit->later(sub {
				try {
					dispose $frame;
					dispose $vbox;
				} catch {
					warn "Failed to dispose frame - $@";
				}
				$win->expose;
			})
		};
	}
	return $vbox, $cleanup;
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Log::Any>

=item * L<Log::Any::Adapter::Tickit>

=item * L<Tie::Tickit::STDERR>

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2014-2015. Licensed under the same terms as Perl itself.
