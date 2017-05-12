
//****************************************************************
//* Select.js
//****************************************************************
//* These are functions which provide manipulation of <select>
//* elements and the <option> elements they contain.
//****************************************************************
//* TODO: update these to use modern, standard methods.
//*       these functions were written in 2003 for compatibility.
//****************************************************************

// *******************************************************************
// CLASS: DualSelectWidget
// *******************************************************************

function DualSelectWidget () {
    this.html = html;
    function html () {

        var values     = this.getValues();
        var labels     = this.getLabels();
        var currValues = this.getCurrentValues();

        // var nullable = this.nullable || 0;
        // if (nullable) {
        //     $values = [ "", @$values ];
        // }

        var i;
        var currValueSelected = new Object();
        for (i = 0; i < currValues.length; i++) {
            currValueSelected[currValues[i]] = 1;
        }

        var currValueUnselected = new Object();
        for (i = 0; i < values.length; i++) {
            if (!currValueSelected[values[i]]) {
                currValueUnselected[values[i]] = 1;
            }
        }

        var currValueValid = new Object();
        for (i = 0; i < values.length; i++) {
            currValueValid[values[i]] = 1;
        }

        var multiple = 1;
        var size     = this.size || (multiple > 0 ? 5 : 0);
        var tabindex = this.tabindex;
        var v, value, none;

        var html = '<table border="0" cellspacing="3"' + this.stdAttribs() + '>\n';
        html += '<tr>\n';
        html += '  <td rowspan="2" align="center valign="middle">\n';

        // build the "unselected" list
        none = 1;
        html += '<select name="' + this.serviceName + '-unsel"';
        html += ' onDblClick="return(context.sendEvent(\'' + this.serviceName + '\',\'dblclick-sel\'));"';
        if (multiple > 0) html += ' multiple';
        if (size > 0) html += ' size="' + size + '"';
        if (tabindex != null) html += ' tabindex="' + tabindex + '"';
        html += '>\n';
        for (v = 0; v < values.length; v++) {
            value = values[v];
            if (currValueUnselected[value] != null) {
                html += '  <option value="' + value + '">';
                if (labels[value] != null) {
                    html += labels[value] + '</option>\n';
                }
                else {
                    html += value + '</option>\n';
                }
                none = 0;
            }
        }
        if (none) {
            html += '  <option value="None">[-None-]</option>\n';
        }
        html += '</select>\n';

        var select_button =
            '<input name="' + this.serviceName + '-select" src="' +
            appOptions.urlDocRoot + '/theme/' + appOptions.theme +
            '/DualSelect/rtarrow.gif" alt="Select" border="0" height="19" type="image" width="19"' +
            ' onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'select\'));">';
        var unselect_button =
            '<input name="' + this.serviceName + '-unselect" src="' +
            appOptions.urlDocRoot + '/theme/' + appOptions.theme +
            '/DualSelect/lfarrow.gif" alt="Unselect" border="0" height="19" type="image" width="19"' +
            ' onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'unselect\'));">';
        var up_button =
            '<input name="' + this.serviceName + '-up" src="' +
            appOptions.urlDocRoot + '/theme/' + appOptions.theme +
            '/DualSelect/uparrow.gif" alt="Up" border="0" height="19" type="image" width="19"' +
            ' onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'up\'));">';
        var down_button =
            '<input name="' + this.serviceName + '-down" src="' +
            appOptions.urlDocRoot + '/theme/' + appOptions.theme +
            '/DualSelect/dnarrow.gif" alt="Down" border="0" height="19" type="image" width="19"' +
            ' onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'down\'));">';
        
        // put in the select buttons
        html += '  </td>\n' +
                '  <td align="center" valign="bottom">' +
                '    ' + select_button +
                '  </td>\n' +
                '  <td rowspan="2" align="center" valign="middle">';

        // build the "selected" list
        none = 1;
        html += '<select name="' + this.serviceName + '-sel"';
        html += ' onDblClick="return(context.sendEvent(\'' + this.serviceName + '\',\'dblclick-unsel\'));"';
        if (multiple > 0) html += ' multiple';
        if (size > 0) html += ' size="' + size + '"';
        if (tabindex != null) html += ' tabindex="' + tabindex + '"';
        html += '>\n';
        for (v = 0; v < currValues.length; v++) {
            value = currValues[v];
            if (currValueValid[value]) {
                html += '  <option value="' + value + '">';
                if (labels[value] != null) {
                    html += labels[value] + '</option>\n';
                }
                else {
                    html += value + '</option>\n';
                }
                none = 0;
            }
        }
        if (none) {
            html += '  <option value="None">[-None-]</option>\n';
        }
        html += '</select>\n';

        // finish up
        html += '  </td>\n' +
                '  <td align="center" valign="bottom">' +
                '    ' + up_button +
                '  </td>\n' +
                '</tr>\n' +
                '<tr>\n' +
                '  <td align="center" valign="top">\n' +
                '    ' + unselect_button +
                '  </td>\n' +
                '  <td align="center" valign="top">\n' +
                '    ' + down_button +
                '  </td>\n' +
                '</tr>\n' +
                '<tr>\n' +
                '   <td align="center" valign="top">Not Selected</td>\n' +
                '   <td align="center" valign="top">&nbsp;</td>\n' +
                '   <td align="center" valign="top">Selected\n' +
                '   <input type="hidden" name="' + this.serviceName + '" value="' + this.getCurrentValue() +
                '"></td>\n' +
                '</tr>\n' +
                '</table>\n';

        return(html);
    }

    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        var handled = 0;
        if (eventName == "up") {
            this.moveHighlightedOptionsUp();
            handled = 1;
        }
        else if (eventName == "down") {
            this.moveHighlightedOptionsDown();
            handled = 1;
        }
        else if (eventName == "select") {
            this.selectHighlightedOptions();
            handled = 1;
        }
        else if (eventName == "unselect") {
            this.unselectHighlightedOptions();
            handled = 1;
        }
        else if (eventName == "dblclick-sel") {
            this.selectHighlightedOptions();
            handled = 1;
        }
        else if (eventName == "dblclick-unsel") {
            this.unselectHighlightedOptions();
            handled = 1;
        }
        else {
            handled = DualSelectWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs);
        }
        return(handled);
    }

    // useAllNone  0=no, 1=yes, 2=useNone
    this.moveHighlightedOptionsUp = moveHighlightedOptionsUp;
    function moveHighlightedOptionsUp () {
       var varname = this.serviceName;
       var selectedList, varElement, useAllNone;

       useAllNone = 2;

       selectedList = context.getElementByName(varname + "-sel");
       unselectedList = context.getElementByName(varname + "-unsel");
       if (selectedList != null && unselectedList != null) {   // ensure that both lists were found
          options_unselectAll(unselectedList.options);         // clean unused selections in the other list
          options_moveHighlightedUp(selectedList.options);        // move the selections up
          varElement = context.getElementByName(varname);
          options_toScalarElement(selectedList,varElement,useAllNone,unselectedList);
          //alert("moveHighlightedOptionsUp: " + varname + "=" + varElement.value);
          return(false);
       }
       else {
          alert("unselectHighlightedOptions: one or both lists not found");
          return(true);   // couldn't do it in JavaScript... go ahead with CGI submission.
       }
    }

    // useAllNone  0=no, 1=yes, 2=useNone
    this.moveHighlightedOptionsDown = moveHighlightedOptionsDown;
    function moveHighlightedOptionsDown () {
       var varname = this.serviceName;
       var selectedList, varElement, useAllNone;

       useAllNone = 2;

       selectedList = context.getElementByName(varname + "-sel");
       unselectedList = context.getElementByName(varname + "-unsel");
       if (selectedList != null && unselectedList != null) {   // ensure that both lists were found
          options_unselectAll(unselectedList.options);         // clean unused selections in the other list
          options_moveHighlightedDown(selectedList.options);      // move the selections down
          varElement = context.getElementByName(varname);
          options_toScalarElement(selectedList,varElement,useAllNone,unselectedList);
          //alert("moveHighlightedOptionsDown: " + varname + "=" + varElement.value);
          return(false);
       }
       else {
          alert("unselectHighlightedOptions: one or both lists not found");
          return(true);   // couldn't do it in JavaScript... go ahead with CGI submission.
       }
    }

    // useAllNone  0=no, 1=yes, 2=useNone
    this.selectHighlightedOptions = selectHighlightedOptions;
    function selectHighlightedOptions () {
       var varname = this.serviceName;
       var sorted = this.sorted;
       var selectedList, unselectedList, varElement, useAllNone;

       useAllNone = 2;

       if (arguments.length == 1) {
          sorted = false;
       }
       selectedList = context.getElementByName(varname + "-sel");
       unselectedList = context.getElementByName(varname + "-unsel");
       if (selectedList != null && unselectedList != null) {               // ensure that both lists were found
          options_unselectAll(selectedList.options);                     // clean unused selections in the other list
          selectPair_moveHighlighted(unselectedList,selectedList,useAllNone,sorted); // move the selections to the other list
          varElement = context.getElementByName(varname);
          options_toScalarElement(selectedList,varElement,useAllNone,unselectedList);
          //alert("selectHighlightedOptions: " + varname + "=" + varElement.value);
          return(false);
       }
       else {
          alert("unselectHighlightedOptions: one or both lists not found");
          return(true);   // couldn't do it in JavaScript... go ahead with CGI submission.
       }
    }

    // useAllNone  0=no, 1=yes, 2=useNone
    this.unselectHighlightedOptions = unselectHighlightedOptions;
    function unselectHighlightedOptions () {
       var varname = this.serviceName;
       var sorted = this.sorted;
       var selectedList, unselectedList, varElement, useAllNone;

       useAllNone = 2;

       if (arguments.length == 1) {
          sorted = false;
       }
       selectedList = context.getElementByName(varname + "-sel");
       unselectedList = context.getElementByName(varname + "-unsel");
       if (selectedList != null && unselectedList != null) {         // ensure that both lists were found
          options_unselectAll(unselectedList.options);               // clean unused selections in the other list
          selectPair_moveHighlighted(selectedList,unselectedList,useAllNone,sorted); // move the selections to the other list
          varElement = context.getElementByName(varname);
          options_toScalarElement(selectedList,varElement,useAllNone,unselectedList);
          //alert("unselectHighlightedOptions: " + varname + "=" + varElement.value);
          return(false);
       }
       else {
          alert("unselectHighlightedOptions: one or both lists not found");
          return(true);   // couldn't do it in JavaScript... go ahead with CGI submission.
       }
    }

    // function picklist_hidden2visible (varname) {
    //    var scalarElem, selectedList, unselectedList, useAllNone;
    //    useAllNone = 2;
    //    scalarElem = context.getElementByName(varname);
    //    selectedList = context.getElementByName(varname + "-sel");
    //    unselectedList = context.getElementByName(varname + "-unsel");
    //    //alert("picklist_hidden2visible(begin): " + varname + "=" + scalarElem.value);
    //    if (scalarElem != null && selectedList != null && unselectedList != null) {
    //       syncScalarElementWithOptions (selectedList, scalarElem, useAllNone, unselectedList);
    //    }
    //    //alert("picklist_hidden2visible(end): " + varname + "=" + scalarElem.value);
    // }

    // function picklist_event (method, varname) {
    //    if (method == "hidden2visible") {
    //       picklist_hidden2visible(varname);
    //    }
    // }
}
DualSelectWidget.prototype = new Widget();

