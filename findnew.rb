#!/usr/bin/ruby

# Some users may have to change the path to Ruby above?

require 'open-uri'
require "rexml/document"
include REXML
# These are, I believe, included as part of standard Ruby install?


# Some logging if you run the script directly on command line for debugging
$logging=false

# -------------------------------------------------------------
# --  CONFIGURATION FOR YOUR SCRIPT ---------------------------

key='[YOUR KEY]'
# This is your Zotero access key. You need to get one from Zotero.org so you can remotely access your library via this script
# https://www.zotero.org/settings/keys
userid='[YOUR USER ID]'
# This is your Zotero userID. You can also find it at the /settings/keys link above 
basepath='[PATH TO ZOTDEVON]' 
# the path to the location of this script
# if you are not sure, open Utilities/Terminal, and drag the folder with this script into the window
# make sure you add the trailing '/'
local=basepath+"keys.txt"
# You can probably just leave this alone
# local list of your Zotero items keys. If you empty that file, it will reimport your entire library
newDataFile=basepath+"new.txt"
# You can probably just leave this alone
# this file is used to temporarily store new Zotero entries that the AppleScript will import into DevonThink
lastUpdateFile=basepath+'lastupdate.txt'
# You can probably just leave this alone
# this notes the time you last synced. A future version of this script may use this for more efficient check of changes
progressFile=basepath+'info.txt'
# You can probably just leave this alone
# this is the "progress" file which is periodically updated as data is downloaded and can be used by the applescript to
# update the user on the progress of the sync, especially when there are a lot of entries to grab
collectionSync=""
# By default, this script will import *all* of your Zotero items. If, instead, you wish to only sync a single collection
# from your Zotero collection, then put the ID of the collection. To find the collection id, open your Zotero library
# online, click on the desired collection and look at the URL. You should find the collection id at the end:
# https://www.zotero.org/[USER]/items/collectionKey/[COLLECTION ID]
#
# IMPORTANT NOTE: If you decide to sync only a single collection, rather than your whole library, this script will not
# as currently written, create references to all the attachments or notes attached to that item. The reason for this is
# this script looks for all keys in the library or in the collection. Attachmemnts are listed in the list of all keys
# for the library, but they are not listed when the API looks for all members of a collection. Hopefully someone else can
# add the ability to recursively add all children of collection items to the loop so they will be added too.

# -- END CONFIGURATION ----------------------------------------
# -------------------------------------------------------------


if collectionSync!=""
  # We are just getting items from a single collection:
  baseuri="https://api.zotero.org/users/#{userid}/collections/#{collectionSync}/items"
else
  # We are grabbing all items
  baseuri="https://api.zotero.org/users/#{userid}/items"
end

itemuri="https://api.zotero.org/users/#{userid}/items"
keyuri="?key=#{key}&format=keys&order=dateModified"

# METHODS ----------------------------------------

def writeFile(writeData,wFile)
  File.open(wFile,'w') {|f| f.write(writeData)}
end

def readFile(rFile)
  dataRead=File.open(rFile,'r') {|f| f.read}
  return dataRead
end

def log(logMessage)
  if logMessage
    if $logging 
      puts "LOG: "+logMessage
    end
  end
end

def checkError(errorMessage)
  # Add explanation for some errors
  if errorMessage=="403 Forbidden"
    log("The forbidden message often appears because your user id or key are invalid.")
  elsif errorMessage=="500 Internal Server Error"
    log("This error can happen if your collection id is invalid.")
  end
end

# END METHODS ----------------------------------

writeFile("0/0",progressFile)
# set the progress file to nothing
# this file is used to pass on progress of the script to the applescript that will run this ruby script


