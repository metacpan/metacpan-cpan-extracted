/*
 * This software is Copyright (c) 2015, 2019 by Ashley Willis.
 * This is free software, licensed under:
 *   The Apache License, Version 2.0, January 2004
 */

var icounter = 1;
var limit = 99;
function addInput(divName){
    if (icounter == limit)  {
        alert("You have reached the limit of adding " + icounter + " inputs");
    }
    else {
        icounter++;
        var tr1 = document.createElement('tr');
        tr1.innerHTML = "<td> Contacts " + icounter +
                ": </td> <td> <input type='text' name='contacts' /> </td>";
        document.getElementById(divName).appendChild(tr1);

        var tr2 = document.createElement('tr');
        tr2.innerHTML = "<td> Description " + icounter +
                " : </td> <td> <input type='text' name='contacts_desc' value='Contacts " +
                icounter + "'> </td>";
        document.getElementById(divName).appendChild(tr2);
    }
}

var bcounter = 1;
function addBody(tableName){
    bcounter++;
    var tbody = document.createElement('tbody');
    tbody.setAttribute('id', 'contacts' + bcounter);
    tbody.innerHTML = "<tr> <td> Contacts " + bcounter +
            ": </td> <td> <input type='text' name='contacts' /> </td> </tr>";
    tbody.innerHTML += "<tr> <td> Description " + bcounter +
            " : </td> <td> <input type='text' name='contacts_desc' value='Contacts " +
            bcounter + "'> </td> </tr>";
    document.getElementById(tableName).appendChild(tbody);
}

var kcounter = new Array();
function addKeyInput(key,max) {
    kcounter[key] = kcounter[key] ? kcounter[key] : 1;
    max = max ? max : limit;
    if (kcounter[key] == max)  {
        alert("You have reached the limit of adding " + kcounter[key] + " inputs");
    }
    else {
        kcounter[key] = kcounter[key] + 1;
        var tr = document.createElement('tr');
        tr.setAttribute('id', key + kcounter[key]);
        tr.innerHTML = '<td /> <td> <input type="text" name="' + key + '" /> </td>';
        if (kcounter[key] == 2) {
            tr.innerHTML += '<td /> <td> <input id="remove_' + key + '" type="button" value="Remove last field" onClick="removeKeyInput(\'' + key + '\');" /> </td>';
        }
        document.getElementById(key).appendChild(tr);
    }
}

function removeKeyInput(key) {
    var d = document.getElementById(key);
    var old = document.getElementById(key + kcounter[key]);
    d.removeChild(old);
    kcounter[key] = kcounter[key] - 1;
}

// based off expander.js
var defaultExpandText = "Show Options";
var defaultCollapseText = "Hide Options";

function toggleGroup(expander, group, expandText, collapseText) {
    for (i in group) {
        if (document.getElementById) {
            if (document.getElementById(group[i]).style.display == "none") {
                document.getElementById(group[i]).style.display = "";
                expander.innerHTML = collapseText?collapseText:defaultCollapseText;
                expander.value = collapseText?collapseText:defaultCollapseText;
            } else {
                document.getElementById(group[i]).style.display = "none";
                expander.innerHTML = expandText?expandText:defaultExpandText;
                expander.value = expandText?expandText:defaultExpandText;
            }
        }
    }
}

// action is a string which the backend understands. currently 'cancel', 'reset' and
// 'delete' for /tasks/:client/id/:id; and 'delete' for /reports/:client/id/:id.
function modifyDocument(action, url) {
    jQuery.ajax({
        async: true,
        dataType: 'json',
        data: { action : action },
        type: (action == 'delete') ? 'DELETE' : 'POST',
        url: url,
        success: function(data, textStatus, obj) {
            // NOTE: 'obj.responseText' should be a JSON string, and 'data' should be that string parsed
            if (obj.status == 204) {
                $(document.getElementById("results")).html("204 No Content: document deleted");
            } else if (obj.status == 205) {
                location.reload();
            } else {
                alert(obj.status + ": " + obj.responseText);
            }
        },
        error: function(obj, textStatus, error) {
            // NOTE: 'obj.responseText' should be a JSON string, and 'error' might be that string parsed??
            if (obj.status == 403) {
                alert("403 Forbidden: " + obj.responseText);
            } else if (obj.status == 410) {
                $(document.getElementById("results")).html("410 Gone: " + obj.responseText);
            } else if (obj.status == 500) {
                alert("500 Internal Server Error: " + obj.responseText);
            } else {
                alert(obj.status + ": " + obj.responseText);
            }
        }
    });
}
