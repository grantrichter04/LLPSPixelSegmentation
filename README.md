# LLPSPixelSegmentation
This is an imageJ macro to speed up segmentation of image stacks. The goal is measure protein characteristics within the cytoplasm, within the nucleus, and within biomolecular condensates.

Input:A Microscopy image of a motor neuron - 2 channels, one with protein of interest, one with nuclear marker.  
Output: Using a seperate labkit classifier, an output labeled stack with (1) background, (2) cytoplasm, (3) nuclear, and (4) biomolecular condensates is segmented.  
This labeled image is presented to the user for approval, and then resulting measurments are saved for downstream analysis. 
