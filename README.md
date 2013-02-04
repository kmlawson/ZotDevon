ZotDevon
========

Script for one-way import of a Zotero library into DEVONthink. 

# What ZotDevon Does

1. Connects to your online Zotero library and downloads either a list of keys for all items in your library, or only items in a single collection determined by you.
2. It will compare this to a list of keys for already imported items.
3. For all missing items in the local list, ZotDevon will then:
4. Grab the title, creator summary (usually last name of author) of each item
5. If you are importing the whole library (instead of single collection) it will also grab title and url of attached files, links, and notes
6. ActivatesDEVONthink: In the currently active database, in a folder designated in the configuration, ZotDevon will then create a sub-folder for each imported item (with a Zotero thumbnail corresponding to the kind of item).
7. In each of these sub-folders ZotDevon will create an RTF file for you to take notes in.
8. If you have imported the entire library, references to attachments, links, and notes will also be added to the sub-folder. Each of these references will contain a "zotero://" link that opens the corresponding item in your Zotero library.

This script is not designed to replace your Zotero collection with the same data in DEVONthink. It was created primarily for those of us who want to use both tools together, maintaining Zotero as a citation manager and home for our PDFs, while using DEVONthink to organize our notes.

# What ZotDevon Does Not Currently Do

1. ZotDevon is one-way and can only add files not found in the local index file (keys.txt). It does not delete DEVONthink items that are no longer found in your Zotero database. It does not re-add items that were deleted in DEVONthink but which are still listed in the local index.
2. ZotDevon does not download and save a copy of attached PDFs or Note files in DEVONthink. When importing the whole library, it creates a simple text file that links to the corresponding item in your local Zotero library.
3. ZotDevon does not currently create attachment references if you only sync a single collection rather than the whole library. 
4. ZotDevon does not replicate your collections structure in DEVONthink. 
5. If you import a single collection it will not look in sub-folders for additional items.

# How to Install

Keep in mind this is an early release of this script. Please test it and offer feedback in the issues tab here so we can work out the bugs.

1. Install [ASObjC Runner](http://www.macosxautomation.com/applescript/apps/runner.html). Download and place it in your Applications folder. This is used to give you feedback on how the import process is going.
2. Download ZotDevon. [Download it Here](http://huginn.net/scripts/ZotDevon.zip)* 
3. Put the folder somewhere in your documents. Move only the ZotDevon.scpt file to your DEVONthink script folder. You can open this from the DEVONthink applescript menu -> Open Scripts Folder
4. Open the ZotDevon.scpt file in AppleScript Editor and configure the script for your machine. Tell it where you put the ZotDevon folder, what folder in DEVONthink you want to import items into, etc.
5. Login to your Zotero account and [request a key](https://www.zotero.org/settings/keys) so the script can access your library. While you are there, make a note of your "userID"
6. While you are at Zotero.org, if you want to import/sync only a single collection, navigate to the Zotero collection you wish to import and make a note of the collection ID at the end of the URL.
7. Now, back on your Mac, open the findnew.rb file in your ZotDevon folder using your favorite text editor (TextWrangler is free, TextEdit will work but don't make it rich text).
8. Configure the findnew.rb script by modifying the variables at the top. You will be asked to enter the key, the user ID, and if you only want to import a single collection rather than your whole library, the collection ID.
9. Make sure your Zotero database is synced with the server.
10. Back in DEVONthink, make sure the desired database is active, your internet connection is live, and select ZotDevon from the applescript menu. In tests, it takes under 3 hours the first time you import a Zotero library of 2500 items (with 5300 total database items when including attachments).

*The version here at GitHub saves the applescript as an applescript text file rather than a scpt file, so if you don't know how to convert it, it is easier just grab it from the link instead.

# How ZotDevon Could Be Improved

ZotDevon is free and open source. Improvements are welcome.

1. **ZotDevon is slow** - It takes a few minutes to import several hundred new items from a Zotero library, and several hours to import an entire library of several thousand items. An older import script I wrote imported items directly from the local sqlite database at a much faster rate. However, changes in Zotero over time made it hard to maintain this fragile method so I have imported directly from the Zotero Server API instead. The speed of ZotDevon could be *radically* improved if either: a) the Ruby findnew.rb script is rewritten to grab data from 50 items at a time, rather than one at a time. However, this will require a rethinking of the workflow and the checking of missing items. b) Or, the script could be rewritten to interface with the Zotero JavaScript API and communicate directly with the local installation of Zotero, rather than the Server API. 
2. **Add Support for Attachment References in Collection Sync** - Currently reference files only get created if you sync the entire library. All attachments are grabbed as keys when using the API on the whole library. Attachments are not listed as members when using the API on a specific collection. This could be overcome by changing the loop to grab data from all "children" of each item in a collection.
3. **Also Import Collection Structure** - ZotDevon could be improved by also grabbing the Zotero collection structure, reproducing this in DEVONthink and replicating each Zotero item into the appropriate folders. At the very least, it could handle subfolders when asked to sync a single collection.
4. **True One-Way Sync** - Currently ZotDevon doesn't look for or deal with deleted items. Nor does it update DEVONthink items to reflect changes in metadata in the titles and authors on the Zotero side. A true sync would look for and deal with changes in a careful manner.
5. **Add Option to Import Notes and PDFs** - Some users may not wish to keep the data in one place and wish instead to move a copy of all PDFs and Notes into DEVONthink. Providing this option would make ZotDevon into a true full import script. Notes in Zotero are in HTML format, but DEVONthink has a "get rich text" of applescript support which can essentially convert an HTML file into rich text. Support for this could be added when importing Notes.
6. **Add Formatted Bibliographic Entry** - ZotDevon could be improved to produce a nice formated bibliographic entry in a desired format in the notes file created for each entry in DEVONthink.
7. **Import Tags** - It would be nice if ZotDevon offered users the option of importing all tags from their Zotero items into DEVONthink. Important that this remain optional.
8. **Error Checking** - ZotDevon does not thoroughly check for errors and data integrity. In other words, the code could be improved in many places.

# Dealing with Problems

**The Import Failed and the Progess Window Won't Close**

Open Activity Monitor in your Utilities folder, search for ASOBjC Runner, and force quit it.

**I Want to Reimport Everything From Scratch**

Delete or move the imported folders in DEVONthink, and then empty the "keys.txt" file in the ZotDevon folder. Then run the import again.

**I See Weird Behavior After Canceling and Restarting ZotDevon**

Currently ZotDevon has an AppleScript which calls a Ruby script. When the AppleScript is cancelled before import is complete, the Ruby script findnew.rb continue to download the updates. The script should ideally be improved to keep track of the process number of the launched Ruby script and shut it down in event of cancellation. Until this is incorporated, you will need to either wait for the import script to complete of its own accord before restarting, or open Activity Monitor, search for Ruby and force quit the ruby script running. If there are multiple ruby scripts running on your computer, inspect the process to determine what is what. 

**How Do I Start Over If Something Goes Wrong?**

If there are problems with the import first try running the script again. It could be that the download from zotero.org failed for some reason and the script may have a partially downloaded copy of your database that it can start from again.

If you want to start completely over, delete the keys.txt, and if you see it, the new.txt and any _backup.txt files in your ZotDevon folder. Then run the script again.