# GET LIST OF ITEMS FROM SERVER AND LOCAL ------
  begin
    serverKeyList=open(baseuri+keyuri) {|f| f.read}
  rescue OpenURI::HTTPError => errorMsg
    log("Error loading list of keys on server: #{errorMsg}")
    checkError(errorMsg.message)
    exit
  end

  if serverKeyList=="An error occurred"
    log("Zotero returned an error. Did you enter the correct key, user id, and collection id?")
    exit
  end
  # Grabs a list of all the IDs for items in the Zotero database, by datemodified

  if File.exists?(local)
    localKeyList=readFile(local)
  else
    localKeyList=""
  end
  # Get the local list of IDs for Zotero items

  serverKeyArray=serverKeyList.split("\n")
  # put all the IDs obtained from the server into an array
  log("SERVER KEY LIST ITEM COUNT: "+serverKeyArray.count.to_s)
  localKeyArray=localKeyList.split("\n")
  # put all the IDs obtained from the local list of keys into an array
  log("LOCAL FILE ITEM COUNT: "+localKeyArray.count.to_s)

# FIND MISSING ITEMS ---------------------------

  missingItems=serverKeyArray-localKeyArray
  # determine what IDs are in the online Zotero database not in the local key list
  
  writeFile("0/#{missingItems.count}",progressFile)
  log("count of missing items: "+missingItems.count.to_s)

  # missingitems.each {|a| puts a}

  missingItemData=""
  mycount=0
  foundcount=0
  
  # now step through each of the items that were not in the local key list
  # and download the info for it
  missingItems.each {|item|
    mycount+=1
    log("#{mycount}/#{missingItems.count}")
    writeFile("#{mycount}/#{missingItems.count}",progressFile)
    # record the progress made in downloading data to give feedback to applescript
    # now grab the data for each missing item:
    begin
      itemData=open(itemuri+"/"+item+"?key=#{key}&format=atom") {|f| f.read}
    rescue OpenURI::HTTPError => errorMsg
      log("Error loading data from item number #{mycount} on server: #{errorMsg}")
      checkError(errorMsg.message)
      exit
    end
    xmlData=Document.new itemData
  
    root=xmlData.root

    entries=root.elements.to_a("//entry")
    
    newType=entries[0].elements.to_a("zapi:itemType")[0].text 
    #get the item type for new item
    # this will return things like journalArticle, book, attachment, note
    if newType
      log(newType)
      foundcount+=1
      newTitle=entries[0].elements.to_a("title")[0].text
      log(newTitle)
      if entries[0].elements.to_a("zapi:creatorSummary")[0]
        newCreatorSummary=entries[0].elements.to_a("zapi:creatorSummary")[0].text
      else
        newCreatorSummary=""
      end
      log(newCreatorSummary)
      # this will return the last name of the author, if it is available
      newID=entries[0].elements.to_a("zapi:key")[0].text
      newUpdated=entries[0].elements.to_a("updated")[0].text
      
      newUp=""
      newAtType=""
      newURL=""
      if newType=="attachment" || newType=="note"
        # For attachments and notes, extract the Key of the item it is attached to
        newUp=entries[0].elements.to_a("link")[1].attributes["href"].gsub("https://api.zotero.org/users/#{userid}/items/",'')
        if newType=="attachment"
          # Find out what kind of attachment it is 
          newAtType=entries[0].elements["content"].elements["div"].elements["table"].elements["tr[@class='mimeType']"].elements["td"].text
        end
      end

      # Grab the link for URL link attachments and webpages
      # Perhaps future version grabs link for all items? Journal articles etc. often link to online database
      if newAtType=="text/html" || newType=="webpage"
        newURL=entries[0].elements["content"].elements["div"].elements["table"].elements["tr[@class='url']"].elements["td"].text
      end
      
      # Put it all together in tab delimited form to put in the new file for the pass-off to the AppleScript
      # 1. TYPE 2. ID 3. TITLE  4. CREATOR SUMMARY  5. PARENT ID  6. ATTACHMENT TYPE  7. URL
      missingItemData+=newType+"\t"+newID+"\t"+newTitle+"\t"+newCreatorSummary+"\t"+newUp+"\t"+newAtType+"\t"+newURL+"\n"
        
    else
        puts "ERROR: No itemtype found for entry."
    end  
  }
  
  writeFile("Done/#{foundcount}",progressFile)
  writeFile(missingItemData.chomp,newDataFile)
  # We are done getting data for missing items, update the key list
  writeFile(serverKeyList,local)
  # Register the time for this sync
  writeFile(Time.now.to_i,lastUpdateFile)


