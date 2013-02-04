--Location of this script and its work files:
set workFolder to "/Users/[your user]/[path to ZotDevon]"
--The name of the group in DevonThink where you wish to create folders/notes:
set groupName to "/Sources/"
--Name of file containing new entries to add:
set newFile to "new.txt"
--set the formate you want to have for the title
-- 1. Author - Title
-- 2. Title - Author
set formatOrder to 1

--if you are debugging or have run the findnew.rb script already, set skipscript to one
--to jump directly to the DevonThink import process. Leave as 0 otherwise.
set skipScript to 0

on split(someText, delimiter)
	set AppleScript's text item delimiters to delimiter
	set someText to someText's text items
	set AppleScript's text item delimiters to {""} --> restore delimiters to default value
	return someText
end split

on readFile(filePath)
	set progressFile to ((POSIX file filePath) as string)
	try
		set fileContents to read file progressFile as Çclass utf8È
	on error error_message number error_number
		if the error_number is not -128 then
			if error_number is -39 then
				--I think this happens when they are writing and reading at same timeÉtry again
				delay 2
				set fileContents to read file progressFile as Çclass utf8È
			end if
		end if
	end try
	return fileContents
end readFile

on existsFile(filePath)
	tell application "Finder" to set fileExists to exists my POSIX file filePath
	return fileExists
end existsFile

on formatTitle(dataArray, type)
	set titleData to item 3 of dataArray
	if titleData is "" then
		set titleData to "Untitled" & item 2 of dataArray
	end if
	set authorData to item 4 of dataArray
	if type is 1 then
		set returnData to titleData
		if authorData is not "" then
			set returnData to authorData & " - " & titleData
		end if
		return cleanTitle(returnData)
	else
		set returnData to titleData
		if authorData is not "" then
			set returnData to titleData & " - " & authorData
		end if
		return cleanTitle(returnData)
	end if
end formatTitle

on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars

on cleanTitle(theTitle)
	log "Pre: " & theTitle
	set returnData to replace_chars(theTitle, "/", "-")
	log "After: " & returnData
	return returnData
end cleanTitle

if skipScript is not 1 then
	--check to see if there is a key and udpate file if there isn't then make an empty one
	if existsFile(workFolder & "keys.txt") is false then
		set a to do shell script "touch '" & workFolder & "keys.txt'"
	end if
	if existsFile(workFolder & "lastupdate.txt") is false then
		set a to do shell script "touch '" & workFolder & "lastupdate.txt'"
	end if
	
	--check to see if there are leftover backup files and use them if there are
	if existsFile(workFolder & "keys_backup.txt") or existsFile(workFolder & "new.txt") then
		set myanswer to display dialog "The last sync did not complete. Do you wish to cancel, look for a backup of pre-import list of entries and ignore any downloaded entries, or first just import already downloaded items and cleanup (You can sync again afterwards)." buttons {"Cancel", "Look for Backup", "Import Downloaded Entries"} default button 3 cancel button 1
		if the button returned of myanswer is "Look for Backup" then
			if existsFile(workFolder & "keys_backup.txt") then
				set a to do shell script "mv '" & workFolder & "keys_backup.txt' '" & workFolder & "keys.txt'"
			end if
			if existsFile(workFolder & "lastupdate.txt") then
				set b to do shell script "mv '" & workFolder & "lastupdate_backup.txt' '" & workFolder & "lastupdate.txt'"
			end if
		else if the button returned of myanswer is "Import Downloaded Entries" then
			if existsFile(workFolder & "keys_backup.txt") then
				set a to do shell script "rm '" & workFolder & "keys_backup.txt'"
			end if
			if existsFile(workFolder & "lastupdate_backup.txt") then
				set a to do shell script "rm '" & workFolder & "lastupdate_backup.txt'"
			end if
			set skipScript to 1
		end if
	end if
end if