//****************************************************************
//* option "methods"
//****************************************************************

function option_copy (option)
{
   var newoption;
   //newoption = document.createElement("OPTION"); // (doesn't work with Netscape)
   newoption = new Option();                     // create new option for inserting in other list
   newoption.text = option.text;                 // copy the text (visible label)
   newoption.value = option.value;               // copy the value (hidden value which gets submitted)
   newoption.selected = false;                   // initialize it as *not selected*
   return(newoption);
}

function option_new (text, value)
{
   var newoption;
   //newoption = document.createElement("OPTION"); // (doesn't work with Netscape)
   newoption = new Option();                     // create new option for inserting in other list
   newoption.text = text;                        // copy the text (visible label)
   newoption.value = value;                      // copy the value (hidden value which gets submitted)
   newoption.selected = false;                   // initialize it as *not selected*
   return(newoption);
}

//****************************************************************
//* options "methods"
//****************************************************************

function options_add (options, option, idx)
{
   var len;
   len = options.length;
   if (arguments.length == 2) {
      //alert("options_add(options, option)");
      options[len] = option;                     // add to other list (NN)
      //options.add(option);                     // add to other list (IE4 +)
   }
   else {
      //alert("options_add(options, option, " + idx + ")");
      if (options.add) {
         options.add(option,idx);                 // add to other list (IE4 +)
      }
      else {
         for (var o = len; o > idx; o--) {          // move all other options up one
            options[o] = options[o-1];
         }
         options[idx] = option;                     // add to other list in ordered position (NN)
      }
   }
}

