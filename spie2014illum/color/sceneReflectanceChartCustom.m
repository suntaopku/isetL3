function [scene, reflectance, rcSize] = sceneReflectanceChartCustom(pSize,wave,grayFlag,LABsamples)
% Create a reflectance chart for testing
%
%   [scene, sampleList, reflectances, rcSize] = ...
%      sceneReflectanceChart(sFiles,sSamples,pSize,[wave],[grayFlag=1],[sampling])
%
% Inputs
%  The surfaces are drawn from the cell array of sFiles{}.  
%  sFiles:   Cell array of file names with reflectance spectra
%            It is also possible to set sFiles to a matrix of reflectances.
%  sSamples: This can either be
%      - Vector indicating how many surfaces to sample from each file
%      - A cell array of specifying the list of samples from each file 
%  pSize:    The number of pixels on the side of each square patch
%  wave:     Wavelength Samples
%  grayFlag: Fill the last part of the chart with gray surfaces, the last
%            one being a white patch and the others sampling different gray
%            level reflectances
%
% Returns
%   scene:         Reflectance chart as a scene
%   sSamples:      A cell array of the surfaces from each file, as above
%   reflectances:  The actual reflectances
%   rcSize:        Row and column sizes
%
% If a specific set of samples is chosen they are written out in row
% first ordering, [ 1 4 7; 2 5 8; 3 6 9]
%  
%Example:
%  sFiles = cell(1,4);
%  sFiles{1} = fullfile(isetRootPath,'data','surfaces','reflectances','MunsellSamples_Vhrel.mat');
%  sFiles{2} = fullfile(isetRootPath,'data','surfaces','reflectances','Food_Vhrel.mat');
%  sFiles{3} = fullfile(isetRootPath,'data','surfaces','reflectances','DupontPaintChip_Vhrel.mat');
%  sFiles{4} = fullfile(isetRootPath,'data','surfaces','reflectances','Skin_Vhrel.mat');
%  sSamples = [12,12,25,25]*5; nSamples = sum(sSamples);
%  pSize = 24; 
%
%  [scene, samples] = sceneReflectanceChart(sFiles,sSamples,pSize);
%  scene = sceneAdjustLuminance(scene,100);
%  vcAddAndSelectObject(scene); sceneWindow;
%
% See also: macbethChartCreate
%
% Copyright ImagEval Consultants, LLC, 2010.

if ieNotDefined('pSize'),    pSize = 32; end
if ieNotDefined('grayFlag'), grayFlag = 1; end
if ieNotDefined('sampling'), sampling = 'r'; end %With replacement by default

nSamples = size(LABsamples,1);

% Default scene
scene = sceneCreate;
if ieNotDefined('wave'), wave = sceneGet(scene,'wave');
else                     scene = sceneSet(scene,'wave',wave);
end
nWave = length(wave);
defaultLuminance = 100;  % cd/m2

% Spatial arrangement
r = ceil(sqrt(nSamples)); c = ceil(nSamples/r);
reflectance = zeros(nWave,nSamples);

% reflectance is in wave x surface format.  We fill up the end of the matrix with
% gray surface reflectances.
if grayFlag
    % Create a column of gray surfaces, from 100% reflectance scaling down
    % in steps of 0.5 (0.3 log unit)
    s = logspace(0,log10(0.05),r); 
    g = ones(nWave,r)*diag(s);
    reflectance = [reflectance, g];
    c = c + 1;
end
rcSize = [r,c];

% Convert the scene reflectances into photons assuming an equal energy
% illuminant.
ee         = ones(nWave,1);           % Equal energy vector
e2pFactors = Energy2Quanta(wave,ee);  % Energy to photon factor

% Illuminant
illuminantPhotons = diag(e2pFactors)*ones(nWave,1);
if numel(wave) > 1,  dWave = wave(2) - wave(1);
else                 dWave = 10;   disp('10 nm band assumed');
end
S = ieReadSpectra('XYZ',wave);
whiteXYZRef = 683*dWave*(S'*ee);

XYZvalues = RGB2XWFormat(lab2xyz(XW2RGBFormat(LABsamples,rcSize(1),rcSize(2)-1),whiteXYZRef));

for rr=1:rcSize(1)
    for cc=1:rcSize(2)
        idx = sub2ind(rcSize,rr,cc);
        if idx <= nSamples
           eData = lsqlinFG(ones(nWave,1)',0,[],[],683*dWave*S',XYZvalues(idx,:)',zeros(nWave,1),ones(nWave,1));
           sData(rr,cc,:) = Energy2Quanta(wave,eData);
           reflectance(:,idx) = diag(e2pFactors)\squeeze(sData(rr,cc,:));
        elseif cc == rcSize(2)-grayFlag
           sData(rr,cc,:) = 0.2*illuminantPhotons;
        else
           sData(rr,cc,:) = diag(e2pFactors)*reflectance(:,idx);
        end
    end
end
  
% Store the photon data as XYZ, too. We will need these for evaluation of
% color algorithms later (sensor and illuminant correction).  These are
% stored in RGB format here (row,col,wave).
XYZ = ieXYZFromPhotons(sData,wave);

% Build up the size of the image regions - still reflectances
sData = imageIncreaseImageRGBSize(sData,pSize);

% Add data to scene, using equal energy illuminant
scene = sceneSet(scene,'cphotons',sData);
scene = sceneSet(scene,'illuminantPhotons',illuminantPhotons);
scene = sceneSet(scene,'illuminantComment','Equal energy');
scene = sceneSet(scene,'name','Reflectance Chart (Custom)');
% vcAddAndSelectObject(scene); sceneWindow;

% Adjust the illuminance to a default level in cd/m2
scene = sceneAdjustLuminance(scene,defaultLuminance);
% vcAddAndSelectObject(scene); sceneWindow;

% Attach the chart parameters to the scene object so we can easily find the
% centers later
chartP.nSamples = nSamples;
chartP.grayFlag = grayFlag;
chartP.rowcol   = rcSize;
chartP.XYZ      = XYZ;
chartP.luminance = defaultLuminance;
scene = sceneSet(scene,'chart parameters',chartP);

return


