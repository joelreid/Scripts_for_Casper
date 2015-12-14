# Asset Tag to Computer Name

**Untested**. Adapted quickly from a script that did the opposite. Test test test, then use at your own risk.

Note: you must edit some config details in the script.  
You should also probably run this script 'before' and do an Update Inventory in the same policy, so Casper is informed of the new name.

Fetches the client Mac's Asset Tag as set in the JSS,  
then sets the Mac's Sharing Name (ComputerName/HostName/LocalHostName),  
making it match the Asset Tag with optional prefix/suffix.

