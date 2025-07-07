// ==============================================
// Nuclei Collage Maker - Final Version
// ==============================================

macro "Create Nuclei Collage" {
    // Get directories
    directory = getDirectory("Choose Directory Containing Nucleus Images");
    outputDir = getDirectory("Choose Output Directory for Collage");
    
    // Get all numbered images
    list = getFileList(directory);
    filteredList = newArray(0);
    numbers = newArray(0);
    
    // First pass: find all images and extract numbers
    for (i=0; i<list.length; i++) {
        if (matches(list[i], "^\\d+_img\\.tif")) {
            num = parseInt(replace(list[i], "^([0-9]+)_.*", "$1"));
            numbers = Array.concat(numbers, num);
            filteredList = Array.concat(filteredList, list[i]);
        }
    }
    
    // Sort numerically (1, 2, 3... instead of 1, 10, 100)
    for (i=0; i<filteredList.length-1; i++) {
        for (j=i+1; j<filteredList.length; j++) {
            if (numbers[i] > numbers[j]) {
                // Swap numbers
                temp = numbers[i];
                numbers[i] = numbers[j];
                numbers[j] = temp;
                // Swap filenames
                temp = filteredList[i];
                filteredList[i] = filteredList[j];
                filteredList[j] = temp;
            }
        }
    }
    
    if (filteredList.length == 0) {
        showMessage("No nucleus images found!");
        return;
    }
    
    // Second pass: find maximum dimensions
    maxWidth = 0;
    maxHeight = 0;
    for (i=0; i<filteredList.length; i++) {
        open(directory + filteredList[i]);
        currentImage = getTitle();
        maxWidth = Math.max(maxWidth, getWidth());
        maxHeight = Math.max(maxHeight, getHeight());
        close(currentImage);
    }
    
    // Add extra space for number labels below images
    labelHeight = Math.round(Math.min(maxWidth, maxHeight)/6);
    cellWidth = maxWidth;
    cellHeight = maxHeight + labelHeight;
    
    // Determine collage layout
    numImages = filteredList.length;
    cols = Math.floor(Math.sqrt(numImages));
    rows = Math.max(1, Math.ceil(numImages/cols));
    
    // Create blank black canvas for collage
    collageWidth = cellWidth * cols;
    collageHeight = cellHeight * rows;
    newImage("Nuclei Collage", "RGB black", collageWidth, collageHeight, 1);
    
    // Process each image
    for (i=0; i<numImages; i++) {
        // Open original image
        open(directory + filteredList[i]);
        currentImage = getTitle();
        originalWidth = getWidth();
        originalHeight = getHeight();
        
        // Calculate position in collage grid
        col = i % cols;
        row = Math.floor(i / cols);
        x = col * cellWidth;
        y = row * cellHeight;
        
        // Copy and paste the original image (top-center aligned)
        run("Copy");
        selectWindow("Nuclei Collage");
        xOffset = x + (cellWidth - originalWidth)/2; // Center horizontally
        makeRectangle(xOffset, y, originalWidth, originalHeight);
        run("Paste");
        
        // Add the number label below the image (white text)
        number = replace(filteredList[i], "^([0-9]+)_.*", "$1");
        fontSize = Math.min(maxWidth, maxHeight)/8; // Smaller font size
        setFont("Arial", fontSize, "bold");
        setForegroundColor(255, 255, 255); // White text
        setJustification("center");
        textX = x + cellWidth/2;
        textY = y + maxHeight + fontSize;
        drawString(number, textX, textY);
        
        // Clean up
        close(currentImage);
    }
    
    // Save the collage
    saveAs("Tiff", outputDir + "Nuclei_Collage.tif");
    showMessage("Collage created successfully with " + numImages + " nuclei!");
}