package Mojo::Debugbar::Monitors;
use Mojo::Base -base;

use Mojo::Util qw(md5_sum);
use Time::HiRes qw(time);

has 'css' => <<'EOF'
<style type="text/css">
#debugbar-push {
    height: 39px;
}
#debugbar {
    position: fixed;
    right: 0;
    bottom: 0;
    left: 0;

    background-color: #fff;
}
#debugbar .debugbar-header {
    background-color: #f5f5f5;
}
#debugbar .debugbar-header .debugbar-brand {
    position: absolute;
    top: 0;
    padding: 9px;
    border-right: 1px solid #ddd;
}
#debugbar .debugbar-header .nav-tabs {
    margin-left: 45px;
    margin-bottom: 0;
}
#debugbar .debugbar-header .nav-tabs .active a {
    color: #fff;
    background-color: #f4645f;
}
#debugbar .debugbar-header .debugbar-actions {
    position: absolute;
    top: 10px;
    right: 15px;
}
#debugbar .debugbar-header .debugbar-actions .minimize-debugbar {
    display: none;
}
#debugbar .debugbar-content {
    display: none;
    padding: 0 5px;
    height: 250px;
    overflow-y: auto;
}
#debugbar-push.open {
    height: 289px;
}
#debugbar.open .debugbar-content {
    display: block;
}
#debugbar.open .debugbar-header .debugbar-actions .minimize-debugbar {
    display: inline;
}
</style>
EOF
;
has 'javascript' => <<'EOF'
<script type="text/javascript">
jQuery(document).ready(function($) {
    $('#debugbar [data-toggle="tab"]').on('click', function(e) {
        $('#debugbar-push').addClass('open');
        $('#debugbar').addClass('open');
    });

    $('.debugbar-actions .minimize-debugbar').on('click', function(e) {
        e.preventDefault();

        $('#debugbar-push').removeClass('open');
        $('#debugbar').removeClass('open');
        $('#debugbar').find('.nav-tabs .active').removeClass('active');
        $('#debugbar').find('.tab-content .active').removeClass('active');
    });
});
</script>
EOF
;
has 'registered' => sub { [] };
has 'hide_empty' => 0;
has 'started_at' => sub { time() };
has 'ended_at' => sub { time() };

=head2 duration
    Ended at - started at
=cut

sub duration {
    my $self = shift;

    return sprintf("%.4f", $self->ended_at - $self->started_at);
}

=head2 render
    Loops through each monitor and renders the html
=cut

sub render {
    my $self = shift;

    my $tabs = '';
    my $content = '';

    foreach my $monitor (@{ $self->registered }) {
        my $count = $monitor->count;

        next if ($self->hide_empty && !$count);

        my $id = md5_sum(ref($monitor));

        $tabs .= sprintf('<li><a href="#%s" data-toggle="tab">%s %s (%s)</a></li>', $id, $monitor->icon, $monitor->name, $count);
        
        $content .= sprintf('<div class="tab-pane" id="%s">%s</div>', $id, $monitor->render);
    }

    return sprintf(
        '%s
        <div id="debugbar-push"></div>
        <div id="debugbar">
            <div class="debugbar-header">
                <div class="debugbar-brand">
                    <i class="icon-cubes"></i>
                </div>
                <ul class="nav nav-tabs">%s</ul>
                <div class="debugbar-actions">
                    <!--<span><i class=" icon-clock"></i>%ss</span> | -->
                    
                    <a href="#" class="minimize-debugbar" title="Minimize debugbar"><i class="icon-down-open"></i></a>
                </div>
            </div>
            <div class="debugbar-content">
                <div class="tab-content">%s</div>
            </div>
        </div>
        %s',
        $self->css, $tabs, $self->duration, $content, $self->javascript
    );
}

=head2 stop
    Loops through each monitor and calls stop then stops the timer
=cut

sub stop {
    my $self = shift;

    $_->stop for @{ $self->registered };

    $self->ended_at(time());
}

=head2 start
    Starts the timer and loops through each monitor and calls start
=cut

sub start {
    my $self = shift;

    $self->started_at(time());

    $_->start for @{ $self->registered };
}

1;