if skipScript is not 1 then
	--make a copy of our list of database keys in case something goes wrong during sync
	set y to do shell script "cp '" & workFolder & "keys.txt' '" & workFolder & "keys_backup.txt'"
	set z to do shell script "cp '" & workFolder & "lastupdate.txt' '" & workFolder & "lastupdate_backup.txt'"
	
	--run ruby script to determine what IDs are missing
	set x to do shell script "'" & workFolder & "findnew.rb' &> /dev/null 2>&1 &"
	set startstat to split(readFile(workFolder & "info.txt"), "/")
	set totalitems to item 2 of startstat
	set abortmission to false
	
	tell application "ASObjC Runner"
		-- set up dialog and show it 
		reset progress
		set properties of progress window to {button title:"Cancel", button visible:true, message:"Checking for new items.", detail:"Looking for Zotero items not yet imported.", indeterminate:false, max value:10, current value:0}
		activate
		show progress
	end tell
	
	set isdone to false
	
	--with timeout of 60 seconds
	repeat while isdone is false
		set mystats to split(readFile(workFolder & "info.txt"), "/")
		log mystats
		tell application "ASObjC Runner"
			set currentitem to item 1 of mystats
			set totalitems to item 2 of mystats
			--reduce chance of annoying error as read/write happens at same time during large library import
			if totalitems < 200 then
				delay 2
			else if totalitems < 500 then
				delay 3
			else
				delay 6
			end if
			if currentitem = "Done" then
				exit repeat
			end if
			if totalitems > 0 then
				set properties of progress window to {detail:"Getting Data: " & currentitem & " of " & totalitems & ".", current value:currentitem, max value:totalitems}
			end if
			if button was pressed of progress window then
				set abortmission to true
				exit repeat
			end if
		end tell
	end repeat
	--end timeout
	--set progressMade to readProgress(workFolder)
	
	
	
	tell application "ASObjC Runner"
		activate
		if abortmission is true then
			set properties of progress window to {detail:"Operation cancelled. DevonThink database not modified."}
			delay 1
			tell application "ASObjC Runner" to hide progress
			error number -128
		else
			set properties of progress window to {detail:"Found " & totalitems & " new items including attachments and notes."}
		end if
	end tell
	
end if





--read the file with new entries to be added
set filetoread to workFolder & "new.txt"

if existsFile(filetoread) of me is false then
	--The "new.txt" file could not be found, so nothing to import
	display dialog "Could not find any downloaded entries. Nothing to import"
	error number -128
end if

