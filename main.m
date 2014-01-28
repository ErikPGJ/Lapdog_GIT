% main -- LAP Dataset Overview and Geometry (lapdog) main file
%
% Create overview of LAP ops and geometry files for a given data set.

% anders.eriksson@irfu.se 2012-03-29

'LAPDOG - LAP Data Overview and Geometry'
''

% Define the dataset:

'lapdog: calling control...'
control;

% Set up PDS keywords etc:
'lapdog: calling preamble...'
preamble;

% Load or, if not defined, generate index:
'lapdog: load indices if existing...'
indexfile = sprintf('index/index_%s.mat',archiveid);
fp = fopen(indexfile,'r');
if(fp > 0)
    fclose(fp);
    load(indexfile);
else
    'lapdog: calling indexgen...'
    indexgen;
end

% Generate daily geometry files:
if(do_geom)
  'lapdog: calling geometry...'
  geometry;
end

% Generate block list file:
'lapdog: calling opsblocks...'
opsblocks;

if(do_mill)
'lapdog: calling process...'
  process;
'lapdog: generate LBL files....'
%  createLBL;

end




'lapdog: Parmesan -Done!'
% End of main.m