function options_remove (options, idx)
{
   //alert("Removing " + idx);
   //options.remove(idx);            // delete from existing list (IE-specific)
   //options[idx].scrollIntoView();    // this seems to be necessary to keep from crashing the browser (only IE 4+)
   options[idx] = null;            // delete from existing list (older, works for NN)
}

function options_move (options, from_idx, to_idx)
{
   var len, option;
   len = options.length;
   if (from_idx < len && to_idx < len) {
      option = option_copy(options[from_idx]);
      if (options[from_idx].selected) {
         option.selected = true;
      }
      options_remove(options, from_idx);
      options_add(options, option, to_idx);
   }
}

function options_moveHighlightedUp (options)
{
   var len;
   len = options.length;
   for (var o = 1; o < len; o++) {
      if (options[o].selected && !options[o-1].selected) {
         options_move(options,o,o-1);
      }
   }
}

function options_moveHighlightedDown (options)
{
   var len;
   len = options.length;
   for (var o = len-2; o >= 0; o--) {
      if (options[o].selected && !options[o+1].selected) {
         options_move(options,o,o+1);
      }
   }
}

function options_addOrdered (options, option, startidx)
{
   if (arguments.length == 2) {
      startidx = 0;
   }
   //alert("options_addOrdered(options, option, " + startidx + ")");
   for (var idx = startidx; idx < options.length; idx++) {  // find proper ordered position, idx
      if (option.text < options[idx].text) {
         break;
      }
   }
   options_add(options, option, idx);
}

