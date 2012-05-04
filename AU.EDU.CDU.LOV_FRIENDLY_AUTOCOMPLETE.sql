----------------- Utility functions ----------------------
function merge_lists (
  p_comma_sep_list1 varchar2,
  p_comma_sep_list2 varchar2)
return varchar2 is
begin
  return TRIM(',' from p_comma_sep_list1 ||','|| p_comma_sep_list2 );
end merge_lists;

-- If there is a prefab way to set posted items, I couldn't find it
procedure set_posted_items(
  p_arg_names      apex_application_global.vc_arr2, -- Untrusted
  p_arg_values     apex_application_global.vc_arr2, -- Untrusted
  p_items_expected varchar2) -- Comma separated list (eg. cascading LOV items)
is
  l_valid_items  apex_application_global.vc_arr2;
  l_arg_map      apex_application_global.vc_map;
  l_dummy        varchar2(32767);

  -- Convert comma separated list to loopable cursor
  cursor cur_expected_items is
    select regexp_substr (p_items_expected, '[^,]+', 1, rownum) name
    from   dual
    connect by level <= LENGTH(REGEXP_REPLACE(p_items_expected,'[^,]+'))+1;
  rec_expected_item cur_expected_items%ROWTYPE;
begin

  if p_items_expected is not null then
  
    -- Handle the arguments with extreme suspicion
    if p_arg_names.count != p_arg_values.count then
      raise_application_error(-20150, 'Posted item data mismatch');
    end if;
  
    -- Simplify the situation by converting args to vc_map
    for i in 1 .. p_arg_names.count loop
      l_arg_map(p_arg_names(i)) := p_arg_values(i);
    end loop;
    
    -- Use our cursor to build a vc_arr2 from comma separated list
    for rec_expected_item in cur_expected_items loop
      l_valid_items(cur_expected_items%ROWCOUNT) := rec_expected_item.name;
    end loop;
    
    -- Throw an error if we got unexpected number of items posted
    if p_arg_names.count != l_valid_items.count then
      raise_application_error(-20151, 'Invalid posted item data');
    end if;
    
    -- Final sanity check (with fun use of dbms_assert.noop)
    for i in 1 .. l_valid_items.count loop
      begin
        l_dummy := dbms_assert.noop(l_arg_map(l_valid_items(i)));
      exception when no_data_found then
        raise_application_error(-20152, 'Missing expected item data');
      end;
    end loop;
    
    -- Set the items
    for i in 1 .. l_valid_items.count loop
      apex_util.set_session_state(
        p_name => dbms_assert.simple_sql_name(l_valid_items(i)),
        p_value => l_arg_map(l_valid_items(i)));
    end loop;
    
  end if;
end;


----------------- Render function ----------------------
function render_item (
  p_item                in apex_plugin.t_page_item,
  p_plugin              in apex_plugin.t_plugin,
  p_value               in varchar2,
  p_is_readonly         in boolean,
  p_is_printer_friendly in boolean )
return apex_plugin.t_page_item_render_result is
  cl_id_suffix         constant varchar2(10) := '.DISPLAY';
  l_min_length         number;
  l_result_set         apex_plugin_util.t_column_value_list;
  l_display_value      varchar2(32767) := null;
  l_return_value       varchar2(32767) := null;
  l_dom_name           varchar2(10); -- Internal APEX form element name
  l_result             apex_plugin.t_page_item_render_result;
