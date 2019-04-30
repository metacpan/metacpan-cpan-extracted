/*
 * This software is Copyright (c) 2015, 2019 by Ashley Willis.
 * This is free software, licensed under:
 *   The Apache License, Version 2.0, January 2004
 */

// underscores because copied from custom.js
var _limit = 99;
var _kcounter = new Array();

function myInnerHTML(key, index) {
    var html = '';
    if (key == 'queues')
        html = '<td><input type="text" name="queues[' + index + ']" size="20" value="" class="queues"/></td><td>even higher priority</td>';
    if (key == 'max_tasks')
        html = '<td><select name="max_tasks[' + index + '][dow]">' +
                '<option value=""></option>' +
                '<option value="*">Daily</option>' +
                '<option value="0">Sun</option>' +
                '<option value="1">Mon</option>' +
                '<option value="2">Tue</option>' +
                '<option value="3">Wed</option>' +
                '<option value="4">Thu</option>' +
                '<option value="5">Fri</option>' +
                '<option value="6">Sat</option>' +
                '</select></td>' +
                '<td><input type="text" name="max_tasks[' + index + '][time]" size="5" value="" class="time"/></td>' +
                '<td><input type="text" name="max_tasks[' + index + '][size]" size="2" value="" class="int"/></td>';
    return html;
}

function _addKeyInput(key,max) {
    _kcounter[key] = _kcounter[key] ? _kcounter[key] : 0;
    max = max ? max : _limit;
    if (_kcounter[key] == max - 1)  {
        alert("You have reached the limit of adding " + max + " inputs to " + key);
    }
    else {
        _kcounter[key] = _kcounter[key] + 1;
        var tr = document.createElement('tr');
        tr.setAttribute('id', key + '[' + _kcounter[key] + ']');
        tr.innerHTML = myInnerHTML(key, _kcounter[key]);
        document.getElementById(key).appendChild(tr);
    }
}

function _removeKeyInput(key) {
    if (_kcounter[key] == 0)
        return;
    var parent = document.getElementById(key);
    var child = document.getElementById(key + '[' + _kcounter[key] + ']');
    parent.removeChild(child);
    _kcounter[key] = _kcounter[key] - 1;
}



var validateTime = function(o) {
    $(o).val( jQuery.trim($(o).val()) );
    if ( $(o).val() && ! $(o).val().match(/^(?:[01]\d|2[0-3]):[0-5]\d$/) ) {
        $('#i_error').text('Invalid time: "' + $(o).val() + '"\nUse 24-hour time: HH:MM');
        $(o).css({'background-color': '#FFE0E0'});
        return false;
    }
    $('#i_error').text('');
    $(o).css({'background-color': 'white'});
    return true;
};

var validateInt = function(o) {
    $(o).val( jQuery.trim($(o).val()) );
    if ( $(o).val() && ! $(o).val().match(/^\d+$/) ) {
        $('#i_error').text('Not an integer: "' + $(o).val() + '"');
        $(o).css({'background-color': '#FFE0E0'});
        return false;
    }
    $('#i_error').text('');
    $(o).css({'background-color': 'white'});
    return true;
};

var validateQueues = function(o) {
    $(o).val( jQuery.trim($(o).val()) );
    $(o).val( $(o).val().replace(/,\s+/g, ',') );
    if ( $(o).val() ) {
        if (! $(o).val().match(/^\w+(?:,\w+)*$/) ) {
            $('#q_error').text('Invalid queue list: "' + $(o).val() + '"');
            $(o).css({'background-color': '#FFE0E0'});
            return false;
        }
        var queues = $(o).val().split(',');
        for (var i = 0; i < queues.length; i++) {
            if (known_queues.indexOf(queues[i]) == -1) {
                $('#q_error').text('Invalid queue name: "' + queues[i] + '"');
                $(o).css({'background-color': '#FFE0E0'});
                return false;
            }
        }
    }
    $('#q_error').text('');
    $(o).css({'background-color': 'white'});
    return true;
}

