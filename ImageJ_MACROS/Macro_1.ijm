// ==============================================
// MERGED MACRO (FIXED VERSION)
// FUNCTION: 
// 1. Scans input folder for .lif files
// 2. For each file, finds nuclei and crops them into individual .tif files
// ==============================================

// Set input/output directories
inputDir_PIM = getDirectory("Choose Primary Image Input (PIM) Directory");
outputDir_nuc_cr = getDirectory("Choose Nucleus Crop Output Directory");

// Faster processing (no UI updates)
setBatchMode(true);

// Get file list (filter for image files only)
fileList1 = getFileList(inputDir_PIM);
count = 0;
totalNuclei = 0;

// Process each file
for (i = 0; i < fileList1.length; i++) {
    currentFile = fileList1[i];
    
    // Skip non-LIF files
    if (!endsWith(currentFile, ".lif")) continue;
    
    // Clear ROI Manager before processing new file
    roiManager("reset");
    
    // Open LIF file silently using Bio-Formats
    path1 = inputDir_PIM + currentFile;
    run("Bio-Formats Importer", "open=[" + path1 + "] autoscale color_mode=Composite view=Hyperstack stack_order=XYCZT");
    currentTitle = getTitle();
    
    // ====== BEGIN PROCESSING ======
    // Get current image title and ID
    original_title = getTitle();
    imageID = getImageID();

    // Verify an image is open
    if (lengthOf(original_title)==0) {
        print("No image found in: " + currentFile);
        continue;
    }

    // Remove file extension if present
    base_title = original_title;
    lastDot = lastIndexOf(base_title, ".");
    if (lastDot >= 0) {
        base_title = substring(base_title, 0, lastDot);
    }

    // Select PI (now uses active image)
    run("Duplicate...", "title=nuc_seg duplicate");
    run("Split Channels");

    // Select DAPI channel for nucleus identification (assuming it's C2)
    selectImage("C2-nuc_seg");

    // Z projection and Gauss blur  for particle analysis
    run("Z Project...", "projection=[Sum Slices]");
    run("Gaussian Blur...", "sigma=2");
    
    //convert to 8bit after Zproject and do auto threshold (with watershed)
    setOption("ScaleConversions", true);
    run("8-bit");
    run("Auto Threshold", "method=Li white");
    run("Watershed");
    
    // Clear any existing ROIs before analysis
    roiManager("reset");
    run("Analyze Particles...", "exclude add");

    // Select the original image for cropping
    selectImage(imageID);

    // Process all ROIs
    nROIs = roiManager("count");
    if (nROIs == 0) {
        print("No nuclei found in: " + original_title);
        // Clean up before next iteration
        close("nuc_seg");
        close("C2-nuc_seg");
        close("SUM_C2-nuc_seg");
        continue;
    }

    // Save each nucleus
    for (j=0; j<nROIs; ++j) {
        roiManager("Select", j);
        run("Duplicate...", "title=crop.lif duplicate");
        // REMOVE BACKGROUND (can be improved)
        run("Clear Outside");
        
        saveAs("Tiff", outputDir_nuc_cr + base_title + "_n" + (j+1) + ".tif");
        close();
        selectImage(imageID); // Return to original image
    }

    totalNuclei += nROIs;
    print("Saved "+nROIs+" nuclei from: " + original_title);
    
    // Clean up all intermediate images
    close("nuc_seg");
    close("C1-nuc_seg");
    close("C2-nuc_seg");
    close("SUM_C2-nuc_seg");
    
    // ====== END PROCESSING ======
    count++;
    
    // Close the original image
    if (isOpen(original_title)) {
        close(original_title);
    }
}

setBatchMode(false);
print("Successfully processed " + count + " of " + fileList1.length + " files.");
print("Total nuclei saved: " + totalNuclei);