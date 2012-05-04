/* 
 * "Text Field Autocomplete - LOV Friendly" Javascript Component
 * Version 1.6
 * Oracle Application Express, Item type plugin
 *
 * This plugin is distributed as open-source under the terms of the MIT Licence
 * 
 * Copyright (c) 2012 Sam Hall, Charles Darwin University. All rights reserved.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy 
 * of this software and associated documentation files (the "Software"), to deal 
 * in the Software without restriction, including without limitation the rights 
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 * copies of the Software, and to permit persons to whom the Software is 
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all 
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
 * SOFTWARE.
*/

var lovFriendlyAutocomplete = new function(){

  // The glue between jQuery UI Autocomplete and the ajax callback
  this.attach=function( returnSelector,  // Return item selector
                        displaySelector, // Display item selector
                        ajaxId,          // APEX plugin ajax id
                        minLength,       // Minimum characters
                        parentSelector,  // Cascading LOV parent(s) selector
                        submitSelector){ // Selector of all items to submit
    
    // Enable autocomplete on the display item
    $(displaySelector).autocomplete({

      // Minimum number of characters to trigger autocomplete
      minLength: minLength,

      // When user selects an option
      select: function( event, ui ) {
        $(returnSelector)
          .val(ui.item.id) // Save the "id" to the return item
          .trigger('change'); // onchange event ( for cascading LOV )
        
        // Clear error feedback
        $(displaySelector)
          .removeClass("lov-friendly-autocomplete-error")
          .unbind('dblclick');
      },

      // Perform a regular APEX ajax request and forward the
      // response to jQuery UI Autocomplete for use as the list
      source: function( request, response ) {
        apex.jQuery.ajax({
          dataType: "json",
          type: "post",
          url: "wwv_flow.show",
          traditional: true,
          data: {
            p_request: "NATIVE="+ajaxId,
            p_flow_id: $("#pFlowId").val(),
            p_flow_step_id: $("#pFlowStepId").val(),
            p_instance: $("#pInstance").val(),
            x01: $(displaySelector).val(),
            p_arg_names:  $(submitSelector) // Item names
                            .map(function () { return $(this).attr("id"); }).get(),
            p_arg_values: $(submitSelector) // Item values
                            .map(function () { return $(this).val(); }).get()},
          success: response, // Response handled by jQuery UI Autocomplete
          error: function (xhr, ajaxOptions, thrownError) {
            
            // Visual feedback that something went wrong
            $(displaySelector)
              .removeClass("ui-autocomplete-loading")
              .addClass("lov-friendly-autocomplete-error");
            
            var dbgMsg = [
                "Debug Message: Invalid JSON",
                "",
                "XMLHttpRequest Status: "+xhr.statusText,
                "Thrown Error: "+thrownError,
                "Response: ",
                xhr.responseText
              ].join("\n");
            
            // Popup error in debug mode
            debug = $('#pdebug').val() == 'YES' ? true : false;
            if (debug) { alert(dbgMsg); }
            
            // Or by double clicking the control
            $(displaySelector)
              .unbind('dblclick')
              .dblclick(function() { alert(dbgMsg); });
          }
        }); // end apex.jQuery.ajax
      }
    }); // end $(displaySelector).autocomplete

    // Bind change event to parent item(s) for cascading LOV
    if (parentSelector != "") {
      $(parentSelector).change( function () {
        // Clear both return and display
        $(returnSelector).val("");
        $(displaySelector).val("");
      });
    }
  }
}

