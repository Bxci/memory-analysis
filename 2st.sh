#!/bin/bash

HOME=$(pwd)
USER=$(whoami)
START=$(echo "script started on $(date)")

mkdir Forensics >/dev/null 2>&1
mkdir "$HOME"/Forensics/registry_dump >/dev/null 2>&1

function ROOT()
{
	if [ "$USER" == "root" ];then
	echo "you are root - continue"
	else
	echo "you are not running on root - EXITING!"
	exit
	fi
}
ROOT

function FILE()
{
	echo "Enter a full path of the file to carve the file:"
    read file

    if [ -e "$file" ] 
    then
        echo "File '$file' exists."
    else
        echo "file '$file' doesn't exist, Please try again."
        exit 1
    fi
}
FILE

function RUN()
{
	if [[ "$file" == *.mem ]]; then
	echo "The file can start with vol - continue"
	else
	echo "The file can't be running with Vol - EXITING!"
	exit 1
	fi
}
RUN

echo "Starting with the Deps we need to install"
sleep 2

function BULK()
{
	if which "bulk_extractor"> /dev/null 2>&1;
	then
	echo "bulk extractor is already installed!"
	sleep 2
else
	sudo apt-get install bulk-extractor -y
	echo "Bulk-extractor not installed.. INSTALLING!"
fi
}
BULK

function BIN()
{
	if which "binwalk"> /dev/null 2>&1;
	then
	echo "Binwalk is already installed!"
	sleep 2
else
	echo "binwalk is not installed! INTALLING!"
	sudo apt-get install binwalk -y
fi
}
BIN

function FORE()
{
	if which "foremost"> /dev/null 2>&1;
	then
	echo "foremost is already installed!"
	sleep 2
else
	echo "foremost is not installed! INSTALLING!"
	sudo apt-get install foremost
fi
}
FORE

function STRINGS()
{
	if which "strings"> /dev/null 2>&1;
	then
	echo "strings is already installed!"
	sleep 2
else
	echo "strings is not installed! INSTALLING!"
	sudo apt-get install strings
fi
}
STRINGS

cd Forensics

function VRFY_VOL()
{
	git clone https://github.com/Bxci/vol.git > /dev/null 2>&1
	cd vol
	chmod + ./volatility_2.5_linux_x64 > /dev/null 2>&1
	cd ..
}
VRFY_VOL


binwalk "$file" >> "$HOME"/Forensics/binwalk_output > /dev/null 2>&1
foremost "$file" >> "$HOME"/Forensics/foremost_output > /dev/null 2>&1
bulk_extractor "$file" -o "$HOME"/Forensics/bulk_output > /dev/null 2>&1

strings "$file" | grep -i passwords >> passwords_output.txt
strings "$file" | grep -i username >> usernames_output.txt
strings "$file" | grep -i .exe >> exe_output.txt


find "$HOME"/Forensics/bulk_output -type f -name "*.pcap" -exec stat --format="%s %n" {} \;
echo "Found Pcap FIle - IF EXE PASSWORDS, AND EMAILS EXISTED ON THAT MEM YOU GETTING NEW FILES WITH THE INFORMATION PRINTED IN!"
cd vol
PROFILE=$(./volatility_2.5_linux_x64 -f $file imageinfo | grep -i profile | awk '{print $4}' | sed 's/,//g')
RUNNING=$(./volatility_2.5_linux_x64 -f $file --profile=$PROFILE pslist)
echo "$RUNNING"
./volatility_2.5_linux_x64 -f $file --profile=$PROFILE connscan

./volatility_2.5_linux_x64 -f $file --profile=$PROFILE hivelist >/dev/null 2>&1
./volatility_2.5_linux_x64 -f $file --profile=$PROFILE dumpregistry -D "$HOME"/Forensics/registry_dump >/dev/null 2>&1

REPORT_FILE="$HOME/Report.txt"
echo "Number of Files Found:" $(find "$HOME/Forensics" | wc -l)

find "$HOME" -type f -exec du -h {} + >> "$REPORT_FILE"
echo "Reported File Exported to your PWD!"

echo "script ended at: $(date)"
echo "$START"
cd "$HOME"
pwd

zip -r BenCForensics.zip "$REPORT_FILE" ./Forensics > /dev/null 2>&1
echo "Zipped File will be on your PWD"


