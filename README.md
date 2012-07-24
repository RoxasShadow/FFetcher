FFetcher
=========

FFetcher is a backup utility for Forumfree and Forumcommunity platforms.

Just give the URL of a section of the forum and it will fetch, organize and backup all the topics present there.
You can give a file with some URLs for each line too. Lines don't start with 'http' are considered comments and will not be fetched. 

```
[sudo/rvm] gem install nokogiri
[sudo/rvm] gem install htmlentities
ruby ffetcher.rb -h
ruby ffetcher.rb --section "http://*******"forumcommunity.net/?f=*******"
ruby ffetcher.rb --file    "urls.txt"
```