function options_addAll (fromOptions, toOptions)
{
   var idx, newoption;
   for (idx = 0; idx < fromOptions.length; idx++) {
      newoption = option_copy(fromOptions[idx]);
      options_add(toOptions,newoption);
   }
}

function options_removeAll (options)
{
   var len;
   //var idx;

   len = options.length;
   //for (idx = options.length-1; idx >= 0; idx--) {
   //   options_remove(options, idx);
   //}

   //while (len > 0) {
   //   options_remove(options, 0);
   //   len--;
   //}

   options.length = 0;
}

function options_unselectAll (options)
{
   var idx;
   for (idx = 0; idx < options.length; idx++) {
      options[idx].selected = false;
   }
}

function options_set (options, text, value)
{
   var idx, options_length, newopt;
   if (text.length != value.length) {
      return;
   }
   options_length = options.length;
   for (idx = 0; idx < options_length && idx < text.length; idx++) {
      if (options[idx].text != text[idx]) {
         options[idx].text = text[idx];
      }
      if (options[idx].value != value[idx]) {
         options[idx].value = value[idx];
      }
   }
   if (options_length > text.length) {
      for (idx = options_length-1; idx >= text.length; idx--) {
         options_remove(options,idx);
      }
   }
   else if (options_length < text.length) {
      for (idx = options_length; idx < text.length; idx++) {
         newopt = option_new(text[idx], value[idx]);
         options_add(options, newopt);
      }
   }
}

// useAllNone  0=no, 1=yes, 2=useNone
function options_toScalarElement (options, elem, useAllNone, nonoptions)
{
   var idx, text, value;
   if (options.length == 0) {
      text = "";
      value = "";
   }
   else if (useAllNone == 1 && options[0].value == "All") {
      text = "[-All-]";
      value = "All";
   }
   else if (useAllNone && options[0].value == "None") {
      text = "[-None-]";
      value = "None";
   }
   else if (useAllNone == 1 &&
            arguments.length == 4 &&
            (nonoptions.length == 0 ||
             (nonoptions.length == 1 && nonoptions[0].value == "None"))) {
      text = "[-All-]";
      value = "All";
   }
   else {
      text = options[0].text;
      value = options[0].value;
      for (idx = 1; idx < options.length; idx++) {
         text += "," + options[idx].text;
         value += "," + options[idx].value;
      }
   }

   if (elem.type == "hidden" || elem.type == "text" || elem.type == "textarea") {
      elem.value = value;
      //alert("value: " + value);
   }
   else {
      alert("Error: tried to assign a value to an element that does not make sense");
   }
}

