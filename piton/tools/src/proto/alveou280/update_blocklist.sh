#!/bin/bash

#This script can be improved adding the default value of the entire line frequency regardless.
#Then we could talk about Ariane core and not "default", and also add more cores if necessary.

#We need to avoid adding this file to the git commit everytime. But in the other hand, it can't be
# in the .gitignore list...

PART_DEFAULT="alveou280,100"
PART_LAGARTO="alveou280,50"
BLOCK_FILE=$PITON_ROOT/piton/tools/src/proto/block.list
CORE=$1

#Changes to block.list made by this script shouldn't be commited
DOIT="git update-index --skip-worktree $BLOCK_FILE"

if [ "$CORE" == "lagarto" ]; then

#switch the lines

	sed -i "{s|$PART_DEFAULT|$PART_LAGARTO|}" $BLOCK_FILE

elif [ "$CORE" == "ariane" ]; then

	sed -i "{s|$PART_LAGARTO|$PART_DEFAULT|}" $BLOCK_FILE

else

	#There are no more supported cores so far.
	git checkout $BLOCK_FILE

fi





