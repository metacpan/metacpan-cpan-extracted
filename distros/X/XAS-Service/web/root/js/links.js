$(document).ready(function() {

    $('.action_delete').click(function(element) {
        $.ajax({
            type: 'DELETE',
            url: element.target,
            contentType: 'text/html',
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.action_start').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'start' }
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.action_resume').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'resume' }
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.action_pause').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'pause' }
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.action_stop').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'stop' },
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.action_kill').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'kill' }
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

});