begin
  ----------------- INITIALISE ALL THE THINGS ----------------------

  -- Enable debugging as required
  if apex_application.g_debug then
    apex_plugin_util.debug_page_item (
      p_plugin              => p_plugin,
      p_page_item           => p_item,
      p_value               => p_value,
      p_is_readonly         => p_is_readonly,
      p_is_printer_friendly => p_is_printer_friendly );
  end if;
  
  -- Assign variables based on plugin attributes etc.
  l_min_length := TO_NUMBER(NVL(p_item.attribute_02,'0'));
  l_dom_name := apex_plugin.get_input_name_for_page_item(false);

  -- Fetch and sanitise display/return values to be used in HTML output
  l_return_value := v(p_item.name);
  if l_return_value is not null then
  
    l_display_value := htf.escape_sc( apex_plugin_util.get_display_data(
      p_sql_statement     => p_item.lov_definition,
      p_min_columns       => 2,
      p_max_columns       => 2,
      p_component_name    => p_item.name,
      p_display_column_no => 1,
      p_search_column_no  => 2,
      p_search_string     => l_return_value,
      p_display_extra     => true,
      p_support_legacy_lov => true));
    
    l_return_value := htf.escape_sc(l_return_value);
  end if;

  ----------------- INCLUDE JAVASCRIPT/CSS/IMAGES ----------------------
  -- Depends on APEX 4.x bundled jquery.ui.autocomplete 1.8
  -- http://jqueryui.com/demos/autocomplete/
  --
  -- Note the identifiers to ensure these are only included once
  --   p_name for files
  --   p_key for inline blocks

  apex_javascript.add_library (
    p_name => 'jquery.ui.autocomplete.min', 
    p_directory => apex_application.g_image_prefix||
      'libraries/jquery-ui/1.8/ui/minified/', 
    p_version => null ) ;

  apex_css.add_file ( 
    p_name => 'jquery-ui', 
    p_directory => apex_application.g_image_prefix||
      'libraries/jquery-ui/1.8/themes/base/', 
    p_version => null ) ;

  -- Include global javascript object lovFriendlyAutocomplete
  apex_javascript.add_library (
    p_name => 'lov-friendly-autocomplete_apex-plugin', 
    p_directory => p_plugin.file_prefix, 
    p_version => null ) ;

  -- WORKAROUND: override apex.widget.autocomplete to display an error message
  apex_javascript.add_inline_code ( p_code =>
    'apex.widget.autocomplete = function(pSelector, pData, pOptions) {' ||
      'alert([' ||
        '"LOV Friendly Autocomplete plugin: incompatibility detected!",' ||
        '"",' ||
        '"The default APEX Autocomplete appears to conflict with LOV Friendly Autocomplete.",' ||
        '"Please do not attempt to use both item types on the same page."' ||
      '].join("\n"));' ||
    '}',
    p_key => 'lov-friendly-autocomplete-incompatibility');

  -- Render some custom CSS inline (allows the use of &IMAGE_PREFIX.)
  apex_css.add ( p_css =>
    '.lov-friendly-autocomplete-error {'||
        'background: pink url(''&IMAGE_PREFIX.ws/redx.gif'') right center no-repeat'||
    '}',
    p_key => 'lov-friendly-autocomplete-error');

  ----------------- RENDER HTML ----------------------  
  -- Where HTML output is minimal, the following rendering code style with a single
  -- htp.prn per tag/node is good practice for both efficiency and maintainability
  --
  -- For larger blocks of HTML, consider using mnemonic replacement templates
  --
  -- Use supplied APEX functions to assist in correctly rendering output
  -- always ensure user entered data has been sanitised

  if (not p_is_readonly and not p_is_printer_friendly) then

    -- Render display element
    htp.prn('<input type="text" '||
              'id="'|| p_item.name||cl_id_suffix ||'" '||
              'value="'|| l_display_value ||'" '||
              'size="'|| p_item.element_width ||'" '||
              'maxlength="'|| p_item.element_max_length ||'" '||
              COALESCE(p_item.element_attributes, 'class="text_field"')||' '||
              'autocomplete="off" />');

    -- Render return element
    htp.prn('<input type="hidden" '||
              'id="'|| p_item.name ||'" '||
              'value="'|| l_return_value ||'" '||
              'name="'|| l_dom_name ||'" />');

    -- Render lovFriendlyAutocomplete.attach() function call
    apex_javascript.add_inline_code ( p_code =>
      'apex.jQuery(document).ready(function(){'||
        'lovFriendlyAutocomplete.attach('||
        
          apex_javascript.add_value(
            -- returnSelector =>
            '#'||p_item.name ) ||
            
          -- Colons or periods in display item id avoids any conflict with APEX items
          -- however, they must be escaped for use as jQuery selectors
          apex_javascript.add_value(
            -- displaySelector =>
            '#'||p_item.name||REGEXP_REPLACE(cl_id_suffix,'([:.])','\\\1') ) ||
            
          apex_javascript.add_value(
            -- ajaxId =>
            apex_plugin.get_ajax_identifier ) ||
            
          apex_javascript.add_value(
            -- minLength =>
            l_min_length ) ||
            
          apex_javascript.add_value(
            -- parentSelector =>
            apex_plugin_util.page_item_names_to_jquery(
              p_item.lov_cascade_parent_items)) ||
              
          apex_javascript.add_value(
            -- submitSelector =>
            apex_plugin_util.page_item_names_to_jquery(
              merge_lists(p_item.lov_cascade_parent_items,
                          p_item.ajax_items_to_submit)),
            false ) || -- trailing comma false for last entry
        ');'||
      '});');
    -- Omitting p_key will create one of these inline blocks for every instance
    
  else -- Readonly mode
  
    -- render display element
    htp.prn('<span type="text" '||
              'id="'|| p_item.name||cl_id_suffix ||'" '||
              COALESCE(p_item.element_attributes, 'class="display_only"')||'>');
    htp.prn(  l_display_value );
    htp.prn('</span>');
    
    -- render return element
    htp.prn('<input type="hidden" '||
              'id="'|| p_item.name||'" '||
              'value="'|| l_return_value ||'" '||
              'name="'|| l_dom_name||'" '||
            '/>');

  end if;

  l_result.is_navigable := (p_is_readonly = false);
  l_result.navigable_dom_id := p_item.name||cl_id_suffix;
  
  return l_result;
