FFetcher
=========

FFetcher is a backup utility for Forumfree and Forumcommunity platforms.

Just give the URL of a section of the forum and it will fetch, organize and backup all the topics present there.

You can give a file with some URLs for each line too.

Lines don't start with 'http' are considered comments and will not be fetched. 

```
[sudo/rvm] gem install nokogiri
[sudo/rvm] gem install htmlentities
ruby ffetcher.rb -h
ruby ffetcher.rb --section "http://*******"forumcommunity.net/?f=*******"
ruby ffetcher.rb --file    "urls.txt"
```


Windows user, please, the way to run Ruby is not hard. Really.

Download the latest RubyInstaller from http://rubyinstaller.org and install it ticking all the box.

So run the Command Prompt and do

```
gem install nokogiri
gem install htmlentities
cd PATH_WHERE_IS_PLACED_FFETCHER
ruby ffetcher.rb -h
ruby ffetcher.rb --section "http://*******"forumcommunity.net/?f=*******"
ruby ffetcher.rb --file    "urls.txt"
```