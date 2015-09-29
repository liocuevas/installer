Installer
===========

# Install
-----------
## Clone this repo (~/)
````````````````````````````````````````````````````````````````````````````````````````````
cd ~ && git clone git@github.com:liocuevas/installer.git
````````````````````````````````````````````````````````````````````````````````````````````
## Install dependencies
``````````````````````````````````````````````
cd installer && bundle install
``````````````````````````````````````````````
## Updating the application
### Run:
````````````````````````````````````````
cd ~/installer && git pull
````````````````````````````````````````

# Running the application
----------------------------------
## Go to the application directory, then:
### To install a website without database run:
````````````````````````````````````````````````
./migrations.rb [REPOSITORY URL]
````````````````````````````````````````````````
### To install a wordpress website run:
```````````````````````````````````````````````````````````````````````
./migrations.rb --type wordpress [REPOSITORY URL]
```````````````````````````````````````````````````````````````````````
### To install a website with custom database file run:
````````````````````````````````````````````````````````````````
./migrations.rb --type lamp [REPOSITORY URL]
````````````````````````````````````````````````````````````````
### To unninstall a website run:
```````````````````````````````````````````````````````````````
./migrations.rb --unninstall [REPOSITORY URL]
```````````````````````````````````````````````````````````````

# Edit your hosts file
----------------------------------

## Windows
Execute as administrator the program Notepad, then open the file
C:\system32\drivers\etc\hosts
(if you are not allowed to see the file, choose show all types *)
Then add a line at the end of the file
```````````````````````````````````````````````````````````````
127.0.0.1 [websitename].dev
```````````````````````````````````````````````````````````````
## Linux
Add a line at the end of the file /etc/hosts
```````````````````````````````````````````````````````````````
127.0.0.1 [websitename].dev
```````````````````````````````````````````````````````````````
