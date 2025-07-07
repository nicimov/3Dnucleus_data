// ==============================================
// MACRO II
// to be used with MAIN MACRO (or individually)
// FUNCTION: Scans each nucleus and segments its components into individual (5) .tif files.
// ==============================================

// Set input/output directories for macro II
inputDir_nuc = getDirectory("Choose Cropped Nucleus Input Directory");
outputDir_obj = getDirectory("Choose visual output Directory");

// Faster processing (no UI updates)
setBatchMode(true);

// Get file list (filter for image files only)
fileList2 = getFileList(inputDir_nuc);
count = 0;

// Process each file
for (i = 0; i < fileList2.length; i++) {
    currentFile = fileList2[i];
    
    // Open tif file of nucleus
    path2 = inputDir_nuc + currentFile;
    open(path2);
    currentTitle = getTitle();
    
    // Run macro 
    pathToMacroII = "C:/Users/Honor/Desktop/MACROS/Macro_2_raw.ijm";
    
    
	// MACRO - separation of each individual nucleus
	
	//Speed up in batch mode
	
	setBatchMode(true);

	// Get current image title
	filename = getTitle();

	// Idenify nucleus number
	baseName = substring(filename, 0, lastIndexOf(filename, "."));
	nucnumber = lastIndexOf(baseName, "n");
	if (nucnumber >= 0) {
    number = substring(baseName, nucnumber+1);
	}



	// select nucleus, split channels
	run("Duplicate...", "title=nuc_obj duplicate");
	run("Split Channels");
	run("Select None");

	// Select Coilin channel (assuming it's C1) and duplicate it
	selectImage("C1-nuc_obj");
	run("Duplicate...", "title=ROIseg duplicate");


	// Run the THRESHOLDING ALGORITHM FOR COILIN (modify this when needed)

	// Gauss blur the duplicate
	selectImage("ROIseg");
	run("Gaussian Blur 3D...", "x=1 y=1 z=1");

	// Find 3D Maxima on the original (then closes the results not needed)
	selectImage("C1-nuc_obj");
	run("3D Maxima Finder", "minimum=0 radiusxy=0.5 radiusz=0.5 noise=25");
	
	// Segment the Coilin channel with 3D Simple segmentation using seeds
	selectImage("ROIseg");
	run("3D Simple Segmentation", "seeds=peaks_C1-nuc_obj low_threshold=16 min_size=0.1 max_size=-1");

	// Save the bin, seg, int for coilin
	selectImage("Bin");
	saveAs("Tiff", outputDir_obj + (i+1) + "_coilbin" + ".tif");
	selectImage("Seg");
	saveAs("Tiff", outputDir_obj + (i+1) + "_coilseg" + ".tif");
	selectImage("C1-nuc_obj");
	saveAs("Tiff", outputDir_obj + (i+1) + "_coilint" + ".tif");

	// CLOSE the bin and seg files!!
	close("Bin");
	close("Seg");

	// FOR DAPI (must me C2)
	// Gasuss filter and segmentation
	selectImage("C2-nuc_obj");
	run("Duplicate...", "title=nm duplicate");
	selectImage("C2-nuc_obj");
	run("Gaussian Blur 3D...", "x=1 y=1 z=1");
	run("3D Simple Segmentation", "seeds=None low_threshold=28 min_size=0 max_size=-1");

	// Save the bin for DAPI

	selectImage("Bin");
	saveAs("Tiff", outputDir_obj + (i+1) + "_DAPIbin" + ".tif");

	// CLOSE the bin and seg files!!
	close("Bin");
	close("Seg");

	// FOR nuclear membrane
	selectImage("nm");
	run("Gaussian Blur...", "sigma=4 stack");
	run("3D Simple Segmentation", "seeds=None low_threshold=12 min_size=0 max_size=-1");

	// Save the bin for nm
	selectImage("Bin");
	saveAs("Tiff", outputDir_obj + (i+1) + "_nmbin" + ".tif");

	// CLOSE the bin and seg files!!
	close("Bin");
	close("Seg");

	// print status
	print("Segmented objects of nucelus " + (i+1));
    
    count++;
    
    // Clean up (close all windows except original if needed)
    while (nImages > 1) {
        selectImage(nImages);
        close();
    }
    if (nImages > 0) {
        close();
    }
}

// Final strokes for MACRO II
if (isOpen("Results")) close("Results");
setBatchMode(false);
print("Successfully processed " + count + " of " + fileList2.length + " files with MACRO II.");

