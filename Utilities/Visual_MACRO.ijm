// ==============================================
// Visual_Macro
// 
// FUNCTION: visualises different channels from idenified nuclei
// ==============================================

//Speed up in batch mode
setBatchMode(true);

// ImageJ macro to process files in groups of 3 with same starting number
macro "Process Numbered File Groups" {
    // Get directories
    directory = getDirectory("Choose Directory Containing segmented Files");
    outputDir_img = getDirectory("Choose Data Output Directory");

    //Speed up in batch mode
    setBatchMode(true);

    // Get and filter files starting with numbers
    list = getFileList(directory);
    filteredList = newArray(0);
    
    for (i=0; i<list.length; i++) {
        if (matches(list[i], "^\\d+.*")) {
            filteredList = Array.concat(filteredList, list[i]);
        }
    }
    
    // Sort array
    Array.sort(filteredList);  

    // First pass to count total number of groups
    totalGroups = 0;
    tempPrefix = "";
    for (i=0; i<filteredList.length; i++) {
        filename = filteredList[i];
        prefix = replace(filename, "^([0-9]+).*", "$1");
        if (prefix != tempPrefix) {
            totalGroups++;
            tempPrefix = prefix;
        }
    }
    print("Found " + totalGroups + " groups to process");
    
    // Process files in groups of 3 with same starting number
    currentPrefix = "";
    fileGroup = newArray(0);
    processedGroups = 0;
    
    for (i=0; i<filteredList.length; i++) {
        filename = filteredList[i];
        prefix = replace(filename, "^([0-9]+).*", "$1");
        
        // When prefix changes or we have 5 files, process the group
        if (prefix != currentPrefix && fileGroup.length > 0) {
            processFileGroup(fileGroup, directory, outputDir_img, currentPrefix);
            fileGroup = newArray(0);
            processedGroups++;
            
            // Show progress
            print("====> PROGRESS: " + processedGroups + "/" + totalGroups + 
                 " (" + d2s(100*processedGroups/totalGroups, 1) + "%)");
        }
        
        currentPrefix = prefix;
        if (fileGroup.length < 5) {
            fileGroup = Array.concat(fileGroup, filename);
        }
    }
    
    // Process the last group if it exists
    if (fileGroup.length > 0) {
        processFileGroup(fileGroup, directory, outputDir_img, currentPrefix);
        processedGroups++;
        // Show final progress
        print("====> PROGRESS: " + processedGroups + "/" + totalGroups + 
             " (" + d2s(100*processedGroups/totalGroups, 1) + "%)");
    }
	
	// Cleanup
    close("*"); 
    
    // Final completion message
    print("All files processed. " + processedGroups + "/" + totalGroups + " nuclei are visualised.");
}

// Function to process a group of files
function processFileGroup(fileGroup, directory, outputDir_img, prefix) {
    print("Processing group " + prefix + " with " + fileGroup.length + " files");
    
    // Open all files in the group
    for (i=0; i<fileGroup.length; i++) {
        open(directory + fileGroup[i]);
    }
    
    // ======================= PROCESSING CODE =======================
    
    
    // Identify open files
    titles = getList("image.titles");
    
    // Select and duplicate images 
    for (i = 0; i < titles.length; i++) {
        selectImage(titles[i]);
        currentTitle = getTitle();
        
        if (indexOf(currentTitle, "coilbin") != -1) {
            print("Found coilbin image: " + currentTitle);
            run("Duplicate...", "title=coilbin duplicate");
        }
    }
    
    for (i = 0; i < titles.length; i++) {
        selectImage(titles[i]);
        currentTitle = getTitle();
        
        if (indexOf(currentTitle, "DAPIbin") != -1) {
            print("Found DAPIbin image: " + currentTitle);
            run("Duplicate...", "title=DAPIbin duplicate");
        }
    }
    
    for (i = 0; i < titles.length; i++) {
        selectImage(titles[i]);
        currentTitle = getTitle();
        
        if (indexOf(currentTitle, "nmbin") != -1) {
            print("Found nmbin image: " + currentTitle);
            run("Duplicate...", "title=nmbin duplicate");
        }
    }
    
    // Merge
    run("Merge Channels...", "c1=DAPIbin c2=coilbin c3=nmbin create");
    
    //zstack
    selectImage("Composite");
    run("Z Project...", "projection=[Sum Slices]");
	selectImage("SUM_Composite");
	run("RGB Color");
    saveAs("Tiff", outputDir_img + prefix + "_img" + ".tif");
    
    // Cleanup (to not confuse the next iteration batch)
    run("Close All");
}