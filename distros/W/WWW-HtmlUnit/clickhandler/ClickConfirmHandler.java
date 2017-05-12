/* **************************************************
 *
 * Extention to htmlunit's ConfirmHandler Interface.
 *
 * This will keep track of all the messages
 * of all the messages of the confirm boxes that
 * pop-up. It will also keep track of the
 * message of the last confirm box.
 *
 * By calling make_click_ok or make_click_cancel
 * you can control which button will get pressed
 * for all the confirms until the other method
 * is called.
 *
 * Compile this java file with:
 *   javac com/gargoylesoftware/htmlunit/ClickConfirmHandler.java
 *
 * and jar it with:
 *   jar cf htmlunit-confirmhandler-2.8.jar com/gargoylesoftware/htmlunit/ClickConfirmHandler.class
 *
 * **************************************************/

package com.gargoylesoftware.htmlunit;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class ClickConfirmHandler implements ConfirmHandler, Serializable {
    
    private boolean click_ok;
    private final List<String> collectedConfirms;
    private String last_confirm_msg;

    // By default the handler will click the ok button
    public ClickConfirmHandler() {
        this(true, new ArrayList<String>());
    }

    public ClickConfirmHandler(boolean click_type) {
        this(click_type, new ArrayList<String>());
    }

    public ClickConfirmHandler(final List<String> list) {
        this(true, new ArrayList<String>());
    }

    public ClickConfirmHandler(boolean click_type, final List<String> list) {
        collectedConfirms = list;
        click_ok = click_type;
    }

    public boolean handleConfirm(final Page page, final String message) {
        last_confirm_msg = message;
        collectedConfirms.add(message);
        return click_ok;
    }

    public void make_click_ok() {
        click_ok = true;
    }

    public void make_click_cancel() {
        click_ok = false;
    }

    public boolean clicking_button() {
        return click_ok;
    }

    public List<String> getCollectedConfirms() {
        return collectedConfirms;
    }

    public String get_last_confirm_msg() {
        return last_confirm_msg;
    }
}
