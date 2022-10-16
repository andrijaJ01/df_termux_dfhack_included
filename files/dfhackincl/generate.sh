#!/bin/bash
#
# Title: Dwarf Fortress World Generator
# Author: Ruxias
# Version: 1.0
# Date: 2012-08-20 (YYYY-MM-DD)
#
# Description:
#     This script enhances command-line world generation in Dwarf Fortress.
#   First, it generates a world with ID 99 and the selected params and seed.
#   Then, it renames the new world's folder to the name of the world and makes
#   a folder ("info") to hold all the information files the game generates.
#   After moving and renaming the information files, it may convert the map
#   images to PNG and create a composite of both of the maps, provided you have
#   ImageMagick installed and the corresponding options enabled in this script.
#   If you include a number when executing this script it will make that many
#   worlds. Otherwise, it will make the default amount.
#
#   IMPORTANT: Always keep this script in the Dwarf Fortress directory!
#              The default name is "df_linux" but may be something different.
#
# Requirements:
#   - BASH
#   - ImageMagick (For image conversion and compositing.)
#   - tar and gzip (For new world backups.)
#
# Changelog:
#   + = Added, x = Removed, * = Changed, # = Fixed, ! = Note
#   Version 1.0 [2012-08-20]
#       ! Initial Release

# BEGIN SCRIPT SETTINGS
cycles=1 # Default number of worlds to generate if no number was passed. [1]
params=AUTO # Name of the parameter set in "data/init/world_gen.txt" to use. [AUTO]
seed=RANDOM # Seed to use for world generation. [RANDOM]
convert=YES # Convert maps from BMP to PNG? (Smaller filesize; requires ImageMagick.) [YES]
composite=YES # Create a combined image from the height and biome maps? (Requires ImageMagick.) [YES]
backup=YES # Make a backup of the newly created world? [YES]
pause=0 # Number of seconds to pause after completion. If less than zero, wait for keypress. [0]
# END SCRIPT SETTINGS

# BEGIN SCRIPT OPERATION
statuscode=0 # Set the status code to 0 (Success) for now.
errorcode=0 # Set the detailed error code to 0 (None) for now.
count=0 # Set the count to 0.

if [[ -n "$1" && $1 =~ ^[0-9]+$ ]]; then # If a number was passed to the script, then ...
	cycles=$1 # Set cycles to that number.
fi

rootdir=$(dirname "$(readlink -fn "$0")") # Change the current directory to where the script is located for compatibility with launchers.
cd "$rootdir"

function quietly() { "$@" > /dev/null; } # Simple function to silence the output of commands.

while [[ $count -lt $cycles && $statuscode -ne 1 ]]; do # While count is less than cycles and status code isn't 1 (Failure) ...
	echo "[?] Creating World ($(( $count+1 ))/$cycles)"
	if [ -d "data/save/region99" ]; then # If a world with ID 99 exists in "data/save" then ...
		echo "[!] Folder 'data/save/region99' already exists!" # Echo an error message and set the status code to 1 (Failure) and the error code to 1. (World ID 99 Exists)
		statuscode=1
		errorcode=1
	else # Otherwise ...
		echo -n "    Generating world... "
		quietly ./df -gen 99 $seed $params # Quietly execute Dwarf Fortress in world generation mode.
		if [ -d "data/save/region99" ]; then # If "region99" was created during world generation, then ...
			echo "Done!"
			echo -n "    Reading world name... "
			name=$(head -n1 region99-world_history.txt) # Read the first line of "region99-world_history.txt" to get the world name.
			echo " Done! ($name)"
			echo -n "    Organizing files... "
			if [ -d "data/save/$name" ]; then # If a world already exists that has the same name ...
				echo "Fail!" # Echo an error message and delete the generated files.
				echo "[?] World with that name already exists! Regenerating world..."
				rm world_map-region99*.bmp 
				rm world_graphic-region99*.bmp
				rm region99-world_history.txt
				rm region99-world_sites_and_pops.txt
				rm region99-world_gen_param.txt
				rm -r data/save/region99 # ("-r" option needed to delete world folder.)
			else # Otherwise ...
				cd data/save/ # Move to the save directory.
				mv "region99" "$name" # Make the world's folder name reflect the actual world name.
				cd "$name" # Move to the world's directory.
				mkdir info # Make the "info" folder.
				mv ../../../world_map-region99*.bmp "info/Biome Map.bmp" # Move the info files to the "info" folder and clean up their file names.
				mv ../../../world_graphic-region99*.bmp "info/Height Map.bmp"
				mv ../../../region99-world_history.txt "info/History.txt"
				mv ../../../region99-world_sites_and_pops.txt "info/Sites.txt"
				mv ../../../region99-world_gen_param.txt "info/Parameters.txt"
				echo "Done!"
				if [ $convert == YES ]; then # If "convert" is "YES", then ...
					echo -n "    Converting images to PNG... "
					cd info # Move to the info directory.
					convert "Biome Map.bmp" "Biome Map.png" # Convert each map to PNG.
					convert "Height Map.bmp" "Height Map.png"
					rm "Biome Map.bmp" # Delete the old maps.
					rm "Height Map.bmp"
					echo "Done!"
					if [ $composite == YES ]; then # If "composite" is "YES", then ...
						echo -n "    Creating composite map... "
						composite -dissolve 30,100 "Height Map.png" "Biome Map.png" "Composite Map.png" # Create the composite map.
						echo "Done!"
					fi
				fi
				if [ $backup == YES ]; then # If "backup" is "YES", then ...
					echo -n "    Performing backup... "
					cd ../.. # Go to the save directory and create a backup of the world.
					tar --create --gzip --file="$name (Fresh World).tar.gz" "$name"
					echo "Done!"
				fi
				cd "$rootdir" # Change directory to where the script is located.
				count=$count+1 # Increase count by one.
			fi
		else # Otherwise ...
			echo "Fail!" # Echo an error message and set the status code to 1 (Failure) and the error code to 2. (World Folder Not Found)
			echo "[!] Folder 'data/save/region99' not found!"
			statuscode=1
			errorcode=2
		fi
	fi
done

# Output the appropriate message.
if [ $statuscode == 0 ]; then # If status code is 0 (Success), then ...
	echo "[?] Operation completed successfully." # Report success.
else # Otherwise ...
	echo "[?] An error occurred during operation." # Report failure.
	case $errorcode in # Output a detailed error message according to the error code.
		1 )
			echo "[?] A saved world named 'region99' already exists."
			echo "    Rename, move, or delete this folder."
			;;
		2 )
			echo "[?] Dwarf Fortress didn't generate a world folder. Perhaps you aborted?"
			;;
	esac
fi

if (( $pause >= 0 )); then # If "pause" is greater than or equal to 0, then ...
	sleep $pause # Sleep for "pause" seconds.
else # Otherwise ...
	read -p "" -n1 -s # Wait for a keypress.
fi

exit $statuscode # Exit, reporting status code.
# END SCRIPT OPERATION
