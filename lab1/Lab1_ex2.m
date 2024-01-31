
% June 8, 2023
% Underwater Colorimetry Course @ IUI Eilat

% Basic Colorimetry and Image formation exercises

% Real Image Exercises

clear all; close all;clc; warning off

%% LOAD AN IMAGE THAT HAS A CALIBRATION TARGET (Color Chart) IN THE SCENE
I = im2double(imread('NikonImage.png'));

s = size(I);
figure;imshow(I*2)
title('Linear image','fontsize',20)


%% LOAD COLOR CHART DATA
% This example is given for a Macbeth ColorChecker

load MacbethColorCheckerData.mat

%% MAKE MASKS FOR THE PATCHES OF THE COLOR CHART
% It places the masks for each patch on the image, and waits for the user to drag each mask over the correct patch.
% Once each mask is aligned its corresponding patch, the user should double click the first patch in the chart
% -- that will accept the masks for all patches. In a Macbeth ColorChecker, the first patch is the Dark Skin.

masks = makeChartMask(I,chart,colors,20);

% It may be helpful to export masks as a masks.m file to avoid tedious if
% script is run again.

%% CHECK (AND CORRECT FOR) LINEARITY OF CAMERA RESPONSE 
% - ONLY UNCOMMENT IF YOUR IMAGE IS NOT LINEAR RGB
% 
% If you started with a raw images (i.e, used Adobe DNG converter to
% demosaic it) your image is linear. skip this cell.if not, uncomment it.
%

% The location and Y values for gray neutral (gray) patches given here are for those in the last row of a Macbeth ColorChecker.
% Modify these to work for your color chart, if different than a Macbeth
% ColorChecker.

neutralPatches = [4 1; 4 2; 4 3; 4 4; 4 5; 4 6]; % location of patches
neutralTarget = [89.57 57.76 35.15 19.44 9.08 3.43]./100; % Y value of patches, published or measured
neutralValues = getPatchValues(I,masks,neutralPatches,colors);
linFactors = getlincam(neutralTarget,neutralValues);
Ilinearized = linearizeRGB(linFactors,I);
plotLinearization(neutralValues,neutralTarget,linFactors);
figure;imshow(Ilinearized)
title('Linearized image','fontsize',20)

%% APPLY WHITE BALANCE
% The location of the white patch and dark patch are for a Macbeth chart, modify as needed.
Ilinearized = I;
whitePatch = [4 1];
darkPatch = [4 6];
Iwhitebalanced = whiteBalance(Ilinearized,masks.(colors{whitePatch(1),whitePatch(2)}).mask,masks.(colors{darkPatch(1),darkPatch(2)}).mask,0.8);
figure;imshow(Iwhitebalanced)
title('white balanced image','fontsize',20)
%% DERIVE THE TRANSFORMATION MATRIX T
% This matrix is derived from the published XYZ values for the Macbeth ColorChecker patches, and the RGB values the camera 
% recorded in the image I. To use with habitat chart, derive the RGB and XYZ values from spectra of
% features from the habitat. See spectra2XYZ.m to get tri-stimulus values.

RGB = getChartRGBvalues(Iwhitebalanced,masks,colors);
XYZ = getChartXYZvalues(chart,colors);
M = XYZ' * pinv(RGB)';

%% APPLY T TO A NOVEL IMAGE

Ixyz = reshape((M*reshape(Iwhitebalanced,[s(1)*s(2) 3])')',[s(1) s(2) 3]);
Irgb = XYZ2ProPhoto(Ixyz); % ProPhoto is a wide gamut RGB space that won't clip most colors.
figure;imshow(Irgb);title('Color transformed image','fontsize',20)

% What to include in report