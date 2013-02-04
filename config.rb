# -------------------------------------------------------------
# --  CONFIGURATION FOR YOUR SCRIPT ---------------------------

key='[YOUR KEY]'
# This is your Zotero access key. You need to get one from Zotero.org so you can remotely access your library via this script
# https://www.zotero.org/settings/keys
userid='[YOUR USER ID]'
# This is your Zotero userID. You can also find it at the /settings/keys link above 
basepath='[PATH TO THIS FOLDER]/' 
# the path to the location of this script
# if you are not sure, open Utilities/Terminal, and drag the folder with this script into the window
# make sure you add the trailing '/'
local=basepath+"keys.txt"
# local list of your Zotero items keys. If you empty that file, it will reimport your entire library
newDataFile=basepath+"new.txt"
# this file is used to temporarily store new Zotero entries that the AppleScript will import into DevonThink
lastUpdateFile=basepath+'lastupdate.txt'
# this notes the time you last synced. A future version of this script may use this for more efficient check of changes
progressFile=basepath+'info.txt'
# this is the "progress" file which is periodically updated as data is downloaded and can be used by the applescript to
# update the user on the progress of the sync, especially when there are a lot of entries to grab
collectionSync=""
# By default, this script will import *all* of your Zotero items. If, instead you wish to only sync a single collection
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