//****************************************************************
//* scalarElement "methods"
//****************************************************************

// useAllNone  0=no, 1=yes, 2=useNone
function syncScalarElementWithOptions (options, elem, useAllNone, nonoptions)
{
   var    scalar_value,    implied_value;
   var   selected_text,   selected_value;
   var unselected_text, unselected_value;
   var     option_text,     hidden_value;
   var      value_used,  rest_unselected;
   var idx, sidx, uidx;

   scalar_value = elem.value;    // save value from hidden element
   options_toScalarElement (options, elem, useAllNone, nonoptions)  // compute implied value
   implied_value = elem.value;   // save implied value
   
   //alert("syncScalarElementWithOptions: elem.value=" + scalar_value + " options.value=" + implied_value);
   if (scalar_value == implied_value) {
      return (0);
   }
   // if (browserVendor == "NS") {
   //    return (0);
   // }
   elem.value = scalar_value;    // restore value to hidden element

   option_text = new Object();

   for (idx = 0; idx < options.length; idx++) {
      option_text[options[idx].value] = options[idx].text;
   }
   for (idx = 0; idx < nonoptions.length; idx++) {
      option_text[nonoptions[idx].value] = nonoptions[idx].text;
   }

   hidden_value = scalar_value.split(",");
   value_used = new Object();
   selected_text = new Array();
   selected_value = new Array();
   unselected_text = new Array();
   unselected_value = new Array();

   sidx = 0;
   uidx = 0;

   for (idx = 0; idx < options.length; idx++) {
      option_text[options[idx].value] = options[idx].text;
   }
   for (idx = 0; idx < nonoptions.length; idx++) {
      option_text[nonoptions[idx].value] = nonoptions[idx].text;
   }

   rest_unselected = 1;
   if (scalar_value == "All") {
      if (useAllNone == 1) {
         selected_value[sidx] = "All";
         selected_text[sidx]  = "[-All-]";
         sidx++;
      }
      if (useAllNone >= 1) {
         unselected_value[uidx] = "None";
         unselected_text[uidx]  = "[-None-]";
         uidx++;
      }
      rest_unselected = 0;
   }
   else if (scalar_value == "None" || scalar_value == "") {
      if (useAllNone == 1) {
         unselected_value[uidx] = "All";
         unselected_text[uidx]  = "[-All-]";
         uidx++;
      }
      if (useAllNone >= 1) {
         selected_value[sidx] = "None";
         selected_text[sidx]  = "[-None-]";
         sidx++;
      }
   }
   else {
      for (idx = 0; idx < hidden_value.length; idx++) {
         if (hidden_value[idx] != "All" && hidden_value[idx] != "None" && hidden_value[idx] != "") {
            if (option_text[hidden_value[idx]] == null) {
               alert("There was a value in the hidden field not in either visible field: " + hidden_value[idx]);
            }
            else {
               selected_value[sidx] = hidden_value[idx];
               selected_text[sidx]  = option_text[hidden_value[idx]];
               sidx++;
               value_used[hidden_value[idx]] = 1;
            }
         }
         else {
            alert("Error #1");
         }
      }
   }

   if (rest_unselected == 1) {
      for (idx = 0; idx < nonoptions.length; idx++) {
         if (nonoptions[idx].value != "All" && nonoptions[idx].value != "None") {
            if (value_used[nonoptions[idx].value] == null) {
               unselected_value[uidx] = nonoptions[idx].value;
               unselected_text[uidx]  = option_text[nonoptions[idx].value];
               uidx++;
            }
            value_used[nonoptions[idx].value] = 1;
         }
      }
      for (idx = 0; idx < options.length; idx++) {
         if (options[idx].value != "All" && options[idx].value != "None") {
            if (value_used[options[idx].value] == null) {
               unselected_value[uidx] = options[idx].value;
               unselected_text[uidx]  = option_text[options[idx].value];
               uidx++;
            }
            value_used[options[idx].value] = 1;
         }
      }
   }
   else {
      for (idx = 0; idx < options.length; idx++) {
         if (options[idx].value != "All" && options[idx].value != "None") {
            if (value_used[options[idx].value] == null) {
               selected_value[sidx] = options[idx].value;
               selected_text[sidx]  = option_text[options[idx].value];
               sidx++;
            }
            value_used[options[idx].value] = 1;
         }
      }
      for (idx = 0; idx < nonoptions.length; idx++) {
         if (nonoptions[idx].value != "All" && nonoptions[idx].value != "None") {
            if (value_used[nonoptions[idx].value] == null) {
               selected_value[sidx] = nonoptions[idx].value;
               selected_text[sidx]  = option_text[nonoptions[idx].value];
               sidx++;
            }
            value_used[nonoptions[idx].value] = 1;
         }
      }
   }

   options_set (nonoptions, unselected_text, unselected_value);
   options_set (   options,   selected_text,   selected_value);
}

