// ==============================================
// COMPLETE COILBIN STACK PROCESSING MACRO - CORRECTED
// ==============================================

// Speed up in batch mode
setBatchMode(true);

macro "Process Numbered File Groups" {
    // Get directories
    inputDir_obj = getDirectory("Choose Directory Containing Segmented objects");
    outputDir_dat = getDirectory("Choose Data Output Directory");
    templateDir = getDirectory("Choose Directory Containing Template CSV Files (M_n, Q_n, C_n etc.)");

    // Get and filter files starting with numbers
    list = getFileList(inputDir_obj);
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
    
    // Process files in groups of 5 with same starting number
    currentPrefix = "";
    fileGroup = newArray(0);
    processedGroups = 0;
    
    for (i=0; i<filteredList.length; i++) {
        filename = filteredList[i];
        prefix = replace(filename, "^([0-9]+).*", "$1");
        
        // When prefix changes or we have 5 files, process the group
        if (prefix != currentPrefix && fileGroup.length > 0) {
            processFileGroup(fileGroup, inputDir_obj, outputDir_dat, templateDir, currentPrefix);
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
        processFileGroup(fileGroup, inputDir_obj, outputDir_dat, templateDir, currentPrefix);
        processedGroups++;
        print("====> PROGRESS: " + processedGroups + "/" + totalGroups + 
             " (" + d2s(100*processedGroups/totalGroups, 1) + "%)");
    }
    
    
    // Cleanup
    close("*"); 
    print("All files processed. Completed data extraction from " + processedGroups + "/" + totalGroups + " nuclei.");
}

function processFileGroup(fileGroup, inputDir_obj, outputDir_dat, templateDir, prefix) {
    print("\n=== Processing group " + prefix + " ===");
    
    // Open all files in the group
    for (i=0; i<fileGroup.length; i++) {
        open(inputDir_obj + fileGroup[i]);
    }
    
    // ======================= COILSEG signal detection =======================
    titles = getList("image.titles");
    hasSignal = false;
    coilsegTitle = "";
    
    // Find coilseg image
    for (i = 0; i < titles.length; i++) {
        if (indexOf(titles[i], "coilseg") != -1) {
            coilsegTitle = titles[i];
            break;
        }
    }
    
    if (coilsegTitle == "") {
        print("No coilseg image found - creating template files");
        createEmptyOutputFiles(templateDir, outputDir_dat, prefix);
        // Don't return here - continue to DAPI and NM processing
    } else {
        // Check for any white pixels in the stack
        selectImage(coilsegTitle);
        print("Checking for signal in: " + coilsegTitle);
        stackDepth = nSlices;
        
        // Save original image
        originalID = getImageID();
        
        // Check each slice for white pixels
        for (slice=1; slice<=stackDepth && !hasSignal; slice++) {
            setSlice(slice);
            getRawStatistics(nPixels, mean, min, max, std, histogram);
            
            if (max > 0) {  // Assuming white pixels have value > 0
                hasSignal = true;
                print("--> Signal detected in slice " + slice);
            }
        }
        
        if (!hasSignal) {
            print("--> No signal detected in any slice - creating template files");
            createEmptyOutputFiles(templateDir, outputDir_dat, prefix);
        }
    }
    
    // ======================= NORMAL 3D PROCESSING =======================
    // Only proceed with coilin processing if signal was detected
    if (hasSignal) {
        print("Proceeding with 3D analysis...");
        
        // Prepare images for 3D analysis
        for (i = 0; i < titles.length; i++) {
            selectImage(titles[i]);
            currentTitle = getTitle();
            
            if (indexOf(currentTitle, "coilbin") != -1) {
                run("Duplicate...", "title=coilbinQM duplicate");
            }
            if (indexOf(currentTitle, "coilint") != -1) {
                run("Duplicate...", "title=coilintQM duplicate");
            }
        }
        
        // Initialize 3D Manager
        run("3D Manager");
        wait(1000);
        
        // Volume measurement (M_n.csv)
        selectImage("coilbinQM");
        Ext.Manager3D_Segment(128, 255);
        selectImage("coilbinQM-3Dseg");
        Ext.Manager3D_AddImage;
        wait(300);
        Ext.Manager3D_Measure;
        Ext.Manager3D_SaveResult("M", outputDir_dat + prefix + ".csv");
        Ext.Manager3D_CloseResult("M");
        print("Completed nuclear body volume measurement for group " + prefix);
        
        // Intensity measurement (Q_n.csv)
        selectImage("coilintQM");
        wait(300);
        Ext.Manager3D_Quantif;
        Ext.Manager3D_SaveResult("Q", outputDir_dat + prefix + ".csv");
        Ext.Manager3D_CloseResult("Q");
        print("Completed nuclear body intensity measurement for group " + prefix);
        
        // Cleanup 3D Manager
        Ext.Manager3D_SelectAll;
        wait(100);
        Ext.Manager3D_Delete;
        wait(200);
        print("Prepared for colocalisation analysis");
        
        // Prepare for colocalization analysis
        for (i = 0; i < titles.length; i++) {
            selectImage(titles[i]);
            currentTitle = getTitle();
            
            if (indexOf(currentTitle, "coilbin") != -1) {
                run("Duplicate...", "title=coilbinC duplicate");
            }
            if (indexOf(currentTitle, "DAPIbin") != -1) {
                run("Duplicate...", "title=DAPIbinC duplicate");
            }
        }
        
        // Colocalization analysis (C_n.csv)
        run("3D Manager");
        selectImage("coilbinC");
        Ext.Manager3D_AddImage;
        wait(100);
        Ext.Manager3D_SelectAll;
        wait(100);
        Ext.Manager3D_Merge;
        wait(200);
        print("Added channel 1");
        
        selectImage("DAPIbinC");
        Ext.Manager3D_AddImage;
        wait(100);
        print("Added channel 2");
        Ext.Manager3D_SelectAll;
        wait(100);
        Ext.Manager3D_Coloc;
        Ext.Manager3D_SaveResult("C", outputDir_dat + prefix + ".csv");
        Ext.Manager3D_CloseResult("C");
        print("Completed colocalisation analysis for group " + prefix);
        
        // Cleanup 3D Manager
        Ext.Manager3D_SelectAll;
        wait(100);
        Ext.Manager3D_Delete;
        wait(200);
    }
    
    // ======================= DAPI AND NUCLEAR MEMBRANE PROCESSING =======================
    // This section will run regardless of whether coilin signal was detected
    
    print("Prepared for DAPI analysis");
    
    // Prepare for DAPI analysis
    // First check if we have a DAPIbin image
    dapiFound = false;
    for (i = 0; i < titles.length; i++) {
        if (indexOf(titles[i], "DAPIbin") != -1) {
            selectImage(titles[i]);
            run("Duplicate...", "title=DAPIbinM duplicate");
            dapiFound = true;
            break;
        }
    }
    
    if (dapiFound) {
        // Volume measurement (M_D_n.csv)
        run("3D Manager");
        selectImage("DAPIbinM");
        Ext.Manager3D_AddImage;
        wait(300);
        Ext.Manager3D_Measure;
        Ext.Manager3D_SaveResult("M", outputDir_dat + "D_" + prefix + ".csv");
        Ext.Manager3D_CloseResult("M");
        print("Completed DAPI volume measurement for group " + prefix);
        
        // Cleanup 3D Manager
        Ext.Manager3D_SelectAll;
        wait(100);
        Ext.Manager3D_Delete;
        wait(200);
    } else {
        print("No DAPIbin image found - skipping DAPI measurement");
    }
    
    print("Prepared for NM analysis");
    
    // Prepare for nuclear border analysis
    // First check if we have a nmbin image
    nmbFound = false;
    for (i = 0; i < titles.length; i++) {
        if (indexOf(titles[i], "nmbin") != -1) {
            selectImage(titles[i]);
            run("Duplicate...", "title=nmbinM duplicate");
            nmbFound = true;
            break;
        }
    }
    
    if (nmbFound) {
        // Volume measurement (M_N_n.csv)
        run("3D Manager");
        selectImage("nmbinM");
        Ext.Manager3D_AddImage;
        wait(300);
        Ext.Manager3D_Measure;
        Ext.Manager3D_SaveResult("M", outputDir_dat + "N_" + prefix + ".csv");
        Ext.Manager3D_CloseResult("M");
        print("Completed nucleus volume measurement for group " + prefix);
        
        // Cleanup 3D Manager
        Ext.Manager3D_SelectAll;
        wait(100);
        Ext.Manager3D_Delete;
        wait(100);
    } else {
        print("No nmbin image found - skipping nuclear border measurement");
    }
    
    // Final cleanup
    run("Close All");
    print("Ready for the next processing group");
    wait(100);
}

function createEmptyOutputFiles(templateDir, outputDir, prefix) {
    fileTypes = newArray("M", "Q", "C");
    
    for (i=0; i<fileTypes.length; i++) {
        type = fileTypes[i];
        templatePath = templateDir + type + "_n.csv";
        outputPath = outputDir + type + "_" + prefix + ".csv";
        
        if (File.exists(templatePath)) {
            File.copy(templatePath, outputPath);
            print("Created " + type + "_" + prefix + ".csv from template");
        } else {
            File.saveString("No coilin objects detected", outputPath);
            print("Created empty " + type + "_" + prefix + ".csv");
        }
    }
}