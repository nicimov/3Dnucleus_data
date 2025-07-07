// ImageJ macro to delete specified groups and renumber remaining files
macro "Delete Groups and Renumber" {
    // Get user input for groups to delete
    Dialog.create("Delete Groups");
    Dialog.addString("Groups to delete (comma-separated):", "1, 2, 3");
    Dialog.show();
    groupsToDelete = Dialog.getString();
    
    // Set the directory containing files
    directory = getDirectory("Choose Directory");
    setBatchMode(true);
    
    // Convert input to array of numbers
    groupsArray = split(groupsToDelete.replace(" ", ""), ",");
    
    // Delete specified groups
    list = getFileList(directory);
    for (i = 0; i < list.length; i++) {
        for (g = 0; g < groupsArray.length; g++) {
            if (startsWith(list[i], groupsArray[g] + "_")) {
                File.delete(directory + list[i]);
                break;
            }
        }
    }
    
    // Find remaining group numbers
    remainingGroups = newArray(0);
    list = getFileList(directory);
    for (i = 0; i < list.length; i++) {
        parts = split(list[i], "_");
        if (parts.length > 0) {
            currentNum = parseInt(parts[0]);
            // Manual array search
            found = false;
            for (k = 0; k < remainingGroups.length; k++) {
                if (remainingGroups[k] == currentNum) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                remainingGroups = Array.concat(remainingGroups, currentNum);
            }
        }
    }
    
    // Sort remaining groups numerically (bubble sort)
    for (i = 0; i < remainingGroups.length-1; i++) {
        for (j = i+1; j < remainingGroups.length; j++) {
            if (remainingGroups[i] > remainingGroups[j]) {
                temp = remainingGroups[i];
                remainingGroups[i] = remainingGroups[j];
                remainingGroups[j] = temp;
            }
        }
    }
    
    // Renumber files (starting from 1)
    for (n = 0; n < remainingGroups.length; n++) {
        oldNum = remainingGroups[n];
        newNum = n + 1;
        if (oldNum != newNum) {
            for (i = 0; i < list.length; i++) {
                if (startsWith(list[i], oldNum + "_")) {
                    newName = replace(list[i], oldNum + "_", newNum + "_");
                    File.rename(directory + list[i], directory + newName);
                }
            }
            // Refresh file list after renaming
            list = getFileList(directory);
        }
    }
    
    setBatchMode(false);
    showMessage("Done! Deleted groups: " + groupsToDelete + "\nRemaining files renumbered sequentially.");
}