$(document).ready(function() {
    $('.time').each(function() { validateTime(this); });
    $('.int').each(function() { validateInt(this); });
    $('.queues').each(function() { validateQueues(this); });
});

$(':submit').live("click", function() {
    submitName = $(this).val();
});


$(function() {

    $('.time').change(function() { validateTime(this) });
    $('.int').change(function() { validateInt(this) });
    $('.queues').change(function() { validateQueues(this) });

    $('form').submit(function() {

        // basic form validation:
        var invalid = false;
        $('.time').each(function() { if (!validateTime(this)) invalid = true });
        $('.int').each(function() { if (!validateInt(this)) invalid = true });
        $('.queues').each(function() { if (!validateQueues(this)) invalid = true });
        if (invalid) {
            $('#error').text('errors found');
            $('#result').text('');
            return false;
        }

        // turn form into json:
        var form = $('form').serializeObject();
        var json = { 'max_tasks' : {}, 'queues': [] };

        // error if disable and re-enable
        if (form.disable != '' && typeof(form.reenable) !== 'undefined') {
            $('#error').text('can\'t set both disable time and re-enable together');
            $('#result').text('');
            return false;
        }

        if (form.disable != '') {
            json.disabled = Math.round(form.disable * 60 + Date.now() / 1000);
        } else if ( typeof(form.reenable) !== 'undefined' ) {
            json.disabled = null;
        }

        // create json.queues:
        var allQueues = [];
        $.each(form.queues, function(i, queues) {
            if (queues != '') {
                var arr = queues.split(',');
                json.queues.push(arr);
                allQueues = allQueues.concat(arr);
            }
        });

        // find duplicate queues:
        var dups = [];
        for (var i = 0; i < allQueues.sort().length - 1; i++) {
            if (allQueues[i + 1] == allQueues[i]) {
                dups.push(allQueues[i]);
            }
        }

        // error if duplicate queues:
        if (dups.length != 0) {
            $('#error').text('duplicate queue names: ' + dups);
            $('#result').text('');
            $('.queues').each(function() {
                if ($(this).val()) {
                    for (var i = 0; i < dups.length; i++) {
                        var rx = new RegExp('^' + dups[i] + '(?:,|$)' + '|' + '(?:^|,)' + dups[i] + '$');
                        if ($(this).val().match(rx)) {
                            $(this).css({'background-color': '#FFE0E0'});
                        }
                    }
                }
            });
            return false;
        }

        // create json.max_tasks:
        var incomplete = false;
        $.each(form.max_tasks, function(i, hash) {
            if (hash.time == '' && hash.dow == '' && hash.size == '') {
                return;
            }
            if (hash.time == '' || hash.dow == '' || hash.size == '') {
                $('input[name^="max_tasks['+i+']"]').css({'background-color': '#FFE0E0'});
                $('#error').text('fields left blank for interval(s)');
                incomplete = true;
                return;
            } else if (json.max_tasks[hash.dow + ' ' + hash.time]) {
                // TODO: also set color for first instance of dup
                $('input[name="max_tasks['+i+'][time]"]').css({'background-color': '#FFE0E0'});
                incomplete = true;
                $('#error').text('dow+time duplicated for intervals');
                return;
            } else {
                json.max_tasks[hash.dow + ' ' + hash.time] = hash.size;
            }
        });
        if (incomplete) {
            $('#result').text('');
            return false;
        }

        $('#error').text('');
        $('#result').text(JSON.stringify(json, null, '  '));
        if (submitName == 'test')
            return false;

        $.ajax({
            type: "POST",
            data: JSON.stringify(json),
            contentType: 'application/json',
            cache: false,
            success: function(data, textStatus, obj) {
                //alert(JSON.stringify(data) + '\n' + textStatus + '\n' + obj.status +  ' ' + obj.responseText);
                location.reload();
            },
            error: function(obj, textStatus, error) { alert(obj + '\n***********\n' + textStatus + '\n*************\n' + error) } // obj is XMLHttpRequest ?
        });
        return false;

    });

});