set newEntries to readFile(filetoread) of me
--split it into separate lines
set entryList to split(newEntries, "
") of me

if the number of items in entryList < 1 then
	--There must be at least one entry to import
	display dialog "Could not find any downloaded entries. Nothing to import"
	error number -128
end if

--add all the attachments and notes last, extract them and add them to end
set normalList to {}
set endList to {}
log the number of items in entryList
tell application "ASObjC Runner"
	-- set up dialog and show it 
	reset progress
	set properties of progress window to {button title:"Cancel", button visible:true, message:"Extracting attachments.", detail:"Putting attachments and notes after all other items before importing into DEVONthink.", indeterminate:true}
	activate
	show progress
end tell
repeat with newEntry in entryList
	if newEntry is not "" and the number of words in newEntry > 1 then
		log newEntry
		if word 1 of newEntry is "attachment" or word 1 of newEntry is "note" then
			set endList to endList & {newEntry}
		else
			set normalList to normalList & {newEntry}
		end if
	end if
end repeat
set sortedList to normalList & endList

tell application id "com.devon-technologies.thinkpro2" to activate
--cycle through each new entry and add it to DevonThink
tell application "ASObjC Runner"
	-- set up dialog and show it 
	reset progress
	set properties of progress window to {button title:"Cancel", button visible:true, message:"Importing downloaded items into DEVONthink.", detail:"Looking for Zotero items not yet imported.", indeterminate:true}
	activate
	show progress
end tell
set mycount to 0
repeat with newEntry in sortedList
	set mycount to mycount + 1
	set entryData to split(newEntry, "	") of me
	log entryData
	set finalTitle to formatTitle(entryData, formatOrder) of me
	set entryType to item 1 of entryData
	set entryKey to item 2 of entryData
	set entryParent to item 5 of entryData
	set entryAtType to item 6 of entryData
	set entryURL to item 7 of entryData
	tell application "ASObjC Runner"
		set properties of progress window to {detail:"Adding item: " & mycount & " of " & the number of items in sortedList & ".", indeterminate:false, current value:mycount, max value:the number of items in sortedList}
		if button was pressed of progress window then
			set abortmission to true
			exit repeat
		end if
	end tell
	log finalTitle
	tell application id "com.devon-technologies.thinkpro2"
		try
			set theDatabase to current database
			if ((entryType is not "attachment") and (entryType is not "note")) then
				
				if not (exists record at groupName & finalTitle) then
					set theGroup to create location groupName & finalTitle in theDatabase
					set the comment of theGroup to entryKey
					if entryURL is not "" then
						set the URL of theGroup to entryURL
					end if
					set newRecord to create record with {name:finalTitle, type:rtf, rich text:finalTitle, URL:"zotero://select/item/0_" & entryKey} in theGroup
					try
						if entryType is "book" then
							set entryIcon to "treeitem-book.png"
						else if entryType is "thesis" then
							set entryIcon to "treeitem-thesis.png"
						else if entryType is "journalArticle" then
							set entryIcon to "treeitem-journalArticle.png"
						else if entryType is "newspaperArticle" then
							set entryIcon to "treeitem-newspaperArticle.png"
						else if entryType is "manuscript" then
							set entryIcon to "treeitem-manuscript.png"
						else if entryType is "case" then
							set entryIcon to "treeitem-case.png"
						else if entryType is "bookSection" then
							set entryIcon to "treeitem-bookSection.png"
						else if entryType is "document" then
							set entryIcon to "treeitem-attachment-file.png"
						else if entryType is "webpage" then
							set entryIcon to "treeitem-webpage.png"
						end if
						
						set iconPath to workFolder & "icons/" & entryIcon
						set thumbnail of theGroup to iconPath
					end try
				end if
			else
				--We should have passed all normal entries now so we can find them by the Key in the comment
				set parentRecordList to lookup records with comment entryParent in theDatabase
				--If one record with the parent key is found then let us add children to it
				if the number of items in parentRecordList is 1 then
					set parentRecord to item 1 of parentRecordList
					if not (exists record at path of parentRecord & "/" & finalTitle) then
						if entryAtType is not "text/html" then
							set myurl to "zotero://select/item/0_" & entryKey
						else
							set myurl to entryURL
						end if
						set newRecord to create record with {name:finalTitle, type:rtf, rich text:finalTitle, URL:myurl} in parentRecord
						
						try
							if entryAtType is "text/html" then
								set entryIcon to "treeitem-attachment-web-link.png"
							else if entryAtType is "application/pdf" then
								set entryIcon to "treeitem-attachment-pdf.png"
							end if
							if entryType is "note" then
								set entryIcon to "treeitem-note.png"
							end if
							
							set iconPath to workFolder & "icons/" & entryIcon
							set thumbnail of newRecord to iconPath
						end try
						
					end if
				end if
			end if
		on error error_message number error_number
			tell application "ASObjC Runner" to hide progress
			if the error_number is not -128 then display alert "DEVONthink Pro" message error_message as warning
		end try
	end tell
end repeat


tell application "ASObjC Runner"
	set properties of progress window to {detail:"Import complete. " & mycount & " entries or attachments added."}
	delay 2
	hide progress
end tell

--Now that import is complete, delete the "new.txt" file
if existsFile(workFolder & "new.txt") then
	set y to do shell script "mv '" & workFolder & "new.txt' '" & workFolder & "lastimport.txt'"
end if
--Delete the backup files too
if existsFile(workFolder & "keys_backup.txt") then
	set y to do shell script "rm '" & workFolder & "keys_backup.txt'"
end if
if existsFile(workFolder & "lastupdate_backup.txt") then
	set z to do shell script "rm '" & workFolder & "lastupdate_backup.txt'"
end if


