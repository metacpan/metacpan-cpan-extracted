if( yote ) {

    var _costForm = new Intl.NumberFormat( "en-US", {
        minimumFractionDigits : 2,
        maximumFractionDigits : 2,              
        style : "decimal",
    } );

    var _makeFormatter = function( decimals ) {
        return new Intl.NumberFormat( "en-US", {
            minimumFractionDigits : decimals,
            maximumFractionDigits : decimals,
            style : "decimal",
        } );
    }
    
    var _updater = function(o) {

        $( ".toggleField" ).each( function() {
            var obj = o;
            var $this = $(this);
            if( $this.data( 'id') != obj.id ) {
                return;
            }

            var fld = $this.data( 'field' );
            var tClass = $this.data( 'toggle-class' );
            var state = o.get( fld );
            var toggleState = state === undefined || state == 0 ?  false : true;
            $this.toggleClass( tClass, toggleState );
            
        } );

        $( ".showField" ).each( function() {
            var obj = o;
            var $this = $(this);
            if( $this.data( 'id') != obj.id ) {
                return;
            }

            var fld = $this.data( 'field' );
            var val = o.get( fld );

            var form = $this.data( 'format' );
            if( form ) {
                if(  form == '$' ) {
                    val = _costForm.format( val );
                }
                else if( form.startsWith('#') ) {
                    val = _makeFormatter( $this.data( 'format').substr( 1 ) ).format( val );
                }
            }
            if( $this.is( 'input' ) ) {
                var t = $this.attr('type');
                if( $this.attr( 'type' ) === 'checkbox' ) {
                    if( val === "1" ) {
                        $this.prop( 'checked', true );
                    } else {
                        $this.prop( 'checked', false );
                    }
                } else {
                    $this.attr( 'value', val );
                }
            } else if( $this.is( 'select' ) ) {
                if( typeof val === 'object' ) {
                    $this.val( val.id );
                } else {
                    $this.val( val );
                }
            } else if( $this.is( 'img' ) ) {
                $this.attr( 'src', val );
            } else if( val ) {
                $this.text( val );
            } else {
                $this.html( '&nbsp;' );
            }
        } );
    }; //_updater

    yote.ui = {

          energize : function( cls, obj ) {
              yote.ui.setIds( cls, obj );
              yote.ui.activateControls();
              yote.ui.watchForUpdates( obj );
          }, 

          fill_template : function( sel, vars, fields ) {
              if( ! fields ) { fields = []; }
              if( ! vars )   { vars = []; }
              var $template = $( 'section.templates ' + sel ).not( '[data-cloned="true"]' );
              if( $template.length > 1 ) {
                  console.warn( "error filling template '" + sel + "'. selector matches somethign other than one thing." );
                  return undefined;
              } else if( $template.length == 0 ) {
                  console.warn( "error filling template '" + sel + "'. could not find template." );
                  return undefined;
              }
              var $clone = $template.clone();
              $clone.data( 'cloned', 'true' );
              function filler( $this ) {
                  for( var i=0;i<fields.length; i++ ) {
                      var fld = fields[i];
                      if( typeof vars[$this.attr( fld )] !== 'undefined' ) {
                          $this.attr( fld, vars[$this.attr( fld )] );
                      }
                  }
              };
              filler( $clone );
              $clone.find("*").each( function() {
                  filler( $(this) );
              } );
              return $clone;
          }, //fill_template

          setIds : function( cls, obj ) {
              $( '.' + cls + ',.'+cls+'-child' ).each( function() {
                  var $this = $(this);

                  $this.data( 'activated-listeners', false );
                  $this.data( 'activated-controls', false );
                  if( $this.is( 'select' ) && $this.data( 'id' ) != obj.id ) {
                      // special casey thing to regenerate select controls
                      $this.removeClass( 'build-select' );
                  }
                  if( $this.hasClass( cls+'-child' ) ) {
                      $this.data( 'parent', obj.id );
                  }
                  if( $this.hasClass( cls ) ) {
                      $this.data( 'id', obj.id );
                  }
              } );
          },

          updateListener : function( obj, listenerName, listenerFunc, runOnStartup ) {
              if( ! obj[ listenerName ] ) {
                  obj[ listenerName ] = true;
                  obj.addUpdateListener( listenerFunc );
              }
              if( runOnStartup ) {
                  listenerFunc( obj );
              }
          }, //updateListener

          onControl : function( selector, key, fun ) {
              $( selector ).each( function(idx,val) {
                  var $this = $( val );
                  if( ! $.contains( $('.templates')[0], val ) ) {
                      if( !( $this.data( key ) || $this.data( 'activated-controls' ) ) && $this.data( 'id') ) {
                          $this.data( key, true );
                          $this.data( 'activated-controls', true );
                          fun( $this );
                      }
                  }
              } );
          }, //onControl

          addListener : function( selector, key, eventFuns ) {
              $( selector ).each( function(idx,val) {
                  var $this = $( val );
                  if( ! $.contains( $('.templates')[0], val ) ) {
                      if( !( $this.data( key ) || $this.data( 'activated-listeners' ) ) && $this.data( 'id') ) {
                          $this.data( key, true );
                          $this.data( 'activated-listeners', true );
                          for( var even in eventFuns ) {
                              $this.off( even, eventFuns[even] ).on( even, eventFuns[even] );
                          }
                      }
                  }
              } );
          }, //addListener

          activateControls : function()  {

              yote.ui.onControl( 'div.updateFieldControl', 'updateField-setup', function( $ctrl ) {
                  var did = 'data-id="' + $ctrl.data( 'id' ) + '"';
                  $ctrl.empty().append( '<div class="editing-area"><textarea class="updateField showField ' + ($ctrl.data( 'classes') ||'') + '" ' + 
                                        did +
                                        '       data-field="' + $ctrl.data( 'field' ) + '"' + 
//                                        '       type="'       + ( $ctrl.data( 'input-type') || 'text' )+ '">' +
                                        '></textarea><br>' + 
                                        '<button type="button" ' + did + ' class="cancel">cancel</button> ' + 
                                        '<button type="button" ' + did + ' class="ok">ok</button>' + 
                                        '</div>' + 
                                        '<pre><span class="showField ' + ($ctrl.data( 'classes')||'') + '"' + 
                                        did +
                                        '      data-format="'+ $ctrl.data( 'format' ) + '"' + 
                                        '      data-field="' + $ctrl.data( 'field') + '">' + 
                                        '  &nbsp;</span></pre>' );
                  var targ_obj = yote.fetch( $ctrl.data( 'id' ) );
                  var targ_fld = $ctrl.data( 'field' );
                  var cur_val    = targ_obj.get( targ_fld );
                  $ctrl.data( 'original', cur_val );
              } );
              yote.ui.onControl( 'select.updateField', 'build-select', function( $ctrl ) {
                  // data : 
                  //   field - field on object to modify
                  //   id - object to modify
                  //   data-src-id     - object where this list comes from
                  //   data-src-field  - 
                  //   data-src-method -

                  var targ_obj = yote.fetch( $ctrl.data( 'id' ) );
                  var targ_fld = $ctrl.data( 'field' );
                  var cur_val    = targ_obj.get( targ_fld );
                  if( $ctrl.data( 'var-is') === 'object' && cur_val ) {
                      cur_val = cur_val.id;
                  }
                  $ctrl.data( 'original', cur_val );

                  var source_id  = $ctrl.data( 'src-id' );
                  var list;
                  var fillOptions = function() {
                      var buf = '';
                      for( var i=0; i<list.length; i++ ) {
                          var el = list[i];
                          var title, val;
                          if( Array.isArray( el ) ) {
                              val   = el[0];
                              title = el[1];
                          } else {
                              val   = el;
                              title = el;
                          }
                          var dataid = '';
                          if( typeof val === 'object' ) {
                              val = val.id;
                              dataid = 'data-id="' + val + '" data-field="name" ';
                          }
                          if( typeof title === 'object' ) {
                              title = title.get( 'name' );
                          }
                          buf += '<option class="showField" ' + dataid + ' value="' + val + '">' + title + '</option>';
                      }
                      $ctrl.empty().append( buf ).val( cur_val );
                      if( ! buf && $ctrl.data( 'hide-on-empty' ) ) {
                          $ctrl.hide();
                      } else {
                          $ctrl.show();
                      }

                  } //fillOptions

                  var source_obj = source_id ? yote.fetch( source_id ) : targ_obj;
                  if( $ctrl.data( 'src-field' ) ) {
                      var listO = source_obj.get( $ctrl.data( 'src-field' ) );
                      list = listO.toArray();
                      fillOptions();
                  
                      yote.ui.updateListener( listO, 'select-chooser-build-select', function() {
                          var key = 'build-select';
                          $ctrl.data( key, false );
//                          yote.ui.activateControls();
                      }, false );
                  }
                  if( typeof targ_fld !== 'undefined' ) {
                      $ctrl.off( 'change' ).on( 'change',
                                                function( ev ) {
                                                    var val = $ctrl.val();
                                                    if( $ctrl.data( 'var-is') === 'object' ) {
                                                        val = yote.fetch( val );
                                                    }
                                                    var up = {};
                                                    up[ targ_fld ] = val;
                                                    targ_obj.update( [up] );
                                                } );
                  }

              } );

/*
              yote.ui.addListener( 'div.updateFieldControl>span', 'updateField-click', {
                  click : function() {
                      var $this = $(this);
                      $this.parent().addClass( 'editing' );
                      var $inpt = $this.parent().find( 'textarea' );
                      $inpt.data( 'original', $inpt.val() );
                      $inpt.focus();
                  }
              } ); //updateFieldControl span click
*/
              yote.ui.addListener( 'div.updateFieldControl', 'updateField-click', {
                  click : function(ev) {
                      ev.preventDefault();
                      var $this = $(this);
                      $this.addClass( 'editing' );
                      var $inpt = $this.find( 'input' );
                      $inpt.data( 'original', $inpt.val() );
                      $inpt.focus();
                  }
              } ); //updateFieldControl click

              yote.ui.addListener( 'div.updateFieldControl>.editing-area>textarea', 'keylisteners', {
                  blur : function(ev) {
                      var $this = $(this);
                      if( $this.data( 'original' ) == $this.val() ) {
                          $this.parent().parent().removeClass( 'editing' );
                      }
                  },

                  keydown : function(ev) {
                      var kk = ev.keyCode || ev.charCode;
                      var $this = $(this);
                      if( kk == 27 )  {
                          var $p = $this.parent().parent();
                          $this.val( $p.data( 'original' ) || '' );
                          $p.removeClass( 'editing' );
                          $this.removeClass('edited' );
                      }
                      $this.toggleClass('edited', $this.data( 'original') == $this.text() );
                  },
                  keyup : function( ev ) {
                      var $ctrl = $( this );
                      $ctrl.toggleClass('edited', $ctrl.data( 'original') != $ctrl.text() );
                  }
              } );

              yote.ui.addListener( '.ok', 'okclick', {
                  click : function( ev ) {
                      ev.preventDefault();
                      ev.stopPropagation();
                      var $p = $(this).parent().parent();
                      var $txt = $p.find( 'textarea' );
                      $p.find('span').text( $txt.text() );
                      $txt.removeClass('edited' );
                      $p.removeClass( 'editing' );
                      var obj = yote.fetch( $txt.data('id') );
                      var fld = $txt.data('field');
                      var inpt = {};
                      inpt[ fld ] = $txt.val();
                      $p.data( 'original', inpt[ fld ] );
                      obj.update( [ inpt ] );
                  }
              } );
              yote.ui.addListener('.cancel', 'cancelclick', {
                  click : function( ev ) {
                      ev.preventDefault();
                      ev.stopPropagation();
                      var $p = $(this).parent().parent();
                      var $txt = $p.find( 'textarea' );
                      $txt.val( $p.data( 'original' ) || '' );
                      $p.removeClass( 'editing' );
                      $txt.removeClass('edited' );
                  }
              } );


              yote.ui.addListener( 'input.updateField[type="checkbox"]', 'checked', {
                  change : function(ev) {
                      var $this = $( this );
                      var obj = yote.fetch( $this.data( 'id') );
                      var fld = $this.data( 'field');
                      var inpt = {};
                      inpt[ fld ] = $this.is(':checked') ? 1 : 0;
                      obj.update( [ inpt ] );
                  }
              }); // input.updateField (checkbox )

              yote.ui.addListener( 'input.updateField', 'input-keydown', {
                  keydown : function(ev) {
                      var kk = ev.keyCode || ev.charCode;
                      if( kk == 13 || kk == 9 ) {
                          var $this = $( this );
                          var obj = yote.fetch( $this.data( 'id') );
                          var proxy_obj = yote.fetch( $this.data( 'proxy') );
                          var fld = $this.data( 'field');
                          var inpt = {};
                          inpt[ fld ] = $this.val();
                          if( proxy_obj ) {
                              proxy_obj.update( [ obj, inpt ] );
                          } else {
                              obj.update( [ inpt ] );
                          }
                      } 
                  }
              } ); // input.updateField
              yote.ui.addListener( '.updateField.autosubmit', 'input-blur', {
                  blur : function(ev) {
                      var $this = $(this);
                      var obj = yote.fetch( $this.data( 'id') );
                      var fld = $this.data( 'field');
                      var inpt = {};
                      inpt[ fld ] = $this.val();
                      obj.update( [ inpt ] );
                  }
              } ); // .updateField.autosubmit blur

              yote.ui.addListener( '.delAction', 'delAction', {
                  click : function(ev) {
                      ev.preventDefault();
                      var $this = $(this);
                      if( $this.data( 'needs-confirmation' ) && ! confirm( $this.data( 'delete-message' ) || 'really delete?' ) ) {
                          return;
                      }
                      var par    = yote.fetch($this.data( 'parent' ));
                      var obj    = yote.fetch($this.data( 'id' ));
                      par.remove_entry( [obj,$this.data( 'from')] );
                  }
              } ); // delAction click

              yote.ui.addListener( '.addAction', 'addClick', {
                  click : function(ev) {
                      ev.preventDefault();
                      var $this = $(this);
                      var list  = $this.data( 'list');
                      var listOn = yote.fetch( $this.data( 'id') );
                      listOn.add_entry( [ list ], function( newo ) {
                          yote.ui.watchForUpdates( Array.isArray( newo ) ? newo[0] : newo ); } );
                  } 
              } );  //addAction click

              yote.ui.addListener( '.action', 'addAction', {
                  click : function(ev) {
                      ev.preventDefault();
                      var $this = $(this);
                      var action  = $this.data( 'action');
                      var params  = [];
                      if( $this.data( 'param') ) {
                          // TODO - for multiple params, a data-number-of-params, then data-param_1, data-param_2 ...
                          params.push( yote.fetch( $this.data( 'param') ));
                      }
                      // TODO - error message for item not found
                      var item = yote.fetch( $this.data( 'id') );
                      item[ action ]( params );
                  }
              } ); //action click
          }, //activateControls

          setup_table : function( args ) {
              var $tab = $( args.conSel ).find( 'tbody' );
              $tab.empty();
              var items = args.list || args.listOn.get( args.listName );
              items.each( function( item, i ) {
                  var replaceList = typeof args.replaceList === 'function' ? args.replaceList( item, i ) : args.replaceList;
                  var row = yote.ui.fill_template( args.rowSel, replaceList || {
                      ID     : item.id,
                      FROMID : args.listOn.id,
                      PROXY  : args.proxy ? args.proxy.id : 0
                  }, args.fieldList || [ 'data-id', 'data-parent', 'data-proxy' ] );
                  
                  $tab.append( row );

                  if( args.onEachRow ) {
                      args.onEachRow( row, item, i );
                  }
                      
                  yote.ui.watchForUpdates(item);
              } );

              yote.ui.activateControls();
              items.each( function( item, i ) {
                  yote.ui.watchForUpdates(item);
              } );
          }, //setup_table

          setup_container : function( args ) {
              var $con = $( args.conSel );
              if( args.isTable ) {
                  var $tBody = $con.find( 'tbody' );
                  if( $tBody ) {
                      $con = $tBody;
                  }
              }
              $con.empty();
              var items = args.list || args.listOn.get( args.listName );
              items.each( function( item, i ) {
                  var replaceList = typeof args.replaceList === 'function' ? args.replaceList( item, i ) : args.replaceList;
                  var row = yote.ui.fill_template( args.rowSel, replaceList || {
                      ID     : item.id,
                      FROMID : args.listOn.id,
                      PROXY  : args.proxy ? args.proxy.id : 0
                  }, args.fieldList || [ 'data-id', 'data-parent', 'data-proxy' ] );
                  
                  $con.append( row );

                  if( args.onEachRow ) {
                      args.onEachRow( row, item, i );
                  }
                      
                  yote.ui.watchForUpdates(item);
              } );

              yote.ui.activateControls();
              items.each( function( item, i ) {
                  yote.ui.watchForUpdates(item);
              } );
          }, //setup_container


          watchForUpdates : function() {
              // if the object changes, all HTML controls displaying data from that object are updated
              for( var i=0; i<arguments.length; i++ ) {
                  var obj = arguments[ i ];
                  if( ! obj._watched ) {
                      obj.addUpdateListener( _updater );
                      obj._watched = true;
                  }
                  _updater( obj );
              }
          } //watchForUpdates
    };
} 