//****************************************************************
//* select "methods"
//****************************************************************

function select_removeHighlightedOptions (select)
{
   var idx, i;
   var selIdx = new Array();

   //alert ("select_removeHighlightedOptions()");

   i = 0;
   for (idx = select.options.length-1; idx >= 0; idx--) {
      if (select.options[idx].selected) {
         selIdx[i] = idx;
         i++;
         select.options[idx].selected = false;
      }
   }
   for (i = 0; i < selIdx.length; i++) {
      options_remove(select.options, selIdx[i]);
   }
}

//****************************************************************
//* selectPair "methods"
//****************************************************************

// param: fromSelect
//        toSelect
//        UseAllNone      0=no, 1=yes, 2=useNone
//        insertInOrder
function selectPair_moveHighlighted (fromSelect, toSelect, useAllNone, insertInOrder)
{
   var o, len, newopt;
   //alert("selectPair_moveHighlighted()");
   if (fromSelect != null && toSelect != null) {
      options_unselectAll(toSelect.options);
      if (useAllNone > 0) {
         if (fromSelect.options.length == 0) {
            //alert("no options in 'from'");
         }
         else if (fromSelect.options[0].value == "None") {
            //alert("'None' in 'from'");
            options_unselectAll(fromSelect.options);
         }
         else if (fromSelect.options[0].value == "All" && fromSelect.options[0].selected) {
            //alert("'All' in 'from'");
            options_unselectAll(fromSelect.options);
            options_removeAll(toSelect.options);
            options_addAll(fromSelect.options, toSelect.options);
            options_removeAll(fromSelect.options);
            newopt = option_new("[-None-]","None");
            options_add(fromSelect.options, newopt);
            newopt = null;
         }
         else {
            if (fromSelect.options[0].value == "All") {
               options_remove(fromSelect.options,0);
            }
            o = 0;
            len = fromSelect.options.length;                 // original length of option list
            while (o < len) {
               if (fromSelect.options[o].selected) {         // change all selected options to the other list

                  if (toSelect.options.length > 0 && toSelect.options[0].value == "None") {
                     options_remove(toSelect.options,0);
                  }

                  newopt = option_copy(fromSelect.options[o]);
                  if (insertInOrder) {
                     options_addOrdered(toSelect.options, newopt);
                  }
                  else {
                     options_add(toSelect.options, newopt);
                  }
                  newopt = null;
               }
               o++;
            }
            select_removeHighlightedOptions(fromSelect);
         }

         if (fromSelect.options.length == 0) {
            newopt = option_new("[-None-]","None");
            options_add(fromSelect.options,newopt,0);
            newopt = null;
            if (useAllNone == 1) {
               if (toSelect.options.length == 0 || toSelect.options[0].value != "All") {
                  newopt = option_new("[-All-]","All");
                  options_add(toSelect.options,newopt,0);
                  newopt = null;
               }
            }
         }
      }
      else {
         o = 0;
         len = fromSelect.options.length;                 // original length of option list
         while (o < len) {
            if (fromSelect.options[o].selected) {         // change all selected options to the other list
               newopt = option_copy(fromSelect.options[o]);
               if (insertInOrder) {
                  options_addOrdered(toSelect.options, newopt);
               }
               else {
                  options_add(toSelect.options, newopt);
               }
               newopt = null;
               options_remove(fromSelect.options, o);
               len--;
            }
            else {
               o++;
            }
         }
      }
   }
   else {
      alert("selectPair_moveHighlighted(): null list");
   }
}