end render_item;


----------------- Ajax callback ----------------------
function autocomplete_lov_json (
  p_item   in apex_plugin.t_page_item,
  p_plugin in apex_plugin.t_plugin )
return apex_plugin.t_page_item_ajax_result is
  l_search           varchar2(32767) := apex_application.g_x01; -- search parameter
  l_arg_names        apex_application_global.vc_arr2 := apex_application.g_arg_names;
  l_arg_values       apex_application_global.vc_arr2 := apex_application.g_arg_values;
  l_submit_items     varchar2(32767) := merge_lists(p_item.lov_cascade_parent_items,
                                                    p_item.ajax_items_to_submit);
  l_max_rows         number;
  l_min_length       number;
  l_search_type      varchar2(50);
  l_sql_handler      apex_plugin_util.t_sql_handler;  
  l_result_set       apex_plugin_util.t_column_value_list;
  l_count            number;
  l_result           apex_plugin.t_page_item_ajax_result;
  
  -- Catch bug affecting APEX 4.0-4.1 in APEX_PLUGIN_UTIL.PREPARE_QUERY
  IDENTIFIER_TOO_LONG  EXCEPTION;
  PRAGMA EXCEPTION_INIT(IDENTIFIER_TOO_LONG, -00972);
begin
  -- Plugin attributes
  l_max_rows    := TO_NUMBER(NVL(p_item.attribute_01,'10'));
  l_min_length  := TO_NUMBER(NVL(p_item.attribute_02,'1'));
  l_search_type := p_item.attribute_03; -- "Case Sensitivity" attribute

  if LENGTH(l_search) >= l_min_length then
    -- Set items submitted for cascading LOV
    set_posted_items(l_arg_names, l_arg_values, l_submit_items);
    
    -- Perform the LOV query (can trigger IDENTIFIER_TOO_LONG)
    l_result_set := apex_plugin_util.get_data (
      p_sql_statement    => p_item.lov_definition,
      p_min_columns      => 2,
      p_max_columns      => 2,
      p_component_name   => p_item.name,
      p_search_type      => l_search_type,
      p_search_column_no => 1,
      p_search_string    => UPPER(l_search),
      p_first_row        => null,
      p_max_rows         => l_max_rows);
    
    l_count := l_result_set(1).count;
  else
    -- Search string does not meet the minimum required characters
    l_count := 0;
  end if;

  -- Render results as jQuery UI Autocomplete compatible JSON
  apex_plugin_util.print_json_http_header;
  
  htp.prn('[');
  if l_count > 0 then
    for i in 1 .. l_count-1 loop
      htp.prn('{'||
        apex_javascript.add_attribute('id',   htf.escape_sc(l_result_set(2)(i))) ||
        apex_javascript.add_attribute('value',htf.escape_sc(l_result_set(1)(i)),true,false) ||
      '},');
    end loop;
    -- Render last row without the trailing comma
    htp.prn('{'||
      apex_javascript.add_attribute('id',   htf.escape_sc(l_result_set(2)(l_count))) ||
      apex_javascript.add_attribute('value',htf.escape_sc(l_result_set(1)(l_count)),true,false) ||
    '}');
  end if;
  htp.prn(']');
  
  return l_result;
exception when IDENTIFIER_TOO_LONG then
  htp.p('IDENTIFIER_TOO_LONG Error: Check your LOV query (use standard column aliases d,r)');
  return l_result;
end autocomplete_lov_json;