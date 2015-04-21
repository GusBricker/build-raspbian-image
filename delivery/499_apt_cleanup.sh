#!/bin/bash

BannerEcho "Apt Cleanup: Cleaning up apt cache"

AptCleanup 
echo "All install later's should come after this point"

BannerEcho "Apt Cleanup: Done"
