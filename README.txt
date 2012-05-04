Text Field Autocomplete - LOV Friendly, Version 1.6
===================================================
Intended to be a fully functional replacement for "Text Field with autocomplete" item type extended to work with standard LOV. Just as useful both as a page item type as well as an introduction to plugin development by example.

See ADDITIONAL DETAILS for developer notes.

TABLE OF CONTENTS
=================

* Installation and Update
* Advanced Installation
* How to use
* Additional Details
* FAQ
* Uninstall
* Credits, License and Terms of Use
* Contact and Support
* Change Log


INSTALLATION AND UPDATE
=======================
1. Ensure you are running Oracle APEX version 4.0 or higher
2. Unzip and extract all files
2. Access your target Workspace
3. Select the Application Builder
4. Select the Application where you wish to import the plug-in 
   (plug-ins belong to an application, not a workspace)
5. Access Shared Components > Plug-Ins
6. Click [Import >]
7. Browse and locate the installer file, lov-friendly-autocomplete.sql
8. Complete the wizard

If the plug-in already exists in that application, you will need to confirm that you 
want to replace it.  Also, once imported, this plug-in can be installed into additional
applications within the same workspace.  Simply navigate to the Export Repository 
(Export > Export Repository), click Install, and then select the target application.
Once the install file is no longer needed, it can be removed from the Export Repository.


ADVANCED INSTALLATION
=====================
1. Follow the steps in INSTALLATION AND UPDATE
2. Copy the files of the directory "server" to the /images/plugins/lov-friendly-autocomplete
   or any other directory on the web server
3. Set the "File Prefix" attribute of the plug-in to #IMAGE_PREFIX#plugins/lov-friendly-autocomplete/

This will provide better performance, because the static files will be served by the web server
instead of reading them each time from the database.


HOW TO USE
==========
1. Install the plug-in (see INSTALLATION AND UPDATE)
2. Create a new page item
3. Pick "Plug-Ins" as type
4. Select the plug-in "Text Field Autocomplete - LOV Friendly"
5. Follow the wizard and use Item Level Help to get more information about the
   purpose and usage of the different settings.

Note that you can also update existing items to use this new item-type, once installed.


ADDITIONAL DETAILS
==================
Known issue #1: Unfortunately this plugin actually conflicts with the standard "Text Field with autocomplete" item type. You can not use both on the same page. Attempting to do so should disable both and display an alert box warning the developer.

Known issue #2: It seems there is a bug in APEX_PLUGIN_UTIL that effectively prevents LOV's containing long concatenated columns unless using a column alias. Any more than 30 character identifier and the results wont get returned.

The control will turn pink if there is a problem. Further details will be displayed in an alert box in DUBUG mode or otherwise by double clicking on the control.

To keep the control simple, there is no "Escape Output" option on this item (output is always escaped). Same goes for "LOV Display NULL", that's another feature left out intentionally as it seemed only to complicate things and not really add any necessary functionality (makes more sense on something like a select list, but not here). There are currently no plans to add these features.

Encrypt Session State is really the only other thing missing that I'd consider adding if I ever have a need to use it. Other than that, the rest of the options not yet mentioned seem irrelevant for this item type.


FAQ
===
* Q: Does this work with Cascading LOV
  A: Yes

* Q: Can I use this along with the standard "Text Field with autocomplete" item type on the same page?
  A: Unfortunately not, attempting to do so will disable both and display an error (see ADDITIONAL DETAILS section)


UNINSTALL
=========
To completely remove the plug-in:

1. Access the plug-in under Shared Components > Plug-Ins
2. Click [Delete]
   Note: If the [Delete] button doesn't show that indicates the plug-in is in use within the
         application.  Click on 'Utilization' under 'Tasks' to see where it is used.


CREDITS, LICENSE AND TERMS OF USE
=================================
This plugin is distributed as open-source under the terms of the MIT Licence

Copyright (c) 2012 Sam Hall, Charles Darwin University. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.


CONTACT AND SUPPORT
===================
Sam Hall
https://github.com/CaptEgg/lov-friendly-autocomplete

Please use above GitHub repository issues register to report any bugs or issues with this plugin.


CHANGE LOG
==========
v1.6 (May the 4th)
-) Be with you

